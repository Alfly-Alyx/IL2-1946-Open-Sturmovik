#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$OutputDirectory,
    [string]$PackageRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $root 'build\loading-rotation-patch' }

function Resolve-BuildDestination([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $root $Path }
    $resolved = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if (-not $resolved.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Build outputs must remain inside the assigned repository.'
    }
    $activeFiles = Join-Path $root 'Files'
    if ($resolved.Equals($activeFiles, [StringComparison]::OrdinalIgnoreCase) -or
        $resolved.StartsWith($activeFiles + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The builder never deploys into active game Files.'
    }
    $cursor = $resolved
    while ($cursor.Length -ge $root.Length) {
        if ((Test-Path -LiteralPath $cursor) -and
            ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Build destinations through reparse points are not supported.'
        }
        if ($cursor -eq $root) { break }
        $cursor = Split-Path -Parent $cursor
    }
    return $resolved
}

function Invoke-BuildCommand([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Build command failed: $Executable" }
}

function Write-BuildUtf8([string]$Path, [string]$Text) {
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

$output = Resolve-BuildDestination $OutputDirectory
$package = ''
if (-not [string]::IsNullOrWhiteSpace($PackageRoot)) { $package = Resolve-BuildDestination $PackageRoot }
$sourceConsole = Join-Path $root 'test-assets\loading-rotation\ConsoleGL0.class'
$sourceProvenance = Join-Path $root 'test-assets\loading-rotation\ConsoleGL0.provenance.json'
$sourceHelper = Join-Path $root 'tools\java\loading-rotation\com\maddox\il2\engine\OpenSturmovikLoadingRotation.java'
$sourcePatcher = Join-Path $root 'tools\java\OpenSturmovikLoadingRotationPatcher.java'
$expectedConsoleHash = '1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C'
foreach ($path in @($sourceConsole, $sourceProvenance, $sourceHelper, $sourcePatcher)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required build source missing: $path" }
}
if ((Get-FileHash -LiteralPath $sourceConsole).Hash -ne $expectedConsoleHash) { throw 'ConsoleGL0 source is not the verified version.' }
$provenance = Get-Content -LiteralPath $sourceProvenance -Raw | ConvertFrom-Json
if ($provenance.sha256 -ne $expectedConsoleHash -or $provenance.javaMajor -ne 47) { throw 'Source provenance mismatch.' }
$helperSourceHash = (Get-FileHash -LiteralPath $sourceHelper).Hash
$patcherSourceHash = (Get-FileHash -LiteralPath $sourcePatcher).Hash
$javac = (Get-Command javac -ErrorAction Stop).Source
$java = (Get-Command java -ErrorAction Stop).Source
$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.commons=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree.analysis=ALL-UNNAMED'
)
$patcherClasses = Join-Path $output 'patcher'
$compiledClasses = Join-Path $output 'compiled'
$classRoot = Join-Path $output 'classes'
$looseRoot = Join-Path $output 'Files'
foreach ($directory in @($output, $patcherClasses, $compiledClasses, $classRoot, $looseRoot)) {
    [void][IO.Directory]::CreateDirectory($directory)
}
$stubPath = Join-Path $output 'stubs\com\maddox\il2\engine\Mat.java'
Write-BuildUtf8 $stubPath 'package com.maddox.il2.engine; public class Mat { public static Mat New(String name) { return null; } }'
Invoke-BuildCommand $javac ($exports + @('-g:none', '-d', $patcherClasses, $sourcePatcher))
Invoke-BuildCommand $javac @('-source', '7', '-target', '7', '-g:none', '-d', $compiledClasses, $stubPath, $sourceHelper)
$helperDirectory = Join-Path $compiledClasses 'com\maddox\il2\engine'
$helperOutputs = @(Get-ChildItem -LiteralPath $helperDirectory -File -Filter 'OpenSturmovikLoadingRotation*.class')
if ($helperOutputs.Count -ne 1 -or $helperOutputs[0].Name -ne 'OpenSturmovikLoadingRotation.class') {
    throw 'Unexpected helper inner classes: each class needs its own SFS mapping.'
}
$outputConsole = Join-Path $classRoot 'com\maddox\il2\engine\ConsoleGL0.class'
$outputHelper = Join-Path $classRoot 'com\maddox\il2\engine\OpenSturmovikLoadingRotation.class'
Invoke-BuildCommand $java ($exports + @('-cp', $patcherClasses, 'OpenSturmovikLoadingRotationPatcher', 'patch', $sourceConsole, $outputConsole))
Invoke-BuildCommand $java ($exports + @('-cp', $patcherClasses, 'OpenSturmovikLoadingRotationPatcher', 'legacy', $helperOutputs[0].FullName, $outputHelper))
if ((Get-FileHash -LiteralPath $sourceHelper).Hash -ne $helperSourceHash -or
    (Get-FileHash -LiteralPath $sourcePatcher).Hash -ne $patcherSourceHash) {
    throw 'Build sources changed during compilation; rebuild from a stable source.'
}
# Names independently calculated with tools/Analyze-Sfs.py:
# finger_string(0, 'cod/' + finger_int('sdw' + dottedClassName + 'cwc2w9e')).
$mapping = @(
    [pscustomobject]@{ Class = 'com.maddox.il2.engine.ConsoleGL0'; Name = 'B96FAC8E2C4DDBE0'; Source = $outputConsole },
    [pscustomobject]@{ Class = 'com.maddox.il2.engine.OpenSturmovikLoadingRotation'; Name = 'F35AD7F42DE76ABC'; Source = $outputHelper }
)
$entries = @()
foreach ($item in $mapping) {
    $bytes = [IO.File]::ReadAllBytes($item.Source)
    $major = ([int]$bytes[6] -shl 8) -bor [int]$bytes[7]
    if ($major -ne 47) { throw "Unexpected Java version: $($item.Class)" }
    $loosePath = Join-Path $looseRoot $item.Name
    [IO.File]::Copy($item.Source, $loosePath, $true)
    $entries += [ordered]@{
        class = $item.Class
        looseName = $item.Name
        path = 'Files/' + $item.Name
        size = $bytes.Length
        javaMajor = $major
        sha256 = (Get-FileHash -LiteralPath $loosePath).Hash
    }
}
$manifest = [ordered]@{
    schemaVersion = 1
    kind = 'open-sturmovik-loading-rotation-patch'
    target = 'Open Sturmovik v1.15; verified ConsoleGL0 shared by modded 4.08m, 4.09b and 4.09m'
    sourceClassSha256 = $expectedConsoleHash
    helperSourceSha256 = $helperSourceHash
    patcherSourceSha256 = $patcherSourceHash
    classes = $entries
}
$manifestText = ($manifest | ConvertTo-Json -Depth 8) + [Environment]::NewLine
Write-BuildUtf8 (Join-Path $output 'manifest.json') $manifestText
if ($package) {
    $packageFiles = Join-Path $package 'Files'
    [void][IO.Directory]::CreateDirectory($packageFiles)
    foreach ($item in $mapping) {
        $from = Join-Path $looseRoot $item.Name
        $to = Join-Path $packageFiles $item.Name
        [IO.File]::Copy($from, $to, $true)
        if ((Get-FileHash -LiteralPath $from).Hash -ne (Get-FileHash -LiteralPath $to).Hash) { throw 'Packaged class copy failed verification.' }
    }
    Write-BuildUtf8 (Join-Path $package 'manifest.json') $manifestText
}
Write-Host "Built two Java 1.3 classes and manifest in $output. No active game files changed."
