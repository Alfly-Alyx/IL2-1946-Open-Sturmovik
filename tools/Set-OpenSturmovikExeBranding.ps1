[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputPath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('OpenSturmovik.NativeResources' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace OpenSturmovik {
    public static class NativeResources {
        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr BeginUpdateResource(string fileName, bool deleteExistingResources);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool UpdateResource(
            IntPtr update,
            IntPtr type,
            IntPtr name,
            ushort language,
            byte[] data,
            uint dataSize
        );

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool EndUpdateResource(IntPtr update, bool discard);
    }
}
'@
}

function Add-UInt16 {
    param([Collections.Generic.List[byte]]$Buffer, [uint16]$Value)
    $Buffer.AddRange([BitConverter]::GetBytes($Value))
}

function Add-UInt32 {
    param([Collections.Generic.List[byte]]$Buffer, [uint32]$Value)
    $Buffer.AddRange([BitConverter]::GetBytes($Value))
}

function Add-UnicodeZ {
    param([Collections.Generic.List[byte]]$Buffer, [string]$Value)
    $Buffer.AddRange([Text.Encoding]::Unicode.GetBytes($Value + [char]0))
}

function Align-ResourceBlock {
    param([Collections.Generic.List[byte]]$Buffer)
    while (($Buffer.Count % 4) -ne 0) {
        $Buffer.Add(0)
    }
}

function Start-ResourceBlock {
    param(
        [Collections.Generic.List[byte]]$Buffer,
        [uint16]$ValueLength,
        [uint16]$Type,
        [string]$Key
    )
    $start = $Buffer.Count
    Add-UInt16 $Buffer 0
    Add-UInt16 $Buffer $ValueLength
    Add-UInt16 $Buffer $Type
    Add-UnicodeZ $Buffer $Key
    Align-ResourceBlock $Buffer
    return $start
}

function Complete-ResourceBlock {
    param([Collections.Generic.List[byte]]$Buffer, [int]$Start)
    $length = $Buffer.Count - $Start
    if ($length -gt [uint16]::MaxValue) {
        throw "Bloc VERSIONINFO trop volumineux : $length octets."
    }
    $bytes = [BitConverter]::GetBytes([uint16]$length)
    $Buffer[$Start] = $bytes[0]
    $Buffer[$Start + 1] = $bytes[1]
}

function Add-VersionString {
    param(
        [Collections.Generic.List[byte]]$Buffer,
        [string]$Key,
        [string]$Value
    )
    $start = Start-ResourceBlock $Buffer ([uint16]($Value.Length + 1)) 1 $Key
    Add-UnicodeZ $Buffer $Value
    Align-ResourceBlock $Buffer
    Complete-ResourceBlock $Buffer $start
}

function New-VersionResource {
    $buffer = [Collections.Generic.List[byte]]::new()
    $root = Start-ResourceBlock $buffer 52 0 'VS_VERSION_INFO'

    # VS_FIXEDFILEINFO: version 1.15.0.0, Windows 32-bit application.
    foreach ($value in @(
        0xFEEF04BDL, 0x00010000L, 0x0001000FL, 0L,
        0x0001000FL, 0L, 0x0000003FL, 0L,
        0x00040004L, 1L, 0L, 0L, 0L
    )) {
        Add-UInt32 $buffer ([uint32]$value)
    }
    Align-ResourceBlock $buffer

    $stringFileInfo = Start-ResourceBlock $buffer 0 1 'StringFileInfo'
    $stringTable = Start-ResourceBlock $buffer 0 1 '040904B0'
    $strings = [ordered]@{
        CompanyName      = 'Open Sturmovik Project'
        FileDescription  = 'Open Sturmovik'
        FileVersion      = '1.15.0.0'
        InternalName     = 'OpenSturmovik'
        OriginalFilename = 'il2fb.exe'
        ProductName      = 'Open Sturmovik'
        ProductVersion   = '1.15.0.0'
    }
    foreach ($entry in $strings.GetEnumerator()) {
        Add-VersionString $buffer ([string]$entry.Key) ([string]$entry.Value)
    }
    Complete-ResourceBlock $buffer $stringTable
    Complete-ResourceBlock $buffer $stringFileInfo

    $varFileInfo = Start-ResourceBlock $buffer 0 1 'VarFileInfo'
    $translation = Start-ResourceBlock $buffer 4 0 'Translation'
    Add-UInt16 $buffer 0x0409
    Add-UInt16 $buffer 0x04B0
    Align-ResourceBlock $buffer
    Complete-ResourceBlock $buffer $translation
    Complete-ResourceBlock $buffer $varFileInfo
    Complete-ResourceBlock $buffer $root
    return $buffer.ToArray()
}

function Get-PeCodeIdentity {
    param([string]$Path)
    $data = [IO.File]::ReadAllBytes($Path)
    if ($data.Length -lt 512 -or $data[0] -ne 0x4D -or $data[1] -ne 0x5A) {
        throw "Executable PE invalide : $Path"
    }
    $pe = [BitConverter]::ToInt32($data, 0x3C)
    if ($pe -lt 0 -or $pe + 24 -ge $data.Length -or
        $data[$pe] -ne 0x50 -or $data[$pe + 1] -ne 0x45) {
        throw "Signature PE absente : $Path"
    }
    $machine = [BitConverter]::ToUInt16($data, $pe + 4)
    $sectionCount = [BitConverter]::ToUInt16($data, $pe + 6)
    $optionalSize = [BitConverter]::ToUInt16($data, $pe + 20)
    $optional = $pe + 24
    $entryPoint = [BitConverter]::ToUInt32($data, $optional + 16)
    $sections = $optional + $optionalSize
    $textHash = $null
    $textSize = 0
    for ($index = 0; $index -lt $sectionCount; ++$index) {
        $offset = $sections + ($index * 40)
        $name = [Text.Encoding]::ASCII.GetString($data, $offset, 8).TrimEnd([char]0)
        if ($name -ne '.text') {
            continue
        }
        $textSize = [BitConverter]::ToUInt32($data, $offset + 16)
        $textOffset = [BitConverter]::ToUInt32($data, $offset + 20)
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $textHash = [Convert]::ToHexString($sha.ComputeHash($data, $textOffset, $textSize))
        } finally {
            $sha.Dispose()
        }
    }
    if (-not $textHash) {
        throw "Section .text absente : $Path"
    }
    [pscustomobject]@{
        Machine = $machine
        EntryPoint = $entryPoint
        TextSize = $textSize
        TextSha256 = $textHash
    }
}

