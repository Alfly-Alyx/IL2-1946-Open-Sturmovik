Option Explicit
Dim fso, shell, root, script, command, code
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
root = fso.GetParentFolderName(WScript.ScriptFullName)
script = fso.BuildPath(root, "tools\Manage-LoadingRotation.ps1")
command = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & script & """ -GameRoot """ & root & """"
code = shell.Run(command, 0, True)
If code <> 0 Then MsgBox "Impossible d'ouvrir les reglages des fonds de chargement.", vbExclamation, "Open Sturmovik"
