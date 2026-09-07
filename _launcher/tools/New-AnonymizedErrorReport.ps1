[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
    [string]$InputPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Json')]
    [string]$InputJson,

    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string]$GameVersion = '4.09m',
    [string]$LauncherVersion = '0.1.0',

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ManifestSha256,

    [string]$ProfileId = 'open-sturmovik-409m-classic',
    [Guid]$SessionId = [Guid]::NewGuid(),
    [switch]$IncludeEnvironment
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$allowedEventTypes = @(
    'missing-texture', 'missing-sound', 'missing-resource', 'java-exception',
    'native-crash', 'integrity-failure', 'startup-error', 'graphics-error',
    'audio-error', 'other'
)
$allowedSeverities = @('info', 'warning', 'error', 'fatal')
$allowedResourceKinds = @('texture', 'sound', 'effect', 'mesh', 'class', 'config', 'other')

function Get-OptionalProperty {
    param($Object, [string]$Name, $Default = $null)

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $Default }
    return $property.Value
}

function Limit-Text {
    param([string]$Value, [int]$Maximum)

    if ($null -eq $Value) { return $null }
    if ($Value.Length -le $Maximum) { return $Value }
    return $Value.Substring(0, $Maximum)
}

function Protect-Text {
    param([string]$Value)

    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    $protected = $Value
    $knownValues = [ordered]@{
        '<game>' = $resolvedGameRoot
        '<user-profile>' = [Environment]::GetFolderPath('UserProfile')
        '<user-name>' = [Environment]::UserName
        '<machine-name>' = [Environment]::MachineName
    }
    foreach ($replacement in $knownValues.Keys) {
        $known = [string]$knownValues[$replacement]
        if (-not [string]::IsNullOrWhiteSpace($known)) {
            $protected = $protected.Replace($known, $replacement)
        }
    }

    $protected = [regex]::Replace(
        $protected,
        '(?i)https?://[^\s"''<>]+',
        '<url>'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?i)\b[A-Z]:\\[^\r\n\t"''<>]*',
        '<absolute-path>'
    )
    $protected = [regex]::Replace(
        $protected,
        '\\\\[^\\\s]+\\[^\r\n\t"''<>]*',
        '<network-path>'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?<![0-9])(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?![0-9])',
        '<ip-address>'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?i)\bport\s*[:=]?\s*[0-9]{1,5}\b',
        'port <port>'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?<=<ip-address>):[0-9]{1,5}\b',
        ':<port>'
    )
    $protected = [regex]::Replace(
        $protected,
        '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        '<email>'
    )
    return $protected
}

function Normalize-ResourcePath {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $candidate = $Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
    if ([IO.Path]::IsPathRooted($candidate)) {
        $full = [IO.Path]::GetFullPath($candidate)
        $rootPrefix = $resolvedGameRoot.TrimEnd('\') + '\'
        if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $candidate = $full.Substring($rootPrefix.Length)
        }
        else {
            return 'external-resource'
        }
    }

    $segments = @($candidate -split '[\\/]' | Where-Object { $_ -and $_ -ne '.' })
    if ($segments -contains '..') { return 'invalid-resource-path' }
    $relative = $segments -join '/'
    return Limit-Text (Protect-Text $relative) 512
}

