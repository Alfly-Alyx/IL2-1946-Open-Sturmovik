[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$source6DofSha256 =
    '68C78F7F981BDDF4B6FB3A6FF901B59115AE7B3D953B8F53121E6BE5B8A65584'
$expectedLength = 348160

$profiles = @(
    '_Game Switchers\4.08 Mod ON (NO 6DOF)\il2fb.exe',
    '_Game Switchers\4.09 Mods ON (NO 6DOF)\il2fb.exe',
    '_Game Switchers\4.09finalModsON(No-6DoF)\il2fb.exe'
)

$onSequences = @(
    @{ Offset = 0x0F205; Bytes = [byte[]](0xE9, 0x16, 0xC6, 0x00, 0x00) },
    @{ Offset = 0x0F282; Bytes = [byte[]](0xEB, 0x81) },
    @{
        Offset = 0x1B820
        Bytes = [byte[]](
            0xD9, 0x44, 0x24, 0x2C, 0xD8, 0x0D, 0x10, 0xC7,
            0x41, 0x00, 0xD9, 0x58, 0x0C, 0xD9, 0x44, 0x24,
            0x30, 0xD8, 0x0D, 0x10, 0xC7, 0x41, 0x00, 0xD9,
            0x58, 0x10, 0xD9, 0x44, 0x24, 0x34, 0xD8, 0x0D,
            0x10, 0xC7, 0x41, 0x00, 0xD9, 0x58, 0x14, 0x8B,
            0x0E, 0xE9, 0x36, 0x3A, 0xFF, 0xFF
        )
    }
)

$offSequences = @(
    @{ Offset = 0x0F205; Bytes = [byte[]](0x90, 0x90, 0x90, 0x90, 0x90) },
    @{ Offset = 0x0F282; Bytes = [byte[]](0x8B, 0x0E) },
    @{ Offset = 0x1B820; Bytes = [byte[]]::new(46) }
)

function Test-Sequence {
    param(
        [byte[]]$Image,
        [int]$Offset,
        [byte[]]$Expected
    )

    for ($index = 0; $index -lt $Expected.Length; $index++) {
        if ($Image[$Offset + $index] -ne $Expected[$index]) {
            return $false
        }
    }

    return $true
}

$resolvedRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path

foreach ($relativePath in $profiles) {
    $target = Join-Path $resolvedRoot $relativePath
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw "Profil sans 6DOF absent : $relativePath"
    }

    $image = [System.IO.File]::ReadAllBytes($target)
    if ($image.Length -ne $expectedLength) {
        throw "Taille inattendue pour $relativePath : $($image.Length) octets"
    }

    $isOn = $true
    $isOff = $true
    for ($index = 0; $index -lt $onSequences.Count; $index++) {
        $isOn = $isOn -and (Test-Sequence -Image $image `
            -Offset $onSequences[$index].Offset `
            -Expected $onSequences[$index].Bytes)
        $isOff = $isOff -and (Test-Sequence -Image $image `
            -Offset $offSequences[$index].Offset `
            -Expected $offSequences[$index].Bytes)
    }

    if ($isOff) {
        Write-Host "Deja sans 6DOF : $relativePath"
        continue
    }

    if (-not $isOn) {
        throw "Les octets 6DOF attendus ne correspondent pas : $relativePath"
    }

    $currentSha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($currentSha256 -ne $source6DofSha256) {
        throw "Empreinte source inattendue pour $relativePath : $currentSha256"
    }

    foreach ($patch in $offSequences) {
        [System.Array]::Copy(
            $patch.Bytes,
            0,
            $image,
            $patch.Offset,
            $patch.Bytes.Length
        )
    }

    [System.IO.File]::WriteAllBytes($target, $image)
    $patchedSha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    Write-Host "Profil sans 6DOF restaure : $relativePath [$patchedSha256]"
}
