[CmdletBinding()]
param([string]$ProjectRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$encoding = [Text.Encoding]::GetEncoding(1252)

function Add-BeforeOnce {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Anchor,
        [Parameter(Mandatory = $true)][string]$Insertion,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    $text = [IO.File]::ReadAllText($Path, $encoding)
    if ($text.Contains($Marker)) { return }
    $matches = ([regex]::Matches($text, [regex]::Escape($Anchor))).Count
    if ($matches -ne 1) { throw "Ancre attendue exactement une fois dans $Path : $Anchor (trouvee $matches fois)" }
    $updated = $text.Replace($Anchor, $Insertion + $Anchor)
    [IO.File]::WriteAllText($Path, $updated, $encoding)
}

$plane = Join-Path $root 'Files\i18n\plane_ru.properties'
Add-BeforeOnce -Path $plane `
    -Anchor 'SeaHurricaneMkIb     Hawker Sea-Hurricane Mk.Ib, 1942' `
    -Insertion "SeaHurricaneMkIbLegacy Hawker Sea-Hurricane Mk.Ib (modele historique Open Sturmovik)`r`n" `
    -Marker 'SeaHurricaneMkIbLegacy '
Add-BeforeOnce -Path $plane `
    -Anchor 'SeaHurricaneMkIIc    Hawker Sea-Hurricane Mk.IIc, 1943' `
    -Insertion "SeaHurricaneMkIIcLegacy Hawker Sea-Hurricane Mk.IIc (modele historique Open Sturmovik)`r`n" `
    -Marker 'SeaHurricaneMkIIcLegacy '

$weapons = Join-Path $root 'Files\i18n\weapons_ru.properties'
$ibBlock = @"
#####################################################################
# SeaHurricaneMkIbLegacy
#####################################################################
SeaHurricaneMkIbLegacy.default          Default
SeaHurricaneMkIbLegacy.none             Empty
"@.Replace("`n", "`r`n") + "`r`n"
# The generic helper cannot select among repeated separators. Insert both
# weapon-label blocks relative to their unique aircraft comments instead.
$text = [IO.File]::ReadAllText($weapons, $encoding)
if (-not $text.Contains('SeaHurricaneMkIbLegacy.default')) {
    $anchor = "#####################################################################`r`n# SeaHurricaneMkIIc"
    if (([regex]::Matches($text, [regex]::Escape($anchor))).Count -ne 1) { throw 'Ancre SeaHurricaneMkIIc introuvable.' }
    $text = $text.Replace($anchor, $ibBlock + $anchor)
}
$iicBlock = @"
#####################################################################
# SeaHurricaneMkIIcLegacy
#####################################################################
SeaHurricaneMkIIcLegacy.default         Default
SeaHurricaneMkIIcLegacy.none            Empty
"@.Replace("`n", "`r`n") + "`r`n"
if (-not $text.Contains('SeaHurricaneMkIIcLegacy.default')) {
    $anchor = "#####################################################################`r`n# SpitfireMk1"
    if (([regex]::Matches($text, [regex]::Escape($anchor))).Count -ne 1) { throw 'Ancre SpitfireMk1 introuvable.' }
    $text = $text.Replace($anchor, $iicBlock + $anchor)
}
$text = $text.Replace('SeaHurricaneMkIbLegacy.none             Empty#####################################################################', "SeaHurricaneMkIbLegacy.none             Empty`r`n#####################################################################")
$text = $text.Replace('SeaHurricaneMkIIcLegacy.none            Empty#####################################################################', "SeaHurricaneMkIIcLegacy.none            Empty`r`n#####################################################################")
[IO.File]::WriteAllText($weapons, $text, $encoding)

'Sea Hurricane legacy labels: PASS'
