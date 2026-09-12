[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$StockExplosions,
    [Parameter(Mandatory = $true)][string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$source = (Resolve-Path -LiteralPath $SourceRoot).Path
$baseline = (Resolve-Path -LiteralPath $StockExplosions).Path
$output = [IO.Path]::GetFullPath($OutputRoot)
if ($output.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Choisir un dossier de sortie de tache hors du depot partage.'
}
if ((Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash -ne '1D5AAA0B19AED7BA95C4B0122C5B277712BF38E3F0CCA5307724A22DC4917891') {
    throw 'La reference Explosions 4.09m ne correspond pas au SFS verifie.'
}
$java = (Get-Command java -ErrorAction Stop).Source
$javac = (Get-Command javac -ErrorAction Stop).Source
$compiled = Join-Path $output 'patcher'
$candidate = Join-Path $output 'classes'
$staging = Join-Path $output 'files-staging'
foreach ($directory in @($compiled, $candidate, $staging)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}
$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree.analysis=ALL-UNNAMED'
)
$patcher = Join-Path $root 'tools\java\OpenSturmovikControlsExplosionsPatcher.java'
$test = Join-Path $root 'tools\java\TestControlsExplosionsNoMds.java'
& $javac @exports -d $compiled $patcher $test
if ($LASTEXITCODE -ne 0) { throw 'Compilation du correctif impossible.' }
$controls = Join-Path $source 'Files\34B2D47E9F860052'
$explosions = Join-Path $source 'Files\72DCDDF4D2AD25E8'
& $java @exports -cp $compiled OpenSturmovikControlsExplosionsPatcher $controls $explosions $candidate
if ($LASTEXITCODE -ne 0) { throw 'Construction ou analyse du bytecode impossible.' }
& $java @exports -cp $compiled TestControlsExplosionsNoMds (Join-Path $candidate 'Controls.class') (Join-Path $candidate 'Explosions.class') $baseline
if ($LASTEXITCODE -ne 0) { throw 'Les tests des classes reconstruites ont echoue.' }
$mapping = [ordered]@{
    'Controls.class' = '34B2D47E9F860052'
    'Explosions.class' = '72DCDDF4D2AD25E8'
}
$entries = @(
    foreach ($entry in $mapping.GetEnumerator()) {
        $destination = Join-Path $staging $entry.Value
        Copy-Item -LiteralPath (Join-Path $candidate $entry.Key) -Destination $destination -Force
        $bytes = [IO.File]::ReadAllBytes($destination)
        [ordered]@{
            class = $entry.Key
            runtimePath = 'Files/' + $entry.Value
            sourceSha256 = (Get-FileHash -LiteralPath (Join-Path $source ('Files\' + $entry.Value)) -Algorithm SHA256).Hash
            sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
            javaMajor = ($bytes[6] -shl 8) -bor $bytes[7]
            javaMinor = ($bytes[4] -shl 8) -bor $bytes[5]
        }
    }
)
[ordered]@{
    schema = 'open-sturmovik-controls-explosions-no-mds-v1'
    installed = $false
    sourceRoot = $source
    stockExplosionsSha256 = (Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash
    tests = @('ASM BasicVerifier all methods', 'Unrelated methods unchanged', 'No MDS constants', 'Real door bytecode JVM test', 'Stock fountain equivalence with local-slot normalization')
    classes = $entries
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $output 'manifest.json') -Encoding UTF8
[pscustomobject]@{ Staging = $staging; Manifest = (Join-Path $output 'manifest.json'); Installed = $false }
