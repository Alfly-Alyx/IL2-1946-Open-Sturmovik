[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946 Selector Dump',
    [ValidateSet('cold','warm')][string]$CacheState = 'cold',
    [ValidateRange(30, 600)][int]$WaitForGameSeconds = 180,
    [switch]$SkipProcmon,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$captureTool = Join-Path $PSScriptRoot 'Start-IL2StartupCapture.ps1'

& $captureTool `
    -GameRoot $GameRoot `
    -Profile 8 `
    -SelectorDumpLab `
    -CacheState $CacheState `
    -Windowed1024 `
    -WaitForGameSeconds $WaitForGameSeconds `
    -SkipProcmon:$SkipProcmon `
    -ValidateOnly:$ValidateOnly
