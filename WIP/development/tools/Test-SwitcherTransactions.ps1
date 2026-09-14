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
    [ValidateSet('profiles','language-standard','language-immersion')][string]$Scope = 'profiles',
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
function Invoke-Switch([int]$Profile, [string]$Hud, [string]$Verb = '--apply', [int]$ExpectedExit = 0, [string]$Language = 'fr') {
    Assert-GameClosed
    # Only these fixed test arguments reach cmd. No game/HTA entry point.
    Assert-True ($Hud -in @('standard','immersion','keep','invalid')) 'Invalid test HUD argument.'
    Assert-True ($Verb -in @('--apply','--validate')) 'Invalid test verb.'
    Assert-True ($Language -in @('fr','us','ru','de','cs','hu','pl','invalid')) 'Invalid test language argument.'
    $callLog = Join-Path $backup ("call-{0:D2}-{1}-{2}-{3}.log" -f $script:callNumber,$Profile,$Hud,$Verb.TrimStart('-'))
    $command = 'call "' + $bat + '" ' + $Verb + ' ' + $Profile + ' ' + $Hud + ' ' + $Language + ' > "' + $callLog + '" 2>&1'
    & $env:ComSpec /D /C $command
    $code = $LASTEXITCODE
    $output = @(Get-Content -LiteralPath $callLog -ErrorAction SilentlyContinue)
    $script:callNumber++
    Assert-True ($code -eq $ExpectedExit) "Switcher exit $code (expected $ExpectedExit): $output"
    if ($Verb -eq '--apply' -and $ExpectedExit -eq 0) {
        $state = Get-Content -LiteralPath (Join-Path $game '_Game Switcher/active-profile.txt') -Raw
        $effective = if ($Profile -in @(1,4,7)) { 'stock' } elseif ($Hud -eq 'keep') {
            $activeHud = 'Files/i18n/hud_log_ru.properties'
            $activeHash = Hash (Join-Path $game $activeHud)
            if ($activeHash -eq $hudHashes[$Language].standard) { 'standard' }
            elseif ($activeHash -eq $hudHashes[$Language].immersion) { 'immersion' }
            else { 'custom' }
        } else { $Hud }
        Assert-True ($state -match "(?m)^hud=$effective\r?$") 'Wrong effective HUD recorded.'
        Assert-True ($state -match '(?m)^background=16x9\r?$') 'Wrong loading-background aspect recorded.'
        Assert-True ($state -match '(?m)^resolution=1920x1080\r?$') 'Wrong loading-background resolution recorded.'
        Assert-True ($state -match "(?m)^language=$Language\r?$") 'Wrong language recorded.'
    }
}
function Check-Active($Profile, [string]$Hud, [string]$Language = 'fr') {
    $number = [int]$Profile.number
    Assert-Hash (Join-Path $game 'il2fb.exe') $Profile.exeSha256
    Assert-Hash (Join-Path $game 'files.SFS') $Profile.filesSha256
    Assert-Hash (Join-Path $game 'Files/2B9A89D62FA5D19A') $Profile.planeSha256
    $payload = switch ($number) { { $_ -in 1..3 } { '4.08m' } { $_ -in 4..6 } { '4.09b' } default { '4.09m' } }
    Assert-True ($Profile.payload -eq $payload) "Unexpected payload mapping: $number"
    foreach ($item in $manifest.versionFiles.$payload) { Assert-Hash (Join-Path $game $item.file) $item.sha256 }
    $original = $number -in @(1,4,7)
    if ($original) {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $game 'wrapper.dll'))) "Wrapper active in stock profile $number"
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $game 'Files/gui/Background.tga'))) "Modded menu background active in stock profile $number"
    } else {
        Assert-Hash (Join-Path $game 'wrapper.dll') '8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78'
        Assert-Hash (Join-Path $game 'Files/gui/Background.tga') $manifest.menuBackground.sha256
        $bytes = [IO.File]::ReadAllBytes((Join-Path $game 'il2fb.exe'))
        $with6 = $number -in @(3,6,9)
        Assert-True ([BitConverter]::ToString($bytes, 0xF205, 5) -eq $(if ($with6) { 'E9-16-C6-00-00' } else { '90-90-90-90-90' })) "6DOF jump: $number"
        Assert-True ([BitConverter]::ToString($bytes, 0xF282, 2) -eq $(if ($with6) { 'EB-81' } else { '8B-0E' })) "6DOF instruction: $number"
        Assert-True ((@($bytes[0x1B820..0x1B84D] | Where-Object { $_ -ne 0 }).Count -gt 0) -eq $with6) "6DOF translation block: $number"
    }
    $effectiveHud = if ($original) { 'standard' } else { $Hud }
    if ($original) {
        if ($Language -eq 'us') {
            $baseHud = Join-Path $game 'Files/i18n/hud_log.properties'
            Assert-True (-not (Test-Path -LiteralPath $baseHud)) 'English HUD override remains active in standard stock mode.'
        } else {
            Assert-Hash (Join-Path $game "Files/i18n/hud_log_$Language.properties") $hudHashes[$Language].standard
        }
    } else {
        $moddedHud = Join-Path $game 'Files/i18n/hud_log_ru.properties'
        if ($effectiveHud -eq 'standard' -and $Language -eq 'us') {
            $englishAlias = Join-Path $repo "_Game Switcher/Languages/$payload/Modded Aliases/us/i18n/hud_log_ru.properties"
            Assert-Hash $moddedHud (Hash $englishAlias)
        } else {
            Assert-Hash $moddedHud $hudHashes[$Language][$effectiveHud]
        }
    }
    $languageSource = Join-Path $repo ("_Game Switcher/Languages/$payload/i18n")
    if (Test-Path -LiteralPath $languageSource) {
        foreach ($source in @(Get-ChildItem -LiteralPath $languageSource -Filter "*_$Language.properties" -File)) {
            Assert-Hash (Join-Path $game ("Files/i18n/" + $source.Name)) (Hash $source.FullName)
        }
    }
    if (-not $original) {
        $aliasSource = Join-Path $repo ("_Game Switcher/Languages/$payload/Modded Aliases/$Language/i18n")
        foreach ($source in @(Get-ChildItem -LiteralPath $aliasSource -Filter '*_ru.properties' -File | Where-Object Name -ne 'hud_log_ru.properties')) {
            Assert-Hash (Join-Path $game ("Files/i18n/" + $source.Name)) (Hash $source.FullName)
        }
    }
    Assert-Hash (Join-Path $game 'Missions/Background.tga') $Profile.presentation.backgroundSha256
    $profileMusic = Join-Path $repo ([string]$Profile.presentation.menuMusicPath)
    $activeMusic = Join-Path $game 'samples/Music/Menu'
    $expectedMusicNames = @(Get-ChildItem -LiteralPath $profileMusic -File -Filter '*.wav' | Sort-Object Name | ForEach-Object Name)
    $actualMusicNames = @(Get-ChildItem -LiteralPath $activeMusic -File -Filter '*.wav' | Sort-Object Name | ForEach-Object Name)
    Assert-True (($actualMusicNames -join '|') -eq ($expectedMusicNames -join '|')) "Wrong menu music set: $number"
    foreach ($name in $expectedMusicNames) { Assert-Hash (Join-Path $activeMusic $name) (Hash (Join-Path $profileMusic $name)) }
    if ($number -le 3) {
        foreach ($name in @('fb_3do19.SFS','fb_3do20.SFS','fb_maps15.SFS')) { Assert-True (-not (Test-Path -LiteralPath (Join-Path $game $name))) "4.09 archive in 4.08 profile $number : $name" }
    }
    $airSource = if ($number -le 3) { '408m air.ini/Air.ini/air.ini' } elseif ($number -le 6) { '409b air.ini/Air.ini/air.ini' } else { '409m air.ini/Air.ini/air.ini' }
    $stationarySource = if ($number -le 6) { 'Stationary/408 & 409b/stationary.ini' } else { 'Stationary/409m/stationary.ini' }
    Assert-Hash (Join-Path $game 'Files/com/maddox/il2/objects/air.ini') (Hash (Join-Path $repo "_Game Switcher/$airSource"))
    Assert-Hash (Join-Path $game 'Files/com/maddox/il2/objects/stationary.ini') (Hash (Join-Path $repo "_Game Switcher/$stationarySource"))
    if ($null -ne $Profile.loadingDisplay.PSObject.Properties['overrideSha256']) { Assert-Hash (Join-Path $game 'Files/B44652EE36C23D32') $Profile.loadingDisplay.overrideSha256 }
    else { Assert-True (-not (Test-Path -LiteralPath (Join-Path $game 'Files/B44652EE36C23D32'))) "Unexpected loading-label override: $number" }
    $conf = Get-Content -LiteralPath (Join-Path $game 'conf.ini') -Raw
    Assert-True ($conf -match ("(?ms)^\[rts\].*?^locale=" + [regex]::Escape($Language) + "\r?$")) "Wrong conf.ini locale: $Language"
    $state = Get-Content -LiteralPath (Join-Path $game '_Game Switcher/active-profile.txt') -Raw
    Assert-True ($state -match "(?m)^profile=$number\r?$") "Wrong active profile: $number"
    Assert-True ($state -match ('(?m)^version=' + [regex]::Escape($Profile.version) + '\r?$')) "Wrong recorded version: $number"
    Assert-True ($state -match "(?m)^language=$Language\r?$") "Wrong recorded language: $number"
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $game '_Game Switcher') -Filter '_transaction-*').Count -eq 0) 'Abandoned transaction.'
}

