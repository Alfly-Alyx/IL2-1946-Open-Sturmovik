[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$ContentRoot,
    [string]$DumpRoot,
    [string]$ReportPath,
    [switch]$ExcludeNuclear
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory = $true)][string]$Details
    )

    $script:Checks.Add([pscustomobject]@{
        Name    = $Name
        Status  = $Status
        Details = $Details
    })
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-NormalizedTextSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    $normalized = (([IO.File]::ReadAllLines($Path) | ForEach-Object { $_.TrimEnd() }) -join "`n").TrimEnd()
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($normalized)
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function Test-SameFile {
    param(
        [Parameter(Mandatory = $true)][string]$ActivePath,
        [Parameter(Mandatory = $true)][string]$ReferencePath,
        [Parameter(Mandatory = $true)][string]$CheckName
    )

    if (-not (Test-Path -LiteralPath $ActivePath -PathType Leaf)) {
        Add-Check $CheckName FAIL "Fichier actif absent : $ActivePath"
        return
    }
    if (-not (Test-Path -LiteralPath $ReferencePath -PathType Leaf)) {
        Add-Check $CheckName FAIL "Fichier de reference absent : $ReferencePath"
        return
    }

    $activeHash = Get-Sha256 $ActivePath
    $referenceHash = Get-Sha256 $ReferencePath
    $activeText = [IO.File]::ReadAllText($ActivePath).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
    $referenceText = [IO.File]::ReadAllText($ReferencePath).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
    if ($activeText -ceq $referenceText) {
        Add-Check $CheckName PASS "Contenu identique a la reference 4.09m (actif=$activeHash, reference=$referenceHash)."
    }
    else {
        Add-Check $CheckName FAIL "Incoherent avec la reference 4.09m : actif=$activeHash, reference=$referenceHash."
    }
}

$defaultProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not $ProjectRoot) { $ProjectRoot = $defaultProjectRoot }
if (-not $ContentRoot) { $ContentRoot = $ProjectRoot }
$specRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$root = (Resolve-Path -LiteralPath $ContentRoot).Path
$airActive = Join-Path $root 'Files\com\maddox\il2\objects\air.ini'
$air409 = Join-Path $specRoot '_Game Switchers\409m air.ini\Air.ini\air.ini'
$stationaryActive = Join-Path $root 'Files\com\maddox\il2\objects\stationary.ini'
$stationary409 = Join-Path $specRoot '_Game Switchers\Stationary\409m\stationary.ini'
$buttons = Join-Path $root 'Files\gui\GAME\buttons'
$chiefActive = Join-Path $root 'Files\com\maddox\il2\objects\chief.ini'
$chiefExtensions = Join-Path $specRoot 'manifests\registries\chief.mod-extensions.ini'
$planeRegistryOverride = Join-Path $root 'Files\2B9A89D62FA5D19A'
$shipRegistryOverride = Join-Path $root 'Files\9AED69FCA28642D0'
$tbm1ClassOverride = Join-Path $root 'Files\7FF44CEAD0A8A81C'

Test-SameFile $airActive $air409 'air.ini actif'
Test-SameFile $stationaryActive $stationary409 'stationary.ini actif'

if ((Test-Path -LiteralPath $buttons -PathType Leaf) -and (Get-Item -LiteralPath $buttons).Length -gt 0) {
    Add-Check 'Buttons' PASS "Present, $((Get-Item -LiteralPath $buttons).Length) octets, SHA-256 $(Get-Sha256 $buttons)."
}
else {
    Add-Check 'Buttons' FAIL "Absent ou vide : $buttons"
}

$aocManifestPath = Join-Path $specRoot 'manifests\aoc-v1.15.json'
$aocProblems = New-Object System.Collections.Generic.List[string]
if (-not (Test-Path -LiteralPath $aocManifestPath -PathType Leaf)) {
    $aocProblems.Add('manifeste AOC v1.15 absent')
}
else {
    $aocManifest = Get-Content -LiteralPath $aocManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($aocManifest.currentSelection -ne 'v1-1a-hsfx4-409m-zuti-merged') {
        $aocProblems.Add("selection inattendue : $($aocManifest.currentSelection)")
    }
    foreach ($entry in @($aocManifest.integration.outputClasses)) {
        $classPath = Join-Path $root ([string]$entry.path)
        if (-not (Test-Path -LiteralPath $classPath -PathType Leaf)) {
            $aocProblems.Add("classe absente : $($entry.path)")
            continue
        }
        $classBytes = [IO.File]::ReadAllBytes($classPath)
        $classMajor = if ($classBytes.Length -ge 8) { ($classBytes[6] -shl 8) -bor $classBytes[7] } else { -1 }
        if ($classBytes.Length -ne [long]$entry.length -or
            (Get-Sha256 $classPath) -ne [string]$entry.sha256 -or
            $classMajor -ne [int]$entry.major -or $classMajor -gt 47) {
            $aocProblems.Add("classe incoherente : $($entry.path)")
        }
    }

    $aocProfileRoot = Join-Path $root ([string]$aocManifest.recoveredPayload.profiles.path)
    $aocProfiles = @(Get-ChildItem -LiteralPath $aocProfileRoot -File -ErrorAction SilentlyContinue)
    $aocProfileBytes = ($aocProfiles | Measure-Object Length -Sum).Sum
    [string[]]$aocProfileNames = @($aocProfiles | ForEach-Object Name)
    [Array]::Sort($aocProfileNames, [StringComparer]::OrdinalIgnoreCase)
    $aocInventory = @()
    foreach ($profileName in $aocProfileNames) {
        $profilePath = Join-Path $aocProfileRoot $profileName
        $aocInventory += ($profileName.ToLowerInvariant() + ' ' + (Get-Sha256 $profilePath).ToLowerInvariant())
    }
    $aocInventoryText = ($aocInventory -join "`n") + "`n"
    $aocSha = [Security.Cryptography.SHA256]::Create()
    try {
        $aocDigestBytes = $aocSha.ComputeHash([Text.Encoding]::UTF8.GetBytes($aocInventoryText))
        $aocDigest = ([BitConverter]::ToString($aocDigestBytes)).Replace('-', '')
    }
    finally {
        $aocSha.Dispose()
    }
    if ($aocProfiles.Count -ne [int]$aocManifest.recoveredPayload.profiles.count -or
        $aocProfileBytes -ne [long]$aocManifest.recoveredPayload.profiles.bytes -or
        $aocDigest -ne [string]$aocManifest.recoveredPayload.profiles.inventoryDigest) {
        $aocProblems.Add("profils incoherents : fichiers=$($aocProfiles.Count), octets=$aocProfileBytes, digest=$aocDigest")
    }
}
$legacyAocFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'Mod_AOC_Public') -File -ErrorAction SilentlyContinue)
if ($legacyAocFiles.Count -ne 0) {
    $aocProblems.Add("ancienne source Mod_AOC_Public encore presente : $($legacyAocFiles.Count) fichier(s)")
}
if ($aocProblems.Count -eq 0) {
    Add-Check 'AOC 1a + Zuti 1.13' PASS 'Trois classes fusionnees et 266 profils distribues verifies ; le Bf-109G-6 Early utilisera Defaut.txt.'
}
else {
    Add-Check 'AOC 1a + Zuti 1.13' FAIL ($aocProblems -join '; ')
}

