param(
    [Parameter(Mandatory = $true)][string]$StockPath,
    [string]$ExtensionPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifests\registries\chief.mod-extensions.ini'),
    [string]$Destination = (Join-Path (Split-Path -Parent $PSScriptRoot) 'Files\com\maddox\il2\objects\chief.ini')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-IniSections {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $preamble = New-Object System.Collections.Generic.List[string]
    $sections = New-Object System.Collections.Generic.List[object]
    $current = $null

    foreach ($line in [IO.File]::ReadAllLines($resolved)) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $current = [pscustomobject]@{
                Name = $Matches[1]
                Lines = New-Object System.Collections.Generic.List[string]
            }
            $current.Lines.Add($line)
            $sections.Add($current)
        }
        elseif ($null -eq $current) {
            $preamble.Add($line)
        }
        else {
            $current.Lines.Add($line)
        }
    }

    $duplicates = @($sections | Group-Object Name | Where-Object Count -gt 1)
    if ($duplicates.Count -gt 0) {
        throw "Sections dupliquees dans $resolved : $($duplicates.Name -join ', ')"
    }

    return [pscustomobject]@{
        Path = $resolved
        Preamble = $preamble
        Sections = $sections
    }
}

function Get-MeaningfulLines {
    param([Parameter(Mandatory = $true)]$Section)

    return @($Section.Lines | Select-Object -Skip 1 | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith(';') -and -not $_.StartsWith('//') })
}

$stock = Read-IniSections $StockPath
$extension = Read-IniSections $ExtensionPath
$stockByName = @{}
foreach ($section in $stock.Sections) {
    $stockByName[$section.Name.ToLowerInvariant()] = $section
}

$extensionByName = @{}
foreach ($section in $extension.Sections) {
    $extensionByName[$section.Name.ToLowerInvariant()] = $section
}

$armorKey = 'armor'
if (-not $stockByName.ContainsKey($armorKey) -or -not $extensionByName.ContainsKey($armorKey)) {
    throw 'La section [Armor] doit exister dans le registre officiel et dans les extensions.'
}

$stockArmor = $stockByName[$armorKey]
$extensionArmor = $extensionByName[$armorKey]
$stockArmorKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($line in (Get-MeaningfulLines $stockArmor)) {
    if ($line -match '^moveType\s+') { continue }
    [void]$stockArmorKeys.Add(($line -split '\s+')[0])
}

$armorAdditions = New-Object System.Collections.Generic.List[string]
foreach ($line in ($extensionArmor.Lines | Select-Object -Skip 1)) {
    $trimmed = $line.Trim()
    if ($trimmed -match '^moveType\s+') { continue }
    if ($trimmed -and -not $trimmed.StartsWith(';') -and -not $trimmed.StartsWith('//')) {
        $key = ($trimmed -split '\s+')[0]
        if ($stockArmorKeys.Contains($key)) {
            throw "Entree [Armor] deja presente dans le registre 4.09m : $key"
        }
    }
    $armorAdditions.Add($line)
}

$newSections = New-Object System.Collections.Generic.List[object]
foreach ($section in $extension.Sections) {
    $key = $section.Name.ToLowerInvariant()
    if ($key -eq $armorKey) { continue }
    if ($stockByName.ContainsKey($key)) {
        $stockLines = (Get-MeaningfulLines $stockByName[$key]) -join "`n"
        $extensionLines = (Get-MeaningfulLines $section) -join "`n"
        if ($stockLines -cne $extensionLines) {
            throw "La section [$($section.Name)] existe dans les deux sources avec un contenu different."
        }
        continue
    }
    $newSections.Add($section)
}

$output = New-Object System.Collections.Generic.List[string]
$output.AddRange([string[]]$stock.Preamble)
foreach ($section in $stock.Sections) {
    $output.AddRange([string[]]$section.Lines)
    if ($section.Name.Equals('Armor', [StringComparison]::OrdinalIgnoreCase)) {
        $output.Add('')
        $output.Add('; --- Open Sturmovik v1.15 : ajouts communautaires ---')
        $output.AddRange([string[]]$armorAdditions)
    }
}

$output.Add('')
$output.Add('; --- Open Sturmovik v1.15 : nouvelles familles de chiefs ---')
foreach ($section in $newSections) {
    $output.AddRange([string[]]$section.Lines)
}

$destinationDirectory = Split-Path -Parent $Destination
if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
}
[IO.File]::WriteAllText($Destination, (($output -join "`r`n").TrimEnd() + "`r`n"), [Text.Encoding]::GetEncoding(1252))

$result = [pscustomobject]@{
    StockSections = $stock.Sections.Count
    ExtensionSections = $extension.Sections.Count
    AddedSections = $newSections.Count
    AddedArmorEntries = @((Get-MeaningfulLines $extensionArmor) | Where-Object { $_ -notmatch '^moveType\s+' }).Count
    Destination = (Resolve-Path -LiteralPath $Destination).Path
    Sha256 = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
}
$result | Format-List
