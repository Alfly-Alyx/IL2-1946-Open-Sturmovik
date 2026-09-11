#requires -Version 5.1
[CmdletBinding()]
param([string]$RepositoryRoot, [string]$OutputDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
$root = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd('\')
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = Join-Path $root ('build\loading-rotation-install-tests\run-' + [Guid]::NewGuid().ToString('N')) }
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $output.StartsWith((Join-Path $root 'build') + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Test fixtures must remain under repository build.' }
if (Test-Path -LiteralPath $output) { throw 'Use a new test output directory; existing fixtures are never deleted.' }
[void][IO.Directory]::CreateDirectory($output)
$moduleSha256 = (Get-FileHash -LiteralPath (Join-Path $root 'tools\OpenSturmovik.LoadingRotation.psm1')).Hash
Import-Module (Join-Path $root 'tools\OpenSturmovik.LoadingRotation.psm1') -Force
$catalog = @(Get-OSLoadingCatalog)
$ids = @($catalog | ForEach-Object id)
$patch = Get-Content -LiteralPath (Join-Path $root '_Game Switcher\Loading Rotation Patch\manifest.json') -Raw | ConvertFrom-Json
$checks = New-Object 'System.Collections.Generic.List[object]'
$script:fixtureNumber = 0

function Assert-Test([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "FAIL: $Name" }
    $checks.Add([pscustomobject]@{name=$Name;passed=$true})
    Write-Host "PASS: $Name"
}
function Hash-Test([string]$Path) {
    if ([IO.File]::Exists($Path)) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
    return ''
}
function Write-Fixture([string]$GameRoot, [string]$Relative, [byte[]]$Bytes) {
    $path = Join-Path $GameRoot $Relative
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
    [IO.File]::WriteAllBytes($path, $Bytes)
}
function Text-Fixture([string]$GameRoot, [string]$Relative, [string]$Text) {
    Write-Fixture $GameRoot $Relative ([Text.Encoding]::UTF8.GetBytes($Text))
}
function New-Fixture([string]$Name, [bool]$ExistingConsole = $false) {
    $script:fixtureNumber++
    $fixture = Join-Path $output ('{0:D2}-{1}' -f $script:fixtureNumber,$Name)
    [void][IO.Directory]::CreateDirectory($fixture)
    # Genuine stock executable/archive permit version recognition; the game is never run.
    foreach ($relative in @('il2fb.exe','files.SFS')) {
        [IO.File]::Copy((Join-Path $root $relative),(Join-Path $fixture $relative),$false)
    }
    Text-Fixture $fixture 'Files/gui/Background.tga' 'untouched-original-background-sentinel'
    Text-Fixture $fixture 'Files/gui/background0_ru.mat' "[ClassInfo]`r`n  ClassName TMaterial`r`n[Layer0]`r`n  TextureName background.tga`r`n"
    Text-Fixture $fixture 'conf.ini' "[il2]`r`ntitle=fixture-only`r`n"
    Text-Fixture $fixture 'Files/gui/backgrounds/il2-2001.tga' 'pre-existing-pool-image-bytes'
    Text-Fixture $fixture 'Files/gui/backgrounds/il2-2001.mat' 'pre-existing-pool-material-bytes'
    Text-Fixture $fixture 'Files/gui/backgrounds/rotation.properties' "# preserved original configuration`r`nenabled=false`r`n"
    if ($ExistingConsole) {
        Write-Fixture $fixture 'Files/B96FAC8E2C4DDBE0' ([IO.File]::ReadAllBytes((Join-Path $root 'test-assets\loading-rotation\ConsoleGL0.class')))
    }
    return $fixture
}
function Snapshot-Fixture([string]$GameRoot) {
    $snapshot = @{}
    $dataPrefix = (Join-Path $GameRoot '.open-sturmovik-loading-rotation') + '\'
    foreach ($file in Get-ChildItem -LiteralPath $GameRoot -File -Recurse) {
        if ($file.FullName.StartsWith($dataPrefix,[StringComparison]::OrdinalIgnoreCase)) { continue }
        $relative = $file.FullName.Substring($GameRoot.Length + 1).Replace('\','/')
        $snapshot[$relative] = Hash-Test $file.FullName
    }
    return $snapshot
}
function Assert-Snapshot([string]$GameRoot, [hashtable]$Expected, [string]$Name) {
    $actual = Snapshot-Fixture $GameRoot
    Assert-Test ($actual.Count -eq $Expected.Count) "$Name file count"
    foreach ($key in $Expected.Keys) {
        if (-not $actual.ContainsKey($key) -or $actual[$key] -ne $Expected[$key]) { throw "FAIL: $Name mismatch $key" }
    }
    Assert-Test $true "$Name byte-identical files and original absences"
}
function Expect-Failure([scriptblock]$Operation, [string]$Name) {
    $failed = $false
    try { & $Operation | Out-Null } catch { $failed = $true; Write-Host ("Expected error: " + $_.Exception.Message) }
    Assert-Test $failed $Name
}
function Assert-Protected([string]$GameRoot, [hashtable]$Baseline, [string]$Name) {
    foreach ($relative in @('il2fb.exe','files.SFS','conf.ini','Files/gui/Background.tga','Files/gui/background0_ru.mat')) {
        if ((Hash-Test (Join-Path $GameRoot $relative)) -ne $Baseline[$relative]) { throw "FAIL: $Name changed $relative" }
    }
    Assert-Test $true $Name
}
function Assert-Installed([string]$GameRoot, [string]$Name) {
    foreach ($item in $patch.classes) {
        Assert-Test ((Hash-Test (Join-Path $GameRoot ('Files/' + $item.looseName))) -eq $item.sha256) "$Name class $($item.looseName)"
    }
    foreach ($image in $catalog) {
        Assert-Test ((Hash-Test (Join-Path $GameRoot ('Files/gui/backgrounds/' + $image.id + '.tga'))) -eq $image.sha256) "$Name image $($image.id)"
        foreach ($suffix in @('','_cs','_de','_fr','_ru')) {
            $material = Join-Path $GameRoot ('Files/gui/backgrounds/' + $image.id + $suffix + '.mat')
            if (-not [IO.File]::Exists($material) -or [IO.File]::ReadAllText($material) -notmatch ('TextureName ' + [regex]::Escape($image.id) + '\.tga')) { throw "FAIL: material $material" }
        }
    }
    $ledger = Get-Content -LiteralPath (Join-Path $GameRoot '.open-sturmovik-loading-rotation/installation.json') -Raw | ConvertFrom-Json
    Assert-Test ($ledger.entries.Count -eq 27) "$Name inventory has 2 classes, 4 textures, 20 materials and configuration"
}

try {
    $game = New-Fixture 'roundtrip' $true
    $before = Snapshot-Fixture $game
    $initial = Set-OSLoadingRotation -GameRoot $game -Action Status
    Assert-Test (-not $initial.installed -and -not $initial.configuration.enabled) 'Initial status is uninstalled and disabled'
    $installed = Set-OSLoadingRotation -GameRoot $game -Action Install
    Assert-Test ($installed.status -eq 'InstalledDisabled') 'Install leaves rotation disabled'
    Assert-Installed $game 'Install'
    Assert-Protected $game $before 'Install preserves original background, material, configuration, EXE and SFS'
    $installedSnapshot = Snapshot-Fixture $game
    Assert-Test ((Set-OSLoadingRotation -GameRoot $game -Action Install).status -eq 'AlreadyInstalled') 'Repeated install is idempotent'
    Assert-Snapshot $game $installedSnapshot 'Repeated install'
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[1]) -OfficialId $ids[0] } 'Official double weight with two images is rejected'
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[0]) } 'Duplicate selection is rejected'
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],'unknown-image') } 'Unknown image is rejected'
    Assert-Snapshot $game $installedSnapshot 'Invalid selections do not change active files'
    $null = Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[1],$ids[2]) -OfficialId $ids[0] -Mode ordered
    $enabled = (Set-OSLoadingRotation -GameRoot $game -Action Status).configuration
    Assert-Test ($enabled.enabled -and $enabled.images.Count -eq 3 -and $enabled.official -eq $ids[0] -and $enabled.mode -eq 'ordered') 'Valid weighted selection is persisted'
    $null = Set-OSLoadingRotation -GameRoot $game -Action Disable
    Assert-Test (-not (Set-OSLoadingRotation -GameRoot $game -Action Status).configuration.enabled) 'Disable clears activation'
    Assert-Installed $game 'Disable retains installed package'
    $removed = Set-OSLoadingRotation -GameRoot $game -Action Remove
    Assert-Test ($removed.status -eq 'Removed' -and @($removed.preserved).Count -eq 0) 'Remove reports a complete restoration'
    Assert-Snapshot $game $before 'Remove restores mixed initial contents and absences'
    Assert-Test (@(Get-ChildItem -LiteralPath (Join-Path $game '.open-sturmovik-loading-rotation/backups') -File).Count -gt 0) 'Durable original backups are retained'

    $game = New-Fixture 'locked-install'
    $before = Snapshot-Fixture $game
    $lockedPath = Join-Path $game 'Files/gui/backgrounds/il2-2001.tga'
    $held = [IO.File]::Open($lockedPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try { Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Install } 'Real locked destination interrupts installation' }
    finally { $held.Dispose() }
    $pending = Join-Path $game '.open-sturmovik-loading-rotation/pending-install.json'
    Assert-Test ([IO.File]::Exists($pending)) 'Journal remains when rollback is blocked by the same lock'
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Remove } 'Next management action recovers then refuses uninstalled removal'
    Assert-Test (-not [IO.File]::Exists($pending)) 'Interrupted installation journal is recovered after lock release'
    Assert-Snapshot $game $before 'Recovery restores pre-installation files'
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    Assert-Installed $game 'Retry after interrupted install'
    $null = Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[1])
    $enabledSnapshot = Snapshot-Fixture $game
    $configPath = Join-Path $game 'Files/gui/backgrounds/rotation.properties'
    $held = [IO.File]::Open($configPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try { Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[1],$ids[2]) } 'Real locked configuration interrupts Enable update' }
    finally { $held.Dispose() }
    Assert-Test ([IO.File]::Exists($pending)) 'Configuration rollback journal is preserved while locked'
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    Assert-Test (-not [IO.File]::Exists($pending)) 'Configuration journal is recovered before idempotent install'
    Assert-Snapshot $game $enabledSnapshot 'Configuration recovery restores prior enabled state'
    Assert-Protected $game $before 'Failure and recovery preserve original game files'

    # Simulate an abrupt stop after ledger commit but before journal cleanup.
    $ledgerPath = Join-Path $game '.open-sturmovik-loading-rotation/installation.json'
    $ledger = Get-Content -LiteralPath $ledgerPath -Raw | ConvertFrom-Json
    $committedJournal = [pscustomobject]@{id=$ledger.transactionId;entries=@()}
    foreach ($entry in $ledger.entries) { $committedJournal.entries += [pscustomobject]@{relative=$entry.relative;before=$entry.original;after=$entry.current} }
    [IO.File]::WriteAllText($pending, ($committedJournal | ConvertTo-Json -Depth 8))
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    Assert-Test (-not [IO.File]::Exists($pending)) 'Committed journal is finalized without rolling back'
    Assert-Snapshot $game $enabledSnapshot 'Committed recovery preserves published files'

    $game = New-Fixture 'custom-texture'
    $before = Snapshot-Fixture $game
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    $customRelative = 'Files/gui/backgrounds/background-3.tga'
    Text-Fixture $game $customRelative 'manual-texture-customization-must-survive'
    $customHash = Hash-Test (Join-Path $game $customRelative)
    $removed = Set-OSLoadingRotation -GameRoot $game -Action Remove
    Assert-Test ($customRelative -in $removed.preserved -and (Hash-Test (Join-Path $game $customRelative)) -eq $customHash) 'Remove preserves and reports a manually changed texture'
    $expected = $before.Clone();$expected[$customRelative]=$customHash
    Assert-Snapshot $game $expected 'Custom texture removal restores all other files'

    $game = New-Fixture 'custom-class'
    $before = Snapshot-Fixture $game
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    Text-Fixture $game 'Files/F35AD7F42DE76ABC' 'manual-class-modification-must-survive'
    $customSnapshot = Snapshot-Fixture $game
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Remove } 'Remove refuses a manually changed Java class'
    Assert-Snapshot $game $customSnapshot 'Class conflict does not partially uninstall resources'
    Assert-Protected $game $before 'Class conflict preserves original game files'

    $game = New-Fixture 'conflicting-console'
    Text-Fixture $game 'Files/B96FAC8E2C4DDBE0' 'unrecognized-console-override'
    $before = Snapshot-Fixture $game
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Install } 'Install refuses an unknown ConsoleGL0 override'
    Assert-Snapshot $game $before 'Unknown override remains byte-identical'

    $game = New-Fixture 'custom-material'
    $before = Snapshot-Fixture $game
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    $customMaterial = 'Files/gui/backgrounds/background-3_fr.mat'
    $relatedTexture = 'Files/gui/backgrounds/background-3.tga'
    Text-Fixture $game $customMaterial "[ClassInfo]`r`n  ClassName TMaterial`r`n[Layer0]`r`n  TextureName background-3.tga`r`n  tfMagLinear 0`r`n"
    $customHash = Hash-Test (Join-Path $game $customMaterial)
    $textureHash = Hash-Test (Join-Path $game $relatedTexture)
    $customSnapshot = Snapshot-Fixture $game
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Enable -ImageIds @($ids[0],$ids[1]) } 'Enable refuses modified installed resources'
    Assert-Snapshot $game $customSnapshot 'Rejected activation preserves all installed files'
    $removed = Set-OSLoadingRotation -GameRoot $game -Action Remove
    Assert-Test ($customMaterial -in $removed.preserved -and $relatedTexture -in $removed.preserved) 'Remove reports custom material and dependent texture'
    $expected = $before.Clone();$expected[$customMaterial]=$customHash;$expected[$relatedTexture]=$textureHash
    Assert-Snapshot $game $expected 'Custom material removal retains its texture and restores other files'

    $game = New-Fixture 'damaged-backup' $true
    $before = Snapshot-Fixture $game
    $null = Set-OSLoadingRotation -GameRoot $game -Action Install
    $installedSnapshot = Snapshot-Fixture $game
    $ledger = Get-Content -LiteralPath (Join-Path $game '.open-sturmovik-loading-rotation/installation.json') -Raw | ConvertFrom-Json
    $originalClass = @($ledger.entries | Where-Object { $_.relative -eq 'Files/B96FAC8E2C4DDBE0' })[0].original
    Text-Fixture $game ('.open-sturmovik-loading-rotation/backups/' + $originalClass + '.bin') 'corrupted-fixture-backup'
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Remove } 'Remove refuses a damaged original backup'
    Assert-Snapshot $game $installedSnapshot 'Damaged backup causes no partial restoration'
    Assert-Protected $game $before 'Damaged backup preserves original game files'

    $game = New-Fixture 'unknown-profile'
    Text-Fixture $game 'il2fb.exe' 'unrecognized-profile-fixture-executable'
    $before = Snapshot-Fixture $game
    Expect-Failure { Set-OSLoadingRotation -GameRoot $game -Action Install } 'Install refuses an unrecognized game profile'
    Assert-Snapshot $game $before 'Unrecognized profile receives no game file changes'

    & 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'tools\Set-LoadingRotation.ps1') -Action Status | Out-Null
    Assert-Test ($LASTEXITCODE -eq 0) 'PowerShell 5.1 entry script resolves its default GameRoot'
    Assert-Test ((Get-FileHash -LiteralPath (Join-Path $root 'tools\OpenSturmovik.LoadingRotation.psm1')).Hash -eq $moduleSha256) 'Module remained unchanged throughout this test run'
    $report = [ordered]@{result='PASS';powershell=$PSVersionTable.PSVersion.ToString();fixtureRoot=$output;moduleSha256=$moduleSha256;checkCount=$checks.Count;checks=@($checks.ToArray());gameLaunched=$false;uiTested=$false}
    [IO.File]::WriteAllText((Join-Path $output 'report.json'),($report | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
    Write-Host ("PASS: {0} checks; no game process launched. Report: {1}" -f $checks.Count,(Join-Path $output 'report.json'))
} catch {
    $failure = $_
    $report = [ordered]@{result='FAIL';powershell=$PSVersionTable.PSVersion.ToString();fixtureRoot=$output;moduleSha256=$moduleSha256;checkCount=$checks.Count;checks=@($checks.ToArray());error=$failure.Exception.Message;line=$failure.InvocationInfo.ScriptLineNumber;gameLaunched=$false}
    [IO.File]::WriteAllText((Join-Path $output 'report.json'),($report | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
    throw $failure
}
