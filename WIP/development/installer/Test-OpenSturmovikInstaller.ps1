[CmdletBinding()]
param(
    [switch]$BeforeCompilation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installerRoot = $PSScriptRoot
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $installerRoot '..\..\..'))
$scriptPath = Join-Path $installerRoot 'Open_Sturmovik_1.15.iss'
$assetManifestPath = Join-Path $installerRoot 'assets\source-manifest.json'
$payloadPath = Join-Path $installerRoot 'Payload'
$validatedConfHash = '769F8C22AC4CD23A351A0BAC57912B9F7746387EEBF550A1756A88F689F45EF1'

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-Condition (Test-Path -LiteralPath $scriptPath) 'Le script Inno Setup est absent.'
Assert-Condition (Test-Path -LiteralPath $assetManifestPath) 'Le manifeste des ressources visuelles est absent.'
Assert-Condition (Test-Path -LiteralPath (Join-Path $installerRoot 'NOTICE_INSTALLATION.txt')) 'La page d information avant installation est absente.'

$source = Get-Content -LiteralPath $scriptPath -Raw
$requiredFragments = @(
    'DiskSpanning=yes',
    'SlicesPerDisk=1',
    'DiskSliceSize=1000000000',
    'UsePreviousAppDir=no',
    'Uninstallable=no',
    'InfoBeforeFile=NOTICE_INSTALLATION.txt',
    'WizardStyle=modern dark includetitlebar',
    'WizardBackImageOpacity=96',
    'Excludes: "conf.ini"',
    'Payload\_Game Switcher\conf.ini',
    'DestName: "conf.ini"',
    'Payload\Missions\*',
    'Excludes: "Background.tga"',
    'Payload\Missions\Background.tga',
    'Payload\PaintSchemes\*',
    'onlyifdoesntexist',
    'ContainsOpenSturmovik',
    'Open Sturmovik Switcher.exe',
    '_Game Switchers',
    'RenameFile(CurrentConf, ConfBackupPath)',
    'procedure CurInstallProgressChanged',
    'procedure PrepareInstallBackgrounds',
    'procedure ApplyNativeResolution',
    'GetSystemMetrics(SM_CXSCREEN)',
    '.open-sturmovik-installing',
    'Made possible by the community, for the community',
    'InstallProgressFill',
    'procedure ConfigureWizardForeground',
    '[seClient, seBorder]',
    'SetupIconFile=assets\exec-0631d7c4__avion-carte__Windows.ico',
    'BackgroundCount = 8;',
    'Open_Sturmovik_Game.vbs',
    'IconFilename: "{app}\il2fb.exe"'
)

foreach ($fragment in $requiredFragments) {
    Assert-Condition ($source.Contains($fragment)) "Regle attendue absente du script Inno : $fragment"
}

Assert-Condition (-not ($source -match '(?im)^\s*Source:\s*"Payload\\Users')) 'Le script Inno ne doit contenir aucune source Payload\Users.'
Assert-Condition (-not ($source -match '(?i)GetFileVersion|ComparePackedVersion')) 'Le script Inno ne doit pas verifier la version IL-2 presente.'
Assert-Condition (-not ($source -match '(?im)^\s*LicenseFile=')) 'La page d information ne doit pas imposer une acceptation de licence.'
Assert-Condition (-not ($source -match '(?im)^\s*\[Run\]')) 'L installeur ne doit lancer aucun programme externe apres extraction.'
Assert-Condition (-not ($source -match '(?i)ExecutionPolicy\s+Bypass')) 'L installeur ne doit pas contourner la strategie PowerShell.'
Assert-Condition (-not $source.Contains('WizardStyle=modern dynamic')) 'Le style dynamic rend les textes et panneaux illisibles sur les fonds sombres.'

$backgroundCallback = [regex]::Match(
    $source,
    '(?s)procedure SetInstallBackground.*?(?=procedure ConfigureInstallPage)'
)
Assert-Condition $backgroundCallback.Success 'Le bloc SetInstallBackground est introuvable.'
Assert-Condition (-not $backgroundCallback.Value.Contains('ExtractTemporaryFile')) 'La rotation des fonds ne doit jamais appeler l extracteur pendant la copie du Payload.'

