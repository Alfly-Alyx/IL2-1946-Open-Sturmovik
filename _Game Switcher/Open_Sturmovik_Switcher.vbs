Option Explicit

Dim fileSystem
Dim shell
Dim processEnvironment
Dim scriptFolder
Dim gameRoot
Dim switcher
Dim interfacePath
Dim mshta

Set fileSystem = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
Set processEnvironment = shell.Environment("PROCESS")

scriptFolder = fileSystem.GetParentFolderName(WScript.ScriptFullName)
gameRoot = fileSystem.GetParentFolderName(scriptFolder)
switcher = gameRoot & "\Open_Sturmovik_Switcher.bat"
interfacePath = scriptFolder & "\Open_Sturmovik_Switcher.hta"
mshta = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\mshta.exe"

processEnvironment.Item("OPEN_STURMOVIK_SWITCHER_BAT") = switcher
shell.Run Quote(mshta) & " " & Quote(interfacePath), 1, False

Function Quote(value)
    Quote = Chr(34) & value & Chr(34)
End Function
