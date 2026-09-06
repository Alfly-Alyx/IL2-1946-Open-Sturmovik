[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$InstallationRoot = (Split-Path -Parent $PSScriptRoot),

    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\manifests\utilities-v1.15.json'),

    [string]$DesktopPath,

    [switch]$AllUsers,

    [string]$DeviceLinkAddress,

    [switch]$SkipDeviceLink,

    [switch]$SkipZipNavMaps,

    [switch]$SkipUtilityInitialization
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($InstallationRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Dossier d'installation introuvable : $root"
}
if (-not (Test-Path -LiteralPath (Join-Path $root 'il2fb.exe') -PathType Leaf)) {
    throw "La mise a jour v1.15 doit etre finalisee dans le dossier contenant il2fb.exe : $root"
}

$initializerPath = Join-Path $PSScriptRoot 'Initialize-OpenSturmovikUtilities.ps1'
$shortcutInstallerPath = Join-Path $PSScriptRoot 'Install-OpenSturmovikUtilityShortcuts.ps1'
# Existing pilots, including unchanged stock identities, belong to the player.
# Update finalization must never migrate or recreate anything under Users.
foreach ($requiredScript in @($initializerPath, $shortcutInstallerPath)) {
    if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
        throw "Etape de finalisation v1.15 absente : $requiredScript"
    }
}

$initializerResult = $null
if (-not $SkipUtilityInitialization) {
    $initializerParameters = @{
        InstallationRoot = $root
        SkipDeviceLink = $SkipDeviceLink
        SkipZipNavMaps = $SkipZipNavMaps
    }
    if ($PSBoundParameters.ContainsKey('DeviceLinkAddress')) {
        $initializerParameters.DeviceLinkAddress = $DeviceLinkAddress
    }
    if ($WhatIfPreference) {
        $initializerParameters.WhatIf = $true
    }

    $initializerResult = & $initializerPath @initializerParameters
}

$shortcutParameters = @{
    InstallationRoot = $root
    ManifestPath = $ManifestPath
}
if ($AllUsers) {
    $shortcutParameters.AllUsers = $true
}
elseif ($PSBoundParameters.ContainsKey('DesktopPath')) {
    $shortcutParameters.DesktopPath = $DesktopPath
}
if ($WhatIfPreference) {
    $shortcutParameters.WhatIf = $true
}

$shortcutResults = @(& $shortcutInstallerPath @shortcutParameters)
$expectedShortcutStatus = if ($WhatIfPreference) { 'SIMULE' } else { 'INSTALLE' }
$incompleteShortcuts = @($shortcutResults | Where-Object Status -ne $expectedShortcutStatus)
if ($shortcutResults.Count -ne 10 -or $incompleteShortcuts.Count -gt 0) {
    throw "La finalisation v1.15 n'a pas installe les dix raccourcis attendus : comptes=$($shortcutResults.Count), incomplets=$($incompleteShortcuts.Count)."
}

[pscustomobject]@{
    Release = '1.15'
    InstallationRoot = $root
    UtilityInitialization = if ($SkipUtilityInitialization) { 'IGNORE' } else { $initializerResult.Status }
    ShortcutCount = $shortcutResults.Count
    ShortcutScope = if ($AllUsers) { 'TOUS_LES_UTILISATEURS' } else { 'UTILISATEUR_COURANT' }
    Status = if ($WhatIfPreference) { 'SIMULATION' } else { 'FINALISE' }
}
