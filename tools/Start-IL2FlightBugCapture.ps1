[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 test',
    [ValidateSet('8','9')][string]$Profile = '9',
    [ValidateSet('cold','warm')][string]$CacheState = 'warm',
    [switch]$WithFileTrace,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$captureTool = Join-Path $PSScriptRoot 'Start-IL2StartupCapture.ps1'

& $captureTool `
    -GameRoot $GameRoot `
    -Profile $Profile `
    -CacheState $CacheState `
    -Windowed1024 `
    -CaptureCrashOrHang `
    -SkipProcmon:(-not $WithFileTrace) `
    -ValidateOnly:$ValidateOnly

if (-not $?) {
    exit 1
}
