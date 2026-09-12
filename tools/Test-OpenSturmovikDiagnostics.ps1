[CmdletBinding()]
param([string]$TestRoot)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$createdRoot = $false
if ([string]::IsNullOrWhiteSpace($TestRoot)) {
    $TestRoot = Join-Path ([IO.Path]::GetTempPath()) ('open-sturmovik-diagnostics-test-' + [Guid]::NewGuid().ToString('N'))
    $createdRoot = $true
}
$resolvedTest = [IO.Path]::GetFullPath($TestRoot).TrimEnd('\')
$safeTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if ($createdRoot -and -not $resolvedTest.StartsWith($safeTemp, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Le dossier de test n'est pas sous le dossier temporaire : $resolvedTest"
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ECHEC : $Message" }
}

$game = Join-Path $resolvedTest 'game'
$state = Join-Path $resolvedTest 'state'
$toolCopy = Join-Path $game 'tools'
$manifestRoot = Join-Path $game 'manifests'
try {
    New-Item -ItemType Directory -Path $game,$state,$toolCopy,$manifestRoot -Force | Out-Null
    foreach ($name in @(
        'Send-OpenSturmovikDiagnostic.ps1',
        'Collect-OpenSturmovikDiagnostic.ps1',
        'Watch-OpenSturmovikDiagnostics.ps1',
        'Install-OpenSturmovikDiagnostics.ps1',
        'Read-OpenSturmovikMinidump.ps1',
        'Set-IL2StartupDiagnostics.ps1'
    )) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $toolCopy $name)
    }

    [IO.File]::WriteAllBytes((Join-Path $game 'il2fb.exe'), [Text.Encoding]::ASCII.GetBytes('synthetic-il2-executable'))
    [IO.File]::WriteAllBytes((Join-Path $game 'files.SFS'), [Text.Encoding]::ASCII.GetBytes('synthetic-files-sfs'))
    [IO.File]::WriteAllBytes((Join-Path $game 'wrapper.dll'), [Text.Encoding]::ASCII.GetBytes('synthetic-wrapper'))
    $presentTexture = Join-Path $game 'Files\3do\Test\present.tga'
    New-Item -ItemType Directory -Path (Split-Path -Parent $presentTexture) -Force | Out-Null
    [IO.File]::WriteAllBytes($presentTexture, [Text.Encoding]::ASCII.GetBytes('synthetic-texture'))
    $conf = @"
[game]
eventlog=eventlog.lst
eventlogkeep=1
[window]
width=1024
height=768
[Console]
LOG=1
LOGTIME=1
LOGFILE=log.lst
LOGKEEP=1
LOGDEBUG=1
"@
    [IO.File]::WriteAllText((Join-Path $game 'conf.ini'), $conf, [Text.Encoding]::ASCII)

    $exeHash = (Get-FileHash -LiteralPath (Join-Path $game 'il2fb.exe') -Algorithm SHA256).Hash
    $filesHash = (Get-FileHash -LiteralPath (Join-Path $game 'files.SFS') -Algorithm SHA256).Hash
    $manifest = [ordered]@{
        profiles = @([ordered]@{ number = 8; version = '4.09m'; mode = 'open-sturmovik-no-6dof'; exeSha256 = $exeHash; filesSha256 = $filesHash })
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $manifestRoot 'switcher-v1.15.json') -Encoding UTF8

    $logPath = Join-Path $game 'log.lst'
    [IO.File]::WriteAllText($logPath, "0: demarrage normal`r`n", [Text.Encoding]::Default)
    $offset = (Get-Item -LiteralPath $logPath).Length
    $privatePath = Join-Path $env:USERPROFILE 'Secret\texture.tga'
    $delta = @(
        '1: contexte avant',
        "2: ERROR: FileNotFoundException: $privatePath",
        '3: user@example.org 192.168.10.25',
        '4: token=secret-value error: authentication failed',
        '5: contexte apres',
        '6: ERROR: cannot load texture Files/3do/Test/present.tga'
    ) -join "`r`n"
    [IO.File]::AppendAllText($logPath, $delta + "`r`n", [Text.Encoding]::Default)

    $sessionPath = Join-Path $state 'session-error.json'
    $now = [DateTime]::UtcNow
    $session = [ordered]@{
        pid = 4242
        started_utc = $now.AddSeconds(-5).ToString('O')
        ended_utc = $now.ToString('O')
        exit_code = 0
        max_unresponsive_seconds = 0
        log_offsets = [ordered]@{ 'log.lst' = $offset }
        dump_files = @()
    }
    $session | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $sessionPath -Encoding UTF8

    $collector = Join-Path $toolCopy 'Collect-OpenSturmovikDiagnostic.ps1'
    $result = & $collector -GameRoot $game -SessionPath $sessionPath -StateRoot $state -QueueOnly
    Assert-True ($result.Status -eq 'QUEUED') 'le rapport synthetique doit etre mis en file'
    Assert-True ($result.Findings -ge 2) 'les erreurs de fichier et authentification doivent etre detectees'
    Assert-True (Test-Path -LiteralPath $result.Report -PathType Leaf) 'le JSON du rapport doit exister'
    $rawReport = Get-Content -LiteralPath $result.Report -Raw
    Assert-True ($rawReport -notmatch [regex]::Escape($env:USERPROFILE)) 'le profil utilisateur doit etre expurge'
    Assert-True ($rawReport -notmatch 'user@example\.org') 'le courriel doit etre expurge'
    Assert-True ($rawReport -notmatch '192\.168\.10\.25') 'adresse IP doit etre expurgee'
    Assert-True ($rawReport -notmatch 'secret-value') 'le secret doit etre expurge'
    Assert-True ($rawReport -match 'FileNotFoundException') 'exception de fichier doit rester diagnostiquable'
    $parsed = $rawReport | ConvertFrom-Json
    Assert-True ($parsed.profile.number -eq 8) 'le profil actif doit etre identifie par ses empreintes'
    Assert-True (@($parsed.affected_resources | Where-Object { $_.path -match 'texture\.tga' }).Count -ge 1) 'la ressource fautive doit etre extraite dans une liste structuree'
    $presentResource = @($parsed.affected_resources | Where-Object { $_.path -ieq 'Files/3do/Test/present.tga' } | Select-Object -First 1)
    Assert-True ($presentResource.Count -eq 1) 'le chemin precis de la ressource doit etre conserve'
    Assert-True (@($parsed.affected_resources | Where-Object { $_.path -ieq 'present.tga' }).Count -eq 0) 'le nom seul ne doit pas dupliquer un chemin deja extrait'
    Assert-True ($presentResource[0].loose_state -eq 'present comme fichier libre') 'la presence du fichier libre doit etre controlee'
    Assert-True ($presentResource[0].loose_sha256 -eq (Get-FileHash -LiteralPath $presentTexture -Algorithm SHA256).Hash) 'empreinte du fichier cite doit etre conservee'
    Assert-True ($presentResource[0].line -gt 0) 'la ligne du journal doit etre conservee'

    $sender = Join-Path $toolCopy 'Send-OpenSturmovikDiagnostic.ps1'
    $preview = & $sender -ReportPath $result.Report -StateRoot $state -DryRun
    Assert-True ($preview.Status -eq 'DRY_RUN') 'le rendu GitHub doit fonctionner hors ligne'
    Assert-True (Test-Path -LiteralPath $preview.Preview -PathType Leaf) 'la previsualisation Markdown doit exister'
    $previewText = Get-Content -LiteralPath $preview.Preview -Raw
    Assert-True ($previewText -match 'Anomalies detectees') 'la previsualisation doit contenir les anomalies'
    Assert-True ($previewText -match 'Ressources concernees') 'la previsualisation doit afficher la liste des fichiers fautifs'
    Assert-True ($previewText -match 'present comme fichier libre') 'la previsualisation doit afficher etat du fichier cite'
    Assert-True ($previewText -match 'Extrait') 'la previsualisation doit contenir le contexte des journaux'

    $minimalDump = Join-Path $state 'minimal.dmp'
    $minimalBytes = New-Object byte[] 32
    [BitConverter]::GetBytes([uint32]0x504D444D).CopyTo($minimalBytes, 0)
    [BitConverter]::GetBytes([uint32]0x0000A793).CopyTo($minimalBytes, 4)
    [BitConverter]::GetBytes([uint32]0).CopyTo($minimalBytes, 8)
    [BitConverter]::GetBytes([uint32]32).CopyTo($minimalBytes, 12)
    [IO.File]::WriteAllBytes($minimalDump, $minimalBytes)
    $dumpReader = Join-Path $toolCopy 'Read-OpenSturmovikMinidump.ps1'
    $dumpResult = & $dumpReader -DumpPath $minimalDump
    Assert-True ($dumpResult.valid -and $dumpResult.format -eq 'MINIDUMP') 'le lecteur doit reconnaitre un en-tete minidump valide'

    $watchGame = Join-Path $resolvedTest 'watch-game'
    $watchTools = Join-Path $watchGame 'tools'
    $watchState = Join-Path $resolvedTest 'watch-state'
    New-Item -ItemType Directory -Path $watchGame,$watchTools,$watchState -Force | Out-Null
    foreach ($name in @('Watch-OpenSturmovikDiagnostics.ps1','Collect-OpenSturmovikDiagnostic.ps1','Send-OpenSturmovikDiagnostic.ps1','Read-OpenSturmovikMinidump.ps1')) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $watchTools $name)
    }
    [IO.File]::WriteAllText((Join-Path $watchGame 'log.lst'), "demarrage precedent`r`n", [Text.Encoding]::Default)
    [IO.File]::WriteAllBytes((Join-Path $watchGame 'files.SFS'), [Text.Encoding]::ASCII.GetBytes('watch-files-sfs'))
    $fakeSource = @'
