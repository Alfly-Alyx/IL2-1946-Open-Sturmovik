[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$writer = Join-Path $launcherRoot 'tools\Set-IL2Configuration.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures\conf.ini'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("open-sturmovik-launcher-{0}" -f [Guid]::NewGuid().ToString('N'))
$configuration = Join-Path $testRoot 'conf.ini'
$changes = @(
    [ordered]@{ section = 'window'; key = 'width'; value = '1920' },
    [ordered]@{ section = 'window'; key = 'StencilBits'; value = '8' },
    [ordered]@{ section = 'sound'; key = 'SoundUse'; value = '0' },
    [ordered]@{ section = 'NET'; key = 'SkinDownload'; value = '1' }
) | ConvertTo-Json -Depth 4 -Compress

try {
    $null = New-Item -ItemType Directory -Path $testRoot
    Copy-Item -LiteralPath $fixture -Destination $configuration
    $beforeBytes = [IO.File]::ReadAllBytes($configuration)

    $preview = (& $writer -ConfigurationPath $configuration -ChangesJson $changes) | ConvertFrom-Json
    if ($preview.applied -or -not $preview.changed) {
        throw 'Le mode apercu ne produit pas le plan attendu.'
    }
    if (-not [Linq.Enumerable]::SequenceEqual($beforeBytes, [IO.File]::ReadAllBytes($configuration))) {
        throw 'Le mode apercu a modifie conf.ini.'
    }

    $result = (& $writer -ConfigurationPath $configuration -ChangesJson $changes -Apply) | ConvertFrom-Json
    if (-not $result.applied -or $result.afterSha256 -ne $result.plannedSha256) {
        throw 'L application transactionnelle a echoue.'
    }
    if (-not (Test-Path -LiteralPath $result.backup -PathType Leaf)) {
        throw 'La sauvegarde transactionnelle est absente.'
    }
    $updated = Get-Content -LiteralPath $configuration -Raw
    foreach ($expected in @(
        'width = 1920',
        'UnknownWindowKey=preserve-me',
        'StencilBits=8',
        'SoundUse=0',
        '[NET]',
        'SkinDownload=1',
        'CustomKey=preserve-me-too'
    )) {
        if (-not $updated.Contains($expected)) { throw "Valeur attendue absente : $expected" }
    }
    $backupBytes = [IO.File]::ReadAllBytes([string]$result.backup)
    if (-not [Linq.Enumerable]::SequenceEqual($beforeBytes, $backupBytes)) {
        throw 'La sauvegarde ne correspond pas au fichier original.'
    }

    [ordered]@{
        passed = $true
        operations = @($result.operations | Group-Object action | ForEach-Object {
            [ordered]@{ action = $_.Name; count = $_.Count }
        })
        backupVerified = $true
        unknownKeysPreserved = $true
    } | ConvertTo-Json -Depth 6
}
finally {
    $resolvedTemp = [IO.Path]::GetFullPath($testRoot)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (($resolvedTemp + '\').StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $resolvedTemp)) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force
    }
}
