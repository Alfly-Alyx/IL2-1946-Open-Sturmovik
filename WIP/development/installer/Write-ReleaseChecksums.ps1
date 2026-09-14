[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'Output'),
    [string]$OutputBaseName = 'Open-Sturmovik-1.15-Setup'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$outputPath = [IO.Path]::GetFullPath($OutputDirectory)
$maximumPartSize = 1000000000L

if (-not (Test-Path -LiteralPath $outputPath)) {
    throw "Dossier de sortie absent : $outputPath"
}

$releaseFiles = Get-ChildItem -LiteralPath $outputPath -File | Where-Object {
    ($_.Name -eq "$OutputBaseName.exe") -or
    ($_.Name -like "$OutputBaseName-*.bin")
} | Sort-Object Name

if (@($releaseFiles).Count -eq 0) {
    throw 'Aucune partie compilee de l installateur n a ete trouvee.'
}

foreach ($file in $releaseFiles) {
    if ($file.Length -gt $maximumPartSize) {
        throw "La partie $($file.Name) depasse 1 Go : $($file.Length) octets."
    }
}

$checksumLines = foreach ($file in $releaseFiles) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    "$hash *$($file.Name)"
}

$checksumPath = Join-Path $outputPath 'SHA256SUMS.txt'
[IO.File]::WriteAllLines(
    $checksumPath,
    [string[]]$checksumLines,
    [Text.UTF8Encoding]::new($false)
)

[pscustomobject]@{
    OutputDirectory = $outputPath
    PartCount = @($releaseFiles).Count
    LargestPartBytes = ($releaseFiles | Measure-Object -Property Length -Maximum).Maximum
    MaximumAllowedBytes = $maximumPartSize
    ChecksumFile = $checksumPath
}
