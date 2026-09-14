[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [Parameter(Mandatory = $true)][string]$SessionPath,
    [string]$Repository = 'Alfly-Alyx/IL2-1946-Open-Sturmovik',
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'OpenSturmovik\Diagnostics'),
    [switch]$QueueOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$resolvedSession = (Resolve-Path -LiteralPath $SessionPath -ErrorAction Stop).Path
$resolvedState = [IO.Path]::GetFullPath($StateRoot)
$queueRoot = Join-Path $resolvedState 'Queue'
New-Item -ItemType Directory -Path $queueRoot -Force | Out-Null
$session = Get-Content -LiteralPath $resolvedSession -Raw | ConvertFrom-Json
function Convert-ToUtcDateTime {
    param([Parameter(Mandatory = $true)]$Value)
    if ($Value -is [DateTime]) {
        return ([DateTime]$Value).ToUniversalTime()
    }
    return [DateTime]::Parse(
        [string]$Value,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::RoundtripKind
    ).ToUniversalTime()
}

$startedUtc = Convert-ToUtcDateTime $session.started_utc
$endedProperty = $session.PSObject.Properties['ended_utc']
$endedUtc = if ($null -ne $endedProperty -and $null -ne $endedProperty.Value) {
    Convert-ToUtcDateTime $endedProperty.Value
}
else { [DateTime]::UtcNow }

