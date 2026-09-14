[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\..\dependances\sdk\test-tools')
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'FrameCapture.cs'
if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Source introuvable : $source"
}

$compiler = @(
    'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe',
    'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe'
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $compiler) {
    throw 'Compilateur C# .NET Framework 4 introuvable.'
}

$resolvedOutput = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $resolvedOutput -Force | Out-Null
$executable = Join-Path $resolvedOutput 'FrameCapture.exe'
& $compiler /nologo /optimize+ /target:exe /platform:anycpu /reference:System.Drawing.dll "/out:$executable" $source
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executable -PathType Leaf)) {
    throw 'Echec de compilation de FrameCapture.exe.'
}

$file = Get-Item -LiteralPath $executable
[pscustomobject]@{
    Executable = $file.FullName
    Length = $file.Length
    SHA256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    Compiler = $compiler
    State = 'OK'
}
