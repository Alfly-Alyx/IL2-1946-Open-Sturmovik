[CmdletBinding()]
param(
    [string]$ResourceDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ResourceDirectory)) {
    $ResourceDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) '_Game Switcher\Resources\Loading Rotation'
}
Add-Type -AssemblyName System.Drawing

# The sources stay byte-for-byte intact. Only the image container changes.
# TGA: type 2, BGR 24-bit, no RLE, bottom-left origin, no alpha or color map.
if (-not ('OpenSturmovik.LoadingRotationPixels' -as [type])) {
    Add-Type -TypeDefinition @"
namespace OpenSturmovik {
    public static class LoadingRotationPixels {
        public static byte[] ToBgr24(byte[] bgra) {
            if ((bgra.Length % 4) != 0) throw new System.ArgumentException("Invalid BGRA buffer.");
            byte[] bgr = new byte[bgra.Length / 4 * 3];
            for (int src = 0, dst = 0; src < bgra.Length; src += 4, dst += 3) {
                if (bgra[src + 3] != 255) throw new System.InvalidOperationException("Transparent source: RGB conversion would lose alpha.");
                bgr[dst] = bgra[src];
                bgr[dst + 1] = bgra[src + 1];
                bgr[dst + 2] = bgra[src + 2];
            }
            return bgr;
        }
        public static bool Equal(byte[] a, byte[] b) {
            if (a.Length != b.Length) return false;
            for (int i = 0; i < a.Length; ++i) if (a[i] != b[i]) return false;
            return true;
        }
    }
}
"@
}

function Read-SourcePixels {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bitmap = [System.Drawing.Bitmap]::FromFile($Path)
    try {
        if ($bitmap.Width -gt 65535 -or $bitmap.Height -gt 65535) {
            throw "Image exceeds the TGA 16-bit dimension fields: $Path"
        }
        $rectangle = New-Object System.Drawing.Rectangle(0, 0, $bitmap.Width, $bitmap.Height)
        $locked = $bitmap.LockBits($rectangle, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $rowLength = $bitmap.Width * 4
            $pixels = New-Object byte[] ($rowLength * $bitmap.Height)
            for ($row = 0; $row -lt $bitmap.Height; $row++) {
                $rowPointer = [IntPtr]::Add($locked.Scan0, $row * $locked.Stride)
                [System.Runtime.InteropServices.Marshal]::Copy($rowPointer, $pixels, $row * $rowLength, $rowLength)
            }
            $bgr = [OpenSturmovik.LoadingRotationPixels]::ToBgr24($pixels)
            return [pscustomobject]@{ Width = $bitmap.Width; Height = $bitmap.Height; Bgr = $bgr }
        }
        finally { $bitmap.UnlockBits($locked) }
    }
    finally { $bitmap.Dispose() }
}

function Write-VerifiedTga {
    param([Parameter(Mandatory = $true)]$SourcePixels, [Parameter(Mandatory = $true)][string]$Path)
    $header = New-Object byte[] 18
    $header[2] = 2
    $header[12] = $SourcePixels.Width -band 255
    $header[13] = ($SourcePixels.Width -shr 8) -band 255
    $header[14] = $SourcePixels.Height -band 255
    $header[15] = ($SourcePixels.Height -shr 8) -band 255
    $header[16] = 24
    $header[17] = 0
    $temporaryPath = "$Path.building-$([Guid]::NewGuid().ToString('N'))"
    try {
        $stream = [System.IO.File]::Open($temporaryPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            $stream.Write($header, 0, $header.Length)
            # The existing game background uses bottom-left origin. Reverse only
            # row storage; decoded pixels remain identical to the PNG source.
            $rowLength = $SourcePixels.Width * 3
            for ($row = $SourcePixels.Height - 1; $row -ge 0; $row--) {
                $stream.Write($SourcePixels.Bgr, $row * $rowLength, $rowLength)
            }
        }
        finally { $stream.Dispose() }

        # Decode the stored TGA independently from its header, then compare all pixels.
        $reader = New-Object System.IO.BinaryReader([System.IO.File]::OpenRead($temporaryPath))
        try {
            $decodedHeader = $reader.ReadBytes(18)
            if ($decodedHeader.Length -ne 18 -or $decodedHeader[0] -ne 0 -or $decodedHeader[1] -ne 0 -or $decodedHeader[2] -ne 2 -or $decodedHeader[16] -ne 24 -or $decodedHeader[17] -ne 0) {
                throw "Unexpected TGA header: $Path"
            }
            $decodedWidth = [int]$decodedHeader[12] + ([int]$decodedHeader[13] -shl 8)
            $decodedHeight = [int]$decodedHeader[14] + ([int]$decodedHeader[15] -shl 8)
            if ($decodedWidth -ne $SourcePixels.Width -or $decodedHeight -ne $SourcePixels.Height) {
                throw "TGA dimensions differ from the source: $Path"
            }
            $storedPixels = $reader.ReadBytes($decodedWidth * $decodedHeight * 3)
            if ($storedPixels.Length -ne $decodedWidth * $decodedHeight * 3) { throw "Truncated TGA pixels: $Path" }
            $decodedPixels = New-Object byte[] $storedPixels.Length
            $decodedRowLength = $decodedWidth * 3
            for ($storedRow = 0; $storedRow -lt $decodedHeight; $storedRow++) {
                $displayRow = $decodedHeight - 1 - $storedRow
                [Buffer]::BlockCopy($storedPixels, $storedRow * $decodedRowLength, $decodedPixels, $displayRow * $decodedRowLength, $decodedRowLength)
            }
            if ($reader.BaseStream.Position -ne $reader.BaseStream.Length -or -not [OpenSturmovik.LoadingRotationPixels]::Equal($decodedPixels, $SourcePixels.Bgr)) {
                throw "TGA pixels differ from the source: $Path"
            }
        }
        finally { $reader.Dispose() }
        [System.IO.File]::Copy($temporaryPath, $Path, $true)
    }
    finally {
        if ([System.IO.File]::Exists($temporaryPath)) { [System.IO.File]::Delete($temporaryPath) }
    }
}

