[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SettingsPath,
    [Parameter(Mandatory = $true)][string]$Key,
    [Parameter(Mandatory = $true)][string]$Action,
    [string]$Section = 'HotKey pilot'
)

$ErrorActionPreference = 'Stop'
$resolvedSettings = (Resolve-Path -LiteralPath $SettingsPath -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $resolvedSettings -PathType Leaf)) {
    throw "Fichier settings.ini absent : $resolvedSettings"
}
if ($Key -match '[=\r\n]' -or $Action -match '[=\r\n]' -or $Section -match '[\[\]\r\n]') {
    throw 'Nom de touche, action ou section invalide.'
}

$encoding = [Text.Encoding]::GetEncoding(1252)
$text = [IO.File]::ReadAllText($resolvedSettings, $encoding)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$sectionPattern = '(?m)^\[' + [Regex]::Escape($Section) + '\]\r?$'
$sectionMatch = [Regex]::Match($text, $sectionPattern)
if (-not $sectionMatch.Success) {
    throw "Section [$Section] absente de $resolvedSettings"
}

$bodyStart = $sectionMatch.Index + $sectionMatch.Length
$nextSection = [Regex]::Match($text.Substring($bodyStart), '(?m)^\[[^\r\n]+\]\r?$')
$bodyEnd = if ($nextSection.Success) { $bodyStart + $nextSection.Index } else { $text.Length }
$body = $text.Substring($bodyStart, $bodyEnd - $bodyStart)
$bindingPattern = '(?m)^' + [Regex]::Escape($Key) + '=([^\r\n]*)\r?$'
$bindingMatch = [Regex]::Match($body, $bindingPattern)
$bindingLine = "$Key=$Action"

if ($bindingMatch.Success -and $bindingMatch.Groups[1].Value -eq $Action) {
    Write-Host "RACCOURCI_DEJA_ACTIF : $bindingLine" -ForegroundColor Green
    exit 0
}
if ($bindingMatch.Success) {
    $newBody = [Regex]::Replace($body, $bindingPattern, $bindingLine, 1)
}
else {
    $trimmedBody = $body.TrimEnd("`r", "`n")
    $trailing = $body.Substring($trimmedBody.Length)
    $newBody = $trimmedBody + $newline + $bindingLine + $newline + $trailing.TrimStart("`r", "`n")
}

$newText = $text.Substring(0, $bodyStart) + $newBody + $text.Substring($bodyEnd)
$beforeHash = (Get-FileHash -LiteralPath $resolvedSettings -Algorithm SHA256).Hash
$timestamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ')
$backupPath = "$resolvedSettings.open-sturmovik-$timestamp.bak"
$temporaryPath = "$resolvedSettings.open-sturmovik-$timestamp.tmp"

try {
    [IO.File]::WriteAllText($temporaryPath, $newText, $encoding)
    $verification = [IO.File]::ReadAllText($temporaryPath, $encoding)
    if ($verification -notmatch ('(?m)^' + [Regex]::Escape($Key) + '=' + [Regex]::Escape($Action) + '\r?$')) {
        throw 'Le raccourci n a pas passe la verification avant remplacement.'
    }
    [IO.File]::Replace($temporaryPath, $resolvedSettings, $backupPath)
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

$afterHash = (Get-FileHash -LiteralPath $resolvedSettings -Algorithm SHA256).Hash
Write-Host "RACCOURCI_ACTIVE : $bindingLine" -ForegroundColor Green
Write-Host "SAUVEGARDE : $backupPath"
Write-Host "SHA256_AVANT : $beforeHash"
Write-Host "SHA256_APRES : $afterHash"