$backgroundPreparation = [regex]::Match(
    $source,
    '(?s)procedure PrepareInstallBackgrounds.*?(?=function PrepareToInstall)'
)
Assert-Condition $backgroundPreparation.Success 'Le prechargement des fonds est introuvable.'
Assert-Condition $backgroundPreparation.Value.Contains('ExtractTemporaryFile') 'Les fonds doivent etre extraits avant le debut de la copie.'

$desktopShortcutCount = [regex]::Matches(
    $source,
    '(?im)^Name:\s*"\{autodesktop\}'
).Count
Assert-Condition ($desktopShortcutCount -eq 11) "Le script Inno contient $desktopShortcutCount raccourcis Bureau au lieu de 11."

$assets = Get-Content -LiteralPath $assetManifestPath -Raw | ConvertFrom-Json
Assert-Condition (@($assets.assets).Count -eq 10) 'Le manifeste doit contenir le logo, l icone Windows et huit fonds.'
Assert-Condition (@($assets.assets | Where-Object { $_.role -eq 'setup-icon' }).Count -eq 1) 'Le manifeste doit contenir exactement une icone d installeur.'
Assert-Condition (@($assets.assets | Where-Object { $_.role -like 'background-*' }).Count -eq 8) 'Le manifeste doit contenir exactement huit fonds.'
foreach ($asset in $assets.assets) {
    $path = Join-Path $installerRoot $asset.installerPath
    Assert-Condition (Test-Path -LiteralPath $path) "Ressource visuelle absente : $($asset.installerPath)"
    $actualHash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    Assert-Condition ($actualHash -eq $asset.sha256) "Empreinte incorrecte : $($asset.installerPath)"
}

$shortcutTargets = @(
    '_Game Switcher\Open_Sturmovik_Game.vbs',
    '_Game Switcher\Open_Sturmovik_Switcher.vbs',
    '_Utilities\Bombsight Table 2\Bombsight Table 2.exe',
    '_Utilities\HardBall408\HardBall408.exe',
    '_Utilities\IL2 Sticks\IL2-Sticks.exe',
    '_Utilities\IL2C\ILC2.exe',
    '_Utilities\JoyCtrl\JoyCtrl.exe',
    '_Utilities\Mission Mate 6\Mission Mate v6.0.exe',
    '_Utilities\Quick Mission Tuner\MissionTuner V2.exe',
    '_Utilities\WeatherSet\WeatherSet.exe',
    '_Utilities\ZipNav\ZipNavV1.1.exe'
)

foreach ($target in $shortcutTargets) {
    Assert-Condition (Test-Path -LiteralPath (Join-Path $repositoryRoot $target)) "Cible de raccourci absente du depot : $target"
}

foreach ($supportFile in @(
    'il2fb.exe',
    'Open_Sturmovik_Switcher.bat',
    '_Game Switcher\Set-OpenSturmovikNativeResolution.ps1',
    '_Game Switcher\Refresh-OpenSturmovikIconCache.ps1',
    '_Game Switcher\Open_Sturmovik_Fonds.bat',
    '_Game Switcher\Open_Sturmovik_Fonds.vbs'
)) {
    Assert-Condition (Test-Path -LiteralPath (Join-Path $repositoryRoot $supportFile)) "Fichier d execution absent du depot : $supportFile"
}

