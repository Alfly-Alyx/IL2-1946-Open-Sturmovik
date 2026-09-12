@echo off
setlocal EnableExtensions EnableDelayedExpansion
if defined OS_SWITCHER_DEBUG echo on
title IL-2 Open Sturmovik Switcher 1.15

set "ROOT=%~dp0"
set "SWITCH_ROOT=%ROOT%_Game Switcher"
set "VALIDATE_ONLY=0"
set "PROFILE="
set "HUD=standard"

if /I "%~1"=="--apply" (
    set "PROFILE=%~2"
    if not "%~3"=="" set "HUD=%~3"
    goto prepare
)
if /I "%~1"=="--validate" (
    set "VALIDATE_ONLY=1"
    set "PROFILE=%~2"
    if not "%~3"=="" set "HUD=%~3"
    goto prepare
)
if not "%~1"=="" goto usage
call :openGui
exit /b %ERRORLEVEL%

:usage
echo Utilisation :
echo   Open_Sturmovik_Switcher.bat
echo   Open_Sturmovik_Switcher.bat --apply 1..9 [standard^|immersion]
echo   Open_Sturmovik_Switcher.bat --validate 1..9 [standard^|immersion]
exit /b 2

:verify
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

:prepare
if "%PROFILE%"=="1" (
    set "LABEL=4.08m Original"
    set "VERSION=4.08m"
    set "PAYLOAD=4.08m"
    set "PAYLOAD_ID=408"
    set "PROFILE_FOLDER=4.08 Mods OFF (Original)"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=42342CE1089C42B4FBB61F6CFC3850F3AC27FAFE6F4192CD7C6CF042E056F7EC"
)
if "%PROFILE%"=="2" (
    set "LABEL=4.08m Open Sturmovik sans 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.08m"
    set "PAYLOAD_ID=408"
    set "PROFILE_FOLDER=4.08 Mods ON (NO 6DOF)"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=BF93435737A3332AAD653D8269DBC18D9F82EBBB6940C96ECEA46E961B314328"
    set "FILES_HASH=E00F86B80183313B846F72F153A9102A1DC40AFBB90323DE8AC7DE34DED0D5FD"
)
if "%PROFILE%"=="3" (
    set "LABEL=4.08m Open Sturmovik avec 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.08m"
    set "PAYLOAD_ID=408"
    set "PROFILE_FOLDER=4.08 Mods ON 6DOF"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=F1DFCE9E955F61D03837BA14F9497CC4A3EFA989A79CA7EF39C0831F840DECE3"
    set "FILES_HASH=E00F86B80183313B846F72F153A9102A1DC40AFBB90323DE8AC7DE34DED0D5FD"
)
if "%PROFILE%"=="4" (
    set "LABEL=4.09b Original"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods OFF (Original)"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=08682F88511336D083A068A2D3DE81BC02F2AE8A27DF61666FC91F3DFF95BCC2"
)
if "%PROFILE%"=="5" (
    set "LABEL=4.09b Open Sturmovik sans 6DOF"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods ON (NO 6DOF)"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=BF93435737A3332AAD653D8269DBC18D9F82EBBB6940C96ECEA46E961B314328"
    set "FILES_HASH=53B97E4993C17DECDEEC6E4E46E70F42ED01A625AE9AEB274A14327C399F890E"
)
if "%PROFILE%"=="6" (
    set "LABEL=4.09b Open Sturmovik avec 6DOF"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods ON 6DOF"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=F1DFCE9E955F61D03837BA14F9497CC4A3EFA989A79CA7EF39C0831F840DECE3"
    set "FILES_HASH=53B97E4993C17DECDEEC6E4E46E70F42ED01A625AE9AEB274A14327C399F890E"
)
if "%PROFILE%"=="7" (
    set "LABEL=4.09m Original"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09 final Mods OFF (Original)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=FCFCE245EC23FF314C6CD86E9A51D563D091CFF74DDD0B46B704B670C0340C6A"
)
if "%PROFILE%"=="8" (
    set "LABEL=4.09m Open Sturmovik sans 6DOF"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09 final Mods ON (NO 6DOF)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=BF93435737A3332AAD653D8269DBC18D9F82EBBB6940C96ECEA46E961B314328"
    set "FILES_HASH=5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71"
)
if "%PROFILE%"=="9" (
    set "LABEL=4.09m Open Sturmovik avec 6DOF"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09 final Mods ON 6DOF"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=F1DFCE9E955F61D03837BA14F9497CC4A3EFA989A79CA7EF39C0831F840DECE3"
    set "FILES_HASH=5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71"
)

if not defined VERSION (
    echo [ERREUR] Profil invalide : %PROFILE%
    exit /b 2
)
if /I not "%HUD%"=="keep" if /I not "%HUD%"=="standard" if /I not "%HUD%"=="immersion" (
    echo [ERREUR] Choix HUD invalide : %HUD%
    exit /b 2
)
for /D %%T in ("%SWITCH_ROOT%\_transaction-*") do if exist "%%~fT" (
    echo [ERREUR] Transaction precedente incomplete : "%%~fT". Sauvegardes conservees.
    exit /b 7
)

set "PROFILE_DIR=%SWITCH_ROOT%\%PROFILE_FOLDER%"
set "PAYLOAD_DIR=%SWITCH_ROOT%\Version Payloads\%PAYLOAD%"
set "WRAPPER_HASH=8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78"

if "%VALIDATE_ONLY%"=="0" (
    tasklist /FI "IMAGENAME eq il2fb.exe" /NH 2>nul | find /I "il2fb.exe" >nul
    if not errorlevel 1 (
        echo [ERREUR] IL-2 est en cours. Fermez le jeu avant de changer de profil.
        exit /b 3
    )
)

call :verify "%ROOT%fb_3do18.SFS" "AFD482C2BECB39BC4E88C8CCA30E367A5261B06C5059A29E2D467CDDDD8163C0" "fb_3do18.SFS commun"
if errorlevel 1 exit /b 4
call :verify "%ROOT%fb_maps14.SFS" "9AFA2CB3670224185B693788F3D9196C971CA25AE5A6064C8F4710B3AB95F1FC" "fb_maps14.SFS commun"
if errorlevel 1 exit /b 4
call :verify "%PROFILE_DIR%\il2fb.exe" "%EXE_HASH%" "Executable du profil"
if errorlevel 1 exit /b 4
call :verify "%PROFILE_DIR%\files.SFS" "%FILES_HASH%" "files.SFS du profil"
if errorlevel 1 exit /b 4
if "%ORIGINAL%"=="0" (
    call :verify "%PROFILE_DIR%\wrapper.dll" "%WRAPPER_HASH%" "Wrapper du profil"
    if errorlevel 1 exit /b 4
)
call :profileDataCheck
if errorlevel 1 exit /b 4
call :payloadCheck%PAYLOAD_ID%
if errorlevel 1 exit /b 4
call :detectBackground
if errorlevel 1 exit /b 4
call :verify "%SWITCH_ROOT%\Resources\Loading Backgrounds\Maddox\%BACKGROUND_FORMAT%\Background.tga" "%BACKGROUND_HASH%" "Fond de chargement %BACKGROUND_FORMAT%"
if errorlevel 1 exit /b 4
if /I "%HUD%"=="standard" (
    call :verify "%SWITCH_ROOT%\HudLogStock\MODS\STD\i18n\hud_log_ru.properties" "932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862" "HUD standard"
    if errorlevel 1 exit /b 4
)
if /I "%HUD%"=="immersion" (
    call :verify "%SWITCH_ROOT%\HudLogImmersion\MODS\STD\i18n\hud_log_ru.properties" "ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C" "HUD immersion"
    if errorlevel 1 exit /b 4
)

if "%VALIDATE_ONLY%"=="1" (
    echo [OK] Profil valide sans modification : %LABEL%
    echo [OK] Fond de chargement valide : %BACKGROUND_FORMAT% pour %BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
    exit /b 0
)

call :detectHud
if /I not "%HUD%"=="keep" set "MOD_HUD=%HUD%"
set "EFFECTIVE_HUD=%MOD_HUD%"
if "%ORIGINAL%"=="1" set "EFFECTIVE_HUD=stock"

