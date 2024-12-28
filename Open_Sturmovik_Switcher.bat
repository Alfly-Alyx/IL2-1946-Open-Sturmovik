@echo off

REM IL2 Open Sturmovik Switcher

REM Configuration des couleurs
title IL2 Open Sturmovik Switcher
color 0A

REM Presentation
:welcome
cls
echo ======================================================
echo                IL2 Open Sturmovik Switcher
echo ======================================================
echo ======================================================
echo                Made by Alfly
echo ======================================================
echo.
pause

REM Instructions et suppression des fichiers inutiles
:instructions
cls
echo Removing obsolete files...
if exist "%~dp0il2fb.exe" del "%~dp0il2fb.exe"
if exist "%~dp0files.sfs" del "%~dp0files.sfs"
if exist "%~dp0wrapper.dll" del "%~dp0wrapper.dll"

REM Affichage du menu principal
:main_menu
cls
echo ======================================================
echo                  VERSION SELECTION
echo ======================================================
echo 1 - 4.08m
echo 2 - 4.08m modified
echo 3 - 4.08m modified + 6Dof
echo 4 - 4.09b
echo 5 - 4.09b modified
echo 6 - 4.09b modified + 6Dof
echo 7 - 4.09m
echo 8 - 4.09m modified
echo 9 - 4.09m modified + 6Dof
echo 10 - Quiet
echo.
set /p CHOICE="Your choice? : "

REM Copier les fichiers appropriés
if "%CHOICE%"=="1" (
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods OFF (Original)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods OFF (Original)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods OFF (Original)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="2" (
    xcopy /Y "%~dp0_Game Switchers\4.08 Mod ON (NO 6DOF)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mod ON (NO 6DOF)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mod ON (NO 6DOF)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="3" (
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods 6DOF ON\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods 6DOF ON\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.08 Mods 6DOF ON\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="4" (
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods OFF (Original)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods OFF (Original)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods OFF (Original)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="5" (
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods ON (NO 6DOF)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods ON (NO 6DOF)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods ON (NO 6DOF)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="6" (
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods 6DOF ON\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods 6DOF ON\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09 Mods 6DOF ON\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="7" (
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsOFF(Original)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsOFF(Original)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsOFF(Original)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="8" (
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsON(No-6DoF)\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsON(No-6DoF)\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09finalModsON(No-6DoF)\wrapper.dll" "%~dp0"
)
if "%CHOICE%"=="9" (
    xcopy /Y "%~dp0_Game Switchers\4.09final_ModsON+6DoF\il2fb.exe" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09final_ModsON+6DoF\files.sfs" "%~dp0"
    xcopy /Y "%~dp0_Game Switchers\4.09final_ModsON+6DoF\wrapper.dll" "%~dp0"
)

REM Copier air.ini si necessaire
if "%CHOICE%" lss "4" xcopy /Y "%~dp0_Game Switchers\408m air.ini\air.ini" "%~dp0Files\com\maddox\il2\objects"
if "%CHOICE%" gtr "3" xcopy /Y "%~dp0_Game Switchers\409m air.ini\air.ini" "%~dp0Files\com\maddox\il2\objects"

REM Menu pour le HUD
:hud_menu
cls
echo ======================================================
echo             HUD SELECTION (DISPLAY)
echo ======================================================
echo Do you want a realistic or standard HUD?
echo By default, the game uses the standard HUD. The realistic HUD provides better simulation.
echo.
echo 1 - Standard HUD
echo 2 - Realistic HUD
echo 3 - Quiet
echo.
set /p HUD_CHOICE="Your choice? : "

REM Lancer les fichiers batch pour le HUD
if "%HUD_CHOICE%"=="1" call "%~dp0HUD_Log-REGULAR.bat"
if "%HUD_CHOICE%"=="2" call "%~dp0HUD_Log-IMMERSION.bat"

REM Fin
:finish
cls
echo ======================================================
echo                 Finished
echo You can now launch IL2 Open Sturmovik.
echo ======================================================
pause
