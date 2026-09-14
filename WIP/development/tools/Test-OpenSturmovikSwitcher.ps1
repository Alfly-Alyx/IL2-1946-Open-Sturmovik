[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$developmentRoot = Split-Path -Parent $PSScriptRoot
if (-not $RepositoryRoot) { $RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..')) }
if (-not $ManifestPath) { $ManifestPath = Join-Path $developmentRoot 'manifests/switcher-v1.15.json' }

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$manifestFile = [IO.Path]::GetFullPath($ManifestPath)
$manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.release -ne '1.15') {
    throw 'Manifeste du switcher v1.15 invalide.'
}

$components = @($manifest.entryPoint, $manifest.gui, $manifest.desktopIcon)
if ($null -ne $manifest.background) {
    $components += [string]$manifest.background.path
}
foreach ($relative in $components | Where-Object { $_ }) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)) -PathType Leaf)) {
        throw "Composant du switcher absent : $relative"
    }
}
if ($null -ne $manifest.background) {
    if ((Get-Item -LiteralPath (Join-Path $root ([string]$manifest.background.path))).Length -ne [long]$manifest.background.size -or
        (Get-FileHash -LiteralPath (Join-Path $root ([string]$manifest.background.path)) -Algorithm SHA256).Hash -ne
            [string]$manifest.background.sha256) {
        throw 'Fond graphique du switcher absent ou altere.'
    }
}
if ([string]$manifest.resourceDirectory -ne '_Game Switcher/Resources' -or
    @($manifest.icons).Count -ne 2) {
    throw 'Le dossier Resources ou la liste des deux icones actives Open Sturmovik est invalide.'
}
foreach ($resource in @($manifest.icons)) {
    $resourcePath = Join-Path $root ([string]$resource.path)
    if (-not (Test-Path -LiteralPath $resourcePath -PathType Leaf) -or
        (Get-Item -LiteralPath $resourcePath).Length -ne [long]$resource.size -or
        (Get-FileHash -LiteralPath $resourcePath -Algorithm SHA256).Hash -ne [string]$resource.sha256) {
        throw "Ressource graphique du switcher absente ou alteree : $($resource.path)"
    }
}

foreach ($background in @($manifest.loadingBackgrounds.formats)) {
    $backgroundPath = Join-Path $root ([string]$background.path)
    if (-not (Test-Path -LiteralPath $backgroundPath -PathType Leaf) -or
        (Get-Item -LiteralPath $backgroundPath).Length -ne [long]$background.size -or
        (Get-FileHash -LiteralPath $backgroundPath -Algorithm SHA256).Hash -ne [string]$background.sha256) {
        throw "Fond de chargement absent ou altere : $($background.path)"
    }
    $header = [IO.File]::ReadAllBytes($backgroundPath)
    $width = [BitConverter]::ToUInt16($header, 12)
    $height = [BitConverter]::ToUInt16($header, 14)
    if ($header[2] -ne 2 -or $header[16] -ne 24 -or
        $width -ne [int]$background.width -or $height -ne [int]$background.height) {
        throw "Format TGA incorrect pour le fond $($background.name)."
    }
}
if ($manifest.guiMode -ne 'dedicated-hta' -or
    $manifest.hashCheckerMode -ne 'embedded-sha256-validation') {
    throw 'La GUI permanente et le controle SHA-256 du BAT sont invalides.'
}
$guiPath = Join-Path $root ([string]$manifest.gui)
if ((Get-FileHash -LiteralPath $guiPath -Algorithm SHA256).Hash -ne [string]$manifest.guiSha256) {
    throw 'Le HTA permanent est absent ou altere.'
}
$guiText = Get-Content -LiteralPath $guiPath -Raw
if ($guiText -notmatch '(?is)^<!doctype html>' -or $guiText.Substring(0, [Math]::Min(512, $guiText.Length)) -match '%~f0|SWITCHER_GUI_LINE|SWITCHER_GUI_TEMP') {
    throw 'Le HTA contient un preambule BAT parasite.'
}

