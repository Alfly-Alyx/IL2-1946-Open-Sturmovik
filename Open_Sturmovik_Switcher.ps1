[CmdletBinding()]
param(
    [Alias('Profile','Choice')]
    [ValidateSet('1','2','3','4','5','6','7','8','9','10','11','12')]
    [string]$SelectedProfile,

    [ValidateSet('1','2','3')]
    [string]$Hud,

    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:AddonVersion = '1.15'
$script:Root = $PSScriptRoot
$script:ProfileRoot = Join-Path $script:Root '_Game Switchers'

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '')
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Test-CopyIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        return $false
    }

    $sourceInfo = Get-Item -LiteralPath $Source
    $destinationInfo = Get-Item -LiteralPath $Destination
    if ($sourceInfo.Length -ne $destinationInfo.Length) {
        return $false
    }

    return (Get-Sha256 -Path $Source) -eq (Get-Sha256 -Path $Destination)
}

function Invoke-FileTransaction {
    param(
        [Parameter(Mandatory = $true)][array]$Copies,
        [string[]]$RemoveTargets = @()
    )

    foreach ($copy in $Copies) {
        if (-not (Test-Path -LiteralPath $copy.Source -PathType Leaf)) {
            throw "Source introuvable : $($copy.Source)"
        }
    }

    $transaction = Join-Path $script:Root ('.open-sturmovik-transaction-' + [Guid]::NewGuid().ToString('N'))
    $stage = Join-Path $transaction 'stage'
    $backup = Join-Path $transaction 'backup'
    New-Item -ItemType Directory -Path $stage, $backup | Out-Null

    $targets = @{}
    $preserveTransaction = $false
    try {
        $index = 0
        foreach ($copy in $Copies) {
            $index++
            $stagedFile = Join-Path $stage (('{0:D2}-' -f $index) + [System.IO.Path]::GetFileName($copy.Target))
            Copy-Item -LiteralPath $copy.Source -Destination $stagedFile -Force
            if (-not (Test-CopyIdentity -Source $copy.Source -Destination $stagedFile)) {
                throw "Echec de verification pendant la preparation de $($copy.Target)."
            }
            $copy | Add-Member -NotePropertyName Staged -NotePropertyValue $stagedFile -Force
        }

        $allTargets = @($Copies | ForEach-Object { $_.Target }) + @($RemoveTargets)
        $index = 0
        foreach ($target in $allTargets) {
            if ($targets.ContainsKey($target)) {
                continue
            }
            $index++
            $record = New-Object PSObject -Property @{
                Existed = (Test-Path -LiteralPath $target -PathType Leaf)
                Backup = (Join-Path $backup (('{0:D2}-' -f $index) + [System.IO.Path]::GetFileName($target)))
            }
            if ($record.Existed) {
                Copy-Item -LiteralPath $target -Destination $record.Backup -Force
                if (-not (Test-CopyIdentity -Source $target -Destination $record.Backup)) {
                    throw "Impossible de verifier la sauvegarde de $target."
                }
            }
            $targets[$target] = $record
        }

        foreach ($copy in $Copies) {
            $targetDirectory = Split-Path -Parent $copy.Target
            if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
                New-Item -ItemType Directory -Path $targetDirectory | Out-Null
            }
            Copy-Item -LiteralPath $copy.Staged -Destination $copy.Target -Force
            if (-not (Test-CopyIdentity -Source $copy.Source -Destination $copy.Target)) {
                throw "La copie finale de $($copy.Target) n'est pas conforme a la source."
            }
        }

        foreach ($target in $RemoveTargets) {
            if (Test-Path -LiteralPath $target) {
                Remove-Item -LiteralPath $target -Force
            }
            if (Test-Path -LiteralPath $target) {
                throw "Impossible de retirer $target pour le profil Original."
            }
        }
    }
    catch {
        Write-Host 'Une erreur est survenue. Restauration de l installation precedente...' -ForegroundColor Yellow
        $rollbackFailed = $false
        foreach ($target in $targets.Keys) {
            $record = $targets[$target]
            try {
                if ($record.Existed) {
                    $targetDirectory = Split-Path -Parent $target
                    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
                        New-Item -ItemType Directory -Path $targetDirectory | Out-Null
                    }
                    Copy-Item -LiteralPath $record.Backup -Destination $target -Force
                    if (-not (Test-CopyIdentity -Source $record.Backup -Destination $target)) {
                        throw "La restauration de $target n'est pas conforme a sa sauvegarde."
                    }
                }
                elseif (Test-Path -LiteralPath $target) {
                    Remove-Item -LiteralPath $target -Force
                }
            }
            catch {
                $rollbackFailed = $true
                Write-Host "[ERREUR] Restauration manuelle necessaire pour : $target" -ForegroundColor Red
            }
        }
        if ($rollbackFailed) {
            $preserveTransaction = $true
            Write-Host "Les sauvegardes de secours sont conservees dans : $transaction" -ForegroundColor Red
        }
        throw
    }
    finally {
        if (-not $preserveTransaction -and (Test-Path -LiteralPath $transaction)) {
            Remove-Item -LiteralPath $transaction -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-ProfileFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $result = [ordered]@{}
    $section = $null
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[(.+)\]$') {
            $section = $matches[1]
            if (-not $result.Contains($section)) {
                $result[$section] = [ordered]@{}
            }
        }
        elseif ($section -and $trimmed -and -not $trimmed.StartsWith(';') -and $trimmed -match '^([^=]+)=(.*)$') {
            $result[$section][$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    return $result
}

function Set-IniSectionValues {
    param(
        [Parameter(Mandatory = $true)]$Lines,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)]$Values
    )

    $sectionStart = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match ('^\s*\[' + [regex]::Escape($Section) + '\]\s*$')) {
            $sectionStart = $i
            break
        }
    }

    if ($sectionStart -lt 0) {
        if ($Lines.Count -gt 0 -and $Lines[$Lines.Count - 1] -ne '') {
            $Lines.Add('') | Out-Null
        }
        $Lines.Add("[$Section]") | Out-Null
        foreach ($key in $Values.Keys) {
            $Lines.Add("$key=$($Values[$key])") | Out-Null
        }
        return
    }

    $sectionEnd = $Lines.Count
    for ($i = $sectionStart + 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*\[.+\]\s*$') {
            $sectionEnd = $i
            break
        }
    }

    foreach ($key in $Values.Keys) {
        $found = $false
        $pattern = '^\s*;?\s*' + [regex]::Escape($key) + '\s*='
        for ($i = $sectionStart + 1; $i -lt $sectionEnd; $i++) {
            if ($Lines[$i] -match $pattern) {
                $Lines[$i] = "$key=$($Values[$key])"
                $found = $true
                break
            }
        }
        if (-not $found) {
            $Lines.Insert($sectionEnd, "$key=$($Values[$key])")
            $sectionEnd++
        }
    }
}

