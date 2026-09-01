[CmdletBinding()]
param(
    [string]$ClassPath = (Join-Path $PSScriptRoot '..\Files\7FF44CEAD0A8A81C')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedInputSha256 = '2B4B6B7C508AB59FD101BA00CEBFB72A3EC47AAB8F3170B352B23F760C57D671'
$expectedIntermediateSha256 = '6502B7A55109A9B2E95AC608DD380A2417FADE85269CD57D062A155877607A0D'
$expectedOutputSha256 = 'BFAC0C3D60CB49DB6D857362196B79305E9D4AE5665E06146E8C30D374374C6B'
$replacements = @(
    [pscustomobject]@{
        Old = '3DO/Plane/TBF-1(Multi1)/TBM1.him'
        New = '3DO/Plane/TBF-1(Multi1)/hier.him'
    },
    [pscustomobject]@{
        Old = '3DO/Plane/TBF-1(USA)/TBM1.him'
        New = '3DO/Plane/TBF-1(USA)/hier.him'
    }
)

$resolved = (Resolve-Path -LiteralPath $ClassPath).Path
$inputHash = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash
if ($inputHash -eq $expectedOutputSha256) {
    Write-Host "Classe TBM1 deja corrigee : $resolved" -ForegroundColor Green
    return
}
if ($inputHash -notin @($expectedInputSha256, $expectedIntermediateSha256)) {
    throw "Classe TBM1 non reconnue. SHA-256 attendu : $expectedInputSha256 ou $expectedIntermediateSha256 ; obtenu : $inputHash"
}

$bytes = [IO.File]::ReadAllBytes($resolved)
if ($bytes.Length -ne 13995 -or $bytes[0] -ne 0xCA -or $bytes[1] -ne 0xFE -or
    $bytes[2] -ne 0xBA -or $bytes[3] -ne 0xBE) {
    throw 'Le fichier attendu n est pas la classe Java TBM1 de 13 995 octets.'
}
$major = ($bytes[6] -shl 8) -bor $bytes[7]
if ($major -ne 47) {
    throw "Version Java inattendue : $major au lieu de 47."
}

$patched = [byte[]]$bytes.Clone()
$applied = [Collections.Generic.List[object]]::new()
foreach ($replacement in $replacements) {
    $oldBytes = [Text.Encoding]::ASCII.GetBytes($replacement.Old)
    $newBytes = [Text.Encoding]::ASCII.GetBytes($replacement.New)
    if ($oldBytes.Length -ne $newBytes.Length) {
        throw 'Les deux chemins doivent avoir strictement la meme longueur.'
    }

    $matches = [Collections.Generic.List[int]]::new()
    for ($offset = 0; $offset -le $patched.Length - $oldBytes.Length; $offset++) {
        $same = $true
        for ($index = 0; $index -lt $oldBytes.Length; $index++) {
            if ($patched[$offset + $index] -ne $oldBytes[$index]) {
                $same = $false
                break
            }
        }
        if ($same) {
            $matches.Add($offset)
        }
    }
    if ($matches.Count -gt 1) {
        throw "Chemin TBM1 attendu au plus une fois, trouve $($matches.Count) fois : $($replacement.Old)"
    }
    if ($matches.Count -eq 1) {
        [Array]::Copy($newBytes, 0, $patched, $matches[0], $newBytes.Length)
        $applied.Add([pscustomobject]@{
            Offset = $matches[0]
            PreviousMesh = $replacement.Old
            ActiveMesh = $replacement.New
        })
    }
}
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $outputHash = ([BitConverter]::ToString($sha.ComputeHash($patched))).Replace('-', '')
}
finally {
    $sha.Dispose()
}
if ($outputHash -ne $expectedOutputSha256) {
    throw "Resultat binaire inattendu : $outputHash"
}

$temporary = "$resolved.new-$([Guid]::NewGuid().ToString('N'))"
try {
    [IO.File]::WriteAllBytes($temporary, $patched)
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $expectedOutputSha256) {
        throw 'La verification du fichier temporaire TBM1 a echoue.'
    }
    Move-Item -LiteralPath $temporary -Destination $resolved -Force
}
finally {
    if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force
    }
}

[pscustomobject]@{
    Class = 'com.maddox.il2.objects.air.TBM1'
    Destination = $resolved
    JavaMajorVersion = $major
    Replacements = $applied
    SourceSha256 = $expectedInputSha256
    DestinationSha256 = $expectedOutputSha256
}