$repo = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
$game = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$allowedGame = Join-Path $repo 'WIP/tests/installations/IL 2 Sturmovik 1946 test'
$allowedGame = [IO.Path]::GetFullPath($allowedGame)
Assert-True ($game -eq $allowedGame) 'Only the named WIP test installation is allowed.'
Assert-True ((& git -C $repo branch --show-current) -eq 'v1.15') 'Expected v1.15.'
Assert-True (([IO.Path]::GetFullPath((& git -C $repo rev-parse --show-toplevel))) -eq $repo) 'Wrong Git root.'
Assert-True (Test-Path -LiteralPath $game -PathType Container) 'Test installation missing.'
Assert-NoLinks $game $repo
Assert-NoLinks (Join-Path $game '_Game Switcher') $repo
Assert-GameClosed
Assert-True ($game -notmatch '[!%"\r\n]') 'Unsupported command-path character.'
$manifest = Get-Content -LiteralPath (Join-Path $repo 'WIP/development/manifests/switcher-v1.15.json') -Raw | ConvertFrom-Json
$languageManifest = Get-Content -LiteralPath (Join-Path $repo 'WIP/development/manifests/game-language-resources-v1.15.json') -Raw | ConvertFrom-Json
$presentationManifest = Get-Content -LiteralPath (Join-Path $repo 'WIP/development/manifests/profile-presentation-resources-v1.15.json') -Raw | ConvertFrom-Json
Assert-True (($manifest.profiles.number -join ',') -eq '1,2,3,4,5,6,7,8,9') 'Expected nine ordered profiles.'
$bat = Join-Path $game $manifest.entryPoint
$components = @($manifest.entryPoint, $manifest.desktopIcon)
if ($null -ne $manifest.background) {
    $components += [string]$manifest.background.path
}
foreach ($component in $components | Where-Object { $_ }) {
    Assert-Hash (Join-Path $game $component) (Hash (Join-Path $repo $component))
}
$activeFiles = @('il2fb.exe','files.SFS','wrapper.dll','fb_3do19.SFS','fb_3do20.SFS','fb_maps15.SFS',
    'il2_core.dll','il2_corep4.dll','mg_snd.dll','mg_snd_sse.dll','Files/com/maddox/il2/objects/air.ini',
    'Files/com/maddox/il2/objects/stationary.ini','Files/i18n/hud_log_ru.properties','Files/i18n/hud_log_fr.properties',
    'Files/i18n/hud_log.properties','Files/i18n/hud_log_cs.properties','Files/i18n/hud_log_de.properties',
    'Files/i18n/hud_log_hu.properties','Files/i18n/hud_log_pl.properties','_Game Switcher/active-profile.txt',
    'Files/background0.tga','Files/2B9A89D62FA5D19A','conf.ini','Files/gui/Background.tga','Files/B44652EE36C23D32','Missions/Background.tga')
