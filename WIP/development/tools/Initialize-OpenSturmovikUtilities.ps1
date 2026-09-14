[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallationRoot,

    [switch]$SkipZipNavMaps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$textEncoding = [Text.Encoding]::GetEncoding(1252)

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Write-PortableTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines
    )

    $newText = ($Lines -join "`r`n") + "`r`n"
    $oldText = if (Test-Path -LiteralPath $Path -PathType Leaf) {
        [IO.File]::ReadAllText($Path, $textEncoding)
    }
    else {
        $null
    }

    if ($oldText -ceq $newText) {
        return $false
    }

    if ($null -ne $oldText) {
        $backup = $Path + '.opensturmovik-v1.15.bak'
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Copy-Item -LiteralPath $Path -Destination $backup
        }
    }

    $temporary = $Path + '.opensturmovik-v1.15.tmp'
    try {
        [IO.File]::WriteAllText($temporary, $newText, $textEncoding)
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporary -PathType Leaf) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }

    return $true
}

$root = Get-NormalizedPath -Path $InstallationRoot
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Dossier d'installation introuvable : $root"
}

$gameExecutable = Join-Path $root 'il2fb.exe'
if (-not (Test-Path -LiteralPath $gameExecutable -PathType Leaf)) {
    throw "il2fb.exe absent du dossier d'installation : $root"
}

$missionMateRoot = Join-Path $root '_Utilities\Mission Mate 6'
$missionMatePath = Join-Path $missionMateRoot 'FBPath.txt'
$missionMateIni = Join-Path $missionMateRoot 'MisMate.ini'
$hardballExecutable = Join-Path $root '_Utilities\HardBall408\HardBall408.exe'
foreach ($requiredPath in @($missionMatePath, $missionMateIni, $hardballExecutable)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Composant utilitaire absent : $requiredPath"
    }
}

$changes = [Collections.Generic.List[string]]::new()
if ($PSCmdlet.ShouldProcess($missionMatePath, 'Configurer le dossier IL-2 de Mission Mate')) {
    if (Write-PortableTextFile -Path $missionMatePath -Lines @($root)) {
        $changes.Add('Mission Mate : dossier IL-2')
    }
}

$missionMateLines = [Collections.Generic.List[string]]::new()
[IO.File]::ReadAllLines($missionMateIni, $textEncoding) | ForEach-Object {
    $missionMateLines.Add($_)
}
$hardballLine = 'HardballLocation|' + $hardballExecutable
$hardballIndex = -1
for ($index = 0; $index -lt $missionMateLines.Count; $index++) {
    if ($missionMateLines[$index] -like 'HardballLocation|*') {
        $hardballIndex = $index
        break
    }
}
if ($hardballIndex -lt 0) {
    $missionMateLines.Add($hardballLine)
}
else {
    $missionMateLines[$hardballIndex] = $hardballLine
}
if ($PSCmdlet.ShouldProcess($missionMateIni, 'Relier Mission Mate a HardBall')) {
    if (Write-PortableTextFile -Path $missionMateIni -Lines $missionMateLines.ToArray()) {
        $changes.Add('Mission Mate : HardBall')
    }
}

$zipNavMapSource = Join-Path $root '_Utilities\ZipNav\maps'
$zipNavMapTarget = Join-Path $root 'mods\mapmods'
if (-not $SkipZipNavMaps) {
    if (-not (Test-Path -LiteralPath $zipNavMapSource -PathType Container)) {
        throw "Cartes ZipNav absentes : $zipNavMapSource"
    }

    if (Test-Path -LiteralPath $zipNavMapTarget) {
        if (-not (Test-Path -LiteralPath $zipNavMapTarget -PathType Container)) {
            throw "Le chemin attendu par ZipNav existe mais n'est pas un dossier : $zipNavMapTarget"
        }
    }
    else {
        $zipNavParent = Split-Path -Parent $zipNavMapTarget
        if (-not (Test-Path -LiteralPath $zipNavParent -PathType Container) -and
            $PSCmdlet.ShouldProcess($zipNavParent, 'Creer le dossier de compatibilite ZipNav')) {
            New-Item -ItemType Directory -Path $zipNavParent -Force | Out-Null
        }

        if ($PSCmdlet.ShouldProcess($zipNavMapTarget, "Relier les cartes ZipNav sans les dupliquer depuis $zipNavMapSource")) {
            New-Item -ItemType Junction -Path $zipNavMapTarget -Target $zipNavMapSource | Out-Null
            $changes.Add('ZipNav : cartes disponibles sous mods\mapmods')
        }
    }
}

# DeviceLink and aspect/FOV settings belong to the player. San FOV is no longer shipped.

[pscustomobject]@{
    InstallationRoot = $root
    Changes = $changes.ToArray()
    ZipNavMapPath = if ($SkipZipNavMaps) { $null } else { $zipNavMapTarget }
    Status = if ($changes.Count -eq 0) { 'DEJA_CONFIGURE' } else { 'CONFIGURE' }
}
