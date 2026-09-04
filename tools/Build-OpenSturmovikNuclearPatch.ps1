[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),
    [string]$SilverplateExplosions,
    [string]$OutputRoot,
    [switch]$Install
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ([string]::IsNullOrWhiteSpace($SilverplateExplosions)) {
    $SilverplateExplosions = Join-Path $root 'build\test-tools\b29-original-classes\com\maddox\il2\objects\effects\Explosions.class'
    if (-not (Test-Path -LiteralPath $SilverplateExplosions -PathType Leaf)) {
        # A clean checkout already contains the merged v1.15 class. The
        # bytecode patcher recognises that state and leaves it unchanged.
        $SilverplateExplosions = Join-Path $root 'Files\72DCDDF4D2AD25E8'
    }
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $root 'build\nuclear-patch'
}
$output = [IO.Path]::GetFullPath($OutputRoot)
$files = Join-Path $root 'Files'

$sourceFiles = [ordered]@{
    'Explosions-Zuti' = [pscustomobject]@{
        Path = Join-Path $files '72DCDDF4D2AD25E8'
        Sha256 = @(
            '2F66A5AA35C0DF6D29D44DA27FC71DDEF1198F05B9974D92DE11B22F14926F91',
            '082E0B42CF24DE7E61C6B55EF057DB3CB87D8E0E33373D9BDDE578507C57AD44',
            '0FAFDB908E7317C8E0E0E5092EE4D40E52251B3D8B06FDAC8CB08EBA1E05554C',
            'E32EBB8B4D84173C88A53AA74D06484DF47A74593D70E1FF858E170BDAD45707',
            'F90E68C7A11987E052146544068E35C0ED5DB8D381E5BDDC63870E7B470D0226',
            '24CCB92F1AD8BCAD777CAF03B9357CD7756E3E1248986A2C3B7FD317DDD2CF9A'
        )
    }
    'Explosions-Silverplate' = [pscustomobject]@{
        Path = [IO.Path]::GetFullPath($SilverplateExplosions)
        Sha256 = @(
            '4749790F3DD6CA95E6FC81930B866A83531F735F4DC6161D6C99921A8811B1A9',
            '082E0B42CF24DE7E61C6B55EF057DB3CB87D8E0E33373D9BDDE578507C57AD44',
            '0FAFDB908E7317C8E0E0E5092EE4D40E52251B3D8B06FDAC8CB08EBA1E05554C',
            'E32EBB8B4D84173C88A53AA74D06484DF47A74593D70E1FF858E170BDAD45707'
        )
    }
    'Explosion' = [pscustomobject]@{
        Path = Join-Path $files '303F5874196BEABE'
        Sha256 = @(
            '3EF7CFFA787DF827F0A16FBAA3B559C7E1A391F864583AD42324BBFBCFD253C5',
            'D4661E8594D24435C24747FBFBD0ADFCD972317E48075C528A1FCC67D9D61685'
        )
    }
    'MsgExplosion' = [pscustomobject]@{
        Path = Join-Path $files '809E3320DB37687A'
        Sha256 = @(
            'BF455F3CC272D9C8B79BCFA5743E5A6E250EC1671D2422AA4519EAF3A7D5088C',
            '0576626EBA5B0DD233BDFEE22967E43A37DA52564B1166F9D4BDF20FEAC4AFBE'
        )
    }
    'BombLittleBoy' = [pscustomobject]@{
        Path = Join-Path $files '3F43760A72781132'
        Sha256 = @(
            'B2780228AA6C8521B9117583E713A39C5F1BB6078BA119D59578F4EE27880AD8',
            '8D7B5F3D570C3463D0119AA6FDDE011D7EF3D07F053F2120A58B601C9D451343',
            'FAEAEFAA3D57ECF615912BB46FD19259E923D8C8AEA23862BB652A7248C2C6BE'
        )
    }
    'BombFatMan' = [pscustomobject]@{
        Path = Join-Path $files '830E5C5AC3A1C77A'
        Sha256 = @(
            '515DCE7B2FE6B555F9F56FC7EA1DFB96C33EBE6F370CCD8FD149FD6FB1C3CA6C',
            '9DCB1DD4BDBF9E6EED9B401157796B1E2BF4F0206564834150C2C3F077AD4589',
            '94ABC0A426CAF8E300FC995FE4D23ACCC164F88406D9314BC2A712C7E088E428'
        )
    }
}

foreach ($entry in $sourceFiles.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value.Path -PathType Leaf)) {
        throw "Source absente ($($entry.Key)) : $($entry.Value.Path)"
    }
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.Value.Path).Hash
    if ($actualHash -notin @($entry.Value.Sha256)) {
        throw "Source non reconnue ($($entry.Key)). Attendu l'une de ces empreintes : $(@($entry.Value.Sha256) -join ', '); obtenu $actualHash."
    }
}