$expectedChiefHash = '14E9D0CE1C3B991FF3C43D9643F4744439126F690B3E294BA27EF1B18786AD8D'
$expectedChiefExtensionsHash = 'E56FE7B7FDF6A4C44EA9DF25A1B9D0D023A192F5D763C925714D06C545CEC22F'
if (-not (Test-Path -LiteralPath $chiefActive -PathType Leaf)) {
    Add-Check 'chief.ini fusionne' FAIL 'Registre actif absent.'
}
elseif (-not (Test-Path -LiteralPath $chiefExtensions -PathType Leaf)) {
    Add-Check 'chief.ini fusionne' FAIL 'Source des extensions communautaires absente.'
}
else {
    $chiefSections = @([IO.File]::ReadAllLines($chiefActive) | ForEach-Object {
        if ($_ -match '^\s*\[([^]]+)\]\s*$') { $Matches[1] }
    })
    $uniqueChiefSections = @($chiefSections | Sort-Object -Unique)
    $requiredChiefSections = @(
        'Ships.USSEssexCV9', 'Ships.IJNAkagiCV', 'Ships.IJNKageroDD41',
        'Ships.IJNAkizukiDD42', 'Ships.USSIndianapolisCA35', 'Ships.USSFletcherDD445',
        'ShipPack.Tanker0', 'Armor.1-HotchkissH35'
    )
    $missingChiefSections = @($requiredChiefSections | Where-Object { $_ -notin $uniqueChiefSections })
    if ((Get-Sha256 $chiefActive) -eq $expectedChiefHash -and
        (Get-Sha256 $chiefExtensions) -eq $expectedChiefExtensionsHash -and
        $chiefSections.Count -eq 504 -and $uniqueChiefSections.Count -eq 504 -and
        $missingChiefSections.Count -eq 0) {
        Add-Check 'chief.ini fusionne' PASS '426 sections officielles 4.09m et 78 sections communautaires fusionnees sans doublon ; les six navires sont enregistres.'
    }
    else {
        Add-Check 'chief.ini fusionne' FAIL ("Fusion inattendue : sections={0}, uniques={1}, absentes={2}, SHA actif={3}, SHA extensions={4}." -f $chiefSections.Count, $uniqueChiefSections.Count, ($missingChiefSections -join ','), (Get-Sha256 $chiefActive), (Get-Sha256 $chiefExtensions))
    }
}

$expectedPlaneRegistryHash = 'FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059'
if (-not (Test-Path -LiteralPath $planeRegistryOverride -PathType Leaf)) {
    Add-Check 'Registre Plane.class fusionne' FAIL 'Surcharge empreintee 2B9A89D62FA5D19A absente.'
}
else {
    $planeRegistryBytes = [IO.File]::ReadAllBytes($planeRegistryOverride)
    $planeMajor = if ($planeRegistryBytes.Length -ge 8) { ($planeRegistryBytes[6] -shl 8) -bor $planeRegistryBytes[7] } else { -1 }
    if ((Get-Sha256 $planeRegistryOverride) -eq $expectedPlaneRegistryHash -and $planeMajor -eq 47) {
        Add-Check 'Registre Plane.class fusionne' PASS 'Les 343 SPAWN sont reunis dans une classe Java major 47 validee en laboratoire.'
    }
    else {
        Add-Check 'Registre Plane.class fusionne' FAIL "Empreinte ou version Java inattendue : SHA=$(Get-Sha256 $planeRegistryOverride), major=$planeMajor."
    }
}

$planeLabels = Join-Path $root 'Files\i18n\plane_ru.properties'
$airLines = if (Test-Path -LiteralPath $airActive -PathType Leaf) { @([IO.File]::ReadAllLines($airActive)) } else { @() }
$kb29Registrations = @($airLines | Where-Object { $_ -match '^\s*KB_29P\s+air\.KB_29P\s+' })
$cw21Registrations = @($airLines | Where-Object { $_ -match '^\s*CW-21\s+air\.CW_21\s+' })
$planeRegistryText = if (Test-Path -LiteralPath $planeRegistryOverride -PathType Leaf) {
    [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($planeRegistryOverride))
}
else { '' }
$planeLabelText = if (Test-Path -LiteralPath $planeLabels -PathType Leaf) {
    [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($planeLabels))
}
else { '' }
$cw21LabelPresent = $planeLabelText -match '(?m)^CW-21\s+Curtiss-Wright CW-21\s*$'
$cw21StaticSpawnerPresent = $planeRegistryText.Contains('com.maddox.il2.objects.vehicles.planes.Plane$CW_21')
if ($kb29Registrations.Count -eq 1 -and
    $cw21Registrations.Count -eq 1 -and
    $cw21LabelPresent -and
    $cw21StaticSpawnerPresent) {
    Add-Check 'Registres KB-29P / CW-21' PASS 'air.ini contient une entree unique par appareil ; le CW-21 a son spawner statique et le libelle Curtiss-Wright attendu.'
}
else {
    Add-Check 'Registres KB-29P / CW-21' FAIL ("KB-29P={0}, CW-21={1}, spawner CW-21={2}, libelle CW-21={3}." -f $kb29Registrations.Count, $cw21Registrations.Count, $cw21StaticSpawnerPresent, $cw21LabelPresent)
}

$kb29pManifestPath = Join-Path $specRoot 'manifests\aircraft\kb29p-qmb-v1.15.json'
$kb29pCockpitClass = Join-Path $root 'Files\2083079EF880398E'
if (-not (Test-Path -LiteralPath $kb29pManifestPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $kb29pCockpitClass -PathType Leaf)) {
    Add-Check 'KB-29P pilotable en Mission rapide' FAIL 'Manifeste ou surcharge KB-29P absente.'
}
else {
    $kb29pManifest = Get-Content -LiteralPath $kb29pManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $kb29pBytes = [IO.File]::ReadAllBytes($kb29pCockpitClass)
    $kb29pMajor = if ($kb29pBytes.Length -ge 8) { ($kb29pBytes[6] -shl 8) -bor $kb29pBytes[7] } else { -1 }
    $kb29pText = [Text.Encoding]::GetEncoding(28591).GetString($kb29pBytes)
    if ((Get-Sha256 $kb29pCockpitClass) -eq [string]$kb29pManifest.patchedClass.sha256 -and
        $kb29pMajor -eq 47 -and
        $kb29pText.Contains('cockpitClass') -and
        $kb29pText.Contains('com.maddox.il2.objects.air.CockpitB29') -and
        @($kb29pManifest.patchedClass.cockpitClasses).Count -eq 1 -and
        -not (Test-Path -LiteralPath (Join-Path $root 'Files\com\maddox\il2\objects\air\KB_29P.class'))) {
        Add-Check 'KB-29P pilotable en Mission rapide' PASS 'La surcharge Java 4.09m declare uniquement le cockpit pilote B-29, avec le meme FMD B-29 que le ravitailleur.'
    }
    else {
        Add-Check 'KB-29P pilotable en Mission rapide' FAIL "Empreinte, version Java ou declaration de cockpit incoherente : SHA=$(Get-Sha256 $kb29pCockpitClass), major=$kb29pMajor."
    }
}

$cwManifestPath = Join-Path $specRoot 'manifests\aircraft\cw21-cockpit-v1.15.json'
$cwErrors = New-Object System.Collections.Generic.List[string]
if (-not (Test-Path -LiteralPath $cwManifestPath)) {
    $cwErrors.Add('Manifeste cockpit absent')
} else {
    $cwManifest = Get-Content -LiteralPath $cwManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($entry in $cwManifest.activeFiles) {
        $cwPath = Join-Path $root $entry.path
        if (-not (Test-Path -LiteralPath $cwPath) -or (Get-Sha256 $cwPath) -ne $entry.sha256) {
            $cwErrors.Add($entry.path)
        }
    }
    if (-not $cwManifest.staticPassed -or @($cwManifest.activeFiles).Count -ne 171) {
        $cwErrors.Add('Inventaire ou audit 4.09m invalide')
    }
    $cwHelper = @($cwManifest.activeFiles | Where-Object { $_.path -eq $cwManifest.uniqueListHelper.path })
    if ($cwManifest.uniqueListHelper.class -ne 'com.maddox.il2.objects.air.OpenSturmovikCW21LoadoutList' -or
        $cwHelper.Count -ne 1 -or $cwHelper[0].sha256 -ne $cwManifest.uniqueListHelper.sha256) {
        $cwErrors.Add('Classe de liste anti-doublons CW-21 absente ou incoherente')
    }
    $cwWeapons = [IO.File]::ReadAllText((Join-Path $root 'Files\i18n\weapons_ru.properties'))
    foreach ($key in @('CW-21.default','CW-21.2x303_2x50','CW-21.none')) {
        if ([regex]::Matches($cwWeapons, '(?m)^' + [regex]::Escape($key) + '\s+').Count -ne 1) {
            $cwErrors.Add("Libelle absent ou duplique : $key")
        }
    }
}
if ($cwErrors.Count -eq 0) {
    Add-Check 'Cockpit et deux armements CW-21' PASS 'Six classes dont la liste anti-doublons, 165 ressources et les libelles d armement correspondent au candidat 4.09m ; essai en jeu requis.'
} else {
    Add-Check 'Cockpit et deux armements CW-21' FAIL ($cwErrors -join '; ')
}

