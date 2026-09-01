[CmdletBinding(DefaultParameterSetName = 'Json')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigurationPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Json')]
    [string]$ChangesJson,

    [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
    [string]$ChangesPath,

    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[Text.Encoding]::RegisterProvider([Text.CodePagesEncodingProvider]::Instance)

function Get-Sha256Bytes {
    param([byte[]]$Bytes)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Read-TextDocument {
    param([string]$Path)

    $bytes = [IO.File]::ReadAllBytes($Path)
    $hasBom = $false
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $encoding = [Text.UTF8Encoding]::new($false, $true)
        $offset = 3
        $hasBom = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $encoding = [Text.UnicodeEncoding]::new($false, $false, $true)
        $offset = 2
        $hasBom = $true
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $encoding = [Text.UnicodeEncoding]::new($true, $false, $true)
        $offset = 2
        $hasBom = $true
    }
    else {
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        try {
            $null = $utf8.GetString($bytes)
            $encoding = $utf8
        }
        catch [Text.DecoderFallbackException] {
            $encoding = [Text.Encoding]::GetEncoding(1252)
        }
        $offset = 0
    }

    $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
    $newLine = if ($text.Contains("`r`n")) { "`r`n" } elseif ($text.Contains("`n")) { "`n" } else { "`r`n" }
    return [ordered]@{
        bytes = $bytes
        text = $text
        encoding = $encoding
        hasBom = $hasBom
        newLine = $newLine
        endsWithNewLine = $text.EndsWith("`n") -or $text.EndsWith("`r")
    }
}

function Convert-TextToBytes {
    param([string]$Text, [Text.Encoding]$Encoding, [bool]$WithBom)

    $body = $Encoding.GetBytes($Text)
    if (-not $WithBom) { return $body }
    $preamble = $Encoding.GetPreamble()
    $combined = [byte[]]::new($preamble.Length + $body.Length)
    [Array]::Copy($preamble, 0, $combined, 0, $preamble.Length)
    [Array]::Copy($body, 0, $combined, $preamble.Length, $body.Length)
    return $combined
}

function Get-IniIndex {
    param([Collections.Generic.List[string]]$Lines)

    $sections = @{}
    $orderedSections = New-Object System.Collections.Generic.List[object]
    $current = $null
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $line = [string]$Lines[$index]
        if ($line -match '^\s*\[(?<name>[^\]]+)\]\s*$') {
            if ($null -ne $current) { $current.endIndex = $index }
            $name = $Matches.name.Trim()
            if ($sections.ContainsKey($name)) {
                throw "Section INI dupliquee : [$name]."
            }
            $current = [pscustomobject]@{
                name = $name
                headerIndex = $index
                endIndex = $Lines.Count
                keys = @{}
            }
            $sections[$name] = $current
            $orderedSections.Add($current)
            continue
        }
        if ($null -eq $current -or $line -match '^\s*[;#]' -or $line -notmatch '=') {
            continue
        }
        $keyMatch = [regex]::Match(
            $line,
            '^(?<leading>\s*)(?<key>[^;#=][^=]*?)(?<before>\s*)=(?<after>\s*)(?<value>.*)$'
        )
        if (-not $keyMatch.Success) { continue }
        $key = $keyMatch.Groups['key'].Value.Trim()
        if ($current.keys.ContainsKey($key)) {
            throw "Cle INI dupliquee : [$($current.name)]/$key."
        }
        $current.keys[$key] = [pscustomobject]@{
            index = $index
            leading = $keyMatch.Groups['leading'].Value
            originalKey = $keyMatch.Groups['key'].Value.Trim()
            beforeEquals = $keyMatch.Groups['before'].Value
            afterEquals = $keyMatch.Groups['after'].Value
            value = $keyMatch.Groups['value'].Value
        }
    }
    if ($null -ne $current) { $current.endIndex = $Lines.Count }
    return [ordered]@{ byName = $sections; ordered = $orderedSections }
}

$resolvedConfiguration = (Resolve-Path -LiteralPath $ConfigurationPath).Path
$document = Read-TextDocument $resolvedConfiguration
$changesText = if ($PSCmdlet.ParameterSetName -eq 'Path') {
    Get-Content -LiteralPath $ChangesPath -Raw
}
else {
    $ChangesJson
}
$changes = @($changesText | ConvertFrom-Json)
if ($changes.Count -eq 0) { throw 'Aucune modification demandee.' }

$splitLines = @([regex]::Split([string]$document.text, '\r\n|\n|\r'))
if ($document.endsWithNewLine -and $splitLines.Count -gt 0 -and $splitLines[-1] -eq '') {
    $splitLines = @($splitLines | Select-Object -First ($splitLines.Count - 1))
}
$lines = New-Object System.Collections.Generic.List[string]
foreach ($line in $splitLines) { $lines.Add([string]$line) }

$plan = New-Object System.Collections.Generic.List[object]
foreach ($change in $changes) {
    $sectionName = [string]$change.section
    $keyName = [string]$change.key
    $value = [string]$change.value
    if ($sectionName -notmatch '^[^\[\]\r\n]{1,128}$') { throw "Section invalide : $sectionName" }
    if ($keyName -notmatch '^[^=\[\]\r\n]{1,128}$') { throw "Cle invalide : $keyName" }
    if ($value -match '[\r\n]') { throw "Valeur multiligne interdite : [$sectionName]/$keyName" }

    $index = Get-IniIndex $lines
    if (-not $index.byName.ContainsKey($sectionName)) {
        if ($lines.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[-1])) {
            $lines.Add('')
        }
        $lines.Add("[$sectionName]")
        $lines.Add("$keyName=$value")
        $plan.Add([ordered]@{
            section = $sectionName
            key = $keyName
            action = 'insert-section'
            before = $null
            after = $value
        })
        continue
    }

    $section = $index.byName[$sectionName]
    if (-not $section.keys.ContainsKey($keyName)) {
        $lines.Insert([int]$section.endIndex, "$keyName=$value")
        $plan.Add([ordered]@{
            section = $sectionName
            key = $keyName
            action = 'insert-key'
            before = $null
            after = $value
        })
        continue
    }

    $entry = $section.keys[$keyName]
    $replacement = '{0}{1}{2}={3}{4}' -f @(
        $entry.leading,
        $entry.originalKey,
        $entry.beforeEquals,
        $entry.afterEquals,
        $value
    )
    $lines[[int]$entry.index] = $replacement
    $plan.Add([ordered]@{
        section = $sectionName
        key = $keyName
        action = if ([string]$entry.value -ceq $value) { 'unchanged' } else { 'update' }
        before = [string]$entry.value
        after = $value
    })
}

