[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [Parameter(Mandatory = $true)][ValidateSet('DirectX', 'OpenGL')][string]$Backend,
    [switch]$Apply
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $GameRoot).Path
$conf = Join-Path $root 'conf.ini'
$originalBytes = [IO.File]::ReadAllBytes($conf)
$encoding = [Text.Encoding]::GetEncoding(28591)
$text = $encoding.GetString($originalBytes)
$newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
$changes = New-Object System.Collections.Generic.List[string]
function Set-IniSetting {
    param([string]$Section, [string]$Key, [string]$Value)
    $pattern = '(?ms)^\[' + [regex]::Escape($Section) + '\][^\r\n]*\r?\n.*?(?=^\[|\z)'
    $blocks = [regex]::Matches($script:text, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($blocks.Count -gt 1) { throw "Section dupliquee : $Section" }
    if ($blocks.Count -eq 0) {
        $script:text = $script:text.TrimEnd("`r", "`n") + $script:newline + "[$Section]" + $script:newline + "$Key=$Value" + $script:newline
        $changes.Add("$Section/$Key=$Value")
        return
    }
    $block = $blocks[0]
    $keyPattern = '(?mi)^\s*' + [regex]::Escape($Key) + '\s*=([^\r\n]*)'
    $matchesFound = [regex]::Matches($block.Value, $keyPattern)
    if ($matchesFound.Count -gt 1) { throw "Cle dupliquee : $Section/$Key" }
    if ($matchesFound.Count -eq 1 -and $matchesFound[0].Groups[1].Value.Trim() -eq $Value) { return }
    if ($matchesFound.Count -eq 1) {
        $updated = [regex]::Replace($block.Value, $keyPattern, "$Key=$Value")
    } else {
        $updated = $block.Value.TrimEnd("`r", "`n") + $script:newline + "$Key=$Value" + $script:newline
    }
    $script:text = $script:text.Substring(0, $block.Index) + $updated + $script:text.Substring($block.Index + $block.Length)
    $changes.Add("$Section/$Key=$Value")
}
if ($Backend -eq 'DirectX') {
    $wrapper = Join-Path $root 'dx8wrap.dll'
    if (-not (Test-Path -LiteralPath $wrapper) -or
        (Get-FileHash -LiteralPath $wrapper).Hash -ne 'A4DB066DAB59C6CF5AF1D7F01643FC83BB29D00FD1DCA177F6CAF99FFB7027FA') {
        throw 'Wrapper DirectX 4.09m original absent ou modifie ; profil non applique.'
    }
    Set-IniSetting 'GLPROVIDERS' 'DirectX' 'dx8wrap.dll'
    Set-IniSetting 'GLPROVIDER' 'GL' 'dx8wrap.dll'
    # Existing official 4.09m DirectX/Excellent values; keep OpenGL untouched.
    $values = [ordered]@{TexQual='3'; TexMipFilter='2'; HardwareShaders='0'; Forest='2'; LandGeom='2'; Water='2'; Effects='1'; TypeClouds='1'}
    foreach ($key in $values.Keys) { Set-IniSetting 'Render_DirectX' $key $values[$key] }
} else {
    Set-IniSetting 'GLPROVIDER' 'GL' 'Opengl32.dll'
    Set-IniSetting 'Render_OpenGL' 'TypeClouds' '1'
}
Set-IniSetting 'game' 'Typeclouds' '1'
$backup = $null
if ($Apply -and $changes.Count -gt 0) {
    if (@(Get-Process -Name il2fb -ErrorAction SilentlyContinue).Count -gt 0) { throw 'Fermer le jeu avant de changer de rendu.' }
    $beforeHash = (Get-FileHash -LiteralPath $conf).Hash
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($conf)) -cne [Convert]::ToBase64String($originalBytes)) {
        throw 'Configuration modifiee depuis sa lecture initiale.'
    }
    $backup = Join-Path $root ('conf.before-' + $Backend + '-' + [guid]::NewGuid().ToString('N') + '.ini')
    $temp = Join-Path $root ('conf.pending-' + [guid]::NewGuid().ToString('N') + '.ini')
    try {
        [IO.File]::WriteAllBytes($temp, $encoding.GetBytes($text))
        if ((Get-FileHash -LiteralPath $conf).Hash -ne $beforeHash) { throw 'Configuration modifiee pendant la preparation.' }
        [IO.File]::Replace($temp, $conf, $backup)
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp }
    }
}
[pscustomobject]@{Backend=$Backend; Applied=[bool]$Apply; Changes=@($changes); Backup=$backup; GameLaunched=$false}
