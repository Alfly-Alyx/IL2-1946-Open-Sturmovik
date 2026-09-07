[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CataloguePath,

    [ValidateRange(1, 65535)]
    [int]$CodePage = 1252
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedPath = (Resolve-Path -LiteralPath $CataloguePath).Path
$sections = [ordered]@{}
$errors = New-Object System.Collections.Generic.List[string]
$currentSection = $null
$lineNumber = 0

function Add-CatalogueError {
    param([string]$Message)
    $script:errors.Add($Message)
}

$encoding = [Text.Encoding]::GetEncoding($CodePage)
foreach ($line in [IO.File]::ReadAllLines($resolvedPath, $encoding)) {
    $lineNumber++
    $trimmed = ([string]$line).Trim()
    if (-not $trimmed -or $trimmed.StartsWith(';') -or $trimmed.StartsWith('#')) {
        continue
    }
    if ($trimmed -match '^\[(?<name>[^\]]+)\]$') {
        $currentSection = $Matches.name.Trim()
        if ($sections.Contains($currentSection)) {
            Add-CatalogueError "Ligne $lineNumber : section dupliquee [$currentSection]."
        }
        else {
            $sections[$currentSection] = [ordered]@{}
        }
        continue
    }
    if ($null -eq $currentSection) {
        Add-CatalogueError "Ligne $lineNumber : valeur hors section."
        continue
    }
    if ($trimmed -notmatch '^(?<key>[^=]+?)\s*=\s*(?<value>.*)$') {
        Add-CatalogueError "Ligne $lineNumber : syntaxe inconnue."
        continue
    }

    $key = $Matches.key.Trim()
    $value = $Matches.value.Trim()
    $section = $sections[$currentSection]
    if ($section.Contains($key)) {
        Add-CatalogueError "Ligne $lineNumber : cle dupliquee [$currentSection]/$key."
    }
    else {
        $section[$key] = $value
    }
}

if (-not $sections.Contains('categories')) {
    Add-CatalogueError 'La section [categories] est absente.'
}

$categoryItems = New-Object System.Collections.Generic.List[object]
$referencedProfiles = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
if ($sections.Contains('categories')) {
    foreach ($entry in $sections['categories'].GetEnumerator()) {
        $profileNames = @(
            [string]$entry.Value -split ',' |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        )
        foreach ($profileName in $profileNames) {
            $null = $referencedProfiles.Add($profileName)
            if (-not $sections.Contains($profileName)) {
                Add-CatalogueError "Categorie $($entry.Key) : profil absent [$profileName]."
            }
        }
        $categoryItems.Add([ordered]@{
            id = [string]$entry.Key
            profiles = $profileNames
        })
    }
}

$resolvedCache = @{}
$visiting = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
function Resolve-Profile {
    param([string]$ProfileName)

    if ($script:resolvedCache.ContainsKey($ProfileName)) {
        return ,$script:resolvedCache[$ProfileName]
    }
    if (-not $script:sections.Contains($ProfileName)) {
        return ,[ordered]@{}
    }
    if (-not $script:visiting.Add($ProfileName)) {
        Add-CatalogueError "Cycle d heritage detecte autour de [$ProfileName]."
        return ,[ordered]@{}
    }

    $profile = $script:sections[$ProfileName]
    $resolved = [ordered]@{}
    if ($profile.Contains('Parent')) {
        $parentName = [string]$profile['Parent']
        if (-not $script:sections.Contains($parentName)) {
            Add-CatalogueError "Profil [$ProfileName] : parent absent [$parentName]."
        }
        else {
            $parentSettings = Resolve-Profile $parentName
            foreach ($entry in $parentSettings.GetEnumerator()) {
                $resolved[$entry.Key] = $entry.Value
            }
        }
    }
    foreach ($entry in $profile.GetEnumerator()) {
        if ([string]$entry.Key -ieq 'Parent' -or [string]$entry.Key -match '(?i)^Name(?:_|$)') {
            continue
        }
        $resolved[$entry.Key] = $entry.Value
    }

    $null = $script:visiting.Remove($ProfileName)
    $script:resolvedCache[$ProfileName] = $resolved
    return ,$resolved
}

$profileItems = New-Object System.Collections.Generic.List[object]
foreach ($profileName in @($sections.Keys | Where-Object { $_ -ine 'categories' })) {
    $profile = $sections[$profileName]
    $labels = [ordered]@{}
    $ownSettings = [ordered]@{}
    foreach ($entry in $profile.GetEnumerator()) {
        if ([string]$entry.Key -match '(?i)^Name(?:_(?<locale>.+))?$') {
            $locale = if ($Matches.ContainsKey('locale') -and $Matches['locale']) {
                $Matches['locale']
            }
            else {
                'default'
            }
            $labels[$locale] = $entry.Value
        }
        elseif ([string]$entry.Key -ine 'Parent') {
            $ownSettings[$entry.Key] = $entry.Value
        }
    }
    $parent = if ($profile.Contains('Parent')) { [string]$profile['Parent'] } else { $null }
    $profileItems.Add([ordered]@{
        id = [string]$profileName
        parent = $parent
        referencedByCategory = $referencedProfiles.Contains([string]$profileName)
        labels = $labels
        ownSettings = $ownSettings
        resolvedSettings = Resolve-Profile ([string]$profileName)
    })
}

[ordered]@{
    schemaVersion = 1
    sourceFile = [IO.Path]::GetFileName($resolvedPath)
    sourceSize = (Get-Item -LiteralPath $resolvedPath).Length
    sourceSha256 = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash
    valid = ($errors.Count -eq 0)
    categoryCount = $categoryItems.Count
    profileCount = $profileItems.Count
    categories = $categoryItems.ToArray()
    profiles = $profileItems.ToArray()
    unreferencedProfiles = @(
        $profileItems |
            Where-Object { -not $_.referencedByCategory } |
            ForEach-Object { $_.id }
    )
    errors = @($errors)
} | ConvertTo-Json -Depth 20

if ($errors.Count -gt 0) { exit 1 }
