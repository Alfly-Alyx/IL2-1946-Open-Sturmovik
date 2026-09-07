[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
    [string]$ReportPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Json')]
    [string]$ReportJson,

    [string]$GameRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rawReport = if ($PSCmdlet.ParameterSetName -eq 'Path') {
    Get-Content -LiteralPath $ReportPath -Raw
}
else {
    $ReportJson
}
$report = $rawReport | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]

function Add-Error {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Test-Properties {
    param($Object, [string[]]$Allowed, [string]$Context)

    foreach ($property in $Object.PSObject.Properties) {
        if ($property.Name -notin $Allowed) {
            Add-Error "$Context : champ interdit $($property.Name)."
        }
    }
}

Test-Properties $report @(
    'schemaVersion', 'reportId', 'sessionId', 'occurredAtUtc', 'product',
    'event', 'environment', 'fingerprint', 'privacy'
) 'rapport'
Test-Properties $report.product @('gameVersion', 'launcherVersion', 'manifestSha256', 'profileId') 'product'
Test-Properties $report.event @(
    'type', 'severity', 'occurrences', 'resourceKind', 'resourcePath',
    'errorCode', 'message', 'module', 'stack', 'javaStack'
) 'event'
Test-Properties $report.privacy @(
    'policyVersion', 'rawLogIncluded', 'memoryDumpIncluded', 'redactions'
) 'privacy'
if ($report.PSObject.Properties['environment']) {
    Test-Properties $report.environment @(
        'osFamily', 'osVersion', 'architecture', 'locale', 'gpuVendor',
        'gpuDeviceId', 'gpuDriverVersion', 'audioBackend'
    ) 'environment'
}

if ($report.schemaVersion -ne 1) { Add-Error 'schemaVersion doit valoir 1.' }
$parsedGuid = [Guid]::Empty
if (-not [Guid]::TryParse([string]$report.reportId, [ref]$parsedGuid)) { Add-Error 'reportId invalide.' }
if (-not [Guid]::TryParse([string]$report.sessionId, [ref]$parsedGuid)) { Add-Error 'sessionId invalide.' }
$parsedDate = [DateTimeOffset]::MinValue
if (-not [DateTimeOffset]::TryParse([string]$report.occurredAtUtc, [ref]$parsedDate)) {
    Add-Error 'occurredAtUtc invalide.'
}
if ([string]$report.product.manifestSha256 -notmatch '^[0-9A-Fa-f]{64}$') {
    Add-Error 'manifestSha256 invalide.'
}
if ([string]$report.fingerprint -notmatch '^[0-9A-Fa-f]{64}$') {
    Add-Error 'fingerprint invalide.'
}

$eventTypes = @(
    'missing-texture', 'missing-sound', 'missing-resource', 'java-exception',
    'native-crash', 'integrity-failure', 'startup-error', 'graphics-error',
    'audio-error', 'other'
)
if ([string]$report.event.type -notin $eventTypes) { Add-Error 'Type d evenement invalide.' }
if ([string]$report.event.severity -notin @('info', 'warning', 'error', 'fatal')) {
    Add-Error 'Severite invalide.'
}
if ([int]$report.event.occurrences -lt 1 -or [int]$report.event.occurrences -gt 1000000) {
    Add-Error 'Compteur occurrences invalide.'
}

$resourceProperty = $report.event.PSObject.Properties['resourcePath']
if ($resourceProperty) {
    $resource = [string]$resourceProperty.Value
    if ([IO.Path]::IsPathRooted($resource) -or $resource -match '(^|[/\\])\.\.([/\\]|$)') {
        Add-Error 'resourcePath doit rester relatif au jeu.'
    }
}

if ($report.privacy.policyVersion -ne 1) { Add-Error 'policyVersion doit valoir 1.' }
if ([bool]$report.privacy.rawLogIncluded) { Add-Error 'Un journal brut est interdit.' }
if ([bool]$report.privacy.memoryDumpIncluded) { Add-Error 'Un dump memoire automatique est interdit.' }

$serialized = $report | ConvertTo-Json -Depth 20 -Compress
$sensitiveFields = New-Object System.Collections.Generic.List[string]
foreach ($field in @('resourcePath', 'errorCode', 'message', 'module')) {
    $property = $report.event.PSObject.Properties[$field]
    if ($property -and $null -ne $property.Value) {
        $sensitiveFields.Add([string]$property.Value)
    }
}
$stackProperty = $report.event.PSObject.Properties['stack']
$stackFrames = if ($stackProperty) { @($stackProperty.Value) } else { @() }
foreach ($frame in $stackFrames) {
    Test-Properties $frame @('module', 'offset', 'symbol') 'event.stack'
    foreach ($field in @('module', 'symbol')) {
        $property = $frame.PSObject.Properties[$field]
        if ($property -and $null -ne $property.Value) {
            $sensitiveFields.Add([string]$property.Value)
        }
    }
}
$javaStackProperty = $report.event.PSObject.Properties['javaStack']
$javaStackFrames = if ($javaStackProperty) { @($javaStackProperty.Value) } else { @() }
foreach ($frame in $javaStackFrames) {
    Test-Properties $frame @('class', 'method', 'source', 'line') 'event.javaStack'
    foreach ($field in @('class', 'method', 'source')) {
        $property = $frame.PSObject.Properties[$field]
        if ($property -and $null -ne $property.Value) {
            $sensitiveFields.Add([string]$property.Value)
        }
    }
}
if ($report.PSObject.Properties['environment']) {
    $audioBackend = $report.environment.PSObject.Properties['audioBackend']
    if ($audioBackend -and $null -ne $audioBackend.Value) {
        $sensitiveFields.Add([string]$audioBackend.Value)
    }
}
$sensitiveText = $sensitiveFields -join "`n"
$forbiddenPatterns = [ordered]@{
    'adresse IP' = '(?<![0-9])(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?![0-9])'
    'adresse electronique' = '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b'
    'chemin absolu' = '(?i)\b[A-Z]:\\'
    'chemin reseau' = '\\\\[^\\\s]+\\'
}
foreach ($label in $forbiddenPatterns.Keys) {
    if ($sensitiveText -match $forbiddenPatterns[$label]) { Add-Error "Donnee sensible detectee : $label." }
}
foreach ($known in @(
    [Environment]::UserName,
    [Environment]::MachineName,
    [Environment]::GetFolderPath('UserProfile'),
    $GameRoot
)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$known) -and
        $serialized.IndexOf([string]$known, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        Add-Error 'Une valeur locale connue subsiste dans le rapport.'
    }
}

$result = [ordered]@{
    valid = ($errors.Count -eq 0)
    report = if ($PSCmdlet.ParameterSetName -eq 'Path') {
        (Resolve-Path -LiteralPath $ReportPath).Path
    }
    else {
        '<memory>'
    }
    errors = @($errors)
}
$result | ConvertTo-Json -Depth 8
if ($errors.Count -gt 0) { exit 1 }