set "TX=%SWITCH_ROOT%\_transaction-%RANDOM%-%RANDOM%"
if exist "%TX%" (
    echo [ERREUR] Dossier de transaction deja present : "%TX%"
    exit /b 5
)
md "%TX%\stage" "%TX%\backup" "%TX%\state" >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Impossible de creer la transaction.
    exit /b 5
)
>"%TX%\next-profile.txt" (
    echo profile=%PROFILE%
    echo version=%VERSION%
    echo label=%LABEL%
    echo hud=%EFFECTIVE_HUD%
    echo modhud=%MOD_HUD%
    echo background=%BACKGROUND_FORMAT%
    echo resolution=%BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
)
if errorlevel 1 goto stage_failed

call :stage "%PROFILE_DIR%\il2fb.exe" "il2fb.exe"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\files.SFS" "files.SFS"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%AIR%" "Files\com\maddox\il2\objects\air.ini"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%STATIONARY%" "Files\com\maddox\il2\objects\stationary.ini"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\Resources\Loading Backgrounds\Maddox\%BACKGROUND_FORMAT%\Background.tga" "Files\background0.tga"
if errorlevel 1 goto stage_failed
if "%ORIGINAL%"=="0" (
    call :stage "%PROFILE_DIR%\wrapper.dll" "wrapper.dll"
    if errorlevel 1 goto stage_failed
)
call :stage "%PAYLOAD_DIR%\il2_core.dll" "il2_core.dll"
if errorlevel 1 goto stage_failed
call :stage "%PAYLOAD_DIR%\il2_corep4.dll" "il2_corep4.dll"
if errorlevel 1 goto stage_failed
call :stage "%PAYLOAD_DIR%\mg_snd.dll" "mg_snd.dll"
if errorlevel 1 goto stage_failed
call :stage "%PAYLOAD_DIR%\mg_snd_sse.dll" "mg_snd_sse.dll"
if errorlevel 1 goto stage_failed
if "%REMOVE_VERSION_SFS%"=="0" (
    call :stage "%PAYLOAD_DIR%\fb_3do19.SFS" "fb_3do19.SFS"
    if errorlevel 1 goto stage_failed
    call :stage "%PAYLOAD_DIR%\fb_3do20.SFS" "fb_3do20.SFS"
    if errorlevel 1 goto stage_failed
    call :stage "%PAYLOAD_DIR%\fb_maps15.SFS" "fb_maps15.SFS"
    if errorlevel 1 goto stage_failed
)
if /I "%HUD%"=="standard" (
    call :stage "%SWITCH_ROOT%\HudLogStock\MODS\STD\i18n\hud_log_ru.properties" "Files\i18n\hud_log_ru.properties"
    if errorlevel 1 goto stage_failed
)
if /I "%HUD%"=="immersion" (
    call :stage "%SWITCH_ROOT%\HudLogImmersion\MODS\STD\i18n\hud_log_ru.properties" "Files\i18n\hud_log_ru.properties"
    if errorlevel 1 goto stage_failed
)

call :backup 01 "il2fb.exe"
if errorlevel 1 goto backup_failed
call :backup 02 "files.SFS"
if errorlevel 1 goto backup_failed
call :backup 03 "wrapper.dll"
if errorlevel 1 goto backup_failed
call :backup 04 "fb_3do19.SFS"
if errorlevel 1 goto backup_failed
call :backup 05 "fb_3do20.SFS"
if errorlevel 1 goto backup_failed
call :backup 06 "fb_maps15.SFS"
if errorlevel 1 goto backup_failed
call :backup 07 "il2_core.dll"
if errorlevel 1 goto backup_failed
call :backup 08 "il2_corep4.dll"
if errorlevel 1 goto backup_failed
call :backup 09 "mg_snd.dll"
if errorlevel 1 goto backup_failed
call :backup 10 "mg_snd_sse.dll"
if errorlevel 1 goto backup_failed
call :backup 11 "Files\com\maddox\il2\objects\air.ini"
if errorlevel 1 goto backup_failed
call :backup 12 "Files\com\maddox\il2\objects\stationary.ini"
if errorlevel 1 goto backup_failed
if /I not "%HUD%"=="keep" (
    call :backup 13 "Files\i18n\hud_log_ru.properties"
    if errorlevel 1 goto backup_failed
)
call :backup 14 "_Game Switcher\active-profile.txt"
if errorlevel 1 goto backup_failed
call :backup 15 "Files\background0.tga"
if errorlevel 1 goto backup_failed

for /R "%TX%\stage" %%F in (*) do (
    set "REL=%%~fF"
    set "REL=!REL:%TX%\stage\=!"
    for %%D in ("%ROOT%!REL!") do if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
    copy /B /Y "%%~fF" "%ROOT%!REL!" >nul || goto commit_failed
    fc /B "%%~fF" "%ROOT%!REL!" >nul || goto commit_failed
)

if "%ORIGINAL%"=="1" (
    call :remove "wrapper.dll"
    if errorlevel 1 goto commit_failed
)
if "%REMOVE_VERSION_SFS%"=="1" (
    call :remove "fb_3do19.SFS"
    if errorlevel 1 goto commit_failed
    call :remove "fb_3do20.SFS"
    if errorlevel 1 goto commit_failed
    call :remove "fb_maps15.SFS"
    if errorlevel 1 goto commit_failed
)

copy /B /Y "%TX%\next-profile.txt" "%SWITCH_ROOT%\active-profile.txt" >nul || goto commit_failed
fc /B "%TX%\next-profile.txt" "%SWITCH_ROOT%\active-profile.txt" >nul || goto commit_failed
rmdir /S /Q "%TX%"
echo [OK] Profil active : %LABEL%
echo [OK] HUD du profil : %EFFECTIVE_HUD%
echo [OK] Fond de chargement : %BACKGROUND_FORMAT% pour %BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
exit /b 0

:stage_failed
echo [ERREUR] Preparation de la transaction impossible. Aucun fichier actif modifie.
rmdir /S /Q "%TX%"
exit /b 5

:backup_failed
echo [ERREUR] Sauvegarde de la configuration active impossible. Aucun remplacement effectue.
rmdir /S /Q "%TX%"
exit /b 6

:commit_failed
echo [ERREUR] Echec pendant le remplacement. Restauration en cours...
call :rollback
if errorlevel 1 (
    echo [ERREUR] Restauration incomplete. Sauvegardes conservees dans "%TX%".
    exit /b 7
)
rmdir /S /Q "%TX%"
echo [OK] Configuration precedente restauree.
exit /b 6

:profileDataCheck
if %PROFILE% LEQ 3 (
    call :verify "%SWITCH_ROOT%\%AIR%" "C7DC944BFFCF1DD2E0D12382894F6193CA23D6F72D8F92478A92A708194C5BA3" "air.ini 4.08m"
) else if %PROFILE% LEQ 6 (
    call :verify "%SWITCH_ROOT%\%AIR%" "9A7ED6510B2569F20EBFC57AB47B06645C39E3766361B5A5C31C0C6A55337B39" "air.ini 4.09b"
) else (
    call :verify "%SWITCH_ROOT%\%AIR%" "71B25E4AD1880ADBB29440BBBD791955DDFC61CEB9DEA9AFCE37B72EA628617F" "air.ini 4.09m"
)
if errorlevel 1 exit /b 1
if %PROFILE% LEQ 6 (
    call :verify "%SWITCH_ROOT%\%STATIONARY%" "C9E5A7E59941945D0434B58CB6F0097EBFC4E31236D0FFF49907830B13E11DD4" "stationary.ini 4.08/4.09b"
) else (
    call :verify "%SWITCH_ROOT%\%STATIONARY%" "9A446C92C5D88986EDADC280689C9F4A1799EEFE1E646017A79E2B7544A18882" "stationary.ini 4.09m"
)
if errorlevel 1 exit /b 1
exit /b 0

:payloadCheck408
call :verify "%PAYLOAD_DIR%\il2_core.dll" "AE1B06F2D4F6CC14A535FC47DF66D53A3DB1AE2BBA49A20F94BD109A03E6CE9C" "il2_core.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\il2_corep4.dll" "9D7D89C664D490EDBED97836FA810BB88BBAFA7D37A7B8D1DC76D15050F79A15" "il2_corep4.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.08m"
if errorlevel 1 exit /b 1
exit /b 0