function Get-Sha256Text {
    param([Parameter(Mandatory = $true)][string]$Text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally { $sha.Dispose() }
}

function Get-FileSha256 {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Protect-DiagnosticText {
    param([AllowEmptyString()][string]$Text)
    if ($null -eq $Text) { return '' }
    $safe = [string]$Text
    $paths = @(
        @{ Value = $resolvedGame; Replacement = '[GAME]' },
        @{ Value = $env:USERPROFILE; Replacement = '[USERPROFILE]' },
        @{ Value = $env:LOCALAPPDATA; Replacement = '[LOCALAPPDATA]' },
        @{ Value = $env:APPDATA; Replacement = '[APPDATA]' },
        @{ Value = $env:TEMP; Replacement = '[TEMP]' },
        @{ Value = $env:COMPUTERNAME; Replacement = '[MACHINE]' },
        @{ Value = $env:USERNAME; Replacement = '[USER]' }
    )
    foreach ($entry in $paths) {
        if (-not [string]::IsNullOrWhiteSpace([string]$entry.Value)) {
            $safe = $safe -replace [regex]::Escape([string]$entry.Value), [string]$entry.Replacement
        }
    }
    $safe = $safe -replace '(?im)^.*(?:password|passwd|token|authorization|secret|api[_-]?key)\s*[=:].*$', '[SECRET REDACTED]'
    $safe = $safe -replace '(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', '[EMAIL]'
    $safe = $safe -replace '(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?![\d.])', '[IP]'
    return $safe
}

function Get-SessionOffset {
    param([string]$RelativePath, [string]$Path)
    $offsetsProperty = $session.PSObject.Properties['log_offsets']
    if ($null -eq $offsetsProperty -or $null -eq $offsetsProperty.Value) { return 0L }
    $property = $offsetsProperty.Value.PSObject.Properties[$RelativePath]
    if ($null -eq $property) { return 0L }
    $offset = [long]$property.Value
    $checkpointsProperty = $session.PSObject.Properties['log_checkpoints']
    if ($null -eq $checkpointsProperty -or $null -eq $checkpointsProperty.Value) { return $offset }
    $checkpointProperty = $checkpointsProperty.Value.PSObject.Properties[$RelativePath]
    if ($null -eq $checkpointProperty -or $null -eq $checkpointProperty.Value) { return $offset }
    $checkpoint = $checkpointProperty.Value
    $tailLength = [int]$checkpoint.tail_length
    $expectedHash = [string]$checkpoint.tail_sha256
    if ($tailLength -le 0 -or [string]::IsNullOrWhiteSpace($expectedHash)) { return $offset }
    $item = Get-Item -LiteralPath $Path
    if ($item.Length -lt $offset -or $offset -lt $tailLength) { return 0L }
    $inputStream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $inputStream.Position = $offset - $tailLength
        $tail = New-Object byte[] $tailLength
        if ($inputStream.Read($tail, 0, $tailLength) -ne $tailLength) { return 0L }
        $tailSha = [Security.Cryptography.SHA256]::Create()
        try { $actualHash = ([BitConverter]::ToString($tailSha.ComputeHash($tail))).Replace('-', '') }
        finally { $tailSha.Dispose() }
    }
    finally { $inputStream.Dispose() }
    if ($actualHash -ne $expectedHash) { return 0L }
    return $offset
}

function Read-NewText {
    param([Parameter(Mandatory = $true)][string]$Path, [long]$Offset)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($Offset -lt 0 -or $Offset -gt $bytes.Length) { $Offset = 0 }
    if ($bytes.Length -eq $Offset) { return '' }
    $count = $bytes.Length - [int]$Offset
    $slice = New-Object byte[] $count
    [Array]::Copy($bytes, [int]$Offset, $slice, 0, $count)
    $encoding = [Text.Encoding]::Default
    if ($slice.Length -ge 3 -and $slice[0] -eq 0xEF -and $slice[1] -eq 0xBB -and $slice[2] -eq 0xBF) {
        $encoding = New-Object Text.UTF8Encoding($false)
        $withoutBom = New-Object byte[] ($slice.Length - 3)
        if ($withoutBom.Length -gt 0) { [Array]::Copy($slice, 3, $withoutBom, 0, $withoutBom.Length) }
        $slice = $withoutBom
    }
    return $encoding.GetString($slice)
}

function Get-RelativeName {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ($Path.StartsWith($resolvedGame + '\', [StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($resolvedGame.Length + 1)
    }
    return [IO.Path]::GetFileName($Path)
}

function Get-ProfileSnapshot {
    $exePath = Join-Path $resolvedGame 'il2fb.exe'
    $filesPath = Join-Path $resolvedGame 'files.SFS'
    $wrapperPath = Join-Path $resolvedGame 'wrapper.dll'
    $exeHash = Get-FileSha256 -Path $exePath
    $filesHash = Get-FileSha256 -Path $filesPath
    $wrapperHash = Get-FileSha256 -Path $wrapperPath
    $label = 'profil inconnu'
    $number = $null
    $version = ''
    $mode = ''
    $manifestPath = Join-Path $resolvedGame 'manifests\switcher-v1.15.json'
    if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
        try {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
            $match = @($manifest.profiles | Where-Object {
                ([string]$_.exeSha256 -ieq $exeHash) -and ([string]$_.filesSha256 -ieq $filesHash)
            } | Select-Object -First 1)
            if ($match.Count -gt 0) {
                $number = [int]$match[0].number
                $version = [string]$match[0].version
                $mode = [string]$match[0].mode
                $label = "$number - $version / $mode"
            }
        }
        catch { }
    }
    return [ordered]@{
        number = $number
        version = $version
        mode = $mode
        label = $label
        exe_sha256 = $exeHash
        files_sha256 = $filesHash
        wrapper_sha256 = $wrapperHash
    }
}

function Get-ConfigurationSummary {
    $conf = Join-Path $resolvedGame 'conf.ini'
    if (-not (Test-Path -LiteralPath $conf -PathType Leaf)) { return @() }
    $allowedSections = @('window','Render_OpenGL','Render_DirectX','Console','game','sound')
    $section = ''
    $selected = [Collections.Generic.List[string]]::new()
    foreach ($line in [IO.File]::ReadAllLines($conf, [Text.Encoding]::Default)) {
        if ($line -match '^\s*\[(.+)\]\s*$') {
            $section = $matches[1]
            if ($allowedSections -contains $section) { $selected.Add("[$section]") }
            continue
        }
        if ($allowedSections -notcontains $section) { continue }
        if ($line -match '^\s*(?:host|IPS|password|token|user|callsign)\s*=') { continue }
        if ($line -match '^\s*[^;#].*=') { $selected.Add((Protect-DiagnosticText -Text $line)) }
        if ($selected.Count -ge 160) { break }
    }
    return $selected.ToArray()
}

function Get-EnvironmentSnapshot {
    $os = $null
    $computer = $null
    $processors = @()
    $graphics = @()
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { }
    try { $computer = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop } catch { }
    try { $processors = @(Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors) } catch { }
    try { $graphics = @(Get-CimInstance Win32_VideoController -ErrorAction Stop | Select-Object Name,DriverVersion,AdapterRAM,CurrentHorizontalResolution,CurrentVerticalResolution) } catch { }
    $sfsInventory = @(
        Get-ChildItem -LiteralPath $resolvedGame -File -Filter '*.SFS' -ErrorAction SilentlyContinue |
            Sort-Object Name |
            ForEach-Object { [ordered]@{ name = $_.Name; length = $_.Length; modified_utc = $_.LastWriteTimeUtc.ToString('O') } }
    )
    return [ordered]@{
        os = if ($os) { [ordered]@{ caption = $os.Caption; version = $os.Version; build = $os.BuildNumber; architecture = $os.OSArchitecture } } else { $null }
        memory_bytes = if ($computer) { [long]$computer.TotalPhysicalMemory } else { $null }
        processors = $processors
        graphics = $graphics
        culture = [Globalization.CultureInfo]::CurrentCulture.Name
        powershell = [string]$PSVersionTable.PSVersion
        configuration = @(Get-ConfigurationSummary)
        root_sfs = $sfsInventory
    }
}

$errorPattern = '(?i)(FileNotFoundException|NoSuchFileException|No such file|cannot find|can''t find|cannot load|can''t load|could not load|failed to load|load failed|\bnot found\b|\bfail(?:ed|ure)?\b|missing (?:file|texture|material|mesh|class|sample|resource)|unknown exception|RuntimeException|NullPointerException|ClassCastException|EOFException|IOException|OutOfMemory|StackOverflow|access violation|fatal error|assertion failed|\berror\b)'
$warningPattern = '(?i)(\bwarn(?:ing)?\s*[:=]|\binvalid\b|\bcorrupt(?:ed)?\b|\bunsupported\b|No spawner|Wrong chief|timed?\s*out|not responding)'
$resourcePattern = '(?i)(texture|\.tga\b|\.mat\b|\.msh\b|\.him\b|file|resource|sample|sound|preset|SectFile|spawner)'
$sources = [Collections.Generic.List[object]]::new()
$findings = [Collections.Generic.List[object]]::new()

$logFiles = [Collections.Generic.List[IO.FileInfo]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $resolvedGame -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.log','.lst' })) {
    $logFiles.Add($file)
}
$dumpTextRoot = Join-Path $resolvedGame 'dump'
if (Test-Path -LiteralPath $dumpTextRoot -PathType Container) {
    foreach ($file in @(Get-ChildItem -LiteralPath $dumpTextRoot -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.log','.lst','.txt' })) {
        $logFiles.Add($file)
    }
}

foreach ($file in @($logFiles | Sort-Object FullName -Unique)) {
    $relative = Get-RelativeName -Path $file.FullName
    $offset = Get-SessionOffset -RelativePath $relative -Path $file.FullName
    $delta = Read-NewText -Path $file.FullName -Offset $offset
    if ([string]::IsNullOrWhiteSpace($delta)) { continue }
    $lines = @($delta -split '\r?\n')
    $selectedIndexes = [Collections.Generic.HashSet[int]]::new()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match $errorPattern -or $lines[$index] -match $warningPattern) {
            $severity = if ($lines[$index] -match $errorPattern) { 'error' } else { 'warning' }
            $category = if ($lines[$index] -match $resourcePattern) { 'resource' } elseif ($lines[$index] -match '(?i)exception') { 'exception' } else { $severity }
            $message = Protect-DiagnosticText -Text $lines[$index].Trim()
            $findings.Add([pscustomobject][ordered]@{ severity = $severity; category = $category; source = $relative; line = $index + 1; message = $message })
            foreach ($contextIndex in ([Math]::Max(0, $index - 2)..[Math]::Min($lines.Count - 1, $index + 2))) {
                $selectedIndexes.Add($contextIndex) | Out-Null
            }
        }
    }
    if ($selectedIndexes.Count -gt 0) {
        $excerpt = [Collections.Generic.List[string]]::new()
        foreach ($index in @($selectedIndexes | Sort-Object | Select-Object -First 600)) {
            $excerpt.Add(('{0,6}: {1}' -f ($index + 1), (Protect-DiagnosticText -Text $lines[$index])))
        }
        if ($selectedIndexes.Count -gt 600) { $excerpt.Add("[extrait limite : $($selectedIndexes.Count - 600) lignes de contexte supplementaires conservees localement]") }
        $matchedCount = @($findings | Where-Object source -eq $relative).Count
        $sources.Add([pscustomobject][ordered]@{ name = $relative; lines = $excerpt.ToArray(); matched_lines = [int]$matchedCount })
    }
}

