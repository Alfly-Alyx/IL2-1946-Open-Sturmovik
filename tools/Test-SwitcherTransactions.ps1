<#
Exercise the real BAT file replacement, never the HTA, game or capture tools.
Restricted to the existing v1.15 WIP test installation. Keeps a recoverable
backup and returns to profile 8 / standard HUD. PASS means file transactions,
not game-version, aircraft, HUD-rendering or TrackIR runtime compatibility.
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
function Assert-Hash([string]$Path, [string]$Expected) {
    Assert-True ((Hash $Path) -eq $Expected) "Wrong hash: $Path"
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
function Assert-GameClosed {
    Assert-True (@(Get-Process -Name il2fb,Open_Sturmovik -ErrorAction SilentlyContinue).Count -eq 0) 'Close IL-2 before this test.'
}
function Snapshot-Protected {
    $result = [ordered]@{}
    $paths = @(Get-ChildItem -LiteralPath $game -Filter 'conf*.ini' -File)
    foreach ($relative in @('Users', '_Game_Enhancements/Mod_AOC_Public')) {
        $folder = Join-Path $game $relative
        if (Test-Path -LiteralPath $folder) {
            $paths += @(Get-ChildItem -LiteralPath $folder -Recurse -File)
        }
    }
    foreach ($path in ($paths | Sort-Object FullName)) {
        $result[$path.FullName] = Hash $path.FullName
    }
    foreach ($relative in $activeFiles + @('Files/i18n/plane_ru.properties')) {
        $path = Join-Path $repo $relative
        $result[$path] = Hash $path
    }
    return $result
}
function Invoke-Switch([int]$Profile, [string]$Hud, [string]$Verb = '--apply', [int]$ExpectedExit = 0) {
    Assert-GameClosed
    # Only these fixed test arguments reach cmd. No game/HTA entry point.
    Assert-True ($Hud -in @('standard','immersion','keep','invalid')) 'Invalid test HUD argument.'
    Assert-True ($Verb -in @('--apply','--validate')) 'Invalid test verb.'
    $command = 'call "' + $bat + '" ' + $Verb + ' ' + $Profile + ' ' + $Hud
    $output = & $env:ComSpec /D /C $command 2>&1
    $code = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $backup ("call-{0:D2}-{1}-{2}-{3}.log" -f $script:callNumber,$Profile,$Hud,$Verb.TrimStart('-'))) -Encoding UTF8
    $script:callNumber++
    Assert-True ($code -eq $ExpectedExit) "Switcher exit $code (expected $ExpectedExit): $output"
    if ($Verb -eq '--apply' -and $ExpectedExit -eq 0) {
        $state = Get-Content -LiteralPath (Join-Path $game '_Game Switcher/active-profile.txt') -Raw
        $effective = if ($Profile -in @(1,4,7)) { 'stock' } elseif ($Hud -eq 'keep') {
            switch (Hash (Join-Path $game 'Files/i18n/hud_log_ru.properties')) {
                $hudHashes.standard { 'standard' }
                $hudHashes.immersion { 'immersion' }
                default { 'custom' }
            }
        } else { $Hud }
        Assert-True ($state -match "(?m)^hud=$effective\r?$") 'Wrong effective HUD recorded.'
        Assert-True ($state -match '(?m)^background=4x3\r?$') 'Wrong loading-background aspect recorded.'
        Assert-True ($state -match '(?m)^resolution=1024x768\r?$') 'Wrong loading-background resolution recorded.'
    }
}
function Check-Active($Profile, [string]$HudHash) {
    $number = [int]$Profile.number
    Assert-Hash (Join-Path $game 'il2fb.exe') $Profile.exeSha256
    Assert-Hash (Join-Path $game 'files.SFS') $Profile.filesSha256
    $payload = switch ($number) { { $_ -in 1..3 } { '4.08m' } { $_ -in 4..6 } { '4.09b' } default { '4.09m' } }
    Assert-True ($Profile.payload -eq $payload) "Unexpected payload mapping: $number"
    foreach ($item in $manifest.payloads.$payload) {
        Assert-Hash (Join-Path $game $item.file) $item.sha256
    }
    $original = $number -in @(1,4,7)
    if ($original) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $game 'wrapper.dll'))) "Wrapper active in stock profile $number"
    } else {
        Assert-Hash (Join-Path $game 'wrapper.dll') '8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78'
        $bytes = [IO.File]::ReadAllBytes((Join-Path $game 'il2fb.exe'))
        $with6 = $number -in @(3,6,9)
        $jump = [BitConverter]::ToString($bytes, 0xF205, 5)
        $instruction = [BitConverter]::ToString($bytes, 0xF282, 2)
        Assert-True ($jump -eq $(if ($with6) { 'E9-16-C6-00-00' } else { '90-90-90-90-90' })) "6DOF jump: $number"
        Assert-True ($instruction -eq $(if ($with6) { 'EB-81' } else { '8B-0E' })) "6DOF instruction: $number"
        $nonzero = @($bytes[0x1B820..0x1B84D] | Where-Object { $_ -ne 0 }).Count
        Assert-True (($nonzero -gt 0) -eq $with6) "6DOF translation block: $number"
    }
    if ($number -le 3) {
        foreach ($name in @('fb_3do19.SFS','fb_3do20.SFS','fb_maps15.SFS')) {
            Assert-True (-not (Test-Path -LiteralPath (Join-Path $game $name))) "4.09 archive in 4.08 profile $number : $name"
        }
    }
    $airSource = if ($number -le 3) { '408m air.ini/Air.ini/air.ini' } elseif ($number -le 6) { '409b air.ini/Air.ini/air.ini' } else { '409m air.ini/Air.ini/air.ini' }
    $stationarySource = if ($number -le 6) { 'Stationary/408 & 409b/stationary.ini' } else { 'Stationary/409m/stationary.ini' }
    Assert-Hash (Join-Path $game 'Files/com/maddox/il2/objects/air.ini') (Hash (Join-Path $repo "_Game Switcher/$airSource"))
    Assert-Hash (Join-Path $game 'Files/com/maddox/il2/objects/stationary.ini') (Hash (Join-Path $repo "_Game Switcher/$stationarySource"))
    Assert-Hash (Join-Path $game 'Files/i18n/hud_log_ru.properties') $HudHash
    Assert-Hash (Join-Path $game 'Files/gui/Background.tga') '0CB0E846175E36FECBCB18CC02B6206BB0000FBA8F54A4B61418F8BE3824A7B4'
    $state = Get-Content -LiteralPath (Join-Path $game '_Game Switcher/active-profile.txt') -Raw
    Assert-True ($state -match "(?m)^profile=$number\r?$") "Wrong active profile: $number"
    Assert-True ($state -match ('(?m)^version=' + [regex]::Escape($Profile.version) + '\r?$')) "Wrong recorded version: $number"
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $game '_Game Switcher') -Filter '_transaction-*').Count -eq 0) 'Abandoned transaction.'
}

