[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$launcherRoot = Split-Path -Parent $PSScriptRoot
$tool = Join-Path $launcherRoot 'tools\Read-IL2HotKeyCatalogue.ps1'
$fixtures = Join-Path $PSScriptRoot 'fixtures\hotkeys'
$disassemblies = @(
    (Join-Path $fixtures 'AircraftHotKeys.javap.txt'),
    (Join-Path $fixtures 'HookKeys.javap.txt'),
    (Join-Path $fixtures 'OrdersTree.javap.txt')
)

$json = & $tool `
    -DisassemblyPath $disassemblies `
    -ControlsPath (Join-Path $fixtures 'controls.properties') `
    -LocalizedControlsPath (Join-Path $fixtures 'controls_fr.properties') `
    -LocalizedControlsCodePage 65001 `
    -SettingsPath (Join-Path $fixtures 'settings.ini') | Out-String
$catalogue = $json | ConvertFrom-Json

function Require-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Environment,

        [Parameter(Mandatory)]
        [string]$Id
    )

    $matches = @($catalogue.commands | Where-Object {
        $_.environment -ceq $Environment -and $_.id -ceq $Id
    })
    if ($matches.Count -ne 1) {
        throw "Commande attendue absente ou dupliquee : $Environment/$Id"
    }
    return $matches[0]
}

if ($catalogue.summary.registrations -ne 7) {
    throw "Nombre de declarations inattendu : $($catalogue.summary.registrations)"
}

if ($catalogue.summary.commands -ne 9 -or $catalogue.summary.settingsOnlyCommands -ne 2) {
    throw 'La fusion des declarations et des commandes settings-only est incorrecte.'
}

$elevator = Require-Command -Environment 'pilot' -Id 'ElevatorUp'
if ($elevator.label -ne 'Elevator Up' -or
    $elevator.localizedLabel -ne 'Profondeur haut' -or
    -not $elevator.bound -or
    $elevator.registrationStatus -ne 'registered') {
    throw 'La commande pilote n est pas correctement cataloguee.'
}

$hidden = Require-Command -Environment 'pilot' -Id '$$$internal'
if ($hidden.visibility -ne 'internal') {
    throw 'Une commande interne est exposee comme commande publique.'
}

$axis = Require-Command -Environment 'move' -Id '-power'
if ($axis.bindingKind -ne 'axis' -or
    $axis.inputMinimum -ne -1 -or
    $axis.inputMaximum -ne 1 -or
    $axis.logicalMinimum -ne 0 -or
    $axis.logicalMaximum -ne 1.1 -or
    -not $axis.inverted -or
    -not $axis.bound) {
    throw 'L axe inverse n est pas correctement reconnu.'
}

$snap = Require-Command -Environment 'SnapView' -Id 'Snap_0_0'
$pan = Require-Command -Environment 'PanView' -Id 'PanReset'
if ($snap.sortKey -ne '01' -or $pan.sortKey -ne '01') {
    throw 'Les environnements explicites de HookKeys sont mal interpretes.'
}

$unknownMod = Require-Command -Environment 'pilot' -Id 'NEW_MOD_COMMAND'
$staleOrder = Require-Command -Environment 'orders' -Id 'order10'
if ($unknownMod.registrationStatus -ne 'settings-only' -or
    $staleOrder.registrationStatus -ne 'settings-only') {
    throw 'Les affectations absentes des classes ne sont pas signalees.'
}

if (($json -match '[A-Za-z]:\\') -or ($json -match '/Users/')) {
    throw 'Le catalogue divulgue un chemin absolu.'
}

[PSCustomObject]@{
    passed = $true
    registrations = $catalogue.summary.registrations
    commands = $catalogue.summary.commands
    settingsOnlyCommands = $catalogue.summary.settingsOnlyCommands
    internalCommands = $catalogue.summary.internalCommands
} | ConvertTo-Json -Depth 4