$maxUnresponsive = 0
if ($session.PSObject.Properties['max_unresponsive_seconds']) { $maxUnresponsive = [int]$session.max_unresponsive_seconds }
$exitCode = $null
if ($session.PSObject.Properties['exit_code'] -and $null -ne $session.exit_code) { $exitCode = [int]$session.exit_code }
if ($null -ne $exitCode -and $exitCode -ne 0) {
    $findings.Add([pscustomobject][ordered]@{ severity = 'fatal'; category = 'process'; source = 'il2fb.exe'; line = 0; message = "Sortie anormale du processus avec le code $exitCode." })
}
if ($maxUnresponsive -ge 20) {
    $findings.Add([pscustomobject][ordered]@{ severity = 'error'; category = 'hang'; source = 'il2fb.exe'; line = 0; message = "Fenetre non reactive pendant au moins $maxUnresponsive secondes." })
}

$windowsEvents = [Collections.Generic.List[string]]::new()
try {
    foreach ($event in @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $startedUtc.ToLocalTime() } -ErrorAction Stop | Where-Object {
        $_.Message -match '(?i)il2fb|wrapper\.dll|jvm\.dll|jgl\.dll'
    } | Select-Object -First 40)) {
        $message = Protect-DiagnosticText -Text ("$($event.TimeCreated.ToUniversalTime().ToString('O')) | $($event.ProviderName) | $($event.Id) | $($event.LevelDisplayName) | $($event.Message)")
        $windowsEvents.Add($message)
        if ($event.Level -le 2 -or $event.ProviderName -match 'Application Error|Windows Error Reporting') {
            $findings.Add([pscustomobject][ordered]@{ severity = 'fatal'; category = 'windows-event'; source = 'Windows/Application'; line = 0; message = (Protect-DiagnosticText -Text ([string]$event.Message)) })
        }
    }
}
catch { }
if ($windowsEvents.Count -gt 0) {
    $sources.Add([pscustomobject][ordered]@{ name = 'Windows/Application'; lines = $windowsEvents.ToArray(); matched_lines = $windowsEvents.Count })
}

