[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,
    [switch]$Launch
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$gamePath = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$confPath = Join-Path $gamePath 'conf.ini'
$gameExe = Join-Path $gamePath 'il2fb.exe'

if (-not (Test-Path -LiteralPath $confPath)) {
    throw "conf.ini absent : $confPath"
}
if ($Launch -and -not (Test-Path -LiteralPath $gameExe)) {
    throw "il2fb.exe absent : $gameExe"
}
if ($Launch -and (Get-Process -Name il2fb -ErrorAction SilentlyContinue)) {
    throw 'IL-2 est deja lance.'
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class OpenSturmovikDisplayMode
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct DEVMODE
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplaySettings(
        string deviceName,
        int modeNumber,
        ref DEVMODE mode);
}
"@

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
if ($null -eq $screen) {
    throw 'Aucun ecran principal detecte.'
}

$mode = New-Object OpenSturmovikDisplayMode+DEVMODE
$mode.dmSize = [Runtime.InteropServices.Marshal]::SizeOf($mode)
$modeRead = [OpenSturmovikDisplayMode]::EnumDisplaySettings(
    $screen.DeviceName,
    -1,
    [ref]$mode)

if ($modeRead -and ($mode.dmPelsWidth -ge 640) -and ($mode.dmPelsHeight -ge 480)) {
    $width = $mode.dmPelsWidth
    $height = $mode.dmPelsHeight
}
else {
    $width = $screen.Bounds.Width
    $height = $screen.Bounds.Height
}

$content = [IO.File]::ReadAllText($confPath)
$values = @{
    width = $width
    height = $height
    ChangeScreenRes = 1
    FullScreen = 1
    SaveAspect = 0
}

foreach ($name in $values.Keys) {
    $pattern = '(?m)^' + [regex]::Escape($name) + '=\d+'
    $expression = New-Object Text.RegularExpressions.Regex($pattern)
    if ($expression.Matches($content).Count -ne 1) {
        throw "Valeur $name absente ou dupliquee dans $confPath"
    }
    $content = $expression.Replace(
        $content,
        ($name + '=' + $values[$name]),
        1)
}

$tempPath = $confPath + '.native-resolution.tmp'
[IO.File]::WriteAllText(
    $tempPath,
    $content,
    (New-Object Text.UTF8Encoding($false)))
Move-Item -LiteralPath $tempPath -Destination $confPath -Force

$ratio = [double]$width / [double]$height
if ($ratio -le 1.420) {
    $backgroundFormat = '4x3'
}
elseif ($ratio -le 1.700) {
    $backgroundFormat = '16x10'
}
elseif ($ratio -le 2.050) {
    $backgroundFormat = '16x9'
}
elseif ($ratio -le 2.800) {
    $backgroundFormat = '21x9'
}
else {
    $backgroundFormat = '32x9'
}

$backgroundSource = Join-Path $gamePath "_Game Switcher\Resources\Loading Backgrounds\Maddox\$backgroundFormat\Background.tga"
$backgroundDestination = Join-Path $gamePath 'Files\background0.tga'
if (-not (Test-Path -LiteralPath $backgroundSource -PathType Leaf)) {
    throw "Fond de chargement $backgroundFormat absent : $backgroundSource"
}
$backgroundDirectory = [IO.Path]::GetDirectoryName($backgroundDestination)
if (-not (Test-Path -LiteralPath $backgroundDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $backgroundDirectory | Out-Null
}
$backgroundTemp = $backgroundDestination + '.native-resolution.tmp'
Copy-Item -LiteralPath $backgroundSource -Destination $backgroundTemp -Force
Move-Item -LiteralPath $backgroundTemp -Destination $backgroundDestination -Force

$statePath = Join-Path $gamePath '_Game Switcher\active-profile.txt'
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    $stateContent = [IO.File]::ReadAllText($statePath)
    $stateValues = @{
        background = $backgroundFormat
        resolution = "${width}x${height}"
    }
    foreach ($name in $stateValues.Keys) {
        $statePattern = '(?m)^' + [regex]::Escape($name) + '=.*$'
        $stateExpression = New-Object Text.RegularExpressions.Regex($statePattern)
        if ($stateExpression.Matches($stateContent).Count -ne 1) {
            throw "Valeur $name absente ou dupliquee dans $statePath"
        }
        $stateContent = $stateExpression.Replace(
            $stateContent,
            ($name + '=' + $stateValues[$name]),
            1)
    }
    $stateTemp = $statePath + '.native-resolution.tmp'
    [IO.File]::WriteAllText(
        $stateTemp,
        $stateContent,
        (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $stateTemp -Destination $statePath -Force
}
$result = [pscustomobject]@{
    Screen = $screen.DeviceName
    Width = $width
    Height = $height
    ConfIni = $confPath
    LoadingBackground = $backgroundDestination
    BackgroundFormat = $backgroundFormat
    Launched = $false
}

if ($Launch) {
    $process = Start-Process -FilePath $gameExe -WorkingDirectory $gamePath -PassThru
    $result.Launched = $true
    $result | Add-Member -NotePropertyName ProcessId -NotePropertyValue $process.Id
}

$result