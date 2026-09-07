[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ToolchainRoot,

    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\..\build\native\wrapper-cache-409m')
)

$ErrorActionPreference = 'Stop'
$compiler = Join-Path $ToolchainRoot 'bin\i686-w64-mingw32-clang.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw "Compilateur 32 bits introuvable : $compiler"
}

$outputDirectoryPath = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputDirectoryPath -Force | Out-Null
$output = Join-Path $outputDirectoryPath 'wrapper.dll'
$map = Join-Path $outputDirectoryPath 'wrapper.map'

& $compiler `
    -std=c11 `
    -O2 `
    -DNDEBUG `
    -D_WIN32_WINNT=0x0501 `
    -Wall `
    -Wextra `
    -Werror `
    -shared `
    -static `
    -s `
    '-Wl,--enable-stdcall-fixup' `
    '-Wl,--no-insert-timestamp' `
    '-Wl,--major-os-version,5,--minor-os-version,1' `
    '-Wl,--major-subsystem-version,5,--minor-subsystem-version,1' `
    "-Wl,-Map,$map" `
    (Join-Path $PSScriptRoot 'wrapper.c') `
    (Join-Path $PSScriptRoot 'wrapper.def') `
    -o $output

if ($LASTEXITCODE -ne 0) {
    throw "La compilation du wrapper a echoue avec le code $LASTEXITCODE."
}

$hash = Get-FileHash -LiteralPath $output -Algorithm SHA256
[pscustomobject]@{
    Path = $output
    Size = (Get-Item -LiteralPath $output).Length
    SHA256 = $hash.Hash
}
