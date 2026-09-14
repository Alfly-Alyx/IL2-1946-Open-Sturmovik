[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallationRoot,

    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\manifests\utilities-v1.15.json'),

    [string]$DesktopPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop),

    [switch]$AllUsers,

    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Resolve-PathBelowRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "$Label doit etre un chemin relatif : $RelativePath"
    }

    $candidate = Get-NormalizedPath -Path (Join-Path $Root $RelativePath)
    $rootPrefix = $Root + [IO.Path]::DirectorySeparatorChar
    if ($candidate -ine $Root -and
        -not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label sort du dossier d'installation : $RelativePath"
    }

    return $candidate
}

$root = Get-NormalizedPath -Path $InstallationRoot
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Dossier d'installation introuvable : $root"
}

$resolvedManifestPath = Get-NormalizedPath -Path $ManifestPath
if (-not (Test-Path -LiteralPath $resolvedManifestPath -PathType Leaf)) {
    throw "Manifeste des utilitaires introuvable : $resolvedManifestPath"
}

$manifest = Get-Content -LiteralPath $resolvedManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.release -ne '1.15') {
    throw "Le manifeste n'est pas celui des raccourcis de la v1.15."
}

$entries = @($manifest.shortcuts)
if ($entries.Count -ne 11) {
    throw "Le manifeste v1.15 doit contenir exactement 11 raccourcis ; trouve : $($entries.Count)."
}

$seenNames = @{}
$validated = foreach ($entry in $entries) {
    $name = [string]$entry.name
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw 'Un raccourci ne possede pas de nom.'
    }
    if ($name.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        throw "Nom de raccourci invalide : $name"
    }
    if ($seenNames.ContainsKey($name)) {
        throw "Nom de raccourci duplique : $name"
    }
    $seenNames[$name] = $true

    $target = Resolve-PathBelowRoot -Root $root -RelativePath ([string]$entry.target) -Label "La cible de $name"
    $workingDirectory = Resolve-PathBelowRoot -Root $root -RelativePath ([string]$entry.workingDirectory) -Label "Le dossier de travail de $name"

    $targetExtension = [IO.Path]::GetExtension($target)
    if ($targetExtension -inotin @('.exe', '.bat')) {
        throw "La cible de $name n'est ni un executable ni un lanceur batch : $target"
    }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw "Executable introuvable pour $name : $target"
    }
    if (-not (Test-Path -LiteralPath $workingDirectory -PathType Container)) {
        throw "Dossier de travail introuvable pour $name : $workingDirectory"
    }

    $launchMode = 'direct'
    if ($entry.PSObject.Properties.Name -contains 'launchMode' -and
        -not [string]::IsNullOrWhiteSpace([string]$entry.launchMode)) {
        $launchMode = [string]$entry.launchMode
    }

    $shortcutTarget = $target
    $arguments = ''
    switch ($launchMode) {
        'direct' {}
        'native-resolution-via-hidden-powershell' {
            foreach ($propertyName in @('launcher', 'resolutionHelper')) {
                if (-not ($entry.PSObject.Properties.Name -contains $propertyName) -or
                    [string]::IsNullOrWhiteSpace([string]$entry.$propertyName)) {
                    throw "Le champ $propertyName du raccourci $name est absent."
                }
                $component = Resolve-PathBelowRoot -Root $root -RelativePath ([string]$entry.$propertyName) -Label "Le composant $propertyName de $name"
                if (-not (Test-Path -LiteralPath $component -PathType Leaf)) {
                    throw "Composant $propertyName introuvable pour ${name} : $component"
                }
                if ($propertyName -eq 'launcher') {
                    $launcher = $component
                }
            }
            $shortcutTarget = Join-Path ([Environment]::SystemDirectory) 'wscript.exe'
            if (-not (Test-Path -LiteralPath $shortcutTarget -PathType Leaf)) {
                throw "Lanceur Windows introuvable pour $name : $shortcutTarget"
            }
            $arguments = '"' + $launcher + '"'
        }
        'hidden-batch-via-vbs' {
            if ($targetExtension -ine '.bat') {
                throw "Le lancement masque de $name est reserve aux fichiers batch : $target"
            }
            if (-not ($entry.PSObject.Properties.Name -contains 'launcher') -or
                [string]::IsNullOrWhiteSpace([string]$entry.launcher)) {
                throw "Le lanceur masque de $name est absent."
            }
            $launcher = Resolve-PathBelowRoot -Root $root -RelativePath ([string]$entry.launcher) -Label "Le lanceur de $name"
            if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
                throw "Lanceur masque introuvable pour ${name} : $launcher"
            }
            $shortcutTarget = Join-Path ([Environment]::SystemDirectory) 'wscript.exe'
            if (-not (Test-Path -LiteralPath $shortcutTarget -PathType Leaf)) {
                throw "Lanceur Windows introuvable pour $name : $shortcutTarget"
            }
            $arguments = '"' + $launcher + '"'
        }
        default {
            throw "Mode de lancement inconnu pour ${name} : $launchMode"
        }
    }
    $icon = $null
    if ($entry.PSObject.Properties.Name -contains 'icon' -and -not [string]::IsNullOrWhiteSpace([string]$entry.icon)) {
        $icon = Resolve-PathBelowRoot -Root $root -RelativePath ([string]$entry.icon) -Label "L'icone de $name"
        if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) {
            throw "Icone introuvable pour $name : $icon"
        }
    }

    [pscustomobject]@{
        Name = $name
        Target = $target
        ShortcutTarget = $shortcutTarget
        Arguments = $arguments
        LaunchMode = $launchMode
        WorkingDirectory = $workingDirectory
        Description = [string]$entry.description
        Icon = $icon
    }
}

