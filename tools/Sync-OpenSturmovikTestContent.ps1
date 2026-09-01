[CmdletBinding()]
param(
    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot),
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [string]$PlanPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifests\test\v1.15-test-sync.json'),
    [string]$BackupRoot,
    [string]$ProtectedReferenceRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946',
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
function Restore-Sync {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[string]]$Created,
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[string]]$BackedUp,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Backup
    )
    foreach ($relative in $Created) {
        $target = Join-Path $Destination $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
    }
    foreach ($relative in $BackedUp) {
        $saved = Join-Path $Backup $relative
        $target = Join-Path $Destination $relative
        if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
        $parent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Move-Item -LiteralPath $saved -Destination $target -Force
    }
}

$source = (Resolve-Path -LiteralPath $SourceRoot -ErrorAction Stop).Path.TrimEnd('\')
$destination = (Resolve-Path -LiteralPath $DestinationRoot -ErrorAction Stop).Path.TrimEnd('\')
$planFile = (Resolve-Path -LiteralPath $PlanPath -ErrorAction Stop).Path
$protected = (Resolve-Path -LiteralPath $ProtectedReferenceRoot -ErrorAction Stop).Path.TrimEnd('\')
if ($source -ieq $destination) { throw 'La source et la destination doivent etre distinctes.' }
if ($destination -ieq $protected) { throw 'Refus absolu de modifier le jeu original protege.' }
$destinationItem = Get-Item -LiteralPath $destination -Force
if ($destinationItem.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'La destination de test ne doit pas etre un lien ou une redirection.'
}
if (@(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'IL-2 est actif. Fermer le jeu avant toute synchronisation.'
}

$plan = Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json
if ($plan.schema -ne 1) { throw 'Version de plan non prise en charge.' }
if ($plan.source_root -ine $source -or $plan.destination_root -ine $destination) {
    throw 'Le plan ne correspond pas aux dossiers source et destination demandes.'
}

$pending = New-Object System.Collections.Generic.List[object]
$already = 0
foreach ($entry in $plan.entries) {
    $relative = $entry.path.Replace('/', '\')
    if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains('..')) {
        throw "Chemin non sur dans le plan : $relative"
    }
    $target = Join-Path $destination $relative
    $targetPresent = Test-Path -LiteralPath $target -PathType Leaf
    if ($entry.action -eq 'copy') {
        $from = Join-Path $source $relative
        if (-not (Test-Path -LiteralPath $from -PathType Leaf)) { throw "Source absente : $relative" }
        $sourceHash = Get-Sha256 $from
        if ($sourceHash -ne $entry.source_sha256) { throw "Source modifiee depuis le plan : $relative" }
        if ($targetPresent -and (Get-Sha256 $target) -eq $sourceHash) { $already++; continue }
    }
    elseif ($entry.action -eq 'remove') {
        if (-not $targetPresent) { $already++; continue }
    }
    else { throw "Action inconnue : $($entry.action)" }

    if ([bool]$entry.destination_before_present -ne $targetPresent) {
        throw "Etat de destination different du plan : $relative"
    }
    if ($targetPresent -and (Get-Sha256 $target) -ne $entry.destination_before_sha256) {
        throw "La destination a change depuis le plan : $relative"
    }
    $pending.Add($entry) | Out-Null
}

Write-Host "Plan valide : $($pending.Count) operation(s), $already deja conforme(s)." -ForegroundColor Green
if (-not $Apply) {
    Write-Host 'Simulation seulement : aucun fichier du jeu de test n a ete modifie.' -ForegroundColor Yellow
    return
}

if (-not $BackupRoot) {
    $BackupRoot = $destination + '.sync-backup-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
}
$backup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
if (Test-Path -LiteralPath $backup) { throw "La sauvegarde existe deja : $backup" }
if ([IO.Path]::GetDirectoryName($backup) -ine [IO.Path]::GetDirectoryName($destination)) {
    throw 'La sauvegarde doit rester a cote du dossier de test.'
}

$created = New-Object 'System.Collections.Generic.List[string]'
$backedUp = New-Object 'System.Collections.Generic.List[string]'
New-Item -ItemType Directory -Path $backup -Force | Out-Null
try {
    foreach ($entry in $pending) {
        $relative = $entry.path.Replace('/', '\')
        $target = Join-Path $destination $relative
        $targetParent = Split-Path -Parent $target
        if (-not (Test-Path -LiteralPath $targetParent)) { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $saved = Join-Path $backup $relative
            $savedParent = Split-Path -Parent $saved
            if (-not (Test-Path -LiteralPath $savedParent)) { New-Item -ItemType Directory -Path $savedParent -Force | Out-Null }
            Move-Item -LiteralPath $target -Destination $saved
            $backedUp.Add($relative) | Out-Null
        }
        else { $created.Add($relative) | Out-Null }

        if ($entry.action -eq 'copy') {
            $from = Join-Path $source $relative
            $temporary = Join-Path $targetParent ('.' + [IO.Path]::GetFileName($target) + '.open-sturmovik-new')
            Copy-Item -LiteralPath $from -Destination $temporary -Force
            Move-Item -LiteralPath $temporary -Destination $target -Force
        }
    }

    $validator = Join-Path $source 'tools\Test-OpenSturmovikContent.ps1'
    & $validator -ProjectRoot $source -ContentRoot $destination | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'La validation fonctionnelle apres synchronisation a echoue.' }

    [ordered]@{
        applied_utc = [DateTime]::UtcNow.ToString('O')
        plan = $planFile
        destination = $destination
        operations = $pending.Count
        backed_up = @($backedUp)
        created = @($created)
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backup 'sync-receipt.json') -Encoding UTF8
    Write-Host "Synchronisation validee. Sauvegarde recuperable : $backup" -ForegroundColor Green
}
catch {
    Restore-Sync -Created $created -BackedUp $backedUp -Destination $destination -Backup $backup
    throw "Synchronisation annulee et fichiers precedents restaures. $($_.Exception.Message)"
}
