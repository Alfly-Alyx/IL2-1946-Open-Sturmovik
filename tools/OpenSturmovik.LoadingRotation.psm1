#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:PackageRoot = Split-Path -Parent $PSScriptRoot
$script:DataName = '.open-sturmovik-loading-rotation'
$script:ConfigRelative = 'Files/gui/backgrounds/rotation.properties'
function Get-OSHash([string]$Path) {
    if ([IO.File]::Exists($Path)) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
    return ''
}
function Get-OSSafePath([string]$Root, [string]$Relative) {
    $boundary = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if ([IO.Path]::IsPathRooted($Relative)) { throw 'Chemin relatif requis.' }
    $path = [IO.Path]::GetFullPath((Join-Path $boundary $Relative))
    if (-not $path.StartsWith($boundary + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Chemin hors du dossier du jeu.' }
    $cursor = $path
    while ($cursor.Length -ge $boundary.Length) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Lien de fichier ou dossier non pris en charge : $cursor" }
        }
        if ($cursor -eq $boundary) { break }
        $cursor = Split-Path -Parent $cursor
    }
    return $path
}
function Write-OSAtomic([string]$Path, [byte[]]$Bytes) {
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    $temp = $Path + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    $old = $temp + '.old'
    try {
        $stream = [IO.File]::Open($temp, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($Bytes, 0, $Bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temp, $Path, $old) }
        else { [IO.File]::Move($temp, $Path) }
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
        if ([IO.File]::Exists($old)) { [IO.File]::Delete($old) }
    }
}
function Get-OSJsonBytes($Value) { return ,([Text.Encoding]::UTF8.GetBytes(($Value | ConvertTo-Json -Depth 12))) }
function Read-OSJson([string]$Path) { return [IO.File]::ReadAllText($Path) | ConvertFrom-Json }
function Get-OSBytesHash([byte[]]$Bytes) {
    if ($null -eq $Bytes) { return '' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '') } finally { $sha.Dispose() }
}
function Assert-OSIdle {
    if (@(Get-Process -Name il2fb,Open_Sturmovik -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Fermez le jeu avant de modifier la rotation.' }
}
function Get-OSLoadingCatalog {
    $folder = Join-Path $script:PackageRoot '_Game Switcher/Resources/Loading Rotation'
    $catalog = Read-OSJson (Join-Path $folder 'catalog.json')
    if ($catalog.schemaVersion -ne 1) { throw 'Catalogue non reconnu.' }
    $seenIds = @{}; $seenHashes = @{}
    foreach ($item in $catalog.images) {
        if ($item.id -notmatch '^[a-z0-9][a-z0-9-]{0,63}$' -or $seenIds.ContainsKey($item.id)) { throw 'Identifiant de fond invalide.' }
        $path = Get-OSSafePath $folder $item.path
        $hash = Get-OSHash $path
        if (-not $hash -or $hash -ne $item.sha256 -or $seenHashes.ContainsKey($hash)) { throw "Image absente, modifiee ou dupliquee : $($item.label)" }
        $stream = [IO.File]::OpenRead($path)
        try {
            $h = New-Object byte[] 18
            if ($stream.Read($h, 0, 18) -ne 18) { throw 'TGA incomplet.' }
            $width = [BitConverter]::ToUInt16($h, 12); $height = [BitConverter]::ToUInt16($h, 14)
            if ($h[1] -ne 0 -or $h[2] -ne 2 -or $h[16] -ne 24 -or $width -ne $item.width -or $height -ne $item.height -or $stream.Length -lt (18L + $h[0] + 3L * $width * $height)) { throw 'Format TGA invalide.' }
        } finally { $stream.Dispose() }
        $seenIds[$item.id] = $true; $seenHashes[$hash] = $true
        [pscustomobject]@{ id=$item.id; label=$item.label; path=$path; sha256=$hash; source=(Get-OSSafePath $folder $item.source); width=$width; height=$height }
    }
}
function Get-OSConfig([string]$GameRoot) {
    $config = [pscustomobject]@{ enabled=$false; images=@(); official=''; mode='shuffle' }
    $path = Get-OSSafePath $GameRoot $script:ConfigRelative
    if (Test-Path -LiteralPath $path) {
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ($line -match '^(enabled|images|official|mode)=(.*)$') {
                switch ($matches[1]) {
                    enabled { $config.enabled = $matches[2] -eq 'true' }
                    images { $config.images = @($matches[2] -split ',' | Where-Object { $_ }) }
                    official { $config.official = $matches[2] }
                    mode { $config.mode = $matches[2] }
                }
            }
        }
    }
    return $config
}
function Get-OSConfigBytes($Config) {
    $nl = [Environment]::NewLine
    $text = '# Open Sturmovik - selection des fonds' + $nl
    $text += 'enabled=' + $Config.enabled.ToString().ToLowerInvariant() + $nl
    $text += 'images=' + ($Config.images -join ',') + $nl + 'official=' + $Config.official + $nl + 'mode=' + $Config.mode + $nl
    return ,([Text.Encoding]::ASCII.GetBytes($text))
}
function Backup-OSBlob([string]$Root, [string]$Path) {
    $hash = Get-OSHash $Path
    if ($hash) {
        $blob = Get-OSSafePath $Root ($script:DataName + '/backups/' + $hash + '.bin')
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $blob))
        if (-not [IO.File]::Exists($blob)) { [IO.File]::Copy($Path, $blob, $false) }
        if ((Get-OSHash $blob) -ne $hash) { throw 'Sauvegarde non conforme.' }
    }
    return $hash
}
function Get-OSBlob([string]$Root, [string]$Hash) {
    if (-not $Hash) { return $null }
    if ($Hash -notmatch '^[A-F0-9]{64}$') { throw 'Empreinte de sauvegarde invalide.' }
    $path = Get-OSSafePath $Root ($script:DataName + '/backups/' + $Hash + '.bin')
    if ((Get-OSHash $path) -ne $Hash) { throw 'Sauvegarde absente ou modifiee.' }
    return ,([IO.File]::ReadAllBytes($path))
}
function Restore-OSJournal([string]$Root, $Journal) {
    foreach ($entry in $Journal.entries) {
        $hash = Get-OSHash (Get-OSSafePath $Root $entry.relative)
        if ($hash -ne $entry.before -and $hash -ne $entry.after) { throw "Modification manuelle conservee : $($entry.relative). Sauvegardes disponibles." }
        if ($entry.before) { $null = Get-OSBlob $Root $entry.before }
    }
    foreach ($entry in $Journal.entries) {
        $path = Get-OSSafePath $Root $entry.relative
        if ($entry.before) { Write-OSAtomic $path (Get-OSBlob $Root $entry.before) }
        elseif ([IO.File]::Exists($path)) { [IO.File]::Delete($path) }
    }
}
function Repair-OSInstallation([string]$Root) {
    $pending = Get-OSSafePath $Root ($script:DataName + '/pending-install.json')
    if (-not [IO.File]::Exists($pending)) { return }
    $journal = Read-OSJson $pending
    $ledgerPath = Get-OSSafePath $Root ($script:DataName + '/installation.json')
    $committed = $false
    if ([IO.File]::Exists($ledgerPath)) { $committed = (Read-OSJson $ledgerPath).transactionId -eq $journal.id }
    if ($committed) {
        foreach ($entry in $journal.entries) {
            if ((Get-OSHash (Get-OSSafePath $Root $entry.relative)) -ne $entry.after) { throw 'Installation interrompue et fichier modifie. Sauvegardes conservees.' }
        }
    } else { Restore-OSJournal $Root $journal }
    [IO.File]::Delete($pending)
}
function Invoke-OSInstallTransaction([string]$Root, [object[]]$Plan, $Ledger) {
    $journal = [pscustomobject]@{ id=[Guid]::NewGuid().ToString('N'); entries=@() }
    $Ledger.transactionId = $journal.id
    $fullPlan = @($Plan) + @([pscustomobject]@{ relative=$script:DataName + '/installation.json'; bytes=(Get-OSJsonBytes $Ledger) })
    foreach ($change in $fullPlan) {
        $path = Get-OSSafePath $Root $change.relative
        if ((Test-Path -LiteralPath $path) -and -not [IO.File]::Exists($path)) { throw "La cible n'est pas un fichier : $path" }
        $journal.entries += [pscustomobject]@{ relative=$change.relative; before=(Backup-OSBlob $Root $path); after=(Get-OSBytesHash $change.bytes) }
    }
    $pending = Get-OSSafePath $Root ($script:DataName + '/pending-install.json')
    Write-OSAtomic $pending (Get-OSJsonBytes $journal)
    try {
        foreach ($change in $fullPlan) {
            $path = Get-OSSafePath $Root $change.relative
            if ($null -eq $change.bytes) { if ([IO.File]::Exists($path)) { [IO.File]::Delete($path) } }
            else { Write-OSAtomic $path $change.bytes }
        }
        foreach ($entry in $journal.entries) {
            if ((Get-OSHash (Get-OSSafePath $Root $entry.relative)) -ne $entry.after) { throw 'Verification apres ecriture incorrecte.' }
        }
        [IO.File]::Delete($pending)
    } catch {
        $failure = $_
        Restore-OSJournal $Root $journal
        [IO.File]::Delete($pending)
        throw $failure
    }
}
function Get-OSGameProfile {
    param([Parameter(Mandatory = $true)][string]$GameRoot)
    $exeHash = Get-OSHash (Get-OSSafePath $GameRoot 'il2fb.exe')
    $sfsHash = Get-OSHash (Get-OSSafePath $GameRoot 'files.SFS')
    $wrapperHash = Get-OSHash (Get-OSSafePath $GameRoot 'wrapper.dll')
    $manifest = Read-OSJson (Join-Path $script:PackageRoot 'manifests/switcher-v1.15.json')
    foreach ($profile in $manifest.profiles) {
        if ($exeHash -ne $profile.exeSha256 -or $sfsHash -ne $profile.filesSha256) { continue }
        if ($profile.mode -eq 'original' -and $wrapperHash -eq '') {
            return [pscustomobject]@{ kind = 'Stock'; number = $profile.number; version = $profile.version }
        }
        if ($profile.mode -ne 'original' -and $wrapperHash -eq '8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78') {
            return [pscustomobject]@{ kind = 'Modded'; number = $profile.number; version = $profile.version }
        }
    }
    return [pscustomobject]@{ kind = 'Unknown'; number = 0; version = '' }
}

