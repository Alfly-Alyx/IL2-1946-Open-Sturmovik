[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BaseRoot,
    [Parameter(Mandatory = $true)][string]$AddonRoot,
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [Parameter(Mandatory = $true)][string]$BackupRoot,
    [switch]$ValidateOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$base = (Resolve-Path -LiteralPath $BaseRoot -ErrorAction Stop).Path.TrimEnd('\')
$addon = (Resolve-Path -LiteralPath $AddonRoot -ErrorAction Stop).Path.TrimEnd('\')
$destination = (Resolve-Path -LiteralPath $DestinationRoot -ErrorAction Stop).Path.TrimEnd('\')
$backup = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
$destinationParent = [IO.Path]::GetDirectoryName($destination)

if ($base -ieq $addon -or $base -ieq $destination -or $addon -ieq $destination) {
    throw 'Les sources et la destination doivent etre des dossiers distincts.'
}
if ([IO.Path]::GetDirectoryName($backup) -ine $destinationParent) {
    throw 'La sauvegarde doit rester dans le meme dossier parent que le jeu de test.'
}
if (Test-Path -LiteralPath $backup) {
    throw "Le chemin de sauvegarde existe deja : $backup"
}
if (@(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'IL-2 est actif. Fermer le jeu avant de reconstruire le dossier de test.'
}

$baseFiles = @(Get-ChildItem -LiteralPath $base -Recurse -File -ErrorAction Stop)
$baseBytes = ($baseFiles | Measure-Object Length -Sum).Sum
$baseSfs = @(Get-ChildItem -LiteralPath $base -File -Filter '*.SFS')
if ($baseFiles.Count -ne 19474 -or $baseBytes -ne 4575508511 -or $baseSfs.Count -ne 47) {
    throw "Base 4.07m inattendue : $($baseFiles.Count) fichiers, $baseBytes octets, $($baseSfs.Count) SFS."
}

$official409 = [ordered]@{
    'fb_3do19.SFS' = '4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670'
    'fb_3do20.SFS' = '02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283'
    'fb_maps15.SFS' = 'AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9'
    'files.SFS' = '9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095'
    'il2_core.dll' = '3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3'
    'il2_corep4.dll' = '0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979'
    'mg_snd.dll' = '2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421'
    'mg_snd_sse.dll' = 'FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4'
}
foreach ($name in $official409.Keys) {
    $path = Join-Path $addon $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Fichier 4.09m absent de l'add-on : $name"
    }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($hash -ne $official409[$name]) {
        throw "Empreinte 4.09m incorrecte : $name"
    }
}

$allowedRootSfs = @('fb_3do.SFS', 'fb_3do18.SFS', 'fb_3do19.SFS', 'fb_3do20.SFS', 'fb_maps14.SFS', 'fb_maps15.SFS', 'files.SFS')
$unexpectedRootSfs = @(Get-ChildItem -LiteralPath $addon -File -Filter '*.SFS' | Where-Object { $_.Name -notin $allowedRootSfs })
if ($unexpectedRootSfs.Count -ne 0) {
    throw "SFS posterieur ou inconnu a la racine de l'add-on : $($unexpectedRootSfs.Name -join ', ')"
}

$payloadDirectories = @(
    '_Game Switchers',
    '_Documentations',
    '_Utilities',
    '_Game_Enhancements',
    'DGen',
    'docs',
    'Files',
    'i18n',
    'Intros',
    'manifests',
    'Missions',
    'NGen',
    'PaintSchemes',
    'samples'
)
foreach ($name in $payloadDirectories) {
    if (-not (Test-Path -LiteralPath (Join-Path $addon $name) -PathType Container)) {
        throw "Dossier de l'add-on absent : $name"
    }
}

$profile9 = @(
    '_Game Switchers\4.09final_ModsON+6DoF\il2fb.exe',
    '_Game Switchers\4.09final_ModsON+6DoF\files.SFS',
    '_Game Switchers\4.09final_ModsON+6DoF\wrapper.dll',
    '_Game Switchers\409m air.ini\Air.ini\air.ini',
    '_Game Switchers\Stationary\409m\stationary.ini'
)
foreach ($relative in $profile9) {
    if (-not (Test-Path -LiteralPath (Join-Path $addon $relative) -PathType Leaf)) {
        throw "Source du profil 4.09m + 6DOF absente : $relative"
    }
}

if ($ValidateOnly) {
    Write-Host 'Base 4.07m, payload 4.09m, profil 6DOF et destinations valides ; aucune copie effectuee.' -ForegroundColor Green
    return
}

function Invoke-TreeCopy {
    param([Parameter(Mandatory = $true)][string]$Source, [Parameter(Mandatory = $true)][string]$Target)

    if (-not (Test-Path -LiteralPath $Target)) {
        New-Item -ItemType Directory -Path $Target | Out-Null
    }
    & robocopy.exe $Source $Target /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ /NFL /NDL /NJH /NJS /NP
    $code = $LASTEXITCODE
    if ($code -gt 7) {
        throw "Robocopy a echoue avec le code $code pour $Source."
    }
}

$failedRoot = $destination + '.failed-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss')
$movedOriginal = $false
try {
    Move-Item -LiteralPath $destination -Destination $backup
    $movedOriginal = $true
    New-Item -ItemType Directory -Path $destination | Out-Null

    Write-Host 'Copie de la base DVD 4.07m...'
    Invoke-TreeCopy -Source $base -Target $destination

    Write-Host 'Superposition du contenu Open Sturmovik...'
    foreach ($name in $payloadDirectories) {
        Write-Host "  $name"
        Invoke-TreeCopy -Source (Join-Path $addon $name) -Target (Join-Path $destination $name)
    }

    Get-ChildItem -LiteralPath $addon -File | Where-Object { $_.Name -notin @('.gitattributes', '.gitignore') } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $destination $_.Name) -Force
    }

    $resultSfs = @(Get-ChildItem -LiteralPath $destination -File -Filter '*.SFS')
    if ($resultSfs.Count -ne 52) {
        throw "Installation superposee inattendue : $($resultSfs.Count) SFS au lieu de 52."
    }
    $forbidden = @($resultSfs | Where-Object { $_.Name -match '^fb_(3do|maps)(2[1-9]|3[0-9])|^fb_sounds\.SFS$|^filesserver\.SFS$' })
    if ($forbidden.Count -ne 0) {
        throw "SFS posterieur a 4.09m detecte : $($forbidden.Name -join ', ')"
    }

    $resultFiles = @(Get-ChildItem -LiteralPath $destination -Recurse -File)
    $resultBytes = ($resultFiles | Measure-Object Length -Sum).Sum
    Write-Host "Arbre de test reconstruit : $($resultFiles.Count) fichiers, $resultBytes octets." -ForegroundColor Green
    Write-Host "Sauvegarde precedente : $backup" -ForegroundColor Green
}
catch {
    if (Test-Path -LiteralPath $destination) {
        Move-Item -LiteralPath $destination -Destination $failedRoot
    }
    if ($movedOriginal -and (Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $destination)) {
        Move-Item -LiteralPath $backup -Destination $destination
    }
    throw "Reconstruction du test annulee et ancien dossier restaure. $($_.Exception.Message)"
}
