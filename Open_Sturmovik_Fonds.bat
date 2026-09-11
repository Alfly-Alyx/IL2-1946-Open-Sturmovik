@echo off
setlocal
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0tools\Manage-LoadingRotation.ps1" -GameRoot "%~dp0."
if errorlevel 1 pause
