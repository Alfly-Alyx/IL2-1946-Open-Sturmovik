@echo off
setlocal EnableExtensions EnableDelayedExpansion

if "%~3"=="" exit /b 2
if not exist "%~1" (
    echo [ERREUR] %~3 absent : "%~1"
    exit /b 1
)

set "ACTUAL_HASH="
for /F "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%~1" SHA256 2^>nul') do if not defined ACTUAL_HASH set "ACTUAL_HASH=%%H"
set "ACTUAL_HASH=!ACTUAL_HASH: =!"
if /I not "!ACTUAL_HASH!"=="%~2" (
    echo [ERREUR] Empreinte incorrecte pour %~3.
    echo          Attendu : %~2
    echo          Obtenu  : !ACTUAL_HASH!
    exit /b 1
)
exit /b 0
