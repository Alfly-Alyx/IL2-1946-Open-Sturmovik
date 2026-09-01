[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$collector = Join-Path $launcherRoot 'tools\Convert-IL2LogToEvents.ps1'
$anonymizer = Join-Path $launcherRoot 'tools\New-AnonymizedErrorReport.ps1'
$validator = Join-Path $launcherRoot 'tools\Test-ErrorReport.ps1'
$fixture = Join-Path $PSScriptRoot 'fixtures\il2-log-sample.lst'
$gameRoot = 'C:\Users\SensitiveUser\Games\Open Sturmovik'

$collection = (& $collector -LogPath $fixture) | ConvertFrom-Json
if ($collection.eventCount -ne 9) {
    throw "Nombre d evenements inattendu : $($collection.eventCount)"
}
if ($collection.occurrenceCount -ne 11) {
    throw "Nombre d occurrences inattendu : $($collection.occurrenceCount)"
}

$sound = @($collection.events | Where-Object errorCode -eq 'SOUND_PRESET_LOAD_FAILED')
if ($sound.Count -ne 1 -or $sound[0].occurrences -ne 2) {
    throw 'Le regroupement des erreurs sonores est incorrect.'
}
$texture = @($collection.events | Where-Object eventType -eq 'missing-texture')
if ($texture.Count -ne 1 -or $texture[0].resourcePath -ne '3DO/Plane/Test/skin.tga') {
    throw 'La texture manquante n est pas reconnue.'
}
$java = @($collection.events | Where-Object eventType -eq 'java-exception')
if ($java.Count -ne 1 -or $java[0].occurrences -ne 2 -or $java[0].javaStack.Count -ne 2) {
    throw 'L exception Java ou sa pile n est pas correctement regroupee.'
}

$validatedReports = 0
foreach ($event in $collection.events) {
    $eventJson = $event | ConvertTo-Json -Depth 12 -Compress
    $reportJson = & $anonymizer `
        -InputJson $eventJson `
        -GameRoot $gameRoot `
        -ManifestSha256 ('B' * 64) `
        -SessionId ([Guid]'22222222-2222-2222-2222-222222222222')
    $validation = (& $validator -ReportJson $reportJson -GameRoot $gameRoot) | ConvertFrom-Json
    if (-not $validation.valid) {
        throw "Rapport invalide pour $($event.errorCode) : $($validation.errors -join '; ')"
    }
    $validatedReports++
}

[ordered]@{
    passed = $true
    uniqueEvents = [int]$collection.eventCount
    occurrences = [int]$collection.occurrenceCount
    validatedReports = $validatedReports
    categories = @($collection.events.eventType | Sort-Object -Unique)
} | ConvertTo-Json -Depth 6
