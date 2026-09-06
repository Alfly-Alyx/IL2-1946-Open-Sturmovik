[CmdletBinding()]
param(
    [string]$OutputRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build\aoc-zuti-v1.15'),
    [switch]$Apply
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$fixtures = Join-Path $root 'test-assets\aoc-v1.15'
$base = Join-Path $fixtures 'base-zuti'
$donor = Join-Path $fixtures 'donor-hsfx4'
$output = [IO.Path]::GetFullPath($OutputRoot)
$patcherClasses = Join-Path $output 'patcher'
$classes = Join-Path $output 'classes'
$staging = Join-Path $output 'Files'

$sourceHashes = [ordered]@{
    'base-zuti\294ABC86A89FAEB4' = 'E3A0842D8A8BAFA37AC32F5AED5F6AAA72A97A4D54C3628964692504B4F647AD'
    'base-zuti\684916A0E86D1CC8' = '8506C75A6FC08982E4F49AA6CE864FE7BCA1161679A5CDDDF1028AF5309958C0'
    'base-zuti\AF5F8A326C3FA53C' = 'C8A1A02BC941E00858F6835A3ECB95DDA5BAD0504B5105A33893AE98F7822E7B'
    'donor-hsfx4\294ABC86A89FAEB4' = '4A405EBFB303FBD5F20D1B5B89FA69A76715F08DAE11387B4D2933F3A4A1EC18'
    'donor-hsfx4\684916A0E86D1CC8' = '3FA99502A9E616FFD2B41608D3BFBC7C3EF58407BD370AD673EC9B0711ABDD30'
    'donor-hsfx4\AF5F8A326C3FA53C' = 'B22731A2DCB126CEA6E0EB22E44C4C26503961FD8CDD8A1E6C439DF02448871D'
}

foreach ($entry in $sourceHashes.GetEnumerator()) {
    $path = Join-Path $fixtures $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Source AOC/Zuti absente : $path"
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actual -ne $entry.Value) {
        throw "Source AOC/Zuti non reconnue : $($entry.Key); attendu $($entry.Value), obtenu $actual."
    }
}

foreach ($directory in @($output, $patcherClasses, $classes, $staging)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}

$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree.analysis=ALL-UNNAMED'
)
$javac = (Get-Command javac -ErrorAction Stop).Source
$java = (Get-Command java -ErrorAction Stop).Source
$patcherSource = Join-Path $root 'tools\java\OpenSturmovikAocZutiPatcher.java'

& $javac @exports -d $patcherClasses $patcherSource
if ($LASTEXITCODE -ne 0) {
    throw "Compilation du constructeur AOC/Zuti impossible (code $LASTEXITCODE)."
}

& $java @exports -cp $patcherClasses OpenSturmovikAocZutiPatcher `
    (Join-Path $base '294ABC86A89FAEB4') `
    (Join-Path $base 'AF5F8A326C3FA53C') `
    (Join-Path $base '684916A0E86D1CC8') `
    (Join-Path $donor 'AF5F8A326C3FA53C') `
    $classes
if ($LASTEXITCODE -ne 0) {
    throw "Construction du correctif AOC/Zuti impossible (code $LASTEXITCODE)."
}

$mapping = [ordered]@{
    'FlightModelMain.class' = '294ABC86A89FAEB4'
    'RealFlightModel.class' = '684916A0E86D1CC8'
    'Motor.class' = 'AF5F8A326C3FA53C'
}

$results = @()
foreach ($entry in $mapping.GetEnumerator()) {
    $compiled = Join-Path $classes $entry.Key
    $loose = Join-Path $staging $entry.Value
    Copy-Item -LiteralPath $compiled -Destination $loose -Force
    $bytes = [IO.File]::ReadAllBytes($loose)
    $major = ($bytes[6] -shl 8) -bor $bytes[7]
    if ($major -gt 47) {
        throw "Classe incompatible avec Java 1.3.1 : $($entry.Key), major $major."
    }
    $results += [pscustomobject]@{
        Class = $entry.Key
        LooseName = $entry.Value
        Length = $bytes.Length
        Major = $major
        SHA256 = (Get-FileHash -LiteralPath $loose -Algorithm SHA256).Hash
    }
}

if ($Apply) {
    foreach ($entry in $mapping.GetEnumerator()) {
        Copy-Item -LiteralPath (Join-Path $staging $entry.Value) `
            -Destination (Join-Path $root ('Files\' + $entry.Value)) -Force
    }
}

$results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $output 'aoc-zuti-build.json') -Encoding UTF8
$results | Format-Table -AutoSize
if ($Apply) {
    Write-Host 'Correctif AOC 1a + Zuti 1.13 applique aux trois classes libres.' -ForegroundColor Green
}
else {
    Write-Host 'Correctif construit et valide hors du jeu ; utiliser -Apply pour mettre a jour Files.' -ForegroundColor Green
}
