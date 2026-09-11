[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
    [ValidateRange(1, 30)][int]$PollSeconds = 2,
    [switch]$Once,
    [switch]$FlushQueueOnly,
    [switch]$QueueOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$gameExecutable = Join-Path $resolvedGame 'il2fb.exe'
if (-not (Test-Path -LiteralPath $gameExecutable -PathType Leaf)) {
    throw "Executable IL-2 introuvable : $gameExecutable"
}
$resolvedState = [IO.Path]::GetFullPath($StateRoot)
$queueRoot = Join-Path $resolvedState 'Queue'
$sessionRoot = Join-Path $resolvedState 'Sessions'
New-Item -ItemType Directory -Path $resolvedState,$queueRoot,$sessionRoot -Force | Out-Null
$watcherLog = Join-Path $resolvedState 'watcher.log'
$sender = Join-Path $PSScriptRoot 'Send-OpenSturmovikDiagnostic.ps1'
$collector = Join-Path $PSScriptRoot 'Collect-OpenSturmovikDiagnostic.ps1'
foreach ($required in @($sender,$collector)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Composant de diagnostic absent : $required" }
}

function Write-WatcherLog {
    param([string]$Message)
    try {
        if ((Test-Path -LiteralPath $watcherLog -PathType Leaf) -and (Get-Item -LiteralPath $watcherLog).Length -gt 1048576) {
            Move-Item -LiteralPath $watcherLog -Destination ($watcherLog + '.previous') -Force
        }
        Add-Content -LiteralPath $watcherLog -Value ([DateTime]::UtcNow.ToString('O') + ' ' + $Message) -Encoding UTF8
    }
    catch { }
}

function Get-RelativeName {
    param([string]$Path)
    if ($Path.StartsWith($resolvedGame + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($resolvedGame.Length + 1)
    }
    return [IO.Path]::GetFileName($Path)
}

function Get-LogSnapshot {
    $offsets = [ordered]@{}
    $checkpoints = [ordered]@{}
    $files = [Collections.Generic.List[IO.FileInfo]]::new()
    foreach ($file in @(Get-ChildItem -LiteralPath $resolvedGame -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.log','.lst' })) {
        $files.Add($file)
    }
    $dumpRoot = Join-Path $resolvedGame 'dump'
    if (Test-Path -LiteralPath $dumpRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $dumpRoot -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.log','.lst','.txt' })) {
            $files.Add($file)
        }
    }
    foreach ($file in @($files | Sort-Object FullName -Unique)) {
        $relative = Get-RelativeName -Path $file.FullName
        $length = [long]$file.Length
        $offsets[$relative] = $length
        $tailLength = [int][Math]::Min(128, $length)
        $tailHash = ''
        if ($tailLength -gt 0) {
            $inputStream = [IO.File]::Open($file.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
            try {
                $inputStream.Position = $length - $tailLength
                $tail = New-Object byte[] $tailLength
                $read = $inputStream.Read($tail, 0, $tailLength)
                if ($read -eq $tailLength) {
                    $tailSha = [Security.Cryptography.SHA256]::Create()
                    try { $tailHash = ([BitConverter]::ToString($tailSha.ComputeHash($tail))).Replace('-', '') }
                    finally { $tailSha.Dispose() }
                }
            }
            finally { $inputStream.Dispose() }
        }
        $checkpoints[$relative] = [ordered]@{ offset = $length; tail_length = $tailLength; tail_sha256 = $tailHash }
    }
    return [pscustomobject]@{ offsets = $offsets; checkpoints = $checkpoints }
}

function Get-DumpFiles {
    $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($root in @((Join-Path $resolvedState 'Dumps'), (Join-Path $resolvedGame 'dump'), $resolvedGame)) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $root -File -Filter '*.dmp' -Recurse -ErrorAction SilentlyContinue)) {
            $paths.Add($file.FullName) | Out-Null
        }
    }
    return @($paths)
}

function Flush-DiagnosticQueue {
    foreach ($report in @(Get-ChildItem -LiteralPath $queueRoot -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc)) {
        try {
            $result = & $sender -ReportPath $report.FullName -Repository $Repository -StateRoot $resolvedState
            Write-WatcherLog "queue_sent report=$($report.Name) issue=$($result.Issue)"
        }
        catch {
            Write-WatcherLog "queue_pending report=$($report.Name) error=$($_.Exception.Message)"
            break
        }
    }
}

