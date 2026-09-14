[CmdletBinding()]
param(
    [string]$GameRoot,
    [ValidateSet('8','9')][string]$Profile = '9',
    [ValidateSet('cold','warm')][string]$CacheState = 'warm',
    [switch]$WithFileTrace,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Join-Path $PSScriptRoot '..\..\tests\installations\IL 2 Sturmovik 1946 test'
}
$captureTool = Join-Path $PSScriptRoot 'Start-IL2StartupCapture.ps1'

& $captureTool `
    -GameRoot $GameRoot `
    -Profile $Profile `
    -CacheState $CacheState `
    -Windowed1024 `
    -DeferCrashOrHang `
    -SkipProcmon:(-not $WithFileTrace) `
    -ValidateOnly:$ValidateOnly

if (-not $?) {
    exit 1
}