function Get-Sha256Text {
    param([string]$Value)

    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$resolvedGameRoot = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$rawText = if ($PSCmdlet.ParameterSetName -eq 'Path') {
    Get-Content -LiteralPath $InputPath -Raw
}
else {
    $InputJson
}
$raw = $rawText | ConvertFrom-Json

$eventType = [string](Get-OptionalProperty $raw 'eventType')
$severity = [string](Get-OptionalProperty $raw 'severity')
if ($eventType -notin $allowedEventTypes) { throw "Type d evenement interdit : $eventType" }
if ($severity -notin $allowedSeverities) { throw "Severite interdite : $severity" }

$resourceKind = [string](Get-OptionalProperty $raw 'resourceKind')
if ($resourceKind -and $resourceKind -notin $allowedResourceKinds) {
    throw "Type de ressource interdit : $resourceKind"
}
$resourcePath = Normalize-ResourcePath ([string](Get-OptionalProperty $raw 'resourcePath'))
$errorCode = Limit-Text (Protect-Text ([string](Get-OptionalProperty $raw 'errorCode'))) 128
$message = Limit-Text (Protect-Text ([string](Get-OptionalProperty $raw 'message'))) 1000
$module = [IO.Path]::GetFileName([string](Get-OptionalProperty $raw 'module'))
if ($module -and $module -notmatch '^[A-Za-z0-9_.-]{1,128}$') { $module = 'unknown-module' }
$occurrences = [int](Get-OptionalProperty $raw 'occurrences' 1)
if ($occurrences -lt 1) { $occurrences = 1 }
if ($occurrences -gt 1000000) { $occurrences = 1000000 }

$event = [ordered]@{
    type = $eventType
    severity = $severity
    occurrences = $occurrences
}
if ($resourceKind) { $event.resourceKind = $resourceKind }
if ($resourcePath) { $event.resourcePath = $resourcePath }
if ($errorCode) { $event.errorCode = $errorCode }
if ($message) { $event.message = $message }
if ($module) { $event.module = $module }

$rawStack = @(Get-OptionalProperty $raw 'stack' @())
if ($rawStack.Count -gt 0) {
    $safeStack = New-Object System.Collections.Generic.List[object]
    foreach ($frame in @($rawStack | Select-Object -First 64)) {
        $frameModule = [IO.Path]::GetFileName([string](Get-OptionalProperty $frame 'module'))
        $offset = [string](Get-OptionalProperty $frame 'offset')
        if ($frameModule -notmatch '^[A-Za-z0-9_.-]{1,128}$' -or $offset -notmatch '^0x[0-9A-Fa-f]{1,16}$') {
            continue
        }
        $safeFrame = [ordered]@{ module = $frameModule; offset = $offset }
        $symbol = Limit-Text (Protect-Text ([string](Get-OptionalProperty $frame 'symbol'))) 256
        if ($symbol) { $safeFrame.symbol = $symbol }
        $safeStack.Add($safeFrame)
    }
    if ($safeStack.Count -gt 0) { $event['stack'] = $safeStack.ToArray() }
}

$rawJavaStack = @(Get-OptionalProperty $raw 'javaStack' @())
if ($rawJavaStack.Count -gt 0) {
    $safeJavaStack = New-Object System.Collections.Generic.List[object]
    foreach ($frame in @($rawJavaStack | Select-Object -First 64)) {
        $className = [string](Get-OptionalProperty $frame 'class')
        $methodName = [string](Get-OptionalProperty $frame 'method')
        if ($className -notmatch '^[A-Za-z0-9_.$]{1,256}$' -or
            $methodName -notmatch '^[A-Za-z0-9_$<>]{1,128}$') {
            continue
        }
        $safeFrame = [ordered]@{ class = $className; method = $methodName }
        $source = [IO.Path]::GetFileName([string](Get-OptionalProperty $frame 'source'))
        if ($source -match '^[A-Za-z0-9_.-]{1,128}$') { $safeFrame.source = $source }
        $line = [int](Get-OptionalProperty $frame 'line' 0)
        if ($line -gt 0) { $safeFrame.line = $line }
        $safeJavaStack.Add($safeFrame)
    }
    if ($safeJavaStack.Count -gt 0) { $event['javaStack'] = $safeJavaStack.ToArray() }
}

$occurred = Get-OptionalProperty $raw 'occurredAtUtc'
if ($occurred) {
    $occurredAt = ([DateTimeOffset]::Parse([string]$occurred)).ToUniversalTime()
}
else {
    $occurredAt = [DateTimeOffset]::UtcNow
}
$occurredAt = [DateTimeOffset]::new(
    $occurredAt.Year, $occurredAt.Month, $occurredAt.Day,
    $occurredAt.Hour, $occurredAt.Minute, $occurredAt.Second,
    [TimeSpan]::Zero
)

$fingerprintSource = @(
    $eventType,
    $severity,
    $resourceKind,
    $resourcePath,
    $errorCode,
    $module,
    $message,
    $(if ($event.Contains('javaStack')) {
        @($event.javaStack | Select-Object -First 3 | ForEach-Object {
            "$($_.class).$($_.method)"
        }) -join ';'
    })
) -join '|'

$report = [ordered]@{
    schemaVersion = 1
    reportId = [Guid]::NewGuid().ToString()
    sessionId = $SessionId.ToString()
    occurredAtUtc = $occurredAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    product = [ordered]@{
        gameVersion = Limit-Text $GameVersion 32
        launcherVersion = Limit-Text $LauncherVersion 32
        manifestSha256 = $ManifestSha256.ToUpperInvariant()
        profileId = $ProfileId
    }
    event = $event
    fingerprint = Get-Sha256Text $fingerprintSource
    privacy = [ordered]@{
        policyVersion = 1
        rawLogIncluded = $false
        memoryDumpIncluded = $false
        redactions = @(
            'user-name', 'machine-name', 'absolute-path', 'ip-address',
            'email', 'server', 'port'
        )
    }
}

if ($IncludeEnvironment) {
    $osVersion = [Environment]::OSVersion.Version
    $report['environment'] = [ordered]@{
        osFamily = 'Windows'
        osVersion = $osVersion.ToString()
        architecture = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
        locale = [Globalization.CultureInfo]::CurrentUICulture.Name
    }
}

$report | ConvertTo-Json -Depth 12