$newText = $lines -join [string]$document.newLine
if ($document.endsWithNewLine) { $newText += [string]$document.newLine }
$newBytes = Convert-TextToBytes $newText $document.encoding $document.hasBom
$beforeHash = Get-Sha256Bytes $document.bytes
$plannedHash = Get-Sha256Bytes $newBytes
$backupPath = $null

if ($Apply -and $beforeHash -ne $plannedHash) {
    $directory = Split-Path -Parent $resolvedConfiguration
    $backupDirectory = Join-Path $directory '_OpenSturmovik_Backups'
    if (-not (Test-Path -LiteralPath $backupDirectory)) {
        $null = New-Item -ItemType Directory -Path $backupDirectory
    }
    $stamp = [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $backupPath = Join-Path $backupDirectory ("{0}.{1}.{2}.bak" -f @(
        [IO.Path]::GetFileName($resolvedConfiguration),
        $stamp,
        $beforeHash.Substring(0, 12)
    ))
    $temporaryPath = Join-Path $directory (".{0}.launcher.{1}.tmp" -f @(
        [IO.Path]::GetFileName($resolvedConfiguration),
        [Guid]::NewGuid().ToString('N')
    ))
    try {
        [IO.File]::WriteAllBytes($temporaryPath, $newBytes)
        if ((Get-Sha256Bytes ([IO.File]::ReadAllBytes($temporaryPath))) -ne $plannedHash) {
            throw 'La verification du fichier temporaire a echoue.'
        }
        [IO.File]::Replace($temporaryPath, $resolvedConfiguration, $backupPath, $true)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

$afterHash = if ($Apply) {
    Get-Sha256Bytes ([IO.File]::ReadAllBytes($resolvedConfiguration))
}
else {
    $beforeHash
}

[ordered]@{
    applied = [bool]$Apply
    changed = ($beforeHash -ne $plannedHash)
    configuration = $resolvedConfiguration
    encoding = $document.encoding.WebName
    newLine = if ($document.newLine -eq "`r`n") { 'CRLF' } else { 'LF' }
    beforeSha256 = $beforeHash
    plannedSha256 = $plannedHash
    afterSha256 = $afterHash
    backup = $backupPath
    operations = $plan.ToArray()
} | ConvertTo-Json -Depth 8
