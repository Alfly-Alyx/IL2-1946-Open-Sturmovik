[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
    [string]$RelayUrl = 'https://androlink-feedback.alex-baujard.workers.dev/api/open-sturmovik/diagnostic',
    [switch]$DryRun,
    [switch]$KeepReport
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    throw "Depot GitHub invalide : $Repository"
}
$resolvedReport = (Resolve-Path -LiteralPath $ReportPath -ErrorAction Stop).Path
$resolvedState = [IO.Path]::GetFullPath($StateRoot)
New-Item -ItemType Directory -Path $resolvedState -Force | Out-Null
$report = Get-Content -LiteralPath $resolvedReport -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $report.signature -or -not $report.report_id) {
    throw "Rapport de diagnostic incomplet : $resolvedReport"
}

function Limit-Text {
    param([AllowEmptyString()][string]$Text, [int]$Maximum = 60000)
    if ($null -eq $Text) { return '' }
    if ($Text.Length -le $Maximum) { return $Text }
    return $Text.Substring(0, [Math]::Max(0, $Maximum - 30)) + "`n`n[contenu tronque localement]"
}

function ConvertTo-CodeBlock {
    param([AllowEmptyString()][string]$Text)
    $safe = ([string]$Text).Replace('~~~~', '~ ~ ~ ~')
    return "~~~~text`n$safe`n~~~~"
}

function Get-PropertyValue {
    param($Object, [string]$Name, $Default = '')
    if ($null -eq $Object) { return $Default }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return $Default }
    return $property.Value
}

function New-OccurrenceMarkdown {
    param($Diagnostic, [switch]$IncludeMarker)

    $lines = [Collections.Generic.List[string]]::new()
    if ($IncludeMarker) {
        $lines.Add("<!-- open-sturmovik-signature:$($Diagnostic.signature) -->")
    }
    $lines.Add("Rapport automatique Open Sturmovik ``$($Diagnostic.report_id)``.")
    $lines.Add('')
    $lines.Add('| Champ | Valeur |')
    $lines.Add('|---|---|')
    $lines.Add("| Date UTC | ``$($Diagnostic.ended_utc)`` |")
    $lines.Add("| Categorie | ``$($Diagnostic.category)`` |")
    $lines.Add("| Gravite | ``$($Diagnostic.severity)`` |")
    $lines.Add("| Profil | ``$($Diagnostic.profile.label)`` |")
    $lines.Add("| Sortie du jeu | ``$($Diagnostic.process.exit_code)`` |")
    $lines.Add("| Duree | ``$($Diagnostic.process.duration_seconds) s`` |")
    $lines.Add("| Non-reponse maximale | ``$($Diagnostic.process.max_unresponsive_seconds) s`` |")
    $lines.Add("| Signature | ``$($Diagnostic.signature)`` |")
    $lines.Add('')
    $lines.Add('### Resume')
    $lines.Add('')
    $lines.Add([string]$Diagnostic.summary)
    $lines.Add('')
    $lines.Add('### Installation')
    $lines.Add('')
    $lines.Add("- Version declaree : ``$($Diagnostic.release)``")
    $lines.Add("- ``il2fb.exe`` : ``$($Diagnostic.profile.exe_sha256)``")
    $lines.Add("- ``files.SFS`` : ``$($Diagnostic.profile.files_sha256)``")
    $lines.Add("- ``wrapper.dll`` : ``$($Diagnostic.profile.wrapper_sha256)``")

    $environmentJson = $Diagnostic.environment | ConvertTo-Json -Depth 6
    $lines.Add('')
    $lines.Add('<details><summary>Environnement technique</summary>')
    $lines.Add('')
    $lines.Add((ConvertTo-CodeBlock -Text $environmentJson))
    $lines.Add('')
    $lines.Add('</details>')

    $findings = @($Diagnostic.findings)
    $affectedResourcesProperty = $Diagnostic.PSObject.Properties['affected_resources']
    $affectedResources = @(if ($null -ne $affectedResourcesProperty) { $affectedResourcesProperty.Value })
    if ($affectedResources.Count -gt 0) {
        $lines.Add('')
        $lines.Add('### Ressources concernees')
        $lines.Add('')
        $lines.Add('| Ressource | Type | Etat du fichier libre | Taille | SHA-256 | Journal |')
        $lines.Add('|---|---|---|---:|---|---|')
        foreach ($resource in @($affectedResources | Select-Object -First 100)) {
            $resourcePath = ([string](Get-PropertyValue -Object $resource -Name 'path')).Replace('|', '\|')
            $extension = [string](Get-PropertyValue -Object $resource -Name 'extension' -Default ([IO.Path]::GetExtension($resourcePath).TrimStart('.').ToUpperInvariant()))
            $looseState = ([string](Get-PropertyValue -Object $resource -Name 'loose_state' -Default 'non controle')).Replace('|', '\|')
            $lengthValue = Get-PropertyValue -Object $resource -Name 'loose_length' -Default $null
            $looseLength = if ($null -ne $lengthValue) { [string]$lengthValue } else { '-' }
            $shaValue = [string](Get-PropertyValue -Object $resource -Name 'loose_sha256')
            $looseSha = if ([string]::IsNullOrWhiteSpace($shaValue)) { '-' } else { "``$shaValue``" }
            $source = [string](Get-PropertyValue -Object $resource -Name 'source')
            $line = [int](Get-PropertyValue -Object $resource -Name 'line' -Default 0)
            $sourceLine = if ($line -gt 0) { "${source}:$line" } else { $source }
            $lines.Add("| ``$resourcePath`` | ``$extension`` | $looseState | $looseLength | $looseSha | ``$sourceLine`` |")
            $loosePath = [string](Get-PropertyValue -Object $resource -Name 'loose_path')
            if (-not [string]::IsNullOrWhiteSpace($loosePath)) {
                $resolvedLoosePath = $loosePath.Replace('|', '\|')
                $lines.Add("| fichier trouve |  | ``$resolvedLoosePath`` |  |  |  |")
            }
        }
    }
    if ($findings.Count -gt 0) {
        $lines.Add('')
        $lines.Add('### Anomalies detectees')
        $lines.Add('')
        foreach ($finding in @($findings | Select-Object -First 80)) {
            $message = ([string]$finding.message).Replace("`r", ' ').Replace("`n", ' ')
            $lines.Add("- **$($finding.category)** / ``$($finding.source)`` : $message")
        }
        if ($findings.Count -gt 80) {
            $lines.Add("- $($findings.Count - 80) anomalies supplementaires figurent dans les extraits joints au ticket.")
        }
    }

    $dumps = @($Diagnostic.dumps)
    if ($dumps.Count -gt 0) {
        $lines.Add('')
        $lines.Add('### Dumps locaux')
        $lines.Add('')
        $lines.Add('Les dumps bruts ne sont pas publies automatiquement, car ils peuvent contenir des donnees privees. Leurs identifiants reproductibles sont conserves ci-dessous.')
        foreach ($dump in $dumps) {
            $lines.Add("- ``$($dump.name)`` - $($dump.length) octets - SHA-256 ``$($dump.sha256)``")
            if ($dump.analysis) {
                $lines.Add('')
                $lines.Add((ConvertTo-CodeBlock -Text ($dump.analysis | ConvertTo-Json -Depth 8)))
            }
            elseif ($dump.analysis_error) {
                $lines.Add("  Analyse locale impossible : $($dump.analysis_error)")
            }
        }
    }

    $lines.Add('')
    $lines.Add('_Cree par le collecteur automatique Open Sturmovik. Les chemins utilisateur, le nom de machine, les adresses IP, les courriels et les secrets connus ont ete expurges avant envoi._')
    return Limit-Text -Text ($lines -join "`n") -Maximum 60000
}

