@echo off
setlocal
title IL-2 Open Sturmovik Switcher 1.15

set "SWITCHER=%~dp0Open_Sturmovik_Switcher.ps1"
if not exist "%SWITCHER%" (
    echo [ERREUR] Fichier introuvable :
    echo %SWITCHER%
    pause
    exit /b 2
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SWITCHER%"
set "RESULT=%ERRORLEVEL%"

if not "%RESULT%"=="0" (
    echo.
    echo Le selecteur s'est arrete avec une erreur. Aucune operation incomplete
    echo ne doit etre consideree comme valide. Consultez le message ci-dessus.
    pause
)

exit /b %RESULT%
