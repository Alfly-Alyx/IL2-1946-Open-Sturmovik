[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$Output = 'manifests\engine\reverse-engineering-snapshot-v1.15.json'
)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
$filesPath = Join-Path $rootPath 'Files'
if (-not (Test-Path -LiteralPath $filesPath -PathType Container)) {
    throw "Dossier Files introuvable : $filesPath"
}

function Get-RelativePath([string]$Path) {
    return $Path.Substring($rootPath.Length + 1).Replace('\', '/')
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Read-Prefix([string]$Path, [int]$Count) {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $buffer = New-Object byte[] $Count
        $read = $stream.Read($buffer, 0, $Count)
        if ($read -eq $Count) {
            return $buffer
        }
        if ($read -eq 0) {
            return [byte[]]@()
        }
        return [byte[]]$buffer[0..($read - 1)]
    }
    finally {
        $stream.Dispose()
    }
}

$allFiles = @(Get-ChildItem -LiteralPath $filesPath -Recurse -File)
$allDirs = @(Get-ChildItem -LiteralPath $filesPath -Recurse -Directory)

$extensions = @(
    $allFiles |
        Group-Object { if ([string]::IsNullOrEmpty($_.Extension)) { '(none)' } else { $_.Extension.ToLowerInvariant() } } |
        ForEach-Object {
            [ordered]@{
                extension = $_.Name
                files = $_.Count
                bytes = [long](($_.Group | Measure-Object -Property Length -Sum).Sum)
            }
        } |
        Sort-Object @{Expression = { $_.files }; Descending = $true}, extension
)

$zones = @()
foreach ($zoneName in @('3do', 'Maps', 'Samples', 'com', 'gui', 'presets')) {
    $zonePath = Join-Path $filesPath $zoneName
    if (Test-Path -LiteralPath $zonePath -PathType Container) {
        $zoneFiles = @($allFiles | Where-Object { $_.FullName.StartsWith($zonePath + '\', [StringComparison]::OrdinalIgnoreCase) })
        $zones += [ordered]@{
            name = $zoneName
            files = $zoneFiles.Count
            bytes = [long](($zoneFiles | Measure-Object -Property Length -Sum).Sum)
        }
    }
}

$runtimeFiles = @()
foreach ($file in @(Get-ChildItem -LiteralPath $rootPath -File | Where-Object {
    $_.Extension -match '^\.(exe|dll|sfs)$'
} | Sort-Object Name)) {
    $runtimeFiles += [ordered]@{
        path = Get-RelativePath $file.FullName
        bytes = [long]$file.Length
        sha256 = Get-Sha256 $file.FullName
    }
}

$classMajors = @{}
$classFiles = @($allFiles | Where-Object {
    $_.DirectoryName -eq $filesPath -and $_.Name -match '^[0-9A-Fa-f]{16}$'
})
$classMagicCount = 0
foreach ($file in $classFiles) {
    $prefix = Read-Prefix $file.FullName 8
    if ($prefix.Length -eq 8 -and
        $prefix[0] -eq 0xCA -and $prefix[1] -eq 0xFE -and
        $prefix[2] -eq 0xBA -and $prefix[3] -eq 0xBE) {
        $classMagicCount++
        $major = [int]$prefix[6] * 256 + [int]$prefix[7]
        $key = [string]$major
        if (-not $classMajors.ContainsKey($key)) {
            $classMajors[$key] = 0
        }
        $classMajors[$key]++
    }
}
$majorRows = @($classMajors.GetEnumerator() | Sort-Object { [int]$_.Key } | ForEach-Object {
    [ordered]@{ major = [int]$_.Key; files = [int]$_.Value }
})

$tgaFiles = @($allFiles | Where-Object { $_.Extension -ieq '.tga' })
$imfTgaCount = 0
foreach ($file in $tgaFiles) {
    $prefix = Read-Prefix $file.FullName 6
    if ($prefix.Length -eq 6 -and
        $prefix[0] -eq 0x49 -and $prefix[1] -eq 0x4D -and
        $prefix[2] -eq 0x46 -and $prefix[3] -eq 0x1A -and
        $prefix[4] -eq 0x31 -and $prefix[5] -eq 0x30) {
        $imfTgaCount++
    }
}

$effectClassCounts = @{}
$effectFieldCounts = @{}
$effectFiles = @($allFiles | Where-Object { $_.Extension -ieq '.eff' })
foreach ($file in $effectFiles) {
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        if ($line -match '^\s*ClassName\s+(.+?)\s*$') {
            $name = $Matches[1]
            if (-not $effectClassCounts.ContainsKey($name)) { $effectClassCounts[$name] = 0 }
            $effectClassCounts[$name]++
        }
        elseif ($line -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s+.+$') {
            $name = $Matches[1]
            if (-not $effectFieldCounts.ContainsKey($name)) { $effectFieldCounts[$name] = 0 }
            $effectFieldCounts[$name]++
        }
    }
}

function Convert-CountMap($Map, [string]$NameKey) {
    return @($Map.GetEnumerator() | Sort-Object Name | ForEach-Object {
        $row = [ordered]@{}
        $row[$NameKey] = $_.Name
        $row['occurrences'] = [int]$_.Value
        $row
    })
}

function Count-IniEntries([string]$Path, [string]$Section) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $inside = $false
    $count = 0
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[(.+)\]$') {
            $inside = $Matches[1] -ieq $Section
            continue
        }
        if ($inside -and $trimmed.Length -gt 0 -and -not $trimmed.StartsWith(';') -and -not $trimmed.StartsWith('#')) {
            $count++
        }
    }
    return $count
}