:payloadCheck409b
call :verify "%PAYLOAD_DIR%\fb_3do19.SFS" "F4EBF76EA04511E57D75AC9F7D3E68953A6D85EF5093AFE35486DDBC10D81007" "fb_3do19.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\fb_maps15.SFS" "35742CA5476DA955C6B544303739F4E3F4BFD54D6EF9505B993BBA4ACC7C2522" "fb_maps15.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\il2_core.dll" "F8DDE5FC6C10BCA94481875BBAA4DA07F408CD5168E7E7DEECDD0B08C0B1992D" "il2_core.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\il2_corep4.dll" "B5D014D457107EFB86F740055692A5923C0E6A14B4C147CD7965EA007101277B" "il2_corep4.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.09b"
if errorlevel 1 exit /b 1
exit /b 0

:payloadCheck409m
call :verify "%PAYLOAD_DIR%\fb_3do19.SFS" "4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670" "fb_3do19.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\fb_maps15.SFS" "AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9" "fb_maps15.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\il2_core.dll" "3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3" "il2_core.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\il2_corep4.dll" "0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979" "il2_corep4.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd.dll" "2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421" "mg_snd.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PAYLOAD_DIR%\mg_snd_sse.dll" "FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4" "mg_snd_sse.dll 4.09m"
if errorlevel 1 exit /b 1
exit /b 0

:detectHud
set "MOD_HUD=custom"
set "ACTUAL_HASH="
if not exist "%ROOT%Files\i18n\hud_log_ru.properties" (
    set "MOD_HUD=stock"
    exit /b 0
)
for /F "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%ROOT%Files\i18n\hud_log_ru.properties" SHA256 2^>nul') do if not defined ACTUAL_HASH set "ACTUAL_HASH=%%H"
set "ACTUAL_HASH=!ACTUAL_HASH: =!"
if /I "!ACTUAL_HASH!"=="932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862" set "MOD_HUD=standard"
if /I "!ACTUAL_HASH!"=="ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C" set "MOD_HUD=immersion"
exit /b 0

:detectBackground
set "BACKGROUND_WIDTH=1024"
set "BACKGROUND_HEIGHT=768"
set "BACKGROUND_IN_WINDOW=0"
if exist "%ROOT%conf.ini" for /F "usebackq tokens=* delims=" %%L in ("%ROOT%conf.ini") do (
    set "BACKGROUND_LINE=%%L"
    if /I "!BACKGROUND_LINE!"=="[window]" (
        set "BACKGROUND_IN_WINDOW=1"
    ) else if "!BACKGROUND_LINE:~0,1!"=="[" (
        set "BACKGROUND_IN_WINDOW=0"
    ) else if "!BACKGROUND_IN_WINDOW!"=="1" (
        for /F "tokens=1,* delims==" %%A in ("!BACKGROUND_LINE!") do (
            if /I "%%A"=="width" set "BACKGROUND_WIDTH=%%B"
            if /I "%%A"=="height" set "BACKGROUND_HEIGHT=%%B"
        )
    )
)
set /A BACKGROUND_RATIO=BACKGROUND_WIDTH*1000/BACKGROUND_HEIGHT >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Resolution invalide dans conf.ini : %BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
    exit /b 1
)
if %BACKGROUND_RATIO% LEQ 1420 (
    set "BACKGROUND_FORMAT=4x3"
    set "BACKGROUND_HASH=E1C0BFB53AE7E5891BF7A4F8333D33F119B177E373DBE8B6BBEC3014EC7CB898"
) else if %BACKGROUND_RATIO% LEQ 1700 (
    set "BACKGROUND_FORMAT=16x10"
    set "BACKGROUND_HASH=B7305B816509CBADF15FC2484696484F676F0CB97721DC503C34FFB7C233913A"
) else if %BACKGROUND_RATIO% LEQ 2050 (
    set "BACKGROUND_FORMAT=16x9"
    set "BACKGROUND_HASH=EFC91DD0047146AA4414A0F06B979AA3CFD7F6B5D86E5D621F0E65F8DD0C70E9"
) else if %BACKGROUND_RATIO% LEQ 2800 (
    set "BACKGROUND_FORMAT=21x9"
    set "BACKGROUND_HASH=59FFE92F41A42A5BD2517D1FFE8B85EE2F85CB1723B7539D315B16EF048875D4"
) else (
    set "BACKGROUND_FORMAT=32x9"
    set "BACKGROUND_HASH=46B39B63E660B7D8CD8C8F544866D17367483BEFA92AD6D322CF403C6A4CA6BC"
)
exit /b 0

:stage
for %%D in ("%TX%\stage\%~2") do if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
copy /B /Y "%~1" "%TX%\stage\%~2" >nul || exit /b 1
fc /B "%~1" "%TX%\stage\%~2" >nul || exit /b 1
exit /b 0

:backup
if exist "%ROOT%%~2" (
    for %%D in ("%TX%\backup\%~2") do if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
    copy /B /Y "%ROOT%%~2" "%TX%\backup\%~2" >nul || exit /b 1
    fc /B "%ROOT%%~2" "%TX%\backup\%~2" >nul || exit /b 1
    type nul >"%TX%\state\%~1.present"
) else (
    type nul >"%TX%\state\%~1.absent"
)
exit /b 0

:remove
if exist "%ROOT%%~1" del /F /Q "%ROOT%%~1" >nul 2>&1
if exist "%ROOT%%~1" exit /b 1
exit /b 0

:restore
if exist "%TX%\state\%~1.present" (
    if "%~1"=="14" (
        fc /B "%TX%\backup\%~2" "%ROOT%%~2" >nul 2>&1
        if not errorlevel 1 exit /b 0
    )
    for %%D in ("%ROOT%%~2") do if not exist "%%~dpD" md "%%~dpD" >nul 2>&1
    copy /B /Y "%TX%\backup\%~2" "%ROOT%%~2" >nul || exit /b 1
    fc /B "%TX%\backup\%~2" "%ROOT%%~2" >nul || exit /b 1
) else if exist "%TX%\state\%~1.absent" (
    if exist "%ROOT%%~2" del /F /Q "%ROOT%%~2" >nul 2>&1
    if exist "%ROOT%%~2" exit /b 1
)
exit /b 0

:rollback
set "ROLLBACK_FAILED=0"
call :restore 01 "il2fb.exe"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 02 "files.SFS"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 03 "wrapper.dll"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 04 "fb_3do19.SFS"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 05 "fb_3do20.SFS"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 06 "fb_maps15.SFS"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 07 "il2_core.dll"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 08 "il2_corep4.dll"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 09 "mg_snd.dll"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 10 "mg_snd_sse.dll"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 11 "Files\com\maddox\il2\objects\air.ini"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 12 "Files\com\maddox\il2\objects\stationary.ini"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 13 "Files\i18n\hud_log_ru.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 14 "_Game Switcher\active-profile.txt"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 15 "Files\background0.tga"
if errorlevel 1 set "ROLLBACK_FAILED=1"
if "%ROLLBACK_FAILED%"=="1" exit /b 1
exit /b 0

