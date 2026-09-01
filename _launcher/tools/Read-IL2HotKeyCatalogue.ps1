[CmdletBinding(DefaultParameterSetName = 'ClassFiles')]
param(
    [Parameter(Mandatory, ParameterSetName = 'ClassFiles')]
    [string]$JavapPath,

    [Parameter(Mandatory, ParameterSetName = 'ClassFiles')]
    [string[]]$ClassPath,

    [Parameter(Mandatory, ParameterSetName = 'Disassembly')]
    [string[]]$DisassemblyPath,

    [Parameter(Mandatory)]
    [string]$ControlsPath,

    [string]$LocalizedControlsPath,

    [ValidateRange(1, 65535)]
    [int]$LocalizedControlsCodePage = 1252,

    [string[]]$SettingsPath = @(),

    [string]$BaselineCataloguePath,

    [string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RequiredFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description introuvable : $Path"
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Get-SourceDescriptor {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Kind
    )

    $item = Get-Item -LiteralPath $Path
    return [PSCustomObject]@{
        kind = $Kind
        name = $item.Name
        length = $item.Length
        sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
    }
}

function Read-ControlLabels {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateRange(1, 65535)]
        [int]$CodePage = 65001
    )

    $labels = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
    $encoding = [Text.Encoding]::GetEncoding($CodePage)
    foreach ($line in [IO.File]::ReadAllLines($Path, $encoding)) {
        if ($line -match '^\s*([^#!\s:=]+)(?:\s*[:=]\s*|\s+)(.*)$') {
            $labels[$Matches[1]] = $Matches[2].Trim()
        }
    }

    return $labels
}

function Read-SettingsBindings {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$SampleId
    )

    $environment = $null
    $bindings = [Collections.Generic.List[object]]::new()

    foreach ($rawLine in Get-Content -LiteralPath $Path) {
        $line = $rawLine.Trim()
        if ($line -match '^\[HotKey\s+(.+)\]$') {
            $environment = $Matches[1]
            continue
        }

        if ($line -match '^\[') {
            $environment = $null
            continue
        }

        if ([string]::IsNullOrWhiteSpace($environment) -or
            [string]::IsNullOrWhiteSpace($line) -or
            $line.StartsWith(';') -or
            $line.StartsWith('#')) {
            continue
        }

        $separator = $line.IndexOf('=')
        if ($separator -lt 1 -or $separator -eq ($line.Length - 1)) {
            continue
        }

        $bindings.Add([PSCustomObject]@{
            sampleId = $SampleId
            environment = $environment
            gesture = $line.Substring(0, $separator).Trim()
            command = $line.Substring($separator + 1).Trim()
        })
    }

    return @($bindings)
}

function Read-HotKeyRegistrations {
    param(
        [Parameter(Mandatory)]
        [string[]]$Lines,

        [Parameter(Mandatory)]
        [string]$SourceName
    )

    $method = $null
    $currentEnvironment = $null
    $pendingString = $null
    $registration = $null
    $registrations = [Collections.Generic.List[object]]::new()

    foreach ($line in $Lines) {
        if ($line -match '^\s{2}(?:public|private|protected).*?([A-Za-z0-9_$.]+)\([^;]*\);$') {
            $method = $Matches[1]
            $currentEnvironment = $null
            $pendingString = $null
            $registration = $null
            continue
        }

        if ($line -match '// String(?: )?(.*)$') {
            $value = $Matches[1]
            if ($null -ne $registration) {
                $registration.strings.Add($value)
            }
            else {
                $pendingString = $value
            }
        }

        if ($line -match 'HotKeyCmdEnv\.setCurrentEnv') {
            $currentEnvironment = $pendingString
        }

        if ($line -match '^\s*\d+: new\s+#[0-9]+\s+// class ([^ ]+\$[^ ]+)$') {
            $registration = [PSCustomObject]@{
                environment = if ([string]::IsNullOrWhiteSpace($currentEnvironment)) {
                    $pendingString
                }
                else {
                    $currentEnvironment
                }
                className = $Matches[1].Replace('/', '.')
                strings = [Collections.Generic.List[string]]::new()
                constructor = $null
            }
            continue
        }

        if ($null -ne $registration -and
            $line -match 'invokespecial.*"<init>":(.*)$') {
            $registration.constructor = $Matches[1]
        }

        if ($null -eq $registration -or $line -notmatch 'HotKeyCmdEnv\.addCmd') {
            continue
        }

        $strings = @($registration.strings)
        if ($strings.Count -gt 0 -and
            -not [string]::IsNullOrWhiteSpace($registration.environment)) {
            $fireStyle = $registration.className -match '\$(?:HotKeyCmdFire|HotKeyCmdFireMove)$'
            $command = if ($fireStyle) { $strings[-1] } else { $strings[0] }
            $sortKey = if ($strings.Count -gt 1) {
                if ($fireStyle) { $strings[0] } else { $strings[-1] }
            }
            else {
                $null
            }

            $registrations.Add([PSCustomObject]@{
                environment = [string]$registration.environment
                command = [string]$command
                sortKey = $sortKey
                source = $SourceName
                method = $method
                className = $registration.className
                constructor = $registration.constructor
            })
        }

        $registration = $null
    }

    return @($registrations)
}

