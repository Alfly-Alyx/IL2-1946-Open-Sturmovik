[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$MsiPath,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$FlatPayloadPath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$RetailExecutablePath,

    [switch]$ValidateOnly
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

trap {
    Write-Error ("{0}`r`n{1}" -f $_.InvocationInfo.PositionMessage, $_.ScriptStackTrace)
    break
}

function Get-MsiTargetName {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$EncodedName)

    if ([string]::IsNullOrEmpty($EncodedName)) {
        return ''
    }
    $targetName = ($EncodedName -split ':', 2)[0]
    if ($targetName -eq '.') {
        return ''
    }
    if ($targetName.Contains('|')) {
        return ($targetName -split '\|', 2)[1]
    }
    return $targetName
}

$resolvedMsi = (Resolve-Path -LiteralPath $MsiPath).Path
$resolvedPayload = (Resolve-Path -LiteralPath $FlatPayloadPath).Path
$resolvedDestination = [IO.Path]::GetFullPath($DestinationPath)
$resolvedRetailExecutable = if ($RetailExecutablePath) {
    (Resolve-Path -LiteralPath $RetailExecutablePath).Path
}
else {
    $null
}

$windowsKitsRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
$msiDb = Get-ChildItem -LiteralPath $windowsKitsRoot -Recurse -File -Filter 'MsiDb.exe' -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -match '\\x86$' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1
if (-not $msiDb) {
    throw 'MsiDb.exe est introuvable dans le kit Windows 10.'
}