:openGui
set "OPEN_STURMOVIK_SWITCHER_BAT=%~f0"
set "SWITCHER_GUI_LINE="
for /F "tokens=1 delims=:" %%N in ('findstr /N /B /C:"### OPEN_STURMOVIK_GUI ###" "%~f0"') do set "SWITCHER_GUI_LINE=%%N"
if not defined SWITCHER_GUI_LINE (
    echo [ERREUR] Interface integree introuvable dans "%~f0".
    exit /b 2
)
set "SWITCHER_GUI_TEMP=%TEMP%\OpenSturmovikSwitcher-%RANDOM%-%RANDOM%.hta"
set "SWITCHER_GUI_ICON_TEMP=%TEMP%\OpenSturmovikSwitcher-v115.ico"
set "SWITCHER_GUI_BACKGROUND_TEMP=%TEMP%\OpenSturmovikSwitcher-v115-background.png"
more +%SWITCHER_GUI_LINE% "%~f0" > "%SWITCHER_GUI_TEMP%"
if errorlevel 1 (
    echo [ERREUR] Impossible de preparer l'interface graphique.
    exit /b 2
)
copy /Y "%SWITCH_ROOT%\Resources\Icons\Open_Sturmovik_Switcher.ico" "%SWITCHER_GUI_ICON_TEMP%" >nul
if errorlevel 1 (
    del /F /Q "%SWITCHER_GUI_TEMP%" >nul 2>&1
    echo [ERREUR] Impossible de preparer l'icone de l'interface.
    exit /b 2
)
copy /Y "%SWITCH_ROOT%\Resources\Backgrounds\Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail.png" "%SWITCHER_GUI_BACKGROUND_TEMP%" >nul
if errorlevel 1 (
    del /F /Q "%SWITCHER_GUI_TEMP%" >nul 2>&1
    del /F /Q "%SWITCHER_GUI_ICON_TEMP%" >nul 2>&1
    del /F /Q "%SWITCHER_GUI_BACKGROUND_TEMP%" >nul 2>&1
    echo [ERREUR] Impossible de preparer le fond de l'interface.
    exit /b 2
)
start "Open Sturmovik Switcher" mshta.exe "%SWITCHER_GUI_TEMP%"
if errorlevel 1 (
    del /F /Q "%SWITCHER_GUI_TEMP%" >nul 2>&1
    del /F /Q "%SWITCHER_GUI_ICON_TEMP%" >nul 2>&1
    del /F /Q "%SWITCHER_GUI_BACKGROUND_TEMP%" >nul 2>&1
    echo [ERREUR] Impossible de lancer l'interface graphique.
    exit /b 2
)
exit /b 0

### OPEN_STURMOVIK_GUI ###
<!doctype html>
<html>
<head>
<meta http-equiv="X-UA-Compatible" content="IE=9" />
<meta charset="utf-8" />
<title>Open Sturmovik Switcher 1.15</title>
<hta:application applicationname="Open Sturmovik Switcher" border="thin"
  caption="yes" icon="OpenSturmovikSwitcher-v115.ico" maximizebutton="no" minimizebutton="yes" scroll="no"
  singleinstance="yes" sysmenu="yes" windowstate="normal" />