if ($AllUsers) {
    if ($PSBoundParameters.ContainsKey('DesktopPath')) {
        throw '-AllUsers et -DesktopPath ne peuvent pas etre utilises ensemble.'
    }
    $DesktopPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonDesktopDirectory)
}

if ($ValidateOnly) {
    $validated | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Target = $_.Target
            ShortcutTarget = $_.ShortcutTarget
            Arguments = $_.Arguments
            LaunchMode = $_.LaunchMode
            Shortcut = $null
            Status = 'VALIDE'
        }
    }
    return
}

$desktop = Get-NormalizedPath -Path $DesktopPath
if (-not (Test-Path -LiteralPath $desktop -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($desktop, 'Creer le dossier du Bureau')) {
        New-Item -ItemType Directory -Path $desktop -Force | Out-Null
    }
}

$shell = if ($WhatIfPreference) { $null } else { New-Object -ComObject WScript.Shell }
try {
    foreach ($entry in $validated) {
        $shortcutPath = Join-Path $desktop ($entry.Name + '.lnk')
        $shortcutWritten = $false
        if ($PSCmdlet.ShouldProcess($shortcutPath, "Creer le raccourci vers $($entry.Target)")) {
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $entry.ShortcutTarget
            $shortcut.Arguments = $entry.Arguments
            $shortcut.WorkingDirectory = $entry.WorkingDirectory
            $shortcut.Description = $entry.Description
            $shortcut.IconLocation = if ($entry.Icon) { $entry.Icon + ',0' } else { $entry.Target + ',0' }
            $shortcut.Save()
            $shortcutWritten = $true
        }

        [pscustomobject]@{
            Name = $entry.Name
            Target = $entry.Target
            ShortcutTarget = $entry.ShortcutTarget
            LaunchMode = $entry.LaunchMode
            Shortcut = $shortcutPath
            Status = if ($WhatIfPreference) { 'SIMULE' } elseif ($shortcutWritten) { 'INSTALLE' } else { 'IGNORE' }
        }
    }
}
finally {
    if ($null -ne $shell) {
        [Runtime.InteropServices.Marshal]::FinalReleaseComObject($shell) | Out-Null
    }
}
