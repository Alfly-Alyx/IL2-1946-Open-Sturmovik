[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'WARN', 'FAIL')][string]$Status,
        [Parameter(Mandatory = $true)][string]$Details
    )
    $script:Results.Add([pscustomobject]@{
        Name = $Name
        Status = $Status
        Details = $Details
    }) | Out-Null
}

$root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path

$branch = (& git -C $root branch --show-current).Trim()
if ($LASTEXITCODE -eq 0 -and $branch -eq 'v1.15') {
    Add-Result 'Branche de travail' PASS 'v1.15'
}
else {
    Add-Result 'Branche de travail' FAIL "Branche attendue v1.15, branche courante : $branch"
}

$contentValidator = Join-Path $root 'tools\Test-OpenSturmovikContent.ps1'
$contentOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $contentValidator -ProjectRoot $root -ContentRoot $root -ExcludeNuclear 2>&1)
$contentExitCode = $LASTEXITCODE
$contentSummary = [string](@($contentOutput | Where-Object { [string]$_ -match '^Resultat :' } | Select-Object -Last 1))
if ($contentExitCode -eq 0) {
    Add-Result 'Contenu v1.15' PASS $contentSummary
}
else {
    Add-Result 'Contenu v1.15' FAIL ((@($contentOutput | Select-Object -Last 5) -join ' ') + " (code $contentExitCode)")
}

try {
    $utilityResult = & (Join-Path $root 'tools\Test-OpenSturmovikUtilityShortcuts.ps1') -RepositoryRoot $root
    if ($utilityResult.Result -eq 'PASS' -and $utilityResult.ShortcutCount -eq 8 -and -not $utilityResult.DesktopModified) {
        Add-Result 'Raccourcis v1.15' PASS 'Sept utilitaires et le switcher valides ; aucun Bureau modifie pendant le controle.'
    }
    else {
        Add-Result 'Raccourcis v1.15' FAIL 'Le controle des huit raccourcis ne retourne pas le resultat attendu.'
    }
}
catch {
    Add-Result 'Raccourcis v1.15' FAIL $_.Exception.Message
}

try {
    $diagnosticResult = & (Join-Path $root 'tools\Test-OpenSturmovikDiagnostics.ps1')
    if ($diagnosticResult.Status -eq 'PASS' -and
        $diagnosticResult.Redaction -eq 'PASS' -and
        $diagnosticResult.CleanRun -eq 'PASS' -and
        $diagnosticResult.MinidumpReader -eq 'PASS' -and
        $diagnosticResult.ProcessWatcher -eq 'PASS') {
        Add-Result 'Diagnostic automatique GitHub' PASS 'Fichiers fautifs, contexte, redaction, minidump, fermeture saine et surveillance il2fb valides hors jeu.'
    }
    else {
        Add-Result 'Diagnostic automatique GitHub' FAIL 'Le controle du collecteur ne retourne pas tous les resultats attendus.'
    }
}
catch {
    Add-Result 'Diagnostic automatique GitHub' FAIL $_.Exception.Message
}

try {
    $switcherResult = & (Join-Path $root 'tools\Test-OpenSturmovikSwitcher.ps1') -RepositoryRoot $root
    if ($switcherResult.Result -eq 'PASS' -and $switcherResult.ProfileCount -eq 9) {
        Add-Result 'Switcher 4.08m/4.09b/4.09m' PASS 'Neuf profils, deux HUD, marquage Open Sturmovik et sources verifies hors jeu.'
    }
    else {
        Add-Result 'Switcher 4.08m/4.09b/4.09m' FAIL 'Le controle du switcher ne retourne pas le resultat attendu.'
    }
}
catch {
    Add-Result 'Switcher 4.08m/4.09b/4.09m' FAIL $_.Exception.Message
}

