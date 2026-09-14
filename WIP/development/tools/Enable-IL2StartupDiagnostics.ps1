[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$GameRoot)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$conf = Join-Path $root 'conf.ini'
if (-not (Test-Path -LiteralPath $conf -PathType Leaf)) {
    throw "conf.ini absent : $conf"
}
if (@(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'IL-2 est actif. Fermer le jeu avant de modifier la journalisation.'
}

$backup = $conf + '.open-sturmovik-diagnostics.bak'
Copy-Item -LiteralPath $conf -Destination $backup -Force

$bytes = [IO.File]::ReadAllBytes($conf)
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
$lines = New-Object 'System.Collections.Generic.List[string]'
foreach ($line in ($text -split '\r?\n')) { $lines.Add($line) }
if ($hadFinalNewline -and $lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') {
    $lines.RemoveAt($lines.Count - 1)
}

function Set-IniValues {
    param(
        [Parameter(Mandatory = $true)]$Lines,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][hashtable]$Values
    )

    $header = -1
    $end = $Lines.Count
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*\[(.+)\]\s*$') {
            if ($header -ge 0) { $end = $index; break }
            if ($matches[1] -ieq $Section) { $header = $index }
        }
    }
    if ($header -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') { $Lines.Add('') }
        $Lines.Add("[$Section]")
        foreach ($key in $Values.Keys) { $Lines.Add("$key=$($Values[$key])") }
        return
    }

    foreach ($key in $Values.Keys) {
        $found = $false
        for ($index = $header + 1; $index -lt $end; $index++) {
            if ($Lines[$index] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) {
                $Lines[$index] = "$key=$($Values[$key])"
                $found = $true
                break
            }
        }
        if (-not $found) {
            $Lines.Insert($end, "$key=$($Values[$key])")
            $end++
        }
    }
}

try {
    Set-IniValues -Lines $lines -Section 'game' -Values @{ eventlogkeep = '1' }
    Set-IniValues -Lines $lines -Section 'Console' -Values @{
        LOG = '1'
        LOGTIME = '1'
        LOGKEEP = '1'
        LOGDEBUG = '1'
    }
    $updated = [string]::Join($newline, $lines.ToArray())
    if ($hadFinalNewline) { $updated += $newline }
    [IO.File]::WriteAllText($conf, $updated, $encoding)
    Write-Host "Journalisation de demarrage activee. Sauvegarde : $backup" -ForegroundColor Green
}
catch {
    Copy-Item -LiteralPath $backup -Destination $conf -Force
    throw
}
