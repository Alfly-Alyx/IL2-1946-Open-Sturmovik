<#
Behavioral checks of the direct Java startup hook, without starting IL-2.
Builds from source and tests the exact packaged Java 47 helper using a fake Mat.
The JVM is the local Java development runtime, not the native IL-2 runtime.
Fixture and report directories remain under this assigned checkout's build folder.
#>
#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$RebuildPackage
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$gitOptions = @('-c', ('safe.directory=' + $root.Replace('\','/')), '-C', $root)
$gitRoot = & git @gitOptions rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($gitRoot).TrimEnd('\') -ne $root) { throw 'Wrong Git root.' }
$branch = & git @gitOptions branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/rotation-fonds') { throw 'Expected the assigned codex/rotation-fonds branch.' }
if ($root -notlike 'C:\Users\Alexis\.codex\*') { throw 'Use the assigned private checkout for these tests.' }
$runRoot = Join-Path $root ('build\loading-rotation-test-run-' + [Guid]::NewGuid().ToString('N'))
$cursor = $runRoot
while ($cursor.Length -ge $root.Length) {
    if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Reparse point: $cursor" }
    if ($cursor -eq $root) { break }
    $cursor = Split-Path -Parent $cursor
}
[void][IO.Directory]::CreateDirectory($runRoot)
$package = Join-Path $root '_Game Switcher\Loading Rotation Patch'
$buildRoot = Join-Path $runRoot 'patch'
$buildArguments = @{ RepositoryRoot=$root; OutputDirectory=$buildRoot }
if ($RebuildPackage) { $buildArguments.PackageRoot = $package }
$source = Join-Path $root 'tools\java\loading-rotation\com\maddox\il2\engine\OpenSturmovikLoadingRotation.java'
$testRoot = Join-Path $root 'tools\java\loading-rotation-tests\com\maddox\il2\engine'
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
$javac = (Get-Command javac -ErrorAction Stop).Source
$java = (Get-Command java -ErrorAction Stop).Source
$oldLocation = Get-Location
$results = @()
try {
    Set-Location -LiteralPath $root
    & (Join-Path $root 'tools\Build-LoadingRotationPatch.ps1') @buildArguments
    $built = Get-Content -LiteralPath (Join-Path $buildRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $packaged = Get-Content -LiteralPath (Join-Path $package 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($built.helperSourceSha256 -ne $sourceHash -or $packaged.helperSourceSha256 -ne $sourceHash -or
        $built.patcherSourceSha256 -ne $packaged.patcherSourceSha256) {
        throw 'Packaged patch differs from current source. Rebuild it with -RebuildPackage.'
    }
    foreach ($entry in @($built.classes)) {
        $match = @($packaged.classes | Where-Object { $_.class -eq $entry.class })
        if ($match.Count -ne 1 -or $match[0].sha256 -ne $entry.sha256) { throw "Packaged class differs from rebuilt class: $($entry.class)" }
        $path = Join-Path $package ([string]$match[0].path)
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) { throw "Packaged class hash mismatch: $path" }
        $bytes = [IO.File]::ReadAllBytes($path)
        if (([int]$bytes[6] * 256 + [int]$bytes[7]) -ne 47) { throw 'Packaged class is not Java 47.' }
    }
    $sourceClasses = Join-Path $runRoot 'source-classes'
    [void][IO.Directory]::CreateDirectory($sourceClasses)
    & $javac --release 7 -d $sourceClasses (Join-Path $testRoot 'Mat.java') (Join-Path $testRoot 'LoadingRotationTest.java') $source
    if ($LASTEXITCODE -ne 0) { throw 'Test harness compilation failed.' }
    $legacyClasses = Join-Path $runRoot 'packaged-classes'
    $helperPath = Join-Path $legacyClasses 'com\maddox\il2\engine\OpenSturmovikLoadingRotation.class'
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $helperPath))
    $helperEntry = @($packaged.classes | Where-Object { $_.class -eq 'com.maddox.il2.engine.OpenSturmovikLoadingRotation' })
    if ($helperEntry.Count -ne 1) { throw 'Expected one packaged loading rotation helper.' }
    Copy-Item -LiteralPath (Join-Path $package ([string]$helperEntry[0].path)) -Destination $helperPath
    foreach ($variant in @('source', 'packaged-java47')) {
        $classpath = if ($variant -eq 'source') { $sourceClasses } else { $legacyClasses + [IO.Path]::PathSeparator + $sourceClasses }
        $fixtures = Join-Path $runRoot ($variant + '-fixtures')
        $log = Join-Path $runRoot ($variant + '.log')
        & $java -Xverify:all -cp $classpath com.maddox.il2.engine.LoadingRotationTest $fixtures | Tee-Object -FilePath $log
        $exitCode = $LASTEXITCODE
        $reportPath = Join-Path $fixtures 'result.properties'
        $details = if (Test-Path -LiteralPath $reportPath -PathType Leaf) { Get-Content -LiteralPath $reportPath -Raw } else { '' }
        $result = if ($exitCode -eq 0 -and $details -match '(?m)^result=PASS\r?$') { 'PASS' } else { 'FAIL' }
        $assertions = if ($details -match '(?m)^assertions=(\d+)\r?$') { [int]$Matches[1] } else { 0 }
        $passed = if ($details -match '(?m)^passed=(\d+)\r?$') { [int]$Matches[1] } else { 0 }
        $results += [ordered]@{ variant=$variant; result=$result; assertions=$assertions; passed=$passed; exitCode=$exitCode; report=$reportPath; log=$log }
    }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $sourceHash) { throw 'Helper source changed during testing.' }
} finally {
    Set-Location -LiteralPath $oldLocation.Path
    $failed = @($results | Where-Object { $_.result -ne 'PASS' })
    $summary = [ordered]@{
        schemaVersion=1; dateUtc=[DateTime]::UtcNow.ToString('o'); repositoryRoot=$root; branch=$branch
        sourceSha256=$sourceHash; javac=$javac; java=$java; verification='-Xverify:all'
        gameLaunched=$false; nativeRenderingValidated=$false; legacyIl2JvmExecuted=$false
        result=$(if ($results.Count -eq 2 -and $failed.Count -eq 0) { 'PASS' } else { 'FAIL' }); variants=$results
    }
    $summaryPath = Join-Path $runRoot 'result.json'
    [IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 7), (New-Object Text.UTF8Encoding($false)))
}
if ($summary.result -ne 'PASS') { throw "Loading rotation tests failed. See $summaryPath" }
[pscustomobject]@{ Result='PASS'; Variants=2; Report=$summaryPath; GameLaunched=$false; LegacyIl2JvmExecuted=$false }
