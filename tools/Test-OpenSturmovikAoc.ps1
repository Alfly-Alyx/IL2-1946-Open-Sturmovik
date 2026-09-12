[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$FilesRoot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
if (-not $FilesRoot) { $FilesRoot = Join-Path $root 'Files' }
$files = (Resolve-Path -LiteralPath $FilesRoot).Path
$manifest = Get-Content -LiteralPath (Join-Path $root 'manifests\aoc-v1.15.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.currentSelection -ne 'v1-1a-hsfx4-409m' -or -not $manifest.integration.retiredExtensionAbsent) {
    throw 'Selection AOC sans extension MDS incoherente.'
}

foreach ($entry in $manifest.integration.outputClasses) {
    $path = Join-Path $files ([IO.Path]::GetFileName([string]$entry.path))
    $data = [IO.File]::ReadAllBytes($path)
    if ($data.Length -lt 8 -or [BitConverter]::ToString($data[0..3]) -ne 'CA-FE-BA-BE') {
        throw "ClassFile absent ou invalide : $path"
    }
    $major = ([int]$data[6] -shl 8) -bor [int]$data[7]
    if ($data.Length -ne $entry.length -or $major -ne $entry.major -or $major -gt 47 -or
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.sha256) {
        throw "Classe AOC inattendue : $path"
    }
    if ([Text.Encoding]::GetEncoding(28591).GetString($data) -match '(?i)zuti') {
        throw "Extension retiree encore presente : $path"
    }
}

$profileRoot = Join-Path $root ([string]$manifest.recoveredPayload.profiles.path)
$profiles = @(Get-ChildItem -LiteralPath $profileRoot -File)
[string[]]$names = @($profiles | ForEach-Object Name)
[Array]::Sort($names, [StringComparer]::OrdinalIgnoreCase)
$inventory = foreach ($name in $names) {
    $hash = (Get-FileHash -LiteralPath (Join-Path $profileRoot $name) -Algorithm SHA256).Hash
    $name.ToLowerInvariant() + ' ' + $hash.ToLowerInvariant()
}
$sha = [Security.Cryptography.SHA256]::Create()
try { $digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($inventory -join "`n") + "`n"))).Replace('-', '') }
finally { $sha.Dispose() }
if ($profiles.Count -ne $manifest.recoveredPayload.profiles.count -or
    ($profiles | Measure-Object Length -Sum).Sum -ne $manifest.recoveredPayload.profiles.bytes -or
    $digest -ne $manifest.recoveredPayload.profiles.inventoryDigest) {
    throw 'Les profils AOC ne correspondent pas au contenu conserve.'
}

[pscustomobject]@{
    Status = 'PASS'
    Classes = @($manifest.integration.outputClasses).Count
    Profiles = $profiles.Count
    RetiredExtensionAbsent = $true
    RuntimeValidation = 'pending-user-test'
    FilesRoot = $files
}