$activeFiles += @($languageManifest.versionSpecificFiles | ForEach-Object { "Files/i18n/$_" })
$activeFiles += @(Get-ChildItem -LiteralPath (Join-Path $repo '_Game Switcher/Languages/4.09m/Modded Aliases/fr/i18n') -File -Filter '*_ru.properties' | ForEach-Object { "Files/i18n/$($_.Name)" })
$activeFiles += @($presentationManifest.profiles.music.path | ForEach-Object { "samples/Music/Menu/$(Split-Path -Leaf $_)" })
$activeFiles = @($activeFiles | Select-Object -Unique)
foreach ($relative in $activeFiles) { Assert-NoLinks (Join-Path $game $relative) $repo }
$hudHashes = @{
    fr = @{ standard='932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862'; immersion='F7B2C346B5DC184DB6FED8113A2906C56E923003EF45B1100862E1BC827D2DAC' }
    us = @{ standard=$null; immersion='ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C' }
    ru = @{ standard='15EE35897F3B074DD5410CBB2070285DA235C7AD257BC9B96CBEE3C0A0144AB3'; immersion='B174028E7F9D6ED6A05F8D21396AF33C79D2581E880DE429F9DF3A10527770B8' }
    de = @{ standard='8F46CC0D2C691ABA26130831E666654268D7E24C0B379A18626151036B677DBA'; immersion='A06C2FBC654A5A41FD7230E2B2C233EBC8FA1F36F6C9691D9443B498543A270A' }
    cs = @{ standard='242C595AE61E3FA6EDB78B426673F011D4691FFF3FFF823C8D402F392AC150EF'; immersion='6B30433CE0E3E352ACC09E755C56CAA3DD3799043BE0152D7D01B4C8C56D1B4E' }
    hu = @{ standard='822B695DD0D07DE62EB251E36E270A4106BD2005483FF1429CF46A99DA58E36F'; immersion='46A546197A184C79DED66CA18CB5C86F00F4BBA2B1568A7338BFE7A0A3FFD231' }
    pl = @{ standard='AF260FFF51B6CD6831C5F72555A86CB1AF5506C3B1BD2E8B8C2D087A05662067'; immersion='B996BCB93D71315586F8512F4EF5EAC07C1A65D2010A354A53FD28B0E5450B19' }
}