$profiles = @($manifest.profiles)
if ($profiles.Count -ne 9 -or @($profiles.number | Sort-Object -Unique).Count -ne 9) {
    throw 'Le switcher doit declarer exactement neuf profils uniques.'
}

$languageCodes = @($manifest.language.choices | ForEach-Object { [string]$_.code })
$expectedLanguageCodes = @('fr','us','de','ru','cs','hu','pl')
if (($languageCodes -join ',') -ne ($expectedLanguageCodes -join ',')) {
    throw "Liste de langues incorrecte : $($languageCodes -join ', ')"
}
$languageRoot = Join-Path $root '_Game Switcher/Languages'
foreach ($version in @('4.08m','4.09b','4.09m')) {
    $versionLanguageFiles = @(Get-ChildItem -LiteralPath (Join-Path $languageRoot "$version/i18n") -File -Filter '*.properties')
    if ($versionLanguageFiles.Count -ne 30) {
        throw "Le moteur $version doit disposer de 30 catalogues localises propres a sa version."
    }
    foreach ($language in $expectedLanguageCodes) {
        $aliases = @(Get-ChildItem -LiteralPath (Join-Path $languageRoot "$version/Modded Aliases/$language/i18n") -File -Filter '*_ru.properties')
        if ($aliases.Count -ne 36) {
            throw "Le moteur $version doit disposer de 36 alias _ru complets pour la langue $language."
        }
    }
}

$profileStorageRoot = Join-Path $root '_Game Switcher'
if (Test-Path -LiteralPath (Join-Path $profileStorageRoot 'Version Payloads')) {
    throw 'L ancien dossier Version Payloads ne doit plus exister.'
}
if (Test-Path -LiteralPath (Join-Path $profileStorageRoot 'Profiles')) {
    throw 'Le dossier Profiles abandonne ne doit plus exister.'
}
foreach ($profileDirectory in @($manifest.profileStorage.directories)) {
    if (-not (Test-Path -LiteralPath (Join-Path $profileStorageRoot ([string]$profileDirectory)) -PathType Container)) {
        throw "Dossier de profil autonome absent : $profileDirectory"
    }
}
foreach ($common in @($manifest.commonFiles)) {
    $path = Join-Path $root ([string]$common.path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne [string]$common.sha256) {
        throw "Fichier commun absent ou altere : $($common.path)"
    }
}

foreach ($registry in $manifest.airRegistries.PSObject.Properties) {
    $path = Join-Path $root $registry.Value.path
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $registry.Value.sha256) {
        throw "Registre d avions altere : $($registry.Name)"
    }
    $count = @(Get-Content -LiteralPath $path | Where-Object { $_ -match '^\s*\S+\s+air\.' }).Count
    if ($count -ne $registry.Value.entries) { throw "Nombre d entrees incorrect : $($registry.Name)" }
}

$windowTitleClass = Join-Path $root ([string]$manifest.branding.windowTitleClass.path)
if (-not (Test-Path -LiteralPath $windowTitleClass -PathType Leaf) -or
    (Get-FileHash -LiteralPath $windowTitleClass -Algorithm SHA256).Hash -ne
        [string]$manifest.branding.windowTitleClass.sha256) {
    throw 'Classe de titre Open Sturmovik absente ou alteree.'
}

