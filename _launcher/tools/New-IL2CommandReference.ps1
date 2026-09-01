[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$HotKeyCataloguePath,

    [Parameter(Mandatory)]
    [string]$SetupContractPath,

    [Parameter(Mandatory)]
    [string]$SetupCataloguePath,

    [Parameter(Mandatory)]
    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$invariant = [Globalization.CultureInfo]::InvariantCulture

function Resolve-JsonFile {
    param([string]$Path, [string]$Description)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description introuvable : $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Escape-MarkdownCell {
    param($Value)
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return '—'
    }
    return ([string]$Value).Replace('|', '\|').Replace("`r", ' ').Replace("`n", ' ').Trim()
}

function Format-Number {
    param($Value)
    if ($null -eq $Value) { return '—' }
    return ([Convert]::ToDouble($Value, $invariant)).ToString('0.###', $invariant)
}

function Format-SettingValues {
    param($Setting)
    if ($Setting.type -eq 'boolean') { return '`0` ou `1`' }
    if ($null -ne $Setting.PSObject.Properties['values']) {
        if ($Setting.values -is [Array]) {
            return (@($Setting.values | ForEach-Object { '`' + [string]$_ + '`' }) -join ', ')
        }
        return (@($Setting.values.PSObject.Properties | ForEach-Object {
            '`' + $_.Name + '=' + $_.Value + '`'
        }) -join ', ')
    }
    if ($null -ne $Setting.PSObject.Properties['visibleChoices']) {
        return (@($Setting.visibleChoices | ForEach-Object { '`' + [string]$_ + '`' }) -join ', ') +
            ' — codage exact non résolu'
    }
    switch ($Setting.type) {
        'display-mode' { return 'modes énumérés par Windows' }
        'provider-reference' { return 'nom déclaré dans `[GLPROVIDERS]`' }
        'profile-reference' { return 'identifiant de profil `il2setup.ini`' }
        'port' { return 'borne valide non encore prouvée' }
        'ip-address' { return 'adresse texte — donnée sensible' }
        default { return 'plage non encore prouvée' }
    }
}

$hotKeyPath = Resolve-JsonFile -Path $HotKeyCataloguePath -Description 'Catalogue des commandes'
$contractPath = Resolve-JsonFile -Path $SetupContractPath -Description 'Contrat il2setup'
$setupCatalogueResolved = Resolve-JsonFile -Path $SetupCataloguePath -Description 'Catalogue il2setup'
$hotKeys = Get-Content -LiteralPath $hotKeyPath -Raw | ConvertFrom-Json
$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
$setupCatalogue = Get-Content -LiteralPath $setupCatalogueResolved -Raw | ConvertFrom-Json

$environmentLabels = @{
    '$$$misc' = 'Commandes internes diverses'
    aircraftView = 'Vues extérieures et cockpit'
    gunner = 'Mitrailleur'
    misc = 'Divers'
    move = 'Axes analogiques'
    orders = 'Communications et ordres'
    PanView = 'Vue panoramique'
    pilot = 'Pilotage et systèmes de l''avion'
    SnapView = 'Vues instantanées'
    timeCompression = 'Temps et pause'
}

$profilePurposes = @{
    Channels = 'Nombre ou mode de canaux audio.'
    ForceShaders1x = 'Force un chemin de shaders compatible avec le matériel ancien.'
    'MusFlags.play' = 'Autorise la lecture de la musique.'
    Placement = 'Mode de placement spatial des sons.'
    PolygonOffsetFactor = 'Décalage de profondeur des polygones : facteur.'
    PolygonOffsetUnits = 'Décalage de profondeur des polygones : unités.'
    RadioEngine = 'Moteur utilisé pour les communications radio.'
    'RadioFlags.enabled' = 'Active les communications radio.'
    SamplingRate = 'Fréquence d''échantillonnage audio ; codage exact encore incomplet.'
    SoundEngine = 'Moteur de rendu sonore.'
    'SoundExt.acoustics' = 'Active les traitements acoustiques étendus.'
    'SoundExt.occlusions' = 'Active l''atténuation des sons masqués par des obstacles.'
    'SoundExt.volumefx' = 'Active les effets sonores volumétriques.'
    'SoundFlags.duplex' = 'Autorise le fonctionnement audio duplex.'
    'SoundFlags.forceEAX1' = 'Force le mode EAX 1.'
    'SoundFlags.hardware' = 'Utilise l''accélération audio matérielle.'
    'SoundFlags.reversestereo' = 'Inverse les canaux gauche et droit.'
    'SoundFlags.static' = 'Autorise les tampons sonores statiques.'
    'SoundFlags.streams' = 'Autorise les flux audio.'
    'SoundFlags.voicemgr' = 'Active le gestionnaire de voix.'
    SoundMode = 'Niveau ou mode du moteur sonore 3D.'
    SoundUse = 'Active complètement le son.'
    Speakers = 'Configuration des haut-parleurs.'
    TexCompress = 'Niveau ou mode de compression des textures.'
    'TexFlags.ARBMultitextureExt' = 'Autorise l''extension ARB multitexture.'
    'TexFlags.ClipHintExt' = 'Autorise l''extension de conseil de clipping.'
    'TexFlags.DepthClampNV' = 'Autorise le depth clamp NVIDIA.'
    'TexFlags.DisableAPIExtensions' = 'Désactive les extensions de l''API graphique.'
    'TexFlags.PolygonStipple' = 'Autorise le tramage de polygones.'
    'TexFlags.SecondaryColorExt' = 'Autorise la couleur secondaire.'
    'TexFlags.SeparateSpecular' = 'Sépare la composante spéculaire.'
    'TexFlags.TexAnisotropicExt' = 'Autorise le filtrage anisotrope.'
    'TexFlags.TexCompressARBExt' = 'Autorise la compression de textures ARB.'
    'TexFlags.TexEnvCombine4NV' = 'Autorise la combinaison de textures NVIDIA à quatre unités.'
    'TexFlags.TexEnvCombineDot3' = 'Autorise la combinaison DOT3.'
    'TexFlags.TexEnvCombineExt' = 'Autorise la combinaison de textures étendue.'
    'TexFlags.TextureShaderNV' = 'Autorise les texture shaders NVIDIA.'
    'TexFlags.UseDither' = 'Active le tramage des couleurs.'
    'TexFlags.UsePaletteExt' = 'Autorise les textures palettisées.'
    'TexFlags.UseVertexArrays' = 'Utilise les tableaux de sommets.'
    'TexFlags.VertexArrayExt' = 'Autorise l''extension de tableaux de sommets.'
    TexMipFilter = 'Choisit le filtrage des niveaux mipmap.'
    TexQual = 'Niveau de qualité des textures.'
}

$observedProfileValues = @{}
foreach ($profile in @($setupCatalogue.profiles)) {
    foreach ($property in $profile.resolvedSettings.PSObject.Properties) {
        if (-not $observedProfileValues.ContainsKey($property.Name)) {
            $observedProfileValues[$property.Name] = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        }
        [void]$observedProfileValues[$property.Name].Add([string]$property.Value)
    }
}

$builder = [Text.StringBuilder]::new()
function Add-Line {
    param([string]$Text = '')
    [void]$builder.AppendLine($Text)
}

Add-Line '# Référence des réglages et commandes IL-2 1946 / Open Sturmovik'
Add-Line
Add-Line '> Document de travail généré depuis des preuves statiques. Une valeur « observée » n''est pas automatiquement une borne valide du moteur.'
Add-Line
Add-Line '## Où sont stockés les réglages'
Add-Line
Add-Line '- `conf.ini` contient les réglages globaux : fenêtre, rendu, son, réseau, moteur RTS, souris et joystick.'
Add-Line '- `Users/{pilote}/settings.ini` contient les affectations de touches et d''axes, la difficulté et plusieurs préférences du pilote.'
Add-Line '- `il2setup.ini` est le catalogue historique de profils lu par `il2setup.exe`; ses clés peuvent être écrites dans `conf.ini` même si elles sont absentes du fichier courant.'
Add-Line '- Une commande bouton reçoit un événement relâché/pressé (`0/1`). Ce n''est pas un réglage continu, même lorsque son effet est un interrupteur.'
Add-Line
Add-Line '## Plages prouvées des périphériques'
Add-Line
Add-Line '| Élément | Minimum | Maximum | Détail |'
Add-Line '|---|---:|---:|---|'
Add-Line '| Valeur brute d''un axe joystick | -125 | 125 | Constantes `Joy.AXE_MIN_MOVE` et `Joy.AXE_MAX_MOVE`. |'
Add-Line '| Valeur normalisée transmise aux commandes | -1 | 1 | `Joy.normal(v) = v × 0,008`. |'
Add-Line '| Zone morte | 0 | 50 | Premier entier de chaque ligne d''axe. |'
Add-Line '| Coefficients de courbe 1 à 10 | 0 | 100 | Dix valeurs indépendantes, limitées par l''écran de réglage. |'
Add-Line '| Filtre d''axe | 0 | 100 | Dernier entier; interface historique par pas de 10. |'
Add-Line '| Sensibilité souris X/Y | 0,1 | 10 | Valeur flottante limitée par `GUISetupInput`. |'
Add-Line '| Retour de force `FF` | 0 | 1 | Désactivé / activé. |'
Add-Line '| Capacité joysticks / axes / POV | — | 4 / 8 / 4 | Quatre joysticks, huit axes et quatre POV par joystick. |'
Add-Line
Add-Line 'Une ligne moderne de `[rts_joystick]` contient douze entiers : zone morte, dix coefficients, puis filtre. Le moteur sait aussi convertir l''ancien format; les deux formats ne doivent pas être fusionnés aveuglément. Le préfixe de format `1` et le suffixe de numéro de joystick doivent être préservés jusqu''à la fin de la rétro-ingénierie.'
Add-Line
Add-Line '## Axes assignables et effet logique'
Add-Line
Add-Line '| Identifiant exact | Fonction française observée | Entrée min | Entrée max | Sortie logique min | Sortie logique max | Inversé |'
Add-Line '|---|---|---:|---:|---:|---:|---|'
foreach ($command in @($hotKeys.commands | Where-Object bindingKind -eq 'axis' | Sort-Object id)) {
    Add-Line ('| `{0}` | {1} | {2} | {3} | {4} | {5} | {6} |' -f
        (Escape-MarkdownCell $command.id),
        (Escape-MarkdownCell $(if ($command.localizedLabel) { $command.localizedLabel } else { $command.label })),
        (Format-Number $command.inputMinimum),
        (Format-Number $command.inputMaximum),
        (Format-Number $command.logicalMinimum),
        (Format-Number $command.logicalMaximum),
        $(if ($command.inverted) { 'oui' } else { 'non' }))
}
Add-Line
Add-Line 'La puissance transforme `-1…1` en `0…1,1` afin de couvrir jusqu''à 110 %. Le pas d''hélice, les volets et les freins donnent `0…1`; aileron, profondeur et palonnier donnent `-1…1`; les trims donnent `-0,5…0,5`. Un identifiant commençant par `-` inverse le sens physique avant cette transformation.'
Add-Line
Add-Line '## Réglages historiques connus de `il2setup.exe`'
Add-Line
Add-Line '| Section / clé | Fonction | Type | Valeurs ou plage | Confiance |'
Add-Line '|---|---|---|---|---|'
foreach ($setting in @($contract.settings)) {
    $key = if ($null -ne $setting.PSObject.Properties['key']) {
        "[$($setting.section)]/$($setting.key)"
    }
    else {
        "[$($setting.section)]/" + (@($setting.keys) -join ', ')
    }
    Add-Line ('| `{0}` | {1} | `{2}` | {3} | `{4}` |' -f
        (Escape-MarkdownCell $key),
        (Escape-MarkdownCell $setting.userLabel),
        (Escape-MarkdownCell $setting.type),
        (Escape-MarkdownCell (Format-SettingValues $setting)),
        (Escape-MarkdownCell $setting.confidence))
}
Add-Line
Add-Line '## Clés que les profils peuvent ajouter à `conf.ini`'
Add-Line
Add-Line 'Cette table couvre les 39 profils statiques d''`il2setup.ini`. Min/max signifie seulement **minimum/maximum observé dans ces profils**, pas limite absolue du moteur.'
Add-Line
Add-Line '| Clé | Valeurs observées | Min observé | Max observé | Rôle technique |'
Add-Line '|---|---|---:|---:|---|'
foreach ($key in @($observedProfileValues.Keys | Sort-Object)) {
    $values = @($observedProfileValues[$key] | Sort-Object)
    $numbers = [Collections.Generic.List[double]]::new()
    $allNumeric = $true
    foreach ($value in $values) {
        $number = 0.0
        if ([double]::TryParse($value, [Globalization.NumberStyles]::Float, $invariant, [ref]$number)) {
            $numbers.Add($number)
        }
        else {
            $allNumeric = $false
        }
    }
    $minimum = if ($allNumeric) { ($numbers | Measure-Object -Minimum).Minimum } else { $null }
    $maximum = if ($allNumeric) { ($numbers | Measure-Object -Maximum).Maximum } else { $null }
    $purpose = if ($profilePurposes.ContainsKey($key)) { $profilePurposes[$key] } else { 'Rôle encore à documenter.' }
    Add-Line ('| `{0}` | {1} | {2} | {3} | {4} |' -f
        (Escape-MarkdownCell $key),
        (Escape-MarkdownCell ($values -join ', ')),
        (Format-Number $minimum),
        (Format-Number $maximum),
        (Escape-MarkdownCell $purpose))
}
Add-Line
Add-Line '## Catalogue des commandes boutons'
Add-Line
Add-Line ('Le relevé contient **{0} commandes uniques**, dont **{1} publiques**, **{2} internes** et **{3} présentes seulement dans un `settings.ini` sans déclaration retrouvée dans les classes analysées**.' -f
    $hotKeys.summary.commands,
    $hotKeys.summary.publicCommands,
    $hotKeys.summary.internalCommands,
    $hotKeys.summary.settingsOnlyCommands)
Add-Line
Add-Line 'L''origine historique ou ajoutée par Open Sturmovik reste `unclassified` tant qu''un catalogue 4.09m propre n''a pas été produit avec la même méthode.'
Add-Line
$buttonCommands = @($hotKeys.commands | Where-Object {
    $_.bindingKind -eq 'button' -and $_.visibility -ne 'internal'
})
foreach ($group in @($buttonCommands | Group-Object environment | Sort-Object Name)) {
    $heading = if ($environmentLabels.ContainsKey($group.Name)) { $environmentLabels[$group.Name] } else { $group.Name }
    Add-Line ('### {0} (`{1}`)' -f $heading, $group.Name)
    Add-Line
    Add-Line '| Identifiant exact | Fonction française observée | Référence anglaise | Entrée | Déclaration | Affectée dans un exemple |'
    Add-Line '|---|---|---|---:|---|---|'
    foreach ($command in @($group.Group | Sort-Object sortKey, id)) {
        Add-Line ('| `{0}` | {1} | {2} | 0 / 1 | `{3}` | {4} |' -f
            (Escape-MarkdownCell $command.id),
            (Escape-MarkdownCell $command.localizedLabel),
            (Escape-MarkdownCell $command.label),
            (Escape-MarkdownCell $command.registrationStatus),
            $(if ($command.bound) { 'oui' } else { 'non' }))
    }
    Add-Line
}

Add-Line '## Commandes internes'
Add-Line
Add-Line 'Ces commandes ont un identifiant ou un environnement marqué interne. Le lanceur ne doit pas les proposer au joueur sans preuve supplémentaire.'
Add-Line
Add-Line '| Environnement | Identifiant | Libellé |'
Add-Line '|---|---|---|'
foreach ($command in @($hotKeys.commands | Where-Object visibility -eq 'internal' | Sort-Object environment, id)) {
    Add-Line ('| `{0}` | `{1}` | {2} |' -f
        (Escape-MarkdownCell $command.environment),
        (Escape-MarkdownCell $command.id),
        (Escape-MarkdownCell $(if ($command.localizedLabel) { $command.localizedLabel } else { $command.label })))
}
Add-Line
Add-Line '## Affectations non confirmées ou probablement anciennes'
Add-Line
Add-Line 'Une ligne `settings-only` a été vue dans un profil joueur mais aucune déclaration correspondante n''a été retrouvée dans les classes statiques analysées. Elle doit être conservée lors d''une réécriture, mais signalée comme non confirmée.'
Add-Line
Add-Line '| Environnement | Identifiant | Exemples d''affectation |'
Add-Line '|---|---|---|'
foreach ($command in @($hotKeys.commands | Where-Object registrationStatus -eq 'settings-only' | Sort-Object environment, id)) {
    $examples = @($command.sampleBindings | ForEach-Object { $_.gesture }) -join ', '
    Add-Line ('| `{0}` | `{1}` | {2} |' -f
        (Escape-MarkdownCell $command.environment),
        (Escape-MarkdownCell $command.id),
        (Escape-MarkdownCell $examples))
}
Add-Line
Add-Line '## Limites et prochaines preuves nécessaires'
Add-Line
Add-Line '- Produire le même catalogue depuis une installation 4.09m strictement d''origine pour classer chaque commande comme historique ou ajoutée.'
Add-Line '- Résoudre les alias observés, notamment `AIRCRAFT_STABILIZER` face à la commande déclarée `Stabilizer`.'
Add-Line '- Vérifier pourquoi les anciens profils contiennent `order10` à `order17` alors que la classe analysée ne déclare que `order0` à `order9`.'
Add-Line '- Corriger ou remplacer certains libellés français manifestement incohérents; le libellé anglais est conservé comme référence parallèle.'
Add-Line '- Étendre l''inventaire à toutes les clés de `conf.ini` et aux formats SFS, missions, modèles de vol, rendu, son et réseau.'

$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw "Dossier de sortie introuvable : $outputDirectory"
}
[IO.File]::WriteAllText($resolvedOutput, $builder.ToString(), [Text.UTF8Encoding]::new($false))

[PSCustomObject]@{
    output = [IO.Path]::GetFileName($resolvedOutput)
    bytes = (Get-Item -LiteralPath $resolvedOutput).Length
    commandCount = $hotKeys.summary.commands
    profileCount = $setupCatalogue.profileCount
    profileKeyCount = $observedProfileValues.Count
} | ConvertTo-Json -Depth 4
