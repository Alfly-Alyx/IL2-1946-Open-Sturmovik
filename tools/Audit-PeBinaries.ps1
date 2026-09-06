[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$OutputPath
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-MachineName {
    param([uint16]$Machine)
    switch ($Machine) {
        0x014C { 'i386' }
        0x8664 { 'amd64' }
        0x01C0 { 'arm' }
        0xAA64 { 'arm64' }
        default { '0x{0:X4}' -f $Machine }
    }
}

function Get-SubsystemName {
    param([uint16]$Subsystem)
    switch ($Subsystem) {
        2 { 'windows-gui' }
        3 { 'windows-console' }
        9 { 'windows-ce' }
        10 { 'efi-application' }
        default { $Subsystem.ToString() }
    }
}

function Read-PeMetadata {
    param([System.IO.FileInfo]$File, [string]$ResolvedRoot)

    $bytes = [System.IO.File]::ReadAllBytes($File.FullName)
    if ($bytes.Length -lt 256 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
        return [pscustomobject][ordered]@{
            path = [IO.Path]::GetRelativePath($ResolvedRoot, $File.FullName).Replace('\', '/')
            size = $File.Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName).Hash
            pe = $false
            error = 'signature MZ absente'
        }
    }

    $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
    if ($peOffset -lt 0 -or ($peOffset + 96) -gt $bytes.Length -or
        $bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or
        $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) {
        return [pscustomobject][ordered]@{
            path = [IO.Path]::GetRelativePath($ResolvedRoot, $File.FullName).Replace('\', '/')
            size = $File.Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName).Hash
            pe = $false
            error = 'en-tete PE absent ou hors limites'
        }
    }

    $machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
    $timestamp = [BitConverter]::ToUInt32($bytes, $peOffset + 8)
    $characteristics = [BitConverter]::ToUInt16($bytes, $peOffset + 22)
    $optionalOffset = $peOffset + 24
    $optionalMagic = [BitConverter]::ToUInt16($bytes, $optionalOffset)
    $subsystem = [BitConverter]::ToUInt16($bytes, $optionalOffset + 68)
    $version = $File.VersionInfo
    $timestampUtc = [DateTimeOffset]::FromUnixTimeSeconds($timestamp).UtcDateTime.ToString('o')

    [pscustomobject][ordered]@{
        path = [IO.Path]::GetRelativePath($ResolvedRoot, $File.FullName).Replace('\', '/')
        size = $File.Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File.FullName).Hash
        pe = $true
        machine = Get-MachineName $machine
        format = switch ($optionalMagic) { 0x010B { 'PE32' } 0x020B { 'PE32+' } default { '0x{0:X4}' -f $optionalMagic } }
        large_address_aware = (($characteristics -band 0x20) -ne 0)
        dll = (($characteristics -band 0x2000) -ne 0)
        subsystem = Get-SubsystemName $subsystem
        pe_timestamp_utc = $timestampUtc
        file_version = $version.FileVersion
        product_name = $version.ProductName
        company_name = $version.CompanyName
    }
}

$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
$rootFiles = @(Get-ChildItem -LiteralPath $resolvedRoot -File -ErrorAction Stop)
$rootDirectories = @(Get-ChildItem -LiteralPath $resolvedRoot -Directory -ErrorAction Stop |
    Where-Object { $_.Name -notin @('.git', 'WIP') })
$files = @($rootFiles + @($rootDirectories | ForEach-Object {
        Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction Stop
    }) |
    Where-Object { $_.Extension -in @('.exe', '.dll') } |
    Sort-Object FullName)

$records = @($files | ForEach-Object { Read-PeMetadata -File $_ -ResolvedRoot $resolvedRoot })
$manifest = [pscustomobject][ordered]@{
    schema = 1
    generated_utc = [DateTime]::UtcNow.ToString('o')
    root = $resolvedRoot
    file_count = $records.Count
    pe_count = @($records | Where-Object pe).Count
    files = $records
}

if ($OutputPath) {
    $destination = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
    $destinationDirectory = Split-Path -Parent $destination
    [IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
    $temporary = "$destination.new-$([Guid]::NewGuid().ToString('N'))"
    try {
        [IO.File]::WriteAllText($temporary, ($manifest | ConvertTo-Json -Depth 6), (New-Object Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporary -Destination $destination -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
    }
}

$manifest
