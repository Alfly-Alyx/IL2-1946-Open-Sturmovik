[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$LogPath,
    [string]$ConfPath,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-IniValue {
    param([string]$Path, [string]$Section, [string]$Key)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $inside = $false
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[(.+)\]\s*$') {
            $inside = $matches[1] -ieq $Section
            continue
        }
        if ($inside -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*?)\s*$')) {
            return $matches[1]
        }
    }
    return $null
}

function Convert-ToNullableInt {
    param([AllowNull()][string]$Value)
    $parsed = 0
    if ($null -ne $Value -and [int]::TryParse($Value, [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function Get-LoggedValue {
    param([string[]]$Lines, [string]$Label)
    foreach ($line in $Lines) {
        if ($line -match ('\b' + [regex]::Escape($Label) + ':\s*(.*?)\s*$')) {
            return $matches[1]
        }
    }
    return $null
}

$resolvedLog = (Resolve-Path -LiteralPath $LogPath -ErrorAction Stop).Path
$resolvedConf = if ($ConfPath -and (Test-Path -LiteralPath $ConfPath -PathType Leaf)) {
    (Resolve-Path -LiteralPath $ConfPath).Path
}
else {
    $null
}
$lines = [IO.File]::ReadAllLines($resolvedLog)

$extensions = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($line in $lines) {
    $extensionText = $null
    if ($line -match '\]\s+Extensions:\s*(.*)$') {
        $extensionText = $matches[1]
    }
    elseif ($line -match '\[x\].*?(GL_[A-Za-z0-9_]+)') {
        $extensionText = $matches[1]
    }
    if (-not $extensionText) {
        continue
    }
    foreach ($match in [regex]::Matches($extensionText, '\bGL_[A-Za-z0-9_]+\b')) {
        $extensions.Add($match.Value) | Out-Null
    }
}

$perfectWarnings = @(
    @(
        foreach ($line in $lines) {
            if ($line -match "WARNING:\s*('Perfect' Mode.*?)\s*$") {
                $matches[1]
            }
        }
    ) | Select-Object -Unique
)

$config = [ordered]@{}
foreach ($key in @(
    'TexFlags.TexEnvCombine4NV',
    'TexFlags.DepthClampNV',
    'TexFlags.TextureShaderNV',
    'HardwareShaders',
    'Forest',
    'LandShading',
    'LandDetails',
    'LandGeom',
    'Water'
)) {
    $config[$key] = Get-IniValue -Path $resolvedConf -Section 'Render_OpenGL' -Key $key
}

$hardwareShaders = Convert-ToNullableInt $config.HardwareShaders
$forest = Convert-ToNullableInt $config.Forest
$landGeom = Convert-ToNullableInt $config.LandGeom
$water = Convert-ToNullableInt $config.Water
$textureShaderNv = Convert-ToNullableInt $config.'TexFlags.TextureShaderNV'
$combine4Nv = Convert-ToNullableInt $config.'TexFlags.TexEnvCombine4NV'
$depthClampNv = Convert-ToNullableInt $config.'TexFlags.DepthClampNV'

$perfectRequested = (
    $hardwareShaders -eq 1 -or
    $forest -ge 3 -or
    $landGeom -ge 3 -or
    $textureShaderNv -eq 1 -or
    $combine4Nv -eq 1 -or
    $depthClampNv -eq 1 -or
    $water -ge 3
)
$safeProfile = (
    $null -ne $hardwareShaders -and $hardwareShaders -eq 0 -and
    $null -ne $forest -and $forest -le 2 -and
    $null -ne $landGeom -and $landGeom -le 2 -and
    $null -ne $textureShaderNv -and $textureShaderNv -eq 0 -and
    $null -ne $combine4Nv -and $combine4Nv -eq 0 -and
    $null -ne $depthClampNv -and $depthClampNv -eq 0 -and
    $null -ne $water -and $water -le 2
)

$pixelWarning = "'Perfect' Mode required pixels shaders"
$unsupportedWarning = "'Perfect' Mode is not supported for this combination of hardware and drivers."
$onlyLegacyPixelRejection = (
    $perfectWarnings.Count -eq 2 -and
    $perfectWarnings -contains $pixelWarning -and
    $perfectWarnings -contains $unsupportedWarning
)

$vendor = Get-LoggedValue -Lines $lines -Label 'Vendor'
$renderer = Get-LoggedValue -Lines $lines -Label 'Render'
$version = Get-LoggedValue -Lines $lines -Label 'Version'
$provider = Get-LoggedValue -Lines $lines -Label 'OpenGL provider'
$modernShaderPath = $extensions.Contains('GL_ARB_vertex_program') -and $extensions.Contains('GL_ARB_fragment_program')
$legacyPixelPath = $extensions.Contains('GL_NV_texture_shader') -or $extensions.Contains('GL_ATI_fragment_shader')

$classification = 'compatible'
$severity = 'info'
$recommendation = 'Conserver le profil courant et valider visuellement le rendu.'
if ($perfectWarnings.Count -gt 0) {
    if ($perfectRequested) {
        $classification = 'unsupported-perfect-request'
        $severity = 'error'
        $recommendation = 'Revenir au profil OpenGL natif securise ou selectionner un wrapper x86 valide avant de demander Perfect.'
    }
    elseif ($onlyLegacyPixelRejection -and $safeProfile -and $vendor -notmatch '(?i)nvidia') {
        $classification = 'expected-legacy-capability-notice'
        $severity = 'info'
        $recommendation = 'Aucune correction conf.ini n est requise. Le moteur 4.09m refuse seulement son ancien chemin Perfect NVIDIA ; Excellent reste actif.'
    }
    else {
        $classification = 'graphics-capability-warning'
        $severity = 'warning'
        $recommendation = 'Verifier le profil, le pilote 32 bits et les extensions du backend avant un essai en vol.'
    }
}

$result = [pscustomobject][ordered]@{
    log_path = $resolvedLog
    conf_path = $resolvedConf
    provider = $provider
    vendor = $vendor
    renderer = $renderer
    version = $version
    classification = $classification
    severity = $severity
    perfect_requested_by_profile = $perfectRequested
    safe_native_profile = $safeProfile
    perfect_warnings = @($perfectWarnings)
    legacy_pixel_shader_path = $legacyPixelPath
    modern_arb_shader_path = $modernShaderPath
    relevant_extensions = [ordered]@{
        GL_NV_texture_shader = $extensions.Contains('GL_NV_texture_shader')
        GL_ATI_fragment_shader = $extensions.Contains('GL_ATI_fragment_shader')
        GL_ARB_vertex_program = $extensions.Contains('GL_ARB_vertex_program')
        GL_ARB_fragment_program = $extensions.Contains('GL_ARB_fragment_program')
    }
    render_opengl = $config
    recommendation = $recommendation
}

if ($OutputPath) {
    $parent = Split-Path -Parent ([IO.Path]::GetFullPath($OutputPath))
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}

$result
