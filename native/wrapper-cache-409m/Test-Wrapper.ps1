[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ToolchainRoot,

    [string]$Wrapper = (Join-Path $PSScriptRoot '..\..\build\native\wrapper-cache-409m\wrapper.dll')
)

$ErrorActionPreference = 'Stop'
$compiler = Join-Path $ToolchainRoot 'bin\i686-w64-mingw32-clang.exe'
if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "Compilateur introuvable : $compiler" }
if (-not (Test-Path -LiteralPath $Wrapper -PathType Leaf)) { throw "Wrapper introuvable : $Wrapper" }

$testRoot = Join-Path $env:TEMP ('open-sturmovik-wrapper-test-' + [guid]::NewGuid().ToString('N'))
$files = Join-Path $testRoot 'Files'
New-Item -ItemType Directory -Path $files -Force | Out-Null
Copy-Item -LiteralPath $Wrapper -Destination (Join-Path $testRoot 'wrapper.dll')

$hostExe = Join-Path $testRoot 'host.exe'
& $compiler `
    -std=c11 `
    -O2 `
    -DNDEBUG `
    (Join-Path $PSScriptRoot 'tests\host.c') `
    (Join-Path $PSScriptRoot 'tests\host.def') `
    -o $hostExe
if ($LASTEXITCODE -ne 0) { throw "Compilation du banc de test impossible : $LASTEXITCODE" }

function Invoke-Host([string]$Hash) {
    Push-Location $testRoot
    try {
        & $hostExe $Hash | Out-Null
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    if ($exitCode -ne 0) { throw "Le banc de test refuse le hash $Hash (code $exitCode)." }
}

Set-Content -LiteralPath (Join-Path $files '0123456789ABCDEF') -Value 'premier' -Encoding ascii
Invoke-Host '0123456789ABCDEF'
$cache = Join-Path $testRoot '.open-sturmovik-cache\files.cache'
$manifest = Join-Path $testRoot '.open-sturmovik-cache\files.dirs'
if (-not (Test-Path -LiteralPath $cache) -or -not (Test-Path -LiteralPath $manifest)) { throw 'Le premier lancement ne cree pas le cache complet.' }

$firstCacheHash = (Get-FileHash -LiteralPath $cache -Algorithm SHA256).Hash
$firstWrite = (Get-Item -LiteralPath $cache).LastWriteTimeUtc
Invoke-Host '0123456789ABCDEF'
if ((Get-Item -LiteralPath $cache).LastWriteTimeUtc -ne $firstWrite) { throw 'Un cache valide a ete reconstruit inutilement.' }

Set-Content -LiteralPath (Join-Path $files 'FEDCBA9876543210') -Value 'second' -Encoding ascii
Invoke-Host 'FEDCBA9876543210'
$secondCacheHash = (Get-FileHash -LiteralPath $cache -Algorithm SHA256).Hash
if ($secondCacheHash -eq $firstCacheHash) { throw "L'ajout d'un fichier n'a pas invalide le cache." }

Set-Content -LiteralPath $cache -Value '#cache volontairement corrompu' -Encoding ascii
Invoke-Host '0123456789ABCDEF'
if ((Get-Content -LiteralPath $cache -TotalCount 1) -notlike '#OSWRAPCACHE1?*') { throw "Le cache corrompu n'a pas ete reconstruit." }

[pscustomobject]@{
    TestRoot = $testRoot
    ColdBuild = 'OK'
    CacheHit = 'OK'
    DirectoryInvalidation = 'OK'
    CorruptionRecovery = 'OK'
}
