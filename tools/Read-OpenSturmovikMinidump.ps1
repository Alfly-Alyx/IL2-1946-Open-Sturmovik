[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$DumpPath)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$resolvedDump = (Resolve-Path -LiteralPath $DumpPath -ErrorAction Stop).Path
$stream = [IO.File]::Open($resolvedDump, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
$reader = New-Object IO.BinaryReader($stream)

function Set-ReaderPosition {
    param([long]$Offset, [long]$Required = 1)
    if ($Offset -lt 0 -or $Required -lt 0 -or $Offset + $Required -gt $stream.Length) {
        throw "Structure minidump hors limites : offset=$Offset taille=$Required longueur=$($stream.Length)"
    }
    $stream.Position = $Offset
}

function Read-MinidumpString {
    param([uint32]$Rva)
    if ($Rva -eq 0) { return '' }
    Set-ReaderPosition -Offset $Rva -Required 4
    $byteLength = $reader.ReadUInt32()
    if ($byteLength -gt 1048576) { throw "Chaine minidump anormalement longue : $byteLength" }
    Set-ReaderPosition -Offset ([long]$Rva + 4) -Required $byteLength
    return [Text.Encoding]::Unicode.GetString($reader.ReadBytes([int]$byteLength))
}

try {
    Set-ReaderPosition -Offset 0 -Required 32
    $signature = $reader.ReadUInt32()
    if ($signature -ne 0x504D444D) { throw 'Signature MDMP absente.' }
    $version = $reader.ReadUInt32()
    $streamCount = $reader.ReadUInt32()
    $directoryRva = $reader.ReadUInt32()
    $checksum = $reader.ReadUInt32()
    $timestamp = $reader.ReadUInt32()
    $flags = $reader.ReadUInt64()
    if ($streamCount -gt 4096) { throw "Nombre de flux minidump invalide : $streamCount" }
    Set-ReaderPosition -Offset $directoryRva -Required ([long]$streamCount * 12)
    $directories = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $streamCount; $index++) {
        $directories.Add([pscustomobject][ordered]@{
            type = $reader.ReadUInt32()
            size = $reader.ReadUInt32()
            rva = $reader.ReadUInt32()
        })
    }

    $system = $null
    $systemDirectory = @($directories | Where-Object type -eq 7 | Select-Object -First 1)
    if ($systemDirectory.Count -gt 0 -and $systemDirectory[0].size -ge 30) {
        Set-ReaderPosition -Offset $systemDirectory[0].rva -Required 30
        $architecture = $reader.ReadUInt16()
        $processorLevel = $reader.ReadUInt16()
        $processorRevision = $reader.ReadUInt16()
        $processorCount = $reader.ReadByte()
        $productType = $reader.ReadByte()
        $major = $reader.ReadUInt32()
        $minor = $reader.ReadUInt32()
        $build = $reader.ReadUInt32()
        $platform = $reader.ReadUInt32()
        $csdRva = $reader.ReadUInt32()
        $suiteMask = $reader.ReadUInt16()
        $system = [ordered]@{
            architecture = [int]$architecture
            processor_level = [int]$processorLevel
            processor_revision = [int]$processorRevision
            processor_count = [int]$processorCount
            product_type = [int]$productType
            os_version = "$major.$minor.$build"
            platform_id = [long]$platform
            service_pack = Read-MinidumpString -Rva $csdRva
            suite_mask = [int]$suiteMask
        }
    }

    $modules = [Collections.Generic.List[object]]::new()
    $moduleDirectory = @($directories | Where-Object type -eq 4 | Select-Object -First 1)
    if ($moduleDirectory.Count -gt 0 -and $moduleDirectory[0].size -ge 4) {
        Set-ReaderPosition -Offset $moduleDirectory[0].rva -Required 4
        $moduleCount = $reader.ReadUInt32()
        if ($moduleCount -gt 65535) { throw "Nombre de modules minidump invalide : $moduleCount" }
        Set-ReaderPosition -Offset ([long]$moduleDirectory[0].rva + 4) -Required ([long]$moduleCount * 108)
        for ($index = 0; $index -lt $moduleCount; $index++) {
            $moduleOffset = [long]$moduleDirectory[0].rva + 4 + ([long]$index * 108)
            Set-ReaderPosition -Offset $moduleOffset -Required 108
            $base = $reader.ReadUInt64()
            $size = $reader.ReadUInt32()
            $moduleChecksum = $reader.ReadUInt32()
            $moduleTimestamp = $reader.ReadUInt32()
            $nameRva = $reader.ReadUInt32()
            $name = Read-MinidumpString -Rva $nameRva
            $modules.Add([pscustomobject][ordered]@{
                name = [IO.Path]::GetFileName($name)
                base = ('0x{0:X16}' -f $base)
                base_value = [uint64]$base
                size = [long]$size
                checksum = ('0x{0:X8}' -f $moduleChecksum)
                timestamp = [long]$moduleTimestamp
            })
        }
    }

    $exception = $null
    $exceptionDirectory = @($directories | Where-Object type -eq 6 | Select-Object -First 1)
    if ($exceptionDirectory.Count -gt 0 -and $exceptionDirectory[0].size -ge 40) {
        Set-ReaderPosition -Offset $exceptionDirectory[0].rva -Required 40
        $threadId = $reader.ReadUInt32()
        $alignment = $reader.ReadUInt32()
        $code = $reader.ReadUInt32()
        $exceptionFlags = $reader.ReadUInt32()
        $record = $reader.ReadUInt64()
        $address = $reader.ReadUInt64()
        $parameterCount = $reader.ReadUInt32()
        $unused = $reader.ReadUInt32()
        $faultModule = $null
        foreach ($module in $modules) {
            $moduleBase = [uint64]$module.base_value
            if ($address -ge $moduleBase -and $address -lt ($moduleBase + [uint64]$module.size)) {
                $faultModule = $module
                break
            }
        }
        $exception = [ordered]@{
            thread_id = [long]$threadId
            code = ('0x{0:X8}' -f $code)
            flags = ('0x{0:X8}' -f $exceptionFlags)
            address = ('0x{0:X16}' -f $address)
            module = if ($faultModule) { [string]$faultModule.name } else { '' }
            module_offset = if ($faultModule) { '0x{0:X}' -f ($address - [uint64]$faultModule.base_value) } else { '' }
            parameter_count = [long]$parameterCount
        }
    }

    [pscustomobject][ordered]@{
        format = 'MINIDUMP'
        valid = $true
        size = $stream.Length
        version = ('0x{0:X8}' -f $version)
        checksum = ('0x{0:X8}' -f $checksum)
        timestamp = [long]$timestamp
        flags = ('0x{0:X16}' -f $flags)
        stream_count = [long]$streamCount
        system = $system
        exception = $exception
        modules = @($modules | ForEach-Object {
            [ordered]@{ name = $_.name; base = $_.base; size = $_.size; checksum = $_.checksum; timestamp = $_.timestamp }
        })
    }
}
finally {
    $reader.Dispose()
    $stream.Dispose()
}
