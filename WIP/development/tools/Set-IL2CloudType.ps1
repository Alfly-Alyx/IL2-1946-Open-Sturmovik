[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [Parameter(Mandatory = $true)][ValidateSet(0, 1)][int]$TypeClouds,
    [string]$BackupRoot,
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedGame = (Resolve-Path -LiteralPath $GameRoot -ErrorAction Stop).Path.TrimEnd('\')
$confPath = Join-Path $resolvedGame 'conf.ini'
if (-not (Test-Path -LiteralPath $confPath -PathType Leaf)) {
    throw "conf.ini absent : $confPath"
}
if ([string]::IsNullOrWhiteSpace($BackupRoot)) {
    $BackupRoot = Join-Path $resolvedGame 'Open-Sturmovik-backups\cloud-ab'
}

$encoding = [Text.Encoding]::GetEncoding(1252)
$originalBytes = [IO.File]::ReadAllBytes($confPath)
$originalText = $encoding.GetString($originalBytes)
$sectionPattern = '(?ms)^\[Render_OpenGL\]\s*\r?\n.*?(?=^\[|\z)'
$sectionMatches = [regex]::Matches($originalText, $sectionPattern)
if ($sectionMatches.Count -ne 1) {
    throw "Une seule section [Render_OpenGL] est attendue, trouvee : $($sectionMatches.Count)."
}

$section = $sectionMatches[0].Value
$cloudPattern = '(?m)^(TypeClouds\s*=\s*)([01])\s*$'
$cloudMatches = [regex]::Matches($section, $cloudPattern)
if ($cloudMatches.Count -ne 1) {
    throw "Une seule valeur TypeClouds=0/1 est attendue dans [Render_OpenGL], trouvee : $($cloudMatches.Count)."
}
$current = [int]$cloudMatches[0].Groups[2].Value
$beforeHash = (Get-FileHash -LiteralPath $confPath -Algorithm SHA256).Hash

[pscustomobject]@{
    ConfIni = $confPath
    CurrentTypeClouds = $current
    RequestedTypeClouds = $TypeClouds
    Changed = $current -ne $TypeClouds
    Sha256Before = $beforeHash
    Mode = if ($ValidateOnly) { 'validate-only' } else { 'apply' }
} | Format-List

if ($ValidateOnly -or $current -eq $TypeClouds) {
    exit 0
}
if (-not $PSCmdlet.ShouldProcess($confPath, "TypeClouds=$TypeClouds dans [Render_OpenGL]")) {
    exit 0
}

$replacementSection = [regex]::Replace(
    $section,
    $cloudPattern,
    { param($match) $match.Groups[1].Value + [string]$TypeClouds },
    1
)
$updatedText = $originalText.Substring(0, $sectionMatches[0].Index) +
    $replacementSection +
    $originalText.Substring($sectionMatches[0].Index + $sectionMatches[0].Length)

$resolvedBackupRoot = [IO.Path]::GetFullPath($BackupRoot)
New-Item -ItemType Directory -Path $resolvedBackupRoot -Force | Out-Null
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss-fff')
$backupPath = Join-Path $resolvedBackupRoot "conf.before-TypeClouds-$TypeClouds-$stamp.ini"
Copy-Item -LiteralPath $confPath -Destination $backupPath -ErrorAction Stop
if ((Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash -ne $beforeHash) {
    throw "La sauvegarde de conf.ini n'est pas identique a la source : $backupPath"
}

$temporaryPath = Join-Path $resolvedGame ('.conf.ini.open-sturmovik.' + [guid]::NewGuid().ToString('N') + '.tmp')
try {
    [IO.File]::WriteAllBytes($temporaryPath, $encoding.GetBytes($updatedText))
    $temporaryText = $encoding.GetString([IO.File]::ReadAllBytes($temporaryPath))
    $temporarySection = [regex]::Match($temporaryText, $sectionPattern).Value
    $temporaryValue = [regex]::Match($temporarySection, $cloudPattern).Groups[2].Value
    if ($temporaryValue -ne [string]$TypeClouds) {
        throw "La verification du fichier temporaire a echoue."
    }
    Move-Item -LiteralPath $temporaryPath -Destination $confPath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

$finalText = $encoding.GetString([IO.File]::ReadAllBytes($confPath))
$finalSection = [regex]::Match($finalText, $sectionPattern).Value
$finalValue = [regex]::Match($finalSection, $cloudPattern).Groups[2].Value
if ($finalValue -ne [string]$TypeClouds) {
    throw "TypeClouds n'a pas ete applique correctement ; sauvegarde : $backupPath"
}

[pscustomobject]@{
    ConfIni = $confPath
    TypeClouds = [int]$finalValue
    Backup = $backupPath
    Sha256After = (Get-FileHash -LiteralPath $confPath -Algorithm SHA256).Hash
    Verified = $true
} | Format-List