$aaaRestoreManifestPath = Join-Path $specRoot 'manifests\aircraft\aaa-community-cockpits-v1.15.json'
$aaaRestoreProblems = New-Object System.Collections.Generic.List[string]
$aaaRestoreExpected = New-Object System.Collections.Generic.List[object]
if (-not (Test-Path -LiteralPath $aaaRestoreManifestPath -PathType Leaf)) {
    $aaaRestoreProblems.Add('manifeste AAA absent')
}
else {
    try {
        $aaaRestoreManifest = Get-Content -LiteralPath $aaaRestoreManifestPath -Raw | ConvertFrom-Json
        foreach ($packageName in @('TBF-1C', 'TBM-3', 'SU_2')) {
            $property = $aaaRestoreManifest.candidate_packages.PSObject.Properties[$packageName]
            if ($null -eq $property) {
                $aaaRestoreProblems.Add("paquet $packageName absent du manifeste")
                continue
            }
            $package = $property.Value
            foreach ($class in @($package.classes)) {
                $aaaRestoreExpected.Add([pscustomobject]@{
                    Path = 'Files/' + [IO.Path]::GetFileName([string]$class.source)
                    Sha256 = [string]$class.sha256
                    Kind = 'class'
                })
            }
            foreach ($resource in @($package.resources)) {
                $aaaRestoreExpected.Add([pscustomobject]@{
                    Path = 'Files/' + ([string]$resource.relative_path).TrimStart('/')
                    Sha256 = [string]$resource.sha256
                    Kind = 'resource'
                })
            }
        }
        $acesProperty = $aaaRestoreManifest.candidate_packages.PSObject.Properties['ACES']
        if ($null -eq $acesProperty) {
            $aaaRestoreProblems.Add('paquet ACES absent du manifeste')
        }
        else {
            $migClasses = @($acesProperty.Value.classes | Where-Object internal_class -eq 'com/maddox/il2/objects/air/MIG_3POKRYSHKIN')
            if ($migClasses.Count -ne 1) {
                $aaaRestoreProblems.Add("classe MIG_3POKRYSHKIN ambigue ou absente : $($migClasses.Count)")
            }
            else {
                $aaaRestoreExpected.Add([pscustomobject]@{
                    Path = 'Files/' + [IO.Path]::GetFileName([string]$migClasses[0].source)
                    Sha256 = [string]$migClasses[0].sha256
                    Kind = 'class'
                })
            }
        }
    }
    catch {
        $aaaRestoreProblems.Add("manifeste AAA illisible : $($_.Exception.Message)")
    }
}

$duplicateAaaRestorePaths = @($aaaRestoreExpected | Group-Object Path | Where-Object Count -gt 1)
if ($duplicateAaaRestorePaths.Count -ne 0) {
    $aaaRestoreProblems.Add("cibles dupliquees : $($duplicateAaaRestorePaths.Name -join ', ')")
}
if ($aaaRestoreExpected.Count -ne 37) {
    $aaaRestoreProblems.Add("payload incomplet : $($aaaRestoreExpected.Count) fichiers au lieu de 37")
}
foreach ($expected in $aaaRestoreExpected) {
    $target = Join-Path $root ([string]$expected.Path).Replace('/', '\')
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $aaaRestoreProblems.Add("$($expected.Path) absent")
        continue
    }
    if ((Get-Sha256 $target) -ne [string]$expected.Sha256) {
        $aaaRestoreProblems.Add("$($expected.Path) empreinte inattendue")
        continue
    }
    if ([string]$expected.Kind -eq 'class') {
        $bytes = [IO.File]::ReadAllBytes($target)
        $major = if ($bytes.Length -ge 8) { ($bytes[6] -shl 8) -bor $bytes[7] } else { -1 }
        if ($major -ne 47) {
            $aaaRestoreProblems.Add("$($expected.Path) Java major $major au lieu de 47")
        }
    }
}
if ($aaaRestoreProblems.Count -eq 0) {
    Add-Check 'Appareils AAA restaures' PASS 'Les 37 classes et ressources de TBF-1C, TBM-3, Su-2 et Pokryshkins MiG-3 correspondent au manifeste et les classes sont en Java major 47.'
}
else {
    Add-Check 'Appareils AAA restaures' FAIL ($aaaRestoreProblems -join '; ')
}

$wheelTire = Join-Path $root 'Files\3do\Plane\Bf-109G-2\WheelTire.mat'
if (-not (Test-Path -LiteralPath $wheelTire -PathType Leaf)) {
    Add-Check 'Bf-109G-2 WheelTire.mat' FAIL 'Fichier absent.'
}
else {
    $wheelBytes = [IO.File]::ReadAllBytes($wheelTire)
    $nonZero = @($wheelBytes | Where-Object { $_ -ne 0 }).Count
    $wheelText = [Text.Encoding]::ASCII.GetString($wheelBytes)
    if ($nonZero -gt 0 -and $wheelText.Contains('ClassName TMaterial') -and $wheelText.Contains('../TEXTURES/wheels.tga')) {
        Add-Check 'Bf-109G-2 WheelTire.mat' PASS "Materiau lisible, $($wheelBytes.Length) octets, SHA-256 $(Get-Sha256 $wheelTire)."
    }
    else {
        Add-Check 'Bf-109G-2 WheelTire.mat' FAIL 'Materiau absent, nul ou incomplet.'
    }
}

$zutiClass = Join-Path $root 'Files\com\maddox\il2\game\ZutiTimer_ExtendPlanesWings.class'
$expectedZutiHash = '70E039E839F092346CF8E4F06BA8431C3FF550237C6888D1BAE7B057E22D12C5'
if (-not (Test-Path -LiteralPath $zutiClass -PathType Leaf)) {
    Add-Check 'Correctif ZutiTimer_ExtendPlanesWings' FAIL 'Classe libre corrigee absente.'
}
elseif ((Get-Sha256 $zutiClass) -eq $expectedZutiHash) {
    Add-Check 'Correctif ZutiTimer_ExtendPlanesWings' PASS "Correctif binaire attendu present ($expectedZutiHash)."
}
else {
    Add-Check 'Correctif ZutiTimer_ExtendPlanesWings' FAIL "Empreinte inattendue : $(Get-Sha256 $zutiClass)."
}

