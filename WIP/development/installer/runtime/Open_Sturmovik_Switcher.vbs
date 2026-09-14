Option Explicit

Dim fileSystem
Dim shell
Dim scriptFolder
Dim gameRoot
Dim powerShellExe
Dim updater
Dim updateCommand
Dim switcher

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

scriptFolder = fileSystem.GetParentFolderName(WScript.ScriptFullName)
gameRoot = fileSystem.GetParentFolderName(scriptFolder)
powerShellExe = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
updater = scriptFolder & "\Set-OpenSturmovikNativeResolution.ps1"
switcher = gameRoot & "\Open_Sturmovik_Switcher.bat"

updateCommand = Quote(powerShellExe) & _
    " -NoProfile -NonInteractive -ExecutionPolicy Bypass -File " & _
    Quote(updater) & " -GameRoot " & Quote(gameRoot)
shell.Run updateCommand, 0, True

shell.Run "%ComSpec% /D /C " & Chr(34) & Chr(34) & switcher & Chr(34) & Chr(34), 0, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function