$snapshot = [ordered]@{
    schema = 'open-sturmovik.reverse-engineering-snapshot.v1'
    target = [ordered]@{
        addon_version = '1.15'
        game_runtime = 'IL-2 Sturmovik 1946 4.09m modified'
        process_architecture = 'x86'
        java_runtime = 'HotSpot 1.3.1'
        maximum_supported_class_major = 47
    }
    evidence_policy = [ordered]@{
        static = 'Observed directly in files, headers, bytecode or configuration.'
        runtime = 'Observed in a captured game session and retained with raw evidence.'
        inferred = 'Consistent with evidence but not yet isolated by a controlled test.'
        unknown = 'Must not be presented as established behavior.'
    }
    repository_runtime_files = $runtimeFiles
    loose_content = [ordered]@{
        root = 'Files'
        files = $allFiles.Count
        directories = $allDirs.Count
        bytes = [long](($allFiles | Measure-Object -Property Length -Sum).Sum)
        zones = $zones
        extensions = $extensions
    }
    java_loose_classes = [ordered]@{
        hexadecimal_root_names = $classFiles.Count
        cafebabe_headers = $classMagicCount
        by_major = $majorRows
    }
    textures = [ordered]@{
        tga_extension_files = $tgaFiles.Count
        imf_1a10_signature_files = $imfTgaCount
        warning = 'The .tga extension does not prove a standard TGA stream. IMF containers require an IL-2-aware decoder.'
    }
    effects = [ordered]@{
        files = $effectFiles.Count
        classes = Convert-CountMap $effectClassCounts 'class_name'
        fields = Convert-CountMap $effectFieldCounts 'field_name'
        observed_409m_bounds = [ordered]@{
            nParticles = [ordered]@{ min = 1; max = 512 }
            FinishTime = [ordered]@{ min = -1; max = 10000 }
            MaxR = [ordered]@{ min = 0; max = 32 }
            PhiN = [ordered]@{ min = 0; max = 32 }
            PsiN = [ordered]@{ min = 0; max = 32 }
            LiveTime = [ordered]@{ min = 0.01; max = 128 }
            Wind = [ordered]@{ min = 0; max = 100 }
            Rnd = [ordered]@{ min = 0; max = 0.95 }
        }
    }
    registries = [ordered]@{
        air_ini_entries = Count-IniEntries (Join-Path $filesPath 'com\maddox\il2\objects\air.ini') 'AIR'
        maps_all_ini_entries = Count-IniEntries (Join-Path $filesPath 'Maps\all.ini') 'all'
    }
    reproducible_tools = @(
        'tools/Analyze-Sfs.py',
        'tools/Audit-PeBinaries.ps1',
        'tools/Disassemble-IL2PE.py',
        'tools/Audit-JavaClasses.py',
        'tools/Analyze-IL2Minidump.py',
        'tools/Analyze-IL2HotSpot131.py',
        'tools/Inspect-IL2HotSpotObject.py',
        'tools/Audit-ButtonsFlightModels.py',
        'tools/Normalize-EffectLimits.py',
        'tools/Start-IL2StartupCapture.ps1'
    )
}

$outputPath = if ([IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path $rootPath $Output }
$outputDir = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $outputDir -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}
$json = $snapshot | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($outputPath, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Host "INSTANTANE_RETROINGENIERIE : $outputPath" -ForegroundColor Green
Write-Host "FILES=$($allFiles.Count) DIRECTORIES=$($allDirs.Count) BYTES=$(($snapshot.loose_content.bytes)) CLASSES=$classMagicCount EFF=$($effectFiles.Count) IMF_TGA=$imfTgaCount"
