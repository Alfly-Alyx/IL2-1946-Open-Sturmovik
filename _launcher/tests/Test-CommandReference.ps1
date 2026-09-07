[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$cataloguePath = Join-Path $launcherRoot 'manifests/hotkeys-4.09m-modified.json'
$setupContractPath = Join-Path $launcherRoot 'manifests/il2setup-1.0.0.2.json'
$setupCataloguePath = Join-Path $launcherRoot 'manifests/il2setup-catalogue-1.0.0.2.json'
$generatorPath = Join-Path $launcherRoot 'tools/New-IL2CommandReference.ps1'
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ("open-sturmovik-command-reference-{0}.md" -f ([guid]::NewGuid().ToString('N')))

try {
    $generatorOutput = & $generatorPath `
        -HotKeyCataloguePath $cataloguePath `
        -SetupContractPath $setupContractPath `
        -SetupCataloguePath $setupCataloguePath `
        -OutputPath $temporaryPath

    $result = (($generatorOutput | Out-String) | ConvertFrom-Json)
    $content = Get-Content -LiteralPath $temporaryPath -Raw
    $catalogue = Get-Content -LiteralPath $cataloguePath -Raw | ConvertFrom-Json

    $checks = [ordered]@{
        outputExists = Test-Path -LiteralPath $temporaryPath -PathType Leaf
        commandCountMatches = $result.commandCount -eq $catalogue.summary.commands
        documentsPowerRange = $content.Contains('| `power` | Puissance | -1 | 1 | 0 | 1.1 | non |')
        documentsSettingsOnlyCommand = $content.Contains('`order17`')
        documentsObservedLimits = $content.Contains('minimum/maximum observé dans ces profils')
        excludesPersonalPaths = -not $content.Contains('C:\Users\')
        validUtf8Text = -not $content.Contains([char]0xFFFD)
    }

    $failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value })
    if ($failed.Count -gt 0) {
        throw "Echec de la reference generee : $($failed.Name -join ', ')"
    }

    [pscustomobject]@{
        passed = $true
        commandCount = $result.commandCount
        profileCount = $result.profileCount
        profileKeyCount = $result.profileKeyCount
        checks = $checks
    } | ConvertTo-Json -Depth 4
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
