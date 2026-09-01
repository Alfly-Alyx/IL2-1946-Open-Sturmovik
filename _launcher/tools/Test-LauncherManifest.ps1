[CmdletBinding()]
param(
    [string]$ManifestPath,
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $ProjectRoot '_launcher\manifests\open-sturmovik-1.15.json'
}

$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$checkedFiles = 0
$checkedContracts = 0

function Add-Error {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Test-RelativeProjectPath {
    param([string]$Value, [string]$Context)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Add-Error "$Context : chemin vide."
        return $false
    }
    if ([IO.Path]::IsPathRooted($Value) -or $Value -split '[\\/]' -contains '..') {
        Add-Error "$Context : chemin non relatif ou traversant ($Value)."
        return $false
    }
    return $true
}

function Test-UniqueIds {
    param([object[]]$Items, [string]$Context)

    $ids = @($Items | ForEach-Object { [string]$_.id })
    $duplicates = @($ids | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
    foreach ($duplicate in $duplicates) {
        Add-Error "$Context : identifiant duplique ($duplicate)."
    }
}

if ($manifest.schemaVersion -ne 1) {
    Add-Error 'schemaVersion doit valoir 1.'
}
if ([string]::IsNullOrWhiteSpace([string]$manifest.product.targetVersion)) {
    Add-Error 'product.targetVersion est obligatoire.'
}

Test-UniqueIds @($manifest.profiles) 'profiles'
Test-UniqueIds @($manifest.visualQuality) 'visualQuality'
Test-UniqueIds @($manifest.capabilities) 'capabilities'

$allowedAvailability = @('available', 'blocked', 'research')
$userFacingObjects = @($manifest.profiles) + @($manifest.visualQuality) + @($manifest.capabilities)
foreach ($item in $userFacingObjects) {
    if ([string]$item.availability -notin $allowedAvailability) {
        Add-Error "Disponibilite invalide pour $($item.id)."
    }
    if ([string]::IsNullOrWhiteSpace([string]$item.userLabel)) {
        Add-Error "Libelle utilisateur absent pour $($item.id)."
    }
}

$technicalTerms = '(?i)\bmods?\b|\bplugin\b|\bpackage\b|\bpaquet\b|\.dll\b|\.sfs\b'
foreach ($capability in @($manifest.capabilities | Where-Object category -eq 'realism')) {
    if ([string]$capability.userLabel -match $technicalTerms) {
        Add-Error "Le libelle de realisme '$($capability.userLabel)' expose un composant technique."
    }
}

foreach ($profile in @($manifest.profiles)) {
    if ($profile.availability -ne 'available' -and [string]::IsNullOrWhiteSpace([string]$profile.reason)) {
        Add-Error "Le profil indisponible $($profile.id) doit expliquer pourquoi."
    }
    foreach ($file in @($profile.files)) {
        $context = "$($profile.id)/$($file.target)"
        if (-not (Test-RelativeProjectPath ([string]$file.source) "$context source")) {
            continue
        }
        if (-not (Test-RelativeProjectPath ([string]$file.target) "$context cible")) {
            continue
        }
        if ([string]$file.sha256 -notmatch '^[A-Fa-f0-9]{64}$') {
            Add-Error "$context : SHA-256 invalide."
            continue
        }

        $sourcePath = Join-Path $resolvedRoot ([string]$file.source)
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            Add-Error "$context : source absente ($($file.source))."
            continue
        }

        $sourceInfo = Get-Item -LiteralPath $sourcePath
        if ($sourceInfo.Length -ne [long]$file.size) {
            Add-Error "$context : taille $($sourceInfo.Length), attendu $($file.size)."
        }
        $actualHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
        if ($actualHash -ne [string]$file.sha256) {
            Add-Error "$context : empreinte SHA-256 inattendue."
        }
        $checkedFiles++
    }
}

$viewCapability = @($manifest.capabilities | Where-Object id -eq 'view.mode')
if ($viewCapability.Count -ne 1) {
    Add-Error 'La capacite view.mode doit etre declaree exactement une fois.'
}
else {
    Test-UniqueIds @($viewCapability[0].options) 'view.mode/options'
    $classic = @($viewCapability[0].options | Where-Object id -eq 'classic')
    $sixDof = @($viewCapability[0].options | Where-Object id -eq 'six-dof')
    if ($classic.Count -ne 1 -or $sixDof.Count -ne 1) {
        Add-Error 'Les choix classic et six-dof sont obligatoires.'
    }
    elseif ($sixDof[0].availability -eq 'available' -and $sixDof[0].profile -eq $classic[0].profile) {
        Add-Error 'Le 6DOF disponible doit resoudre un profil distinct de la vue classique.'
    }
}

