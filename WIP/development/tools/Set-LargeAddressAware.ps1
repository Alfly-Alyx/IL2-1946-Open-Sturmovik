[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Path
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-PeCharacteristicsOffset {
    param([byte[]]$Bytes, [string]$DisplayPath)

    if ($Bytes.Length -lt 256 -or $Bytes[0] -ne 0x4D -or $Bytes[1] -ne 0x5A) {
        throw "$DisplayPath n'est pas un executable PE valide (signature MZ absente)."
    }

    $peOffset = [System.BitConverter]::ToInt32($Bytes, 0x3C)
    if ($peOffset -lt 0 -or ($peOffset + 24) -gt $Bytes.Length) {
        throw "$DisplayPath contient un en-tete PE hors limites."
    }
    if ($Bytes[$peOffset] -ne 0x50 -or $Bytes[$peOffset + 1] -ne 0x45 -or
        $Bytes[$peOffset + 2] -ne 0 -or $Bytes[$peOffset + 3] -ne 0) {
        throw "$DisplayPath n'est pas un executable PE valide (signature PE absente)."
    }

    return ($peOffset + 22)
}

foreach ($item in $Path) {
    $resolved = (Resolve-Path -LiteralPath $item).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    $characteristicsOffset = Get-PeCharacteristicsOffset -Bytes $bytes -DisplayPath $resolved
    $characteristics = [System.BitConverter]::ToUInt16($bytes, $characteristicsOffset)

    if (($characteristics -band 0x20) -ne 0) {
        Write-Host "Deja Large Address Aware : $resolved"
        continue
    }

    $updated = [uint16]($characteristics -bor 0x20)
    $flagBytes = [System.BitConverter]::GetBytes($updated)
    $bytes[$characteristicsOffset] = $flagBytes[0]
    $bytes[$characteristicsOffset + 1] = $flagBytes[1]

    $temporary = "$resolved.laa-new-$([Guid]::NewGuid().ToString('N'))"
    $backup = "$resolved.laa-backup-$([Guid]::NewGuid().ToString('N'))"
    try {
        [System.IO.File]::WriteAllBytes($temporary, $bytes)
        $verification = [System.IO.File]::ReadAllBytes($temporary)
        $verificationOffset = Get-PeCharacteristicsOffset -Bytes $verification -DisplayPath $temporary
        $verificationFlags = [System.BitConverter]::ToUInt16($verification, $verificationOffset)
        if (($verificationFlags -band 0x20) -eq 0) {
            throw "Le drapeau Large Address Aware n'a pas ete ecrit dans $temporary."
        }

        Move-Item -LiteralPath $resolved -Destination $backup
        try {
            Move-Item -LiteralPath $temporary -Destination $resolved
        }
        catch {
            Move-Item -LiteralPath $backup -Destination $resolved -Force
            throw
        }
        Remove-Item -LiteralPath $backup -Force
        Write-Host "Large Address Aware active : $resolved" -ForegroundColor Green
    }
    finally {
        if (Test-Path -LiteralPath $temporary) {
            Remove-Item -LiteralPath $temporary -Force
        }
        if (Test-Path -LiteralPath $backup) {
            if (-not (Test-Path -LiteralPath $resolved)) {
                Move-Item -LiteralPath $backup -Destination $resolved -Force
            }
            else {
                Remove-Item -LiteralPath $backup -Force
            }
        }
    }
}
