[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
if (-not $ManifestPath) { $ManifestPath = Join-Path $RepositoryRoot 'manifests/switcher-v1.15.json' }

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$manifestFile = [IO.Path]::GetFullPath($ManifestPath)
$manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1 -or $manifest.release -ne '1.15') {
    throw 'Manifeste du switcher v1.15 invalide.'
}

$components = @($manifest.entryPoint, $manifest.desktopIcon)
if ($null -ne $manifest.background) {
    $components += [string]$manifest.background.path
}
foreach ($relative in $components | Where-Object { $_ }) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$relative)) -PathType Leaf)) {
        throw "Composant du switcher absent : $relative"
    }
}
if ($null -ne $manifest.background) {
    if ((Get-Item -LiteralPath (Join-Path $root ([string]$manifest.background.path))).Length -ne [long]$manifest.background.size -or
        (Get-FileHash -LiteralPath (Join-Path $root ([string]$manifest.background.path)) -Algorithm SHA256).Hash -ne
            [string]$manifest.background.sha256) {
        throw 'Fond graphique du switcher absent ou altere.'
    }
}
if ([string]$manifest.resourceDirectory -ne '_Game Switcher/Resources' -or
    @($manifest.icons).Count -ne 2) {
    throw 'Le dossier Resources ou la liste des deux icones actives Open Sturmovik est invalide.'
}
foreach ($resource in @($manifest.icons)) {
    $resourcePath = Join-Path $root ([string]$resource.path)
    if (-not (Test-Path -LiteralPath $resourcePath -PathType Leaf) -or
        (Get-Item -LiteralPath $resourcePath).Length -ne [long]$resource.size -or
        (Get-FileHash -LiteralPath $resourcePath -Algorithm SHA256).Hash -ne [string]$resource.sha256) {
        throw "Ressource graphique du switcher absente ou alteree : $($resource.path)"
    }
}

foreach ($background in @($manifest.loadingBackgrounds.formats)) {
    $backgroundPath = Join-Path $root ([string]$background.path)
    if (-not (Test-Path -LiteralPath $backgroundPath -PathType Leaf) -or
        (Get-Item -LiteralPath $backgroundPath).Length -ne [long]$background.size -or
        (Get-FileHash -LiteralPath $backgroundPath -Algorithm SHA256).Hash -ne [string]$background.sha256) {
        throw "Fond de chargement absent ou altere : $($background.path)"
    }
    $header = [IO.File]::ReadAllBytes($backgroundPath)
    $width = [BitConverter]::ToUInt16($header, 12)
    $height = [BitConverter]::ToUInt16($header, 14)
    if ($header[2] -ne 2 -or $header[16] -ne 24 -or
        $width -ne [int]$background.width -or $height -ne [int]$background.height) {
        throw "Format TGA incorrect pour le fond $($background.name)."
    }
}
if ($manifest.guiMode -ne 'embedded-hta-in-entry-point' -or
    $manifest.hashCheckerMode -ne 'embedded-sha256-validation') {
    throw 'La GUI et le controle SHA-256 doivent etre integres au BAT unique.'
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

foreach ($registry in $manifest.airRegistries.PSObject.Properties) {
    $path = Join-Path $root $registry.Value.path
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $registry.Value.sha256) {
        throw "Registre d avions altere : $($registry.Name)"
    }
    $count = @(Get-Content -LiteralPath $path | Where-Object { $_ -match '^\s*\S+\s+air\.' }).Count
    if ($count -ne $registry.Value.entries) { throw "Nombre d entrees incorrect : $($registry.Name)" }
}

$windowTitleClass = Join-Path $root ([string]$manifest.branding.windowTitleClass.path)
if (-not (Test-Path -LiteralPath $windowTitleClass -PathType Leaf) -or
    (Get-FileHash -LiteralPath $windowTitleClass -Algorithm SHA256).Hash -ne
        [string]$manifest.branding.windowTitleClass.sha256) {
    throw 'Classe de titre Open Sturmovik absente ou alteree.'
}

foreach ($payloadProperty in $manifest.payloads.PSObject.Properties) {
    foreach ($file in @($payloadProperty.Value)) {
        $relative = "_Game Switcher\Version Payloads\$($payloadProperty.Name)\$($file.file)"
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
    $profileRoot = Join-Path $root ("_Game Switcher\" + [string]$profile.folder)
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

$transactions = @(Get-ChildItem -LiteralPath (Join-Path $root '_Game Switcher') -Directory -Filter '_transaction-*')
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
