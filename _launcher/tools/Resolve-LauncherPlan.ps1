[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$ProjectRoot,
    [string]$VisualQuality,
    [ValidateSet('classic', 'six-dof')]
    [string]$ViewMode,
    [string[]]$Realism = @(),
    [switch]$TechnicalDetails
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $ProjectRoot '_launcher\manifests\open-sturmovik-1.15.json'
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
if (-not $VisualQuality) { $VisualQuality = [string]$manifest.defaults.visualQuality }
if (-not $ViewMode) { $ViewMode = [string]$manifest.defaults.viewMode }

function Get-OneById {
    param([object[]]$Items, [string]$Id, [string]$Context)

    $matches = @($Items | Where-Object id -eq $Id)
    if ($matches.Count -ne 1) {
        throw "$Context inconnu : $Id"
    }
    return $matches[0]
}

function Assert-Available {
    param($Item, [string]$Context)

    if ([string]$Item.availability -ne 'available') {
        $reason = if ([string]::IsNullOrWhiteSpace([string]$Item.reason)) {
            'Ce choix n est pas encore disponible.'
        }
        else {
            [string]$Item.reason
        }
        throw "$Context indisponible : $reason"
    }
}

$quality = Get-OneById @($manifest.visualQuality) $VisualQuality 'Palier visuel'
Assert-Available $quality 'Palier visuel'

$viewCapability = Get-OneById @($manifest.capabilities) 'view.mode' 'Capacite de vue'
$view = Get-OneById @($viewCapability.options) $ViewMode 'Mode de vue'
Assert-Available $view 'Mode de vue'

$profile = Get-OneById @($manifest.profiles) ([string]$view.profile) 'Profil de jeu'
Assert-Available $profile 'Profil de jeu'

$realismChoices = New-Object System.Collections.Generic.List[object]
foreach ($realismId in @($Realism)) {
    $capability = Get-OneById @($manifest.capabilities) $realismId 'Reglage de realisme'
    if ($capability.category -ne 'realism') {
        throw "Le choix $realismId n est pas un reglage de realisme."
    }
    Assert-Available $capability 'Reglage de realisme'
    $realismChoices.Add($capability)
}

$plan = [ordered]@{
    readyToApply = $true
    game = [string]$manifest.product.name
    version = [string]$manifest.product.targetVersion
    summary = [ordered]@{
        visualQuality = [string]$quality.userLabel
        view = [string]$view.userLabel
        realism = @($realismChoices | ForEach-Object { [string]$_.userLabel })
    }
    safeguards = [ordered]@{
        confirmationRequired = [bool]$manifest.integrity.repair.requiresConfirmation
        verifyBeforeAndAfter = $true
        rollbackOnFailure = [bool]$manifest.integrity.repair.rollbackOnFailure
        preservePlayerCommands = [bool]$manifest.keyMapping.preserveUnknownEntries
    }
}

if ($TechnicalDetails) {
    $plan.technical = [ordered]@{
        profileId = [string]$profile.id
        visualQualityId = [string]$quality.id
        viewModeId = [string]$view.id
        files = @($profile.files | ForEach-Object {
            [ordered]@{
                source = [string]$_.source
                target = [string]$_.target
                size = [long]$_.size
                sha256 = [string]$_.sha256
            }
        })
    }
}

$plan | ConvertTo-Json -Depth 10
