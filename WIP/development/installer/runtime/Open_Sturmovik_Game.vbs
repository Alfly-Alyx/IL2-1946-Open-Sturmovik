Option Explicit

Dim fileSystem
Dim shell
Dim scriptFolder
Dim gameRoot
Dim powerShellExe
Dim updater
Dim command

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptFolder = fileSystem.GetParentFolderName(WScript.ScriptFullName)
gameRoot = fileSystem.GetParentFolderName(scriptFolder)
powerShellExe = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
updater = scriptFolder & "\Set-OpenSturmovikNativeResolution.ps1"

command = Quote(powerShellExe) & _
    " -NoProfile -NonInteractive -ExecutionPolicy Bypass -File " & _
    Quote(updater) & " -GameRoot " & Quote(gameRoot) & " -Launch"

shell.Run command, 0, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function