function Get-FourPhysicalCoreAffinityMask {
    try {
        if (-not ('OpenSturmovik.CpuTopology' -as [type])) {
            $source = @"
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace OpenSturmovik {
    internal enum LogicalProcessorRelationship : int {
        ProcessorCore = 0
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct SystemLogicalProcessorInformation {
        public UIntPtr ProcessorMask;
        public LogicalProcessorRelationship Relationship;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
        public byte[] Details;
    }

    public static class CpuTopology {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GetLogicalProcessorInformation(
            IntPtr buffer,
            ref uint returnedLength);

        public static ulong[] GetPhysicalCoreMasks() {
            uint length = 0;
            if (!GetLogicalProcessorInformation(IntPtr.Zero, ref length)) {
                int error = Marshal.GetLastWin32Error();
                if (error != 122) {
                    throw new Win32Exception(error);
                }
            }
            if (length == 0) {
                throw new InvalidOperationException("Empty processor topology.");
            }

            IntPtr buffer = Marshal.AllocHGlobal((int)length);
            try {
                if (!GetLogicalProcessorInformation(buffer, ref length)) {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }

                int itemSize = Marshal.SizeOf(typeof(SystemLogicalProcessorInformation));
                int count = (int)length / itemSize;
                List<ulong> masks = new List<ulong>();
                for (int index = 0; index < count; index++) {
                    IntPtr current = new IntPtr(buffer.ToInt64() + (index * itemSize));
                    SystemLogicalProcessorInformation item =
                        (SystemLogicalProcessorInformation)Marshal.PtrToStructure(
                            current, typeof(SystemLogicalProcessorInformation));
                    if (item.Relationship == LogicalProcessorRelationship.ProcessorCore) {
                        ulong mask = UIntPtr.Size == 8
                            ? item.ProcessorMask.ToUInt64()
                            : item.ProcessorMask.ToUInt32();
                        if (mask != 0) {
                            masks.Add(mask);
                        }
                    }
                }
                ulong[] result = masks.ToArray();
                Array.Sort(result);
                return result;
            }
            finally {
                Marshal.FreeHGlobal(buffer);
            }
        }
    }
}
"@
            Add-Type -TypeDefinition $source -ErrorAction Stop
        }

        [uint64]$mask = 0
        $selectedCores = 0
        foreach ($coreMaskValue in [OpenSturmovik.CpuTopology]::GetPhysicalCoreMasks()) {
            [uint64]$coreMask = $coreMaskValue
            for ($logicalIndex = 0; $logicalIndex -lt 32; $logicalIndex++) {
                [uint64]$logicalBit = ([uint64]1 -shl $logicalIndex)
                if (($coreMask -band $logicalBit) -ne 0) {
                    $mask = $mask -bor $logicalBit
                    $selectedCores++
                    break
                }
            }
            if ($selectedCores -ge 4) {
                break
            }
        }
        if ($mask -eq 0) {
            throw 'Masque processeur vide.'
        }
        return $mask
    }
    catch {
        # Valeur historique : au plus quatre processeurs logiques.
        return [uint64]15
    }
}

function Get-GraphicsVendorProfile {
    try {
        $adapters = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        $adapter = @($adapters | Where-Object {
            $_.CurrentHorizontalResolution -and $_.CurrentVerticalResolution
        })[0]
        if (-not $adapter) {
            $adapter = $adapters[0]
        }
        if (-not $adapter) {
            throw 'Aucune carte graphique detectee.'
        }

        $pnpId = [string]$adapter.PNPDeviceID
        $vendor = if ($pnpId -match 'VEN_10DE') {
            'NVIDIA'
        }
        elseif ($pnpId -match 'VEN_(1002|1022)') {
            'AMD'
        }
        elseif ($pnpId -match 'VEN_8086') {
            'Intel'
        }
        else {
            'Generique'
        }
        return (New-Object PSObject -Property @{
            Vendor = $vendor
            Name = [string]$adapter.Name
        })
    }
    catch {
        return (New-Object PSObject -Property @{
            Vendor = 'Generique'
            Name = 'carte non identifiee'
        })
    }
}

function Set-MaximumConfiguration {
    $confPath = Join-Path $script:Root 'conf.ini'
    $profilePath = Join-Path $script:ProfileRoot 'conf.max.ini'
    if (-not (Test-Path -LiteralPath $confPath -PathType Leaf)) {
        Write-Host '[AVERTISSEMENT] conf.ini absent : les reglages maximum seront appliques apres installation sur le jeu.' -ForegroundColor Yellow
        return
    }
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        throw "Profil graphique introuvable : $profilePath"
    }

    $backupPath = "$confPath.open-sturmovik.bak"
    Copy-Item -LiteralPath $confPath -Destination $backupPath -Force

    try {
        $bytes = [System.IO.File]::ReadAllBytes($confPath)
        $encoding = [System.Text.Encoding]::Default
        $offset = 0
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = New-Object System.Text.UTF8Encoding($true)
            $offset = 3
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $encoding = [System.Text.Encoding]::Unicode
            $offset = 2
        }

        $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
        $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
        $hadFinalNewline = $text.EndsWith("`n")
        $parts = $text -split '\r?\n'
        if ($hadFinalNewline -and $parts.Count -gt 0 -and $parts[$parts.Count - 1] -eq '') {
            $parts = $parts[0..($parts.Count - 2)]
        }
        $lines = New-Object 'System.Collections.Generic.List[string]'
        foreach ($line in $parts) {
            $lines.Add($line) | Out-Null
        }

        $profile = Read-ProfileFile -Path $profilePath
        $affinityMask = Get-FourPhysicalCoreAffinityMask
        $profile['rts']['ProcessAffinityMask'] = $affinityMask.ToString([System.Globalization.CultureInfo]::InvariantCulture)
        $graphics = Get-GraphicsVendorProfile
        $nvExtensions = if ($graphics.Vendor -eq 'NVIDIA') { '1' } else { '0' }
        foreach ($key in 'TexFlags.TexEnvCombine4NV','TexFlags.DepthClampNV','TexFlags.TextureShaderNV') {
            $profile['Render_OpenGL'][$key] = $nvExtensions
        }
        foreach ($section in $profile.Keys) {
            Set-IniSectionValues -Lines $lines -Section $section -Values $profile[$section]
        }

        $updated = [string]::Join($newline, $lines.ToArray())
        if ($hadFinalNewline) {
            $updated += $newline
        }
        [System.IO.File]::WriteAllText($confPath, $updated, $encoding)
        Write-Host "Reglages graphiques maximum appliques pour $($graphics.Vendor) ($($graphics.Name))." -ForegroundColor Green
        Write-Host "Affinite limitee a quatre coeurs maximum (masque $affinityMask)." -ForegroundColor Green
    }
    catch {
        Copy-Item -LiteralPath $backupPath -Destination $confPath -Force
        throw "Echec de mise a jour de conf.ini ; la sauvegarde a ete restauree. $($_.Exception.Message)"
    }
}