if (-not $ExcludeNuclear) {
    $nuclearManifestPath = Join-Path $specRoot 'manifests\effects\nuclear-blast-v1.15.json'
    $b29SilverplateClass = Join-Path $root 'Files\7BCE3C02C280ED18'
    $b29SilverplateMesh = Join-Path $root 'Files\3do\Cockpit\B-29-SP\CockpitB29SP.him'
    $expectedB29SilverplateHash = '0A83344F9617AECF9F2B0B50B06B265E7C41F2A733B226DA32656465AF994992'
    if (-not (Test-Path -LiteralPath $b29SilverplateClass -PathType Leaf) -or
        -not (Test-Path -LiteralPath $b29SilverplateMesh -PathType Leaf)) {
        Add-Check 'Cockpit pilote B-29 Silverplate' FAIL 'Classe ou maillage Silverplate absent.'
    }
    else {
        $b29Text = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($b29SilverplateClass))
        $meshText = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($b29SilverplateMesh))
        $requiredChunks = @('zOilFlap1', 'zOilFlap2', 'zCompressor1', 'zCompressor2')
        $missingChunks = @($requiredChunks | Where-Object { -not $meshText.Contains($_) })
        $usesSilverplate = $b29Text.Contains('com.maddox.il2.objects.air.CockpitB29SP')
        $usesOldPilot = [regex]::IsMatch($b29Text, 'com\.maddox\.il2\.objects\.air\.CockpitB29(?!SP)')
        if ((Get-Sha256 $b29SilverplateClass) -eq $expectedB29SilverplateHash -and
            $usesSilverplate -and -not $usesOldPilot -and $missingChunks.Count -eq 0) {
            Add-Check 'Cockpit pilote B-29 Silverplate' PASS 'La variante Silverplate appelle CockpitB29SP et son maillage contient les quatre morceaux auparavant absents.'
        }
        else {
            Add-Check 'Cockpit pilote B-29 Silverplate' FAIL "empreinte=$((Get-Sha256 $b29SilverplateClass)); Silverplate=$usesSilverplate; ancien=$usesOldPilot; morceaux_absents=$($missingChunks -join ',')"
        }
    }
    $expectedNuclearClasses = [ordered]@{
    '72DCDDF4D2AD25E8' = '24CCB92F1AD8BCAD777CAF03B9357CD7756E3E1248986A2C3B7FD317DDD2CF9A'
    '303F5874196BEABE' = 'D4661E8594D24435C24747FBFBD0ADFCD972317E48075C528A1FCC67D9D61685'
    '809E3320DB37687A' = '0576626EBA5B0DD233BDFEE22967E43A37DA52564B1166F9D4BDF20FEAC4AFBE'
    '3F43760A72781132' = 'FAEAEFAA3D57ECF615912BB46FD19259E923D8C8AEA23862BB652A7248C2C6BE'
    '830E5C5AC3A1C77A' = '94ABC0A426CAF8E300FC995FE4D23ACCC164F88406D9314BC2A712C7E088E428'
    '5AC49B8080496790' = 'FF2F2698D31EC53119CC7A76BA6CBD084C636F0A3793A9FC29D3A149C2F25FD5'
    '761B02162C6E5D04' = '15BB56B33EB48A835700B623B21B04856D2F81DA4F08DB6C6BC8408A9F097F4C'
    '709FB7A0C816C8B2' = 'BFBF4A805BDDC4FA186065333139A645316392E1A5345BD3C1A8AC7FF0837D1F'
    '6482BE08C086B0BA' = '5FC39F58A4A924905BF7C924918E906E318AC74E4EFE981BD99BC138CCE6D25F'
    '145128EC449ADBDA' = '05B45025FB3E1E09BA1BCC24E6D6FC0AC070481F1EC1689CFCC7D60143B43D66'
    '8D53953C1956F06A' = '49F04044ED71EC2966A1CE912A5C64BA8FB3D5120E0B4B4FC30299F681CCABC0'
    '51AD1FEC90031C8A' = '68E05AB18BA693EF0B2AC48D95D0D251434D36376937A568264045C9ACF05CE9'
    'ABFC6F18761EB542' = 'A80BD5673F14A795CFF6DFBC65372C73C80700BD5AEAB215506ED42F1F1E307B'
    }
    $expectedNuclearVisuals = [ordered]@{
    'Files/3do/Effects/Fireworks/FatMan(buff).eff' = '2065B731EB3EE3BB12388CC56584686F17CD9151F7CD4C6D7368746BD84CD2BA'
    'Files/3do/Effects/Fireworks/FatMan(circle).eff' = 'B18FCFB0B0107B10196BA6B370D8C12A95311551E3A1D8BB7478593F5CE56BB4'
    'Files/3do/Effects/Fireworks/FatMan(circleL).eff' = '3674DDFD5B25B369E09FD27B689CE42F02AED44F7ED81F5C84AE972029556D6B'
    'Files/3do/Effects/Fireworks/FatMan(column).eff' = 'BB9E2292D82562ABFE7C3FE6DC7BB07E999FE9EA88973D832B14074CDD5E09D4'
    'Files/3do/Effects/Fireworks/FatMan(flare).eff' = 'EE46469205665B504577D637B604475AFEECDF6DA1A22E4CF097D30BC23EEE37'
    'Files/3do/Effects/Fireworks/FatMan(ring).eff' = '1E60279ED5E9834EF23A28711CF4EA7C19A2237F865DB5C24552FD514B53A936'
    'Files/3do/Effects/Fireworks/FatMan(shock).eff' = 'B02B7C38413EC34244E868C2D0290F35997B83E0AC23957DAC81A96AA79B5A00'
    'Files/3do/Effects/Fireworks/FatMan(rise-head).eff' = 'AF4B25448C25D85F78E3E493427A6E734AA85F14AEBE401EDBF7AD6EBE1E9217'
    'Files/3do/Effects/Fireworks/FatMan(rise-torus).eff' = 'D5A25A90A7DCDC37B5B5C308B86A69EC0A63837416F1B9EC153D1F55263C0346'
    'Files/3do/Effects/Fireworks/FatMan(stabilized).eff' = '7100A469125EED848C07B0F3AEA7AB238ED7584FF00DE20CBD9BE074E1AB91D7'
    }
    $badNuclearClasses = New-Object System.Collections.Generic.List[string]
    $nuclearManifest = $null
    if (-not (Test-Path -LiteralPath $nuclearManifestPath -PathType Leaf)) {
        $badNuclearClasses.Add('manifeste absent')
    }
    else {
        try {
            $nuclearManifest = Get-Content -LiteralPath $nuclearManifestPath -Raw | ConvertFrom-Json
        }
        catch {
            $badNuclearClasses.Add("manifeste illisible : $($_.Exception.Message)")
        }
    }
    foreach ($entry in $expectedNuclearClasses.GetEnumerator()) {
        $path = Join-Path $root "Files\$($entry.Key)"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $badNuclearClasses.Add("$($entry.Key) absent")
            continue
        }
        $bytes = [IO.File]::ReadAllBytes($path)
        $major = if ($bytes.Length -ge 8) { ($bytes[6] -shl 8) -bor $bytes[7] } else { -1 }
        if ((Get-Sha256 $path) -ne $entry.Value -or $major -ne 47) {
            $badNuclearClasses.Add("$($entry.Key) empreinte/version inattendue")
        }
    }
    foreach ($entry in $expectedNuclearVisuals.GetEnumerator()) {
        $path = Join-Path $root $entry.Key.Replace('/', '\')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $badNuclearClasses.Add("$($entry.Key) absent")
        }
        elseif ((Get-Sha256 $path) -ne $entry.Value) {
            $badNuclearClasses.Add("$($entry.Key) empreinte inattendue")
        }
    }
    if ($null -ne $nuclearManifest) {
        $manifestOutputs = @($nuclearManifest.outputs)
        foreach ($entry in $expectedNuclearClasses.GetEnumerator()) {
            $manifestEntry = @($manifestOutputs | Where-Object { [IO.Path]::GetFileName([string]$_.file) -eq $entry.Key })
            if ($manifestEntry.Count -ne 1 -or [string]$manifestEntry[0].sha256 -ne $entry.Value) {
                $badNuclearClasses.Add("$($entry.Key) incoherent avec le manifeste")
            }
        }
        $manifestVisuals = @($nuclearManifest.visual_outputs)
        foreach ($entry in $expectedNuclearVisuals.GetEnumerator()) {
            $manifestEntry = @($manifestVisuals | Where-Object { [string]$_.file -eq $entry.Key })
            if ($manifestEntry.Count -ne 1 -or [string]$manifestEntry[0].sha256 -ne $entry.Value) {
                $badNuclearClasses.Add("$($entry.Key) incoherent avec le manifeste")
            }
        }
        if ($nuclearManifest.model.little_boy.yield_kt -ne 15 -or
            $nuclearManifest.model.little_boy.airburst_m_agl -ne 600 -or
            $nuclearManifest.model.fat_man.yield_kt -ne 21 -or
            $nuclearManifest.model.fat_man.airburst_m_agl -ne 503 -or
            [string]$nuclearManifest.model.visual_lifecycle.clock -notmatch 'simulation time only' -or
            $nuclearManifest.model.visual_lifecycle.cleanup_deadline_s -ne 3728 -or
            $nuclearManifest.model.visual_lifecycle.transient_drain_end_s -ne 130 -or
            $nuclearManifest.model.visual_lifecycle.rise_drain_end_s -ne 728 -or
            $nuclearManifest.model.visual_lifecycle.stabilized_particle_drain_end_s -ne 3718 -or
            $nuclearManifest.model.cloud_summit.little_boy_m -ne 12000 -or
            $nuclearManifest.model.cloud_summit.fat_man_m -ne 13500 -or
            [string]$nuclearManifest.model.persistent_visual_state.replacement -notmatch 'real-time clock.*removed' -or
            $nuclearManifest.validation.runtime_test_required -ne $true) {
            $badNuclearClasses.Add('parametres historiques ou statut de validation inattendus')
        }
    }
    if ($badNuclearClasses.Count -eq 0) {
        Add-Check 'Souffle nucleaire Little Boy / Fat Man' PASS 'Les treize classes Java 1.3 et les dix effets correspondent au manifeste v1.15 : 15/21 kt, airbursts 600/503 m, souffle differe, couches fixes bornees et nettoyage a 3728 s. Ce controle est statique.'
    }
    else {
        Add-Check 'Souffle nucleaire Little Boy / Fat Man' FAIL ($badNuclearClasses -join '; ')
    }
    if ($null -ne $nuclearManifest -and [string]$nuclearManifest.status -eq 'phased_visual_candidate_offline_validated_runtime_pending') {
        Add-Check 'Validation visuelle nucleaire' WARN 'Le cycle chevauche et borne passe les controles hors jeu ; pause/reprise, demi-tour, eau, acceleration temporelle et nettoyage final doivent encore etre valides dans IL-2.'
    }
}

