[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [string]$ReferenceRoot = 'C:\Users\Alexis\Desktop\IL 2 Sturmovik 1946',
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),
    [string]$ProcmonPath = (Join-Path $PSScriptRoot '..\build\test-tools\sysinternals\Procmon64.exe'),
    [string]$FrameCapturePath = (Join-Path $PSScriptRoot '..\build\test-tools\FrameCapture.exe'),
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
$checks = New-Object 'System.Collections.Generic.List[object]'
function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $checks.Add([pscustomobject]@{ Check = $Name; Passed = $Passed; Detail = $Detail }) | Out-Null
}

function Get-IniValue {
    param([string]$Path, [string]$Section, [string]$Key)
    $inside = $false
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[(.+)\]\s*$') {
            $inside = $matches[1] -ieq $Section
            continue
        }
        if ($inside -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*)$')) {
            return $matches[1].Trim()
        }
    }
    return $null
}

function Get-PeState {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 256 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
        throw "En-tete PE invalide : $Path"
    }
    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    if ($peOffset -lt 0 -or $peOffset + 24 -ge $bytes.Length -or
        $bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45) {
        throw "Signature PE invalide : $Path"
    }
    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    $characteristics = [BitConverter]::ToUInt16($bytes, $peOffset + 22)
    $optionalMagic = [BitConverter]::ToUInt16($bytes, $peOffset + 24)
    return [pscustomobject]@{
        Machine = ('0x{0:X4}' -f $machine)
        Pe32 = $optionalMagic -eq 0x10B
        LargeAddressAware = ($characteristics -band 0x20) -ne 0
    }
}

