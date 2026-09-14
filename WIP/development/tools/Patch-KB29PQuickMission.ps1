[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),

    [string]$SourceClass = 'Files\2083079EF880398E',

    [string]$DestinationClass = 'Files\2083079EF880398E'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$source = [IO.Path]::GetFullPath((Join-Path $root $SourceClass))
$destination = [IO.Path]::GetFullPath((Join-Path $root $DestinationClass))
$expectedSourceSha256 = '0E761121A10FD1B3224ED9B29E91895D2C0013C2F411BD08DBF50D2E0E24AB1F'
$expectedOutputSha256 = '0BC5BDBDFB58E0165CF664940DADA6615750DEC6CA18BF6657266E9E7E779CFB'

foreach ($classPath in @($source, $destination)) {
    if (-not $classPath.StartsWith($root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'La classe doit rester dans le depot cible.'
    }
}

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Classe KB-29P source absente : $source"
}
$sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash
if ($sourceHash -notin @($expectedSourceSha256, $expectedOutputSha256)) {
    throw 'La classe KB-29P source ne correspond pas a la version 4.09m attendue.'
}

$java = (Get-Command java -ErrorAction Stop).Source
$javac = (Get-Command javac -ErrorAction Stop).Source
$buildRoot = Join-Path $root 'build\aircraft-patcher'
$patcherSource = Join-Path $root 'tools\java\OpenSturmovikAircraftPatcher.java'
[IO.Directory]::CreateDirectory($buildRoot) | Out-Null

$exports = @(
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED',
    '--add-exports', 'java.base/jdk.internal.org.objectweb.asm.tree.analysis=ALL-UNNAMED'
)

& $javac @exports -d $buildRoot $patcherSource
if ($LASTEXITCODE -ne 0) {
    throw "Compilation du constructeur KB-29P impossible (code $LASTEXITCODE)."
}

if ($sourceHash -eq $expectedSourceSha256) {
    $staged = Join-Path $buildRoot 'KB_29P.class'
    & $java @exports -cp $buildRoot OpenSturmovikAircraftPatcher $source $staged
    if ($LASTEXITCODE -ne 0 -or
        (Get-FileHash -LiteralPath $staged).Hash -ne $expectedOutputSha256) {
        throw 'Construction du KB-29P pilotable non conforme.'
    }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $staged -Destination $destination -Force
} elseif ($source -ine $destination) {
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

# Keep one class definition at the existing loader address. The former named
# override coexisted with the unpatched hashed class and did not prove priority.
$oldOverride = Join-Path $root 'Files\com\maddox\il2\objects\air\KB_29P.class'
if ($destination -ine $oldOverride -and (Test-Path -LiteralPath $oldOverride)) {
    if ((Get-FileHash -LiteralPath $oldOverride).Hash -ne $expectedOutputSha256) {
        throw 'Ancienne surcharge KB-29P modifiee : conservation obligatoire.'
    }
    Remove-Item -LiteralPath $oldOverride
}

[pscustomobject]@{
    Source = $source
    Destination = $destination
    SourceSha256 = $expectedSourceSha256
    DestinationSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $destination).Hash
    CockpitClass = 'com.maddox.il2.objects.air.CockpitB29'
    JavaMajorVersion = 47
}
