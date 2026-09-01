[CmdletBinding()]
param(
    [string]$RunRoot,
    [string]$ResultsRoot,
    [string]$Detail = 'largage de bombe Weapon3 imminent'
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 can evaluate parameter defaults before $PSScriptRoot is
# populated. Resolve the script-relative default after parameter binding.
if ([string]::IsNullOrWhiteSpace($ResultsRoot)) {
    $ResultsRoot = Join-Path $PSScriptRoot '..\test-results\startup'
}

if ([string]::IsNullOrWhiteSpace($RunRoot)) {
    $resolvedResults = [IO.Path]::GetFullPath($ResultsRoot)
    $candidate = Get-ChildItem -LiteralPath $resolvedResults -Directory |
        Where-Object {
            (Test-Path -LiteralPath (Join-Path $_.FullName 'timeline.csv') -PathType Leaf) -and
            -not (Test-Path -LiteralPath (Join-Path $_.FullName 'stop-frame-capture.signal') -PathType Leaf)
        } |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if (-not $candidate) {
        throw 'Aucune capture IL-2 active n a ete trouvee.'
    }
    $resolvedRun = $candidate.FullName
}
else {
    $resolvedRun = (Resolve-Path -LiteralPath $RunRoot -ErrorAction Stop).Path
}

$timelinePath = Join-Path $resolvedRun 'timeline.csv'
$timeline = @(Import-Csv -LiteralPath $timelinePath)
$gameEvent = $timeline | Where-Object event -eq 'game_detected' | Select-Object -Last 1
if (-not $gameEvent -or $gameEvent.detail -notmatch 'pid=(\d+)') {
    throw 'La capture n a pas encore detecte le processus IL-2.'
}

$gamePid = [int]$Matches[1]
$game = Get-Process -Id $gamePid -ErrorAction Stop
if ($game.ProcessName -ne 'il2fb') {
    throw "Le PID $gamePid n appartient plus a IL-2."
}

$signalPath = Join-Path $resolvedRun 'arm-crash-or-hang.signal'
$utc = [DateTime]::UtcNow.ToString('O')
[IO.File]::WriteAllText($signalPath, "$utc`r`n$Detail", [Text.UTF8Encoding]::new($false))
$escapedDetail = $Detail.Replace('"','""')
Add-Content -LiteralPath $timelinePath -Value ('"{0}","critical_trigger_armed","{1}"' -f $utc, $escapedDetail) -Encoding UTF8

Write-Host "CAPTURE_GEL_ARMEE : PID $gamePid" -ForegroundColor Green
Write-Host "DOSSIER : $resolvedRun"
Write-Host 'Attendez la ligne procdump_started dans timeline.csv avant de declencher Weapon3.'
