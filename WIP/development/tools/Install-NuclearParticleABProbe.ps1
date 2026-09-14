[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TestRoot,
    [switch]$Disable
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$target = [IO.Path]::GetFullPath($TestRoot)
$forbidden = [IO.Path]::GetFullPath((Join-Path $root 'D:\Projets\GITHUB\#res\IL2 1946\0 - ORIGINAL GAMES DO NOT MODIFIED\Il-2 Sturmovik 1946 _4.09m'))
if ($target.TrimEnd('\') -ieq $forbidden.TrimEnd('\')) {
    throw 'Le jeu original est strictement interdit comme cible.'
}
if (-not (Test-Path -LiteralPath (Join-Path $target 'il2fb.exe') -PathType Leaf)) {
    throw "La cible ne ressemble pas a une installation IL-2 : $target"
}
if ([IO.Path]::GetFileName($target) -notlike '*test*') {
    throw "La cible doit etre explicitement un dossier de test : $target"
}

$marker = Join-Path $target '_OS_TEST_NUCLEAR_PARTICLE_AB.enabled'
if ($Disable) {
    if (Test-Path -LiteralPath $marker -PathType Leaf) {
        Remove-Item -LiteralPath $marker -Force
    }
    [pscustomobject]@{ TestRoot = $target; Enabled = $false; Marker = $marker }
    return
}

$source = Join-Path $root 'test-assets\nuclear-particle-ab'
$classes = @(
    '5AC49B8080496790',
    '8D53953C1956F06A',
    '51AD1FEC90031C8A',
    'ABFC6F18761EB542'
)
$files = @(
    'NuclearParticleCapacity-A.eff',
    'NuclearParticleCapacity-B.eff'
)
$payload = [Collections.Generic.List[object]]::new()
foreach ($name in $classes) {
    $payload.Add([pscustomobject]@{
        Relative = Join-Path 'Files' $name
        Source = Join-Path (Join-Path $root 'Files') $name
        Target = Join-Path (Join-Path $target 'Files') $name
        Existed = $false
    })
}
foreach ($name in $files) {
    $relative = Join-Path 'Files\3do\Effects\OpenSturmovikTest' $name
    $payload.Add([pscustomobject]@{
        Relative = $relative
        Source = Join-Path $source $name
        Target = Join-Path $target $relative
        Existed = $false
    })
}
$payload.Add([pscustomobject]@{
    Relative = '_OS_TEST_NUCLEAR_PARTICLE_AB.enabled'
    Source = Join-Path $source '_OS_TEST_NUCLEAR_PARTICLE_AB.enabled'
    Target = $marker
    Existed = $false
})

foreach ($item in $payload) {
    if (-not (Test-Path -LiteralPath $item.Source -PathType Leaf)) {
        throw "Payload de sonde absent : $($item.Source)"
    }
}

$backup = $target.TrimEnd('\') + '.nuclear-particle-ab-backup-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ')
[IO.Directory]::CreateDirectory($backup) | Out-Null
foreach ($item in $payload) {
    if (Test-Path -LiteralPath $item.Target -PathType Leaf) {
        $item.Existed = $true
        $backupFile = Join-Path $backup $item.Relative
        [IO.Directory]::CreateDirectory((Split-Path -Parent $backupFile)) | Out-Null
        Copy-Item -LiteralPath $item.Target -Destination $backupFile -Force
    }
}

try {
    foreach ($item in $payload) {
        [IO.Directory]::CreateDirectory((Split-Path -Parent $item.Target)) | Out-Null
        Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force
        $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.Source).Hash
        $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.Target).Hash
        if ($sourceHash -ne $targetHash) {
            throw "Copie non conforme : $($item.Target)"
        }
    }
}
catch {
    foreach ($item in $payload) {
        $backupFile = Join-Path $backup $item.Relative
        if ($item.Existed -and (Test-Path -LiteralPath $backupFile -PathType Leaf)) {
            Copy-Item -LiteralPath $backupFile -Destination $item.Target -Force
        }
        elseif (Test-Path -LiteralPath $item.Target -PathType Leaf) {
            Remove-Item -LiteralPath $item.Target -Force
        }
    }
    throw
}

$hashes = foreach ($item in $payload) {
    [ordered]@{
        file = $item.Target
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.Target).Hash
    }
}

[pscustomobject]@{
    TestRoot = $target
    Enabled = $true
    Marker = $marker
    Backup = $backup
    Classes = $classes
    Payload = $hashes
}
