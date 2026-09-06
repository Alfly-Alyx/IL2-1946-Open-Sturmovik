[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$DumpRoot,
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (-not $DumpRoot) {
    $airManifest = Join-Path $root 'manifests\aircraft\air-ini-static-v1.15.json'
    if (-not (Test-Path -LiteralPath $airManifest -PathType Leaf)) {
        throw "DumpRoot absent et manifeste avion introuvable : $airManifest"
    }
    $DumpRoot = [string](Get-Content -Raw -LiteralPath $airManifest | ConvertFrom-Json).selector_dump_root
}
$dump = (Resolve-Path -LiteralPath $DumpRoot).Path
if (-not $ReportPath) { $ReportPath = Join-Path $root 'manifests\mods\zuti-mds-1.13-static.json' }

$checks = [Collections.Generic.List[object]]::new()

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory = $true)][string]$Details
    )
    $checks.Add([pscustomobject]@{ name = $Name; status = $Status; details = $Details })
}

function Get-Sha256([string]$Path) {
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-JavaMajor([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 8 -or $bytes[0] -ne 0xCA -or $bytes[1] -ne 0xFE -or
        $bytes[2] -ne 0xBA -or $bytes[3] -ne 0xBE) { return -1 }
    return ($bytes[6] -shl 8) -bor $bytes[7]
}

function Test-BinaryContains([string]$Path, [string]$Needle) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    return [Text.Encoding]::GetEncoding(28591).GetString($bytes).Contains($Needle)
}

$readme = Join-Path $root 'Files\$ReadMe$.txt'
if (-not (Test-Path -LiteralPath $readme -PathType Leaf)) {
    Add-Check 'Version Zuti' FAIL 'Readme Zuti absent.'
}
else {
    $readmeText = [IO.File]::ReadAllText($readme)
    if ($readmeText -match '(?m)^Version:\s*v1\.13\s*$') {
        Add-Check 'Version Zuti' PASS "Le paquet declare exactement v1.13 (SHA-256 $(Get-Sha256 $readme))."
    }
    else { Add-Check 'Version Zuti' FAIL 'Le readme ne declare pas v1.13.' }
}

$zutiClasses = @(Get-ChildItem -LiteralPath $dump -Recurse -File -Filter '*Zuti*.class')
$badMajors = @($zutiClasses | Where-Object { (Get-JavaMajor $_.FullName) -gt 47 -or (Get-JavaMajor $_.FullName) -lt 45 })
$requiredZutiClasses = @(
    'com\maddox\il2\builder\PlMission$WZutiMDS.class',
    'com\maddox\il2\builder\Zuti_WManageAircrafts.class',
    'com\maddox\il2\game\ZutiAirfieldPoint.class',
    'com\maddox\il2\game\ZutiTimer_ExtendPlanesWings.class',
    'com\maddox\il2\game\ZutiTimer_RadarsCountRefresh.class',
    'com\maddox\il2\game\ZutiWeaponsManagement.class',
    'com\maddox\il2\game\order\ZutiOrder_Loadout.class',
    'com\maddox\il2\game\order\ZutiOrder_RearmAircraft.class',
    'com\maddox\il2\game\order\ZutiOrder_RefuelAircraft.class',
    'com\maddox\il2\game\order\ZutiOrder_RepairAircraft.class'
)
$missingZutiClasses = @($requiredZutiClasses | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $dump $_) -PathType Leaf)
})
if ($zutiClasses.Count -ge 30 -and $badMajors.Count -eq 0 -and $missingZutiClasses.Count -eq 0) {
    Add-Check 'Classes Zuti chargees' PASS "$($zutiClasses.Count) classes Zuti presentes dans le Selector Dump, toutes compatibles Java 1.3 (major 45 a 47)."
}
else {
    Add-Check 'Classes Zuti chargees' FAIL "classes=$($zutiClasses.Count), majors invalides=$($badMajors.Count), requises absentes=$($missingZutiClasses -join ', ')."
}

$hookClasses = @(
    'com\maddox\il2\game\Mission.class',
    'com\maddox\il2\game\AircraftHotKeys.class',
    'com\maddox\il2\game\HUD.class',
    'com\maddox\il2\game\order\OrdersTree.class',
    'com\maddox\il2\net\BornPlace.class',
    'com\maddox\il2\net\NetServerParams.class',
    'com\maddox\il2\objects\air\Aircraft.class',
    'com\maddox\il2\objects\air\NetAircraft.class',
    'com\maddox\il2\objects\ships\BigshipGeneric.class',
    'com\maddox\il2\builder\ActorBorn.class',
    'com\maddox\il2\builder\PlMisBorn.class',
    'com\maddox\il2\builder\PlMission.class'
)
$badHooks = [Collections.Generic.List[string]]::new()
foreach ($relative in $hookClasses) {
    $path = Join-Path $dump $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $badHooks.Add("$relative absent")
    }
    elseif (-not (Test-BinaryContains $path 'Zuti')) {
        $badHooks.Add("$relative sans reference Zuti")
    }
}
if ($badHooks.Count -eq 0) {
    Add-Check "Points d'accrochage moteur" PASS "$($hookClasses.Count) classes structurantes chargees referencent Zuti : mission, commandes, reseau, appareil, porte-avions et FMB."
}
else { Add-Check "Points d'accrochage moteur" FAIL ($badHooks -join '; ') }

