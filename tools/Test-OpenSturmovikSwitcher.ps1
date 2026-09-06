[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$ManifestPath = (Join-Path $PSScriptRoot '..\manifests\switcher-v1.15.json')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$manifestFile = [IO.Path]::GetFullPath($ManifestPath)
$manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.release -ne '1.15') {
    throw 'Manifeste du switcher v1.15 invalide.'
}

foreach ($relative in @($manifest.entryPoint, $manifest.gui, $manifest.hashChecker, $manifest.desktopIcon)) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)) -PathType Leaf)) {
        throw "Composant du switcher absent : $relative"
    }
}

$profiles = @($manifest.profiles)
if ($profiles.Count -ne 9 -or @($profiles.number | Sort-Object -Unique).Count -ne 9) {
    throw 'Le switcher doit declarer exactement neuf profils uniques.'
}

foreach ($common in @($manifest.commonFiles)) {
    $path = Join-Path $root ([string]$common.path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne [string]$common.sha256) {
        throw "Fichier commun absent ou altere : $($common.path)"
    }
}

$windowTitleClass = Join-Path $root ([string]$manifest.branding.windowTitleClass.path)
if (-not (Test-Path -LiteralPath $windowTitleClass -PathType Leaf) -or
    (Get-FileHash -LiteralPath $windowTitleClass -Algorithm SHA256).Hash -ne
        [string]$manifest.branding.windowTitleClass.sha256) {
    throw 'Classe de titre Open Sturmovik absente ou alteree.'
}

foreach ($payloadProperty in $manifest.payloads.PSObject.Properties) {
    foreach ($file in @($payloadProperty.Value)) {
        $relative = "_Game Switchers\Version Payloads\$($payloadProperty.Name)\$($file.file)"
        $path = Join-Path $root $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Charge utile absente : $relative"
        }
        $item = Get-Item -LiteralPath $path
        $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($item.Length -ne [long]$file.size -or $hash -ne [string]$file.sha256) {
            throw "Charge utile alteree : $relative"
        }
    }
}

foreach ($profile in $profiles | Sort-Object number) {
    $profileRoot = Join-Path $root ("_Game Switchers\" + [string]$profile.folder)
    $exe = Join-Path $profileRoot 'il2fb.exe'
    $files = Join-Path $profileRoot 'files.SFS'
    if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne [string]$profile.exeSha256 -or
        (Get-FileHash -LiteralPath $files -Algorithm SHA256).Hash -ne [string]$profile.filesSha256) {
        throw "Profil altere : $($profile.number) - $($profile.version) $($profile.mode)"
    }
    $versionInfo = (Get-Item -LiteralPath $exe).VersionInfo
    if ([string]$profile.mode -eq 'original') {
        if ($versionInfo.FileDescription -eq 'Open Sturmovik' -or
            $versionInfo.ProductName -eq 'Open Sturmovik') {
            throw "L executable original du profil $($profile.number) a ete rebaptise."
        }
    } else {
        if ($versionInfo.FileDescription -ne [string]$manifest.branding.moddedExeVersionInfo.fileDescription -or
            $versionInfo.ProductName -ne [string]$manifest.branding.moddedExeVersionInfo.productName -or
            $versionInfo.FileVersion -ne [string]$manifest.branding.moddedExeVersionInfo.fileVersion -or
            $versionInfo.OriginalFilename -ne [string]$manifest.branding.moddedExeVersionInfo.originalFilename) {
            throw "Metadonnees Open Sturmovik incorrectes pour le profil $($profile.number)."
        }
    }
}

$switcher = Join-Path $root ([string]$manifest.entryPoint)
$validations = foreach ($profile in $profiles | Sort-Object number) {
    $output = @(& cmd.exe /D /C "`"$switcher`" --validate $($profile.number) keep" 2>&1)
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Validation batch du profil $($profile.number) en echec (code $exitCode) : $($output -join ' | ')"
    }
    [pscustomobject]@{
        Profile = [int]$profile.number
        Version = [string]$profile.version
        Mode = [string]$profile.mode
        Status = 'PASS'
    }
}

foreach ($hud in @('standard', 'immersion')) {
    $output = @(& cmd.exe /D /C "`"$switcher`" --validate 8 $hud" 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Validation HUD $hud en echec : $($output -join ' | ')"
    }
}

$transactions = @(Get-ChildItem -LiteralPath (Join-Path $root '_Game Switchers') -Directory -Filter '_transaction-*')
if ($transactions.Count -ne 0) {
    throw "Transaction abandonnee detectee : $($transactions.FullName -join ', ')"
}

[pscustomobject]@{
    Release = '1.15'
    ProfileCount = $validations.Count
    HudVariants = 2
    SourceIntegrity = $true
    RuntimeValidation = 'EN_ATTENTE'
    Result = 'PASS'
}
