[CmdletBinding()]
param(
    [string]$RepositoryRoot = ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))),
    [string]$Destination = (Join-Path $PSScriptRoot 'Payload'),
    [switch]$Replace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryPath = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$destinationPath = [IO.Path]::GetFullPath($Destination).TrimEnd('\')
$expectedDestination = [IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot 'Payload')).TrimEnd('\')

if (-not $destinationPath.Equals(
        $expectedDestination,
        [StringComparison]::OrdinalIgnoreCase)) {
    throw "La destination autorisee est uniquement : $expectedDestination"
}

if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
    throw "Le depot source est introuvable : $repositoryPath"
}

if ((Test-Path -LiteralPath $destinationPath) -and -not $Replace) {
    throw "Le Payload existe deja. Relancer avec -Replace pour le reconstruire."
}

$rootFiles = @(
    'DeviceLink.txt',
    'fb_3do.SFS',
    'fb_3do18.SFS',
    'fb_3do19.SFS',
    'fb_3do20.SFS',
    'fb_maps14.SFS',
    'fb_maps15.SFS',
    'files.SFS',
    'HUD_Log-IMMERSION.bat',
    'HUD_Log-REGULAR.bat',
    'il2_core.dll',
    'il2_corep4.dll',
    'il2_usgs.dll',
    'il2_usgs2.dll',
    'il2fb.exe',
    'LICENSE.md',
    'mg_snd_sse.dll',
    'mg_snd.dll',
    'msvcp71.dll',
    'msvcr71.dll',
    'Open_Sturmovik_Switcher.bat',
    'README.md'
)

$rootDirectories = @(
    '_Documentations',
    '_Game Switcher',
    '_Game_Enhancements',
    '_Utilities',
    'DGen',
    'Files',
    'i18n',
    'Intros',
    'Missions',
    'NGen',
    'PaintSchemes',
    'samples'
)

$distributionDocuments = @(
    'LICENSING.md',
    'THIRD_PARTY_NOTICES.md',
    'ORGANISATION_PROFILS_SWITCHER.md',
    'ROTATION_FONDS_CHARGEMENT.md'
)

$shortcutTargets = @(
    'il2fb.exe',
    'Open_Sturmovik_Switcher.bat',
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

foreach ($relativePath in $rootFiles + $rootDirectories) {
    $sourcePath = Join-Path $repositoryPath $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Element requis absent du depot : $relativePath"
    }
}

foreach ($fileName in $distributionDocuments) {
    $sourcePath = Join-Path $repositoryPath (Join-Path 'docs' $fileName)
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Notice de distribution absente : docs\$fileName"
    }
}

$stagingPath = Join-Path $PSScriptRoot (
    'Payload.staging.' + [Guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $stagingPath | Out-Null

    foreach ($relativePath in $rootFiles) {
        Copy-Item -LiteralPath (Join-Path $repositoryPath $relativePath) -Destination (Join-Path $stagingPath $relativePath)
    }

    foreach ($relativePath in $rootDirectories) {
        $sourcePath = Join-Path $repositoryPath $relativePath
        $targetPath = Join-Path $stagingPath $relativePath
        New-Item -ItemType Directory -Path $targetPath | Out-Null

        & robocopy.exe $sourcePath $targetPath /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP
        $robocopyExitCode = $LASTEXITCODE
        if ($robocopyExitCode -ge 8) {
            throw "Echec de copie de $relativePath (robocopy $robocopyExitCode)."
        }
    }

    $docsTarget = Join-Path $stagingPath 'docs'
    New-Item -ItemType Directory -Path $docsTarget | Out-Null
    foreach ($fileName in $distributionDocuments) {
        $sourceDocument = Join-Path $repositoryPath (Join-Path 'docs' $fileName)
        Copy-Item -LiteralPath $sourceDocument -Destination (Join-Path $docsTarget $fileName)
    }

    $defaultProfileScript = Join-Path $PSScriptRoot 'Set-OpenSturmovikPayloadDefaultProfile.ps1'
    if (-not (Test-Path -LiteralPath $defaultProfileScript -PathType Leaf)) {
        throw "Assembleur du profil par defaut absent : $defaultProfileScript"
    }
    & $defaultProfileScript -PayloadRoot $stagingPath | Out-Host
    if (Test-Path -LiteralPath (Join-Path $stagingPath 'Users')) {
        throw 'Le dossier Users ne doit jamais entrer dans le Payload.'
    }

    if (Test-Path -LiteralPath (Join-Path $stagingPath 'conf.ini')) {
        throw 'Le conf.ini de la racine ne doit pas entrer dans le Payload.'
    }

    $sourceConf = Join-Path $repositoryPath '_Game Switcher\conf.ini'
    $payloadConf = Join-Path $stagingPath '_Game Switcher\conf.ini'
    if (-not (Test-Path -LiteralPath $payloadConf)) {
        throw 'Le conf.ini valide du pack est absent du Payload.'
    }

    $sourceConfHash = (Get-FileHash -LiteralPath $sourceConf -Algorithm SHA256).Hash
    $payloadConfHash = (Get-FileHash -LiteralPath $payloadConf -Algorithm SHA256).Hash
    if ($sourceConfHash -ne $payloadConfHash) {
        throw 'Le conf.ini du Payload differe de _Game Switcher\conf.ini.'
    }

    foreach ($relativePath in $shortcutTargets) {
        if (-not (Test-Path -LiteralPath (Join-Path $stagingPath $relativePath))) {
            throw "Cible de raccourci absente du Payload : $relativePath"
        }
    }

    if (Test-Path -LiteralPath $destinationPath) {
        Remove-Item -LiteralPath $destinationPath -Recurse -Force
    }
    Move-Item -LiteralPath $stagingPath -Destination $destinationPath

    $payloadFiles = Get-ChildItem -LiteralPath $destinationPath -File -Recurse
    [pscustomobject]@{
        Destination = $destinationPath
        FileCount = @($payloadFiles).Count
        Bytes = ($payloadFiles | Measure-Object -Property Length -Sum).Sum
        ConfIniSHA256 = $payloadConfHash
        UsersExcluded = -not (
            Test-Path -LiteralPath (Join-Path $destinationPath 'Users'))
    }
}
finally {
    if (Test-Path -LiteralPath $stagingPath) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force
    }
}
