[CmdletBinding()]
param()
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$sender = Join-Path $PSScriptRoot 'Send-OpenSturmovikDiagnostic.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('open-sturmovik-transport-' + [Guid]::NewGuid().ToString('N'))
$transportTestState = @{ Calls = 0; Scenario = 'offline' }
function Assert-Transport { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } }
function Invoke-RestMethod {
    param($Method, $Uri, $TimeoutSec, $MaximumRedirection, $Headers, $UserAgent, $ContentType, $Body)
    $transportTestState.Calls++
    Assert-Transport ($Uri -eq 'https://androlink-feedback.alex-baujard.workers.dev/api/open-sturmovik/diagnostic') 'fixed service endpoint'
    Assert-Transport (-not $Headers.ContainsKey('Authorization')) 'no client GitHub credential'
    Assert-Transport ($Headers['X-Open-Sturmovik-Diagnostic'] -eq '1') 'recognized client header'
    Assert-Transport ($UserAgent -eq 'Open-Sturmovik/1.15') 'versioned client'
    Assert-Transport ($Body -is [byte[]]) 'explicit UTF-8 bytes'
    $payload = [Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    Assert-Transport ($payload.body.Contains([string][char]0x00e9)) 'accents preserved'
    Assert-Transport ($payload.comments.Count -eq 1) 'log excerpts preserved'
    if ($transportTestState.Scenario -eq 'offline') { throw 'Synthetic connection failure' }
    return [pscustomobject]@{
        ok = $true
        completed = ($transportTestState.Scenario -ne 'incomplete')
        reportId = if ($transportTestState.Scenario -eq 'wrong-id') { 'b' * 32 } else { $payload.reportId }
        issueNumber = 42
        url = if ($transportTestState.Scenario -eq 'wrong-url') { 'https://github.com/other/repo/issues/42' } else { 'https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/issues/42' }
        created = $true
    }
}
try {
    New-Item -ItemType Directory -Path $root -Force | Out-Null
    $reportPath = Join-Path $root 'pending.json'
    $state = Join-Path $root 'state'
    $report = [ordered]@{
        report_id = 'a' * 32; signature = 'c' * 64; ended_utc = '2026-09-12T00:00:00Z'
        release = '1.15'; category = 'test'; severity = 'warning'; summary = ('Test synth' + [char]0x00e9 + 'tique')
        profile = @{ label = 'synthetic'; exe_sha256 = ''; files_sha256 = ''; wrapper_sha256 = '' }
        process = @{ exit_code = 1; duration_seconds = 5; max_unresponsive_seconds = 0 }
        environment = @{}; findings = @(); dumps = @(); affected_resources = @()
        sources = @(@{ name = 'synthetic.log'; lines = @('TEST ONLY') })
    }
    [IO.File]::WriteAllText($reportPath, ($report | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    foreach ($scenario in @('offline', 'wrong-id', 'incomplete', 'wrong-url')) {
        $transportTestState.Scenario = $scenario
        $failed = $false
        try { & $sender -ReportPath $reportPath -StateRoot $state | Out-Null } catch { $failed = $true }
        Assert-Transport $failed "reject $scenario"
        Assert-Transport (Test-Path -LiteralPath $reportPath) "retain queue on $scenario"
        Assert-Transport (-not (Test-Path -LiteralPath (Join-Path $state ('Sent\' + ('a' * 32) + '.json')))) 'no false receipt'
    }
    $transportTestState.Scenario = 'success'
    $sent = & $sender -ReportPath $reportPath -StateRoot $state -KeepReport
    Assert-Transport ($sent.Status -eq 'ISSUE_CREATED') 'successful receipt'
    Assert-Transport (Test-Path -LiteralPath $sent.SentRecord) 'receipt persisted'
    $callsBefore = $transportTestState.Calls
    $again = & $sender -ReportPath $reportPath -StateRoot $state
    Assert-Transport ($again.Status -eq 'ALREADY_SENT') 'skip a received report'
    Assert-Transport ($transportTestState.Calls -eq $callsBefore) 'no duplicate network send'
    Assert-Transport (-not (Test-Path -LiteralPath $reportPath)) 'queue cleared only after confirmed delivery'
    [pscustomobject]@{ Status = 'PASS'; Scenarios = 6; CredentialFree = $true; Utf8 = $true; QueueRecovery = $true }
} finally {
    $verified = [IO.Path]::GetFullPath($root)
    $tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if ($verified.StartsWith($tempPrefix, [StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($verified).StartsWith('open-sturmovik-transport-')) {
        Remove-Item -LiteralPath $verified -Recurse -Force -ErrorAction SilentlyContinue
    }
}