$expectedTbm1Hash = 'BFAC0C3D60CB49DB6D857362196B79305E9D4AE5665E06146E8C30D374374C6B'
if (-not (Test-Path -LiteralPath $tbm1ClassOverride -PathType Leaf)) {
    Add-Check 'Chemin de maillage TBM-1' FAIL 'Surcharge empreintee 7FF44CEAD0A8A81C absente.'
}
else {
    $tbm1Bytes = [IO.File]::ReadAllBytes($tbm1ClassOverride)
    $tbm1Major = if ($tbm1Bytes.Length -ge 8) { ($tbm1Bytes[6] -shl 8) -bor $tbm1Bytes[7] } else { -1 }
    $tbm1Text = [Text.Encoding]::GetEncoding(28591).GetString($tbm1Bytes)
    $oldMeshPaths = @('3DO/Plane/TBF-1(Multi1)/TBM1.him', '3DO/Plane/TBF-1(USA)/TBM1.him')
    $newMeshPaths = @('3DO/Plane/TBF-1(Multi1)/hier.him', '3DO/Plane/TBF-1(USA)/hier.him')
    $oldMeshPresent = @($oldMeshPaths | Where-Object { $tbm1Text.Contains($_) }).Count -gt 0
    $newMeshMissing = @($newMeshPaths | Where-Object { -not $tbm1Text.Contains($_) }).Count -gt 0
    if ((Get-Sha256 $tbm1ClassOverride) -eq $expectedTbm1Hash -and
        $tbm1Major -eq 47 -and
        -not $oldMeshPresent -and
        -not $newMeshMissing) {
        Add-Check 'Chemin de maillage TBM-1' PASS 'La classe Java 1.3 utilise les hier.him disponibles pour ses maillages Multi1 et USA.'
    }
    else {
        Add-Check 'Chemin de maillage TBM-1' FAIL "Correction inattendue : SHA=$(Get-Sha256 $tbm1ClassOverride), major=$tbm1Major."
    }
}

$slovakiaLoad = Join-Path $root 'Files\Maps\Slovakia\load.ini'
if (-not (Test-Path -LiteralPath $slovakiaLoad -PathType Leaf)) {
    Add-Check 'Objets statiques Slovakia 4.09m' FAIL 'Surcharge load.ini absente.'
}
else {
    $slovakiaLines = [IO.File]::ReadAllLines($slovakiaLoad)
    $staticIndex = [Array]::IndexOf($slovakiaLines, '[static]')
    $staticResource = if ($staticIndex -ge 0 -and $staticIndex + 1 -lt $slovakiaLines.Length) {
        $slovakiaLines[$staticIndex + 1].Trim()
    } else { '' }
    if ($staticResource -ceq 'actors_summer.static') {
        Add-Check 'Objets statiques Slovakia 4.09m' PASS 'load.ini demande actors_summer.static, ressource officielle presente dans fb_maps15.SFS.'
    }
    else {
        Add-Check 'Objets statiques Slovakia 4.09m' FAIL "Ressource [static] inattendue : $staticResource."
    }
}

$presetRoot = Join-Path $root 'Files\presets'
$soundPresetRoot = Join-Path $presetRoot 'sounds'
$topPresetNames = @(Get-ChildItem -LiteralPath $presetRoot -File -Filter '*.prs' | ForEach-Object { $_.Name })
$soundPresetNames = @(Get-ChildItem -LiteralPath $soundPresetRoot -File -Filter '*.prs' | ForEach-Object { $_.Name })
$duplicatePresetNames = @($topPresetNames | Where-Object { $_ -in $soundPresetNames } | Sort-Object -Unique)
if ($duplicatePresetNames.Count -eq 0) {
    Add-Check 'Collisions de presets sonores' PASS 'Aucun nom .prs duplique entre Files\presets et Files\presets\sounds.'
}
else {
    Add-Check 'Collisions de presets sonores' FAIL ("{0} doublon(s) : {1}" -f $duplicatePresetNames.Count, ($duplicatePresetNames -join ', '))
}

$startPresets = @(
    'motor.DB-600_Series.start.begin.prs'
    'motor.DB-600_Series.start.end.prs'
    'motor.Rolls-Royce-Merlin.start.begin.prs'
    'motor.Rolls-Royce-Merlin.start.end.prs'
    'motor.Sabre.start.begin.prs'
    'motor.Sabre.start.end.prs'
    'motor.PrattWhitney_R-2800_Series.start.begin.prs'
    'motor.PrattWhitney_R-2800_Series.start.end.prs'
    'motor.Sakae.start.begin.prs'
    'motor.Sakae.start.end.prs'
)
$badStartPresets = New-Object System.Collections.Generic.List[string]
foreach ($presetName in $startPresets) {
    $path = Join-Path $soundPresetRoot $presetName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $badStartPresets.Add("$presetName absent")
        continue
    }

    $lines = [IO.File]::ReadAllLines($path)
    $hasCommon = @($lines | Where-Object { $_.Trim() -ieq '[common]' }).Count -eq 1
    if (@($lines | Where-Object { $_ -match '^\s*infinite\s+1\s*(;.*)?$' }).Count -gt 0) {
        $badStartPresets.Add("$presetName contient un demarrage en boucle infinie")
    }
    $hasMixer = @($lines | Where-Object { $_.Trim() -match '^type\s+mixer\s*$' }).Count -ge 1
    $samplesIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].Trim() -ieq '[samples]') {
            $samplesIndex = $index
            break
        }
    }
    $sampleNames = New-Object System.Collections.Generic.List[string]
    if ($samplesIndex -ge 0) {
        for ($index = $samplesIndex + 1; $index -lt $lines.Count; $index++) {
            $line = $lines[$index].Trim()
            if ($line.StartsWith('[')) { break }
            if ($line -and -not $line.StartsWith(';')) {
                $sampleNames.Add($line)
            }
        }
    }
    $missingSamples = @($sampleNames | Where-Object {
        -not (Test-Path -LiteralPath (Join-Path $root "Files\Samples\$_") -PathType Leaf)
    })
    if (-not $hasCommon -or -not $hasMixer -or $samplesIndex -lt 0 -or $sampleNames.Count -lt 1) {
        $badStartPresets.Add("$presetName n est pas un preset mixeur complet")
    }
    elseif ($missingSamples.Count -gt 0) {
        $badStartPresets.Add("$presetName reference des WAV absents : $($missingSamples -join ', ')")
    }
}
if ($badStartPresets.Count -eq 0) {
    Add-Check 'Presets de demarrage moteur' PASS 'Les dix presets de demarrage sont complets, sans boucle infinie, et tous leurs WAV sont presents.'
}
else {
    Add-Check 'Presets de demarrage moteur' FAIL ($badStartPresets -join '; ')
}