# Final selection provided by Alexis; only il2-2001 has the official double weight.
$definitions = @(
    [pscustomobject]@{ Id = 'forgotten-battles-box'; Label = 'Forgotten Battles - jaquette, logo gauche'; Weight = 1; SourceFilename = 'Forgotten Battles - jaquette remaster 1586x992 - logo gauche.png' },
    [pscustomobject]@{ Id = 'il2-2001'; Label = 'IL-2 Sturmovik 2001 Retail - officiel'; Weight = 2; SourceFilename = 'IL-2 Sturmovik 2001 Retail - remaster 1586x992.png' },
    [pscustomobject]@{ Id = 'background-3'; Label = 'Fond 3 (3.png)'; Weight = 1; SourceFilename = '3.png' },
    [pscustomobject]@{ Id = 'il2-2001-box'; Label = 'IL-2 Sturmovik 2001 - jaquette'; Weight = 1; SourceFilename = 'IL-2 Sturmovik 2001 - jaquette remaster 1586x992.png' }
)
$ResourceDirectory = [System.IO.Path]::GetFullPath($ResourceDirectory)
foreach ($definition in $definitions) {
    $sourcePath = Join-Path $ResourceDirectory "Sources\$($definition.Id).png"
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing original source: $sourcePath" }
}
[void][System.IO.Directory]::CreateDirectory((Join-Path $ResourceDirectory 'Images'))
$images = @()
foreach ($definition in $definitions) {
    $sourceRelativePath = "Sources/$($definition.Id).png"
    $imageRelativePath = "Images/$($definition.Id).tga"
    $sourcePath = Join-Path $ResourceDirectory $sourceRelativePath
    $imagePath = Join-Path $ResourceDirectory $imageRelativePath
    $pixels = Read-SourcePixels -Path $sourcePath
    Write-VerifiedTga -SourcePixels $pixels -Path $imagePath
    $images += [ordered]@{
        id = $definition.Id
        label = $definition.Label
        weight = $definition.Weight
        sourceFilename = $definition.SourceFilename
        source = $sourceRelativePath
        path = $imageRelativePath
        sha256 = (Get-FileHash -LiteralPath $imagePath -Algorithm SHA256).Hash.ToLowerInvariant()
        sourceSha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        width = $pixels.Width
        height = $pixels.Height
    }
    Write-Host ("Verified {0}: {1} x {2}, RGB pixels unchanged." -f $definition.Id, $pixels.Width, $pixels.Height)
}
$catalog = [ordered]@{ schemaVersion = 1; status = 'selected-by-user'; images = $images }
$catalogJson = ($catalog | ConvertTo-Json -Depth 5) + [Environment]::NewLine
[System.IO.File]::WriteAllText((Join-Path $ResourceDirectory 'catalog.json'), $catalogJson, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Catalog rebuilt from the four bundled Sources PNG files."