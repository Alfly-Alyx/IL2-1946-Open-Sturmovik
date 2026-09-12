[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),

    [string]$InstallationRoot,

    [string]$DesktopPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$specRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$root = if ([string]::IsNullOrWhiteSpace($InstallationRoot)) {
    $specRoot
}
else {
    [IO.Path]::GetFullPath($InstallationRoot)
}
$manifestPath = Join-Path $specRoot 'manifests\utilities-v1.15.json'
$installerPath = Join-Path $specRoot 'tools\Install-OpenSturmovikUtilityShortcuts.ps1'
$initializerPath = Join-Path $specRoot 'tools\Initialize-OpenSturmovikUtilities.ps1'
$updateFinalizerPath = Join-Path $specRoot 'tools\Complete-OpenSturmovikV115Update.ps1'

$expectedNames = @(
    'Bombsight Table 2',
    'HardBall 4.08',
    'IL2 Compare',
    'JoyCtrl',
    'Mission Mate 6',
    'WeatherSet',
    'ZipNav',
    'Open Sturmovik Switcher'
)

if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Installateur de raccourcis introuvable : $installerPath"
}

if (-not (Test-Path -LiteralPath $initializerPath -PathType Leaf)) {
    throw "Initialiseur des utilitaires introuvable : $initializerPath"
}

if (-not (Test-Path -LiteralPath $updateFinalizerPath -PathType Leaf)) {
    throw "Finalisation de mise a jour v1.15 introuvable : $updateFinalizerPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.configuration.initializer -ne 'tools\Initialize-OpenSturmovikUtilities.ps1') {
    throw 'Initialiseur incoherent dans le manifeste des utilitaires.'
}
if ($manifest.updateInstaller.finalizer -ne 'tools\Complete-OpenSturmovikV115Update.ps1' -or
    $manifest.updateInstaller.runAfterFilesAreInstalled -ne $true) {
    throw 'Finalisation incoherente dans le manifeste de mise a jour v1.15.'
}

$zipNavMaps = Join-Path $root ([string]$manifest.configuration.zipNav.bundledMaps)
foreach ($mapFile in @('Crimea\map_h.tga', 'Bessarabia\map_h.tga', 'Slovakia\map_h.tga')) {
    if (-not (Test-Path -LiteralPath (Join-Path $zipNavMaps $mapFile) -PathType Leaf)) {
        throw "Carte ZipNav attendue absente : $mapFile"
    }
}

foreach ($missionMateFile in @(
    '_Utilities\Mission Mate 6\FBPath.txt',
    '_Utilities\Mission Mate 6\MisMate.ini',
    '_Utilities\HardBall408\HardBall408.exe'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $missionMateFile) -PathType Leaf)) {
        throw "Composant Mission Mate/HardBall absent : $missionMateFile"
    }
}

$missionMatePolicy = $manifest.configuration.missionMate.modCatalogPolicy
if ($missionMatePolicy.useBundledCatalogForFirstValidation -ne $true -or
    $missionMatePolicy.filesDirectoryMustNotBeExposedAsModsStd -ne $true) {
    throw 'Politique de catalogue Mission Mate incoherente avec le chargement separe de Files.'
}

$bombsightSettings = Join-Path $root ([string]$manifest.configuration.bombsightTable2.settingsFile)
if (-not (Test-Path -LiteralPath $bombsightSettings -PathType Leaf)) {
    throw "Reglages de Bombsight Table 2 absents : $bombsightSettings"
}
$bombsightText = [IO.File]::ReadAllText($bombsightSettings, [Text.Encoding]::GetEncoding(1252))
$expectedBombsightLeft = [int]$manifest.configuration.bombsightTable2.defaultWindowPosition.left
$expectedBombsightTop = [int]$manifest.configuration.bombsightTable2.defaultWindowPosition.top
if ($bombsightText -notmatch "(?m)^Left=$expectedBombsightLeft\s*$" -or
    $bombsightText -notmatch "(?m)^Top=$expectedBombsightTop\s*$") {
    throw 'Position initiale de Bombsight Table 2 incoherente avec le manifeste.'
}

$validation = @(& $installerPath -InstallationRoot $root -ManifestPath $manifestPath -ValidateOnly)
if ($validation.Count -ne $expectedNames.Count) {
    throw "Nombre de raccourcis valide incorrect : $($validation.Count)."
}

$actualNames = @($validation | ForEach-Object { $_.Name } | Sort-Object)
$missingNames = @($expectedNames | Where-Object { $_ -notin $actualNames })
$unexpectedNames = @($actualNames | Where-Object { $_ -notin $expectedNames })
if ($missingNames.Count -gt 0 -or $unexpectedNames.Count -gt 0) {
    throw "Liste de raccourcis incorrecte. Manquants : $($missingNames -join ', '). Inattendus : $($unexpectedNames -join ', ')."
}

$duplicateTargets = @($validation | Group-Object Target | Where-Object Count -gt 1)
if ($duplicateTargets.Count -gt 0) {
    throw "Cibles dupliquees : $($duplicateTargets.Name -join ', ')."
}

foreach ($entry in $validation) {
    if ($entry.Status -ne 'VALIDE') {
        throw "Validation incomplete pour $($entry.Name)."
    }
}

$installedShortcutsVerified = $false
if (-not [string]::IsNullOrWhiteSpace($DesktopPath)) {
    $desktop = [IO.Path]::GetFullPath($DesktopPath)
    if (-not (Test-Path -LiteralPath $desktop -PathType Container)) {
        throw "Bureau de test introuvable : $desktop"
    }
    $shortcutFiles = @(Get-ChildItem -LiteralPath $desktop -File -Filter '*.lnk')
    if ($shortcutFiles.Count -ne $expectedNames.Count) {
        throw "Nombre de raccourcis installes incorrect : $($shortcutFiles.Count)."
    }

    $shell = New-Object -ComObject WScript.Shell
    try {
        foreach ($entry in $validation) {
            $shortcutPath = Join-Path $desktop ($entry.Name + '.lnk')
            if (-not (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
                throw "Raccourci installe absent : $($entry.Name)"
            }
            $shortcut = $shell.CreateShortcut($shortcutPath)
            if ([IO.Path]::GetFullPath([string]$shortcut.TargetPath) -ine
                    [IO.Path]::GetFullPath([string]$entry.Target) -or
                [IO.Path]::GetFullPath([string]$shortcut.WorkingDirectory) -ine
                    [IO.Path]::GetDirectoryName([string]$entry.Target)) {
                throw "Raccourci installe incoherent : $($entry.Name)"
            }
        }
    }
    finally {
        [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
    }
    $installedShortcutsVerified = $true
}

[pscustomobject]@{
    Release = '1.15'
    InstallationRoot = $root
    ShortcutCount = $validation.Count
    ZipNavBundledMaps = $true
    MissionMateBundledCatalog = $true
    BombsightTableWindowVisible = $true
    UtilityInitializer = $true
    UpdateFinalizer = $true
    InstalledShortcutsVerified = $installedShortcutsVerified
    Result = 'PASS'
    DesktopModified = $false
}