using System;
using System.IO;
using System.Threading;
public static class Program {
    public static int Main() {
        Thread.Sleep(4000);
        File.AppendAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "log.lst"), "ERROR: can't load texture 3DO/Test/missing.tga\r\n");
        Thread.Sleep(500);
        return 0;
    }
}
'@
    $fakeExe = Join-Path $watchGame 'il2fb.exe'
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        Add-Type -TypeDefinition $fakeSource -OutputAssembly $fakeExe -OutputType ConsoleApplication
    }
    else {
        $fakeSourcePath = Join-Path $watchGame 'SyntheticIl2.cs'
        [IO.File]::WriteAllText($fakeSourcePath, $fakeSource, [Text.UTF8Encoding]::new($false))
        $escapedSourcePath = $fakeSourcePath.Replace("'", "''")
        $escapedFakeExe = $fakeExe.Replace("'", "''")
        $compileCommand = "Add-Type -Path '$escapedSourcePath' -OutputAssembly '$escapedFakeExe' -OutputType ConsoleApplication"
        $compileOutput = @(& $windowsPowerShell -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $compileCommand 2>&1)
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $fakeExe -PathType Leaf)) {
            throw "ECHEC : compilation du faux jeu impossible avec Windows PowerShell : $($compileOutput -join ' ')"
        }
    }
    $watchArguments = @(
        '-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass',
        '-File',('"' + (Join-Path $watchTools 'Watch-OpenSturmovikDiagnostics.ps1') + '"'),
        '-GameRoot',('"' + $watchGame + '"'),
        '-StateRoot',('"' + $watchState + '"'),
        '-PollSeconds','1','-Once','-QueueOnly'
    )
    $watchPowerShell = if ($PSVersionTable.PSEdition -eq 'Core') {
        (Get-Process -Id $PID).Path
    }
    else {
        $windowsPowerShell
    }
    $watchProcess = Start-Process -FilePath $watchPowerShell -ArgumentList $watchArguments -WindowStyle Hidden -PassThru
    $watcherLogPath = Join-Path $watchState 'watcher.log'
    $watcherDeadline = [DateTime]::UtcNow.AddSeconds(10)
    $watcherReady = $false
    while ([DateTime]::UtcNow -lt $watcherDeadline -and -not $watchProcess.HasExited) {
        if ((Test-Path -LiteralPath $watcherLogPath -PathType Leaf) -and
            (Select-String -LiteralPath $watcherLogPath -Pattern 'watcher_started' -Quiet)) {
            $watcherReady = $true
            break
        }
        Start-Sleep -Milliseconds 100
        $watchProcess.Refresh()
    }
    Assert-True $watcherReady 'le moniteur synthetique doit confirmer son demarrage'
    $fakeProcess = Start-Process -FilePath $fakeExe -WorkingDirectory $watchGame -PassThru
    $fakeProcess.WaitForExit()
    if (-not $watchProcess.WaitForExit(20000)) {
        Stop-Process -Id $watchProcess.Id -Force -ErrorAction SilentlyContinue
        throw 'ECHEC : le moniteur synthetique ne se termine pas'
    }
    Assert-True ($watchProcess.ExitCode -eq 0) 'le moniteur synthetique doit se terminer normalement'
    $watchReports = @(Get-ChildItem -LiteralPath (Join-Path $watchState 'Queue') -File -Filter '*.json' -ErrorAction SilentlyContinue)
    Assert-True ($watchReports.Count -eq 1) 'le moniteur doit produire exactement un rapport pour le faux jeu'
    $watchReport = Get-Content -LiteralPath $watchReports[0].FullName -Raw | ConvertFrom-Json
    Assert-True (@($watchReport.findings | Where-Object { $_.message -match 'missing\.tga' }).Count -eq 1) 'le moniteur doit conserver erreur texture du faux jeu'

    $cleanOffset = (Get-Item -LiteralPath $logPath).Length
    $cleanSessionPath = Join-Path $state 'session-clean.json'
    $cleanSession = [ordered]@{
        pid = 4243
        started_utc = $now.ToString('O')
        ended_utc = $now.AddSeconds(2).ToString('O')
        exit_code = 0
        max_unresponsive_seconds = 0
        log_offsets = [ordered]@{ 'log.lst' = $cleanOffset }
        dump_files = @()
    }
    $cleanSession | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $cleanSessionPath -Encoding UTF8
    $cleanResult = & $collector -GameRoot $game -SessionPath $cleanSessionPath -StateRoot $state -QueueOnly
    Assert-True ($cleanResult.Status -eq 'CLEAN') 'une fermeture normale sans nouveau message ne doit pas creer de ticket'

    $installer = Join-Path $toolCopy 'Install-OpenSturmovikDiagnostics.ps1'
    $installSimulation = & $installer -InstallationRoot $game -StateRoot (Join-Path $resolvedTest 'install-state') -WhatIf
    Assert-True ($installSimulation.Status -eq 'INSTALL_SIMULATED') 'installation doit prendre en charge WhatIf sans toucher au registre'

    [pscustomobject]@{
        Status = 'PASS'
        Root = $resolvedTest
        Findings = [int]$result.Findings
        Signature = [string]$result.Signature
        Profile = [string]$parsed.profile.label
        Redaction = 'PASS'
        GitHubPreview = $preview.Preview
        CleanRun = 'PASS'
        InstallerWhatIf = 'PASS'
        MinidumpReader = 'PASS'
        ProcessWatcher = 'PASS'
    }
}
finally {
    if ($createdRoot -and (Test-Path -LiteralPath $resolvedTest -PathType Container)) {
        $verified = [IO.Path]::GetFullPath($resolvedTest)
        if ($verified.StartsWith($safeTemp, [StringComparison]::OrdinalIgnoreCase) -and $verified -like '*open-sturmovik-diagnostics-test-*') {
            Remove-Item -LiteralPath $verified -Recurse -Force
        }
    }
}
