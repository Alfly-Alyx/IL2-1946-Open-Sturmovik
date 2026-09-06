[CmdletBinding()]
param(
    [string]$GameRoot,
    [ValidateSet('cold','warm')][string]$CacheState = 'cold',
    [ValidateRange(30, 600)][int]$WaitForGameSeconds = 180,
    [switch]$WithFileTrace,
    [switch]$SkipProcmon,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameRoot)) {
    $GameRoot = Join-Path $PSScriptRoot '..\WIP\test-installations\IL 2 Sturmovik 1946 test'
}
$captureTool = Join-Path $PSScriptRoot 'Start-IL2StartupCapture.ps1'

& $captureTool `
    -GameRoot $GameRoot `
    -Profile 9 `
    -CacheState $CacheState `
    -Windowed1024 `
    -ExcludeNuclear `
    -WaitForGameSeconds $WaitForGameSeconds `
    -SkipProcmon:($SkipProcmon -or -not $WithFileTrace) `
    -ValidateOnly:$ValidateOnly
