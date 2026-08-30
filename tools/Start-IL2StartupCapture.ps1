[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [string]$ReferenceRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946',
    [string]$ResultsRoot = (Join-Path $PSScriptRoot '..\test-results\startup'),
    [string]$ProcmonPath = (Join-Path $PSScriptRoot '..\build\test-tools\sysinternals\Procmon64.exe'),
    [string]$FrameCapturePath = (Join-Path $PSScriptRoot '..\build\test-tools\FrameCapture.exe'),
    [ValidateRange(1, 30)][int]$FrameRate = 10,
    [ValidateRange(50, 1000)][int]$SampleIntervalMs = 100,
    [ValidateRange(30, 600)][int]$WaitForGameSeconds = 180,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedReference = (Resolve-Path -LiteralPath $ReferenceRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedResults = [IO.Path]::GetFullPath($ResultsRoot)
$resolvedProcmon = [IO.Path]::GetFullPath($ProcmonPath)
$resolvedFrameCapture = [IO.Path]::GetFullPath($FrameCapturePath)
$readinessTool = Join-Path $PSScriptRoot 'Test-IL2StartupReadiness.ps1'

if ($ValidateOnly) {
    $reportPath = Join-Path $resolvedResults 'readiness-latest.json'
    & $readinessTool -GameRoot $resolvedGame -ReferenceRoot $resolvedReference -RepositoryRoot $repositoryRoot -ProcmonPath $resolvedProcmon -FrameCapturePath $resolvedFrameCapture -ReportPath $reportPath
    exit 0
}

$existingRecorder = @(Get-Process -Name 'Procmon','Procmon64','FrameCapture','il2fb' -ErrorAction SilentlyContinue)
if ($existingRecorder.Count -ne 0) {
    throw "Un processus de jeu ou de capture est deja actif : $($existingRecorder.Name -join ', ')"
}

$runName = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ') + '-profile8-cold-startup'
$runRoot = Join-Path $resolvedResults $runName
$frameRoot = Join-Path $runRoot 'screen'
$logsRoot = Join-Path $runRoot 'logs'
$preexistingLogs = Join-Path $runRoot 'preexisting-logs'
New-Item -ItemType Directory -Path $runRoot, $frameRoot, $logsRoot, $preexistingLogs -Force | Out-Null
$readinessReport = Join-Path $runRoot 'readiness.json'
& $readinessTool -GameRoot $resolvedGame -ReferenceRoot $resolvedReference -RepositoryRoot $repositoryRoot -ProcmonPath $resolvedProcmon -FrameCapturePath $resolvedFrameCapture -ReportPath $readinessReport | Out-Host

$timelinePath = Join-Path $runRoot 'timeline.csv'
$metricsPath = Join-Path $runRoot 'process-metrics.csv'
$modulesPath = Join-Path $runRoot 'loaded-modules.csv'
$stopFile = Join-Path $runRoot 'stop-frame-capture.signal'
$procmonTrace = Join-Path $runRoot 'process-monitor.pml'
$wprTrace = Join-Path $runRoot 'windows-performance.etl'
$wprLog = Join-Path $runRoot 'wpr.txt'
$procmonLog = Join-Path $runRoot 'procmon.txt'
$captureStartUtc = [DateTime]::UtcNow
$captureStartLocal = Get-Date
$procmonStarted = $false
$wprStarted = $false
$frameProcess = $null
$game = $null
$completed = $false

function Write-Timeline {
    param([string]$Event, [string]$Detail = '')
    $line = '"{0}","{1}","{2}"' -f [DateTime]::UtcNow.ToString('O'), $Event.Replace('"','""'), $Detail.Replace('"','""')
    Add-Content -LiteralPath $timelinePath -Value $line -Encoding UTF8
}

'utc,event,detail' | Set-Content -LiteralPath $timelinePath -Encoding UTF8
'utc,elapsed_ms,pid,total_cpu_ms,working_set,private_bytes,virtual_bytes,threads,handles,responding' | Set-Content -LiteralPath $metricsPath -Encoding UTF8
'utc,elapsed_ms,pid,module,path,base_address,size,file_version' | Set-Content -LiteralPath $modulesPath -Encoding UTF8

$criticalRelative = @(
    'il2fb.exe','files.SFS','wrapper.dll','conf.ini',
    'Files\com\maddox\il2\objects\air.ini',
    'Files\com\maddox\il2\objects\stationary.ini'
)
$criticalSnapshot = foreach ($relative in $criticalRelative) {
    $path = Join-Path $resolvedGame $relative
    $item = Get-Item -LiteralPath $path
    [ordered]@{ path = $relative; length = $item.Length; modified_utc = $item.LastWriteTimeUtc.ToString('O'); sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
}
$referenceSnapshot = foreach ($relative in @('il2fb.exe','files.SFS','conf.ini')) {
    $path = Join-Path $resolvedReference $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $item = Get-Item -LiteralPath $path
        [ordered]@{ path = $relative; length = $item.Length; modified_utc = $item.LastWriteTimeUtc.ToString('O'); sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
    }
}
$environment = [ordered]@{
    run = $runName
    started_utc = $captureStartUtc.ToString('O')
    game_root = $resolvedGame
    reference_root = $resolvedReference
    profile = '8 - 4.09m modifie (sans 6DOF), wrapper historique, OpenGL natif'
    frame_rate = $FrameRate
    sample_interval_ms = $SampleIntervalMs
    operating_system = @(Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object Caption,Version,BuildNumber,OSArchitecture)
    processors = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed)
    graphics = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object Name,DriverVersion,AdapterRAM,CurrentHorizontalResolution,CurrentVerticalResolution,PNPDeviceID)
    physical_memory = @(Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object TotalPhysicalMemory)
    critical_files = @($criticalSnapshot)
    reference_files_before = @($referenceSnapshot)
}
$environment | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runRoot 'environment.json') -Encoding UTF8