function Get-OSPatchPlan {
    $folder = Join-Path $script:PackageRoot '_Game Switcher/Loading Rotation Patch'
    $manifest = Read-OSJson (Join-Path $folder 'manifest.json')
    foreach ($item in $manifest.classes) {
        if ($item.looseName -notmatch '^[A-F0-9]{16}$') { throw 'Nom de classe invalide.' }
        $path = Get-OSSafePath $folder ('Files/' + $item.looseName)
        if ((Get-OSHash $path) -ne $item.sha256) { throw 'Classe de rotation absente ou modifiee.' }
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -lt 8 -or [BitConverter]::ToString($bytes,0,4) -ne 'CA-FE-BA-BE' -or $bytes[6] -ne 0 -or $bytes[7] -ne 47) { throw 'Classe incompatible avec Java 1.3.' }
        [pscustomobject]@{ relative='Files/' + $item.looseName; bytes=$bytes }
    }
    foreach ($image in @(Get-OSLoadingCatalog)) {
        [pscustomobject]@{ relative='Files/gui/backgrounds/' + $image.id + '.tga'; bytes=[IO.File]::ReadAllBytes($image.path) }
        $material = "[ClassInfo]{0}  ClassName TMaterial{0}[Layer0]{0}  TextureName {1}.tga{0}  tfNoWriteZ 1{0}  tfNoDegradation 1{0}  tfMinLinear 1{0}  tfMagLinear 1{0}" -f [Environment]::NewLine,$image.id
        foreach ($suffix in @('','_cs','_de','_fr','_ru')) {
            [pscustomobject]@{ relative='Files/gui/backgrounds/' + $image.id + $suffix + '.mat'; bytes=[Text.Encoding]::ASCII.GetBytes($material) }
        }
    }
    [pscustomobject]@{ relative=$script:ConfigRelative; bytes=(Get-OSConfigBytes ([pscustomobject]@{enabled=$false;images=@();official='';mode='shuffle'})) }
}
function Set-OSLoadingRotation {
    [CmdletBinding()]
    param([string]$GameRoot=$script:PackageRoot,
        [ValidateSet('Status','Install','Enable','Disable','Remove')][string]$Action='Status',
        [string[]]$ImageIds=@(),[string]$OfficialId='',
        [ValidateSet('shuffle','ordered')][string]$Mode='shuffle')
    $root = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Dossier du jeu absent.' }
    $ledgerPath = Get-OSSafePath $root ($script:DataName + '/installation.json')
    $ledger = $null
    if ([IO.File]::Exists($ledgerPath)) { $ledger = Read-OSJson $ledgerPath }
    if ($Action -eq 'Status') { return [pscustomobject]@{installed=($null -ne $ledger -and $ledger.installed);configuration=(Get-OSConfig $root)} }
    if ($Action -eq 'Install' -and (Get-OSGameProfile -GameRoot $root).kind -eq 'Unknown') { throw 'Profil Open Sturmovik v1.15 non reconnu (EXE/SFS/wrapper). Aucune installation effectuee.' }
    Assert-OSIdle
    $switchRoot = Get-OSSafePath $root '_Game Switcher'
    if ((Test-Path -LiteralPath $switchRoot) -and @(Get-ChildItem -LiteralPath $switchRoot -Directory -Filter '_transaction-*').Count) { throw 'Changement de profil en cours.' }
    $data = Get-OSSafePath $root $script:DataName
    [void][IO.Directory]::CreateDirectory($data)
    try { $lock = [IO.File]::Open((Get-OSSafePath $data 'management.lock'),'OpenOrCreate','ReadWrite','None') }
    catch { throw 'Une autre operation de gestion est deja en cours.' }
    try {
        Repair-OSInstallation $root
        $ledger = if ([IO.File]::Exists($ledgerPath)) { Read-OSJson $ledgerPath } else { $null }
        if ($Action -eq 'Install') {
            if ($null -ne $ledger -and $ledger.installed) { return [pscustomobject]@{status='AlreadyInstalled';preserved=@()} }
            $plan = @(Get-OSPatchPlan)
            $hash = Get-OSHash (Get-OSSafePath $root 'Files/B96FAC8E2C4DDBE0')
            if ($hash -and $hash -ne '1C36806AA965835949125E09518425DD45D6E927EB1E055B3E701A5647215D9C') { throw 'Une autre surcharge ConsoleGL0 est presente. Integration refusee.' }
            $ledger = [pscustomobject]@{schemaVersion=1;installed=$true;transactionId='';entries=@()}
            foreach ($change in $plan) {
                $ledger.entries += [pscustomobject]@{relative=$change.relative;original=(Backup-OSBlob $root (Get-OSSafePath $root $change.relative));current=(Get-OSBytesHash $change.bytes)}
            }
            Invoke-OSInstallTransaction $root $plan $ledger
            return [pscustomobject]@{status='InstalledDisabled';preserved=@()}
        }
        if ($null -eq $ledger -or -not $ledger.installed) { throw 'La rotation integree doit etre installee auparavant.' }
        if ($Action -eq 'Remove') {
            $plan=@();$preserved=@()
            foreach ($entry in $ledger.entries | Where-Object { $_.relative -match '^Files/[A-F0-9]{16}$' }) {
                if ((Get-OSHash (Get-OSSafePath $root $entry.relative)) -ne $entry.current) { throw "Classe modifiee manuellement : $($entry.relative). Sauvegarde conservee." }
            }
            foreach ($entry in $ledger.entries) {
                if ((Get-OSHash (Get-OSSafePath $root $entry.relative)) -ne $entry.current) { $preserved += $entry.relative;continue }
                $plan += [pscustomobject]@{relative=$entry.relative;bytes=(Get-OSBlob $root $entry.original)}
            }
            foreach ($custom in @($preserved)) {
                if ($custom -match '^Files/gui/backgrounds/([a-z0-9-]+)(?:_[a-z]{2})?\.mat$') {
                    $texture = 'Files/gui/backgrounds/' + $matches[1] + '.tga'
                    $plan = @($plan | Where-Object { $_.relative -ne $texture })
                    if ($texture -notin $preserved) { $preserved += $texture }
                }
            }
            $ledger.installed=$false
            Invoke-OSInstallTransaction $root $plan $ledger
            return [pscustomobject]@{status='Removed';preserved=$preserved}
        }
        $configuration = Get-OSConfig $root
        if ($Action -eq 'Enable') {
            foreach ($installed in $ledger.entries | Where-Object { $_.relative -ne $script:ConfigRelative }) {
                if ((Get-OSHash (Get-OSSafePath $root $installed.relative)) -ne $installed.current) { throw "Ressource installee absente ou modifiee : $($installed.relative)" }
            }
            $catalog=@(Get-OSLoadingCatalog)
            if ($ImageIds.Count -lt 2 -or $ImageIds.Count -gt 4 -or @($ImageIds | Select-Object -Unique).Count -ne $ImageIds.Count) { throw 'Choisir entre deux et quatre images distinctes.' }
            foreach ($id in $ImageIds) { if ($id -notin $catalog.id) { throw "Fond inconnu : $id" } }
            if ($OfficialId -and ($OfficialId -notin $ImageIds -or $ImageIds.Count -lt 3)) { throw 'Le fond officiel double demande au moins trois images, dont ce fond.' }
            $configuration.images=@($ImageIds);$configuration.official=$OfficialId;$configuration.mode=$Mode;$configuration.enabled=$true
        } else { $configuration.enabled=$false }
        $bytes=Get-OSConfigBytes $configuration
        $configEntry=@($ledger.entries | Where-Object { $_.relative -eq $script:ConfigRelative })
        if ($configEntry.Count -ne 1) { throw 'Inventaire de configuration incomplet.' }
        $configEntry[0].current=Get-OSBytesHash $bytes
        Invoke-OSInstallTransaction $root @([pscustomobject]@{relative=$script:ConfigRelative;bytes=$bytes}) $ledger
        $selectionLock=Get-OSSafePath $data 'selection.lock'
        if ([IO.File]::Exists($selectionLock)) { [IO.File]::Delete($selectionLock) }
        return [pscustomobject]@{status=$Action;preserved=@()}
    } finally { $lock.Dispose() }
}
Export-ModuleMember -Function Get-OSLoadingCatalog, Set-OSLoadingRotation
