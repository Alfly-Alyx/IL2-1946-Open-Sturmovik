#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Status','Install','Enable','Disable','Remove')][string]$Action = 'Status',
    [string]$GameRoot,
    [string[]]$ImageIds = @(),
    [string]$OfficialId = '',
    [ValidateSet('shuffle','ordered')][string]$Mode = 'shuffle'
)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($GameRoot)) { $GameRoot = Split-Path -Parent $PSScriptRoot }
Import-Module (Join-Path $PSScriptRoot 'OpenSturmovik.LoadingRotation.psm1') -Force
Set-OSLoadingRotation -GameRoot $GameRoot -Action $Action -ImageIds $ImageIds -OfficialId $OfficialId -Mode $Mode