$repo = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$game = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$allowedGame = Join-Path $repo 'WIP/test-installations/IL 2 Sturmovik 1946 test'
$allowedGame = [IO.Path]::GetFullPath($allowedGame)
Assert-True ($game -eq $allowedGame) 'Only the named WIP test installation is allowed.'
Assert-True ((& git -C $repo branch --show-current) -eq 'v1.15') 'Expected v1.15.'
Assert-True (([IO.Path]::GetFullPath((& git -C $repo rev-parse --show-toplevel))) -eq $repo) 'Wrong Git root.'
Assert-True (Test-Path -LiteralPath $game -PathType Container) 'Test installation missing.'
Assert-NoLinks $game $repo
Assert-NoLinks (Join-Path $game '_Game Switcher') $repo
Assert-GameClosed
Assert-True ($game -notmatch '[!%"\r\n]') 'Unsupported command-path character.'
$manifest = Get-Content -LiteralPath (Join-Path $repo 'manifests/switcher-v1.15.json') -Raw | ConvertFrom-Json
Assert-True (($manifest.profiles.number -join ',') -eq '1,2,3,4,5,6,7,8,9') 'Expected nine ordered profiles.'
$bat = Join-Path $game $manifest.entryPoint
foreach ($component in @($manifest.entryPoint,$manifest.desktopIcon,$manifest.background.path) | Where-Object { $_ }) {
    Assert-Hash (Join-Path $game $component) (Hash (Join-Path $repo $component))
}
$activeFiles = @('il2fb.exe','files.SFS','wrapper.dll','fb_3do19.SFS','fb_3do20.SFS','fb_maps15.SFS',
    'il2_core.dll','il2_corep4.dll','mg_snd.dll','mg_snd_sse.dll','Files/com/maddox/il2/objects/air.ini',
    'Files/com/maddox/il2/objects/stationary.ini','Files/i18n/hud_log_ru.properties','Files/gui/Background.tga',
    '_Game Switcher/active-profile.txt')
foreach ($relative in $activeFiles) { Assert-NoLinks (Join-Path $game $relative) $repo }
$hudHashes = @{
    standard = '932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862'
    immersion = 'ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C'
}
Check-Active $manifest.profiles[7] $hudHashes.standard
$before = Snapshot-Protected
Assert-True ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($game)).AvailableFreeSpace -gt 4GB) 'Insufficient backup/transaction space.'
if (-not $Apply) { Write-Output 'Preflight PASS. Use -Apply to exercise 18 file transactions; no game or capture is started.'; return }

