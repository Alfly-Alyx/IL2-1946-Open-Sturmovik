[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [ValidateSet('1','2','3','4','5','6','7','8','9')][string]$Profile = '9',
    [switch]$Windowed1024,
    [string]$ReferenceRoot,
    [string]$RepositoryRoot,
    [string]$ProcmonPath,
    [string]$FrameCapturePath,
    [switch]$SelectorDumpLab,
    [string[]]$AllowedContentFailures = @(),
    [switch]$ExcludeNuclear,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

# Windows PowerShell 5.1 can evaluate parameter defaults before $PSScriptRoot is
# populated. Resolve script-relative defaults only after parameter binding.
if ([string]::IsNullOrWhiteSpace($ReferenceRoot)) {
    $ReferenceRoot = Join-Path $PSScriptRoot '..\WIP\resources\IL2\IL 2 Sturmovik 1946'
}
if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
    $RepositoryRoot = Join-Path $PSScriptRoot '..'
}
if ([string]::IsNullOrWhiteSpace($ProcmonPath)) {
    $ProcmonPath = Join-Path $PSScriptRoot '..\WIP\sdk\test-tools\sysinternals\Procmon64.exe'
}
if ([string]::IsNullOrWhiteSpace($FrameCapturePath)) {
    $FrameCapturePath = Join-Path $PSScriptRoot '..\WIP\sdk\test-tools\FrameCapture.exe'
}

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

function Get-PowerShellSemanticHash {
    param([string]$Path)

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null
    if ($parseErrors.Count -ne 0) {
        throw "Script PowerShell invalide : $Path ($($parseErrors[0].Message))"
    }

    $semanticText = [string]::Join("`n", @(
        $tokens | Where-Object {
            $_.Kind -notin @(
                [System.Management.Automation.Language.TokenKind]::Comment,
                [System.Management.Automation.Language.TokenKind]::NewLine,
                [System.Management.Automation.Language.TokenKind]::EndOfInput
            )
        } | ForEach-Object { "$($_.Kind):$($_.Text)" }
    ))
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($semanticText))
        return ([BitConverter]::ToString($hash)).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-GraphicsVendor {
    try {
        $adapters = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        $adapter = @($adapters | Where-Object {
            $_.CurrentHorizontalResolution -and $_.CurrentVerticalResolution
        })[0]
        if (-not $adapter) {
            $adapter = $adapters[0]
        }
        $pnpId = [string]$adapter.PNPDeviceID
        if ($pnpId -match 'VEN_10DE') { return 'NVIDIA' }
        if ($pnpId -match 'VEN_(1002|1022)') { return 'AMD' }
        if ($pnpId -match 'VEN_8086') { return 'Intel' }
    }
    catch { }
    return 'Generique'
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

$rootSfs = @(Get-ChildItem -LiteralPath $resolvedGame -File -Filter '*.SFS')
Add-Check -Name 'Nombre de SFS conforme a la base 4.09m' -Passed ($rootSfs.Count -eq 52) -Detail "racine=$($rootSfs.Count), attendu=52"
$laterSfs = @($rootSfs | Where-Object {
    $_.Name -match '^fb_(3do|maps)(2[1-9]|3[0-9])' -or
    $_.Name -match '^fb_sounds\.SFS$' -or
    $_.Name -match '^filesserver\.SFS$'
})
$laterSfsDetail = if ($laterSfs.Count -eq 0) { 'aucun' } else { $laterSfs.Name -join ', ' }
Add-Check -Name 'Aucun SFS posterieur a 4.09m' -Passed ($laterSfs.Count -eq 0) -Detail $laterSfsDetail

$official409 = [ordered]@{
    'fb_3do19.SFS' = '4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670'
    'fb_3do20.SFS' = '02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283'
    'fb_maps15.SFS' = 'AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9'
    'il2_core.dll' = '3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3'
    'il2_corep4.dll' = '0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979'
    'mg_snd.dll' = '2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421'
    'mg_snd_sse.dll' = 'FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4'
}
foreach ($name in $official409.Keys) {
    $path = Join-Path $resolvedGame $name
    $present = Test-Path -LiteralPath $path -PathType Leaf
    $actual = if ($present) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash } else { '' }
    Add-Check -Name "Fichier officiel 4.09m : $name" -Passed ($present -and $actual -eq $official409[$name]) -Detail "identique=$($present -and $actual -eq $official409[$name])"
}