$input = [IO.Path]::GetFullPath($InputPath)
$output = [IO.Path]::GetFullPath($OutputPath)
if (-not (Test-Path -LiteralPath $input -PathType Leaf)) {
    throw "Executable source absent : $input"
}
$inputHash = (Get-FileHash -LiteralPath $input -Algorithm SHA256).Hash
if ($inputHash -ne $ExpectedSha256.ToUpperInvariant()) {
    throw "Empreinte source inattendue : $inputHash"
}

$outputDirectory = Split-Path -Parent $output
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}
Copy-Item -LiteralPath $input -Destination $output -Force
$before = Get-PeCodeIdentity $input
$resource = New-VersionResource
$handle = [OpenSturmovik.NativeResources]::BeginUpdateResource($output, $false)
if ($handle -eq [IntPtr]::Zero) {
    throw "BeginUpdateResource a echoue (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
}
$committed = $false
try {
    $ok = [OpenSturmovik.NativeResources]::UpdateResource(
        $handle,
        [IntPtr]16,
        [IntPtr]1,
        [uint16]0x0409,
        $resource,
        [uint32]$resource.Length
    )
    if (-not $ok) {
        throw "UpdateResource a echoue (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
    }
    if (-not [OpenSturmovik.NativeResources]::EndUpdateResource($handle, $false)) {
        throw "EndUpdateResource a echoue (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
    }
    $committed = $true
} finally {
    if (-not $committed) {
        [void][OpenSturmovik.NativeResources]::EndUpdateResource($handle, $true)
    }
}

$after = Get-PeCodeIdentity $output
if ($before.Machine -ne $after.Machine -or
    $before.EntryPoint -ne $after.EntryPoint -or
    $before.TextSize -ne $after.TextSize -or
    $before.TextSha256 -ne $after.TextSha256) {
    throw 'Le code PE a change pendant l ajout de la ressource VERSIONINFO.'
}

$version = (Get-Item -LiteralPath $output).VersionInfo
if ($version.FileDescription -ne 'Open Sturmovik' -or
    $version.ProductName -ne 'Open Sturmovik' -or
    $version.FileVersion -ne '1.15.0.0' -or
    $version.OriginalFilename -ne 'il2fb.exe') {
    throw 'La ressource VERSIONINFO produite ne peut pas etre relue correctement par Windows.'
}

[pscustomobject]@{
    InputSha256 = $inputHash
    OutputSha256 = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    FileDescription = $version.FileDescription
    ProductName = $version.ProductName
    OriginalFilename = $version.OriginalFilename
    Machine = ('0x{0:X4}' -f $after.Machine)
    EntryPoint = ('0x{0:X8}' -f $after.EntryPoint)
    TextSha256 = $after.TextSha256
}
