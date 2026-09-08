[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [string]$SelectorArchive = 'D:\Projets\GITHUB\#res\IL2 1946\Outils\IL-2_Selector_5.1.2.zip',
    [string]$SevenZipPath = 'C:\Program Files\7-Zip\7z.exe',
    [string]$BaselineRoot,
    [switch]$RefreshManifest
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($BaselineRoot)) {
    $BaselineRoot = Join-Path $PSScriptRoot '..\WIP\test-installations\IL 2 Sturmovik 1946 test'
}
$expectedArchiveSha256 = '0F1A8C6DDB4D6062DE84F99583B932C1DE429E1D2D7119DCA8EE69EB7817C7D4'
$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedArchive = (Resolve-Path -LiteralPath $SelectorArchive -ErrorAction Stop).Path
$resolvedSevenZip = (Resolve-Path -LiteralPath $SevenZipPath -ErrorAction Stop).Path
$resolvedBaseline = (Resolve-Path -LiteralPath $BaselineRoot -ErrorAction Stop).Path.TrimEnd('\')

if (@(Get-Process -Name 'il2fb','IL-2 Selector' -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'IL-2 ou IL-2 Selector est actif. Fermer le programme avant de preparer le laboratoire.'
}
if ((Get-FileHash -LiteralPath $resolvedArchive -Algorithm SHA256).Hash -ne $expectedArchiveSha256) {
    throw 'L archive IL-2 Selector 5.1.2 ne correspond pas a l empreinte approuvee.'
}
foreach ($relative in @(
    'files.SFS',
    'Files\com\maddox\il2\objects\air.ini',
    'Files\com\maddox\il2\objects\stationary.ini',
    '_Game Switcher\4.09finalModsON(No-6DoF)\files.SFS'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedGame $relative) -PathType Leaf)) {
        throw "Fichier 4.09m requis absent : $relative"
    }
}

$modSfs = Join-Path $resolvedGame '_Game Switcher\4.09finalModsON(No-6DoF)\files.SFS'
$activeSfs = Join-Path $resolvedGame 'files.SFS'
if ((Get-FileHash -LiteralPath $activeSfs -Algorithm SHA256).Hash -ne
    (Get-FileHash -LiteralPath $modSfs -Algorithm SHA256).Hash) {
    throw 'Le profil 4.09m modifie sans 6DOF doit etre active avant l installation du laboratoire.'
}

$labRoot = Join-Path $resolvedGame '_OpenSturmovikLab'
$stageRoot = Join-Path $labRoot 'selector-5.1.2-package'
$backupRoot = Join-Path $labRoot 'pre-selector-backup'
$manifestPath = Join-Path $labRoot 'selector-dump-lab.json'
if ((Test-Path -LiteralPath $manifestPath -PathType Leaf) -and -not $RefreshManifest) {
    throw "Le laboratoire Selector est deja prepare : $manifestPath"
}
New-Item -ItemType Directory -Path $stageRoot,$backupRoot -Force | Out-Null

$extractOutput = & $resolvedSevenZip x -y "-o$stageRoot" $resolvedArchive 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Echec d extraction du Selector : $($extractOutput -join ' ')"
}

$packageFiles = @(Get-ChildItem -LiteralPath $stageRoot -File -Recurse -Force)
if ($packageFiles.Count -eq 0) {
    throw 'Le paquet Selector extrait est vide.'
}
$before = New-Object 'System.Collections.Generic.List[object]'
foreach ($source in $packageFiles) {
    $relative = [IO.Path]::GetRelativePath($stageRoot, $source.FullName)
    $target = Join-Path $resolvedGame $relative
    $backup = Join-Path $backupRoot $relative
    $baseline = Join-Path $resolvedBaseline $relative
    $existed = Test-Path -LiteralPath $baseline -PathType Leaf
    $record = [ordered]@{
        path = $relative
        existed = $existed
        length = if ($existed) { (Get-Item -LiteralPath $baseline).Length } else { $null }
        sha256 = if ($existed) { (Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash } else { $null }
    }
    $before.Add([pscustomobject]$record) | Out-Null
    if ($existed) {
        $backupDirectory = Split-Path -Parent $backup
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
        if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
            Copy-Item -LiteralPath $baseline -Destination $backup
        }
        if ((Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash) {
            throw "Sauvegarde non conforme : $relative"
        }
    }
}

foreach ($source in $packageFiles) {
    $relative = [IO.Path]::GetRelativePath($stageRoot, $source.FullName)
    $target = Join-Path $resolvedGame $relative
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    Copy-Item -LiteralPath $source.FullName -Destination $target -Force
    if ((Get-FileHash -LiteralPath $source.FullName -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
        throw "Installation non conforme : $relative"
    }
}

function Set-IniValue {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Value
    )
    $inside = $false
    $found = $false
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*\[(.+)\]\s*$') {
            $inside = $matches[1] -ieq $Section
            continue
        }
        if ($inside -and $Lines[$index] -match ('^\s*' + [regex]::Escape($Key) + '\s*=')) {
            $Lines[$index] = "$Key=$Value"
            $found = $true
            break
        }
    }
    if (-not $found) { throw "Cle introuvable dans il2fb.ini : [$Section] $Key" }
    return ,$Lines
}