if (-not $manifest.keyMapping.preserveUnknownEntries) {
    Add-Error 'Le mapping doit conserver les entrees inconnues du joueur.'
}
if (-not $manifest.keyMapping.backupBeforeWrite) {
    Add-Error 'Le mapping doit sauvegarder avant toute ecriture.'
}
if (-not $manifest.integrity.repair.rollbackOnFailure) {
    Add-Error 'La reparation doit restaurer automatiquement en cas d echec.'
}

if ([string]$manifest.il2SetupCompatibility.replacementFileName -cne 'il2setup.exe') {
    Add-Error 'Le lanceur doit conserver exactement le nom interne il2setup.exe.'
}
if ([string]$manifest.il2SetupCompatibility.configurationFile -cne 'conf.ini') {
    Add-Error 'Le contrat il2setup doit cibler conf.ini.'
}
if ([string]$manifest.il2SetupCompatibility.presetCatalogue -cne 'il2setup.ini') {
    Add-Error 'Le contrat il2setup doit conserver il2setup.ini comme catalogue de profils.'
}
if (-not $manifest.il2SetupCompatibility.transactionalWrites) {
    Add-Error 'Les ecritures de configuration doivent etre transactionnelles.'
}
if (-not $manifest.il2SetupCompatibility.preserveUnknownKeys) {
    Add-Error 'Les cles inconnues de conf.ini doivent etre preservees.'
}

if (-not $manifest.errorReporting.automaticUploadRequiresConsent) {
    Add-Error 'L envoi automatique doit exiger un consentement explicite.'
}
if (-not $manifest.errorReporting.canDisable) {
    Add-Error 'Le joueur doit pouvoir desactiver les rapports automatiques.'
}
if (-not $manifest.errorReporting.canPreview -or -not $manifest.errorReporting.canDeletePending) {
    Add-Error 'Le joueur doit pouvoir consulter et supprimer les rapports en attente.'
}
if ($manifest.errorReporting.includeRawLogs) {
    Add-Error 'Les journaux bruts ne doivent jamais etre joints automatiquement.'
}
if ($manifest.errorReporting.includeMemoryDumpsAutomatically) {
    Add-Error 'Les dumps memoire ne doivent jamais etre joints automatiquement.'
}
if ([string]$manifest.errorReporting.transport -cne 'https-relay-github-app') {
    Add-Error 'Le transport des rapports doit passer par le relais HTTPS de la GitHub App.'
}
$githubPermissions = @($manifest.errorReporting.githubPermissions)
if ($githubPermissions.Count -ne 1 -or [string]$githubPermissions[0] -cne 'issues:write') {
    Add-Error 'La GitHub App du lanceur doit demander uniquement issues:write.'
}

$contracts = [ordered]@{
    'il2SetupCompatibility.legacyContract' = [string]$manifest.il2SetupCompatibility.legacyContract
    'errorReporting.schema' = [string]$manifest.errorReporting.schema
    'errorReporting.collectorManifest' = [string]$manifest.errorReporting.collectorManifest
}
foreach ($context in $contracts.Keys) {
    $relativePath = [string]$contracts[$context]
    if (-not (Test-RelativeProjectPath $relativePath $context)) {
        continue
    }
    $contractPath = Join-Path $resolvedRoot $relativePath
    if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
        Add-Error "$context : fichier absent ($relativePath)."
        continue
    }
    try {
        Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json | Out-Null
        $checkedContracts++
    }
    catch {
        Add-Error "$context : JSON invalide ($relativePath)."
    }
}

$collectorRelativePath = [string]$manifest.errorReporting.logCollector
if (Test-RelativeProjectPath $collectorRelativePath 'errorReporting.logCollector') {
    $collectorPath = Join-Path $resolvedRoot $collectorRelativePath
    if (-not (Test-Path -LiteralPath $collectorPath -PathType Leaf)) {
        Add-Error "errorReporting.logCollector : fichier absent ($collectorRelativePath)."
    }
    elseif ([IO.Path]::GetExtension($collectorPath) -cne '.ps1') {
        Add-Error 'errorReporting.logCollector : le collecteur attendu doit etre un script PowerShell.'
    }
    else {
        $tokens = $null
        $collectorErrors = $null
        [Management.Automation.Language.Parser]::ParseFile(
            $collectorPath,
            [ref]$tokens,
            [ref]$collectorErrors
        ) | Out-Null
        if ($collectorErrors.Count -gt 0) {
            Add-Error 'errorReporting.logCollector : syntaxe PowerShell invalide.'
        }
        else {
            $checkedContracts++
        }
    }
}

$result = [ordered]@{
    valid = ($errors.Count -eq 0)
    manifest = $resolvedManifest
    targetVersion = [string]$manifest.product.targetVersion
    checkedFiles = $checkedFiles
    checkedContracts = $checkedContracts
    errors = @($errors)
    warnings = @($warnings)
}

$result | ConvertTo-Json -Depth 8
if ($errors.Count -gt 0) {
    exit 1
}
