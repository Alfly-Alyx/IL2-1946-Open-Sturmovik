<#
Exercise the switcher's rollback after a real failure on the last state write.
Restricted to the named v1.15 WIP test installation. The test never launches
the game, the embedded GUI or capture tooling, and preserves a recovery copy.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [switch]$Apply
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Hash([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
    return $null
}

function Assert-NoLinks([string]$Path, [string]$Boundary) {
    $cursor = [IO.Path]::GetFullPath($Path)
    Assert-True ($cursor.StartsWith($Boundary + '\', [StringComparison]::OrdinalIgnoreCase) -or $cursor -eq $Boundary) "Outside boundary: $cursor"
    while ($cursor.Length -ge $Boundary.Length) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            Assert-True (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) "Reparse point: $cursor"
        }
        if ($cursor -eq $Boundary) { break }
        $cursor = Split-Path -Parent $cursor
    }
}

$repo = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$game = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$allowedGame = [IO.Path]::GetFullPath((Join-Path $repo 'WIP/tests/installations/IL 2 Sturmovik 1946 test'))
Assert-True ($game -eq $allowedGame) 'Only the named WIP test installation is allowed.'
Assert-True ((& git -C $repo branch --show-current) -eq 'v1.15') 'Expected v1.15.'
Assert-True (([IO.Path]::GetFullPath((& git -C $repo rev-parse --show-toplevel))) -eq $repo) 'Wrong Git root.'
Assert-True (Test-Path -LiteralPath $game -PathType Container) 'Test installation missing.'
Assert-NoLinks $game $repo
$switchRoot = Join-Path $game '_Game Switcher'
Assert-NoLinks $switchRoot $repo
Assert-True (@(Get-Process -Name il2fb,Open_Sturmovik -ErrorAction SilentlyContinue).Count -eq 0) 'Close IL-2 before this test.'
Assert-True (@(Get-ChildItem -LiteralPath $switchRoot -Directory -Filter '_transaction-*').Count -eq 0) 'Abandoned transaction exists before the test.'

$bat = Join-Path $game 'Open_Sturmovik_Switcher.bat'
foreach ($relative in @(
    'Open_Sturmovik_Switcher.bat',
    '_Game Switcher/Open_Sturmovik_Switcher.hta',
    '_Game Switcher/Resources/Icons/Open_Sturmovik_Switcher.ico',
    '_Game Switcher/Resources/Icons/Open_Sturmovik_Game.ico',
    '_Game Switcher/Resources/Backgrounds/Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.jpg',
    '_Game Switcher/Refresh-OpenSturmovikIconCache.ps1'
)) {
    Assert-True ((Hash (Join-Path $game $relative)) -eq (Hash (Join-Path $repo $relative))) "The test copy does not contain the current switcher component: $relative"
}
$statePath = Join-Path $switchRoot 'active-profile.txt'
$state = Get-Content -LiteralPath $statePath -Raw
Assert-True ($state -match '(?m)^profile=8\r?$') 'The test must start from profile 8.'
Assert-True ($state -match '(?m)^hud=standard\r?$') 'The test must start from the standard HUD.'

$activeFiles = @(
    'il2fb.exe', 'files.SFS', 'wrapper.dll',
    'fb_3do19.SFS', 'fb_3do20.SFS', 'fb_maps15.SFS',
    'il2_core.dll', 'il2_corep4.dll', 'mg_snd.dll', 'mg_snd_sse.dll',
    'Files/com/maddox/il2/objects/air.ini',
    'Files/com/maddox/il2/objects/stationary.ini',
    'Files/i18n/hud_log_ru.properties',
    'Files/i18n/hud_log_fr.properties',
    'Files/i18n/hud_log.properties',
    'Files/i18n/hud_log_cs.properties',
    'Files/i18n/hud_log_de.properties',
    'Files/i18n/hud_log_hu.properties',
    'Files/i18n/hud_log_pl.properties',
    'Files/i18n/gui_cs.properties',
    'Files/i18n/maps_cs.properties',
    'Files/i18n/plane_cs.properties',
    'Files/i18n/regInfo_cs.properties',
    'Files/i18n/regShort_cs.properties',
    'Files/i18n/weapons_cs.properties',
    '_Game Switcher/active-profile.txt',
    'Files/background0.tga',
    'Files/2B9A89D62FA5D19A',
    'conf.ini',
    'Files/gui/Background.tga',
    'Files/B44652EE36C23D32',
    'Missions/Background.tga'
)
$languageManifest = Get-Content -LiteralPath (Join-Path $repo 'WIP/development/manifests/game-language-resources-v1.15.json') -Raw | ConvertFrom-Json
$presentationManifest = Get-Content -LiteralPath (Join-Path $repo 'WIP/development/manifests/profile-presentation-resources-v1.15.json') -Raw | ConvertFrom-Json
$activeFiles += @(Get-ChildItem -LiteralPath (Join-Path $repo '_Game Switcher/Languages/4.09m/Modded Aliases/fr/i18n') -File -Filter '*_ru.properties' | ForEach-Object { "Files/i18n/$($_.Name)" })
$activeFiles += @($presentationManifest.profiles.music.path | ForEach-Object { "samples/Music/Menu/$(Split-Path -Leaf $_)" })
$activeFiles = @($activeFiles | Select-Object -Unique)
$before = [ordered]@{}
foreach ($relative in $activeFiles) {
    $path = Join-Path $game $relative
    Assert-NoLinks $path $repo
    $before[$relative] = Hash $path
}

if (-not $Apply) {
    Write-Output 'Preflight PASS. Use -Apply to simulate the final state-write failure.'
    return
}

$reportRoot = Join-Path (Split-Path -Parent $game) ('switcher-rollback-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Assert-NoLinks $reportRoot $repo
Assert-True (-not (Test-Path -LiteralPath $reportRoot)) 'Report folder must not already exist.'
New-Item -ItemType Directory -Path $reportRoot | Out-Null
$report = [ordered]@{
    dateUtc = [DateTime]::UtcNow.ToString('o')
    gitHead = (& git -C $repo rev-parse HEAD)
    scope = 'single-batch-late-write-rollback-only'
    gameRoot = $game
    gameLaunched = $false
    guiLaunched = $false
    capturesLaunched = $false
    expectedExitCode = 6
    actualExitCode = $null
    allActiveFilesRestored = $false
    abandonedTransactionCount = $null
    finalProfile = $null
    result = 'FAIL'
}

try {
    $lock = [IO.File]::Open($statePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        $logPath = Join-Path $reportRoot 'switcher-output.log'
        $command = 'call "' + $bat + '" --apply 2 standard cs > "' + $logPath + '" 2>&1'
        & $env:ComSpec /D /C $command
        $report.actualExitCode = $LASTEXITCODE
        $output = @(Get-Content -LiteralPath $logPath -ErrorAction SilentlyContinue)
    }
    finally {
        $lock.Dispose()
    }
    Assert-True ($report.actualExitCode -eq 6) "Switcher exit $($report.actualExitCode), expected 6."
    Assert-True (($output -join "`n") -match 'Configuration precedente restauree') 'The switcher did not report a successful restoration.'

    foreach ($relative in $activeFiles) {
        Assert-True ((Hash (Join-Path $game $relative)) -eq $before[$relative]) "Rollback mismatch: $relative"
    }
    $report.allActiveFilesRestored = $true
    $transactions = @(Get-ChildItem -LiteralPath $switchRoot -Directory -Filter '_transaction-*')
    $report.abandonedTransactionCount = $transactions.Count
    Assert-True ($transactions.Count -eq 0) 'A transaction folder remains after the rollback.'
    $finalState = Get-Content -LiteralPath $statePath -Raw
    Assert-True ($finalState -match '(?m)^profile=8\r?$') 'The final profile is not 8.'
    Assert-True ($finalState -match '(?m)^version=4\.09m\r?$') 'The final version is not 4.09m.'
    Assert-True ($finalState -match '(?m)^hud=standard\r?$') 'The final HUD is not standard.'
    Assert-True ($finalState -match '(?m)^language=fr\r?$') 'The final language is not French.'
    $report.finalProfile = '8 / 4.09m / Open Sturmovik without 6DOF / standard HUD'
    $report.result = 'PASS'
}
finally {
    $reportPath = Join-Path $reportRoot 'result.json'
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding UTF8
}

[pscustomobject]@{
    Result = $report.result
    RestoredFiles = $activeFiles.Count
    FinalProfile = $report.finalProfile
    Report = $reportPath
}