$mutexSeed = [Text.Encoding]::UTF8.GetBytes($resolvedGame.ToLowerInvariant())
$sha = [Security.Cryptography.SHA256]::Create()
try { $mutexSuffix = ([BitConverter]::ToString($sha.ComputeHash($mutexSeed))).Replace('-', '').Substring(0,16) }
finally { $sha.Dispose() }
$mutex = New-Object Threading.Mutex($false, "Local\OpenSturmovikDiagnostics-$mutexSuffix")
$ownsMutex = $false
try {
    try { $ownsMutex = $mutex.WaitOne(0, $false) } catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { Write-WatcherLog 'watcher_already_running'; exit 0 }

    if (-not $QueueOnly) { Flush-DiagnosticQueue }
    if ($FlushQueueOnly) { exit 0 }

    Write-WatcherLog "watcher_started game=$resolvedGame repository=$Repository"
    $lastIdleOffsets = [ordered]@{}
    $lastIdleCheckpoints = [ordered]@{}
    while ($true) {
        $game = $null
        foreach ($candidate in @(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue)) {
            try {
                if ($candidate.Path -ieq $gameExecutable) { $game = $candidate; break }
            }
            catch { }
        }
        if (-not $game) {
            $idleSnapshot = Get-LogSnapshot
            $lastIdleOffsets = $idleSnapshot.offsets
            $lastIdleCheckpoints = $idleSnapshot.checkpoints
            Start-Sleep -Seconds $PollSeconds
            continue
        }

        try { $startedUtc = $game.StartTime.ToUniversalTime() } catch { $startedUtc = [DateTime]::UtcNow }
        $sessionPath = Join-Path $sessionRoot ("il2fb-$($game.Id)-$($startedUtc.ToString('yyyyMMdd-HHmmssZ')).json")
        $session = [ordered]@{
            schema_version = 1
            pid = [int]$game.Id
            started_utc = $startedUtc.ToString('O')
            ended_utc = $null
            exit_code = $null
            max_unresponsive_seconds = 0
            log_offsets = $lastIdleOffsets
            log_checkpoints = $lastIdleCheckpoints
            dump_files = @(Get-DumpFiles)
        }
        $session | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding UTF8
        Write-WatcherLog "game_detected pid=$($game.Id)"

        $unresponsiveSeconds = 0
        $maxUnresponsiveSeconds = 0
        while (-not $game.HasExited) {
            Start-Sleep -Seconds $PollSeconds
            try {
                $game.Refresh()
                if ($game.HasExited) { break }
                $hasWindow = $game.MainWindowHandle -ne [IntPtr]::Zero
                $responding = $true
                if ($hasWindow) { $responding = $game.Responding }
                if ($hasWindow -and -not $responding) {
                    $unresponsiveSeconds += $PollSeconds
                    if ($unresponsiveSeconds -gt $maxUnresponsiveSeconds) { $maxUnresponsiveSeconds = $unresponsiveSeconds }
                }
                else { $unresponsiveSeconds = 0 }
            }
            catch { }
        }

        try { $game.WaitForExit() } catch { }
        $exitCode = $null
        try { $exitCode = [int]$game.ExitCode } catch { }
        Start-Sleep -Seconds 3
        $session.ended_utc = [DateTime]::UtcNow.ToString('O')
        $session.exit_code = $exitCode
        $session.max_unresponsive_seconds = $maxUnresponsiveSeconds
        $session | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding UTF8
        Write-WatcherLog "game_exited pid=$($game.Id) code=$exitCode max_unresponsive=$maxUnresponsiveSeconds"

        try {
            $result = & $collector -GameRoot $resolvedGame -SessionPath $sessionPath -Repository $Repository -StateRoot $resolvedState -QueueOnly:$QueueOnly
            Write-WatcherLog "collection_finished status=$($result.Status) findings=$($result.Findings)"
        }
        catch { Write-WatcherLog "collection_failed error=$($_.Exception.Message)" }
        finally { Remove-Item -LiteralPath $sessionPath -Force -ErrorAction SilentlyContinue }

        if (-not $QueueOnly) { Flush-DiagnosticQueue }
        if ($Once) { break }
        $idleSnapshot = Get-LogSnapshot
        $lastIdleOffsets = $idleSnapshot.offsets
        $lastIdleCheckpoints = $idleSnapshot.checkpoints
        Start-Sleep -Seconds $PollSeconds
    }
}
finally {
    if ($ownsMutex) { try { $mutex.ReleaseMutex() } catch { } }
    $mutex.Dispose()
    Write-WatcherLog 'watcher_stopped'
}
