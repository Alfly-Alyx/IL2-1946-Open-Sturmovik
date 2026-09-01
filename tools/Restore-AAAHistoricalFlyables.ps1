[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$AAARoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$aaa = (Resolve-Path -LiteralPath $AAARoot).Path
$manifestPath = Join-Path $root 'manifests\aircraft\aaa-community-cockpits-v1.15.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Manifeste AAA absent : $manifestPath"
}
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ([string]$manifest.aaa_root -ne $aaa) {
    throw "La source ne correspond pas au manifeste : attendu=$($manifest.aaa_root), recu=$aaa"
}

function Get-Sha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

$operations = [Collections.Generic.List[object]]::new()
foreach ($packageName in @('TBF-1C', 'TBM-3')) {
    $package = $manifest.candidate_packages.$packageName
    if ($null -eq $package) { throw "Paquet absent du manifeste : $packageName" }
    foreach ($class in $package.classes) {
        $source = [string]$class.source
        $operations.Add([pscustomobject]@{
            Source = $source
            Target = Join-Path $root "Files\$([IO.Path]::GetFileName($source))"
            Sha256 = [string]$class.sha256
            Provenance = $packageName
        })
    }
    foreach ($resource in $package.resources) {
        $relative = ([string]$resource.relative_path).Replace('/', '\')
        $operations.Add([pscustomobject]@{
            Source = Join-Path ([string]$package.root) $relative
            Target = Join-Path $root "Files\$relative"
            Sha256 = [string]$resource.sha256
            Provenance = $packageName
        })
    }
}

$aces = $manifest.candidate_packages.ACES
$mig = @($aces.classes | Where-Object internal_class -eq 'com/maddox/il2/objects/air/MIG_3POKRYSHKIN')
if ($mig.Count -ne 1) { throw "Classe AAA MIG_3POKRYSHKIN ambigue ou absente : $($mig.Count)" }
$operations.Add([pscustomobject]@{
    Source = [string]$mig[0].source
    Target = Join-Path $root "Files\$([IO.Path]::GetFileName([string]$mig[0].source))"
    Sha256 = [string]$mig[0].sha256
    Provenance = 'ACES/MIG_3POKRYSHKIN uniquement'
})

$duplicateTargets = @($operations | Group-Object Target | Where-Object Count -gt 1)
if ($duplicateTargets.Count -gt 0) {
    throw "Cibles dupliquees : $($duplicateTargets.Name -join ', ')"
}
foreach ($operation in $operations) {
    if (-not (Test-Path -LiteralPath $operation.Source -PathType Leaf)) {
        throw "Source absente : $($operation.Source)"
    }
    $actual = Get-Sha256 $operation.Source
    if ($actual -ne $operation.Sha256) {
        throw "Source modifiee : $($operation.Source), attendu=$($operation.Sha256), actuel=$actual"
    }
    $targetFull = [IO.Path]::GetFullPath([string]$operation.Target)
    $filesFull = [IO.Path]::GetFullPath((Join-Path $root 'Files')) + [IO.Path]::DirectorySeparatorChar
    if (-not $targetFull.StartsWith($filesFull, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Cible hors de Files : $targetFull"
    }
}

if (-not $PSCmdlet.ShouldProcess("$($operations.Count) fichiers", 'Restaurer les ensembles flyable AAA verifies')) {
    $operations | Select-Object Provenance,Source,Target,Sha256
    return
}

$backupRoot = Join-Path ([IO.Path]::GetTempPath()) ("open-sturmovik-aaa-rollback-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $backupRoot | Out-Null
$completed = [Collections.Generic.List[object]]::new()
try {
    for ($index = 0; $index -lt $operations.Count; $index++) {
        $operation = $operations[$index]
        $target = [string]$operation.Target
        $backup = Join-Path $backupRoot ("{0:D3}.bak" -f $index)
        $existed = Test-Path -LiteralPath $target -PathType Leaf
        if ($existed) { Copy-Item -LiteralPath $target -Destination $backup }
        $parent = Split-Path -Parent $target
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $operation.Source -Destination $target -Force
        if ((Get-Sha256 $target) -ne $operation.Sha256) {
            throw "Verification apres copie en echec : $target"
        }
        $completed.Add([pscustomobject]@{ Target = $target; Backup = $backup; Existed = $existed })
    }
}
catch {
    $rollbackItems = @($completed)
    [array]::Reverse($rollbackItems)
    foreach ($item in $rollbackItems) {
        if ($item.Existed) { Copy-Item -LiteralPath $item.Backup -Destination $item.Target -Force }
        elseif (Test-Path -LiteralPath $item.Target -PathType Leaf) { Remove-Item -LiteralPath $item.Target -Force }
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $backupRoot) { Remove-Item -LiteralPath $backupRoot -Recurse -Force }
}

$operations | Select-Object Provenance,Target,Sha256
"Restauration AAA : PASS ($($operations.Count) fichiers)"