$before = Snapshot-Protected
Assert-True ([IO.DriveInfo]::new([IO.Path]::GetPathRoot($game)).AvailableFreeSpace -gt 4GB) 'Insufficient backup/transaction space.'
    Write-Host "Preflight PASS ($Scope): aucune mutation effectuee." -ForegroundColor Green

$backup = Join-Path (Split-Path -Parent $game) ('switcher-' + $Scope + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
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
    scope = $Scope + '-file-transactions-only-not-runtime-qualification'; gameRoot = $game; backupRoot = $backup
    gameLaunched = $false; capturesLaunched = $false; guiLaunched = $false
    cases = @(); keepChecks = @(); invalidArgumentsRejected = $false; protectedFilesUnchanged = $false
    finalProfile = $null; result = 'FAIL'
}
$script:callNumber = 1
try {
    if ($Scope -eq 'profiles') {
        $matrixCases = @(
            @{ profile=1; hud='standard'; language='fr' },
            @{ profile=2; hud='immersion'; language='cs' },
            @{ profile=3; hud='standard'; language='us' },
            @{ profile=4; hud='standard'; language='ru' },
            @{ profile=5; hud='immersion'; language='de' },
            @{ profile=6; hud='standard'; language='pl' },
            @{ profile=7; hud='standard'; language='hu' },
            @{ profile=8; hud='immersion'; language='fr' },
            @{ profile=9; hud='immersion'; language='ru' }
        )
        foreach ($case in $matrixCases) {
            $profile = $manifest.profiles[[int]$case.profile - 1]
            Invoke-Switch $case.profile $case.hud '--apply' 0 $case.language
            Check-Active $profile $case.hud $case.language
            $report.cases += [ordered]@{ profile=$case.profile; version=$profile.version; mode=$profile.mode; payload=$profile.payload; hudFile=$case.hud; language=$case.language; result='PASS' }
            Write-Output "PASS $($report.cases.Count)/9: profile $($case.profile), HUD $($case.hud), language $($case.language)"
        }
        Invoke-Switch 8 'keep' '--apply' 0 'ru'
        Check-Active $manifest.profiles[7] immersion 'ru'
        $report.keepChecks += 'Russian immersion preserved from profile 9 to 8'
        Invoke-Switch 8 'standard' '--apply' 0 'fr'
        Check-Active $manifest.profiles[7] standard 'fr'
        $rollbackBefore = @($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ','
        $stateLock = [IO.File]::Open((Join-Path $game '_Game Switcher/active-profile.txt'), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        try { Invoke-Switch 2 'standard' '--apply' 6 'cs' }
        finally { $stateLock.Dispose() }
        Assert-True ((@($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ',') -eq $rollbackBefore) 'Late failure did not restore every protected and version-specific file.'
        Check-Active $manifest.profiles[7] standard 'fr'
        $report.lateWriteFailureRollback = ('PASS - all ' + $activeFiles.Count + ' protected files restored including language catalogues, conf.ini, HUD, backgrounds and active-profile state')
        Write-Output 'PASS: real last-write failure restores the complete multilingual profile.'
    } else {
        $hud = if ($Scope -eq 'language-immersion') { 'immersion' } else { 'standard' }
        $report.languageChecks = @()
        foreach ($language in @('fr','us','de','ru','cs','hu','pl')) {
            Invoke-Switch 8 $hud '--apply' 0 $language
            Check-Active $manifest.profiles[7] $hud $language
            $report.languageChecks += "$language/$hud/profile8 PASS"
            $report.cases += [ordered]@{ profile=8; version='4.09m'; mode='standard'; payload='4.09m'; hudFile=$hud; language=$language; result='PASS' }
            Write-Output "PASS $($report.cases.Count)/7: language $language, HUD $hud"
        }
        Invoke-Switch 8 'standard' '--apply' 0 'fr'
        Check-Active $manifest.profiles[7] standard 'fr'
    }
    $leftover = Join-Path $game ('_Game Switcher/_transaction-audit-' + [guid]::NewGuid().ToString('N'))
    Assert-NoLinks $leftover $repo
    New-Item -ItemType Directory -Path $leftover | Out-Null
    try { Invoke-Switch 8 'keep' '--validate' 7 }
    finally { Remove-Item -LiteralPath $leftover }
    $report.abandonedTransactionRejected = $true
    $invalidBefore = @($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ','
    Invoke-Switch 0 'standard' '--validate' 2
    Invoke-Switch 8 'invalid' '--validate' 2
    Invoke-Switch 8 'standard' '--validate' 2 'invalid'
    Assert-True (($activeFiles | ForEach-Object { Hash (Join-Path $game $_) }) -join ',' -eq $invalidBefore) 'Invalid input changed active files.'
    $report.invalidArgumentsRejected = $true
    $after = Snapshot-Protected
    Assert-True (($before | ConvertTo-Json -Compress) -ceq ($after | ConvertTo-Json -Compress)) 'Protected files changed.'
    $report.protectedFilesUnchanged = $true
    $report.protectedFileCount = $before.Count
    $report.finalProfile = '8 / 4.09m / modded without 6DOF / standard HUD / French'
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

