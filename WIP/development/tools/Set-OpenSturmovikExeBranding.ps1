[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputPath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedSha256,

    [Parameter(Mandatory)]
    [string]$IconPath
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

        [DllImport("kernel32.dll", EntryPoint = "UpdateResourceW", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool UpdateResourceByName(
            IntPtr update,
            IntPtr type,
            string name,
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

function Read-IconFile {
    param([string]$Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 6 -or
        [BitConverter]::ToUInt16($bytes, 0) -ne 0 -or
        [BitConverter]::ToUInt16($bytes, 2) -ne 1) {
        throw "Fichier ICO invalide : $Path"
    }
    $count = [BitConverter]::ToUInt16($bytes, 4)
    if ($count -lt 1 -or $count -gt 64 -or $bytes.Length -lt 6 + (16 * $count)) {
        throw "Repertoire ICO invalide : $Path"
    }
    $entries = [Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $count; ++$index) {
        $offset = 6 + (16 * $index)
        $imageSize = [BitConverter]::ToUInt32($bytes, $offset + 8)
        $imageOffset = [BitConverter]::ToUInt32($bytes, $offset + 12)
        $imageEnd = [uint64]$imageOffset + [uint64]$imageSize
        if ($imageSize -eq 0 -or $imageEnd -gt [uint64]$bytes.Length) {
            throw "Image ICO hors limites a l index $index : $Path"
        }
        $image = [byte[]]::new($imageSize)
        [Array]::Copy($bytes, [int]$imageOffset, $image, 0, [int]$imageSize)
        $entries.Add([pscustomobject]@{
            Width = $bytes[$offset]
            Height = $bytes[$offset + 1]
            ColorCount = $bytes[$offset + 2]
            Reserved = $bytes[$offset + 3]
            Planes = [BitConverter]::ToUInt16($bytes, $offset + 4)
            BitCount = [BitConverter]::ToUInt16($bytes, $offset + 6)
            Image = $image
        })
    }
    return $entries.ToArray()
}

function New-GroupIconResource {
    param([object[]]$Entries)
    $buffer = [Collections.Generic.List[byte]]::new()
    Add-UInt16 $buffer 0
    Add-UInt16 $buffer 1
    Add-UInt16 $buffer ([uint16]$Entries.Count)
    for ($index = 0; $index -lt $Entries.Count; ++$index) {
        $entry = $Entries[$index]
        $buffer.Add([byte]$entry.Width)
        $buffer.Add([byte]$entry.Height)
        $buffer.Add([byte]$entry.ColorCount)
        $buffer.Add([byte]$entry.Reserved)
        Add-UInt16 $buffer ([uint16]$entry.Planes)
        Add-UInt16 $buffer ([uint16]$entry.BitCount)
        Add-UInt32 $buffer ([uint32]$entry.Image.Length)
        Add-UInt16 $buffer ([uint16]($index + 1))
    }
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

function Get-PeFileOffsetFromRva {
    param([byte[]]$Data, [uint32]$Rva)
    $pe = [BitConverter]::ToInt32($Data, 0x3C)
    $sectionCount = [BitConverter]::ToUInt16($Data, $pe + 6)
    $optionalSize = [BitConverter]::ToUInt16($Data, $pe + 20)
    $sections = $pe + 24 + $optionalSize
    for ($index = 0; $index -lt $sectionCount; ++$index) {
        $offset = $sections + ($index * 40)
        $virtualSize = [BitConverter]::ToUInt32($Data, $offset + 8)
        $virtualAddress = [BitConverter]::ToUInt32($Data, $offset + 12)
        $rawSize = [BitConverter]::ToUInt32($Data, $offset + 16)
        $rawOffset = [BitConverter]::ToUInt32($Data, $offset + 20)
        $mappedSize = [Math]::Max([uint64]$virtualSize, [uint64]$rawSize)
        if ($Rva -ge $virtualAddress -and [uint64]$Rva -lt [uint64]$virtualAddress + $mappedSize) {
            return [int]([uint64]$rawOffset + ([uint64]$Rva - [uint64]$virtualAddress))
        }
    }
    throw ('RVA 0x{0:X8} hors des sections PE.' -f $Rva)
}

function Set-WindowClassIconBinding {
    param([string]$Path)
    $data = [IO.File]::ReadAllBytes($Path)
    $patches = @(
        [pscustomobject]@{
            Rva = [uint32]0x0000D820
            Before = [byte[]](0x68, 0x00, 0x7F, 0x00, 0x00, 0x56)
            After = [byte[]](0x68, 0x00, 0x7F, 0x00, 0x00, 0x50)
            Meaning = 'RegisterClassW: LoadIconA(hInstance, 0x7F00)'
        },
        [pscustomobject]@{
            Rva = [uint32]0x0000D88E
            Before = [byte[]](0x68, 0x00, 0x7F, 0x00, 0x00, 0x56)
            After = [byte[]](0x68, 0x00, 0x7F, 0x00, 0x00, 0x52)
            Meaning = 'RegisterClassA: LoadIconA(hInstance, 0x7F00)'
        }
    )
    $changed = 0
    foreach ($patch in $patches) {
        $offset = Get-PeFileOffsetFromRva -Data $data -Rva $patch.Rva
        $current = [byte[]]::new($patch.Before.Length)
        [Array]::Copy($data, $offset, $current, 0, $current.Length)
        $isBefore = [Linq.Enumerable]::SequenceEqual($current, $patch.Before)
        $isAfter = [Linq.Enumerable]::SequenceEqual($current, $patch.After)
        if (-not $isBefore -and -not $isAfter) {
            throw ('Sequence inattendue au RVA 0x{0:X8} ; correction de l icone refusee.' -f $patch.Rva)
        }
        if ($isBefore) {
            [Array]::Copy($patch.After, 0, $data, $offset, $patch.After.Length)
            ++$changed
        }
    }
    if ($changed -gt 0) {
        [IO.File]::WriteAllBytes($Path, $data)
    }
    [pscustomobject]@{ Bindings = $patches.Count; Changed = $changed }
}

$input = [IO.Path]::GetFullPath($InputPath)
$output = [IO.Path]::GetFullPath($OutputPath)
$icon = [IO.Path]::GetFullPath($IconPath)
if (-not (Test-Path -LiteralPath $input -PathType Leaf)) {
    throw "Executable source absent : $input"
}
if (-not (Test-Path -LiteralPath $icon -PathType Leaf)) {
    throw "Icone source absente : $icon"
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
$iconEntries = Read-IconFile $icon
$groupIcon = New-GroupIconResource $iconEntries
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
    for ($index = 0; $index -lt $iconEntries.Count; ++$index) {
        $image = [byte[]]$iconEntries[$index].Image
        $ok = [OpenSturmovik.NativeResources]::UpdateResource(
            $handle,
            [IntPtr]3,
            [IntPtr]($index + 1),
            [uint16]0x0419,
            $image,
            [uint32]$image.Length
        )
        if (-not $ok) {
            throw "Ajout de l image ICO $($index + 1) impossible (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
        }
    }
    # Le nouveau groupe reference uniquement les six images de l'ICO. Une
    # ancienne image non referencee peut rester sans influer sur le resultat.
    $ok = [OpenSturmovik.NativeResources]::UpdateResourceByName(
        $handle,
        [IntPtr]14,
        'IL2ICON',
        [uint16]0x0419,
        $groupIcon,
        [uint32]$groupIcon.Length
    )
    if (-not $ok) {
        throw "Remplacement du groupe IL2ICON impossible (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
    }
    # IL-2 enregistre sa classe de fenetre avec l'identifiant numerique 0x7F00.
    # Le groupe nomme IL2ICON reste le premier groupe de l'EXE pour Explorer.
    $ok = [OpenSturmovik.NativeResources]::UpdateResource(
        $handle,
        [IntPtr]14,
        [IntPtr]0x7F00,
        [uint16]0x0419,
        $groupIcon,
        [uint32]$groupIcon.Length
    )
    if (-not $ok) {
        throw "Ajout du groupe d icone de fenetre 0x7F00 impossible (Win32 $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
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

$afterResources = Get-PeCodeIdentity $output
if ($before.Machine -ne $afterResources.Machine -or
    $before.EntryPoint -ne $afterResources.EntryPoint -or
    $before.TextSize -ne $afterResources.TextSize -or
    $before.TextSha256 -ne $afterResources.TextSha256) {
    throw 'Le code PE a change pendant l ajout des ressources Windows.'
}
$windowIconBinding = Set-WindowClassIconBinding -Path $output
$after = Get-PeCodeIdentity $output
if ($before.Machine -ne $after.Machine -or
    $before.EntryPoint -ne $after.EntryPoint -or
    $before.TextSize -ne $after.TextSize) {
    throw 'La structure du code PE a change pendant le marquage.'
}

$version = (Get-Item -LiteralPath $output).VersionInfo
if ($version.FileDescription -ne 'Open Sturmovik' -or
    $version.ProductName -ne 'Open Sturmovik' -or
    $version.FileVersion -ne '1.15.0.0' -or
    $version.OriginalFilename -ne 'il2fb.exe') {
    throw 'La ressource VERSIONINFO produite ne peut pas etre relue correctement par Windows.'
}
Add-Type -AssemblyName System.Drawing
$embeddedIcon = [Drawing.Icon]::ExtractAssociatedIcon($output)
if ($null -eq $embeddedIcon) {
    throw 'La ressource IL2ICON produite ne peut pas etre relue correctement par Windows.'
}
try {
    $embeddedIconSize = '{0}x{1}' -f $embeddedIcon.Width, $embeddedIcon.Height
} finally {
    $embeddedIcon.Dispose()
}

[pscustomobject]@{
    InputSha256 = $inputHash
    OutputSha256 = (Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash
    FileDescription = $version.FileDescription
    ProductName = $version.ProductName
    OriginalFilename = $version.OriginalFilename
    IconSha256 = (Get-FileHash -LiteralPath $icon -Algorithm SHA256).Hash
    IconImages = $iconEntries.Count
    EmbeddedIconSize = $embeddedIconSize
    WindowIconBindings = $windowIconBinding.Bindings
    WindowIconBindingsChanged = $windowIconBinding.Changed
    Machine = ('0x{0:X4}' -f $after.Machine)
    EntryPoint = ('0x{0:X8}' -f $after.EntryPoint)
    TextSha256 = $after.TextSha256
}