$knownDumps = @()
if ($session.PSObject.Properties['dump_files']) { $knownDumps = @($session.dump_files) }
$dumpRoots = @((Join-Path $resolvedState 'Dumps'), (Join-Path $resolvedGame 'dump'), $resolvedGame)
$dumps = [Collections.Generic.List[object]]::new()
$seenDumps = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$dumpAnalyzer = Join-Path $PSScriptRoot 'Read-OpenSturmovikMinidump.ps1'
foreach ($dumpRoot in $dumpRoots) {
    if (-not (Test-Path -LiteralPath $dumpRoot -PathType Container)) { continue }
    foreach ($dump in @(Get-ChildItem -LiteralPath $dumpRoot -File -Filter '*.dmp' -Recurse -ErrorAction SilentlyContinue)) {
        if (-not $seenDumps.Add($dump.FullName)) { continue }
        if ($dump.LastWriteTimeUtc -lt $startedUtc.AddSeconds(-2)) { continue }
        if ($knownDumps -contains $dump.FullName) { continue }
        $analysis = $null
        $analysisError = ''
        if (Test-Path -LiteralPath $dumpAnalyzer -PathType Leaf) {
            try { $analysis = & $dumpAnalyzer -DumpPath $dump.FullName }
            catch { $analysisError = Protect-DiagnosticText -Text $_.Exception.Message }
        }
        $dumps.Add([pscustomobject][ordered]@{
            name = $dump.Name
            length = $dump.Length
            sha256 = (Get-FileHash -LiteralPath $dump.FullName -Algorithm SHA256).Hash
            local_path = (Protect-DiagnosticText -Text $dump.FullName)
            analysis = $analysis
            analysis_error = $analysisError
        })
        $findings.Add([pscustomobject][ordered]@{ severity = 'fatal'; category = 'crash-dump'; source = $dump.Name; line = 0; message = 'Nouveau dump de processus cree par Windows Error Reporting.' })
    }
}

