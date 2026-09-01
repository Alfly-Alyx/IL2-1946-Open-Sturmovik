[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$ContentRoot,
    [string]$DumpRoot,
    [string]$ReportPath
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

$nuclearManifestPath = Join-Path $specRoot 'manifests\effects\nuclear-blast-v1.15.json'
$expectedNuclearClasses = [ordered]@{
    '72DCDDF4D2AD25E8' = 'E32EBB8B4D84173C88A53AA74D06484DF47A74593D70E1FF858E170BDAD45707'
    '303F5874196BEABE' = 'D4661E8594D24435C24747FBFBD0ADFCD972317E48075C528A1FCC67D9D61685'
    '809E3320DB37687A' = '0576626EBA5B0DD233BDFEE22967E43A37DA52564B1166F9D4BDF20FEAC4AFBE'
    '3F43760A72781132' = '8D7B5F3D570C3463D0119AA6FDDE011D7EF3D07F053F2120A58B601C9D451343'
    '830E5C5AC3A1C77A' = '9DCB1DD4BDBF9E6EED9B401157796B1E2BF4F0206564834150C2C3F077AD4589'
    '5AC49B8080496790' = '94ECE2CA0D1204B90EFD37BCEE7131F8083CF715305845E37FF4587B61DB3F30'
    '761B02162C6E5D04' = '15BB56B33EB48A835700B623B21B04856D2F81DA4F08DB6C6BC8408A9F097F4C'
    '709FB7A0C816C8B2' = 'BFBF4A805BDDC4FA186065333139A645316392E1A5345BD3C1A8AC7FF0837D1F'
    '6482BE08C086B0BA' = '5FC39F58A4A924905BF7C924918E906E318AC74E4EFE981BD99BC138CCE6D25F'
    '145128EC449ADBDA' = '05B45025FB3E1E09BA1BCC24E6D6FC0AC070481F1EC1689CFCC7D60143B43D66'
    '2A3CF08C7344E18A' = '038C1168E34931873D64A2AFFE1FF9F464F00F0C8BDD47CB426984BB443FE196'
    'AB04450E05C9E67C' = '5FED08559B56C2CD401D53AA2F4432999A3B98412FFEBF715D91E73B3FE4017B'
}
$expectedNuclearVisuals = [ordered]@{
    'Files/3do/Effects/Fireworks/FatMan(buff).eff' = '8294F91189F87294B79ECBFE7C2F47B4621FC67B68EC4643EDB2D430771560A4'
    'Files/3do/Effects/Fireworks/FatMan(circle).eff' = 'B18FCFB0B0107B10196BA6B370D8C12A95311551E3A1D8BB7478593F5CE56BB4'
    'Files/3do/Effects/Fireworks/FatMan(circleL).eff' = '62B43DA7E8045DA2E25BA907010C6CFC72F26124F3D387CC58A56D069CC3A247'
    'Files/3do/Effects/Fireworks/FatMan(column).eff' = 'BB9E2292D82562ABFE7C3FE6DC7BB07E999FE9EA88973D832B14074CDD5E09D4'
    'Files/3do/Effects/Fireworks/FatMan(flare).eff' = 'EE46469205665B504577D637B604475AFEECDF6DA1A22E4CF097D30BC23EEE37'
    'Files/3do/Effects/Fireworks/FatMan(ring).eff' = '1E60279ED5E9834EF23A28711CF4EA7C19A2237F865DB5C24552FD514B53A936'
    'Files/3do/Effects/Fireworks/FatMan(shock).eff' = 'B02B7C38413EC34244E868C2D0290F35997B83E0AC23957DAC81A96AA79B5A00'
    'Files/3do/Effects/Fireworks/FatMan(stabilized).eff' = 'A6C4D47C51D828946A263EA3D0A6E60CB52F55FD2646A41FFDB1DE5E41722C86'
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
        [string]$nuclearManifest.model.pause_preservation.detection -notmatch '25 ms' -or
        [string]$nuclearManifest.model.pause_preservation.control -notmatch 'Eff3D.pause' -or
        $nuclearManifest.validation.runtime_test_required -ne $true) {
        $badNuclearClasses.Add('parametres historiques ou statut de validation inattendus')
    }
}
if ($badNuclearClasses.Count -eq 0) {
    Add-Check 'Souffle nucleaire Little Boy / Fat Man' PASS 'Les douze classes Java 1.3 et les huit effets correspondent au manifeste v1.15 : 15/21 kt, airbursts 600/503 m, souffle differe et cycle visuel phase 600/3600 s. Ce controle est statique.'
}
else {
    Add-Check 'Souffle nucleaire Little Boy / Fat Man' FAIL ($badNuclearClasses -join '; ')
}
if ($null -ne $nuclearManifest -and [string]$nuclearManifest.status -eq 'static_coherent_runtime_visual_blocked') {
    Add-Check 'Validation visuelle nucleaire' WARN 'Le panache repart encore apres pause/reprise et apres sortie du champ camera ; la surveillance native a 25 ms n est pas une correction validee.'
}
if ($null -ne $nuclearManifest -and $nuclearManifest.third_party_origin.redistribution_authorized -ne $true) {
    Add-Check 'Licence Silverplate v1.2' WARN 'Le paquet n a pas de licence publiee et n accorde aucune autorisation de redistribution ; permission explicite, composant externe ou remplacement requis.'
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
    Add-Check 'Presets de demarrage moteur' PASS 'Les dix presets DB-600, Merlin, Sabre, R-2800 et Sakae utilisent un mixeur complet et tous leurs WAV sont presents.'
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
    Add-Check 'Provenance sons Tiger33' PASS 'Les dix presets et vingt WAV correspondent au manifeste source ; les deux WAV Sabre historiques sont explicitement conserves.'
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
    Add-Check 'References WAV corrigees' PASS 'Les trois anciens noms invalides ne sont plus references ; les echantillons Allison et MG FF correspondants sont presents.'
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
}
else {
    Add-Check 'Introduction du profil de test' FAIL 'conf.max.ini absent.'
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
