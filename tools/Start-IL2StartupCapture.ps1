[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [ValidateSet('1','2','3','4','5','6','7','8','9')][string]$Profile = '9',
    [ValidateSet('cold','warm')][string]$CacheState = 'cold',
    [switch]$Windowed1024,
    [string]$ReferenceRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946',
    [string]$ResultsRoot = (Join-Path $PSScriptRoot '..\test-results\startup'),
    [string]$ProcmonPath = (Join-Path $PSScriptRoot '..\build\test-tools\sysinternals\Procmon64.exe'),
    [string]$ProcDumpPath = (Join-Path $PSScriptRoot '..\build\test-tools\sysinternals\procdump\procdump.exe'),
    [string]$FrameCapturePath = (Join-Path $PSScriptRoot '..\build\test-tools\FrameCapture.exe'),
    [ValidateRange(1, 30)][int]$FrameRate = 10,
    [ValidateRange(50, 1000)][int]$SampleIntervalMs = 100,
    [ValidateRange(30, 600)][int]$WaitForGameSeconds = 180,
    [switch]$SelectorDumpLab,
    [switch]$CaptureCrashOrHang,
    [switch]$SkipProcmon,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedReference = (Resolve-Path -LiteralPath $ReferenceRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedResults = [IO.Path]::GetFullPath($ResultsRoot)
$resolvedProcmon = [IO.Path]::GetFullPath($ProcmonPath)
$resolvedProcDump = [IO.Path]::GetFullPath($ProcDumpPath)
$resolvedFrameCapture = [IO.Path]::GetFullPath($FrameCapturePath)
$readinessTool = Join-Path $PSScriptRoot 'Test-IL2StartupReadiness.ps1'

if ($CaptureCrashOrHang) {
    if (-not (Test-Path -LiteralPath $resolvedProcDump -PathType Leaf)) {
        throw "ProcDump x86 absent : $resolvedProcDump"
    }
    $procDumpSignature = Get-AuthenticodeSignature -LiteralPath $resolvedProcDump
    if ($procDumpSignature.Status -ne 'Valid' -or
        $procDumpSignature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
        throw "Signature Microsoft invalide pour ProcDump : $($procDumpSignature.Status)"
    }
}

if ($ValidateOnly) {
    $reportPath = Join-Path $resolvedResults 'readiness-latest.json'
    & $readinessTool -GameRoot $resolvedGame -Profile $Profile -Windowed1024:$Windowed1024 -SelectorDumpLab:$SelectorDumpLab -ReferenceRoot $resolvedReference -RepositoryRoot $repositoryRoot -ProcmonPath $resolvedProcmon -FrameCapturePath $resolvedFrameCapture -ReportPath $reportPath
    if ($CaptureCrashOrHang) {
        Write-Host "PROCDUMP_PRET : $resolvedProcDump" -ForegroundColor Green
    }
    exit 0
}

$existingRecorder = @(Get-Process -Name 'Procmon','Procmon64','FrameCapture','il2fb' -ErrorAction SilentlyContinue)
if ($existingRecorder.Count -ne 0) {
    throw "Un processus de jeu ou de capture est deja actif : $($existingRecorder.Name -join ', ')"
}

$displayTag = if ($Windowed1024) { '-windowed1024' } else { '-fullscreen' }
$profileTag = if ($SelectorDumpLab) { 'selector-dump' } else { "profile$Profile" }
$runName = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ') + "-$profileTag-$CacheState$displayTag-startup"
$runRoot = Join-Path $resolvedResults $runName
$frameRoot = Join-Path $runRoot 'screen'
$logsRoot = Join-Path $runRoot 'logs'
$preexistingLogs = Join-Path $runRoot 'preexisting-logs'
$dumpRoot = Join-Path $runRoot 'process-dumps'
$captureDirectories = @($runRoot, $frameRoot, $logsRoot, $preexistingLogs)
if ($CaptureCrashOrHang) { $captureDirectories += $dumpRoot }
New-Item -ItemType Directory -Path $captureDirectories -Force | Out-Null
$readinessReport = Join-Path $runRoot 'readiness.json'
& $readinessTool -GameRoot $resolvedGame -Profile $Profile -Windowed1024:$Windowed1024 -SelectorDumpLab:$SelectorDumpLab -ReferenceRoot $resolvedReference -RepositoryRoot $repositoryRoot -ProcmonPath $resolvedProcmon -FrameCapturePath $resolvedFrameCapture -ReportPath $readinessReport | Out-Host

$timelinePath = Join-Path $runRoot 'timeline.csv'
$metricsPath = Join-Path $runRoot 'process-metrics.csv'
$modulesPath = Join-Path $runRoot 'loaded-modules.csv'
$systemCountersPath = Join-Path $runRoot 'system-counters.csv'
$stopFile = Join-Path $runRoot 'stop-frame-capture.signal'
$procmonTrace = Join-Path $runRoot 'process-monitor.pml'
$wprTrace = Join-Path $runRoot 'windows-performance.etl'
$wprLog = Join-Path $runRoot 'wpr.txt'
$procmonLog = Join-Path $runRoot 'procmon.txt'
$procDumpLog = Join-Path $runRoot 'procdump.txt'
$procDumpErrorLog = Join-Path $runRoot 'procdump-error.txt'
$captureStartUtc = [DateTime]::UtcNow
$captureStartLocal = Get-Date
$procmonStarted = $false
$procmonProcess = $null
$wprStarted = $false
$frameProcess = $null
$counterProcess = $null
$procDumpProcess = $null
$game = $null
$completed = $false
$graphicsCompatibility = $null

function Write-Timeline {
    param([string]$Event, [string]$Detail = '')
    $line = '"{0}","{1}","{2}"' -f [DateTime]::UtcNow.ToString('O'), $Event.Replace('"','""'), $Detail.Replace('"','""')
    Add-Content -LiteralPath $timelinePath -Value $line -Encoding UTF8
}

'utc,event,detail' | Set-Content -LiteralPath $timelinePath -Encoding UTF8
'utc,elapsed_ms,pid,total_cpu_ms,working_set,private_bytes,virtual_bytes,threads,handles,responding' | Set-Content -LiteralPath $metricsPath -Encoding UTF8
'utc,elapsed_ms,pid,module,path,base_address,size,file_version' | Set-Content -LiteralPath $modulesPath -Encoding UTF8

$criticalRelative = @(
    'il2fb.exe','files.SFS','wrapper.dll','DINPUT.dll','il2fb.ini','conf.ini',
    'Files\com\maddox\il2\objects\air.ini',
    'Files\com\maddox\il2\objects\stationary.ini'
)
$criticalSnapshot = foreach ($relative in $criticalRelative) {
    $path = Join-Path $resolvedGame $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $item = Get-Item -LiteralPath $path
        [ordered]@{ path = $relative; present = $true; length = $item.Length; modified_utc = $item.LastWriteTimeUtc.ToString('O'); sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
    }
    else {
        [ordered]@{ path = $relative; present = $false }
    }
}
$referenceSnapshot = foreach ($relative in @('il2fb.exe','files.SFS','conf.ini')) {
    $path = Join-Path $resolvedReference $relative
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $item = Get-Item -LiteralPath $path
        [ordered]@{ path = $relative; length = $item.Length; modified_utc = $item.LastWriteTimeUtc.ToString('O'); sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
    }
}
$profileLabel = switch ($Profile) {
    '1' { '1 - 4.08m Original, sans wrapper, OpenGL natif' }
    '2' { '2 - 4.08m modifie (sans 6DOF), wrapper historique, OpenGL natif' }
    '3' { '3 - 4.08m modifie + profil 6DOF historique, wrapper historique, OpenGL natif' }
    '4' { '4 - 4.09b Original, sans wrapper, OpenGL natif' }
    '5' { '5 - 4.09b modifie (sans 6DOF), wrapper historique, OpenGL natif' }
    '6' { '6 - 4.09b modifie + profil 6DOF historique, wrapper historique, OpenGL natif' }
    '7' { '7 - 4.09m Original, sans wrapper, OpenGL natif' }
    '9' { '9 - 4.09m modifie + profil 6DOF historique, wrapper historique, OpenGL natif' }
    default { '8 - 4.09m modifie (sans 6DOF), wrapper historique, OpenGL natif' }
}
$profileLabel = if ($SelectorDumpLab) { 'Selector 5.1.2 - 4.09m modifie sans 6DOF, DumpMode=3, cache desactive' } else { $profileLabel }
$environment = [ordered]@{
    run = $runName
    started_utc = $captureStartUtc.ToString('O')
    game_root = $resolvedGame
    reference_root = $resolvedReference
    profile = $profileLabel
    cache_state = $CacheState
    display_mode = if ($Windowed1024) { 'windowed-1024x768' } else { 'configured-fullscreen' }
    selector_dump_lab = [bool]$SelectorDumpLab
    crash_or_hang_capture = [bool]$CaptureCrashOrHang
    frame_rate = $FrameRate
    sample_interval_ms = $SampleIntervalMs
    operating_system = @(Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object Caption,Version,BuildNumber,OSArchitecture)
    processors = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed)
    graphics = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object Name,DriverVersion,AdapterRAM,CurrentHorizontalResolution,CurrentVerticalResolution,PNPDeviceID)
    physical_memory = @(Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object TotalPhysicalMemory)
    procdump = if ($CaptureCrashOrHang) {
        $procDumpItem = Get-Item -LiteralPath $resolvedProcDump
        [ordered]@{
            path = $resolvedProcDump
            version = $procDumpItem.VersionInfo.FileVersion
            sha256 = (Get-FileHash -LiteralPath $resolvedProcDump -Algorithm SHA256).Hash
            signature = 'Microsoft Corporation / valid'
        }
    } else { $null }
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
    if ($SkipProcmon) {
        Write-Timeline -Event 'procmon_skipped' -Detail 'mode de capture degrade demande'
        Write-Warning 'Process Monitor est ignore pour ce passage. Les autres captures restent actives.'
    }
    else {
        $procmonArguments = @('-accepteula','-quiet','-minimized','-backingfile',('"' + $procmonTrace + '"'))
        $procmonProcess = Start-Process -FilePath $resolvedProcmon -ArgumentList $procmonArguments -PassThru
        $procmonDeadline = [DateTime]::UtcNow.AddSeconds(30)
        while ([DateTime]::UtcNow -lt $procmonDeadline -and
            -not $procmonProcess.HasExited -and
            -not (Test-Path -LiteralPath $procmonTrace -PathType Leaf)) {
            Start-Sleep -Milliseconds 250
            $procmonProcess.Refresh()
        }
        $procmonReady = -not $procmonProcess.HasExited -and
            (Test-Path -LiteralPath $procmonTrace -PathType Leaf)
        @(
            "pid=$($procmonProcess.Id)"
            "exited=$($procmonProcess.HasExited)"
            "trace_present=$((Test-Path -LiteralPath $procmonTrace -PathType Leaf))"
        ) | Set-Content -LiteralPath $procmonLog -Encoding UTF8
        if (-not $procmonReady) {
            $exitDetail = if ($procmonProcess.HasExited) { $procmonProcess.ExitCode } else { 'actif' }
            throw "Process Monitor n a pas confirme son armement apres 30 secondes (etat $exitDetail)."
        }
        $procmonStarted = $true
        Write-Timeline -Event 'procmon_started' -Detail "pid=$($procmonProcess.Id)"
    }

    $wprOutput = & wpr.exe -start GeneralProfile -filemode 2>&1
    $wprOutput | Set-Content -LiteralPath $wprLog -Encoding UTF8
    if ($LASTEXITCODE -eq 0) {
        $wprStarted = $true
        Write-Timeline -Event 'wpr_started'
    }
    else {
        Write-Timeline -Event 'wpr_unavailable' -Detail ($wprOutput -join ' ')
        Write-Warning 'WPR est refuse par la politique Windows. Les compteurs CPU/disque locaux restent actifs.'
    }
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
    if ($CaptureCrashOrHang) {
        $procDumpArguments = @(
            '-accepteula','-ma','-e','-h','-n','2',
            $game.Id,
            ('"' + $dumpRoot + '"')
        )
        $procDumpProcess = Start-Process `
            -FilePath $resolvedProcDump `
            -ArgumentList $procDumpArguments `
            -RedirectStandardOutput $procDumpLog `
            -RedirectStandardError $procDumpErrorLog `
            -WindowStyle Hidden `
            -PassThru
        Write-Timeline -Event 'procdump_started' -Detail "pid=$($procDumpProcess.Id); target=$($game.Id); triggers=exception,hang"
    }
    $frameArguments = @(
        '--process-id', $game.Id,
        '--output', ('"' + $frameRoot + '"'),
        '--stop-file', ('"' + $stopFile + '"'),
        '--fps', $FrameRate,
        '--quality', 82
    )
    $frameProcess = Start-Process -FilePath $resolvedFrameCapture -ArgumentList $frameArguments -PassThru
    Write-Timeline -Event 'frame_capture_started' -Detail "pid=$($frameProcess.Id)"
    $counterTool = Join-Path $PSScriptRoot 'Sample-IL2SystemCounters.ps1'
    $powerShellExecutable = Join-Path $PSHOME 'pwsh.exe'
    if (-not (Test-Path -LiteralPath $powerShellExecutable -PathType Leaf)) { $powerShellExecutable = 'powershell.exe' }
    $counterArguments = @(
        '-NoProfile','-File',('"' + $counterTool + '"'),
        '-Output',('"' + $systemCountersPath + '"'),
        '-StopFile',('"' + $stopFile + '"')
    )
    $counterProcess = Start-Process -FilePath $powerShellExecutable -ArgumentList $counterArguments -PassThru
    Write-Timeline -Event 'system_counters_started' -Detail "pid=$($counterProcess.Id)"

    $knownModules = @{}
    $nextModuleSnapshot = 0L
    while (-not $game.HasExited) {
        try {
            $game.Refresh()
            $responding = $false
            try { $responding = $game.Responding } catch { }
            $totalCpuMs = [Math]::Round($game.TotalProcessorTime.TotalMilliseconds, 3).ToString(
                '0.###',
                [Globalization.CultureInfo]::InvariantCulture
            )
            $metric = '"{0}",{1},{2},{3},{4},{5},{6},{7},{8},{9}' -f
                [DateTime]::UtcNow.ToString('O'), $clock.ElapsedMilliseconds, $game.Id,
                $totalCpuMs,
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
    if ($counterProcess -and -not $counterProcess.HasExited) {
        try { $counterProcess.WaitForExit(5000) | Out-Null } catch { }
        if (-not $counterProcess.HasExited) { Stop-Process -Id $counterProcess.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($procDumpProcess -and -not $procDumpProcess.HasExited) {
        try { $procDumpProcess.WaitForExit(5000) | Out-Null } catch { }
        if (-not $procDumpProcess.HasExited) {
            Stop-Process -Id $procDumpProcess.Id -Force -ErrorAction SilentlyContinue
        }
    }
    if ($wprStarted) {
        $wprStopOutput = & wpr.exe -stop $wprTrace 2>&1
        $wprStopOutput | Add-Content -LiteralPath $wprLog -Encoding UTF8
        Write-Timeline -Event 'wpr_stopped' -Detail "exit=$LASTEXITCODE"
    }
    if ($procmonStarted -or ($procmonProcess -and -not $procmonProcess.HasExited)) {
        $procmonStopOutput = & $resolvedProcmon -accepteula -terminate -quiet 2>&1
        $procmonStopOutput | Add-Content -LiteralPath $procmonLog -Encoding UTF8
        $procmonStopDeadline = [DateTime]::UtcNow.AddSeconds(10)
        while ([DateTime]::UtcNow -lt $procmonStopDeadline -and
            @(Get-Process -Name 'Procmon','Procmon64' -ErrorAction SilentlyContinue).Count -ne 0) {
            Start-Sleep -Milliseconds 250
        }
        Get-Process -Name 'Procmon','Procmon64' -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Timeline -Event 'procmon_stopped' -Detail "exit=$LASTEXITCODE"
    }

    foreach ($logName in @('log.lst','eventlog.lst','sound.log')) {
        $logPath = Join-Path $resolvedGame $logName
        if (Test-Path -LiteralPath $logPath -PathType Leaf) {
            Copy-Item -LiteralPath $logPath -Destination (Join-Path $logsRoot $logName) -Force
        }
    }
    $capturedLog = Join-Path $logsRoot 'log.lst'
    $graphicsTool = Join-Path $PSScriptRoot 'Test-IL2GraphicsCompatibility.ps1'
    if ((Test-Path -LiteralPath $capturedLog -PathType Leaf) -and
        (Test-Path -LiteralPath $graphicsTool -PathType Leaf)) {
        try {
            $graphicsCompatibility = & $graphicsTool `
                -LogPath $capturedLog `
                -ConfPath (Join-Path $resolvedGame 'conf.ini') `
                -OutputPath (Join-Path $runRoot 'graphics-compatibility.json')
            Write-Timeline -Event 'graphics_compatibility_classified' -Detail $graphicsCompatibility.classification
        }
        catch {
            Write-Timeline -Event 'graphics_compatibility_error' -Detail $_.Exception.Message
        }
    }
    if ($SelectorDumpLab) {
        $dumpSource = Join-Path $resolvedGame 'dump'
        $dumpResult = Join-Path $runRoot 'dump'
        if (Test-Path -LiteralPath $dumpSource -PathType Container) {
            New-Item -ItemType Directory -Path $dumpResult -Force | Out-Null
            Get-ChildItem -LiteralPath $dumpSource -Force | Copy-Item -Destination $dumpResult -Recurse -Force
            $dumpManifest = foreach ($file in @(Get-ChildItem -LiteralPath $dumpSource -File -Recurse -Force)) {
                [ordered]@{
                    path = [IO.Path]::GetRelativePath($dumpSource, $file.FullName)
                    length = $file.Length
                    modified_utc = $file.LastWriteTimeUtc.ToString('O')
                    sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
                }
            }
            @($dumpManifest) | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runRoot 'dump-manifest.json') -Encoding UTF8
            Write-Timeline -Event 'selector_dump_archived' -Detail "files=$(@($dumpManifest).Count)"
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
        graphics_compatibility = $graphicsCompatibility
        process_dumps = if (Test-Path -LiteralPath $dumpRoot -PathType Container) {
            @(
                Get-ChildItem -LiteralPath $dumpRoot -File | ForEach-Object {
                    [ordered]@{
                        name = $_.Name
                        length = $_.Length
                        sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
                    }
                }
            )
        } else { @() }
        reference_files_after = @($referenceAfter)
    }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $runRoot 'summary.json') -Encoding UTF8
    Write-Host "RESULTATS_CAPTURE : $runRoot" -ForegroundColor Cyan
}