$java = (Get-Command java -ErrorAction Stop).Source
$javac = (Get-Command javac -ErrorAction Stop).Source
$patcherClasses = Join-Path $output 'patcher'
$compiledClasses = Join-Path $output 'compiled'
$semanticClasses = Join-Path $output 'semantic'
$staging = Join-Path $output 'files-staging'
foreach ($directory in @($output, $patcherClasses, $compiledClasses, $semanticClasses, $staging)) {
    [IO.Directory]::CreateDirectory($directory) | Out-Null
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$FailureMessage
    )
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (code $LASTEXITCODE)."
    }
}

$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree.analysis=ALL-UNNAMED'
)

$patcherSource = Join-Path $root 'tools\java\OpenSturmovikNuclearPatcher.java'
Invoke-Checked -Executable $javac -Arguments @(
    $exports + @('-d', $patcherClasses, $patcherSource)
) -FailureMessage 'Compilation du constructeur nucleaire impossible'

$stubSources = @(Get-ChildItem -LiteralPath (Join-Path $root 'tools\java\nuclear-stubs') -Recurse -Filter *.java | ForEach-Object FullName)
$nuclearSource = Join-Path $root 'tools\java\nuclear\com\maddox\il2\objects\effects\NuclearBlast.java'
$nuclearCompileArguments = @(
    '-source', '7', '-target', '7', '-g:none', '-d', $compiledClasses
) + $stubSources + @($nuclearSource)
Invoke-Checked -Executable $javac -Arguments $nuclearCompileArguments -FailureMessage 'Compilation de NuclearBlast impossible'

$compiledNuclear = Join-Path $compiledClasses 'com\maddox\il2\objects\effects'
Invoke-Checked -Executable $java -Arguments @(
    $exports + @(
        '-cp', $patcherClasses,
        'OpenSturmovikNuclearPatcher',
        $sourceFiles['Explosions-Zuti'].Path,
        $sourceFiles['Explosions-Silverplate'].Path,
        $sourceFiles['Explosion'].Path,
        $sourceFiles['MsgExplosion'].Path,
        $sourceFiles['BombLittleBoy'].Path,
        $sourceFiles['BombFatMan'].Path,
        $compiledNuclear,
        $semanticClasses
    )
) -FailureMessage 'Construction ou verification du bytecode nucleaire impossible'

$mapping = [ordered]@{
    'Explosions.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.Explosions'; LooseName = '72DCDDF4D2AD25E8' }
    'Explosion.class' = [pscustomobject]@{ Class = 'com.maddox.il2.ai.Explosion'; LooseName = '303F5874196BEABE' }
    'MsgExplosion.class' = [pscustomobject]@{ Class = 'com.maddox.il2.ai.MsgExplosion'; LooseName = '809E3320DB37687A' }
    'BombLittleBoy.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.weapons.BombLittleBoy'; LooseName = '3F43760A72781132' }
    'BombFatMan.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.weapons.BombFatMan'; LooseName = '830E5C5AC3A1C77A' }
    'NuclearBlast.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast'; LooseName = '5AC49B8080496790' }
    'NuclearBlast$DamageAction.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$DamageAction'; LooseName = '761B02162C6E5D04' }
    'NuclearBlast$DamageData.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$DamageData'; LooseName = '709FB7A0C816C8B2' }
    'NuclearBlast$ShockAction.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$ShockAction'; LooseName = '6482BE08C086B0BA' }
    'NuclearBlast$ShockData.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$ShockData'; LooseName = '145128EC449ADBDA' }
    'NuclearBlast$PhaseAction.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$PhaseAction'; LooseName = '8D53953C1956F06A' }
    'NuclearBlast$VisualTickAction.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$VisualTickAction'; LooseName = 'ABFC6F18761EB542' }
    'NuclearBlast$State.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$State'; LooseName = '51AD1FEC90031C8A' }
}

# Every class emitted from NuclearBlast.java must have one loose-file mapping.
# The semantic audit independently verifies that each hexadecimal name is the
# SFS fingerprint of the corresponding Java class name.
$generatedNuclearClassNames = @(
    Get-ChildItem -LiteralPath $semanticClasses -Filter 'NuclearBlast*.class' -File |
        ForEach-Object Name |
        Sort-Object
)
$mappedNuclearClassNames = @(
    $mapping.Keys |
        Where-Object { $_ -like 'NuclearBlast*.class' } |
        Sort-Object
)
$mappingDifferences = @(Compare-Object -ReferenceObject $generatedNuclearClassNames -DifferenceObject $mappedNuclearClassNames)
if ($mappingDifferences.Count -ne 0) {
    throw "Mappage incomplet des classes NuclearBlast : $($mappingDifferences | Out-String)"
}
$duplicateLooseNames = @($mapping.Values | Group-Object LooseName | Where-Object Count -gt 1)
if ($duplicateLooseNames.Count -ne 0) {
    throw "Noms libres SFS dupliques : $($duplicateLooseNames.Name -join ', ')."
}