$audioManifestPath = Join-Path $specRoot 'manifests\audio\tiger33-startup-sounds.json'
$badAudioManifestFiles = New-Object System.Collections.Generic.List[string]
if (-not (Test-Path -LiteralPath $audioManifestPath -PathType Leaf)) {
    $badAudioManifestFiles.Add('manifeste absent')
}
else {
    try {
        $audioManifest = Get-Content -LiteralPath $audioManifestPath -Raw | ConvertFrom-Json
        foreach ($property in $audioManifest.presetSha256.PSObject.Properties) {
            $path = Join-Path $soundPresetRoot $property.Name
            if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
                (Get-Sha256 $path) -ne [string]$property.Value) {
                $badAudioManifestFiles.Add($property.Name)
            }
        }
        foreach ($group in @($audioManifest.extractedSampleSha256, $audioManifest.preservedExistingSamples)) {
            foreach ($property in $group.PSObject.Properties) {
                $path = Join-Path $root "Files\Samples\$($property.Name)"
                if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
                    (Get-Sha256 $path) -ne [string]$property.Value) {
                    $badAudioManifestFiles.Add($property.Name)
                }
            }
        }
    }
    catch {
        $badAudioManifestFiles.Add("manifeste illisible : $($_.Exception.Message)")
    }
}
if ($badAudioManifestFiles.Count -eq 0) {
    Add-Check 'Provenance sons Tiger33' PASS 'Les dix presets adaptes et vingt WAV correspondent au manifeste ; les empreintes des presets sources et les deux WAV Sabre historiques sont conserves.'
}
else {
    Add-Check 'Provenance sons Tiger33' FAIL ($badAudioManifestFiles -join '; ')
}

$obsoleteSampleNames = @('Allison_XX_Starter.wav', 'mg__ffe.wav', 'mg__ffi.wav')
$replacementSampleNames = @('Allison_tb_XX_Starter.wav', 'MG_FFx.wav', 'MG_FF.wav')
$presetFiles = @(Get-ChildItem -LiteralPath $presetRoot -File -Filter '*.prs' -Recurse)
$obsoleteReferences = @()
foreach ($obsoleteName in $obsoleteSampleNames) {
    $obsoleteReferences += @($presetFiles | Select-String -SimpleMatch -Pattern $obsoleteName)
}
$missingReplacements = @($replacementSampleNames | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root "Files\Samples\$_") -PathType Leaf)
})
if ($obsoleteReferences.Count -eq 0 -and $missingReplacements.Count -eq 0) {
    Add-Check 'References WAV corrigees' PASS 'Les trois remplacements WAV cibles sont presents ; la chaine de presets Allison chargee en vol est controlee separement.'
}
else {
    $details = @()
    if ($obsoleteReferences.Count -gt 0) {
        $details += ("{0} ancienne(s) reference(s) subsiste(nt)" -f $obsoleteReferences.Count)
    }
    if ($missingReplacements.Count -gt 0) {
        $details += ("echantillon(s) de remplacement absent(s) : {0}" -f ($missingReplacements -join ', '))
    }
    Add-Check 'References WAV corrigees' FAIL ($details -join '; ')
}

$allisonRuntimePresetNames = @(
    'motor.Allison.start.begin.prs',
    'motor.Allison.start.end.prs',
    'motor.Allison_V1700_series.prs'
)
$missingAllisonRuntimePresets = @($allisonRuntimePresetNames | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $soundPresetRoot $_) -PathType Leaf)
})
$allisonStartPresetNames = @(
    'motor.Allison.start.begin.prs',
    'motor.Allison.start.end.prs',
    'motor.Allison_tb.start.begin.prs',
    'motor.Allison_tb.start.end.prs'
)
$allisonStartSamples = @{
    'motor.Allison.start.begin.prs' = 'Allison_tb_XX_Starter.wav'
    'motor.Allison.start.end.prs' = 'Allison_tb_XX_Startup.wav'
    'motor.Allison_tb.start.begin.prs' = 'Allison_tb_XX_Starter.wav'
    'motor.Allison_tb.start.end.prs' = 'Allison_tb_XX_Startup.wav'
}
$malformedAllisonStartPresets = @()
foreach ($presetName in $allisonStartPresetNames) {
    $path = Join-Path $soundPresetRoot $presetName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $malformedAllisonStartPresets += $presetName
        continue
    }
    $text = Get-Content -LiteralPath $path -Raw
    if (-not $text.Contains('[common]') -or
        -not $text.Contains('[sample.') -or
        -not $text.Contains($allisonStartSamples[$presetName])) {
        $malformedAllisonStartPresets += $presetName
    }
}
$allisonSamples = @(
    'Allison_tb_XX_Starter.wav',
    'Allison_tb_XX_Startup.wav',
    'xallison_1001.wav'
)
$missingAllisonSamples = @($allisonSamples | Where-Object {
    -not (Test-Path -LiteralPath (Join-Path $root "Files\Samples\$_") -PathType Leaf)
})
$allisonSeriesPreset = Join-Path $soundPresetRoot 'motor.Allison_V1700_series.prs'
$allisonBasePreset = Join-Path $soundPresetRoot 'motor.Allison.prs'
$malformedAllisonMixers = @()
foreach ($mixerPath in @($allisonBasePreset, $allisonSeriesPreset)) {
    if (-not (Test-Path -LiteralPath $mixerPath -PathType Leaf)) {
        continue
    }
    $mixerText = Get-Content -LiteralPath $mixerPath -Raw
    if ([regex]::Matches($mixerText, '(?m)^\[sample\.xAllison_1001\.wav\]\r?$').Count -ne 1 -or
        [regex]::Matches($mixerText, '(?m)^\[sample\.Allison_1001\.wav\]\r?$').Count -ne 1) {
        $malformedAllisonMixers += [IO.Path]::GetFileName($mixerPath)
    }
}
$allisonSeriesMismatch = (
    (Test-Path -LiteralPath $allisonSeriesPreset -PathType Leaf) -and
    (Test-Path -LiteralPath $allisonBasePreset -PathType Leaf) -and
    ((Get-Content -LiteralPath $allisonSeriesPreset -Raw).Replace("`r`n", "`n").TrimEnd("`r", "`n")) -ne
        ((Get-Content -LiteralPath $allisonBasePreset -Raw).Replace("`r`n", "`n").TrimEnd("`r", "`n"))
)
$allisonManifestPath = Join-Path $specRoot 'manifests\audio\allison-v1.15.json'
$allisonManifestProblems = New-Object System.Collections.Generic.List[string]
if (-not (Test-Path -LiteralPath $allisonManifestPath -PathType Leaf)) {
    $allisonManifestProblems.Add('manifeste Allison absent')
}
else {
    try {
        $allisonManifest = Get-Content -LiteralPath $allisonManifestPath -Raw | ConvertFrom-Json
        $allisonManifestFiles = @($allisonManifest.files.PSObject.Properties)
        if ($allisonManifest.release -ne '1.15' -or $allisonManifestFiles.Count -ne 9) {
            $allisonManifestProblems.Add('version ou nombre de fichiers inattendu dans le manifeste')
        }
        foreach ($property in $allisonManifestFiles) {
            $manifestFile = Join-Path $root ([string]$property.Name).Replace('/', '\')
            if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) {
                $allisonManifestProblems.Add("$($property.Name) absent")
            }
            elseif ((Get-Sha256 $manifestFile) -ne [string]$property.Value) {
                $allisonManifestProblems.Add("$($property.Name) ne correspond pas au manifeste")
            }
        }
        if ([string]$allisonManifest.source.recoveredSampleSha256 -ne
            '66B2B6E4454F8B8B17F3261DE96146653FE29A227211D78D1D4E35EADAA77DF2') {
            $allisonManifestProblems.Add('provenance de la couche exterieure inattendue')
        }
    }
    catch {
        $allisonManifestProblems.Add("manifeste Allison illisible : $($_.Exception.Message)")
    }
}
if ($missingAllisonRuntimePresets.Count -eq 0 -and
    $malformedAllisonStartPresets.Count -eq 0 -and
    $missingAllisonSamples.Count -eq 0 -and
    $malformedAllisonMixers.Count -eq 0 -and
    -not $allisonSeriesMismatch -and
    $allisonManifestProblems.Count -eq 0) {
    Add-Check 'Chaine sonore Allison en vol' PASS 'Les presets demandes par le moteur, leur repli V-1710 et leurs echantillons de demarrage sont complets.'
}
else {
    $details = @()
    if ($missingAllisonRuntimePresets.Count -gt 0) {
        $details += ('presets runtime absents : ' + ($missingAllisonRuntimePresets -join ', '))
    }
    if ($malformedAllisonStartPresets.Count -gt 0) {
        $details += ('presets de demarrage incomplets : ' + ($malformedAllisonStartPresets -join ', '))
    }
    if ($missingAllisonSamples.Count -gt 0) {
        $details += ('echantillons Allison absents : ' + ($missingAllisonSamples -join ', '))
    }
    if ($malformedAllisonMixers.Count -gt 0) {
        $details += ('couches interieure/exterieure Allison 1001 incoherentes : ' + ($malformedAllisonMixers -join ', '))
    }
    if ($allisonSeriesMismatch) {
        $details += 'le repli motor.Allison_V1700_series ne correspond pas au mixeur Allison valide'
    }
    if ($allisonManifestProblems.Count -gt 0) {
        $details += ($allisonManifestProblems -join ', ')
    }
    Add-Check 'Chaine sonore Allison en vol' FAIL ($details -join '; ')
}

