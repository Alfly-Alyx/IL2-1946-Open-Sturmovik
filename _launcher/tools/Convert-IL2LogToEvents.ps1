[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [string]$PatternManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $PatternManifestPath) {
    $launcherRoot = Split-Path -Parent $PSScriptRoot
    $PatternManifestPath = Join-Path $launcherRoot 'manifests\diagnostic-patterns.json'
}

$resolvedLog = (Resolve-Path -LiteralPath $LogPath).Path
$patterns = (Get-Content -LiteralPath $PatternManifestPath -Raw | ConvertFrom-Json).patterns
$lines = @(Get-Content -LiteralPath $resolvedLog)
$events = New-Object System.Collections.Generic.List[object]
$eventIndexes = @{}

function Get-MessageText {
    param([string]$Line)

    return ($Line -replace '^\[[^\]]+\]\s*', '').Trim()
}

function Get-MatchValue {
    param([Text.RegularExpressions.Match]$Match, [string]$GroupName)

    if ([string]::IsNullOrWhiteSpace($GroupName)) { return $null }
    $group = $Match.Groups[$GroupName]
    if ($null -eq $group -or -not $group.Success) { return $null }
    return $group.Value.Trim()
}

function Add-RawEvent {
    param([Collections.Specialized.OrderedDictionary]$Event)

    $identity = [ordered]@{}
    foreach ($field in @(
        'eventType', 'severity', 'resourceKind', 'resourcePath',
        'errorCode', 'message', 'module', 'stack', 'javaStack'
    )) {
        if ($Event.Contains($field)) { $identity[$field] = $Event[$field] }
    }
    $key = $identity | ConvertTo-Json -Depth 12 -Compress
    if ($script:eventIndexes.ContainsKey($key)) {
        $index = [int]$script:eventIndexes[$key]
        $existing = $script:events[$index]
        $existing['occurrences'] = [Math]::Min(1000000, [int]$existing['occurrences'] + 1)
        return
    }

    $script:eventIndexes[$key] = $script:events.Count
    $script:events.Add($Event)
}

function New-PatternEvent {
    param($Pattern, [Text.RegularExpressions.Match]$Match, [string]$Message)

    $eventType = [string]$Pattern.eventType
    $resourceKindProperty = $Pattern.PSObject.Properties['resourceKind']
    $resourceKind = if ($resourceKindProperty) { [string]$resourceKindProperty.Value } else { '' }
    $resourceCaptureProperty = $Pattern.PSObject.Properties['resourceCapture']
    $resourceCapture = if ($resourceCaptureProperty) { [string]$resourceCaptureProperty.Value } else { '' }
    $resource = Get-MatchValue $Match $resourceCapture
    $classifier = $Pattern.PSObject.Properties['classifier']
    if ($classifier -and [string]$classifier.Value -eq 'audio-path' -and
        $resource -match '(?i)^(?:music|sound|sounds|samples)(?:[/\\]|$)|\.(?:wav|prs)$') {
        $eventType = 'missing-sound'
        $resourceKind = 'sound'
    }

    $detail = Get-MatchValue $Match 'detail'
    $event = [ordered]@{
        eventType = $eventType
        severity = [string]$Pattern.severity
        occurrences = 1
        errorCode = [string]$Pattern.errorCode
        message = if ($detail) { $detail } else { $Message }
    }
    if ($resourceKind) { $event['resourceKind'] = $resourceKind }
    if ($resource) { $event['resourcePath'] = $resource }
    return $event
}

:lineLoop for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
    $message = Get-MessageText ([string]$lines[$lineIndex])
    if (-not $message) { continue }

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($message, [string]$pattern.regex, 'IgnoreCase,CultureInvariant')
        if ($match.Success) {
            Add-RawEvent (New-PatternEvent $pattern $match $message)
            continue lineLoop
        }
    }

    $exceptionMatch = [regex]::Match(
        $message,
        '^(?<class>(?:[A-Za-z_$][A-Za-z0-9_$]*\.)+[A-Za-z_$][A-Za-z0-9_$]*(?:Exception|Error))(?::\s*(?<detail>.*))?$'
    )
    if (-not $exceptionMatch.Success) { continue }

    $exceptionClass = $exceptionMatch.Groups['class'].Value
    $detail = $exceptionMatch.Groups['detail'].Value.Trim()
    $javaStack = New-Object System.Collections.Generic.List[object]
    $nextIndex = $lineIndex + 1
    while ($nextIndex -lt $lines.Count) {
        $stackText = Get-MessageText ([string]$lines[$nextIndex])
        $stackMatch = [regex]::Match(
            $stackText,
            '^at\s+(?<class>[A-Za-z0-9_.$]+)\.(?<method>[A-Za-z0-9_$<>]+)\((?<location>[^)]*)\)$'
        )
        if (-not $stackMatch.Success) { break }

        $frame = [ordered]@{
            class = $stackMatch.Groups['class'].Value
            method = $stackMatch.Groups['method'].Value
        }
        $location = $stackMatch.Groups['location'].Value
        $locationMatch = [regex]::Match($location, '^(?<source>[^:()]+):(?<line>[0-9]+)$')
        if ($locationMatch.Success) {
            $frame['source'] = [IO.Path]::GetFileName($locationMatch.Groups['source'].Value)
            $frame['line'] = [int]$locationMatch.Groups['line'].Value
        }
        $javaStack.Add($frame)
        $nextIndex++
    }

    $event = [ordered]@{
        eventType = 'java-exception'
        severity = if ($exceptionClass -match '(?:OutOfMemoryError|StackOverflowError)$') { 'fatal' } else { 'error' }
        occurrences = 1
        errorCode = $exceptionClass
        message = if ($detail) { $detail } else { $exceptionClass }
        module = $exceptionClass
    }
    if ($javaStack.Count -gt 0) { $event['javaStack'] = $javaStack.ToArray() }
    Add-RawEvent $event
    if ($nextIndex -gt $lineIndex + 1) { $lineIndex = $nextIndex - 1 }
}

$occurrenceCount = 0
foreach ($event in $events) { $occurrenceCount += [int]$event.occurrences }
[ordered]@{
    schemaVersion = 1
    sourceFile = [IO.Path]::GetFileName($resolvedLog)
    eventCount = $events.Count
    occurrenceCount = $occurrenceCount
    events = $events.ToArray()
} | ConvertTo-Json -Depth 16
