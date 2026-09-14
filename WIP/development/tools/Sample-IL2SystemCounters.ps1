[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Output,
    [Parameter(Mandatory = $true)][string]$StopFile,
    [Parameter(Mandatory = $true)][ValidateRange(1, 2147483647)][int]$ProcessId
)

$ErrorActionPreference = 'Stop'
$resolvedOutput = [IO.Path]::GetFullPath($Output)
$resolvedStop = [IO.Path]::GetFullPath($StopFile)
$sets = @(Get-Counter -ListSet '*' -ErrorAction Stop)
$processorSet = $sets | Where-Object { $_.CounterSetName -match '^(Processor|Processeur)$' } | Select-Object -First 1
$processorInformationSet = $sets | Where-Object { $_.CounterSetName -match '^(Processor Information|Informations sur le processeur)$' } | Select-Object -First 1
$diskSet = $sets | Where-Object { $_.CounterSetName -match '^(PhysicalDisk|Physical Disk|Disque physique)$' } | Select-Object -First 1
$memorySet = $sets | Where-Object { $_.CounterSetName -match '^(Memory|Memoire|Mémoire)$' } | Select-Object -First 1
$gpuEngineSet = $sets | Where-Object { $_.CounterSetName -eq 'GPU Engine' } | Select-Object -First 1
$gpuProcessMemorySet = $sets | Where-Object { $_.CounterSetName -eq 'GPU Process Memory' } | Select-Object -First 1
$gpuAdapterMemorySet = $sets | Where-Object { $_.CounterSetName -eq 'GPU Adapter Memory' } | Select-Object -First 1
if (-not $processorSet -or -not $diskSet) {
    throw 'Compteurs processeur ou disque physique introuvables.'
}

$paths = @()
$paths += $processorSet.Paths | Where-Object {
    $_ -match '(?i)(% Processor Time|% temps processeur|% User Time|% temps utilisateur|% Privileged Time|% temps privilégié|Interrupts/sec|Interruptions/s)$'
}
$paths += $diskSet.Paths | Where-Object {
    $_ -match '(?i)(Disk Read Bytes/sec|Lectures disque, octets/s|Disk Write Bytes/sec|Écritures disque, octets/s|Current Disk Queue Length|Taille de file d.attente du disque actuelle|% Disk Time|Pourcentage du temps disque)$'
}
$paths += @($processorInformationSet.Paths) | Where-Object {
    $_ -match '(?i)(% Processor Performance|Pourcentage de rendement du processeur|% of Maximum Frequency|% de la fréquence maximale)$'
}
$paths += @($memorySet.Paths) | Where-Object {
    $_ -match '(?i)(Available Bytes|Octets disponibles|Committed Bytes|Octets validés|Commit Limit|Limite de mémoire dédiée|Pages Input/sec|Entrées de pages/s|Page Reads/sec|Lectures de pages/s)$'
}
$paths += @($gpuAdapterMemorySet.Paths) | Where-Object {
    $_ -match '(?i)(Dedicated Usage|Shared Usage|Total Committed)$'
}
$paths = @($paths | Sort-Object -Unique)
if ($paths.Count -lt 8) {
    throw "Jeu de compteurs incomplet : $($paths.Count) chemins."
}

$directory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$writer = New-Object IO.StreamWriter($resolvedOutput, $false, (New-Object Text.UTF8Encoding($false)))
try {
    $writer.AutoFlush = $true
    $writer.WriteLine('utc,path,instance,cooked_value,status,target_pid')
    $gpuTargetPaths = @()
    $nextGpuDiscovery = [DateTime]::MinValue
    while (-not (Test-Path -LiteralPath $resolvedStop -PathType Leaf)) {
        if ([DateTime]::UtcNow -ge $nextGpuDiscovery) {
            $nextGpuDiscovery = [DateTime]::UtcNow.AddSeconds(5)
            $gpuPrefix = '^\\GPU (Engine|Process Memory)\(pid_' + $ProcessId + '_'
            $discoveredGpuPaths = @()
            foreach ($gpuSetName in @('GPU Engine','GPU Process Memory')) {
                try {
                    $discoveredGpuPaths += (Get-Counter -ListSet $gpuSetName -ErrorAction Stop).PathsWithInstances |
                        Where-Object {
                            $_ -match $gpuPrefix -and
                            $_ -match '(?i)(Utilization Percentage|Running Time|Dedicated Usage|Shared Usage|Total Committed|Local Usage|Non Local Usage)$'
                        }
                }
                catch { }
            }
            $gpuTargetPaths = @($discoveredGpuPaths | Sort-Object -Unique)
        }

        $activePaths = @($paths) + @($gpuTargetPaths)
        try {
            $sample = Get-Counter -Counter $activePaths -MaxSamples 1 -ErrorAction Stop
        }
        catch {
            if ($gpuTargetPaths.Count -eq 0) { throw }
            $gpuTargetPaths = @()
            $sample = Get-Counter -Counter $paths -MaxSamples 1 -ErrorAction Stop
        }
        $utc = $sample.Timestamp.ToUniversalTime().ToString('O')
        foreach ($counter in $sample.CounterSamples) {
            $path = ([string]$counter.Path).Replace('"','""')
            $instance = ([string]$counter.InstanceName).Replace('"','""')
            $value = ([double]$counter.CookedValue).ToString('R', [Globalization.CultureInfo]::InvariantCulture)
            $writer.WriteLine(('"{0}","{1}","{2}",{3},{4},{5}' -f $utc, $path, $instance, $value, $counter.Status, $ProcessId))
        }
    }
}
finally {
    $writer.Dispose()
}