function New-CopyOperation {
    param([string]$Source, [string]$Target)
    return (New-Object PSObject -Property @{ Source = $Source; Target = $Target })
}

$profiles = @{
    '1' = @{ Label = '4.08m Original'; Folder = '4.08 Mods OFF (Original)'; Air = '408m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $true }
    '2' = @{ Label = '4.08m modifie (sans 6DOF)'; Folder = '4.08 Mod ON (NO 6DOF)'; Air = '408m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $false }
    '3' = @{ Label = '4.08m modifie + profil 6DOF historique'; Folder = '4.08 Mods 6DOF ON'; Air = '408m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $false }
    '4' = @{ Label = '4.09b Original'; Folder = '4.09 Mods OFF (Original)'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $true }
    '5' = @{ Label = '4.09b modifie (sans 6DOF)'; Folder = '4.09 Mods ON (NO 6DOF)'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $false }
    '6' = @{ Label = '4.09b modifie + profil 6DOF historique'; Folder = '4.09 Mods 6DOF ON'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\408 & 409b\stationary.ini'; Original = $false }
    '7' = @{ Label = '4.09m Original'; Folder = '4.09finalModsOFF(Original)'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\409m\stationary.ini'; Original = $true }
    '8' = @{ Label = '4.09m modifie (sans 6DOF)'; Folder = '4.09finalModsON(No-6DoF)'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\409m\stationary.ini'; Original = $false }
    '9' = @{ Label = '4.09m modifie + profil 6DOF historique'; Folder = '4.09final_ModsON+6DoF'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\409m\stationary.ini'; Original = $false }
    '11' = @{ Label = '4.09m modifie + cache experimental (sans 6DOF)'; Folder = '4.09finalModsON(No-6DoF)'; Wrapper = 'Wrapper Cache 4.09m (Experimental)\wrapper.dll'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\409m\stationary.ini'; Original = $false; ExperimentalCache = $true }
    '12' = @{ Label = '4.09m modifie + cache experimental + profil 6DOF historique'; Folder = '4.09final_ModsON+6DoF'; Wrapper = 'Wrapper Cache 4.09m (Experimental)\wrapper.dll'; Air = '409m air.ini\Air.ini\air.ini'; Stationary = 'Stationary\409m\stationary.ini'; Original = $false; ExperimentalCache = $true }
}

try {
    if (-not $PSBoundParameters.ContainsKey('SelectedProfile')) {
        Clear-Host
    }
    Write-Host '======================================================'
    Write-Host "       IL-2 Open Sturmovik Switcher $script:AddonVersion"
    Write-Host '======================================================'
    Write-Host 'Les fichiers actuels ne sont modifies qu apres validation complete.'
    Write-Host ''
    foreach ($key in '1','2','3','4','5','6','7','8','9') {
        Write-Host "$key - $($profiles[$key].Label)"
    }
    Write-Host '10 - Quiet (quitter sans aucune modification)'
    Write-Host '11 - 4.09m modifie + cache experimental (sans 6DOF)'
    Write-Host '12 - 4.09m modifie + cache experimental + profil 6DOF historique'
    Write-Host ''
    $choice = if ($PSBoundParameters.ContainsKey('SelectedProfile')) {
        $SelectedProfile
    }
    else {
        (Read-Host 'Votre choix').Trim()
    }

    if ($choice -eq '10' -or $choice -match '^[Qq]$') {
        Write-Host 'Aucune modification effectuee.' -ForegroundColor Green
        exit 0
    }
    if (-not $profiles.ContainsKey($choice)) {
        throw "Choix invalide : $choice"
    }

    if ($choice -in @('3', '6', '9', '12')) {
        Write-Host '[AVERTISSEMENT] Les fichiers 6DOF historiques sont identiques au profil sans 6DOF correspondant.' -ForegroundColor Yellow
        Write-Host 'Ce choix est conserve pour compatibilite du menu, mais ne peut pas activer seul un comportement 6DOF distinct.' -ForegroundColor Yellow
    }

    $profile = $profiles[$choice]
    if ($profile.ContainsKey('ExperimentalCache') -and $profile.ExperimentalCache) {
        Write-Host '[EXPERIMENTAL] Ce wrapper a passe les tests statiques et le banc de cache, mais pas encore un lancement IL-2.' -ForegroundColor Yellow
        Write-Host 'Le profil stable reste disponible avec les choix 8 et 9.' -ForegroundColor Yellow
    }
    $sourceFolder = Join-Path $script:ProfileRoot $profile.Folder
    $copies = @(
        (New-CopyOperation -Source (Join-Path $sourceFolder 'il2fb.exe') -Target (Join-Path $script:Root 'il2fb.exe')),
        (New-CopyOperation -Source (Join-Path $sourceFolder 'files.SFS') -Target (Join-Path $script:Root 'files.SFS')),
        (New-CopyOperation -Source (Join-Path $script:ProfileRoot $profile.Air) -Target (Join-Path $script:Root 'Files\com\maddox\il2\objects\air.ini')),
        (New-CopyOperation -Source (Join-Path $script:ProfileRoot $profile.Stationary) -Target (Join-Path $script:Root 'Files\com\maddox\il2\objects\stationary.ini'))
    )
    $removeTargets = @()
    $wrapperTarget = Join-Path $script:Root 'wrapper.dll'
    if ($profile.Original) {
        $removeTargets += $wrapperTarget
    }
    else {
        $wrapperSource = if ($profile.ContainsKey('Wrapper')) {
            Join-Path $script:ProfileRoot $profile.Wrapper
        }
        else {
            Join-Path $sourceFolder 'wrapper.dll'
        }
        $copies += New-CopyOperation -Source $wrapperSource -Target $wrapperTarget
    }

    Invoke-FileTransaction -Copies $copies -RemoveTargets $removeTargets
    Write-Host "Profil active : $($profile.Label)" -ForegroundColor Green

    Write-Host ''
    Write-Host 'HUD :'
    Write-Host '1 - Standard'
    Write-Host '2 - Immersion'
    Write-Host '3 - Quiet (conserver le HUD actuel)'
    $hudChoice = if ($PSBoundParameters.ContainsKey('Hud')) {
        $Hud
    }
    elseif ($PSBoundParameters.ContainsKey('SelectedProfile')) {
        '3'
    }
    else {
        (Read-Host 'Votre choix').Trim()
    }
    if ($hudChoice -eq '1' -or $hudChoice -eq '2') {
        $hudFolder = if ($hudChoice -eq '1') { 'HudLogStock' } else { 'HudLogImmersion' }
        $hudSource = Join-Path $script:ProfileRoot "$hudFolder\MODS\STD\i18n\hud_log_ru.properties"
        $hudTarget = Join-Path $script:Root 'Files\i18n\hud_log_ru.properties'
        Invoke-FileTransaction -Copies @((New-CopyOperation -Source $hudSource -Target $hudTarget))
        Write-Host 'HUD mis a jour et verifie.' -ForegroundColor Green
    }
    elseif ($hudChoice -ne '3' -and $hudChoice -notmatch '^[Qq]$') {
        throw "Choix HUD invalide : $hudChoice"
    }

    Set-MaximumConfiguration
    Write-Host ''
    Write-Host 'Operation terminee avec succes. Vous pouvez lancer IL-2 Open Sturmovik.' -ForegroundColor Green
    if (-not $NoPause) {
        Read-Host 'Appuyez sur Entree pour fermer' | Out-Null
    }
    exit 0
}
catch {
    Write-Host ''
    Write-Host "[ERREUR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Le selecteur n annonce jamais une operation reussie apres cette erreur.' -ForegroundColor Red
    exit 1
}