$effectManifestPath = Join-Path $specRoot 'manifests\effects\effect-limit-audit.json'
if (-not (Test-Path -LiteralPath $effectManifestPath -PathType Leaf)) {
    Add-Check 'Limites des effets libres' FAIL 'Manifeste de normalisation absent.'
}
else {
    $effectManifest = Get-Content -LiteralPath $effectManifestPath -Raw | ConvertFrom-Json
    $badEffects = New-Object System.Collections.Generic.List[string]
    $effectGroups = @($effectManifest.changes | Group-Object path)
    foreach ($group in $effectGroups) {
        $effectPath = Join-Path $root ($group.Name.Replace('/', '\'))
        $expectedHash = @($group.Group.after_sha256 | Sort-Object -Unique)
        if (-not (Test-Path -LiteralPath $effectPath -PathType Leaf)) {
            $badEffects.Add("$($group.Name) absent")
        }
        elseif ($expectedHash.Count -ne 1 -or (Get-Sha256 $effectPath) -ne $expectedHash[0]) {
            $badEffects.Add("$($group.Name) modifie apres normalisation")
        }
    }
    if ($effectManifest.mode -eq 'apply' -and
        $effectManifest.scanned_effect_files -eq 298 -and
        $effectManifest.changed_files -eq 168 -and
        $effectManifest.normalized_values -eq 179 -and
        $effectGroups.Count -eq 168 -and
        $badEffects.Count -eq 0) {
        Add-Check 'Limites des effets libres' PASS '179 valeurs dans 168 effets correspondent exactement aux bornes appliquees par le moteur 4.09m.'
    }
    else {
        Add-Check 'Limites des effets libres' FAIL ("Manifeste ou fichiers incoherents : groupes={0}, erreurs={1}." -f $effectGroups.Count, ($badEffects -join '; '))
    }
}

$cloudManifestPath = Join-Path $specRoot 'manifests\effects\clouds-4.09m-v1.15.json'
if (-not (Test-Path -LiteralPath $cloudManifestPath -PathType Leaf)) {
    Add-Check 'Nuages detailles WxTech pour 4.09m' FAIL 'Manifeste de correction des nuages absent.'
}
else {
    $cloudManifest = Get-Content -LiteralPath $cloudManifestPath -Raw | ConvertFrom-Json
    $badCloudFiles = New-Object System.Collections.Generic.List[string]
    foreach ($entry in @($cloudManifest.activeFiles)) {
        $cloudPath = Join-Path $root ([string]$entry.path).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $cloudPath -PathType Leaf)) {
            $badCloudFiles.Add("$($entry.path) absent")
        }
        elseif ((Get-Item -LiteralPath $cloudPath).Length -ne [long]$entry.size -or
                (Get-Sha256 $cloudPath) -ne [string]$entry.sha256) {
            $badCloudFiles.Add("$($entry.path) ne correspond pas au paquet selectionne")
        }
    }
    $retiredCloudPaths = @($cloudManifest.removedLegacyFiles) + @($cloudManifest.removedSuperfluousDuplicate)
    $unexpectedCloudFiles = @($retiredCloudPaths | Where-Object {
        Test-Path -LiteralPath (Join-Path $root ([string]$_).Replace('/', '\')) -PathType Leaf
    })
    if ($cloudManifest.schemaVersion -eq 2 -and
        $cloudManifest.release -eq '1.15' -and
        $cloudManifest.gameVersion -eq '4.09m' -and
        $cloudManifest.selection -eq 'WxTech clouds Jan 2023' -and
        @($cloudManifest.activeFiles).Count -eq 8 -and
        $badCloudFiles.Count -eq 0 -and
        $unexpectedCloudFiles.Count -eq 0) {
        Add-Check 'Nuages detailles WxTech pour 4.09m' PASS 'Paquet cumulus a deux couches 1024x1024 conforme ; anciennes ressources visuelles et copie 3do retirees, sans conclusion sur les autres fonctions Atmosphere.'
    }
    else {
        Add-Check 'Nuages detailles WxTech pour 4.09m' FAIL ("Etat inattendu : fichiers invalides={0}, anciens fichiers presents={1}." -f ($badCloudFiles -join '; '), ($unexpectedCloudFiles -join ', '))
    }
}

$sixDofManifestPath = Join-Path $specRoot 'manifests\profiles-6dof-v1.15.json'
if (-not (Test-Path -LiteralPath $sixDofManifestPath -PathType Leaf)) {
    Add-Check 'Profils avec/sans 6DOF' FAIL 'Manifeste 6DOF absent.'
}
else {
    $sixDofManifest = Get-Content -LiteralPath $sixDofManifestPath -Raw | ConvertFrom-Json
    $badSixDofFiles = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in @($sixDofManifest.currentExecutables.with6DofProfiles)) {
        $profilePath = Join-Path $root ([string]$relativePath).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf) -or
            (Get-Item -LiteralPath $profilePath).Length -ne [long]$sixDofManifest.currentExecutables.size -or
            (Get-Sha256 $profilePath) -ne [string]$sixDofManifest.currentExecutables.with6DofSha256) {
            $badSixDofFiles.Add("profil 6DOF inattendu : $relativePath")
        }
    }
    foreach ($relativePath in @($sixDofManifest.currentExecutables.without6DofProfiles)) {
        $profilePath = Join-Path $root ([string]$relativePath).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf) -or
            (Get-Item -LiteralPath $profilePath).Length -ne [long]$sixDofManifest.currentExecutables.size -or
            (Get-Sha256 $profilePath) -ne [string]$sixDofManifest.currentExecutables.without6DofSha256) {
            $badSixDofFiles.Add("profil sans 6DOF inattendu : $relativePath")
        }
    }
    foreach ($entry in @($sixDofManifest.moduleClasses)) {
        $modulePath = Join-Path $root ([string]$entry.file).Replace('/', '\')
        if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf) -or
            (Get-Sha256 $modulePath) -ne [string]$entry.sha256) {
            $badSixDofFiles.Add("classe 6DOF inattendue : $($entry.file)")
        }
    }
    if ($sixDofManifest.release -eq '1.15' -and
        @($sixDofManifest.currentExecutables.with6DofProfiles).Count -eq 3 -and
        @($sixDofManifest.currentExecutables.without6DofProfiles).Count -eq 3 -and
        @($sixDofManifest.moduleClasses).Count -eq 5 -and
        $sixDofManifest.currentExecutables.with6DofSha256 -ne $sixDofManifest.currentExecutables.without6DofSha256 -and
        $badSixDofFiles.Count -eq 0) {
        Add-Check 'Profils avec/sans 6DOF' PASS 'Les trois couples utilisent deux EXE distincts et les cinq classes TrackIR/HookPilot correspondent au manifeste.'
    }
    else {
        Add-Check 'Profils avec/sans 6DOF' FAIL ($badSixDofFiles -join '; ')
    }
}

$sfsEffectOverride = Join-Path $root 'Files\Effects\Smokes\SmokeBoiling.eff'
$expectedSfsEffectSemanticHash = '629673DF3A1EE5EE23D8CFED8587DD06FAEFCB53FF6038AE889367EA0D56138D'
$activeFilesSfs = Join-Path $root 'files.SFS'
$allowedFilesSfsHashes = @(
    '9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095',
    '18F3C5471D93642916394DE53B482051106E024DDAC8124C7B0D700D1796B05A'
)
$activeFilesSfsHash = if (Test-Path -LiteralPath $activeFilesSfs -PathType Leaf) { Get-Sha256 $activeFilesSfs } else { '' }
if ((Test-Path -LiteralPath $sfsEffectOverride -PathType Leaf) -and
    (Get-NormalizedTextSha256 $sfsEffectOverride) -eq $expectedSfsEffectSemanticHash -and
    $activeFilesSfsHash -in $allowedFilesSfsHashes) {
    Add-Check 'Effet SmokeBoiling du files.SFS' PASS "La surcharge libre ramene nParticles de 2000 a 512 avec un files.SFS 4.09m autorise ; les espaces de fin de ligne sont ignores ($activeFilesSfsHash)."
}
else {
    Add-Check 'Effet SmokeBoiling du files.SFS' FAIL "Surcharge SmokeBoiling ou archive source inattendue ($activeFilesSfsHash)."
}

