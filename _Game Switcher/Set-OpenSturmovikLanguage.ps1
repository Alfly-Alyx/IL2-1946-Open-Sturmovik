[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [Parameter(Mandatory = $true)][ValidateSet('fr', 'us', 'ru', 'de', 'cs', 'hu', 'pl')][string]$Language
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourcePath = [IO.Path]::GetFullPath($Source)
$destinationPath = [IO.Path]::GetFullPath($Destination)
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "conf.ini source absent : $sourcePath"
}
$bytes = [IO.File]::ReadAllBytes($sourcePath)
$encoding = $null
$preambleLength = 0
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $encoding = New-Object Text.UTF8Encoding($true)
    $preambleLength = 3
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $encoding = New-Object Text.UnicodeEncoding($false, $true)
    $preambleLength = 2
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $encoding = New-Object Text.UnicodeEncoding($true, $true)
    $preambleLength = 2
} else {
    $encoding = [Text.Encoding]::GetEncoding(1252)
}
$text = $encoding.GetString($bytes, $preambleLength, $bytes.Length - $preambleLength)
$newLine = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$sectionMatch = [regex]::Match($text, '(?ms)^\[rts\][ \t]*\r?\n.*?(?=^\[|\z)')
if (-not $sectionMatch.Success) { throw 'Section [rts] absente de conf.ini.' }
$section = $sectionMatch.Value
$localeMatches = [regex]::Matches($section, '(?mi)^locale=.*$')
if ($localeMatches.Count -gt 1) { throw 'Plusieurs lignes locale= sont presentes dans [rts].' }
if ($localeMatches.Count -eq 1) {
    $updatedSection = [regex]::Replace($section, '(?mi)^locale=.*$', "locale=$Language", 1)
} else {
    $updatedSection = $section.TrimEnd("`r", "`n") + $newLine + "locale=$Language" + $newLine
}
$updated = $text.Substring(0, $sectionMatch.Index) + $updatedSection + $text.Substring($sectionMatch.Index + $sectionMatch.Length)
$check = [regex]::Match($updated, '(?ms)^\[rts\][ \t]*\r?\n.*?(?=^\[|\z)')
if (@([regex]::Matches($check.Value, '(?mi)^locale=' + [regex]::Escape($Language) + '$')).Count -ne 1) {
    throw 'Verification de locale= impossible.'
}
$destinationDirectory = Split-Path -Parent $destinationPath
if (-not (Test-Path -LiteralPath $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}
$body = $encoding.GetBytes($updated)
if ($preambleLength -gt 0) {
    $preamble = $encoding.GetPreamble()
    $output = New-Object byte[] ($preamble.Length + $body.Length)
    [Array]::Copy($preamble, 0, $output, 0, $preamble.Length)
    [Array]::Copy($body, 0, $output, $preamble.Length, $body.Length)
} else {
    $output = $body
}
[IO.File]::WriteAllBytes($destinationPath, $output)
Write-Output "locale=$Language"
