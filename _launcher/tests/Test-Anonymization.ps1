[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$tool = Join-Path $launcherRoot 'tools\New-AnonymizedErrorReport.ps1'
$validator = Join-Path $launcherRoot 'tools\Test-ErrorReport.ps1'
$gameRoot = 'C:\Users\SensitiveUser\Games\Open Sturmovik'
$machineName = [Environment]::MachineName
$raw = [ordered]@{
    eventType = 'missing-texture'
    severity = 'error'
    occurrences = 4
    resourceKind = 'texture'
    resourcePath = "$gameRoot\3do\plane\Test\Textures\missing.tga"
    errorCode = 'RESOURCE_NOT_FOUND'
    message = "C:\Users\SensitiveUser\secret@example.com depuis 192.168.1.50:21000 sur $machineName"
    module = 'C:\Users\SensitiveUser\Games\Open Sturmovik\il2_core.dll'
    stack = @(
        [ordered]@{
            module = 'C:\Users\SensitiveUser\Games\Open Sturmovik\il2_core.dll'
            offset = '0x1234'
            symbol = 'Load C:\Users\SensitiveUser\private\asset.tga'
        }
    )
}

$json = $raw | ConvertTo-Json -Depth 8
$output = & $tool `
    -InputJson $json `
    -GameRoot $gameRoot `
    -ManifestSha256 ('A' * 64) `
    -SessionId ([Guid]'11111111-1111-1111-1111-111111111111')
$report = $output | ConvertFrom-Json
$serialized = $report | ConvertTo-Json -Depth 12 -Compress
$forbidden = @('SensitiveUser', 'secret@example.com', '192.168.1.50', $machineName, 'C:\Users')
foreach ($value in $forbidden) {
    if ($serialized.IndexOf($value, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Donnee sensible non retiree : $value"
    }
}
if ($report.event.resourcePath -ne '3do/plane/Test/Textures/missing.tga') {
    throw "Chemin relatif inattendu : $($report.event.resourcePath)"
}
if ($report.event.module -ne 'il2_core.dll') {
    throw "Module inattendu : $($report.event.module)"
}
if ($report.event.stack[0].offset -ne '0x1234') {
    throw 'Offset de pile perdu.'
}
if ($report.privacy.rawLogIncluded -or $report.privacy.memoryDumpIncluded) {
    throw 'Le rapport annonce une piece sensible.'
}
$validationOutput = & $validator -ReportJson $output -GameRoot $gameRoot
$validation = $validationOutput | ConvertFrom-Json
if (-not $validation.valid) {
    throw "Le rapport anonymise ne passe pas sa propre validation : $($validation.errors -join '; ')"
}

[ordered]@{
    passed = $true
    reportValid = [bool]$validation.valid
    fingerprint = [string]$report.fingerprint
    resourcePath = [string]$report.event.resourcePath
    redactions = @($report.privacy.redactions)
} | ConvertTo-Json -Depth 6