<style>
html, body { width:100%; height:100%; margin:0; overflow:hidden; }
body { font-family:"Trebuchet MS",Tahoma,Arial,sans-serif; font-size:17px; color:#d6d8d0; background:#293a40 url("OpenSturmovikSwitcher-v115-background.png") center center no-repeat; background-size:cover; text-shadow:1px 1px 1px #252c2b; }
.titlebar { position:absolute; left:0; right:0; top:0; height:29px; border:2px ridge #8b9690; background:rgba(91,101,98,.98); box-shadow:inset 1px 1px #c6ccc2,inset -2px -2px #34413f; }
.titlebar .caption { box-sizing:border-box; float:left; width:30%; height:29px; padding:3px 28px; border-right:3px ridge #87928d; font-size:17px; font-weight:normal; }
.titlebar .pilot { float:right; margin:3px 28px 0 0; font-size:17px; }
.panel { position:absolute; left:50%; top:66px; width:820px; height:598px; margin-left:-414px; border:4px ridge #89938e; border-radius:1px; background:rgba(77,86,83,.94); background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI2IiBoZWlnaHQ9IjYiPjxwYXRoIGQ9Ik0tMSAxbDItMk0wIDZsNi02TTUgN2wyLTIiIHN0cm9rZT0iI2QyZGNjZSIgc3Ryb2tlLW9wYWNpdHk9Ii4wMzUiLz48cGF0aCBkPSJNLTEgNWwyIDJNMCAwbDYgNk01LTFsMiAyIiBzdHJva2U9IiMwOTFiMjAiIHN0cm9rZS1vcGFjaXR5PSIuMDYiLz48L3N2Zz4="); box-shadow:inset 2px 2px 2px #aeb7b0,inset -3px -3px 3px #283330,0 3px 4px #111a1b; }
.bolt { position:absolute; width:12px; height:12px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMiIgaGVpZ2h0PSIxMiI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJtIiB4Mj0iMSIgeTI9IjEiPjxzdG9wIHN0b3AtY29sb3I9IiNkNmQ1YWUiLz48c3RvcCBvZmZzZXQ9Ii40IiBzdG9wLWNvbG9yPSIjODI5MTgxIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMjUzYzM5Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PGNpcmNsZSBjeD0iNi41IiBjeT0iNi41IiByPSI0LjgiIGZpbGw9IiMxMTJiMmUiLz48Y2lyY2xlIGN4PSI1LjUiIGN5PSI1LjUiIHI9IjQuMiIgZmlsbD0idXJsKCNtKSIgc3Ryb2tlPSIjNTk3NjZiIiBzdHJva2Utd2lkdGg9Ii42Ii8+PHBhdGggZD0iTTMgOGw1LTUiIHN0cm9rZT0iIzIzM2IzNSIgc3Ryb2tlLXdpZHRoPSIxLjEiLz48cGF0aCBkPSJNMy42IDguNGw1LTUiIHN0cm9rZT0iI2NlZDJiMiIgc3Ryb2tlLXdpZHRoPSIuNiIvPjwvc3ZnPg==") center center no-repeat; }
.tl{left:4px;top:4px}.tr{right:4px;top:4px}.bl{left:4px;bottom:4px}.br{right:4px;bottom:4px}
.tm{left:50%;top:4px;margin-left:-6px}.bm{left:50%;bottom:4px;margin-left:-6px}.ml{left:4px;top:50%;margin-top:-6px}.mr{right:4px;top:50%;margin-top:-6px}
.tq{left:25%;top:4px}.tq3{left:75%;top:4px}.bq{left:25%;bottom:4px}.bq3{left:75%;bottom:4px}.lq{left:4px;top:25%}.lq3{left:4px;top:75%}.rq{right:4px;top:25%}.rq3{right:4px;top:75%}
.column { position:absolute; top:29px; bottom:112px; box-sizing:border-box; }
.left { left:30px; width:380px; padding-right:25px; border-right:2px solid #c3c7be; box-shadow:2px 0 #353e3b; }
.right { right:30px; width:354px; }
.heading { margin:0 0 12px; padding:8px 14px; color:#e0e2d8; font-size:19px; line-height:24px; font-weight:normal; border:0; border-radius:0; background:none; box-shadow:none; text-align:left; text-shadow:1px 1px #252d2b,0 0 1px #e9eadf; }
.choice { display:block; position:relative; height:52px; margin:2px 0; cursor:pointer; }
.choice input { position:absolute; left:11px; top:15px; width:27px; height:27px; margin:0; opacity:0; filter:alpha(opacity=0); }
.lamp { position:absolute; left:3px; top:7px; width:44px; height:44px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg==") no-repeat; }
.choice input:checked + .lamp, .choice:hover .lamp { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNjMWVjNTkiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzIxYjkxYiIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMTU0NjE3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.choice .name { position:absolute; left:64px; top:17px; font-size:19px; font-weight:normal; color:#d8dad2; text-shadow:1px 1px #2b312f,0 0 1px #e5e7dd; }
.choice input:checked ~ .name { color:#f0f3e4; }
.choice input:focus ~ .name { outline:1px dotted #dfdfc0; outline-offset:4px; }
.choice .detail { display:none; }
.choice.disabled { cursor:default; opacity:.45; }
.choice.disabled:hover .lamp { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.hudrow { height:53px; margin-top:4px; }
.hudrow .choice { display:inline-block; width:170px; height:51px; margin:0; vertical-align:top; }
.hudrow .choice .lamp { left:1px; top:3px; }
.hudrow .choice .name { left:52px; top:16px; font-size:16px; }
.hudheading { margin-top:14px; padding:8px 0 0; border:0; border-top:2px solid #c3c7be; border-radius:0; background:none; box-shadow:inset 0 2px #353e3b; text-align:left; }
.summary { box-sizing:border-box; height:128px; margin-top:18px; padding:10px 12px; border:2px inset #89958e; background:rgba(38,45,43,.72); box-shadow:none; color:#d0d4cc; font-size:11px; line-height:17px; text-shadow:1px 1px #202624; }
.summary strong { font-weight:normal; color:#eff0d7; font-size:12px; }
.current { box-sizing:border-box; margin-top:16px; min-height:60px; padding:10px 13px; border:2px ridge #838d84; border-radius:1px; background:rgba(42,48,46,.84); box-shadow:inset 1px 1px #aeb3a7,inset -2px -2px #313a36; color:#d9ddd4; font-size:14px; line-height:19px; }
.actions { position:absolute; left:30px; right:30px; bottom:28px; height:52px; padding-top:18px; border-top:2px solid #c3c7be; box-shadow:inset 0 2px #353e3b; }
.button { position:relative; box-sizing:border-box; height:46px; min-width:154px; margin:0 0 0 56px; padding:0 16px; border:3px ridge #b3bbb1; border-radius:1px; color:#e2e3da; background:#68716d; font:18px "Trebuchet MS",Tahoma,Arial,sans-serif; text-align:left; cursor:pointer; box-shadow:inset 1px 1px #d7dbd0,inset -2px -2px #3a4440; text-shadow:1px 1px #2c302f; }
.button .bulb { display:none; }
.button:before { content:""; position:absolute; left:-55px; top:0; width:44px; height:44px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg==") no-repeat; }
.button.quit { background:#9b3025; border-color:#d2c2b9; }
.button.quit:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNmZmE3NzMiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iI2QzMWExMCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjNjYxNzE0Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button.apply { float:right; min-width:144px; margin-right:0; border-color:transparent; border-radius:0; background:transparent; box-shadow:none; }
.button.apply:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button.apply:hover:before, .button.apply:focus:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNjMWVjNTkiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzIxYjkxYiIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMTU0NjE3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button.apply#apply { border-color:#adc49f; color:#f0f5e9; background:#3f6e40; box-shadow:inset 1px 1px #b4cba8,inset -2px -2px #294b2d; }
.button.apply#apply:hover, .button.apply#apply:focus { background:#4c8050; }
.button.apply#apply:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNjMWVjNTkiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzIxYjkxYiIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMTU0NjE3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button:hover, .button:focus { color:#fffde5; outline:1px dotted #dddcc3; outline-offset:3px; }
.button.quit:hover { background:#ad382b; }
.button:active { top:1px; }
.button:disabled { color:#8da097; cursor:default; opacity:.6; outline:0; }
.button.credits { position:absolute; left:50%; top:18px; min-width:150px; margin-left:-75px; text-align:center; }
#creditsPage { display:none; position:absolute; left:30px; right:30px; top:29px; bottom:28px; }
#creditsPage h1 { margin:0; padding:3px 0; color:#f0f0df; font-size:23px; line-height:32px; font-weight:normal; }
#creditsJump { position:absolute; right:0; top:6px; box-sizing:border-box; width:244px; padding:5px 7px; border:2px inset #929b91; color:#e4e6dc; background:#303b36; font:13px "Trebuchet MS",Tahoma,Arial,sans-serif; }
#creditsScroll { position:absolute; left:0; right:0; top:57px; bottom:89px; overflow-x:hidden; overflow-y:auto; padding:4px 19px 24px; border:2px inset #929b91; background:rgba(29,37,33,.94); color:#dce0d5; font-size:14px; line-height:21px; text-shadow:none; }
#creditsScroll:focus { outline:1px dotted #dddcc3; outline-offset:3px; }
#creditsScroll p { margin:15px 0; }
#creditsScroll strong, .credits-author { color:#eee7bd; font-weight:bold; }
.credits-section { margin-top:27px; }
.credits-section h2 { margin:0 0 13px; padding:8px 0; border-bottom:1px solid #859084; color:#f1efdb; font-size:19px; line-height:25px; font-weight:normal; }
.credits-table { width:100%; border-collapse:collapse; table-layout:fixed; font-size:13px; line-height:20px; }
.credits-table th { padding:9px 10px; border-bottom:1px solid #94a08f; color:#b8c6ad; background:#26332c; font-size:12px; text-align:left; font-weight:normal; }
.credits-table td { padding:12px 10px; border-bottom:1px solid #46554a; vertical-align:top; word-wrap:break-word; }
.credits-table tbody tr:nth-child(even) { background:rgba(108,124,107,.09); }
.credits-table td:first-child { color:#f0f1e1; }
.credits-table.cols-3 th:first-child { width:27%; }
.credits-table.cols-3 th:first-child + th { width:28%; }
.credits-table.cols-2 th:first-child { width:64%; }
#creditsScroll a { color:#c8dca5; text-decoration:underline; }
#creditsScroll a:hover, #creditsScroll a:focus { color:#fff4c5; }
.credits-reference { border-bottom:1px dotted #829079; cursor:help; }
#creditsPage .actions { left:0; right:0; bottom:0; }
.credits-hint { float:left; padding-top:11px; color:#bac3b6; font-size:13px; }

#result { display:none; position:absolute; left:30px; right:30px; top:29px; bottom:28px; }
#statusTitle { margin:0 0 22px; padding:15px; border:2px ridge #929b91; border-radius:1px; background:rgba(39,46,44,.88); font-size:21px; font-weight:normal; text-align:center; }
#log { box-sizing:border-box; height:359px; overflow:auto; padding:16px; border:2px inset #929b91; background:rgba(34,40,38,.86); color:#d9dcd4; font:13px/20px Consolas,monospace; white-space:pre-wrap; word-wrap:break-word; text-shadow:none; }
#result .actions { left:0; right:0; bottom:0; }
.ok { color:#bbdf9d; }.error { color:#ffb49a; }
@media screen and (max-height:700px) { .panel { top:44px; height:calc(100% - 62px); min-height:565px; } .column { top:24px; } }
</style>
<script language="javascript">
var fso, shell, root, bat, switchRoot, guiTemp, guiIconTemp, guiBackgroundTemp;

function init() {
  window.resizeTo(1000, 760);
  window.moveTo((screen.availWidth - 1000) / 2, (screen.availHeight - 760) / 2);
  fso = new ActiveXObject('Scripting.FileSystemObject');
  shell = new ActiveXObject('WScript.Shell');
  bat = shell.Environment('PROCESS').Item('OPEN_STURMOVIK_SWITCHER_BAT');
  guiTemp = shell.Environment('PROCESS').Item('SWITCHER_GUI_TEMP');
  guiIconTemp = shell.Environment('PROCESS').Item('SWITCHER_GUI_ICON_TEMP');
  guiBackgroundTemp = shell.Environment('PROCESS').Item('SWITCHER_GUI_BACKGROUND_TEMP');
  root = fso.GetParentFolderName(bat);
  switchRoot = fso.BuildPath(root, '_Game Switcher');
  restoreState();
  updateSelection();
  setTimeout(cleanupGuiSource, 750);
}

function cleanupGuiSource() {
  if (!guiTemp) return;
  try { if (fso.FileExists(guiTemp)) fso.DeleteFile(guiTemp, true); } catch (ignore) {}
  try { if (guiIconTemp && fso.FileExists(guiIconTemp)) fso.DeleteFile(guiIconTemp, true); } catch (ignore) {}
  try { if (guiBackgroundTemp && fso.FileExists(guiBackgroundTemp)) fso.DeleteFile(guiBackgroundTemp, true); } catch (ignore) {}
}

function selected(name) {
  var items = document.getElementsByName(name);
  for (var i = 0; i < items.length; i++) if (items[i].checked) return items[i].value;
  return '';
}

function selectValue(name, value) {
  var items = document.getElementsByName(name);
  for (var i = 0; i < items.length; i++) items[i].checked = items[i].value == value;
}

function restoreState() {
  var state = fso.BuildPath(switchRoot, 'active-profile.txt');
  if (!fso.FileExists(state)) return;
  var stream = fso.OpenTextFile(state, 1, false, -2);
  var text = stream.ReadAll();
  stream.Close();
  var match = /^profile=([1-9])\r?$/m.exec(text);
  if (!match) {
    document.getElementById('current').innerText = 'Profil actuel non reconnu. Choisissez une configuration.';
    return;
  }
  var profile = parseInt(match[1], 10) - 1;
  selectValue('version', ['408', '409b', '409m'][Math.floor(profile / 3)]);
  selectValue('mode', ['original', 'standard', 'sixdof'][profile % 3]);
  var hud = /^modhud=(standard|immersion)\r?$/m.exec(text);
  if (!hud) hud = /^hud=(standard|immersion)\r?$/m.exec(text);
  selectValue('hud', hud ? hud[1] : 'standard');
  var label = /^label=([^\r\n]+)/m.exec(text);
  document.getElementById('current').innerText = label ? 'Configuration active : ' + label[1] : 'Configuration active : profil ' + (profile + 1);
}

function profileNumber() {
  var version = selected('version');
  var mode = selected('mode');
  if (version != '408' && version != '409b' && version != '409m') return 0;
  if (mode != 'original' && mode != 'standard' && mode != 'sixdof') return 0;
  var base = version == '408' ? 0 : (version == '409b' ? 3 : 6);
  return base + (mode == 'original' ? 1 : (mode == 'standard' ? 2 : 3));
}

function updateSelection() {
  var version = selected('version');
  var mode = selected('mode');
  var original = mode == 'original';
  var immersion = document.getElementById('hudImmersion');
  immersion.disabled = original;
  document.getElementById('hudImmersionChoice').className = original ? 'choice disabled' : 'choice';
  if (original) selectValue('hud', 'standard');
  var modeText = original ? 'Jeu stock' : (mode == 'sixdof' ? 'Open Sturmovik avec 6DOF' : 'Open Sturmovik sans 6DOF');
  var wrapper = original ? 'retiré' : 'installé';
  var archives = version == '408' ? 'archives 4.09 retirées' : 'archives ' + (version == '409b' ? '4.09b' : '4.09m');
  var hud = original ? 'HUD original du jeu' : (selected('hud') == 'immersion' ? 'HUD immersion' : 'HUD standard');
  document.getElementById('summary').innerHTML = '<strong>' + (version == '408' ? '4.08m' : version) + ' — ' + modeText + '</strong><br>' +
    'Moteur : fichiers DLL/SFS propres à ' + (version == '408' ? '4.08m' : version) + '<br>' +
    'Profil : il2fb.exe + files.SFS correspondants<br>' +
    'Données : air.ini et stationary.ini compatibles<br>' +
    'Chargeur de mods : ' + wrapper + ' · ' + archives + '<br>' + hud;
}

function applyProfile() {
  var profile = profileNumber();
  if (!profile || !fso.FileExists(bat)) {
    showResult(false, 'Le switcher ou la configuration sélectionnée est invalide.');
    return;
  }
  var hud = selected('mode') == 'original' ? 'standard' : selected('hud');
  document.getElementById('apply').disabled = true;
  document.getElementById('apply').innerText = 'Vérification...';
  setTimeout(function () { runSwitch(profile, hud); }, 50);
}

function runSwitch(profile, hud) {
  var log = fso.BuildPath(fso.GetSpecialFolder(2), 'OpenSturmovikSwitcher-' + new Date().getTime() + '.log');
  var command = 'cmd.exe /D /C ""' + bat + '" --apply ' + profile + ' ' + hud + ' > "' + log + '" 2>&1"';
  var code;
  try { code = shell.Run(command, 0, true); }
  catch (error) { showResult(false, 'Impossible d’exécuter le switcher : ' + error.message); return; }
  var text = '';
  if (fso.FileExists(log)) {
    var stream = fso.OpenTextFile(log, 1, false, -2);
    text = stream.ReadAll(); stream.Close();
    try { fso.DeleteFile(log, true); } catch (ignore) {}
  }
  showResult(code === 0, text || ('Le switcher a retourné le code ' + code + '.'));
}

function showResult(ok, text) {
  document.getElementById('form').style.display = 'none';
  document.getElementById('result').style.display = 'block';
  var title = document.getElementById('statusTitle');
  title.className = ok ? 'ok' : 'error';
  title.innerText = ok ? 'Configuration installée' : 'Le changement a échoué';
  document.getElementById('log').innerText = text;
}

function showCredits() {
  if (document.getElementById('apply').disabled) return;
  document.getElementById('form').style.display = 'none';
  document.getElementById('creditsPage').style.display = 'block';
  document.getElementById('pageCaption').innerText = 'Credits';
  document.getElementById('creditsScroll').focus();
}

function closeCredits() {
  document.getElementById('creditsPage').style.display = 'none';
  document.getElementById('form').style.display = 'block';
  document.getElementById('pageCaption').innerText = 'S\u00e9lecteur de version';
  document.getElementById('creditsButton').focus();
}

function jumpToCreditSection(value) {
  var scroll = document.getElementById('creditsScroll');
  var section = document.getElementById(value);
  scroll.scrollTop = section ? Math.max(0, section.offsetTop - 12) : 0;
  scroll.focus();
}

function openCreditLink(url) {
  if (!/^https?:\/\/[a-z0-9.-]+(?::[0-9]+)?\/[^\s<>"']*$/i.test(url)) return false;
  try { shell.Run(url, 1, false); }
  catch (error) { alert('Impossible d\u2019ouvrir cette source dans le navigateur.'); }
  return false;
}

function handlePageKey(event) {
  if (event.keyCode == 27 && document.getElementById('creditsPage').style.display == 'block') {
    closeCredits();
    return false;
  }
  return true;
}

function backToForm() {
  document.getElementById('result').style.display = 'none';
  document.getElementById('form').style.display = 'block';
  document.getElementById('apply').disabled = false;
  document.getElementById('apply').innerText = 'Appliquer';
  restoreState(); updateSelection();
}
</script>
</head>
<body onload="init()" onunload="cleanupGuiSource()" onkeydown="return handlePageKey(event)">
<div class="titlebar"><div class="caption" id="pageCaption">Sélecteur de version</div><div class="pilot">Open Sturmovik v1.15 · Made by Alfly</div></div>
<div class="panel">
  <span class="bolt tl"></span><span class="bolt tm"></span><span class="bolt tr"></span>
  <span class="bolt ml"></span><span class="bolt mr"></span>
  <span class="bolt bl"></span><span class="bolt bm"></span><span class="bolt br"></span>
  <span class="bolt tq"></span><span class="bolt tq3"></span><span class="bolt bq"></span><span class="bolt bq3"></span>
  <span class="bolt lq"></span><span class="bolt lq3"></span><span class="bolt rq"></span><span class="bolt rq3"></span>
  <div id="form">
    <div class="column left">
      <div class="heading">Version du jeu</div>
      <label class="choice"><input type="radio" name="version" value="408" onclick="updateSelection()" /><span class="lamp"></span><span class="name">4.08m</span><span class="detail">Version complète 4.08m</span></label>
      <label class="choice"><input type="radio" name="version" value="409b" onclick="updateSelection()" /><span class="lamp"></span><span class="name">4.09b</span><span class="detail">Version bêta historique</span></label>
      <label class="choice"><input type="radio" name="version" value="409m" onclick="updateSelection()" checked="checked" /><span class="lamp"></span><span class="name">4.09m</span><span class="detail">Version finale recommandée</span></label>
      <div class="heading hudheading">Affichage HUD</div>
      <div class="hudrow">
        <label class="choice"><input type="radio" name="hud" value="standard" onclick="updateSelection()" checked="checked" /><span class="lamp"></span><span class="name">Standard</span></label>
        <label class="choice" id="hudImmersionChoice"><input id="hudImmersion" type="radio" name="hud" value="immersion" onclick="updateSelection()" /><span class="lamp"></span><span class="name">Immersion</span></label>
      </div>
    </div>
    <div class="column right">
      <div class="heading">Mode de jeu</div>
      <label class="choice"><input type="radio" name="mode" value="original" onclick="updateSelection()" /><span class="lamp"></span><span class="name">Jeu stock</span><span class="detail">Fichiers d’origine, mods désactivés</span></label>
      <label class="choice"><input type="radio" name="mode" value="standard" onclick="updateSelection()" checked="checked" /><span class="lamp"></span><span class="name">Sans 6DOF</span><span class="detail">Open Sturmovik, vue standard</span></label>
      <label class="choice"><input type="radio" name="mode" value="sixdof" onclick="updateSelection()" /><span class="lamp"></span><span class="name">Avec 6DOF</span><span class="detail">Open Sturmovik, suivi de tête 6 axes</span></label>
      
      <div class="summary" id="summary"></div>
      <div class="current" id="current">Choisissez la version et le mode de jeu.</div>
    </div>
    <div class="actions">
      <button class="button quit" onclick="window.close()"><span class="bulb"></span>Quitter</button>
      <button class="button credits" id="creditsButton" onclick="showCredits()">Credits</button>
      <button class="button apply" id="apply" onclick="applyProfile()"><span class="bulb"></span>Appliquer</button>
    </div>
  </div>
  <div id="creditsPage" role="region" aria-labelledby="creditsTitle">
    <h1 id="creditsTitle"><!-- BEGIN GENERATED CREDITS TITLE -->
Cr&#233;dits &#8212; Open Sturmovik
<!-- END GENERATED CREDITS TITLE --></h1>
    <select id="creditsJump" title="Aller directement &agrave; une rubrique" aria-label="Rubrique des cr&eacute;dits" onchange="jumpToCreditSection(this.value)">
      <option value="">Toutes les contributions</option>
<!-- BEGIN GENERATED CREDITS NAVIGATION -->
<option value="credits-section-1">Mods et contributions</option>
<option value="credits-section-2">B-29 Silverplate</option>
<option value="credits-section-3">Cartes et textures</option>
<option value="credits-section-4">Campagnes fournies</option>
<option value="credits-section-5">Variantes et outils fournis</option>
<option value="credits-section-6">Attributions compl&#233;mentaires</option>
<option value="credits-section-7">Inventaire en cours</option>
<!-- END GENERATED CREDITS NAVIGATION -->
    </select>
    <div id="creditsScroll" tabindex="0" role="region" aria-label="Liste des cr&eacute;dits">
<!-- BEGIN GENERATED CREDITS CONTENT -->
<p><strong>par la communaut&#233;, pour la communaut&#233;</strong></p>
<p>Open Sturmovik r&#233;unit des cr&#233;ations de la communaut&#233; IL-2 1946. Merci aux auteurs et aux &#233;quipes des mods dont les travaux contribuent au pack.</p>
<p>Liste en cours pour la v1.15, enrichie par le scan des dossiers du jeu et la comparaison aux sources locales. Les contributions et options ci-dessous sont fournies par le pack ; leur pr&#233;sence ne signifie pas qu&#8217;elles sont toutes s&#233;lectionn&#233;es dans chaque profil.</p>
<div class="credits-section" id="credits-section-1">
<h2>Mods et contributions</h2>
<table class="credits-table cols-3">
<thead><tr><th scope="col">Mod</th><th scope="col">Auteur ou collectif</th><th scope="col">Contribution au pack</th></tr></thead>
<tbody>
<tr><td>Am&#233;liorations issues du forum All Aircraft Arcade (AAA)</td><td class="credits-author">Auteurs et contributeurs du forum AAA</td><td>Plusieurs am&#233;liorations d&#8217;Open Sturmovik proviennent des cr&#233;ations partag&#233;es sur ce forum.</td></tr>
<tr><td>Zuti Moving Dogfight Server 1.13</td><td class="credits-author">|ZUTI|</td><td>Fonctions MDS et gestion des missions.</td></tr>
<tr><td>Advanced Engine Management &#8212; AOC 1a</td><td class="credits-author">II/JG51-Lutz</td><td>Gestion avanc&#233;e des moteurs.</td></tr>
<tr><td>Tiger33 Ultimate Sound Mod V3</td><td class="credits-author">Tiger33</td><td>S&#233;lection de sons et de r&#233;glages de d&#233;marrage des moteurs.</td></tr>
<tr><td>WxTech clouds Jan 2023</td><td class="credits-author">WxTech</td><td>Ressources visuelles des nuages. <a href="https://www.sas1946.com/main/index.php?topic=70195.0" onclick="return openCreditLink(this.href)">Publication du mod</a>.</td></tr>
<tr><td>Cockpit CW-21 pour 4.09</td><td class="credits-author">Epervier &#8212; conversion pour Rebels 409 ; Team Daidalos &#8212; cr&#233;dits du cockpit</td><td>Cockpit du CW-21 adapt&#233; &#224; la base 4.09.</td></tr>
<tr><td>Magister &#8212; mod&#232;le ext&#233;rieur</td><td class="credits-author">RAF_Magpie</td><td>&#201;l&#233;ment du mod&#232;le ext&#233;rieur retrouv&#233; &#224; l&#8217;identique ; <span class="credits-reference" title="Documentation : ../../docs/SCAN_PACKS_CREDITS_V1.15.md">source et p&#233;rim&#232;tre confirm&#233;</span>.</td></tr>
<tr><td>B-29 Silverplate 1.2, Little Boy et Fat Man</td><td class="credits-author">Auteurs et &#233;quipe d&#233;taill&#233;s ci-dessous</td><td>B-29 Silverplate, cockpit et ressources des bombes, avec adaptations pour Open Sturmovik.</td></tr>
<tr><td>6DOF Tracker 2.0</td><td class="credits-author">sHr</td><td>D&#233;placement du point de vue dans les profils 6DOF du switcher ; attribution aussi reprise dans les <a href="https://mail.mission4today.com/index.php?file=viewtopic&amp;finish=15&amp;name=ForumsPro&amp;start=0&amp;t=7663" onclick="return openCreditLink(this.href)">notes HSFX v4</a>.</td></tr>
</tbody></table>
<p>La <span class="credits-reference" title="Documentation : Zuti MDS 1.13/Lisez-moi - Zuti MDS 1.13.txt">notice originale de Zuti</span> mentionne aussi <strong>Certificates AI mod 3.0</strong> et <strong>Fireballs Carrier Takeoff mod 5.3.x</strong> parmi les mods incorpor&#233;s &#224; MDS. Ces noms sont repris de la notice ; leurs attributions individuelles restent &#224; compl&#233;ter.</p>
</div>
<div class="credits-section" id="credits-section-2">
<h2>B-29 Silverplate</h2>
<p>Cr&#233;dits du paquet d&#x27;origine : <strong>1C/Maddox, O_Magpie, Fireball, SAS~Cirx, MrJolly, Lt.Wolf, Fat Duck, VC-81_BOLTER, O_Leigh, Max_Thehitman, Ranwers, Wolfighter et Twister</strong>. <a href="https://www.sas1946.com/main/index.php?topic=7894.0" onclick="return openCreditLink(this.href)">Publication et cr&#233;dits du mod Silverplate</a>.</p>
</div>
<div class="credits-section" id="credits-section-3">
<h2>Cartes et textures</h2>
<table class="credits-table cols-3">
<thead><tr><th scope="col">Carte ou contribution</th><th scope="col">Auteurs</th><th scope="col">Notice conserv&#233;e</th></tr></thead>
<tbody>
<tr><td>Ukraine, &#233;t&#233; et hiver</td><td class="credits-author">Autopilot</td><td><span class="credits-reference" title="Documentation : ../Maps/AP_Ukraine/Lisez-moi - Ukraine beta ete et hiver.txt">Notice</span></td></tr>
<tr><td>B29 Alley</td><td class="credits-author">delvpier</td><td><span class="credits-reference" title="Documentation : ../Maps/B29_Alley/Lisez-moi - installation.txt">Notice</span></td></tr>
<tr><td>Bessarabia &#8212; repeuplement</td><td class="credits-author">Zipzapp ; Fly_zo pour l&#8217;installateur historique</td><td><span class="credits-reference" title="Documentation : ../Maps/Bessarabia/Lisez-moi - repeuplement par Zipzapp.txt">Notice</span></td></tr>
<tr><td>Guadalcanal, septembre 1942</td><td class="credits-author">Marco</td><td><span class="credits-reference" title="Documentation : ../Maps/guadal/Lisez-moi - Guadalcanal septembre 1942 version 1-2.txt">Notice</span></td></tr>
<tr><td>Channel &#8212; petite carte Kt_channel</td><td class="credits-author">Kapteeni</td><td><span class="credits-reference" title="Documentation : ../Maps/Kt_channel/Lisez-moi - Channel.txt">Notice</span></td></tr>
<tr><td>Eastafrica</td><td class="credits-author">Kapteeni ; Fly_zo pour le correctif</td><td><span class="credits-reference" title="Documentation : ../Maps/Kt_eastafrica/Lisez-moi - Eastafrica beta 0.91.txt">Notice</span></td></tr>
<tr><td>Lybia N-E / Tobruk</td><td class="credits-author">BADA</td><td><span class="credits-reference" title="Documentation : ../Maps/Lybia_N-E/Lisez-moi - Lybia N-E alpha 1.3.txt">Notice</span></td></tr>
<tr><td>BP Midway et eau du Pacifique</td><td class="credits-author">Boosher &#8212; carte ; panzerkeil &#8212; objets statiques ; Viking &#8212; couleur de l&#8217;eau</td><td><span class="credits-reference" title="Documentation : ../Maps/midway/Lisez-moi - eau du Pacifique pour BP Midway.txt">Notice</span></td></tr>
<tr><td>Darwin Small</td><td class="credits-author">Neil Lowe</td><td><span class="credits-reference" title="Documentation : ../Maps/NTL_Darwin_Small/Lisez-moi - Darwin Small 1.1.txt">Notice</span></td></tr>
<tr><td>Alpen</td><td class="credits-author">Zipzapp ; JV69_BADA &#8212; a&#233;rodromes ; Lowfighter &#8212; ch&#226;teaux suisses</td><td><span class="credits-reference" title="Documentation : ../Maps/zip_Alpen/Lisez-moi - Alpen beta 2.txt">Notice</span></td></tr>
<tr><td>Alpen &#8212; textures fsmd_mount3 et champs Bob</td><td class="credits-author">Phasmid &#8212; relief ; Rus_Andrey &#8212; champs</td><td><span class="credits-reference" title="Documentation : ../Maps/zip_Alpen/Lisez-moi - Alpen beta 2.txt">Notice</span></td></tr>
<tr><td>Mbug Slovakia winter</td><td class="credits-author">may-bug &#8212; adaptation hivernale ; Slovakia Team &#8212; carte d&#8217;origine</td><td><span class="credits-reference" title="Documentation : ../../docs/SCAN_CARTES_CREDITS_V1.15.md">Preuves et version adapt&#233;e</span></td></tr>
</tbody></table>
<p>Les cr&#233;dits portent sur les contributions indiqu&#233;es. Ils ne remplacent pas ceux des cartes d&#8217;origine ni ceux des autres &#233;l&#233;ments utilis&#233;s.</p>
</div>
<div class="credits-section" id="credits-section-4">
<h2>Campagnes fournies</h2>
<table class="credits-table cols-2">
<thead><tr><th scope="col">Campagne</th><th scope="col">Auteur</th></tr></thead>
<tbody>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Baltic Sparrows 1946/Lisez-moi - Baltic Sparrows 1946.txt">Baltic Sparrows 1946</span></td><td class="credits-author">Eldon45</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Schlageter 43/Lisez-moi - Schlageter 43.txt">Schlageter 43</span></td><td class="credits-author">mandrill7</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Wunderbomber/Lisez-moi - Wunderbomber.txt">Wunderbomber</span></td><td class="credits-author">Kernow</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Kilroy/Lisez-moi - Kilroy - version moddee.txt">Kilroy</span></td><td class="credits-author">Bowie</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Straight Down/Lisez-moi - Straight Down.txt">Straight Down</span></td><td class="credits-author">Zeus-cat</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Two Little DUCs/Lisez-moi - Two Little DUCs.htm">Two Little DUCs</span></td><td class="credits-author">Extreme_One</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Wings over Waves/Version - Kuro Yuri IJ1.txt">Wings over Waves - Kuro Yuri</span></td><td class="credits-author">PlusWave Expansions / MDi Design GmbH</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Wings over Waves/Version - Koryo IJ2.txt">Wings over Waves - Koryo</span></td><td class="credits-author">PlusWave Expansions / MDi Design GmbH</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Wings over Waves/Version - Archer US2.txt">Wings over Waves - Archer</span></td><td class="credits-author">PlusWave Expansions / MDi Design GmbH</td></tr>
<tr><td><span class="credits-reference" title="Documentation : ../Campaigns/Wings over Waves/Version - Catball US1.txt">Wings over Waves - Catball</span></td><td class="credits-author">PlusWave Expansions / MDi Design GmbH</td></tr>
</tbody></table>
</div>
<div class="credits-section" id="credits-section-5">
<h2>Variantes et outils fournis</h2>
<table class="credits-table cols-3">
<thead><tr><th scope="col">Mod ou outil</th><th scope="col">Auteur</th><th scope="col">Contribution</th></tr></thead>
<tbody>
<tr><td>Viseurs Schr&#228;ge Musik du Bf-110G</td><td class="credits-author">magot</td><td>Variantes de r&#233;ticules fournies.</td></tr>
<tr><td>Gamma Panel</td><td class="credits-author">Tomasz Porosi&#324;ski</td><td>R&#233;glage optionnel du gamma.</td></tr>
<tr><td>Bombsight Table 2</td><td class="credits-author">WT_Pedropan ; WT_Pitr</td><td>Outil de calcul pour le bombardement.</td></tr>
<tr><td>HardBall Aircraft Viewer 4.08</td><td class="credits-author">Matt &#171; HardBall &#187; Henderson</td><td>Consultation des caract&#233;ristiques des avions.</td></tr>
<tr><td>IL2 Sticks</td><td class="credits-author">FoolTrottel</td><td>Configuration des commandes.</td></tr>
<tr><td>IL2 JoyControl</td><td class="credits-author">Oleg_BS</td><td>R&#233;glage des commandes.</td></tr>
<tr><td>Mission Mate 6</td><td class="credits-author">CrazySchmidt ; Barbs</td><td>Pr&#233;paration de missions.</td></tr>
<tr><td>Quick Mission Tuner 1946</td><td class="credits-author">DiverseWare</td><td>Modification de missions.</td></tr>
<tr><td>Properties Editor et Difficulty Editor</td><td class="credits-author">MadBran</td><td>Outils auxiliaires de Quick Mission Tuner.</td></tr>
<tr><td>Shift-Rot</td><td class="credits-author">Antonio M.</td><td>Outil auxiliaire de Quick Mission Tuner.</td></tr>
</tbody></table>
<p>Les versions, les notices et les limites de ces options sont relev&#233;es dans <span class="credits-reference" title="Documentation : ../../docs/SCAN_OPTIONS_CREDITS_V1.15.md">l&#8217;inventaire des outils</span>.</p>
</div>
<div class="credits-section" id="credits-section-6">
<h2>Attributions compl&#233;mentaires</h2>
<p><strong>BombBayDoors Plus 2.5.3 &#8212; Zuti et Fireball.</strong> Attribution retrouv&#233;e dans une notice du pack BAT. La version exacte du code pr&#233;sent dans Open Sturmovik reste &#224; pr&#233;ciser ; <span class="credits-reference" title="Documentation : ../../docs/SCAN_PACKS_CREDITS_V1.15.md">la source et les correspondances sont conserv&#233;es ici</span>.</p>
</div>
<div class="credits-section" id="credits-section-7">
<h2>Inventaire en cours</h2>
<p>Le <span class="credits-reference" title="Documentation : ../../docs/SCAN_MODS_V1.15.md">scan des dossiers et des ressources</span> conserve les noms des 130 modules compar&#233;s, leurs correspondances et les fichiers restant &#224; attribuer. Le <span class="credits-reference" title="Documentation : ../../docs/SCAN_PACKS_CREDITS_V1.15.md">relev&#233; des packs locaux examin&#233;s</span> compl&#232;te ces recherches. La liste sera enrichie avec les auteurs des autres ressources effectivement int&#233;gr&#233;es. L&#x27;attribution des &#233;l&#233;ments h&#233;rit&#233;s de RMP3 Atmosphere et de WindConfig v3 reste notamment &#224; pr&#233;ciser.</p>
<p>Les sources, les limites des int&#233;grations partielles et les points &#224; v&#233;rifier sont consign&#233;s dans <span class="credits-reference" title="Documentation : ../../docs/CREDITS_MODS.md">l&#x27;inventaire d&#233;taill&#233; des mods</span>.</p>
</div>
<!-- END GENERATED CREDITS CONTENT -->
    </div>
    <div class="actions">
      <span class="credits-hint">Merci &agrave; la communaut&eacute; IL-2 1946.</span>
      <button class="button apply" id="creditsBack" onclick="closeCredits()"><span class="bulb"></span>Retour</button>
    </div>
  </div>
  <div id="result">
    <div id="statusTitle"></div><div id="log"></div>
    <div class="actions"><button class="button quit" onclick="window.close()"><span class="bulb"></span>Quitter</button><button class="button apply" onclick="backToForm()"><span class="bulb"></span>Retour</button></div>
  </div>
</div>
</body>
</html>
