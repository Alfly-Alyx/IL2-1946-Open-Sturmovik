@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "GAME_ROOT=%%~fI"
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%GAME_ROOT%\tools\Manage-LoadingRotation.ps1" -GameRoot "%GAME_ROOT%"
if errorlevel 1 pause