$backup = Join-Path (Split-Path -Parent $game) ('switcher-matrix-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
Assert-NoLinks $backup $repo
Assert-True (-not (Test-Path -LiteralPath $backup)) 'Backup must not exist.'
New-Item -ItemType Directory -Path $backup | Out-Null
$saved = [ordered]@{}
foreach ($relative in $activeFiles) {
    $source = Join-Path $game $relative
    $saved[$relative] = Hash $source
    if ($saved[$relative]) {
        $destination = Join-Path (Join-Path $backup 'files') $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination
        Assert-Hash $destination $saved[$relative]
    }
}
$saved | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'before-sha256.json') -Encoding UTF8
$report = [ordered]@{
    dateUtc = [DateTime]::UtcNow.ToString('o'); gitHead = (& git -C $repo rev-parse HEAD)
    scope = 'file-transactions-only-not-runtime-qualification'; gameRoot = $game; backupRoot = $backup
    gameLaunched = $false; capturesLaunched = $false; guiLaunched = $false
    cases = @(); keepChecks = @(); invalidArgumentsRejected = $false; protectedFilesUnchanged = $false
    finalProfile = $null; result = 'FAIL'
}
$script:callNumber = 1
try {
    foreach ($profile in $manifest.profiles) {
        foreach ($hud in @('standard','immersion')) {
            Invoke-Switch $profile.number $hud
            Check-Active $profile $hudHashes[$hud]
            $report.cases += [ordered]@{ profile=$profile.number; version=$profile.version; mode=$profile.mode; payload=$profile.payload; hudFile=$hud; result='PASS' }
            Write-Output "PASS $($report.cases.Count)/18: profile $($profile.number), HUD file $hud"
        }
    }
    # Crossing a mode boundary with keep must preserve the actual file, for both HUDs.
    Invoke-Switch 8 'keep'
    Check-Active $manifest.profiles[7] $hudHashes.immersion
    $report.keepChecks += 'immersion-preserved-9-to-8'
    Invoke-Switch 9 'standard'
    Check-Active $manifest.profiles[8] $hudHashes.standard
    Invoke-Switch 8 'keep'
    Check-Active $manifest.profiles[7] $hudHashes.standard
    $report.keepChecks += 'standard-preserved-9-to-8'
    Invoke-Switch 8 'standard'
    Check-Active $manifest.profiles[7] $hudHashes.standard
    # Real I/O failure at the LAST write, after the selected files and removals.
    # The state remains readable for backup but cannot be overwritten.
    $rollbackBefore = @($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ','
    $stateLock = [IO.File]::Open((Join-Path $game '_Game Switcher/active-profile.txt'), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try { Invoke-Switch 1 'standard' '--apply' 6 }
    finally { $stateLock.Dispose() }
    Assert-True ((@($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ',') -eq $rollbackBefore) 'Late failure did not restore all fifteen files.'
    Check-Active $manifest.profiles[7] $hudHashes.standard
    $report.lateWriteFailureRollback = 'PASS - all fifteen files restored including loading background and active-profile state'
    Write-Output 'PASS: real last-write failure restores the complete profile.'
    $leftover = Join-Path $game ('_Game Switcher/_transaction-audit-' + [guid]::NewGuid().ToString('N'))
    Assert-NoLinks $leftover $repo
    New-Item -ItemType Directory -Path $leftover | Out-Null
    try { Invoke-Switch 8 'keep' '--validate' 7 }
    finally { Remove-Item -LiteralPath $leftover }
    $report.abandonedTransactionRejected = $true
    $invalidBefore = @($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ','
    Invoke-Switch 0 'standard' '--validate' 2
    Invoke-Switch 8 'invalid' '--validate' 2
    Assert-True (($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ',' -eq $invalidBefore) 'Invalid input changed active files.'
    $report.invalidArgumentsRejected = $true
    $after = Snapshot-Protected
    Assert-True (($before | ConvertTo-Json -Compress) -ceq ($after | ConvertTo-Json -Compress)) 'Protected files changed.'
    $report.protectedFilesUnchanged = $true
    $report.protectedFileCount = $before.Count
    $report.finalProfile = '8 / 4.09m / modded without 6DOF / standard HUD'
    $report.result = 'PASS'
}
catch {
    $report.error = $_.Exception.Message
    Assert-GameClosed
    # Restore only this fixed list of files, never a directory tree.
    foreach ($relative in $activeFiles) {
        $destination = Join-Path $game $relative
        Assert-NoLinks $destination $repo
        if ($saved[$relative]) {
            if ((Hash $destination) -ne $saved[$relative]) {
                Copy-Item -LiteralPath (Join-Path (Join-Path $backup 'files') $relative) -Destination $destination -Force
            }
            Assert-Hash $destination $saved[$relative]
        } elseif (Test-Path -LiteralPath $destination -PathType Leaf) {
            Remove-Item -LiteralPath $destination -Force
        }
    }
    $report.originalFilesRestored = $true
    throw
}
finally {
    $report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $backup 'result.json') -Encoding UTF8
}
[pscustomobject]@{ Result=$report.result; Cases=$report.cases.Count; FinalProfile=$report.finalProfile; Report=(Join-Path $backup 'result.json') }