$testConf = Join-Path $root '_Game Switchers\conf.max.ini'
if (Test-Path -LiteralPath $testConf -PathType Leaf) {
    $introLines = @(Select-String -LiteralPath $testConf -Pattern '^\s*Intro\s*=\s*(\d+)\s*$')
    if ($introLines.Count -gt 0 -and $introLines[-1].Matches[0].Groups[1].Value -eq '0') {
        Add-Check 'Introduction du profil de test' PASS 'Intro=0 dans conf.max.ini.'
    }
    else {
        Add-Check 'Introduction du profil de test' FAIL 'Intro=0 absent de conf.max.ini.'
    }

    $focusValues = New-Object System.Collections.Generic.List[string]
    $gameCloudValues = New-Object System.Collections.Generic.List[string]
    $renderCloudValues = New-Object System.Collections.Generic.List[string]
    $currentSection = ''
    foreach ($line in Get-Content -LiteralPath $testConf) {
        if ($line -match '^\s*\[([^]]+)\]\s*$') {
            $currentSection = $Matches[1]
            continue
        }
        if ($line -match '^\s*DrawIfNotFocused\s*=\s*(\d+)\s*$' -and $currentSection -ieq 'window') {
            $focusValues.Add($Matches[1])
        }
        elseif ($line -match '^\s*TypeClouds\s*=\s*(\d+)\s*$') {
            if ($currentSection -ieq 'game') {
                $gameCloudValues.Add($Matches[1])
            }
            elseif ($currentSection -ieq 'Render_OpenGL') {
                $renderCloudValues.Add($Matches[1])
            }
        }
    }
    if ($focusValues.Count -eq 1 -and $focusValues[0] -eq '1' -and
        $gameCloudValues.Count -eq 1 -and $gameCloudValues[0] -eq '1' -and
        $renderCloudValues.Count -eq 1 -and $renderCloudValues[0] -eq '1') {
        Add-Check 'Profil focus et nuages v1.15' PASS 'DrawIfNotFocused=1 est sous [window] ; TypeClouds=1 est present sous [game] et [Render_OpenGL], comme dans la configuration officielle 4.09m.'
    }
    else {
        Add-Check 'Profil focus et nuages v1.15' FAIL 'Le profil ne reproduit pas les emplacements officiels : DrawIfNotFocused sous [window], TypeClouds sous [game] et [Render_OpenGL].'
    }
}
else {
    Add-Check 'Introduction du profil de test' FAIL 'conf.max.ini absent.'
    Add-Check 'Profil focus et nuages v1.15' FAIL 'conf.max.ini absent.'
}

if ($DumpRoot) {
    $resolvedDump = (Resolve-Path -LiteralPath $DumpRoot).Path
    $planeDirectory = Join-Path $resolvedDump 'com\maddox\il2\objects\vehicles\planes'
    $planeClass = Join-Path $planeDirectory 'Plane.class'
    if ((Test-Path -LiteralPath $planeClass -PathType Leaf) -and (Test-Path -LiteralPath $planeDirectory -PathType Container)) {
        $effectivePlaneClass = if (Test-Path -LiteralPath $planeRegistryOverride -PathType Leaf) { $planeRegistryOverride } else { $planeClass }
        $planeText = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($effectivePlaneClass))
        $nestedPlanes = @(Get-ChildItem -LiteralPath $planeDirectory -File -Filter 'Plane$*.class' | ForEach-Object {
            if ($_.Name -match '^Plane\$(.+)\.class$') { $Matches[1] }
        } | Sort-Object -Unique)
        $registeredPlanes = @($nestedPlanes | Where-Object { $planeText.Contains("Plane`$$_") })
        $unregistered = @($nestedPlanes | Where-Object { $_ -notin $registeredPlanes })
        if ($unregistered.Count -eq 0) {
            Add-Check 'Plane.class / classes imbriquees' PASS "$($nestedPlanes.Count) classes statiques enregistrees par la surcharge v1.15."
        }
        else {
            Add-Check 'Plane.class / classes imbriquees' FAIL ("{0} classe(s) statique(s) sans enregistrement central : {1}" -f $unregistered.Count, ($unregistered -join ', '))
        }
    }
    else {
        Add-Check 'Plane.class / classes imbriquees' FAIL "Dump incomplet : $planeClass absent."
    }

    $shipDirectory = Join-Path $resolvedDump 'com\maddox\il2\objects\ships'
    $shipClass = Join-Path $shipDirectory 'Ship.class'
    if ((Test-Path -LiteralPath $shipClass -PathType Leaf) -and (Test-Path -LiteralPath $shipRegistryOverride -PathType Leaf)) {
        $shipText = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($shipRegistryOverride))
        $nestedShips = @(Get-ChildItem -LiteralPath $shipDirectory -File -Filter 'Ship$*.class' | ForEach-Object {
            if ($_.Name -match '^Ship\$(.+)\.class$') { $Matches[1] }
        } | Sort-Object -Unique)
        $unregisteredShips = @($nestedShips | Where-Object { -not $shipText.Contains("Ship`$$_") })
        if ($unregisteredShips.Count -eq 0) {
            Add-Check 'Ship.class / classes imbriquees' PASS "$($nestedShips.Count) classes de navires enregistrees."
        }
        else {
            Add-Check 'Ship.class / classes imbriquees' FAIL ("{0} navire(s) sans enregistrement central : {1}" -f $unregisteredShips.Count, ($unregisteredShips -join ', '))
        }
    }
    else {
        Add-Check 'Ship.class / classes imbriquees' FAIL 'Dump ou surcharge Ship.class incomplet.'
    }

    $tooRecent = New-Object System.Collections.Generic.List[string]
    Get-ChildItem -LiteralPath $resolvedDump -File -Recurse -Filter '*.class' | ForEach-Object {
        $bytes = [IO.File]::ReadAllBytes($_.FullName)
        if ($bytes.Length -ge 8 -and $bytes[0] -eq 0xCA -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0xBA -and $bytes[3] -eq 0xBE) {
            $major = ($bytes[6] -shl 8) -bor $bytes[7]
            if ($major -gt 47) {
                $tooRecent.Add("$($_.FullName.Substring($resolvedDump.Length + 1)) (major $major)")
            }
        }
    }
    if ($tooRecent.Count -eq 0) {
        Add-Check 'Compatibilite Java du dump' PASS 'Aucune classe au-dela du major 47.'
    }
    else {
        Add-Check 'Compatibilite Java du dump' FAIL ("{0} classe(s) exigent une JVM plus recente que Java 1.3 : {1}" -f $tooRecent.Count, (($tooRecent | Select-Object -First 20) -join '; '))
    }
}
else {
    Add-Check 'Validation du dump runtime' WARN 'Non executee : fournir -DumpRoot pour verifier Plane.class et les versions Java.'
}

$summary = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToString('o')
    ProjectRoot = $specRoot
    ContentRoot = $root
    DumpRoot = $DumpRoot
    Pass = @($script:Checks | Where-Object Status -eq 'PASS').Count
    Warn = @($script:Checks | Where-Object Status -eq 'WARN').Count
    Fail = @($script:Checks | Where-Object Status -eq 'FAIL').Count
    Checks = $script:Checks
}

$script:Checks | Format-Table -AutoSize -Wrap
Write-Host ("Resultat : {0} PASS, {1} WARN, {2} FAIL" -f $summary.Pass, $summary.Warn, $summary.Fail)

if ($ReportPath) {
    $absoluteReport = if ([IO.Path]::IsPathRooted($ReportPath)) { $ReportPath } else { Join-Path $specRoot $ReportPath }
    $reportDirectory = Split-Path -Parent $absoluteReport
    if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
        New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
    }
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $absoluteReport -Encoding UTF8
    Write-Host "Rapport JSON : $absoluteReport"
}

if ($summary.Fail -gt 0) { exit 1 }
exit 0
