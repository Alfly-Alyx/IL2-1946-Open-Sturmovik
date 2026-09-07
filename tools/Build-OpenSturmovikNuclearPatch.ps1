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
            'E32EBB8B4D84173C88A53AA74D06484DF47A74593D70E1FF858E170BDAD45707'
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
            '8D7B5F3D570C3463D0119AA6FDDE011D7EF3D07F053F2120A58B601C9D451343'
        )
    }
    'BombFatMan' = [pscustomobject]@{
        Path = Join-Path $files '830E5C5AC3A1C77A'
        Sha256 = @(
            '515DCE7B2FE6B555F9F56FC7EA1DFB96C33EBE6F370CCD8FD149FD6FB1C3CA6C',
            '9DCB1DD4BDBF9E6EED9B401157796B1E2BF4F0206564834150C2C3F077AD4589'
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
    'NuclearBlast$VisualAction.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$VisualAction'; LooseName = '2A3CF08C7344E18A' }
    'NuclearBlast$VisualData.class' = [pscustomobject]@{ Class = 'com.maddox.il2.objects.effects.NuclearBlast$VisualData'; LooseName = 'AB04450E05C9E67C' }
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
    generated_utc = [DateTime]::UtcNow.ToString('o')
    model = [ordered]@{
        little_boy = [ordered]@{ yield_kt = 15; airburst_m = 600; engine_radius_m = 2150; mass_kg = 4400; visual_scale = 0.894 }
        fat_man = [ordered]@{ yield_kt = 21; airburst_m = 503; engine_radius_m = 2360; mass_kg = 4670; visual_scale = 1.0 }
        pressure_reference_10kt_m = [ordered]@{ psi20 = 480; psi10 = 710; psi5 = 970; psi2 = 1800 }
        propagation_m_s = 343
        damage_timing = 'per-actor simulation-time delay'
        outer_aircraft_effect = 'bounded velocity impulse only'
        visual_clock = 'explicit IL-2 simulation time; pause must not consume particle lifetime'
        pause_preservation = [ordered]@{
            detection_clock = 'IL-2 real-time MsgAction, one shared 25 ms watcher'
            emitter_control = 'native Eff3D.pause via cached protected-method reflection'
            scope = 'registered Little Boy and Fat Man emitters only'
            purpose = 'prevent particle emitter reset and accelerated age replay after pause menu'
        }
        visual_lifecycle_s = [ordered]@{
            fireball_max = 1
            active_cloud_rise = 600
            stabilized_cloud_visibility = 3600
        }
        effect_engine_limits = [ordered]@{
            particles_per_emitter = 512
            particle_lifetime_s = 128
            representation = 'bounded pools renewed by simulation-time emitters'
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
