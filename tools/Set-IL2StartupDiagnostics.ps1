[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [switch]$Restore
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path
$confPath = Join-Path $resolvedRoot 'conf.ini'
$backupPath = "$confPath.open-sturmovik-diagnostics.bak"
$temporaryPath = "$confPath.open-sturmovik-diagnostics.tmp"
if (-not (Test-Path -LiteralPath $confPath -PathType Leaf)) {
    throw "conf.ini introuvable : $confPath"
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Set-IniSectionValues {
    param(
        [Parameter(Mandatory = $true)]$Lines,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)]$Values
    )

    $sectionStart = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match ('^\s*\[' + [regex]::Escape($Section) + '\]\s*$')) {
            $sectionStart = $index
            break
        }
    }
    if ($sectionStart -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') {
            $Lines.Add('') | Out-Null
        }
        $Lines.Add("[$Section]") | Out-Null
        foreach ($key in $Values.Keys) {
            $Lines.Add("$key=$($Values[$key])") | Out-Null
        }
        return
    }

    $sectionEnd = $Lines.Count
    for ($index = $sectionStart + 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*\[.+\]\s*$') {
            $sectionEnd = $index
            break
        }
    }
    foreach ($key in $Values.Keys) {
        $found = $false
        $pattern = '^\s*;?\s*' + [regex]::Escape($key) + '\s*='
        for ($index = $sectionStart + 1; $index -lt $sectionEnd; $index++) {
            if ($Lines[$index] -match $pattern) {
                $Lines[$index] = "$key=$($Values[$key])"
                $found = $true
                break
            }
        }
        if (-not $found) {
            $Lines.Insert($sectionEnd, "$key=$($Values[$key])")
            $sectionEnd++
        }
    }
}

if ($Restore) {
    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        throw "Sauvegarde de diagnostic introuvable : $backupPath"
    }
    Copy-Item -LiteralPath $backupPath -Destination $temporaryPath -Force
    if ((Get-Sha256 -Path $backupPath) -ne (Get-Sha256 -Path $temporaryPath)) {
        throw 'La copie de restauration de conf.ini ne correspond pas a la sauvegarde.'
    }
    Move-Item -LiteralPath $temporaryPath -Destination $confPath -Force
    [pscustomobject]@{ GameRoot = $resolvedRoot; Configuration = $confPath; State = 'RESTORED'; SHA256 = (Get-Sha256 -Path $confPath) }
    exit 0
}

if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
    Copy-Item -LiteralPath $confPath -Destination $backupPath
    if ((Get-Sha256 -Path $confPath) -ne (Get-Sha256 -Path $backupPath)) {
        throw 'La sauvegarde initiale de conf.ini a echoue.'
    }
}

$bytes = [IO.File]::ReadAllBytes($confPath)
$encoding = [Text.Encoding]::Default
$offset = 0
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $encoding = New-Object Text.UTF8Encoding($true)
    $offset = 3
}
elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $encoding = [Text.Encoding]::Unicode
    $offset = 2
}
$text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$hadFinalNewline = $text.EndsWith("`n")
$parts = $text -split '\r?\n'
if ($hadFinalNewline -and $parts.Count -gt 0 -and $parts[$parts.Count - 1] -eq '') {
    $parts = $parts[0..($parts.Count - 2)]
}
$lines = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in $parts) { $lines.Add($line) | Out-Null }

Set-IniSectionValues -Lines $lines -Section 'game' -Values ([ordered]@{ eventlog = 'eventlog.lst'; eventlogkeep = '1' })
Set-IniSectionValues -Lines $lines -Section 'Console' -Values ([ordered]@{
    LOG = '1'
    LOGTIME = '1'
    LOGFILE = 'log.lst'
    LOGKEEP = '1'
    LOGDEBUG = '1'
})

$updated = [string]::Join($newline, $lines.ToArray())
if ($hadFinalNewline) { $updated += $newline }
try {
    [IO.File]::WriteAllText($temporaryPath, $updated, $encoding)
    if ((Get-Item -LiteralPath $temporaryPath).Length -eq 0) {
        throw 'Le fichier de configuration temporaire est vide.'
    }
    Move-Item -LiteralPath $temporaryPath -Destination $confPath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}

[pscustomobject]@{
    GameRoot = $resolvedRoot
    Configuration = $confPath
    Backup = $backupPath
    State = 'DIAGNOSTICS_ENABLED'
    SHA256 = (Get-Sha256 -Path $confPath)
}