$profileFolders = @(
    '4.08 Mods OFF (Original)',
    '4.08 Mods ON (NO 6DOF)',
    '4.08 Mods ON 6DOF',
    '4.09b Mods OFF (Original)',
    '4.09b Mods ON (NO 6DOF)',
    '4.09b Mods ON 6DOF',
    '4.09m Mods OFF (Original)',
    '4.09m Mods ON (NO 6DOF)',
    '4.09m Mods ON 6DOF'
)
$loadingHashes = [ordered]@{
    '4.08 Mods ON (NO 6DOF)' = '24DE629468DF28AAE8B67F9D6865586F039705B10AD6220B1F29CAF51883377E'
    '4.08 Mods ON 6DOF' = '9FCED298BAC9D2F2F936FA368A761189B35C25F2D691AA92A56322D5576D8DC2'
    '4.09b Mods ON (NO 6DOF)' = '7483519C3711AA8DA0B8524BDB157B2562851FF1CDC0DFAD1979C4015AF17D81'
    '4.09b Mods ON 6DOF' = '5A2BFCFF7302B1F52E115C9B15BAA256A8341D902CA9C13B549F055E62416302'
    '4.09m Mods ON (NO 6DOF)' = 'A357B5E5B8F4EE8CC42D65A155096B9DDC229733C64679A10F3A24696CD894F9'
    '4.09m Mods ON 6DOF' = 'C376AA67E0C5E12D39B75C957615DC80778B3414D2D2BDCF3B0BF0911AF82BC4'
}
$sourceSwitcherRoot = Join-Path $repositoryRoot '_Game Switcher'
Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $sourceSwitcherRoot 'Version Payloads'))) 'Version Payloads ne doit plus exister dans le depot.'
Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $sourceSwitcherRoot 'Profiles'))) 'Le dossier Profiles abandonne ne doit pas exister dans le depot.'
foreach ($profileFolder in $profileFolders) {
    $profileRoot = Join-Path $sourceSwitcherRoot $profileFolder
    Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'il2fb.exe')) "Executable absent du profil autonome : $profileFolder"
    Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'files.SFS')) "Archive absente du profil autonome : $profileFolder"
    Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'il2_core.dll')) "Moteur absent du profil autonome : $profileFolder"
    $planePath = Join-Path $profileRoot 'Profiles\Files\2B9A89D62FA5D19A'
    $expectedPlaneHash = if ($profileFolder -like '4.09m*') { 'FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059' } else { 'CFCC074266A0EDFF44D439884D92667EAD6EAC84FE3B59E8BBA97B08244634BB' }
    Assert-Condition ((Get-FileHash -LiteralPath $planePath -Algorithm SHA256).Hash -eq $expectedPlaneHash) "Registre Plane absent ou altere : $profileFolder"
}
foreach ($profileFolder in $profileFolders) {
    $loadingPath = Join-Path $sourceSwitcherRoot "$profileFolder\Profiles\Files\B44652EE36C23D32"
    if ($loadingHashes.Contains($profileFolder)) {
        Assert-Condition ((Get-FileHash -LiteralPath $loadingPath -Algorithm SHA256).Hash -eq $loadingHashes[$profileFolder]) "Libelle de chargement absent ou altere : $profileFolder"
    } else {
        Assert-Condition (-not (Test-Path -LiteralPath $loadingPath)) "Libelle libre inattendu : $profileFolder"
    }
}
$menuBackground = Join-Path $sourceSwitcherRoot 'Resources\Menu Backgrounds\Open Sturmovik\Background.tga'
Assert-Condition ((Get-FileHash -LiteralPath $menuBackground -Algorithm SHA256).Hash -eq '0CB0E846175E36FECBCB18CC02B6206BB0000FBA8F54A4B61418F8BE3824A7B4') 'Fond de menu Open Sturmovik absent ou altere.'
$languageCounts = [ordered]@{
    fr = 36
    ru = 36
    de = 23
    cs = 33
    hu = 20
    pl = 29
}
$sourceI18n = Join-Path $repositoryRoot 'Files\i18n'
$sourceProperties = @(Get-ChildItem -LiteralPath $sourceI18n -Filter '*.properties' -File)
foreach ($language in $languageCounts.Keys) {
    $count = @($sourceProperties | Where-Object Name -like "*_$language.properties").Count
    Assert-Condition ($count -eq $languageCounts[$language]) "Le depot contient $count catalogues $language au lieu de $($languageCounts[$language])."
}
$baseCount = @($sourceProperties | Where-Object Name -notmatch '_[a-z]{2}\.properties$').Count
Assert-Condition ($baseCount -eq 3) "Le depot contient $baseCount catalogues anglais sans suffixe au lieu de 3."
Assert-Condition ($sourceProperties.Count -eq 180) "Le depot contient $($sourceProperties.Count) catalogues actifs au lieu de 180."