function Split-MarkdownComments {
    param($Sources, [int]$Maximum = 50000)
    $comments = [Collections.Generic.List[string]]::new()
    foreach ($source in @($Sources)) {
        $heading = "### Extrait : ``$($source.name)```n`n"
        $text = @($source.lines) -join "`n"
        if ([string]::IsNullOrWhiteSpace($text)) { continue }
        $position = 0
        while ($position -lt $text.Length) {
            $room = $Maximum - $heading.Length - 30
            $length = [Math]::Min($room, $text.Length - $position)
            $part = $text.Substring($position, $length)
            $comments.Add($heading + (ConvertTo-CodeBlock -Text $part))
            $position += $length
            $heading = "### Extrait (suite) : ``$($source.name)```n`n"
        }
    }
    return $comments.ToArray()
}

$mainBody = New-OccurrenceMarkdown -Diagnostic $report -IncludeMarker
$previewPath = $resolvedReport + '.preview.md'
if ($DryRun) {
    $preview = [Collections.Generic.List[string]]::new()
    $preview.Add($mainBody)
    foreach ($comment in @(Split-MarkdownComments -Sources $report.sources)) {
        $preview.Add("`n`n---`n`nCOMMENTAIRE GITHUB`n`n$comment")
    }
    [IO.File]::WriteAllText($previewPath, ($preview -join ''), [Text.UTF8Encoding]::new($false))
    [pscustomobject]@{ Status = 'DRY_RUN'; Preview = $previewPath; Report = $resolvedReport; Repository = $Repository }
    exit 0
}

