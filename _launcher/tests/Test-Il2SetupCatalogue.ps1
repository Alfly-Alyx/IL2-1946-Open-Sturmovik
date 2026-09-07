[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$reader = Join-Path $launcherRoot 'tools\Read-Il2SetupCatalogue.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures\il2setup-catalogue.ini'
$catalogue = (& $reader -CataloguePath $fixture) | ConvertFrom-Json

if (-not $catalogue.valid -or $catalogue.categoryCount -ne 2 -or $catalogue.profileCount -ne 3) {
    throw 'Le catalogue de test n est pas reconnu.'
}
$child = @($catalogue.profiles | Where-Object id -eq 'Child')
if ($child.Count -ne 1) { throw 'Le profil enfant est absent.' }
if ($child[0].resolvedSettings.TexMipFilter -ne '1') {
    throw 'La valeur heritee TexMipFilter est perdue.'
}
if ($child[0].resolvedSettings.TexCompress -ne '2') {
    throw 'La valeur surchargee TexCompress est incorrecte.'
}
if (@($catalogue.unreferencedProfiles).Count -ne 0) {
    throw 'Un profil reference est declare orphelin.'
}

[ordered]@{
    passed = $true
    categories = [int]$catalogue.categoryCount
    profiles = [int]$catalogue.profileCount
    inheritedTexMipFilter = [string]$child[0].resolvedSettings.TexMipFilter
    overriddenTexCompress = [string]$child[0].resolvedSettings.TexCompress
} | ConvertTo-Json