if ($findings.Count -eq 0) {
    [pscustomobject]@{ Status = 'CLEAN'; ReportCreated = $false; Findings = 0 }
    exit 0
}

$resourceExtensions = 'tga|mat|msh|him|sim|emd|prs|wav|mp3|class|ini|properties|mis|sfs|dll|exe|bmp|jpg|jpeg|png|txt|dat|eff'
$quotedResourcePattern = '(?i)["''](?<path>[^"''\r\n]+\.(?:' + $resourceExtensions + '))["'']'
$resourcePathPattern = "(?i)(?:\[GAME\][\\/]|[A-Za-z]:[\\/])?(?:[A-Za-z0-9_.$@#()\[\]'-]+[\\/])+(?:[A-Za-z0-9_.$@#()'-]+)\.(?:$resourceExtensions)\b"
$resourceNamePattern = "(?i)\b[A-Za-z0-9_.$@#()'-]+\.(?:$resourceExtensions)\b"

function Get-LooseResourceState {
    param([Parameter(Mandatory = $true)][string]$Candidate)

    $relative = $Candidate.Trim().Trim('"', "'") -replace '/', '\'
    if ($relative -match '^\[(?:USERPROFILE|LOCALAPPDATA|APPDATA|TEMP)\]') {
        return [ordered]@{ state = 'chemin externe expurge'; path = ''; length = $null; sha256 = '' }
    }
    $relative = $relative -replace '^\[GAME\][\\/]*', ''
    $relative = $relative.TrimStart('\')
    if ($relative -notmatch '[\\/]') {
        return [ordered]@{ state = 'nom seul; emplacement non resolu'; path = ''; length = $null; sha256 = '' }
    }

    $candidatePaths = [Collections.Generic.List[string]]::new()
    $candidatePaths.Add((Join-Path $resolvedGame $relative))
    if ($relative -notmatch '^(?i)Files[\\/]') {
        $candidatePaths.Add((Join-Path (Join-Path $resolvedGame 'Files') $relative))
    }
    foreach ($path in @($candidatePaths | Select-Object -Unique)) {
        try {
            $fullPath = [IO.Path]::GetFullPath($path)
            if (-not $fullPath.StartsWith($resolvedGame + '\', [StringComparison]::OrdinalIgnoreCase)) { continue }
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                $item = Get-Item -LiteralPath $fullPath
                return [ordered]@{
                    state = 'present comme fichier libre'
                    path = Get-RelativeName -Path $fullPath
                    length = [long]$item.Length
                    sha256 = Get-FileSha256 -Path $fullPath
                }
            }
        }
        catch { }
    }
    return [ordered]@{ state = 'absent des fichiers libres; verifier les SFS'; path = ''; length = $null; sha256 = '' }
}

$resourcesByPath = @{}
foreach ($finding in $findings) {
    $matches = [Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches([string]$finding.message, $quotedResourcePattern)) { $matches.Add($match.Groups['path'].Value.Trim()) }
    foreach ($match in [regex]::Matches([string]$finding.message, $resourcePathPattern)) { $matches.Add($match.Value.Trim()) }
    foreach ($match in [regex]::Matches([string]$finding.message, $resourceNamePattern)) {
        $name = $match.Value.Trim()
        $alreadyCovered = @($matches | Where-Object {
            $_ -ieq $name -or $_.EndsWith('\' + $name, [StringComparison]::OrdinalIgnoreCase) -or $_.EndsWith('/' + $name, [StringComparison]::OrdinalIgnoreCase)
        }).Count -gt 0
        if (-not $alreadyCovered) { $matches.Add($name) }
    }
    foreach ($candidate in @($matches | Sort-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        $safeCandidate = Protect-DiagnosticText -Text $candidate
        $key = $safeCandidate.ToLowerInvariant()
        if (-not $resourcesByPath.ContainsKey($key)) {
            $loose = Get-LooseResourceState -Candidate $safeCandidate
            $resourcesByPath[$key] = [pscustomobject][ordered]@{
                path = $safeCandidate
                extension = [IO.Path]::GetExtension($safeCandidate).TrimStart('.').ToUpperInvariant()
                source = [string]$finding.source
                line = [int]$finding.line
                message = [string]$finding.message
                loose_state = [string]$loose.state
                loose_path = [string]$loose.path
                loose_length = $loose.length
                loose_sha256 = [string]$loose.sha256
            }
        }
    }
}

$profile = Get-ProfileSnapshot
$severity = if (@($findings | Where-Object severity -eq 'fatal').Count -gt 0) { 'fatal' } elseif (@($findings | Where-Object severity -eq 'error').Count -gt 0) { 'error' } else { 'warning' }
$category = if ($dumps.Count -gt 0 -or ($null -ne $exitCode -and $exitCode -ne 0)) { 'crash' } elseif ($maxUnresponsive -ge 20) { 'hang' } elseif (@($findings | Where-Object category -eq 'resource').Count -gt 0) { 'resource' } elseif (@($findings | Where-Object category -eq 'exception').Count -gt 0) { 'exception' } else { 'warning' }
$normalizedMessages = @($findings | ForEach-Object {
    $value = ([string]$_.message).ToLowerInvariant()
    $value = $value -replace '0x[0-9a-f]+', '0x#'
    $value = $value -replace '\b\d+\b', '#'
    "$($_.category)|$value"
} | Sort-Object -Unique | Select-Object -First 40)
$signatureSeed = "$category|$($profile.version)|$($profile.mode)|" + ($normalizedMessages -join '|')
$signature = Get-Sha256Text -Text $signatureSeed
$duration = [Math]::Max(0, [Math]::Round(($endedUtc - $startedUtc).TotalSeconds, 1))
$reportId = [Guid]::NewGuid().ToString('N')
$report = [ordered]@{
    schema_version = 1
    report_id = $reportId
    signature = $signature
    repository = $Repository
    release = '1.15'
    category = $category
    severity = $severity
    started_utc = $startedUtc.ToString('O')
    ended_utc = $endedUtc.ToString('O')
    summary = "$($findings.Count) anomalie(s) detectee(s) dans $($sources.Count) source(s) ; categorie principale $category, gravite $severity."
    process = [ordered]@{ pid = [int]$session.pid; exit_code = $exitCode; duration_seconds = $duration; max_unresponsive_seconds = $maxUnresponsive }
    profile = $profile
    environment = Get-EnvironmentSnapshot
    affected_resources = @($resourcesByPath.Values | Sort-Object path)
    findings = $findings.ToArray()
    sources = $sources.ToArray()
    dumps = $dumps.ToArray()
}
$reportPath = Join-Path $queueRoot (([DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ')) + '-' + $reportId + '.json')
$report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $reportPath -Encoding UTF8

if ($QueueOnly) {
    [pscustomobject]@{ Status = 'QUEUED'; ReportCreated = $true; Findings = $findings.Count; Report = $reportPath; Signature = $signature }
    exit 0
}

$sender = Join-Path $PSScriptRoot 'Send-OpenSturmovikDiagnostic.ps1'
try {
    $sent = & $sender -ReportPath $reportPath -Repository $Repository -StateRoot $resolvedState
    [pscustomobject]@{ Status = [string]$sent.Status; ReportCreated = $true; Findings = $findings.Count; Report = $reportPath; Signature = $signature; Issue = $sent.Issue; Url = $sent.Url }
}
catch {
    $errorPath = Join-Path $resolvedState 'last-send-error.txt'
    $safeError = Protect-DiagnosticText -Text $_.Exception.Message
    [IO.File]::WriteAllText($errorPath, ([DateTime]::UtcNow.ToString('O') + ' ' + $safeError), [Text.UTF8Encoding]::new($false))
    [pscustomobject]@{ Status = 'QUEUED_OFFLINE'; ReportCreated = $true; Findings = $findings.Count; Report = $reportPath; Signature = $signature; Error = $safeError }
}