# The public service holds the GitHub App credentials; no client credential is read.
if ($Repository -cne 'Alfly-Alyx/IL2-1946-Open-Sturmovik') {
    throw 'Le service de rapports ne prend pas en charge ce depot.'
}
$endpoint = $null
if (-not [Uri]::TryCreate($RelayUrl, [UriKind]::Absolute, [ref]$endpoint) -or
    $endpoint.Scheme -ne 'https' -or $endpoint.UserInfo -or $endpoint.Fragment) {
    throw 'Adresse HTTPS du service de rapports invalide.'
}
if ([string]$report.report_id -notmatch '^[a-fA-F0-9]{32}$' -or
    [string]$report.signature -notmatch '^[a-fA-F0-9]{64}$') {
    throw 'Identifiant du rapport invalide.'
}
$sentRoot = Join-Path $resolvedState 'Sent'
$sentPath = Join-Path $sentRoot (([string]$report.report_id) + '.json')
if (Test-Path -LiteralPath $sentPath -PathType Leaf) {
    $previous = Get-Content -LiteralPath $sentPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($previous.report_id -eq $report.report_id -and $previous.signature -eq $report.signature -and
        $previous.repository -eq $Repository -and $previous.issue_url -match '^https://github\.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/issues/[1-9][0-9]*$') {
        if (-not $KeepReport) { Remove-Item -LiteralPath $resolvedReport -Force }
        [pscustomobject]@{ Status = 'ALREADY_SENT'; Issue = $previous.issue_number; Url = $previous.issue_url; Signature = $report.signature; SentRecord = $sentPath }
        return
    }
}
$shortSignature = ([string]$report.signature).Substring(0, 12)
$title = "[Diagnostic automatique][$shortSignature] $(([string]$report.category).ToUpperInvariant()) - $($report.profile.label)"
$allComments = @(Split-MarkdownComments -Sources $report.sources)
$comments = @($allComments | Select-Object -First 20)
$omitted = $allComments.Count - $comments.Count
$payload = [ordered]@{
    schemaVersion = 1
    reportId = ([string]$report.report_id).ToLowerInvariant()
    signature = ([string]$report.signature).ToLowerInvariant()
    title = (Limit-Text -Text $title -Maximum 240)
    body = $mainBody
    comments = $comments
}
do {
    $payload.comments = @($comments)
    $notice = if ($omitted -gt 0) { "`n`n_$omitted extrait(s) supplementaire(s) conserve(s) dans le rapport local complet._" } else { '' }
    $payload.body = (Limit-Text -Text $mainBody -Maximum 59500) + $notice
    $wireBytes = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 6 -Compress))
    if ($wireBytes.Length -le 1000000) { break }
    if ($comments.Count -eq 0) { throw 'Rapport trop volumineux pour le service.' }
    $comments = @($comments | Select-Object -First ($comments.Count - 1))
    $omitted++
} while ($true)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$result = Invoke-RestMethod -Method Post -Uri $endpoint.AbsoluteUri -TimeoutSec 90 -MaximumRedirection 0 `
    -Headers @{ 'X-Open-Sturmovik-Diagnostic' = '1' } -UserAgent 'Open-Sturmovik/1.15' `
    -ContentType 'application/json; charset=utf-8' -Body $wireBytes
$issueUrl = [string](Get-PropertyValue -Object $result -Name 'url')
$issueNumber = Get-PropertyValue -Object $result -Name 'issueNumber' -Default 0
if ((Get-PropertyValue -Object $result -Name 'ok' -Default $false) -ne $true -or
    (Get-PropertyValue -Object $result -Name 'completed' -Default $false) -ne $true -or
    (Get-PropertyValue -Object $result -Name 'reportId') -cne $payload.reportId -or
    $issueNumber -notmatch '^[1-9][0-9]*$' -or
    $issueUrl -cne ("https://github.com/$Repository/issues/$issueNumber")) {
    throw 'La livraison complete du rapport na pas ete confirmee. Le rapport reste dans la file locale.'
}
$created = (Get-PropertyValue -Object $result -Name 'created' -Default $false) -eq $true
$sentRecord = [ordered]@{
    sent_utc = [DateTime]::UtcNow.ToString('O')
    report_id = [string]$report.report_id
    signature = [string]$report.signature
    repository = $Repository
    issue_number = [int]$issueNumber
    issue_url = $issueUrl
    issue_created = $created
    omitted_log_parts = $omitted
}
New-Item -ItemType Directory -Path $sentRoot -Force | Out-Null
if ($omitted -gt 0) {
    Copy-Item -LiteralPath $resolvedReport -Destination (Join-Path $sentRoot ($report.report_id + '.report.json')) -Force
}
$receiptTemp = $sentPath + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
[IO.File]::WriteAllText($receiptTemp, ($sentRecord | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
Move-Item -LiteralPath $receiptTemp -Destination $sentPath -Force
if (-not $KeepReport) { Remove-Item -LiteralPath $resolvedReport -Force }
[pscustomobject]@{
    Status = if ($created) { 'ISSUE_CREATED' } else { 'ISSUE_UPDATED' }
    Issue = [int]$issueNumber
    Url = $issueUrl
    Signature = [string]$report.signature
    SentRecord = $sentPath
}
