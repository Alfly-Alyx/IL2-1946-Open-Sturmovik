[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceClass,

    [string]$DestinationClass = (Join-Path $PSScriptRoot '..\Files\com\maddox\il2\game\ZutiTimer_ExtendPlanesWings.class')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedSourceSha256 = '7C01D9322D3C9FF2EE8C55399D08B544E006F1C6269012674E28A2F5FFB3D530'
$sourcePath = (Resolve-Path -LiteralPath $SourceClass).Path
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourcePath).Hash

if ($sourceHash -ne $expectedSourceSha256) {
    throw "Classe Zuti non reconnue. SHA-256 attendu : $expectedSourceSha256 ; obtenu : $sourceHash"
}

$bytes = [System.IO.File]::ReadAllBytes($sourcePath)
if ($bytes.Length -ne 1573) {
    throw "Taille inattendue pour la classe Zuti : $($bytes.Length) octets au lieu de 1573."
}

if ($bytes[0] -ne 0xCA -or $bytes[1] -ne 0xFE -or $bytes[2] -ne 0xBA -or $bytes[3] -ne 0xBE) {
    throw 'Le fichier source ne possede pas la signature CAFEBABE d une classe Java.'
}

$majorVersion = ($bytes[6] -shl 8) -bor $bytes[7]
if ($majorVersion -ne 45) {
    throw "Version Java inattendue : $majorVersion au lieu de 45."
}

# Dans run(), ArrayList.get() renvoie Object. La version historique caste cet
# objet en Actor avant de verifier instanceof Aircraft. Mission.actors contient
# aussi des Integer. Le checkcast declenche donc une ClassCastException a chaque
# passage du timer. Trois NOP conservent les offsets, le format de la classe et
# la logique suivante : l'instanceof existant ignore les elements non-Aircraft.
$pattern = [byte[]](0xB6, 0x00, 0x0F, 0xC0, 0x00, 0x10, 0x4E, 0x2D, 0xC1, 0x00, 0x11)
$matches = [System.Collections.Generic.List[int]]::new()

for ($offset = 0; $offset -le $bytes.Length - $pattern.Length; $offset++) {
    $same = $true
    for ($index = 0; $index -lt $pattern.Length; $index++) {
        if ($bytes[$offset + $index] -ne $pattern[$index]) {
            $same = $false
            break
        }
    }
    if ($same) {
        $matches.Add($offset)
    }
}

if ($matches.Count -ne 1) {
    throw "Motif de bytecode attendu une fois, trouve $($matches.Count) fois. Aucun fichier n'a ete ecrit."
}

$checkcastOffset = $matches[0] + 3
$patched = [byte[]]$bytes.Clone()
$patched[$checkcastOffset] = 0x00
$patched[$checkcastOffset + 1] = 0x00
$patched[$checkcastOffset + 2] = 0x00

$changedOffsets = for ($index = 0; $index -lt $bytes.Length; $index++) {
    if ($bytes[$index] -ne $patched[$index]) {
        $index
    }
}

$patchedInstructionOffsets = @($checkcastOffset, ($checkcastOffset + 1), ($checkcastOffset + 2))
# L'octet central de l'operande de checkcast vaut deja 00. Il est bien inclus
# dans l'instruction remplacee, mais seuls C0 et 10 changent effectivement.
$expectedChangedOffsets = @($checkcastOffset, ($checkcastOffset + 2))
if (($changedOffsets -join ',') -ne ($expectedChangedOffsets -join ',')) {
    throw "La correction modifierait des octets inattendus : $($changedOffsets -join ', ')."
}

$destinationPath = [System.IO.Path]::GetFullPath($DestinationClass)
$destinationDirectory = [System.IO.Path]::GetDirectoryName($destinationPath)
[System.IO.Directory]::CreateDirectory($destinationDirectory) | Out-Null
[System.IO.File]::WriteAllBytes($destinationPath, $patched)

$written = [System.IO.File]::ReadAllBytes($destinationPath)
if ($written.Length -ne $bytes.Length) {
    throw 'La taille de la classe ecrite differe de la source.'
}

$destinationHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $destinationPath).Hash
[pscustomobject]@{
    Source = $sourcePath
    Destination = $destinationPath
    JavaMajorVersion = $majorVersion
    PatchedInstructionOffsets = $patchedInstructionOffsets -join ', '
    ChangedByteOffsets = $expectedChangedOffsets -join ', '
    SourceSha256 = $sourceHash
    DestinationSha256 = $destinationHash
}