$languageManifestPath = Join-Path $repositoryRoot 'WIP\development\manifests\game-language-resources-v1.15.json'
$languageManifest = Get-Content -LiteralPath $languageManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Condition ((@($languageManifest.offeredLanguages) -join ',') -eq 'fr,us,ru,de,cs,hu,pl') 'Le rapport des langues ne declare pas les sept langues attendues.'
Assert-Condition ([int]$languageManifest.versionSpecificCount -eq 30) 'Le rapport doit declarer 30 noms de catalogues propres aux moteurs.'
$sourceVersionLanguageRoot = Join-Path $repositoryRoot '_Game Switcher\Languages'
$sourceVersionLanguageFiles = @(Get-ChildItem -LiteralPath $sourceVersionLanguageRoot -Recurse -Filter '*.properties' -File)
$sourceModdedAliases = @($sourceVersionLanguageFiles | Where-Object FullName -match 'Modded Aliases')
$sourceVersionOverrides = @($sourceVersionLanguageFiles | Where-Object FullName -notmatch 'Modded Aliases')
Assert-Condition ($sourceVersionOverrides.Count -eq 90) "Le depot contient $($sourceVersionOverrides.Count) catalogues propres aux moteurs au lieu de 90."
Assert-Condition ($sourceModdedAliases.Count -eq 756) "Le depot contient $($sourceModdedAliases.Count) alias de langue moddes au lieu de 756."
Assert-Condition ($sourceVersionLanguageFiles.Count -eq 846) "Le depot contient $($sourceVersionLanguageFiles.Count) ressources de langue du switcheur au lieu de 846."
$presentationManifest = Get-Content -LiteralPath (Join-Path $repositoryRoot 'WIP\development\manifests\profile-presentation-resources-v1.15.json') -Raw -Encoding UTF8 | ConvertFrom-Json

