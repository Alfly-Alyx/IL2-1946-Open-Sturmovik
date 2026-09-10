param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($RepositoryRoot)
$backgroundRoot = Join-Path $root '_Game Switcher\Resources\Loading Backgrounds'
$manifestPath = Join-Path $backgroundRoot 'manifest.json'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Manifest missing: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$expectedThemes = @(
    'Maddox',
    'Forgotten Battles 2003 Remaster',
    'Helmet Red 2001',
    'IL-2 2001 Box Art',
    'Helmet Green 2001'
)
$expectedFormats = @{
    '4x3' = @(2880, 2160)
    '16x10' = @(3456, 2160)
    '16x9' = @(3840, 2160)
    '21x9' = @(3840, 1646)
    '32x9' = @(3840, 1080)
}

$themeNames = @($manifest.themes | ForEach-Object { [string]$_.name })
foreach ($theme in $expectedThemes) {
    if ($themeNames -notcontains $theme) {
        throw "Theme missing from manifest: $theme"
    }
}

$logoSource = Join-Path $backgroundRoot 'Shared\Sources\Maddox-Games-trademark-RBC-original.jpg'
$logoMaster = Join-Path $backgroundRoot 'Shared\Maddox-Games-Official-Gold.png'
if ((Get-FileHash -LiteralPath $logoSource -Algorithm SHA256).Hash -ne
    [string]$manifest.maddoxGamesSource.sourceSha256) {
    throw 'Registered Maddox Games source hash mismatch'
}
if ((Get-FileHash -LiteralPath $logoMaster -Algorithm SHA256).Hash -ne
    [string]$manifest.maddoxGamesSource.derivedMasterSha256) {
    throw 'Derived Maddox Games master hash mismatch'
}

foreach ($theme in @($manifest.themes)) {
    foreach ($output in @($theme.outputs)) {
        $name = [string]$output.format
        if (-not $expectedFormats.ContainsKey($name)) {
            throw "Unexpected format: $name"
        }
        $formatRoot = Join-Path $backgroundRoot (
            ([string]$theme.name) + '\' + $name
        )
        $png = Join-Path $formatRoot 'Background.png'
        $tga = Join-Path $formatRoot 'Background.tga'
        $preview = Join-Path $formatRoot 'Preview.jpg'
        foreach ($path in @($png, $tga, $preview)) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                throw "Output missing: $path"
            }
        }
        if ((Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash -ne
            [string]$output.pngSha256) {
            throw "PNG hash mismatch: $png"
        }
        if ((Get-FileHash -LiteralPath $tga -Algorithm SHA256).Hash -ne
            [string]$output.tgaSha256) {
            throw "TGA hash mismatch: $tga"
        }
        $header = [IO.File]::ReadAllBytes($tga)
        $width = [BitConverter]::ToUInt16($header, 12)
        $height = [BitConverter]::ToUInt16($header, 14)
        $expected = $expectedFormats[$name]
        if ($width -ne $expected[0] -or $height -ne $expected[1]) {
            throw "TGA dimensions mismatch: $tga ($width x $height)"
        }
        if ($width -gt 3840 -or $height -gt 2160) {
            throw "TGA exceeds 4K canvas: $tga"
        }
    }
}

$icons = Join-Path $root '_Game Switcher\Resources\Icons'
foreach ($name in @(
    'IL2-2001-Demo__icone-extraite-executable.ico',
    'OFFICIEL-Steam__IL2-1946__icone-communaute.jpg',
    'Open_Sturmovik_Switcher_Original.ico',
    'Open_Sturmovik_Switcher.ico'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $icons $name) -PathType Leaf)) {
        throw "Icon missing: $name"
    }
}

$guiBackgrounds = Join-Path $root '_Game Switcher\Resources\Backgrounds'
foreach ($name in @('1.png', '2.png', '3.png')) {
    if (-not (Test-Path -LiteralPath (Join-Path $guiBackgrounds $name) -PathType Leaf)) {
        throw "Switcher background missing: $name"
    }
}

$message = (
    "PASS: {0} themes x {1} formats, authentic Maddox master, " +
    "4 icons and 3 switcher backgrounds verified."
) -f $expectedThemes.Count, $expectedFormats.Count
Write-Host $message