$resolvedControls = Resolve-RequiredFile -Path $ControlsPath -Description 'Catalogue controls.properties'
$labels = Read-ControlLabels -Path $resolvedControls
$localizedLabels = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
$sourceDescriptors = [Collections.Generic.List[object]]::new()
$sourceDescriptors.Add((Get-SourceDescriptor -Path $resolvedControls -Kind 'controls'))
if (-not [string]::IsNullOrWhiteSpace($LocalizedControlsPath)) {
    $resolvedLocalizedControls = Resolve-RequiredFile `
        -Path $LocalizedControlsPath `
        -Description 'Catalogue controls.properties localise'
    $localizedLabels = Read-ControlLabels `
        -Path $resolvedLocalizedControls `
        -CodePage $LocalizedControlsCodePage
    $sourceDescriptors.Add((Get-SourceDescriptor -Path $resolvedLocalizedControls -Kind 'localized-controls'))
}
$registrations = [Collections.Generic.List[object]]::new()

if ($PSCmdlet.ParameterSetName -eq 'ClassFiles') {
    $resolvedJavap = Resolve-RequiredFile -Path $JavapPath -Description 'Outil javap'
    foreach ($candidate in $ClassPath) {
        $resolvedClass = Resolve-RequiredFile -Path $candidate -Description 'Classe Java'
        $sourceDescriptors.Add((Get-SourceDescriptor -Path $resolvedClass -Kind 'class'))
        $lines = @(& $resolvedJavap -p -c $resolvedClass 2>&1 | Where-Object {
            -not [string]::IsNullOrEmpty($_)
        })
        if ($LASTEXITCODE -ne 0) {
            throw "javap n'a pas pu analyser $resolvedClass"
        }

        foreach ($item in Read-HotKeyRegistrations -Lines $lines -SourceName ([IO.Path]::GetFileName($resolvedClass))) {
            $registrations.Add($item)
        }
    }
}
else {
    foreach ($candidate in $DisassemblyPath) {
        $resolvedDisassembly = Resolve-RequiredFile -Path $candidate -Description 'Desassemblage javap'
        $sourceDescriptors.Add((Get-SourceDescriptor -Path $resolvedDisassembly -Kind 'disassembly'))
        $lines = @(Get-Content -LiteralPath $resolvedDisassembly | Where-Object {
            -not [string]::IsNullOrEmpty($_)
        })
        foreach ($item in Read-HotKeyRegistrations -Lines $lines -SourceName ([IO.Path]::GetFileName($resolvedDisassembly))) {
            $registrations.Add($item)
        }
    }
}

