[CmdletBinding()]
param(
    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot),
    [Parameter(Mandatory = $true)][string]$DestinationRoot,
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifests\test\v1.15-test-sync.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}
$source = (Resolve-Path -LiteralPath $SourceRoot -ErrorAction Stop).Path.TrimEnd('\')
$destination = (Resolve-Path -LiteralPath $DestinationRoot -ErrorAction Stop).Path.TrimEnd('\')
if ($source -ieq $destination) { throw 'La source et la destination doivent etre distinctes.' }

$changedPaths = @(& git -C $source ls-files -m -d -o --exclude-standard -- 'Files' '_Game Switchers' 'Open_Sturmovik_Switcher.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Git ne peut pas enumerer les changements a synchroniser.' }
$changedPaths = @($changedPaths | Where-Object { $_ } | Sort-Object -Unique)
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