$selectorIni = Join-Path $resolvedGame 'il2fb.ini'
$iniLines = [IO.File]::ReadAllLines($selectorIni)
$settings = [ordered]@{
    ModType = '7'
    RamSize = '1024'
    ExpertMode = '1'
    MemoryStrategy = '0'
    UseCachedFileLists = '0'
    MultipleInstances = '0'
    ExitWithIL2 = '1'
    SplashScreenMode = '0'
    DumpMode = '3'
    InstantDump = '1'
    DebugMode = '0'
    ShowLogWarnings = '0'
}
foreach ($key in $settings.Keys) {
    $iniLines = Set-IniValue -Lines $iniLines -Section 'Settings' -Key $key -Value $settings[$key]
}
[IO.File]::WriteAllLines($selectorIni, $iniLines, [Text.UTF8Encoding]::new($false))

$runtimePairs = [ordered]@{
    'bin\selector\basefiles\mod\il2fb.exe' = 'il2fb.exe'
    'bin\selector\basefiles\mod\wrapper.dll' = 'wrapper.dll'
    'bin\selector\basefiles\DINPUT.dll' = 'DINPUT.dll'
}
foreach ($targetRelative in $runtimePairs.Values) {
    $target = Join-Path $resolvedGame $targetRelative
    $backup = Join-Path $backupRoot $targetRelative
    $sourceRelative = @($runtimePairs.Keys | Where-Object { $runtimePairs[$_] -eq $targetRelative })[0]
    $source = Join-Path $resolvedGame $sourceRelative
    $baseline = Join-Path $resolvedBaseline $targetRelative
    $runtimeAlreadyApplied = (Test-Path -LiteralPath $target -PathType Leaf) -and
        (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq
        (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $backupExists = Test-Path -LiteralPath $backup -PathType Leaf
    $backupIsSelector = $backupExists -and
        (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash -eq
        (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    $baselineExists = Test-Path -LiteralPath $baseline -PathType Leaf
    $existed = ($backupExists -and -not ($backupIsSelector -and -not $baselineExists)) -or
        ($baselineExists -and -not $runtimeAlreadyApplied)
    $statePath = if ($backupExists -and -not ($backupIsSelector -and -not $baselineExists)) {
        $backup
    }
    elseif ($baselineExists) {
        $baseline
    }
    else {
        $target
    }
    $before.Add([pscustomobject][ordered]@{
        path = $targetRelative
        existed = $existed
        length = if ($existed) { (Get-Item -LiteralPath $statePath).Length } else { $null }
        sha256 = if ($existed) { (Get-FileHash -LiteralPath $statePath -Algorithm SHA256).Hash } else { $null }
    }) | Out-Null
    if ($existed -and -not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        $backupDirectory = Split-Path -Parent $backup
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
        Copy-Item -LiteralPath $target -Destination $backup
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash) {
            throw "Sauvegarde du runtime non conforme : $targetRelative"
        }
    }
}
foreach ($sourceRelative in $runtimePairs.Keys) {
    $source = Join-Path $resolvedGame $sourceRelative
    $target = Join-Path $resolvedGame $runtimePairs[$sourceRelative]
    Copy-Item -LiteralPath $source -Destination $target -Force
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
        throw "Runtime Selector non conforme : $($runtimePairs[$sourceRelative])"
    }
}

$dumpRoot = Join-Path $resolvedGame 'dump'
New-Item -ItemType Directory -Path $dumpRoot -Force | Out-Null
if (@(Get-ChildItem -LiteralPath $dumpRoot -Force).Count -ne 0) {
    throw 'Le dossier dump doit etre vide avant le premier essai.'
}

$after = foreach ($relative in @('il2fb.exe','wrapper.dll','DINPUT.dll','files.SFS','il2fb.ini','IL-2 Selector.exe')) {
    $path = Join-Path $resolvedGame $relative
    $item = Get-Item -LiteralPath $path
    [ordered]@{
        path = $relative
        length = $item.Length
        sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    }
}
$manifest = [ordered]@{
    created_utc = [DateTime]::UtcNow.ToString('O')
    purpose = 'Open Sturmovik 4.09m Selector 5.1.2 Dump Mode laboratory'
    game_root = $resolvedGame
    baseline_root = $resolvedBaseline
    selector_archive = $resolvedArchive
    selector_archive_sha256 = $expectedArchiveSha256
    base_profile = '8 - 4.09m modifie sans 6DOF'
    settings = $settings
    package_destinations_before = @($before | ForEach-Object { $_ })
    runtime_after = @($after)
    backup_root = $backupRoot
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

[pscustomobject]@{
    ReadyForSelectorConfirmation = $true
    GameRoot = $resolvedGame
    Manifest = $manifestPath
    Selector = (Join-Path $resolvedGame 'IL-2 Selector.exe')
}