$settingsDescriptors = [Collections.Generic.List[object]]::new()
$bindings = [Collections.Generic.List[object]]::new()
foreach ($candidate in $SettingsPath) {
    $resolvedSettings = Resolve-RequiredFile -Path $candidate -Description 'settings.ini'
    $descriptor = Get-SourceDescriptor -Path $resolvedSettings -Kind 'settings'
    $sampleId = 'settings-' + $descriptor.sha256.Substring(0, 12).ToLowerInvariant()
    $sampleBindings = @(Read-SettingsBindings -Path $resolvedSettings -SampleId $sampleId)
    $settingsDescriptors.Add([PSCustomObject]@{
        kind = $descriptor.kind
        name = $descriptor.name
        length = $descriptor.length
        sha256 = $descriptor.sha256
        sampleId = $sampleId
        bindingCount = $sampleBindings.Count
    })
    foreach ($binding in $sampleBindings) {
        $bindings.Add($binding)
    }
}

$baselineKeys = $null
if (-not [string]::IsNullOrWhiteSpace($BaselineCataloguePath)) {
    $resolvedBaseline = Resolve-RequiredFile -Path $BaselineCataloguePath -Description 'Catalogue de base'
    $sourceDescriptors.Add((Get-SourceDescriptor -Path $resolvedBaseline -Kind 'baseline'))
    $baseline = Get-Content -LiteralPath $resolvedBaseline -Raw | ConvertFrom-Json
    $baselineKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($command in @($baseline.commands)) {
        [void]$baselineKeys.Add(([string]$command.environment + [char]31 + [string]$command.id))
    }
}

$registrationMap = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
foreach ($registrationItem in $registrations) {
    $key = $registrationItem.environment + [char]31 + $registrationItem.command
    if (-not $registrationMap.ContainsKey($key)) {
        $registrationMap[$key] = [PSCustomObject]@{
            environment = $registrationItem.environment
            id = $registrationItem.command
            sortKey = $registrationItem.sortKey
            sources = [Collections.Generic.List[object]]::new()
        }
    }

    $registrationMap[$key].sources.Add([PSCustomObject]@{
        file = $registrationItem.source
        method = $registrationItem.method
        className = $registrationItem.className
        constructor = $registrationItem.constructor
    })
}

$bindingMap = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
foreach ($binding in $bindings) {
    $key = $binding.environment + [char]31 + $binding.command
    if (-not $bindingMap.ContainsKey($key)) {
        $bindingMap[$key] = [Collections.Generic.List[object]]::new()
    }
    $bindingMap[$key].Add($binding)
}

$allKeys = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($key in $registrationMap.Keys) { [void]$allKeys.Add($key) }
foreach ($key in $bindingMap.Keys) { [void]$allKeys.Add($key) }

