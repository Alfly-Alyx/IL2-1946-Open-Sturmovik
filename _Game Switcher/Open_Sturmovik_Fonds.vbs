Option Explicit
Dim fso, shell, scriptFolder, gameRoot, script, command, code
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
scriptFolder = fso.GetParentFolderName(WScript.ScriptFullName)
gameRoot = fso.GetParentFolderName(scriptFolder)
script = fso.BuildPath(gameRoot, "tools\Manage-LoadingRotation.ps1")
command = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & script & """ -GameRoot """ & gameRoot & """"
code = shell.Run(command, 0, True)
If code <> 0 Then MsgBox "Impossible d'ouvrir les reglages des fonds de chargement.", vbExclamation, "Open Sturmovik"