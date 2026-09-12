[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$InstallationRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
    [switch]$StartNow,
    [switch]$Remove
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($InstallationRoot).TrimEnd('\')
$state = [IO.Path]::GetFullPath($StateRoot).TrimEnd('\')
$watcher = Join-Path $root 'tools\Watch-OpenSturmovikDiagnostics.ps1'
$collector = Join-Path $root 'tools\Collect-OpenSturmovikDiagnostic.ps1'
$sender = Join-Path $root 'tools\Send-OpenSturmovikDiagnostic.ps1'
$dumpReader = Join-Path $root 'tools\Read-OpenSturmovikMinidump.ps1'
$loggingTool = Join-Path $root 'tools\Set-IL2StartupDiagnostics.ps1'
$runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName = 'OpenSturmovikDiagnostics'
$werKey = 'HKCU:\Software\Microsoft\Windows\Windows Error Reporting\LocalDumps\il2fb.exe'

$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if (-not (Test-Path -LiteralPath $windowsPowerShell -PathType Leaf)) {
    $currentPowerShell = Get-Process -Id $PID
    $windowsPowerShell = $currentPowerShell.Path
}

function Stop-DiagnosticWatcher {
    foreach ($process in @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" -ErrorAction SilentlyContinue)) {
        if ([string]$process.CommandLine -like "*$watcher*" -and [string]$process.CommandLine -like "*$root*") {
            if ($PSCmdlet.ShouldProcess("PID $($process.ProcessId)", 'Arreter le moniteur Open Sturmovik')) {
                Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

if ($Remove) {
    Stop-DiagnosticWatcher
    $configurationBackup = (Join-Path $root 'conf.ini') + '.open-sturmovik-diagnostics.bak'
    if ((Test-Path -LiteralPath $loggingTool -PathType Leaf) -and (Test-Path -LiteralPath $configurationBackup -PathType Leaf)) {
        if ($PSCmdlet.ShouldProcess((Join-Path $root 'conf.ini'), 'Restaurer la configuration anterieure des journaux IL-2')) {
            & $loggingTool -GameRoot $root -Restore | Out-Null
        }
    }
    if (Test-Path -LiteralPath $runKey) {
        if ($PSCmdlet.ShouldProcess("$runKey\$runName", 'Supprimer le demarrage automatique')) {
            Remove-ItemProperty -LiteralPath $runKey -Name $runName -ErrorAction SilentlyContinue
        }
    }
    if (Test-Path -LiteralPath $werKey) {
        if ($PSCmdlet.ShouldProcess($werKey, 'Supprimer la capture WER configuree par Open Sturmovik')) {
            Remove-Item -LiteralPath $werKey -Force
        }
    }
    [pscustomobject]@{ Status = if ($WhatIfPreference) { 'REMOVE_SIMULATED' } else { 'REMOVED' }; InstallationRoot = $root; StateRoot = $state }
    exit 0
}

if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw "Depot GitHub invalide : $Repository" }
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Installation introuvable : $root" }
if (-not (Test-Path -LiteralPath (Join-Path $root 'il2fb.exe') -PathType Leaf)) { throw "il2fb.exe absent : $root" }
foreach ($required in @($watcher,$collector,$sender,$dumpReader,$loggingTool)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Composant de diagnostic absent : $required" }
}

$dumpRoot = Join-Path $state 'Dumps'
$queueRoot = Join-Path $state 'Queue'
$sessionRoot = Join-Path $state 'Sessions'
$configPath = Join-Path $state 'config.json'
$arguments = @(
    '-NoLogo','-NoProfile','-NonInteractive','-WindowStyle','Hidden','-ExecutionPolicy','Bypass',
    '-File',('"' + $watcher + '"'),
    '-GameRoot',('"' + $root + '"'),
    '-Repository',('"' + $Repository + '"'),
    '-StateRoot',('"' + $state + '"')
)
$runCommand = '"' + $windowsPowerShell + '" ' + ($arguments -join ' ')

if ($PSCmdlet.ShouldProcess($state, 'Creer le stockage local des diagnostics')) {
    New-Item -ItemType Directory -Path $state,$dumpRoot,$queueRoot,$sessionRoot -Force | Out-Null
    $config = [ordered]@{
        schema_version = 1
        enabled = $true
        installed_utc = [DateTime]::UtcNow.ToString('O')
        game_root = $root
        repository = $Repository
        state_root = $state
        queue_root = $queueRoot
        dump_root = $dumpRoot
        transport = 'GitHub Issues API; DPAPI token, environment token, or Git Credential Manager'
        privacy = 'sanitized text only; raw memory dumps remain local'
    }
    $config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8
}

if ($PSCmdlet.ShouldProcess((Join-Path $root 'conf.ini'), 'Activer les journaux persistants IL-2')) {
    & $loggingTool -GameRoot $root | Out-Null
}

if ($PSCmdlet.ShouldProcess($werKey, 'Configurer les dumps complets Windows Error Reporting')) {
    New-Item -Path $werKey -Force | Out-Null
    New-ItemProperty -LiteralPath $werKey -Name DumpFolder -PropertyType String -Value $dumpRoot -Force | Out-Null
    New-ItemProperty -LiteralPath $werKey -Name DumpCount -PropertyType DWord -Value 5 -Force | Out-Null
    New-ItemProperty -LiteralPath $werKey -Name DumpType -PropertyType DWord -Value 2 -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess("$runKey\$runName", 'Activer le moniteur au demarrage de session')) {
    New-Item -Path $runKey -Force | Out-Null
    New-ItemProperty -LiteralPath $runKey -Name $runName -PropertyType String -Value $runCommand -Force | Out-Null
}

if ($StartNow -and $PSCmdlet.ShouldProcess($watcher, 'Demarrer le moniteur de diagnostic')) {
    Stop-DiagnosticWatcher
    Start-Process -FilePath $windowsPowerShell -ArgumentList $arguments -WindowStyle Hidden | Out-Null
}

[pscustomobject]@{
    Status = if ($WhatIfPreference) { 'INSTALL_SIMULATED' } else { 'INSTALLED' }
    InstallationRoot = $root
    Repository = $Repository
    StateRoot = $state
    Configuration = $configPath
    DumpFolder = $dumpRoot
    AutoStart = $runCommand
    Started = [bool]($StartNow -and -not $WhatIfPreference)
}