$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedReference = (Resolve-Path -LiteralPath $ReferenceRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedRepository = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path.TrimEnd('\')
Add-Check -Name 'Dossier de test distinct de la reference' -Passed ($resolvedGame -ine $resolvedReference) -Detail "$resolvedGame != $resolvedReference"
$gameItem = Get-Item -LiteralPath $resolvedGame -Force
Add-Check -Name 'Dossier de test non redirige' -Passed (-not ($gameItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) -Detail $gameItem.Attributes.ToString()
Add-Check -Name 'Aucun IL-2 actif' -Passed (@(Get-Process -Name 'il2fb' -ErrorAction SilentlyContinue).Count -eq 0) -Detail 'Le processus doit etre absent avant armement.'

$pairs = [ordered]@{
    'il2fb.exe' = '_Game Switchers\4.09finalModsON(No-6DoF)\il2fb.exe'
    'files.SFS' = '_Game Switchers\4.09finalModsON(No-6DoF)\files.SFS'
    'wrapper.dll' = '_Game Switchers\4.09finalModsON(No-6DoF)\wrapper.dll'
    'Files\com\maddox\il2\objects\air.ini' = '_Game Switchers\409m air.ini\Air.ini\air.ini'
    'Files\com\maddox\il2\objects\stationary.ini' = '_Game Switchers\Stationary\409m\stationary.ini'
}
foreach ($activeRelative in $pairs.Keys) {
    $active = Join-Path $resolvedGame $activeRelative
    $source = Join-Path $resolvedGame $pairs[$activeRelative]
    $present = (Test-Path -LiteralPath $active -PathType Leaf) -and (Test-Path -LiteralPath $source -PathType Leaf)
    $same = $false
    if ($present) {
        $same = (Get-FileHash -LiteralPath $active -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
    }
    $pairDetail = if ($present) { "identique=$same" } else { 'fichier absent' }
    Add-Check -Name "Profil 8 : $activeRelative" -Passed ($present -and $same) -Detail $pairDetail
}

$activeExe = Join-Path $resolvedGame 'il2fb.exe'
if (Test-Path -LiteralPath $activeExe -PathType Leaf) {
    $pe = Get-PeState -Path $activeExe
    Add-Check -Name 'Executable PE32 x86' -Passed ($pe.Pe32 -and $pe.Machine -eq '0x014C') -Detail "machine=$($pe.Machine), pe32=$($pe.Pe32)"
    Add-Check -Name 'Executable Large Address Aware' -Passed $pe.LargeAddressAware -Detail "LAA=$($pe.LargeAddressAware)"
}
else {
    Add-Check -Name 'Executable actif present' -Passed $false -Detail $activeExe
}

$switcherRepository = Join-Path $resolvedRepository 'Open_Sturmovik_Switcher.ps1'
$switcherTest = Join-Path $resolvedGame 'Open_Sturmovik_Switcher.ps1'
$switcherSame = (Test-Path -LiteralPath $switcherRepository -PathType Leaf) -and
    (Test-Path -LiteralPath $switcherTest -PathType Leaf) -and
    ((Get-FileHash -LiteralPath $switcherRepository -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $switcherTest -Algorithm SHA256).Hash)
Add-Check -Name 'Selecteur de test a jour' -Passed $switcherSame -Detail "identique=$switcherSame"

$manifestPath = Join-Path $resolvedGame 'manifests\java47-1.15.json'
$javaGood = $true
$javaCount = 0
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
    foreach ($item in (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)) {
        $classPath = Join-Path (Join-Path $resolvedGame 'Files') $item.file
        if (-not (Test-Path -LiteralPath $classPath -PathType Leaf)) { $javaGood = $false; continue }
        $hash = (Get-FileHash -LiteralPath $classPath -Algorithm SHA256).Hash
        $stream = [IO.File]::OpenRead($classPath)
        try {
            $header = New-Object byte[] 8
            if ($stream.Read($header, 0, 8) -ne 8) { $javaGood = $false; continue }
        }
        finally { $stream.Dispose() }
        $major = ([int]$header[6] -shl 8) -bor [int]$header[7]
        if ($hash -ne $item.staged_sha256 -or $major -ne 47) { $javaGood = $false }
        $javaCount++
    }
}
else { $javaGood = $false }
Add-Check -Name 'Classes Java corrigees' -Passed ($javaGood -and $javaCount -eq 56) -Detail "verifiees=$javaCount, version=47"

$conf = Join-Path $resolvedGame 'conf.ini'
$configurationExpectations = [ordered]@{
    'game/eventlogkeep' = '1'
    'Console/LOG' = '1'
    'Console/LOGTIME' = '1'
    'Console/LOGKEEP' = '1'
    'Console/LOGDEBUG' = '1'
    'Render_OpenGL/TexQual' = '3'
    'Render_OpenGL/TexMipFilter' = '2'
    'Render_OpenGL/HardwareShaders' = '1'
    'Render_OpenGL/Forest' = '3'
    'Render_OpenGL/Water' = '4'
    'Render_OpenGL/Effects' = '1'
}
foreach ($expectation in $configurationExpectations.Keys) {
    $section, $key = $expectation -split '/', 2
    $actual = Get-IniValue -Path $conf -Section $section -Key $key
    $expected = $configurationExpectations[$expectation]
    Add-Check -Name "Configuration $expectation" -Passed ($actual -eq $expected) -Detail "attendu=$expected, actuel=$actual"
}
$affinityText = Get-IniValue -Path $conf -Section 'rts' -Key 'ProcessAffinityMask'
$affinity = 0L
$affinityValid = [Int64]::TryParse($affinityText, [ref]$affinity) -and $affinity -gt 0 -and $affinity -le [UInt32]::MaxValue
Add-Check -Name 'Affinite CPU configuree' -Passed $affinityValid -Detail "masque=$affinityText"

$procmonResolved = [IO.Path]::GetFullPath($ProcmonPath)
$frameResolved = [IO.Path]::GetFullPath($FrameCapturePath)
Add-Check -Name 'Process Monitor portable' -Passed (Test-Path -LiteralPath $procmonResolved -PathType Leaf) -Detail $procmonResolved
Add-Check -Name 'Enregistreur de la fenetre' -Passed (Test-Path -LiteralPath $frameResolved -PathType Leaf) -Detail $frameResolved
$wpr = Get-Command 'wpr.exe' -ErrorAction SilentlyContinue
$wprDetail = if ($wpr) { $wpr.Source } else { 'introuvable' }
Add-Check -Name 'Windows Performance Recorder' -Passed ($null -ne $wpr) -Detail $wprDetail

$drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($resolvedRepository).Substring(0, 1))
$freeGiB = [Math]::Round($drive.Free / 1GB, 2)
Add-Check -Name 'Espace libre pour les traces' -Passed ($drive.Free -ge 10GB) -Detail "$freeGiB Gio libres"

$report = [ordered]@{
    generated_utc = [DateTime]::UtcNow.ToString('O')
    game_root = $resolvedGame
    reference_root = $resolvedReference
    repository_root = $resolvedRepository
    profile = '8 - 4.09m modifie (sans 6DOF), wrapper historique, OpenGL natif'
    checks = $checks
    ready = @($checks | Where-Object { -not $_.Passed }).Count -eq 0
}
if ($ReportPath) {
    $resolvedReport = [IO.Path]::GetFullPath($ReportPath)
    $reportDirectory = Split-Path -Parent $resolvedReport
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedReport -Encoding UTF8
}
$checks | Format-Table -Wrap -AutoSize
if (-not $report.ready) {
    throw 'La copie de test n est pas prete. Corriger les controles en echec avant toute capture.'
}
[pscustomobject]@{ Ready = $true; Profile = $report.profile; GameRoot = $resolvedGame; Checks = $checks.Count; Report = $ReportPath }
