[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),
    [string]$OutputRoot,
    [switch]$Install
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $root 'build\b29-silverplate-cockpit'
}
$output = [IO.Path]::GetFullPath($OutputRoot)
$source = Join-Path $root 'Files\7BCE3C02C280ED18'
$staged = Join-Path $output 'files-staging\7BCE3C02C280ED18'
$manifest = Join-Path $output 'manifest.json'
$knownHashes = @(
    '94312FF3B395E081B785871C0D584E2EEB9E14C4BF2C77A22AAB250D31E6AF6F',
    '0A83344F9617AECF9F2B0B50B06B265E7C41F2A733B226DA32656465AF994992'
)

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Classe B_29SP absente : $source"
}
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
if ($sourceHash -notin $knownHashes) {
    throw "Classe B_29SP non reconnue : $sourceHash"
}
[IO.Directory]::CreateDirectory((Split-Path -Parent $staged)) | Out-Null

& python (Join-Path $root 'tools\Patch-B29SilverplateCockpit.py') `
    --input $source --output $staged --json $manifest
if ($LASTEXITCODE -ne 0) {
    throw "Correction du cockpit B-29 Silverplate impossible (code $LASTEXITCODE)."
}

$backupPath = $null
if ($Install) {
    $backupPath = Join-Path $output ('backup-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmssZ'))
    [IO.Directory]::CreateDirectory($backupPath) | Out-Null
    Copy-Item -LiteralPath $source -Destination (Join-Path $backupPath '7BCE3C02C280ED18') -Force
    Copy-Item -LiteralPath $staged -Destination $source -Force
}

[pscustomobject]@{
    Output = $output
    Manifest = $manifest
    Staging = $staged
    Installed = [bool]$Install
    Backup = $backupPath
    Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $staged).Hash
}
