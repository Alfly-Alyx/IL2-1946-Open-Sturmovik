[CmdletBinding()]
param(
    [string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [string]$OutputPath,
    [string[]]$IncludePath = @(),
    [switch]$IncludeManagedPayloads,
    [switch]$OnlyIncludedPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $SourceRoot) { $SourceRoot = Split-Path -Parent $PSScriptRoot }

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
$source = (Resolve-Path -LiteralPath $SourceRoot -ErrorAction Stop).Path.TrimEnd('\')
$destination = (Resolve-Path -LiteralPath $DestinationRoot -ErrorAction Stop).Path.TrimEnd('\')
if ($source -ieq $destination) { throw 'La source et la destination doivent etre distinctes.' }
if (-not $OutputPath) { $OutputPath = Join-Path $source 'manifests\test\v1.15-test-sync.json' }

$changedPaths = @()
if (-not $OnlyIncludedPaths) {
    $changedPaths = @(& git -C $source ls-files -m -d -o --exclude-standard -- `
        'Files' '_Documentation' '_Documentations' '_Game Switchers' '_Game_Enhancements' `
        '_Runtime_Addons' '_Utilities' 'Mod_AOC_Public' 'DeviceLink.txt' `
        'Open_Sturmovik_Switcher.bat' 'Open_Sturmovik_Switcher.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Git ne peut pas enumerer les changements a synchroniser.' }
}
$forcedPaths = @($IncludePath | ForEach-Object { $_.Replace('\', '/').TrimStart('/') } | Where-Object { $_ })
if (-not $OnlyIncludedPaths) {
    # This old untracked override disappears from Git's changed-file list once
    # removed, but still must be retired from earlier test installations.
    $forcedPaths += 'Files/com/maddox/il2/objects/air/KB_29P.class'
}
if ($IncludeManagedPayloads) {
    $nuclearManifestPath = Join-Path $source 'manifests\effects\nuclear-blast-v1.15.json'
    if (-not (Test-Path -LiteralPath $nuclearManifestPath -PathType Leaf)) {
        throw "Manifeste nucleaire absent : $nuclearManifestPath"
    }
    $nuclearManifest = Get-Content -LiteralPath $nuclearManifestPath -Raw | ConvertFrom-Json
    $forcedPaths += @($nuclearManifest.outputs | ForEach-Object { ([string]$_.file).Replace('\', '/') })

    $aaaManifestPath = Join-Path $source 'manifests\aircraft\aaa-community-cockpits-v1.15.json'
    if (-not (Test-Path -LiteralPath $aaaManifestPath -PathType Leaf)) {
        throw "Manifeste AAA absent : $aaaManifestPath"
    }
    $aaaManifest = Get-Content -LiteralPath $aaaManifestPath -Raw | ConvertFrom-Json
    foreach ($packageName in @('TBF-1C', 'TBM-3', 'SU_2')) {
        $property = $aaaManifest.candidate_packages.PSObject.Properties[$packageName]
        if ($null -eq $property) { throw "Paquet AAA absent : $packageName" }
        $forcedPaths += @($property.Value.classes | ForEach-Object {
            'Files/' + [IO.Path]::GetFileName([string]$_.source)
        })
        $forcedPaths += @($property.Value.resources | ForEach-Object {
            'Files/' + ([string]$_.relative_path).TrimStart('/')
        })
    }
    $acesProperty = $aaaManifest.candidate_packages.PSObject.Properties['ACES']
    if ($null -eq $acesProperty) { throw 'Paquet AAA ACES absent.' }
    $migClasses = @($acesProperty.Value.classes | Where-Object internal_class -eq 'com/maddox/il2/objects/air/MIG_3POKRYSHKIN')
    if ($migClasses.Count -ne 1) { throw "Classe MIG_3POKRYSHKIN ambigue ou absente : $($migClasses.Count)" }
    $forcedPaths += 'Files/' + [IO.Path]::GetFileName([string]$migClasses[0].source)

    # These two addresses belong to the retired VisualAction/VisualData classes.
    # Keeping their canonical repository bytes in the plan repairs test trees
    # produced by the failed 2026-09-02 candidate which overwrote both paths.
    $forcedPaths += @('Files/2A3CF08C7344E18A', 'Files/AB04450E05C9E67C')
}
$changedPaths = @($changedPaths + $forcedPaths | Where-Object { $_ } | Sort-Object -Unique)
if ($changedPaths.Count -eq 0) { throw 'Aucun changement runtime detecte par Git.' }

$entries = foreach ($relativeGit in $changedPaths) {
    $relative = $relativeGit.Replace('/', '\')
    $sourcePath = Join-Path $source $relative
    $destinationPath = Join-Path $destination $relative
    $sourcePresent = Test-Path -LiteralPath $sourcePath -PathType Leaf
    $destinationPresent = Test-Path -LiteralPath $destinationPath -PathType Leaf
    $entry = [ordered]@{
        path = $relativeGit.Replace('\', '/')
        action = if ($sourcePresent) { 'copy' } else { 'remove' }
        destination_before_present = $destinationPresent
        destination_before_size = if ($destinationPresent) { (Get-Item -LiteralPath $destinationPath).Length } else { $null }
        destination_before_sha256 = if ($destinationPresent) { Get-Sha256 $destinationPath } else { $null }
    }
    if ($sourcePresent) {
        $entry.source_size = (Get-Item -LiteralPath $sourcePath).Length
        $entry.source_sha256 = Get-Sha256 $sourcePath
    }
    [pscustomobject]$entry
}

$head = (& git -C $source rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw 'Impossible de lire le commit courant.' }
$manifest = [ordered]@{
    schema = 1
    purpose = 'Synchronisation transactionnelle des correctifs runtime v1.15 vers la copie de test'
    generated_utc = [DateTime]::UtcNow.ToString('O')
    source_root = $source
    destination_root = $destination
    source_head = $head
    copy_count = @($entries | Where-Object action -eq 'copy').Count
    remove_count = @($entries | Where-Object action -eq 'remove').Count
    entries = @($entries)
}

$absoluteOutput = [IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $absoluteOutput
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}
$manifest | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $absoluteOutput -Encoding UTF8
Write-Host "Plan cree : $absoluteOutput" -ForegroundColor Green
Write-Host "Copies : $($manifest.copy_count) ; retraits recuperables : $($manifest.remove_count)."
