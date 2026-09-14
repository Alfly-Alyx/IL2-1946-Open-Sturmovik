[CmdletBinding()]
param(
    [string]$GameRoot,
    [string]$UserId = '0',
    [string]$KeyChord = 'Ctrl R',
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Join-Path $PSScriptRoot '..\..\tests\installations\IL 2 Sturmovik 1946 test'
}
$settingsPath = Join-Path $GameRoot "Users\$UserId\settings.ini"
if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
    throw "Profil IL-2 introuvable : $settingsPath"
}
if (@(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'IL-2 doit etre ferme avant de modifier son profil de commandes.'
}

$lines = [Collections.Generic.List[string]]::new()
$lines.AddRange([string[]](Get-Content -LiteralPath $settingsPath))
$targetHeader = '[HotKey $$$misc]'
$targetStart = $lines.IndexOf($targetHeader)
$targetEnd = $lines.Count
if ($targetStart -ge 0) {
    for ($index = $targetStart + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\[') {
            $targetEnd = $index
            break
        }
    }
}

$correctBinding = $false
$actionIndexes = [Collections.Generic.List[int]]::new()
for ($index = 0; $index -lt $lines.Count; $index++) {
    if ($lines[$index] -match '=quickSaveNetTrack\s*$') {
        $actionIndexes.Add($index)
        if ($targetStart -ge 0 -and $index -gt $targetStart -and $index -lt $targetEnd) {
            $correctBinding = $lines[$index] -eq "$KeyChord=quickSaveNetTrack"
        }
    }
    if ($lines[$index] -match ('^' + [regex]::Escape($KeyChord) + '=') -and
        $lines[$index] -notmatch '=quickSaveNetTrack\s*$') {
        throw "La combinaison $KeyChord est deja utilisee : $($lines[$index])"
    }
}

if ($correctBinding -and $actionIndexes.Count -eq 1) {
    Write-Host "ENREGISTREMENT_PISTE_DEJA_LIE : $KeyChord=quickSaveNetTrack dans $targetHeader" -ForegroundColor Green
    exit 0
}
if ($ValidateOnly) {
    Write-Host "ENREGISTREMENT_PISTE_A_CONFIGURER : $KeyChord=quickSaveNetTrack dans $targetHeader" -ForegroundColor Yellow
    exit 2
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupPath = "$settingsPath.open-sturmovik-quick-track-$stamp.bak"
Copy-Item -LiteralPath $settingsPath -Destination $backupPath

# Une liaison placee dans [HotKey misc] est acceptee par l'editeur de texte mais
# ignoree par le moteur 4.09m. Retirer toute ancienne tentative avant d'ecrire
# l'unique liaison dans l'environnement $$$misc reserve a cette commande.
for ($index = $actionIndexes.Count - 1; $index -ge 0; $index--) {
    $lines.RemoveAt($actionIndexes[$index])
}
$targetStart = $lines.IndexOf($targetHeader)
if ($targetStart -lt 0) {
    $insertBefore = $lines.IndexOf('[HotKey timeCompression]')
    if ($insertBefore -lt 0) {
        $insertBefore = $lines.Count
    }
    $lines.Insert($insertBefore, $targetHeader)
    $lines.Insert($insertBefore + 1, "$KeyChord=quickSaveNetTrack")
}
else {
    $lines.Insert($targetStart + 1, "$KeyChord=quickSaveNetTrack")
}
[IO.File]::WriteAllLines($settingsPath, $lines, [Text.Encoding]::Default)

$written = Get-Content -LiteralPath $settingsPath
$writtenCount = @($written | Where-Object { $_ -eq "$KeyChord=quickSaveNetTrack" }).Count
if ($writtenCount -ne 1) {
    throw 'La liaison d enregistrement n a pas ete ecrite exactement une fois.'
}
$writtenTargetStart = [array]::IndexOf($written, $targetHeader)
$writtenTargetEnd = $written.Count
for ($index = $writtenTargetStart + 1; $index -lt $written.Count; $index++) {
    if ($written[$index] -match '^\[') {
        $writtenTargetEnd = $index
        break
    }
}
$writtenBindingIndex = [array]::IndexOf($written, "$KeyChord=quickSaveNetTrack")
if ($writtenTargetStart -lt 0 -or
    $writtenBindingIndex -le $writtenTargetStart -or
    $writtenBindingIndex -ge $writtenTargetEnd) {
    throw "La liaison d enregistrement n est pas dans $targetHeader."
}

Write-Host "ENREGISTREMENT_PISTE_PRET : $KeyChord dans $targetHeader" -ForegroundColor Green
Write-Host "SAUVEGARDE : $backupPath"