$manifestEntries = [Collections.Generic.List[object]]::new()
foreach ($entry in $mapping.GetEnumerator()) {
    $source = Join-Path $semanticClasses $entry.Key
    $destination = Join-Path $staging $entry.Value.LooseName
    Copy-Item -LiteralPath $source -Destination $destination -Force
    $bytes = [IO.File]::ReadAllBytes($destination)
    $major = ($bytes[6] -shl 8) -bor $bytes[7]
    if ($major -ne 47) {
        throw "Classe $($entry.Value.Class) en version Java $major au lieu de 47."
    }
    $manifestEntries.Add([ordered]@{
        class = $entry.Value.Class
        loose_name = $entry.Value.LooseName
        size = $bytes.Length
        java_major = $major
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
    })
}

$manifest = [ordered]@{
    schema = 'open-sturmovik-nuclear-patch-v1'
    model = [ordered]@{
        little_boy = [ordered]@{ yield_kt = 15; airburst_m = 600; engine_radius_m = 2150; mass_kg = 4400; visual_scale = 0.894 }
        fat_man = [ordered]@{ yield_kt = 21; airburst_m = 503; engine_radius_m = 2360; mass_kg = 4670; visual_scale = 1.0 }
        pressure_reference_10kt_m = [ordered]@{ psi20 = 480; psi10 = 710; psi5 = 970; psi2 = 1800 }
        propagation_m_s = 343
        damage_timing = 'per-actor simulation-time delay'
        outer_aircraft_effect = 'bounded velocity impulse only'
        visual_clock = 'IL-2 simulation time only; pause freezes age and never recreates an emitter'
        visual_state = [ordered]@{
            identity = 'one persistent state per rendered detonation'
            fields = @('detonation_time', 'position', 'altitude', 'ground_altitude', 'yield', 'surface', 'phase', 'actor_roles', 'actors_created', 'actors_destroyed', 'visual_ticks', 'stabilized_created', 'transients_retired', 'rise_retired', 'next_rise_layer', 'rise_layers_created', 'rise_layers_skipped', 'emission_complete')
            ownership = 'all initial and phased Eff3DActor instances are registered and explicitly destroyed'
            diagnostics = 'event, phase, simulation age, surface, actor, heartbeat, drain and emission state written to log'
            pause_recovery = 'no Java recreation: the simulation-timed actors remain owned across pause and resume'
            rise_curve = 'fixed layers follow a quadratic ease-out from the historical airburst to the configured AGL summit over 600 simulated seconds; no live emitter is moved'
            phase_overlap = 'ten head layers at 30+60n s and five torus layers at 90+120n s each emit for 60 s and drain for 128 s; transients drain through 130 s; all rise actors overlap the stabilized phase until 728 s'
        }
        visual_lifecycle_s = [ordered]@{
            detonation_end = 1
            early_rise_end = 30
            mature_rise_end = 120
            late_rise_end = 600
            stabilized_end = 1800
            dissipating_end = 3600
            transient_drain_end = 130
            rise_drain_end = 728
            stabilized_particle_drain_end = 3718
            cleanup_deadline = 3728
            rise_layer_checkpoints = @(30, 90, 150, 210, 270, 330, 390, 450, 510, 570)
            torus_layer_checkpoints = @(90, 210, 330, 450, 570)
            rise_layer_emission = 60
            rise_layer_particle_drain = 128
            rise_layer_actor_duration = 190
        }
        cloud_summit = [ordered]@{
            little_boy_m = 12000
            fat_man_m = 13500
            interpretation = 'approximately above local ground including historical airburst altitude'
        }
        effect_engine_limits = [ordered]@{
            particles_per_emitter = 512
            particle_lifetime_s = 128
            max_concurrent_rise_head_emitters = 4
            max_concurrent_rise_torus_emitters = 2
            max_created_visual_actors_per_blast = 22
            representation = 'bounded fixed-position pools renewed by simulation-time emitters; no particle origin is moved after creation'
        }
    }
    classes = $manifestEntries
    installed = [bool]$Install
}
$manifestPath = Join-Path $output 'manifest.json'
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

$backupPath = $null
if ($Install) {
    $backupPath = Join-Path $output ('backup-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ'))
    [IO.Directory]::CreateDirectory($backupPath) | Out-Null
    foreach ($entry in $mapping.GetEnumerator()) {
        $target = Join-Path $files $entry.Value.LooseName
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            Copy-Item -LiteralPath $target -Destination (Join-Path $backupPath $entry.Value.LooseName) -Force
        }
        Copy-Item -LiteralPath (Join-Path $staging $entry.Value.LooseName) -Destination $target -Force
    }
}

[pscustomobject]@{
    Output = $output
    Manifest = $manifestPath
    Staging = $staging
    Installed = [bool]$Install
    Backup = $backupPath
    Classes = $manifestEntries.Count
}