$patchedTimer = Join-Path $root 'Files\com\maddox\il2\game\ZutiTimer_ExtendPlanesWings.class'
$expectedTimerHash = '70E039E839F092346CF8E4F06BA8431C3FF550237C6888D1BAE7B057E22D12C5'
if ((Test-Path -LiteralPath $patchedTimer -PathType Leaf) -and
    (Get-Sha256 $patchedTimer) -eq $expectedTimerHash -and
    (Get-JavaMajor $patchedTimer) -eq 45) {
    Add-Check 'Correctif ExtendPlanesWings' PASS 'La surcharge corrigeant le cast premature est presente, Java major 45 et empreinte validee.'
}
else { Add-Check 'Correctif ExtendPlanesWings' FAIL 'Surcharge corrigee absente, modifiee ou incompatible.' }

$i18nExpected = [ordered]@{
    'Files\i18n\bld_ru.properties' = 169
    'Files\i18n\hud_log_ru.properties' = 36
    'Files\i18n\hud_order_ru.properties' = 12
}
$badI18n = [Collections.Generic.List[string]]::new()
foreach ($entry in $i18nExpected.GetEnumerator()) {
    $path = Join-Path $root $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $badI18n.Add("$($entry.Key) absent")
        continue
    }
    $count = (Select-String -LiteralPath $path -Pattern '(?i)zuti|mds').Count
    if ($count -lt $entry.Value) { $badI18n.Add("$($entry.Key): $count < $($entry.Value)") }
}
if ($badI18n.Count -eq 0) {
    Add-Check 'Textes interface MDS' PASS 'Les 169/36/12 entrees attendues sont presentes dans les trois catalogues historiques.'
}
else { Add-Check 'Textes interface MDS' FAIL ($badI18n -join '; ') }

$sampleNames = @(
    'MDS_Capturing_RedBlue.mis',
    'MDS_Capturing_RedBlueGreen_DF.mis',
    'MDS_Capturing_RedBlueGreen_Coop.mis',
    'MDS_Capturing_RedBlueGreen_Single.mis'
)
$badSamples = [Collections.Generic.List[string]]::new()
foreach ($name in $sampleNames) {
    $path = Join-Path $root "Files\Sample Missions\$name"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $badSamples.Add("$name absent")
        continue
    }
    $text = [IO.File]::ReadAllText($path)
    foreach ($needle in @('[MDS]', 'ZutiRadar_', 'ZutiReload_', '[BornPlace]')) {
        if (-not $text.Contains($needle)) { $badSamples.Add("$name sans $needle") }
    }
}
if ($badSamples.Count -eq 0) {
    Add-Check 'Missions exemples MDS' PASS 'Les quatre missions solo/coop/dogfight contiennent MDS, radar, R/R/R et bases.'
}
else { Add-Check 'Missions exemples MDS' FAIL ($badSamples -join '; ') }

$tools = [ordered]@{
    'Files\Tools\AirportsExtractor\ZutiAirportsExtractor.jar' = '792CB85DE0974A9F0480B468C191DD8D847E4E1B96692EAEFF18F1AB676E5C07'
    'Files\Tools\Mods_Conflicts_Revealer\IL2_ModsConflictsRevealer.jar' = '8DF69D26BF02491155685F6EC958C3C20407CCEA3E4DF18F56EB28F1725D2F90'
}
$badTools = @($tools.GetEnumerator() | Where-Object {
    $path = Join-Path $root $_.Key
    -not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Sha256 $path) -ne $_.Value
})
if ($badTools.Count -eq 0) { Add-Check 'Outils Zuti' PASS 'AirportsExtractor et Mods Conflicts Revealer correspondent aux empreintes inventoriees.' }
else { Add-Check 'Outils Zuti' FAIL 'Un outil Zuti est absent ou a une empreinte inattendue.' }

Add-Check 'Validation fonctionnelle runtime' WARN 'La structure est chargee, mais une mission MDS doit encore valider base capturable, radar, limite appareils, R/R/R, client/serveur et arret propre du minuteur radar.'

$summary = [ordered]@{
    pass = @($checks | Where-Object status -eq 'PASS').Count
    warn = @($checks | Where-Object status -eq 'WARN').Count
    fail = @($checks | Where-Object status -eq 'FAIL').Count
    static_integration = if (@($checks | Where-Object status -eq 'FAIL').Count -eq 0) { 'READY_FOR_RUNTIME_TEST' } else { 'BLOCKED' }
    runtime_validated = $false
}
$payload = [ordered]@{
    schema = 1
    generated_utc = [DateTime]::UtcNow.ToString('o')
    project_root = $root
    selector_dump_root = $dump
    target = 'IL-2 1946 4.09m / Zuti MDS v1.13 STD'
    summary = $summary
    checks = @($checks)
    zuti_dump_classes = @($zutiClasses | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            path = $_.FullName
            bytes = $_.Length
            java_major = Get-JavaMajor $_.FullName
            sha256 = Get-Sha256 $_.FullName
        }
    })
}
$reportParent = Split-Path -Parent $ReportPath
if ($reportParent) { New-Item -ItemType Directory -Force -Path $reportParent | Out-Null }
$payload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportPath -Encoding utf8
$checks | Format-Table -AutoSize
"Summary: PASS=$($summary.pass) WARN=$($summary.warn) FAIL=$($summary.fail) - $($summary.static_integration)"
if ($summary.fail -gt 0) { exit 1 }