$profileFolder = switch ($Profile) {
    '1' { '4.08 Mods OFF (Original)' }
    '2' { '4.08 Mod ON (NO 6DOF)' }
    '3' { '4.08 Mods 6DOF ON' }
    '4' { '4.09 Mods OFF (Original)' }
    '5' { '4.09 Mods ON (NO 6DOF)' }
    '6' { '4.09 Mods 6DOF ON' }
    '7' { '4.09finalModsOFF(Original)' }
    '9' { '4.09final_ModsON+6DoF' }
    default { '4.09finalModsON(No-6DoF)' }
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
$isOriginal = $Profile -in @('1','4','7')
$airSource = if ($Profile -in @('1','2','3')) { '408m air.ini\Air.ini\air.ini' } else { '409m air.ini\Air.ini\air.ini' }
$stationarySource = if ($Profile -in @('7','8','9')) { 'Stationary\409m\stationary.ini' } else { 'Stationary\408 & 409b\stationary.ini' }
$pairs = if ($SelectorDumpLab) {
    [ordered]@{
        'il2fb.exe' = 'bin\selector\basefiles\mod\il2fb.exe'
        'wrapper.dll' = 'bin\selector\basefiles\mod\wrapper.dll'
        'DINPUT.dll' = 'bin\selector\basefiles\DINPUT.dll'
        'files.SFS' = '_Game Switchers\4.09finalModsON(No-6DoF)\files.SFS'
        'Files\com\maddox\il2\objects\air.ini' = '_Game Switchers\409m air.ini\Air.ini\air.ini'
        'Files\com\maddox\il2\objects\stationary.ini' = '_Game Switchers\Stationary\409m\stationary.ini'
    }
}
else {
    $profilePairs = [ordered]@{
        'il2fb.exe' = "_Game Switchers\$profileFolder\il2fb.exe"
        'files.SFS' = "_Game Switchers\$profileFolder\files.SFS"
        'Files\com\maddox\il2\objects\air.ini' = "_Game Switchers\$airSource"
        'Files\com\maddox\il2\objects\stationary.ini' = "_Game Switchers\$stationarySource"
    }
    if (-not $isOriginal) {
        $profilePairs['wrapper.dll'] = "_Game Switchers\$profileFolder\wrapper.dll"
    }
    $profilePairs
}
foreach ($activeRelative in $pairs.Keys) {
    $active = Join-Path $resolvedGame $activeRelative
    $source = Join-Path $resolvedGame $pairs[$activeRelative]
    $present = (Test-Path -LiteralPath $active -PathType Leaf) -and (Test-Path -LiteralPath $source -PathType Leaf)
    $same = $false
    if ($present) {
        if ([IO.Path]::GetExtension($activeRelative) -ieq '.ini') {
            # Les copies LF et CRLF sont equivalentes pour IL-2. Un controle
            # binaire ferait echouer a tort un profil pourtant identique.
            $activeText = [IO.File]::ReadAllText($active).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
            $sourceText = [IO.File]::ReadAllText($source).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
            $same = $activeText -ceq $sourceText
        }
        else {
            $same = (Get-FileHash -LiteralPath $active -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        }
    }
    $pairDetail = if ($present) { "identique=$same" } else { 'fichier absent' }
    Add-Check -Name "Profil $Profile : $activeRelative" -Passed ($present -and $same) -Detail $pairDetail
}
if ($isOriginal -and -not $SelectorDumpLab) {
    $activeWrapper = Join-Path $resolvedGame 'wrapper.dll'
    Add-Check -Name "Profil $Profile : aucun wrapper.dll actif" -Passed (-not (Test-Path -LiteralPath $activeWrapper)) -Detail $activeWrapper
}

$activeExe = Join-Path $resolvedGame 'il2fb.exe'
if (Test-Path -LiteralPath $activeExe -PathType Leaf) {
    $pe = Get-PeState -Path $activeExe
    Add-Check -Name 'Executable PE32 x86' -Passed ($pe.Pe32 -and $pe.Machine -eq '0x014C') -Detail "machine=$($pe.Machine), pe32=$($pe.Pe32)"
    if ($SelectorDumpLab) {
        Add-Check -Name 'Executable Selector de laboratoire' -Passed $true -Detail "LAA=$($pe.LargeAddressAware), memoire geree par le Selector"
    }
    else {
        $laaExpected = -not $isOriginal
        Add-Check -Name 'Executable Large Address Aware conforme au profil' -Passed ($pe.LargeAddressAware -eq $laaExpected) -Detail "attendu=$laaExpected, actuel=$($pe.LargeAddressAware)"
    }
}
else {
    Add-Check -Name 'Executable actif present' -Passed $false -Detail $activeExe
}

$switcherComponents = @(
    'Open_Sturmovik_Switcher.bat',
    '_Game Switchers\Open_Sturmovik_Switcher.hta',
    '_Game Switchers\Open_Sturmovik_Hash_Check.bat',
    '_Game Switchers\Open_Sturmovik_Switcher.ico'
)
$switcherDifferences = @()
foreach ($relative in $switcherComponents) {
    $repositoryComponent = Join-Path $resolvedRepository $relative
    $testComponent = Join-Path $resolvedGame $relative
    if (-not (Test-Path -LiteralPath $repositoryComponent -PathType Leaf) -or
        -not (Test-Path -LiteralPath $testComponent -PathType Leaf) -or
        (Get-FileHash -LiteralPath $repositoryComponent -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $testComponent -Algorithm SHA256).Hash) {
        $switcherDifferences += $relative
    }
}
$switcherDetail = if ($switcherDifferences.Count -eq 0) {
    'BAT, interface, controleur et icone identiques'
}
else {
    'absents ou differents : ' + ($switcherDifferences -join ', ')
}
Add-Check -Name 'Switcher de test a jour' -Passed ($switcherDifferences.Count -eq 0) -Detail $switcherDetail

if ($SelectorDumpLab) {
    $selectorIni = Join-Path $resolvedGame 'il2fb.ini'
    $selectorExpectations = [ordered]@{
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
    }
    foreach ($key in $selectorExpectations.Keys) {
        $actual = if (Test-Path -LiteralPath $selectorIni -PathType Leaf) { Get-IniValue -Path $selectorIni -Section 'Settings' -Key $key } else { $null }
        Add-Check -Name "Selector $key" -Passed ($actual -eq $selectorExpectations[$key]) -Detail "attendu=$($selectorExpectations[$key]), actuel=$actual"
    }
    $selectorManifest = Join-Path $resolvedGame '_OpenSturmovikLab\selector-dump-lab.json'
    Add-Check -Name 'Manifeste du laboratoire Selector' -Passed (Test-Path -LiteralPath $selectorManifest -PathType Leaf) -Detail $selectorManifest
    $dumpRoot = Join-Path $resolvedGame 'dump'
    $dumpEmpty = (Test-Path -LiteralPath $dumpRoot -PathType Container) -and @(Get-ChildItem -LiteralPath $dumpRoot -Force).Count -eq 0
    Add-Check -Name 'Dossier dump vide avant capture' -Passed $dumpEmpty -Detail $dumpRoot
}

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

$contentValidator = Join-Path $resolvedRepository 'tools\Test-OpenSturmovikContent.ps1'
$contentReport = if ($ReportPath) {
    [IO.Path]::ChangeExtension([IO.Path]::GetFullPath($ReportPath), '.content.json')
}
else {
    Join-Path ([IO.Path]::GetTempPath()) ('open-sturmovik-content-' + [Guid]::NewGuid().ToString('N') + '.json')
}
$contentValidationPassed = $false
$contentValidationDetail = 'outil absent'
if (Test-Path -LiteralPath $contentValidator -PathType Leaf) {
    & $contentValidator -ProjectRoot $resolvedRepository -ContentRoot $resolvedGame -ReportPath $contentReport -ExcludeNuclear:$ExcludeNuclear | Out-Host
    $contentExitCode = $LASTEXITCODE
    if (Test-Path -LiteralPath $contentReport -PathType Leaf) {
        $contentSummary = Get-Content -LiteralPath $contentReport -Raw | ConvertFrom-Json
        $failedContentNames = @($contentSummary.Checks | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object { $_.Name })
        $unexpectedContentFailures = @($failedContentNames | Where-Object { $_ -notin $AllowedContentFailures })
        $contentValidationPassed = $unexpectedContentFailures.Count -eq 0 -and
            ($contentExitCode -eq 0 -or $failedContentNames.Count -gt 0)
        $allowedDetail = if ($failedContentNames.Count -ne 0) {
            "; echecs autorises=$($failedContentNames -join ', ')"
        }
        else { '' }
        $contentValidationDetail = "PASS=$($contentSummary.Pass), WARN=$($contentSummary.Warn), FAIL=$($contentSummary.Fail)$allowedDetail"
    }
    else {
        $contentValidationDetail = "rapport absent, code=$contentExitCode"
    }
}
Add-Check -Name 'Contenu Open Sturmovik v1.15 coherent' -Passed $contentValidationPassed -Detail $contentValidationDetail
if (-not $ReportPath -and (Test-Path -LiteralPath $contentReport -PathType Leaf)) {
    Remove-Item -LiteralPath $contentReport -Force
}

$conf = Join-Path $resolvedGame 'conf.ini'
$graphicsVendor = Get-GraphicsVendor
$glProvider = Get-IniValue -Path $conf -Section 'GLPROVIDER' -Key 'GL'
$dxProvider = Get-IniValue -Path $conf -Section 'GLPROVIDERS' -Key 'DirectX'
$isDirectX = $dxProvider -and $glProvider -ieq $dxProvider
$renderSection = if ($isDirectX) { 'Render_DirectX' } else { 'Render_OpenGL' }
$profileLabel = $profileLabel -replace ', OpenGL natif$', (', rendu ' + $glProvider)
$nativeNvidia = -not $isDirectX -and $graphicsVendor -eq 'NVIDIA'
$expectedHardwareShaders = if ($nativeNvidia) { '1' } else { '0' }
$expectedForest = if ($nativeNvidia) { '3' } else { '2' }
$expectedLandGeom = if ($nativeNvidia) { '3' } else { '2' }
$configurationExpectations = [ordered]@{
    'window/DrawIfNotFocused' = '1'
    'game/eventlogkeep' = '1'
    'Console/LOG' = '1'
    'Console/LOGTIME' = '1'
    'Console/LOGKEEP' = '1'
    'Console/LOGDEBUG' = '1'
    "$renderSection/TexQual" = '3'
    "$renderSection/TexMipFilter" = '2'
    "$renderSection/HardwareShaders" = $expectedHardwareShaders
    "$renderSection/Forest" = $expectedForest
    "$renderSection/LandGeom" = $expectedLandGeom
    "$renderSection/Water" = '2'
    "$renderSection/Effects" = '1'
    "$renderSection/TypeClouds" = '1'
    'game/Typeclouds' = '1'
}
if ($Windowed1024) {
    $configurationExpectations['window/width'] = '1024'
    $configurationExpectations['window/height'] = '768'
    $configurationExpectations['window/ChangeScreenRes'] = '0'
    $configurationExpectations['window/FullScreen'] = '0'
    # San's IL2 FOV Changer 1.0 requires SaveAspect=0 (bundled manual, page 5).
    $configurationExpectations['window/SaveAspect'] = '0'
    $configurationExpectations['window/WideScreenFoV'] = '0'
    $configurationExpectations['rts/mouseUse'] = '1'
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

$driveRoot = [IO.Path]::GetPathRoot($resolvedRepository)
# Windows PowerShell 5.1 peut retourner Free=$null pour Get-PSDrive dans une
# session non interactive, alors que pwsh renseigne la valeur. DriveInfo donne
# le meme espace disponible dans les deux hotes.
$availableFreeSpace = [IO.DriveInfo]::new($driveRoot).AvailableFreeSpace
$freeGiB = [Math]::Round($availableFreeSpace / 1GB, 2)
Add-Check -Name 'Espace libre pour les traces' -Passed ($availableFreeSpace -ge 10GB) -Detail "$freeGiB Gio libres"

$report = [ordered]@{
    generated_utc = [DateTime]::UtcNow.ToString('O')
    game_root = $resolvedGame
    reference_root = $resolvedReference
    repository_root = $resolvedRepository
    profile = $profileLabel
    graphics_provider = $glProvider
    render_section = $renderSection
    content_scope = if ($ExcludeNuclear) { 'v1.15-excluding-v1.20-nuclear-content' } else { 'complete-historical-validator' }
    allowed_content_failures = @($AllowedContentFailures)
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