foreach ($profile in $profiles | Sort-Object number) {
    $exe = Join-Path $root ([string]$profile.executablePath)
    $files = Join-Path $root ([string]$profile.filesArchivePath)
    $plane = Join-Path $root ([string]$profile.planePath)
    foreach ($versionFile in @($manifest.versionFiles.([string]$profile.version))) {
        $versionPath = Join-Path $root (([string]$profile.directoryPath) + '/' + [string]$versionFile.file)
        if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
            throw "Fichier moteur absent du profil $($profile.number) : $($versionFile.file)"
        }
        $versionItem = Get-Item -LiteralPath $versionPath
        $versionHash = (Get-FileHash -LiteralPath $versionPath -Algorithm SHA256).Hash
        if ($versionItem.Length -ne [long]$versionFile.size -or $versionHash -ne [string]$versionFile.sha256) {
            throw "Fichier moteur altere dans le profil $($profile.number) : $($versionFile.file)"
        }
    }
    if ([string]$profile.mode -ne 'original') {
        $wrapper = Join-Path $root ([string]$profile.wrapperPath)
        if ((Get-FileHash -LiteralPath $wrapper -Algorithm SHA256).Hash -ne '8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78') {
            throw "Wrapper modde absent ou altere pour le profil $($profile.number)."
        }
    }
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne [string]$profile.exeSha256 -or
        (Get-FileHash -LiteralPath $files -Algorithm SHA256).Hash -ne [string]$profile.filesSha256 -or
        (Get-FileHash -LiteralPath $plane -Algorithm SHA256).Hash -ne [string]$profile.planeSha256) {
        throw "Profil altere : $($profile.number) - $($profile.version) $($profile.mode)"
    }
    $presentationBackground = Join-Path $root ([string]$profile.presentation.backgroundPath)
    $presentationMusic = Join-Path $root ([string]$profile.presentation.menuMusicPath)
    if ((Get-FileHash -LiteralPath $presentationBackground -Algorithm SHA256).Hash -ne [string]$profile.presentation.backgroundSha256) {
        throw "Fond Missions altere pour le profil $($profile.number)."
    }
    if (@(Get-ChildItem -LiteralPath $presentationMusic -File -Filter '*.wav').Count -ne [int]$profile.presentation.menuMusicFiles) {
        throw "Jeu de musiques incomplet pour le profil $($profile.number)."
    }
    if ($null -ne $profile.loadingDisplay.PSObject.Properties['overridePath']) {
        $loading = Join-Path $root ([string]$profile.loadingDisplay.overridePath)
        if (-not (Test-Path -LiteralPath $loading -PathType Leaf) -or
            (Get-FileHash -LiteralPath $loading -Algorithm SHA256).Hash -ne [string]$profile.loadingDisplay.overrideSha256) {
            throw "Libelle de chargement absent ou altere pour le profil $($profile.number)."
        }
    }
    $versionInfo = (Get-Item -LiteralPath $exe).VersionInfo
    if ([string]$profile.mode -eq 'original') {
        if ($versionInfo.FileDescription -eq 'Open Sturmovik' -or
            $versionInfo.ProductName -eq 'Open Sturmovik') {
            throw "L executable original du profil $($profile.number) a ete rebaptise."
        }
    } else {
        if ($versionInfo.FileDescription -ne [string]$manifest.branding.moddedExeVersionInfo.fileDescription -or
            $versionInfo.ProductName -ne [string]$manifest.branding.moddedExeVersionInfo.productName -or
            $versionInfo.FileVersion -ne [string]$manifest.branding.moddedExeVersionInfo.fileVersion -or
            $versionInfo.OriginalFilename -ne [string]$manifest.branding.moddedExeVersionInfo.originalFilename) {
            throw "Metadonnees Open Sturmovik incorrectes pour le profil $($profile.number)."
        }
    }
}

$runtimeRoot = Join-Path $root 'WIP/tests/installations/IL 2 Sturmovik 1946 test'
if (-not (Test-Path -LiteralPath (Join-Path $runtimeRoot 'conf.ini') -PathType Leaf)) {
    throw 'Installation de test absente pour les validations transactionnelles.'
}
$runtimeSwitcher = Join-Path $runtimeRoot ([string]$manifest.entryPoint)
if ((Get-FileHash -LiteralPath $runtimeSwitcher -Algorithm SHA256).Hash -ne $manifest.entryPointSha256) {
    throw 'Le BAT de l installation de test n est pas synchronise.'
}

$transactions = @(Get-ChildItem -LiteralPath (Join-Path $runtimeRoot '_Game Switcher') -Directory -Filter '_transaction-*')
if ($transactions.Count -ne 0) {
    throw "Transaction abandonnee detectee : $($transactions.FullName -join ', ')"
}

[pscustomobject]@{
    Release = '1.15'
    ProfileCount = $profiles.Count
    HudVariants = 2
    LanguageVariants = 7
    SourceIntegrity = $true
    RuntimeValidation = 'COUVERTE_PAR_Test-SwitcherTransactions.ps1'
    Result = 'PASS'
}
