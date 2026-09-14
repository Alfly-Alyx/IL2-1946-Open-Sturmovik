@echo off
setlocal
set "SOURCE=%~dp0_Game Switcher\HudLogStock\MODS\STD\i18n\hud_log_ru.properties"
set "TARGET_DIR=%~dp0Files\i18n"
set "TARGET=%TARGET_DIR%\hud_log_ru.properties"

if not exist "%SOURCE%" goto :error_source
if not exist "%TARGET_DIR%\" md "%TARGET_DIR%" || goto :error_copy
copy /b /y "%SOURCE%" "%TARGET%" >nul || goto :error_copy
fc /b "%SOURCE%" "%TARGET%" >nul || goto :error_verify

echo HUD standard active et verifie.
exit /b 0

:error_source
echo [ERREUR] Source HUD standard introuvable : "%SOURCE%"
exit /b 2

:error_copy
echo [ERREUR] Impossible de copier le HUD standard vers "%TARGET%"
exit /b 3

:error_verify
echo [ERREUR] La copie du HUD standard ne correspond pas a la source.
exit /b 4