$tableDirectory = Join-Path ([IO.Path]::GetTempPath()) ('OpenSturmovik-MsiTables-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tableDirectory | Out-Null
$arguments = @(
    '-d', ('"' + $resolvedMsi + '"'),
    '-f', ('"' + $tableDirectory + '"'),
    '-e', 'Directory',
    '-e', 'Component',
    '-e', 'File'
)
$export = Start-Process -FilePath $msiDb.FullName -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
if ($export.ExitCode -ne 0) {
    throw "MsiDb.exe n'a pas pu exporter les tables MSI (code $($export.ExitCode))."
}

function Import-MsiIdt {
    param([Parameter(Mandatory = $true)][string]$Path)

    $rows = @(Import-Csv -LiteralPath $Path -Delimiter "`t" -Encoding Default)
    if ($rows.Count -lt 3) {
        throw "Table IDT vide ou invalide : $Path"
    }
    # Les deux premieres lignes de donnees decrivent les types et les cles.
    return @($rows | Select-Object -Skip 2)
}

$directoryRows = @(Import-MsiIdt -Path (Join-Path $tableDirectory 'Directory.idt'))
$componentRows = @(Import-MsiIdt -Path (Join-Path $tableDirectory 'Component.idt'))
$fileRows = @(Import-MsiIdt -Path (Join-Path $tableDirectory 'File.idt'))

$directories = @{}
foreach ($row in $directoryRows) {
    $directories[[string]$row.Directory] = New-Object PSObject -Property @{
        Parent = [string]$row.Directory_Parent
        DefaultName = [string]$row.DefaultDir
    }
}

$components = @{}
foreach ($row in $componentRows) {
    $components[[string]$row.Component] = [string]$row.Directory_
}

$directoryCache = @{}
function Resolve-InstallDirectory {
    param([Parameter(Mandatory = $true)][string]$DirectoryId)

    if ($directoryCache.ContainsKey($DirectoryId)) {
        return $directoryCache[$DirectoryId]
    }
    if ($DirectoryId -eq 'INSTALLDIR') {
        $directoryCache[$DirectoryId] = ''
        return ''
    }

    $segments = New-Object System.Collections.Generic.List[string]
    $visited = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $currentId = $DirectoryId
    while ($currentId -and $currentId -ne 'INSTALLDIR') {
        if (-not $visited.Add($currentId)) {
            throw "Cycle detecte dans la table Directory pour $DirectoryId."
        }
        if (-not $directories.ContainsKey($currentId)) {
            return $null
        }
        $segment = Get-MsiTargetName -EncodedName $directories[$currentId].DefaultName
        if ($segment) {
            $segments.Insert(0, $segment)
        }
        $currentId = $directories[$currentId].Parent
    }

    if ($currentId -ne 'INSTALLDIR') {
        return $null
    }

    $relativePath = [string]::Join([IO.Path]::DirectorySeparatorChar, $segments.ToArray())
    $directoryCache[$DirectoryId] = $relativePath
    return $relativePath
}

$mappedFiles = New-Object System.Collections.Generic.List[object]
$outsideInstallDirectory = 0
$missingSources = New-Object System.Collections.Generic.List[string]
$sizeMismatches = New-Object System.Collections.Generic.List[string]
$relativePaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

foreach ($row in $fileRows) {
    $fileId = [string]$row.File
    $componentId = [string]$row.Component_
    $encodedFileName = [string]$row.FileName
    $expectedSize = [int64]$row.FileSize
    $sequence = [int]$row.Sequence

    if (-not $components.ContainsKey($componentId)) {
        $outsideInstallDirectory++
        continue
    }
    $relativeDirectory = Resolve-InstallDirectory -DirectoryId $components[$componentId]
    if ($null -eq $relativeDirectory) {
        $outsideInstallDirectory++
        continue
    }

    $fileName = Get-MsiTargetName -EncodedName $encodedFileName
    if ([string]::IsNullOrWhiteSpace($fileName)) {
        throw "Nom cible vide pour l'identifiant MSI $fileId."
    }
    $relativePath = if ($relativeDirectory) {
        Join-Path $relativeDirectory $fileName
    }
    else {
        $fileName
    }
    if ([IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Chemin MSI non sur : $relativePath"
    }
    if (-not $relativePaths.Add($relativePath)) {
        throw "Chemin cible duplique dans le MSI : $relativePath"
    }

    $sourcePath = Join-Path $resolvedPayload $fileId
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $missingSources.Add($fileId)
    }
    elseif ((Get-Item -LiteralPath $sourcePath).Length -ne $expectedSize) {
        $sizeMismatches.Add($fileId)
    }

    $mappedFiles.Add((New-Object PSObject -Property @{
        Id = $fileId
        RelativePath = $relativePath
        SourcePath = $sourcePath
        Size = $expectedSize
        Sequence = $sequence
    }))
}

$executableRecord = @($mappedFiles | Where-Object { $_.RelativePath -eq 'il2fb.exe' })
if ($executableRecord.Count -ne 1) {
    throw "Le MSI doit decrire exactement un il2fb.exe ; resultat : $($executableRecord.Count)."
}
if ($executableRecord[0].Size -eq 0) {
    if (-not $resolvedRetailExecutable) {
        throw "Le MSI contient un il2fb.exe vide. Indiquer -RetailExecutablePath avec l'executable place a la racine du DVD."
    }
    $retailExecutable = Get-Item -LiteralPath $resolvedRetailExecutable
    if ($retailExecutable.Length -le 0) {
        throw "L'executable DVD est vide : $resolvedRetailExecutable"
    }
    $executableRecord[0].SourcePath = $resolvedRetailExecutable
    $executableRecord[0].Size = $retailExecutable.Length
}

Write-Host "MSI : $($fileRows.Count) fichiers, $($mappedFiles.Count) chemins reconstruits."
Write-Host "Sources absentes : $($missingSources.Count) ; tailles incorrectes : $($sizeMismatches.Count) ; hors INSTALLDIR : $outsideInstallDirectory."

if ($missingSources.Count -gt 0) {
    throw "Le contenu CAB est incomplet. Premiers identifiants absents : $([string]::Join(', ', @($missingSources | Select-Object -First 10)))"
}
if ($sizeMismatches.Count -gt 0) {
    throw "Le contenu CAB contient des tailles incorrectes. Premiers identifiants : $([string]::Join(', ', @($sizeMismatches | Select-Object -First 10)))"
}
if ($outsideInstallDirectory -ne 0) {
    throw "$outsideInstallDirectory fichier(s) MSI ne sont pas rattaches a INSTALLDIR."
}

$criticalNames = @('conf.ini', 'files.SFS', 'il2fb.exe', 'il2_core.dll', 'il2_corep4.dll', 'mg_snd.dll', 'mg_snd_sse.dll')
$critical = @($mappedFiles | Where-Object { $criticalNames -contains $_.RelativePath })
foreach ($name in $criticalNames) {
    if (-not ($critical | Where-Object { $_.RelativePath -eq $name })) {
        throw "Fichier critique absent de la reconstruction MSI : $name"
    }
}
$critical | Sort-Object RelativePath | ForEach-Object {
    Write-Host ("  {0} ({1} octets)" -f $_.RelativePath, $_.Size)
}

if ($ValidateOnly) {
    Write-Host 'Validation terminee ; aucun fichier reconstruit.' -ForegroundColor Green
    return
}

if (Test-Path -LiteralPath $resolvedDestination) {
    $existing = @(Get-ChildItem -LiteralPath $resolvedDestination -Force -ErrorAction Stop | Select-Object -First 1)
    if ($existing.Count -ne 0) {
        throw "La destination doit etre absente ou vide : $resolvedDestination"
    }
}
elseif ($PSCmdlet.ShouldProcess($resolvedDestination, 'Creer le dossier de reconstruction')) {
    New-Item -ItemType Directory -Path $resolvedDestination | Out-Null
}

$copied = 0
foreach ($file in ($mappedFiles | Sort-Object Sequence)) {
    $destinationFile = Join-Path $resolvedDestination $file.RelativePath
    $destinationDirectory = Split-Path -Parent $destinationFile
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }
    if ($PSCmdlet.ShouldProcess($destinationFile, 'Reconstruire le fichier du DVD')) {
        Copy-Item -LiteralPath $file.SourcePath -Destination $destinationFile
        $copied++
    }
}

$resultFiles = @(Get-ChildItem -LiteralPath $resolvedDestination -Recurse -File)
$resultBytes = ($resultFiles | Measure-Object Length -Sum).Sum
$expectedBytes = ($mappedFiles | Measure-Object Size -Sum).Sum
if ($resultFiles.Count -ne $mappedFiles.Count -or $resultBytes -ne $expectedBytes) {
    throw "Verification finale incorrecte : $($resultFiles.Count)/$($mappedFiles.Count) fichiers, $resultBytes/$expectedBytes octets."
}

Write-Host "Reconstruction 4.07m terminee : $copied fichiers, $resultBytes octets." -ForegroundColor Green