$defaultProfileAssembler = Join-Path $installerRoot 'Set-OpenSturmovikPayloadDefaultProfile.ps1'
Assert-Condition (Test-Path -LiteralPath $defaultProfileAssembler -PathType Leaf) 'Assembleur du profil initial absent.'
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($defaultProfileAssembler, [ref]$null, [ref]$parseErrors) | Out-Null
Assert-Condition (@($parseErrors).Count -eq 0) 'Assembleur du profil initial invalide.'
$prepareScript = Get-Content -LiteralPath (Join-Path $installerRoot 'Prepare-OpenSturmovikPayload.ps1') -Raw
Assert-Condition ($prepareScript.Contains('Set-OpenSturmovikPayloadDefaultProfile.ps1')) 'La preparation du Payload n appelle pas l assembleur du profil initial.'
$switcherManifest = Get-Content -LiteralPath (Join-Path $repositoryRoot 'WIP\development\manifests\switcher-v1.15.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Condition ([int]$switcherManifest.defaultProfile -eq 8) 'Le profil par defaut du switcher doit etre le profil 8.'
$nativeResolutionScript = Get-Content -LiteralPath (Join-Path $repositoryRoot '_Game Switcher\Set-OpenSturmovikNativeResolution.ps1') -Raw
foreach ($format in @('4x3', '16x10', '16x9', '21x9', '32x9')) {
    Assert-Condition ($nativeResolutionScript.Contains("`$backgroundFormat = '$format'")) "Le choix automatique du fond $format est absent."
}
Assert-Condition ($nativeResolutionScript.Contains('Files\background0.tga')) 'Le fond natif n est pas copie vers Files\background0.tga.'
Assert-Condition ($nativeResolutionScript.Contains('_Game Switcher\active-profile.txt')) 'La resolution native n est pas reportee dans l etat actif.'

if (Test-Path -LiteralPath $payloadPath) {
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $payloadPath 'Users'))) 'Le Payload contient un dossier Users.'
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $payloadPath 'conf.ini'))) 'Le Payload contient un conf.ini a la racine.'
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $payloadPath '_Game Switcher\Version Payloads'))) 'Version Payloads ne doit plus exister dans le Payload.'
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $payloadPath '_Game Switcher\Profiles'))) 'Le dossier Profiles abandonne ne doit pas exister dans le Payload.'

    $defaultProfileSource = Join-Path $payloadPath '_Game Switcher\4.09m Mods ON (NO 6DOF)'
    $defaultCopies = [ordered]@{
        'il2fb.exe' = 'il2fb.exe'
        'files.SFS' = 'files.SFS'
        'wrapper.dll' = 'wrapper.dll'
        'fb_3do19.SFS' = 'fb_3do19.SFS'
        'fb_3do20.SFS' = 'fb_3do20.SFS'
        'fb_maps15.SFS' = 'fb_maps15.SFS'
        'il2_core.dll' = 'il2_core.dll'
        'il2_corep4.dll' = 'il2_corep4.dll'
        'mg_snd.dll' = 'mg_snd.dll'
        'mg_snd_sse.dll' = 'mg_snd_sse.dll'
        'Profiles\Files\2B9A89D62FA5D19A' = 'Files\2B9A89D62FA5D19A'
        'Profiles\Files\B44652EE36C23D32' = 'Files\B44652EE36C23D32'
        'Profiles\Missions\Background.tga' = 'Missions\Background.tga'
    }
    foreach ($sourceRelative in $defaultCopies.Keys) {
        $sourceFile = Join-Path $defaultProfileSource $sourceRelative
        $targetFile = Join-Path $payloadPath $defaultCopies[$sourceRelative]
        Assert-Condition (Test-Path -LiteralPath $targetFile -PathType Leaf) "Fichier actif du profil 8 absent : $($defaultCopies[$sourceRelative])"
        Assert-Condition ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) "Fichier actif different du profil 8 : $($defaultCopies[$sourceRelative])"
    }
    foreach ($mapping in @(
        @('_Game Switcher\409m air.ini\Air.ini\air.ini', 'Files\com\maddox\il2\objects\air.ini'),
        @('_Game Switcher\Stationary\409m\stationary.ini', 'Files\com\maddox\il2\objects\stationary.ini'),
        @('_Game Switcher\Resources\Menu Backgrounds\Open Sturmovik\Background.tga', 'Files\gui\Background.tga'),
        @('_Game Switcher\Resources\Loading Backgrounds\Maddox\4x3\Background.tga', 'Files\background0.tga')
    )) {
        $sourceFile = Join-Path $payloadPath $mapping[0]
        $targetFile = Join-Path $payloadPath $mapping[1]
        Assert-Condition ((Get-FileHash -LiteralPath $sourceFile -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) "Ressource active differente du profil 8 : $($mapping[1])"
    }
    $defaultMusicSource = Join-Path $defaultProfileSource 'Profiles\samples\Music\Menu'
    $defaultMusicTarget = Join-Path $payloadPath 'samples\Music\Menu'
    $defaultMusicFiles = @(Get-ChildItem -LiteralPath $defaultMusicSource -Filter '*.wav' -File)
    Assert-Condition ($defaultMusicFiles.Count -eq 14) 'Le profil 8 doit contenir 14 musiques.'
    Assert-Condition (@(Get-ChildItem -LiteralPath $defaultMusicTarget -Filter '*.wav' -File).Count -eq 14) 'Le Payload actif doit contenir les 14 musiques du profil 8.'
    foreach ($musicFile in $defaultMusicFiles) {
        $targetFile = Join-Path $defaultMusicTarget $musicFile.Name
        Assert-Condition ((Get-FileHash -LiteralPath $musicFile.FullName -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $targetFile -Algorithm SHA256).Hash) "Musique active differente du profil 8 : $($musicFile.Name)"
    }
    $activeProfilePath = Join-Path $payloadPath '_Game Switcher\active-profile.txt'
    Assert-Condition (Test-Path -LiteralPath $activeProfilePath -PathType Leaf) 'Etat actif initial absent du Payload.'
    $activeProfile = @{}
    foreach ($line in Get-Content -LiteralPath $activeProfilePath) {
        if ($line -match '^([^=]+)=(.*)$') { $activeProfile[$matches[1]] = $matches[2] }
    }
    Assert-Condition ($activeProfile['profile'] -eq '8') 'Le Payload ne declare pas le profil 8 actif.'
    Assert-Condition ($activeProfile['version'] -eq '4.09m') 'Le Payload ne declare pas 4.09m actif.'
    Assert-Condition ($activeProfile['label'] -eq '4.09m Open Sturmovik sans 6DOF') 'Le libelle initial du Payload est incorrect.'
    Assert-Condition ($activeProfile['hud'] -eq 'standard') 'Le HUD initial du Payload doit etre standard.'
    Assert-Condition ($activeProfile['language'] -eq 'fr') 'La langue initiale du Payload doit etre le francais.'
    foreach ($profileFolder in $profileFolders) {
        $profileRoot = Join-Path $payloadPath (Join-Path '_Game Switcher' $profileFolder)
        Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'il2fb.exe')) "Executable absent du profil autonome du Payload : $profileFolder"
        Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'files.SFS')) "Archive absente du profil autonome du Payload : $profileFolder"
        Assert-Condition (Test-Path -LiteralPath (Join-Path $profileRoot 'il2_core.dll')) "Moteur absent du profil autonome du Payload : $profileFolder"
        $planePath = Join-Path $profileRoot 'Profiles\Files\2B9A89D62FA5D19A'
        $expectedPlaneHash = if ($profileFolder -like '4.09m*') { 'FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059' } else { 'CFCC074266A0EDFF44D439884D92667EAD6EAC84FE3B59E8BBA97B08244634BB' }
        Assert-Condition ((Get-FileHash -LiteralPath $planePath -Algorithm SHA256).Hash -eq $expectedPlaneHash) "Registre Plane absent ou altere dans le Payload : $profileFolder"
        $presentation = @($presentationManifest.profiles | Where-Object profile -eq $profileFolder)[0]
        $presentationFiles = @($presentation.background) + @($presentation.music)
        foreach ($item in $presentationFiles) {
            $payloadItem = Join-Path $payloadPath ([string]$item.path)
            Assert-Condition (Test-Path -LiteralPath $payloadItem -PathType Leaf) "Ressource de presentation absente du Payload : $($item.path)"
            Assert-Condition ((Get-FileHash -LiteralPath $payloadItem -Algorithm SHA256).Hash -eq [string]$item.sha256) "Ressource de presentation alteree dans le Payload : $($item.path)"
        }
    }

    foreach ($profileFolder in $profileFolders) {
        $loadingPath = Join-Path $payloadPath "_Game Switcher\$profileFolder\Profiles\Files\B44652EE36C23D32"
        if ($loadingHashes.Contains($profileFolder)) {
            Assert-Condition ((Get-FileHash -LiteralPath $loadingPath -Algorithm SHA256).Hash -eq $loadingHashes[$profileFolder]) "Libelle de chargement absent ou altere dans le Payload : $profileFolder"
        } else {
            Assert-Condition (-not (Test-Path -LiteralPath $loadingPath)) "Libelle libre inattendu dans le Payload : $profileFolder"
        }
    }
    Assert-Condition ((Get-FileHash -LiteralPath (Join-Path $payloadPath '_Game Switcher\Resources\Menu Backgrounds\Open Sturmovik\Background.tga') -Algorithm SHA256).Hash -eq '0CB0E846175E36FECBCB18CC02B6206BB0000FBA8F54A4B61418F8BE3824A7B4') 'Fond de menu absent du Payload.'
    $payloadProperties = @(Get-ChildItem -LiteralPath (Join-Path $payloadPath 'Files\i18n') -Filter '*.properties' -File)
    Assert-Condition ($payloadProperties.Count -eq $sourceProperties.Count) "Le Payload contient $($payloadProperties.Count) catalogues actifs au lieu de $($sourceProperties.Count)."
    $defaultAliasRoot = Join-Path $payloadPath '_Game Switcher\Languages\4.09m\Modded Aliases\fr\i18n'
    $defaultHud = Join-Path $payloadPath '_Game Switcher\HudLogStock\MODS\STD\i18n\hud_log_fr.properties'
    foreach ($catalogue in $sourceProperties) {
        $payloadCatalogue = Join-Path $payloadPath ('Files\i18n\' + $catalogue.Name)
        Assert-Condition (Test-Path -LiteralPath $payloadCatalogue) "Catalogue absent du Payload : $($catalogue.Name)"
        $expectedCatalogue = $catalogue.FullName
        $defaultAlias = Join-Path $defaultAliasRoot $catalogue.Name
        if (Test-Path -LiteralPath $defaultAlias -PathType Leaf) { $expectedCatalogue = $defaultAlias }
        if ($catalogue.Name -eq 'hud_log_ru.properties') { $expectedCatalogue = $defaultHud }
        Assert-Condition ((Get-FileHash -LiteralPath $payloadCatalogue -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $expectedCatalogue -Algorithm SHA256).Hash) "Catalogue actif incorrect dans le Payload : $($catalogue.Name)"
    }
    $payloadVersionLanguageRoot = Join-Path $payloadPath '_Game Switcher\Languages'
    $payloadVersionLanguageFiles = @(Get-ChildItem -LiteralPath $payloadVersionLanguageRoot -Recurse -Filter '*.properties' -File)
    Assert-Condition ($payloadVersionLanguageFiles.Count -eq 846) "Le Payload contient $($payloadVersionLanguageFiles.Count) ressources de langue du switcheur au lieu de 846."
    foreach ($catalogue in $sourceVersionLanguageFiles) {
        $relative = $catalogue.FullName.Substring($sourceVersionLanguageRoot.Length).TrimStart('\')
        $payloadCatalogue = Join-Path $payloadVersionLanguageRoot $relative
        Assert-Condition (Test-Path -LiteralPath $payloadCatalogue) "Catalogue moteur absent du Payload : $relative"
        Assert-Condition ((Get-FileHash -LiteralPath $payloadCatalogue -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $catalogue.FullName -Algorithm SHA256).Hash) "Catalogue moteur altere dans le Payload : $relative"
    }

    $sourceConf = Join-Path $repositoryRoot '_Game Switcher\conf.ini' 
    $payloadConf = Join-Path $payloadPath '_Game Switcher\conf.ini'
    Assert-Condition (Test-Path -LiteralPath $payloadConf) 'Le conf.ini valide du pack est absent du Payload.'
    Assert-Condition ((Get-FileHash -LiteralPath $sourceConf -Algorithm SHA256).Hash -eq $validatedConfHash) 'Le conf.ini source ne correspond plus a la version validee.'
    Assert-Condition (
        (Get-FileHash -LiteralPath $sourceConf -Algorithm SHA256).Hash -eq
        (Get-FileHash -LiteralPath $payloadConf -Algorithm SHA256).Hash
    ) 'Le conf.ini du Payload ne correspond pas a _Game Switcher\conf.ini.'

    foreach ($supportFile in @(
        'il2fb.exe',
        'Open_Sturmovik_Switcher.bat',
        '_Game Switcher\Open_Sturmovik_Switcher.hta',
        '_Game Switcher\Set-OpenSturmovikNativeResolution.ps1',
        '_Game Switcher\Set-OpenSturmovikLanguage.ps1',
        '_Game Switcher\Refresh-OpenSturmovikIconCache.ps1',
        '_Game Switcher\Open_Sturmovik_Fonds.bat',
        '_Game Switcher\Open_Sturmovik_Fonds.vbs'
    )) {
        Assert-Condition (Test-Path -LiteralPath (Join-Path $payloadPath $supportFile)) "Fichier d execution absent du Payload : $supportFile"
    }

    foreach ($notice in @('LICENSE.md', 'docs\LICENSING.md', 'docs\THIRD_PARTY_NOTICES.md', '_Documentations\Mods and Tools\Credits - Open Sturmovik.md', 'docs\ORGANISATION_PROFILS_SWITCHER.md', 'docs\ROTATION_FONDS_CHARGEMENT.md')) {
        Assert-Condition (Test-Path -LiteralPath (Join-Path $payloadPath $notice)) "Notice requise absente du Payload : $notice"
    }

    foreach ($target in $shortcutTargets) {
        Assert-Condition (Test-Path -LiteralPath (Join-Path $payloadPath $target)) "Cible de raccourci absente du Payload : $target"
    }
}

if ($BeforeCompilation) {
    $outputPath = Join-Path $installerRoot 'Output'
    if (Test-Path -LiteralPath $outputPath) {
        $compiledFiles = Get-ChildItem -LiteralPath $outputPath -File | Where-Object { $_.Extension -in '.exe', '.bin' }
        Assert-Condition (@($compiledFiles).Count -eq 0) 'Une sortie Inno compilee existe deja dans installer\Output.'
    }
}

[pscustomobject]@{
    InstallerSource = $scriptPath
    AssetCount = @($assets.assets).Count
    ShortcutCount = $desktopShortcutCount
    PayloadPresent = Test-Path -LiteralPath $payloadPath
    CompilationNotStarted = $BeforeCompilation.IsPresent
    Status = 'OK'
}