$commands = [Collections.Generic.List[object]]::new()
$axisLogicalRanges = @{
    power = [PSCustomObject]@{ minimum = 0.0; maximum = 1.1 }
    flaps = [PSCustomObject]@{ minimum = 0.0; maximum = 1.0 }
    aileron = [PSCustomObject]@{ minimum = -1.0; maximum = 1.0 }
    elevator = [PSCustomObject]@{ minimum = -1.0; maximum = 1.0 }
    rudder = [PSCustomObject]@{ minimum = -1.0; maximum = 1.0 }
    brakes = [PSCustomObject]@{ minimum = 0.0; maximum = 1.0 }
    pitch = [PSCustomObject]@{ minimum = 0.0; maximum = 1.0 }
    trimaileron = [PSCustomObject]@{ minimum = -0.5; maximum = 0.5 }
    trimelevator = [PSCustomObject]@{ minimum = -0.5; maximum = 0.5 }
    trimrudder = [PSCustomObject]@{ minimum = -0.5; maximum = 0.5 }
}
foreach ($key in $allKeys) {
    $separator = $key.IndexOf([char]31)
    $environment = $key.Substring(0, $separator)
    $id = $key.Substring($separator + 1)
    $registered = $registrationMap.ContainsKey($key)
    $commandBindings = @()
    if ($bindingMap.ContainsKey($key)) {
        $commandBindings = @($bindingMap[$key])
    }
    $registrationSources = @()
    if ($registered) {
        $registrationSources = @($registrationMap[$key].sources)
    }
    $labelLookupId = if ($environment -eq 'move' -and $id.StartsWith('-')) {
        $id.TrimStart('-')
    }
    else {
        $id
    }
    $label = if ($labels.ContainsKey($labelLookupId)) { $labels[$labelLookupId] } else { $null }
    $localizedLabel = if ($localizedLabels.ContainsKey($labelLookupId)) {
        $localizedLabels[$labelLookupId]
    }
    else {
        $null
    }
    $visibility = if ($id.StartsWith('$') -or $environment.StartsWith('$$$')) {
        'internal'
    }
    elseif ([string]::IsNullOrWhiteSpace($label)) {
        'needs-label'
    }
    else {
        'public'
    }
    $origin = if ($null -eq $baselineKeys) {
        'unclassified'
    }
    elseif ($baselineKeys.Contains($key)) {
        'historical'
    }
    else {
        'added'
    }
    $isAxis = $environment -eq 'move'
    $axisBaseId = if ($isAxis) { $id.TrimStart('-') } else { $null }
    $logicalRange = if ($isAxis -and $axisLogicalRanges.ContainsKey($axisBaseId)) {
        $axisLogicalRanges[$axisBaseId]
    }
    else {
        $null
    }

    $commands.Add([PSCustomObject]@{
        environment = $environment
        id = $id
        sortKey = if ($registered) { $registrationMap[$key].sortKey } else { $null }
        label = $label
        localizedLabel = $localizedLabel
        visibility = $visibility
        origin = $origin
        registrationStatus = if ($registered) { 'registered' } else { 'settings-only' }
        bindingKind = if ($isAxis) { 'axis' } else { 'button' }
        inputMinimum = if ($isAxis) { -1.0 } else { 0 }
        inputMaximum = 1.0
        logicalMinimum = if ($null -ne $logicalRange) { $logicalRange.minimum } else { $null }
        logicalMaximum = if ($null -ne $logicalRange) { $logicalRange.maximum } else { $null }
        inverted = $isAxis -and $id.StartsWith('-')
        bound = $commandBindings.Count -gt 0
        sampleBindings = @($commandBindings | Sort-Object sampleId, gesture)
        registrations = $registrationSources
    })
}

$commands = @($commands | Sort-Object environment, sortKey, id)
$catalogue = [PSCustomObject]@{
    schemaVersion = 1
    extraction = 'static-javap'
    originClassification = if ($null -eq $baselineKeys) { 'pending-baseline' } else { 'baseline-comparison' }
    sources = [PSCustomObject]@{
        staticInputs = @($sourceDescriptors)
        settingsSamples = @($settingsDescriptors)
    }
    summary = [PSCustomObject]@{
        registrations = $registrations.Count
        commands = $commands.Count
        publicCommands = @($commands | Where-Object visibility -eq 'public').Count
        internalCommands = @($commands | Where-Object visibility -eq 'internal').Count
        commandsNeedingLabel = @($commands | Where-Object visibility -eq 'needs-label').Count
        boundCommands = @($commands | Where-Object bound).Count
        settingsOnlyCommands = @($commands | Where-Object registrationStatus -eq 'settings-only').Count
        historicalCommands = @($commands | Where-Object origin -eq 'historical').Count
        addedCommands = @($commands | Where-Object origin -eq 'added').Count
    }
    limitations = @(
        'Les classes Java sont desassemblees sans etre chargees ni executees.',
        'Un settings.ini ne contient que les commandes deja affectees.',
        'La distinction historique/ajoute exige un catalogue de base produit avec la meme methode.'
    )
    commands = $commands
}

$json = $catalogue | ConvertTo-Json -Depth 12
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
    $parent = Split-Path -Parent $resolvedOutput
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "Dossier de sortie introuvable : $parent"
    }
    [IO.File]::WriteAllText($resolvedOutput, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}

$json
