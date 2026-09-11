[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
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
$report = Get-Content -LiteralPath $resolvedReport -Raw | ConvertFrom-Json
if (-not $report.signature -or -not $report.report_id) {
    throw "Rapport de diagnostic incomplet : $resolvedReport"
}

function Limit-Text {
    param([AllowEmptyString()][string]$Text, [int]$Maximum = 60000)
    if ($null -eq $Text) { return '' }
    if ($Text.Length -le $Maximum) { return $Text }
    return $Text.Substring(0, $Maximum) + "`n`n[contenu tronque localement]"
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
    $affectedResources = if ($null -ne $affectedResourcesProperty) { @($affectedResourcesProperty.Value) } else { @() }
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

function Get-GitHubToken {
    if (-not [string]::IsNullOrWhiteSpace($env:OPEN_STURMOVIK_GITHUB_TOKEN)) {
        return $env:OPEN_STURMOVIK_GITHUB_TOKEN
    }

    $protectedToken = Join-Path $resolvedState 'github-token.dpapi'
    if (Test-Path -LiteralPath $protectedToken -PathType Leaf) {
        try {
            $secure = Get-Content -LiteralPath $protectedToken -Raw | ConvertTo-SecureString
            $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
            try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
            finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
        }
        catch { }
    }

    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if (-not $git) { $git = Get-Command git -ErrorAction SilentlyContinue }
    if ($git) {
        $credentialInputPath = $null
        try {
            $credentialInputPath = [IO.Path]::GetTempFileName()
            [IO.File]::WriteAllText($credentialInputPath, "protocol=https`r`nhost=github.com`r`n`r`n", [Text.Encoding]::ASCII)
            $startInfo = New-Object Diagnostics.ProcessStartInfo
            $startInfo.FileName = $env:ComSpec
            $startInfo.Arguments = '/d /s /c ""' + $git.Source + '" credential fill < "' + $credentialInputPath + '""'
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $credentialProcess = New-Object Diagnostics.Process
            $credentialProcess.StartInfo = $startInfo
            [void]$credentialProcess.Start()
            $credentialOutput = $credentialProcess.StandardOutput.ReadToEnd()
            $credentialProcess.StandardError.ReadToEnd() | Out-Null
            $credentialProcess.WaitForExit()
            if ($credentialProcess.ExitCode -ne 0) { return $null }
            foreach ($line in @($credentialOutput -split '\r?\n')) {
                if ($line.StartsWith('password=', [StringComparison]::OrdinalIgnoreCase)) {
                    return $line.Substring('password='.Length)
                }
            }
        }
        catch { }
        finally {
            if (-not [string]::IsNullOrWhiteSpace($credentialInputPath)) {
                Remove-Item -LiteralPath $credentialInputPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    return $null
}

function Invoke-GitHubJson {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('GET','POST','PATCH')][string]$Method,
        [Parameter(Mandatory = $true)][string]$Uri,
        $Payload,
        [Parameter(Mandatory = $true)][string]$Token
    )
    $headers = @{
        Authorization = 'Bearer ' + $Token
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
        'User-Agent' = 'Open-Sturmovik-Diagnostics'
    }
    if ($Method -eq 'GET') {
        return Invoke-RestMethod -Method Get -Uri $Uri -Headers $headers
    }
    $json = $Payload | ConvertTo-Json -Depth 10 -Compress
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $json
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = Get-GitHubToken
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'Aucune authentification GitHub disponible. Le rapport reste dans la file locale.'
}

$apiRoot = 'https://api.github.com/repos/' + $Repository
$shortSignature = ([string]$report.signature).Substring(0, [Math]::Min(12, ([string]$report.signature).Length))
$query = [Uri]::EscapeDataString("repo:$Repository is:issue in:title $shortSignature")
$search = Invoke-GitHubJson -Method GET -Uri ("https://api.github.com/search/issues?q=$query&per_page=10") -Token $token
$existing = @($search.items | Where-Object { $_.title -like "*$shortSignature*" } | Select-Object -First 1)
$issue = $null
$created = $false
if ($existing.Count -gt 0) {
    $issue = $existing[0]
    if ([string]$issue.state -eq 'closed') {
        $issue = Invoke-GitHubJson -Method PATCH -Uri ("$apiRoot/issues/$($issue.number)") -Payload @{ state = 'open' } -Token $token
    }
    $occurrence = New-OccurrenceMarkdown -Diagnostic $report
    Invoke-GitHubJson -Method POST -Uri ("$apiRoot/issues/$($issue.number)/comments") -Payload @{ body = $occurrence } -Token $token | Out-Null
}
else {
    $titleCategory = ([string]$report.category).ToUpperInvariant()
    $title = "[Diagnostic automatique][$shortSignature] $titleCategory - $($report.profile.label)"
    $issue = Invoke-GitHubJson -Method POST -Uri ("$apiRoot/issues") -Payload @{ title = (Limit-Text -Text $title -Maximum 240); body = $mainBody } -Token $token
    $created = $true
}

foreach ($comment in @(Split-MarkdownComments -Sources $report.sources)) {
    Invoke-GitHubJson -Method POST -Uri ("$apiRoot/issues/$($issue.number)/comments") -Payload @{ body = $comment } -Token $token | Out-Null
}

$sentRecord = [ordered]@{
    sent_utc = [DateTime]::UtcNow.ToString('O')
    report_id = [string]$report.report_id
    signature = [string]$report.signature
    repository = $Repository
    issue_number = [int]$issue.number
    issue_url = [string]$issue.html_url
    issue_created = $created
}
$sentRoot = Join-Path $resolvedState 'Sent'
New-Item -ItemType Directory -Path $sentRoot -Force | Out-Null
$sentPath = Join-Path $sentRoot (([string]$report.report_id) + '.json')
$sentRecord | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $sentPath -Encoding UTF8
if (-not $KeepReport) { Remove-Item -LiteralPath $resolvedReport -Force }

[pscustomobject]@{
    Status = if ($created) { 'ISSUE_CREATED' } else { 'ISSUE_UPDATED' }
    Issue = [int]$issue.number
    Url = [string]$issue.html_url
    Signature = [string]$report.signature
    SentRecord = $sentPath
}