foreach ($logName in @('log.lst','eventlog.lst','sound.log')) {
    $logPath = Join-Path $resolvedGame $logName
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        Move-Item -LiteralPath $logPath -Destination (Join-Path $preexistingLogs $logName)
    }
}

try {
    Write-Timeline -Event 'capture_preparing'
    $procmonArguments = @('/AcceptEula','/Quiet','/Minimized','/BackingFile',('"' + $procmonTrace + '"'))
    $procmonProcess = Start-Process -FilePath $resolvedProcmon -ArgumentList $procmonArguments -PassThru
    Start-Sleep -Milliseconds 1200
    if ($procmonProcess.HasExited) {
        throw "Process Monitor s est arrete pendant l armement (code $($procmonProcess.ExitCode))."
    }
    $procmonStarted = $true
    Write-Timeline -Event 'procmon_started' -Detail "pid=$($procmonProcess.Id)"

    $wprOutput = & wpr.exe -start GeneralProfile -filemode 2>&1
    $wprOutput | Set-Content -LiteralPath $wprLog -Encoding UTF8
    if ($LASTEXITCODE -ne 0) {
        throw "WPR n a pas pu demarrer : $($wprOutput -join ' ')"
    }
    $wprStarted = $true
    Write-Timeline -Event 'wpr_started'
    Write-Timeline -Event 'capture_armed' -Detail "attente il2fb.exe pendant $WaitForGameSeconds secondes"
    Write-Host "CAPTURE_ARMEE : lancez maintenant $resolvedGame\il2fb.exe" -ForegroundColor Green

    $deadline = [DateTime]::UtcNow.AddSeconds($WaitForGameSeconds)
    while ([DateTime]::UtcNow -lt $deadline -and -not $game) {
        foreach ($candidate in @(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue)) {
            try {
                if ($candidate.Path -ieq (Join-Path $resolvedGame 'il2fb.exe')) {
                    $game = $candidate
                    break
                }
            }
            catch { }
        }
        if (-not $game) { Start-Sleep -Milliseconds 50 }
    }
    if (-not $game) {
        throw "il2fb.exe n a pas ete detecte dans le delai de $WaitForGameSeconds secondes."
    }

    $game.Refresh()
    $gameStartUtc = $game.StartTime.ToUniversalTime()
    $clock = [Diagnostics.Stopwatch]::StartNew()
    Write-Timeline -Event 'game_detected' -Detail "pid=$($game.Id); start=$($gameStartUtc.ToString('O'))"
    $frameArguments = @(
        '--process-id', $game.Id,
        '--output', ('"' + $frameRoot + '"'),
        '--stop-file', ('"' + $stopFile + '"'),
        '--fps', $FrameRate,
        '--quality', 82
    )
    $frameProcess = Start-Process -FilePath $resolvedFrameCapture -ArgumentList $frameArguments -PassThru
    Write-Timeline -Event 'frame_capture_started' -Detail "pid=$($frameProcess.Id)"

    $knownModules = @{}
    $nextModuleSnapshot = 0L
    while (-not $game.HasExited) {
        try {
            $game.Refresh()
            $responding = $false
            try { $responding = $game.Responding } catch { }
            $metric = '"{0}",{1},{2},{3},{4},{5},{6},{7},{8},{9}' -f
                [DateTime]::UtcNow.ToString('O'), $clock.ElapsedMilliseconds, $game.Id,
                [Math]::Round($game.TotalProcessorTime.TotalMilliseconds, 3),
                $game.WorkingSet64, $game.PrivateMemorySize64, $game.VirtualMemorySize64,
                $game.Threads.Count, $game.HandleCount, $responding
            Add-Content -LiteralPath $metricsPath -Value $metric -Encoding UTF8

            if ($clock.ElapsedMilliseconds -ge $nextModuleSnapshot) {
                $nextModuleSnapshot = $clock.ElapsedMilliseconds + 500
                try {
                    foreach ($module in $game.Modules) {
                        $moduleKey = $module.FileName.ToLowerInvariant()
                        if (-not $knownModules.ContainsKey($moduleKey)) {
                            $knownModules[$moduleKey] = $true
                            $version = ''
                            try { $version = $module.FileVersionInfo.FileVersion } catch { }
                            $moduleLine = '"{0}",{1},{2},"{3}","{4}","0x{5:X}",{6},"{7}"' -f
                                [DateTime]::UtcNow.ToString('O'), $clock.ElapsedMilliseconds, $game.Id,
                                $module.ModuleName.Replace('"','""'), $module.FileName.Replace('"','""'),
                                $module.BaseAddress.ToInt64(), $module.ModuleMemorySize, ([string]$version).Replace('"','""')
                            Add-Content -LiteralPath $modulesPath -Value $moduleLine -Encoding UTF8
                        }
                    }
                }
                catch { Write-Timeline -Event 'module_snapshot_error' -Detail $_.Exception.Message }
            }
        }
        catch {
            if (-not $game.HasExited) { Write-Timeline -Event 'metrics_error' -Detail $_.Exception.Message }
        }
        Start-Sleep -Milliseconds $SampleIntervalMs
    }
    $game.Refresh()
    Write-Timeline -Event 'game_exited' -Detail "code=$($game.ExitCode)"
    $completed = $true
}
finally {
    [IO.File]::WriteAllText($stopFile, 'stop')
    if ($frameProcess -and -not $frameProcess.HasExited) {
        try { $frameProcess.WaitForExit(5000) | Out-Null } catch { }
        if (-not $frameProcess.HasExited) { Stop-Process -Id $frameProcess.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($wprStarted) {
        $wprStopOutput = & wpr.exe -stop $wprTrace 2>&1
        $wprStopOutput | Add-Content -LiteralPath $wprLog -Encoding UTF8
        Write-Timeline -Event 'wpr_stopped' -Detail "exit=$LASTEXITCODE"
    }
    if ($procmonStarted) {
        $procmonStopOutput = & $resolvedProcmon /Terminate /Quiet 2>&1
        $procmonStopOutput | Set-Content -LiteralPath $procmonLog -Encoding UTF8
        Write-Timeline -Event 'procmon_stopped' -Detail "exit=$LASTEXITCODE"
    }

    foreach ($logName in @('log.lst','eventlog.lst','sound.log')) {
        $logPath = Join-Path $resolvedGame $logName
        if (Test-Path -LiteralPath $logPath -PathType Leaf) {
            Copy-Item -LiteralPath $logPath -Destination (Join-Path $logsRoot $logName) -Force
        }
    }
    try {
        Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $captureStartLocal } -ErrorAction Stop |
            Where-Object { $_.Message -match 'il2fb|wrapper\.dll|jvm\.dll|jgl\.dll' -or $_.ProviderName -match 'Application Error|Windows Error Reporting' } |
            Select-Object TimeCreated,ProviderName,Id,LevelDisplayName,Message |
            Export-Csv -LiteralPath (Join-Path $runRoot 'windows-application-events.csv') -NoTypeInformation -Encoding UTF8
    }
    catch { Write-Timeline -Event 'eventlog_export_error' -Detail $_.Exception.Message }

    $referenceAfter = foreach ($relative in @('il2fb.exe','files.SFS','conf.ini')) {
        $path = Join-Path $resolvedReference $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $item = Get-Item -LiteralPath $path
            [ordered]@{ path = $relative; length = $item.Length; modified_utc = $item.LastWriteTimeUtc.ToString('O'); sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
        }
    }
    $summary = [ordered]@{
        run = $runName
        completed = $completed
        ended_utc = [DateTime]::UtcNow.ToString('O')
        game_pid = if ($game) { $game.Id } else { $null }
        game_exit_code = if ($game -and $game.HasExited) { $game.ExitCode } else { $null }
        results = $runRoot
        reference_files_after = @($referenceAfter)
    }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runRoot 'summary.json') -Encoding UTF8
    Write-Host "RESULTATS_CAPTURE : $runRoot" -ForegroundColor Cyan
}
