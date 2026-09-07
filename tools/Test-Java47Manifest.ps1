[CmdletBinding()]
param(
    [string]$FilesRoot = (Join-Path $PSScriptRoot '..\Files'),
    [string]$Manifest = (Join-Path $PSScriptRoot '..\manifests\java47-1.15.json')
)

$ErrorActionPreference = 'Stop'
$items = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json
$verified = 0
foreach ($item in $items) {
    $path = Join-Path $FilesRoot $item.file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Classe absente : $path"
    }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($hash -ne $item.staged_sha256) {
        throw "Empreinte inattendue : $($item.file)"
    }
    $stream = [IO.File]::OpenRead($path)
    try {
        $header = New-Object byte[] 8
        if ($stream.Read($header, 0, 8) -ne 8) { throw "En-tete tronque : $($item.file)" }
    }
    finally {
        $stream.Dispose()
    }
    $major = ([int]$header[6] -shl 8) -bor [int]$header[7]
    if ($major -ne 47) { throw "Version Java $major inattendue : $($item.file)" }
    $verified++
}

[pscustomobject]@{
    Manifest = [IO.Path]::GetFullPath($Manifest)
    ClassesVerifiees = $verified
    Version = 47
    Etat = 'OK'
}
