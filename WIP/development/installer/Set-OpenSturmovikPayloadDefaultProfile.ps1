[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PayloadRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
$payloadPath = [IO.Path]::GetFullPath($PayloadRoot).TrimEnd('\')
$payloadParent = [IO.Path]::GetDirectoryName($payloadPath).TrimEnd('\')
$payloadName = [IO.Path]::GetFileName($payloadPath)

if (-not $payloadParent.Equals($installerRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Le profil par defaut ne peut etre assemble que dans le dossier de l'installeur : $installerRoot"
}
if ($payloadName -notmatch '^Payload(?:\.staging\.[0-9a-f]{32})?$') {
    throw "Nom de Payload non autorise : $payloadName"
}
if (-not (Test-Path -LiteralPath $payloadPath -PathType Container)) {
    throw "Payload absent : $payloadPath"
}
if (Test-Path -LiteralPath (Join-Path $payloadPath 'Users')) {
    throw 'Le dossier Users ne doit jamais entrer dans le Payload.'
}
if (Test-Path -LiteralPath (Join-Path $payloadPath 'conf.ini')) {
    throw 'Le conf.ini de la racine ne doit jamais entrer dans le Payload.'
}

$switcherRoot = Join-Path $payloadPath '_Game Switcher'
$profileRoot = Join-Path $switcherRoot '4.09m Mods ON (NO 6DOF)'
$languageRoot = Join-Path $switcherRoot 'Languages\4.09m'
$i18nRoot = Join-Path $payloadPath 'Files\i18n'

function Copy-CheckedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        throw "Fichier source absent : $Source"
    }
    $destinationDirectory = [IO.Path]::GetDirectoryName($Destination)
    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationDirectory | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $destinationHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if ($sourceHash -ne $destinationHash) {
        throw "Copie alteree : $Destination"
    }
}

foreach ($fileName in @(
    'il2fb.exe',
    'files.SFS',
    'wrapper.dll',
    'fb_3do19.SFS',
    'fb_3do20.SFS',
    'fb_maps15.SFS',
    'il2_core.dll',
    'il2_corep4.dll',
    'mg_snd.dll',
    'mg_snd_sse.dll'
)) {
    Copy-CheckedFile -Source (Join-Path $profileRoot $fileName) -Destination (Join-Path $payloadPath $fileName)
}

Copy-CheckedFile -Source (Join-Path $switcherRoot '409m air.ini\Air.ini\air.ini') -Destination (Join-Path $payloadPath 'Files\com\maddox\il2\objects\air.ini')
Copy-CheckedFile -Source (Join-Path $switcherRoot 'Stationary\409m\stationary.ini') -Destination (Join-Path $payloadPath 'Files\com\maddox\il2\objects\stationary.ini')
Copy-CheckedFile -Source (Join-Path $profileRoot 'Profiles\Files\2B9A89D62FA5D19A') -Destination (Join-Path $payloadPath 'Files\2B9A89D62FA5D19A')
Copy-CheckedFile -Source (Join-Path $profileRoot 'Profiles\Files\B44652EE36C23D32') -Destination (Join-Path $payloadPath 'Files\B44652EE36C23D32')
Copy-CheckedFile -Source (Join-Path $switcherRoot 'Resources\Menu Backgrounds\Open Sturmovik\Background.tga') -Destination (Join-Path $payloadPath 'Files\gui\Background.tga')
Copy-CheckedFile -Source (Join-Path $profileRoot 'Profiles\Missions\Background.tga') -Destination (Join-Path $payloadPath 'Missions\Background.tga')
Copy-CheckedFile -Source (Join-Path $switcherRoot 'Resources\Loading Backgrounds\Maddox\4x3\Background.tga') -Destination (Join-Path $payloadPath 'Files\background0.tga')

$musicSource = Join-Path $profileRoot 'Profiles\samples\Music\Menu'
$musicTarget = Join-Path $payloadPath 'samples\Music\Menu'
$musicFiles = @(Get-ChildItem -LiteralPath $musicSource -Filter '*.wav' -File)
if ($musicFiles.Count -ne 14) {
    throw "Le profil 8 contient $($musicFiles.Count) musiques de menu au lieu de 14."
}
Get-ChildItem -LiteralPath $musicTarget -Filter '*.wav' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force
foreach ($musicFile in $musicFiles) {
    Copy-CheckedFile -Source $musicFile.FullName -Destination (Join-Path $musicTarget $musicFile.Name)
}

$versionCatalogues = @(Get-ChildItem -LiteralPath (Join-Path $languageRoot 'i18n') -Filter '*_fr.properties' -File)
foreach ($catalogue in $versionCatalogues) {
    Copy-CheckedFile -Source $catalogue.FullName -Destination (Join-Path $i18nRoot $catalogue.Name)
}

$moddedCatalogues = @(Get-ChildItem -LiteralPath (Join-Path $languageRoot 'Modded Aliases\fr\i18n') -Filter '*_ru.properties' -File)
if ($moddedCatalogues.Count -ne 36) {
    throw "Le profil francais modde contient $($moddedCatalogues.Count) catalogues au lieu de 36."
}
foreach ($catalogue in $moddedCatalogues) {
    Copy-CheckedFile -Source $catalogue.FullName -Destination (Join-Path $i18nRoot $catalogue.Name)
}
Copy-CheckedFile -Source (Join-Path $switcherRoot 'HudLogStock\MODS\STD\i18n\hud_log_fr.properties') -Destination (Join-Path $i18nRoot 'hud_log_ru.properties')

$confTemplate = Join-Path $switcherRoot 'conf.ini'
$confContent = [IO.File]::ReadAllText($confTemplate)
if ([regex]::Matches($confContent, '(?m)^locale=fr\s*$').Count -ne 1) {
    throw 'Le conf.ini du pack ne declare pas exactement une langue francaise.'
}

$statePath = Join-Path $switcherRoot 'active-profile.txt'
$state = @(
    'profile=8',
    'version=4.09m',
    'label=4.09m Open Sturmovik sans 6DOF',
    'hud=standard',
    'modhud=standard',
    'background=4x3',
    'resolution=1024x768',
    'language=fr'
) -join "`r`n"
[IO.File]::WriteAllText($statePath, $state + "`r`n", [Text.Encoding]::ASCII)

[pscustomobject]@{
    Profile = 8
    Version = '4.09m'
    Mode = 'Open Sturmovik sans 6DOF'
    Hud = 'standard'
    Language = 'fr'
    MusicFiles = $musicFiles.Count
    ModdedLanguageCatalogues = $moddedCatalogues.Count
    Payload = $payloadPath
}