[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Output,
    [Parameter(Mandatory = $true)][string]$StopFile
)

$ErrorActionPreference = 'Stop'
$resolvedOutput = [IO.Path]::GetFullPath($Output)
$resolvedStop = [IO.Path]::GetFullPath($StopFile)
$sets = @(Get-Counter -ListSet '*' -ErrorAction Stop)
$processorSet = $sets | Where-Object { $_.CounterSetName -match '^(Processor|Processeur)$' } | Select-Object -First 1
$diskSet = $sets | Where-Object { $_.CounterSetName -match '^(PhysicalDisk|Physical Disk|Disque physique)$' } | Select-Object -First 1
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
if ($paths.Count -lt 8) {
    throw "Jeu de compteurs incomplet : $($paths.Count) chemins."
}

$directory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$writer = New-Object IO.StreamWriter($resolvedOutput, $false, (New-Object Text.UTF8Encoding($false)))
try {
    $writer.AutoFlush = $true
    $writer.WriteLine('utc,path,instance,cooked_value,status')
    while (-not (Test-Path -LiteralPath $resolvedStop -PathType Leaf)) {
        $sample = Get-Counter -Counter $paths -MaxSamples 1 -ErrorAction Stop
        $utc = $sample.Timestamp.ToUniversalTime().ToString('O')
        foreach ($counter in $sample.CounterSamples) {
            $path = ([string]$counter.Path).Replace('"','""')
            $instance = ([string]$counter.InstanceName).Replace('"','""')
            $value = ([double]$counter.CookedValue).ToString('R', [Globalization.CultureInfo]::InvariantCulture)
            $writer.WriteLine(('"{0}","{1}","{2}",{3},{4}' -f $utc, $path, $instance, $value, $counter.Status))
        }
    }
}
finally {
    $writer.Dispose()
}
