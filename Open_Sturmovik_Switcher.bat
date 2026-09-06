@echo off
setlocal EnableExtensions EnableDelayedExpansion
if defined OS_SWITCHER_DEBUG echo on
title IL-2 Open Sturmovik Switcher 1.15

set "ROOT=%~dp0"
set "SWITCH_ROOT=%ROOT%_Game Switchers"
set "GUI=%SWITCH_ROOT%\Open_Sturmovik_Switcher.hta"
set "HASH_CHECK=%SWITCH_ROOT%\Open_Sturmovik_Hash_Check.bat"
set "VALIDATE_ONLY=0"
set "PROFILE="
set "HUD=keep"

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

if not exist "%GUI%" (
    echo [ERREUR] Interface graphique introuvable : "%GUI%"
    exit /b 2
)
start "" mshta.exe "%GUI%"
exit /b 0

:usage
echo Utilisation :
echo   Open_Sturmovik_Switcher.bat
echo   Open_Sturmovik_Switcher.bat --apply 1..9 [keep^|standard^|immersion]
echo   Open_Sturmovik_Switcher.bat --validate 1..9 [keep^|standard^|immersion]
exit /b 2

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
    set "FILES_HASH=7F872ADAB1845E2837A2EE43FD378372B9DBAF01819C8F3BA7413B04BEFEAFD0"
)
if "%PROFILE%"=="2" (
    set "LABEL=4.08m Open Sturmovik sans 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.08 Mod ON (NO 6DOF)"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3"
    set "FILES_HASH=D8A7DAD54CBA505B5E7B2C394491701A705A86D20091D3746F399D8A08049986"
)
if "%PROFILE%"=="3" (
    set "LABEL=4.08m Open Sturmovik avec 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.08 Mods 6DOF ON"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E"
    set "FILES_HASH=D8A7DAD54CBA505B5E7B2C394491701A705A86D20091D3746F399D8A08049986"
)
if "%PROFILE%"=="4" (
    set "LABEL=4.09b Original"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods OFF (Original)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=DD9A1C7CFD51533560FC349A5B09DE360126F733FB2765F099A01CE6B178CFA8"
)
if "%PROFILE%"=="5" (
    set "LABEL=4.09b Open Sturmovik sans 6DOF"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods ON (NO 6DOF)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3"
    set "FILES_HASH=99CF133FA20A1A117C60E85D510E443693AB15B860314CAE02684069D3C79D17"
)
if "%PROFILE%"=="6" (
    set "LABEL=4.09b Open Sturmovik avec 6DOF"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods 6DOF ON"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E"
    set "FILES_HASH=99CF133FA20A1A117C60E85D510E443693AB15B860314CAE02684069D3C79D17"
)
if "%PROFILE%"=="7" (
    set "LABEL=4.09m Original"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09finalModsOFF(Original)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=9F7D136C586EB3FCD258C5C000F34951D410A0236934F22ABA2516637874B095"
)
if "%PROFILE%"=="8" (
    set "LABEL=4.09m Open Sturmovik sans 6DOF"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09finalModsON(No-6DoF)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3"
    set "FILES_HASH=18F3C5471D93642916394DE53B482051106E024DDAC8124C7B0D700D1796B05A"
)
if "%PROFILE%"=="9" (
    set "LABEL=4.09m Open Sturmovik avec 6DOF"
    set "VERSION=4.09m"
    set "PAYLOAD=4.09m"
    set "PAYLOAD_ID=409m"
    set "PROFILE_FOLDER=4.09final_ModsON+6DoF"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E"
    set "FILES_HASH=18F3C5471D93642916394DE53B482051106E024DDAC8124C7B0D700D1796B05A"
)

if not defined VERSION (
    echo [ERREUR] Profil invalide : %PROFILE%
    exit /b 2
)
if not exist "%HASH_CHECK%" (
    echo [ERREUR] Controleur d'empreintes introuvable : "%HASH_CHECK%"
    exit /b 2
)
if /I not "%HUD%"=="keep" if /I not "%HUD%"=="standard" if /I not "%HUD%"=="immersion" (
    echo [ERREUR] Choix HUD invalide : %HUD%
    exit /b 2
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
    exit /b 0
)

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

call :stage "%PROFILE_DIR%\il2fb.exe" "il2fb.exe"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\files.SFS" "files.SFS"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%AIR%" "Files\com\maddox\il2\objects\air.ini"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%STATIONARY%" "Files\com\maddox\il2\objects\stationary.ini"
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

>"%SWITCH_ROOT%\active-profile.txt" (
    echo profile=%PROFILE%
    echo version=%VERSION%
    echo label=%LABEL%
    echo hud=%HUD%
)
rmdir /S /Q "%TX%"
echo [OK] Profil active : %LABEL%
if /I not "%HUD%"=="keep" echo [OK] HUD applique : %HUD%
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
    call :verify "%SWITCH_ROOT%\%AIR%" "B25B048B2FB9D434BC31A47F74430143A169DB1887A2C9B09405F627423197EE" "air.ini 4.08m"
) else (
    call :verify "%SWITCH_ROOT%\%AIR%" "3ABEB3E3EB136AD3C1E1825118D06EA2C293D10F8C7E442BA5A599C8D6AAB508" "air.ini 4.09"
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
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_core.dll" "AE1B06F2D4F6CC14A535FC47DF66D53A3DB1AE2BBA49A20F94BD109A03E6CE9C" "il2_core.dll 4.08m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_corep4.dll" "9D7D89C664D490EDBED97836FA810BB88BBAFA7D37A7B8D1DC76D15050F79A15" "il2_corep4.dll 4.08m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.08m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.08m"
if errorlevel 1 exit /b 1
exit /b 0

:payloadCheck409b
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_3do19.SFS" "F4EBF76EA04511E57D75AC9F7D3E68953A6D85EF5093AFE35486DDBC10D81007" "fb_3do19.SFS 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_maps15.SFS" "35742CA5476DA955C6B544303739F4E3F4BFD54D6EF9505B993BBA4ACC7C2522" "fb_maps15.SFS 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_core.dll" "F8DDE5FC6C10BCA94481875BBAA4DA07F408CD5168E7E7DEECDD0B08C0B1992D" "il2_core.dll 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_corep4.dll" "B5D014D457107EFB86F740055692A5923C0E6A14B4C147CD7965EA007101277B" "il2_corep4.dll 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.09b"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.09b"
if errorlevel 1 exit /b 1
exit /b 0

:payloadCheck409m
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_3do19.SFS" "4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670" "fb_3do19.SFS 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\fb_maps15.SFS" "AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9" "fb_maps15.SFS 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_core.dll" "3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3" "il2_core.dll 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\il2_corep4.dll" "0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979" "il2_corep4.dll 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd.dll" "2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421" "mg_snd.dll 4.09m"
if errorlevel 1 exit /b 1
"%ComSpec%" /D /C call "%HASH_CHECK%" "%PAYLOAD_DIR%\mg_snd_sse.dll" "FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4" "mg_snd_sse.dll 4.09m"
if errorlevel 1 exit /b 1
exit /b 0

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
if "%ROLLBACK_FAILED%"=="1" exit /b 1
exit /b 0
