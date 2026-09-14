[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GameRoot,

    [string[]]$DesktopFolders
)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($GameRoot).TrimEnd('\')
$exe = Join-Path $root 'il2fb.exe'
if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) {
    throw "Executable absent : $exe"
}

$updated = 0
$updatedShortcutPaths = @()
if (-not $DesktopFolders) {
    $DesktopFolders = @(
        [Environment]::GetFolderPath('Desktop'),
        [Environment]::GetFolderPath('CommonDesktopDirectory')
    )
}
$DesktopFolders = @($DesktopFolders | Where-Object { $_ } | Select-Object -Unique)

$shell = New-Object -ComObject WScript.Shell
foreach ($desktop in $desktopFolders) {
    $shortcutPath = Join-Path $desktop 'Open Sturmovik.lnk'
    if (-not (Test-Path -LiteralPath $shortcutPath -PathType Leaf)) {
        continue
    }
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.IconLocation = "$exe,0"
    $shortcut.Save()
    $updatedShortcutPaths += $shortcutPath
    $updated++
}

if (-not ('OpenSturmovik.IconRefresh' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace OpenSturmovik {
    public static class IconRefresh {
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
        public static extern void SHChangeNotify(uint eventId, uint flags, string item1, IntPtr item2);
    }
}
"@
}

# SHCNE_UPDATEITEM + SHCNF_PATHW + SHCNF_FLUSHNOWAIT refreshes the
# executable and shortcuts without blocking the switcher on Explorer.
[OpenSturmovik.IconRefresh]::SHChangeNotify(0x00002000, 0x2005, $exe, [IntPtr]::Zero)
foreach ($shortcutPath in $updatedShortcutPaths) {
    [OpenSturmovik.IconRefresh]::SHChangeNotify(0x00002000, 0x2005, $shortcutPath, [IntPtr]::Zero)
}

[pscustomobject]@{
    Executable = $exe
    UpdatedDesktopShortcuts = $updated
    ShellRefreshSent = $true
}