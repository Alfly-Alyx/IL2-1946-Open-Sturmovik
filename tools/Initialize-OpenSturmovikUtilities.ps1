[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallationRoot,

    [string]$DeviceLinkAddress,

    [switch]$SkipDeviceLink,

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

function Set-IniValues {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Sections
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Fichier INI absent : $Path"
    }

    $lines = [Collections.Generic.List[string]]::new()
    [IO.File]::ReadAllLines($Path, $textEncoding) | ForEach-Object {
        $lines.Add($_)
    }

    foreach ($sectionName in $Sections.Keys) {
        $sectionIndex = -1
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^\s*\[([^]]+)\]\s*$' -and
                $Matches[1] -ieq [string]$sectionName) {
                $sectionIndex = $index
                break
            }
        }

        if ($sectionIndex -lt 0) {
            if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') {
                $lines.Add('')
            }
            $lines.Add("[$sectionName]")
            foreach ($key in $Sections[$sectionName].Keys) {
                $lines.Add("$key=$($Sections[$sectionName][$key])")
            }
            continue
        }

        $sectionEnd = $lines.Count
        for ($index = $sectionIndex + 1; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -match '^\s*\[[^]]+\]\s*$') {
                $sectionEnd = $index
                break
            }
        }

        foreach ($key in $Sections[$sectionName].Keys) {
            # PowerShell variable names are case-insensitive. Do not call this
            # list $matches: the -match operator overwrites the automatic
            # $Matches hashtable before the index is appended.
            $matchingIndexes = [Collections.Generic.List[int]]::new()
            $keyPattern = '^\s*' + [regex]::Escape([string]$key) + '\s*='
            for ($index = $sectionIndex + 1; $index -lt $sectionEnd; $index++) {
                if ($lines[$index] -match $keyPattern) {
                    $matchingIndexes.Add($index)
                }
            }

            $valueLine = "$key=$($Sections[$sectionName][$key])"
            if ($matchingIndexes.Count -eq 0) {
                $lines.Insert($sectionEnd, $valueLine)
                $sectionEnd++
            }
            else {
                $lines[$matchingIndexes[0]] = $valueLine
                for ($matchIndex = $matchingIndexes.Count - 1; $matchIndex -ge 1; $matchIndex--) {
                    $lines.RemoveAt($matchingIndexes[$matchIndex])
                    $sectionEnd--
                }
            }
        }
    }

    return Write-PortableTextFile -Path $Path -Lines $lines.ToArray()
}

function Get-PreferredLocalIpv4 {
    $candidates = foreach ($adapter in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($adapter.OperationalStatus -ne [Net.NetworkInformation.OperationalStatus]::Up -or
            $adapter.NetworkInterfaceType -eq [Net.NetworkInformation.NetworkInterfaceType]::Loopback) {
            continue
        }

        $properties = $adapter.GetIPProperties()
        $hasGateway = @($properties.GatewayAddresses | Where-Object {
            $_.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and
            -not $_.Address.Equals([Net.IPAddress]::Any)
        }).Count -gt 0

        foreach ($unicast in $properties.UnicastAddresses) {
            if ($unicast.Address.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork -and
                -not [Net.IPAddress]::IsLoopback($unicast.Address)) {
                [pscustomobject]@{
                    Address = $unicast.Address.IPAddressToString
                    HasGateway = $hasGateway
                    Adapter = $adapter.Name
                }
            }
        }
    }

    $preferred = $candidates | Sort-Object HasGateway -Descending | Select-Object -First 1
    if ($null -eq $preferred) {
        throw 'Aucune adresse IPv4 locale non loopback active pour DeviceLink.'
    }

    return $preferred.Address
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

if (-not $SkipDeviceLink) {
    $deviceLinkDocumentation = Join-Path $root 'DeviceLink.txt'
    $confIni = Join-Path $root 'conf.ini'
    $fovPreference = Join-Path $root "_Game_Enhancements\San's IL2 FOV Changer\pref.ini"
    foreach ($requiredPath in @($deviceLinkDocumentation, $confIni, $fovPreference)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Composant DeviceLink/FOV absent : $requiredPath"
        }
    }

    if ([string]::IsNullOrWhiteSpace($DeviceLinkAddress)) {
        $DeviceLinkAddress = Get-PreferredLocalIpv4
    }

    $parsedAddress = $null
    if (-not [Net.IPAddress]::TryParse($DeviceLinkAddress, [ref]$parsedAddress) -or
        $parsedAddress.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork -or
        [Net.IPAddress]::IsLoopback($parsedAddress)) {
        throw "Adresse DeviceLink invalide ou loopback : $DeviceLinkAddress"
    }

    $iniValues = [ordered]@{
        window = [ordered]@{
            SaveAspect = '0'
        }
        DeviceLink = [ordered]@{
            port = '1711'
            host = $DeviceLinkAddress
            IPS = $DeviceLinkAddress
        }
    }

    if ($PSCmdlet.ShouldProcess($confIni, "Configurer DeviceLink sur $DeviceLinkAddress`:1711")) {
        if (Set-IniValues -Path $confIni -Sections $iniValues) {
            $changes.Add("DeviceLink : $DeviceLinkAddress`:1711")
        }
    }
}

[pscustomobject]@{
    InstallationRoot = $root
    Changes = $changes.ToArray()
    DeviceLinkAddress = if ($SkipDeviceLink) { $null } else { $DeviceLinkAddress }
    DeviceLinkPort = if ($SkipDeviceLink) { $null } else { 1711 }
    ZipNavMapPath = if ($SkipZipNavMaps) { $null } else { $zipNavMapTarget }
    Status = if ($changes.Count -eq 0) { 'DEJA_CONFIGURE' } else { 'CONFIGURE' }
}