$aocPath = Join-Path $root 'manifests\aoc-v1.15.json'
if (-not (Test-Path -LiteralPath $aocPath -PathType Leaf)) {
    Add-Result 'Choix AOC 4.09m' FAIL 'Manifeste AOC absent.'
}
else {
    $aoc = Get-Content -LiteralPath $aocPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lines = @($aoc.versions | ForEach-Object { [string]$_.line })
    $v1 = @($aoc.versions | Where-Object line -eq 'v1')
    if ($aoc.release -ne '1.15' -or $aoc.gameVersion -ne '4.09m' -or
        (@($lines | Sort-Object) -join ',') -ne 'v1,v2,v3' -or
        $v1.Count -ne 1 -or $v1[0].functionalState -notmatch '^selected-' -or
        $aoc.currentSelection -ne 'v1-1a-hsfx4-409m-zuti-merged') {
        Add-Result 'Choix AOC 4.09m' FAIL 'La matrice V1/V2/V3 est incoherente.'
    }
    else {
        $classErrors = @()
        foreach ($entry in @($aoc.integration.outputClasses)) {
            $classPath = Join-Path $root ([string]$entry.path)
            if (-not (Test-Path -LiteralPath $classPath -PathType Leaf)) {
                $classErrors += "absente: $($entry.path)"
                continue
            }
            $item = Get-Item -LiteralPath $classPath
            $hash = (Get-FileHash -LiteralPath $classPath -Algorithm SHA256).Hash
            $bytes = [IO.File]::ReadAllBytes($classPath)
            $major = ($bytes[6] -shl 8) -bor $bytes[7]
            if ($item.Length -ne [long]$entry.length -or $hash -ne [string]$entry.sha256 -or
                $major -ne [int]$entry.major -or $major -gt 47) {
                $classErrors += "incoherente: $($entry.path)"
            }
        }

        $profileRoot = Join-Path $root ([string]$aoc.recoveredPayload.profiles.path)
        $profiles = @(Get-ChildItem -LiteralPath $profileRoot -File -ErrorAction SilentlyContinue)
        $profileBytes = ($profiles | Measure-Object Length -Sum).Sum
        [string[]]$profileNames = @($profiles | ForEach-Object Name)
        [Array]::Sort($profileNames, [StringComparer]::OrdinalIgnoreCase)
        $inventoryLines = @()
        foreach ($profileName in $profileNames) {
            $profilePath = Join-Path $profileRoot $profileName
            $profileHash = (Get-FileHash -LiteralPath $profilePath -Algorithm SHA256).Hash.ToLowerInvariant()
            $inventoryLines += ($profileName.ToLowerInvariant() + ' ' + $profileHash)
        }
        $inventoryText = ($inventoryLines -join "`n") + "`n"
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $inventoryBytes = [Text.Encoding]::UTF8.GetBytes($inventoryText)
            $inventoryDigest = ([BitConverter]::ToString($sha.ComputeHash($inventoryBytes))).Replace('-', '')
        }
        finally {
            $sha.Dispose()
        }
        $profileGood = $profiles.Count -eq [int]$aoc.recoveredPayload.profiles.count -and
            $profileBytes -eq [long]$aoc.recoveredPayload.profiles.bytes -and
            $inventoryDigest -eq [string]$aoc.recoveredPayload.profiles.inventoryDigest

        if ($classErrors.Count -ne 0 -or -not $profileGood) {
            Add-Result 'Choix AOC 4.09m' FAIL ((@($classErrors) + @(
                "profils=$($profiles.Count), octets=$profileBytes, digest=$inventoryDigest"
            )) -join '; ')
        }
        else {
            Add-Result 'Choix AOC 4.09m' PASS 'V1/1a HSFX 4.0 selectionne : trois classes AOC+Zuti et 266 profils distribues verifies ; Bf-109G-6 Early sur Defaut.txt.'
        }
    }
}

$campaignPath = Join-Path $root 'docs\CAMPAGNE_FINALE_V1.15.md'
if (Test-Path -LiteralPath $campaignPath -PathType Leaf) {
    Add-Result 'Plan de campagne finale' PASS 'Protocole present ; ce controle hors jeu ne qualifie pas les essais utilisateur.'
}
else {
    Add-Result 'Plan de campagne finale' FAIL 'Cahier de campagne absent.'
}

$script:Results | Format-Table -AutoSize -Wrap
$pass = @($script:Results | Where-Object Status -eq 'PASS').Count
$warn = @($script:Results | Where-Object Status -eq 'WARN').Count
$fail = @($script:Results | Where-Object Status -eq 'FAIL').Count
Write-Host ("Preparation hors jeu : {0} PASS, {1} WARN, {2} FAIL" -f $pass, $warn, $fail)
Write-Host 'Aucun executable IL-2 n a ete lance et ce controle n a modifie ni la copie de test ni le Bureau.'

if ($fail -gt 0) { exit 1 }
exit 0
