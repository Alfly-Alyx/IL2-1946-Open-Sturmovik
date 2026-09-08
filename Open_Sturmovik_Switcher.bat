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
    set "FILES_HASH=7F872ADAB1845E2837A2EE43FD378372B9DBAF01819C8F3BA7413B04BEFEAFD0"
)
if "%PROFILE%"=="2" (
    set "LABEL=4.08m Open Sturmovik sans 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.08m"
    set "PAYLOAD_ID=408"
    set "PROFILE_FOLDER=4.08 Mod ON (NO 6DOF)"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3"
    set "FILES_HASH=D8A7DAD54CBA505B5E7B2C394491701A705A86D20091D3746F399D8A08049986"
)
if "%PROFILE%"=="3" (
    set "LABEL=4.08m Open Sturmovik avec 6DOF"
    set "VERSION=4.08m"
    set "PAYLOAD=4.08m"
    set "PAYLOAD_ID=408"
    set "PROFILE_FOLDER=4.08 Mods 6DOF ON"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=F43C999779B599102146A19E644DF7B56E20A5995E3D060C7D80C958BCDD845E"
    set "FILES_HASH=D8A7DAD54CBA505B5E7B2C394491701A705A86D20091D3746F399D8A08049986"
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
    set "FILES_HASH=DD9A1C7CFD51533560FC349A5B09DE360126F733FB2765F099A01CE6B178CFA8"
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
    set "EXE_HASH=70B3F84EDD111921B93CDFD720D6394764DD7C40249D0CD3617B18A7A3F990D3"
    set "FILES_HASH=99CF133FA20A1A117C60E85D510E443693AB15B860314CAE02684069D3C79D17"
)
if "%PROFILE%"=="6" (
    set "LABEL=4.09b Open Sturmovik avec 6DOF"
    set "VERSION=4.09b"
    set "PAYLOAD=4.09b"
    set "PAYLOAD_ID=409b"
    set "PROFILE_FOLDER=4.09 Mods 6DOF ON"
    set "AIR=409b air.ini\Air.ini\air.ini"
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
more +%SWITCHER_GUI_LINE% "%~f0" > "%SWITCHER_GUI_TEMP%"
if errorlevel 1 (
    echo [ERREUR] Impossible de preparer l'interface graphique.
    exit /b 2
)
copy /Y "%SWITCH_ROOT%\Resources\Open_Sturmovik_Switcher_Original.ico" "%SWITCHER_GUI_ICON_TEMP%" >nul
if errorlevel 1 (
    del /F /Q "%SWITCHER_GUI_TEMP%" >nul 2>&1
    echo [ERREUR] Impossible de preparer l'icone de l'interface.
    exit /b 2
)
start "Open Sturmovik Switcher" mshta.exe "%SWITCHER_GUI_TEMP%"
if errorlevel 1 (
    del /F /Q "%SWITCHER_GUI_TEMP%" >nul 2>&1
    del /F /Q "%SWITCHER_GUI_ICON_TEMP%" >nul 2>&1
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
body { font-family:Arial,Helvetica,sans-serif; font-size:17px; color:#d2d8cf; background:#1d3037 center center no-repeat; background-size:cover; }
.titlebar { position:absolute; left:0; right:0; top:0; height:29px; border:1px solid #172d32; background:rgba(92,114,117,.96); box-shadow:inset 1px 1px 2px #c0ceca,inset -1px -2px 3px #364e53; }
.titlebar .caption { box-sizing:border-box; float:left; width:30%; height:29px; padding:4px 28px; border-right:3px ridge #728785; font-size:16px; font-weight:normal; }
.titlebar .pilot { float:right; margin:4px 28px 0 0; font-size:16px; }
.panel { position:absolute; left:50%; top:66px; width:820px; height:598px; margin-left:-414px; border:4px solid #15363b; border-radius:6px; background:rgba(38,72,79,.84); background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI2IiBoZWlnaHQ9IjYiPjxwYXRoIGQ9Ik0tMSAxbDItMk0wIDZsNi02TTUgN2wyLTIiIHN0cm9rZT0iI2QyZGNjZSIgc3Ryb2tlLW9wYWNpdHk9Ii4wMzUiLz48cGF0aCBkPSJNLTEgNWwyIDJNMCAwbDYgNk01LTFsMiAyIiBzdHJva2U9IiMwOTFiMjAiIHN0cm9rZS1vcGFjaXR5PSIuMDYiLz48L3N2Zz4="); box-shadow:inset 2px 2px 3px #638489,inset -2px -2px 3px #061f27,0 2px 3px #0e1c23; }
.bolt { position:absolute; width:12px; height:12px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMiIgaGVpZ2h0PSIxMiI+PGRlZnM+PGxpbmVhckdyYWRpZW50IGlkPSJtIiB4Mj0iMSIgeTI9IjEiPjxzdG9wIHN0b3AtY29sb3I9IiNkNmQ1YWUiLz48c3RvcCBvZmZzZXQ9Ii40IiBzdG9wLWNvbG9yPSIjODI5MTgxIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMjUzYzM5Ii8+PC9saW5lYXJHcmFkaWVudD48L2RlZnM+PGNpcmNsZSBjeD0iNi41IiBjeT0iNi41IiByPSI0LjgiIGZpbGw9IiMxMTJiMmUiLz48Y2lyY2xlIGN4PSI1LjUiIGN5PSI1LjUiIHI9IjQuMiIgZmlsbD0idXJsKCNtKSIgc3Ryb2tlPSIjNTk3NjZiIiBzdHJva2Utd2lkdGg9Ii42Ii8+PHBhdGggZD0iTTMgOGw1LTUiIHN0cm9rZT0iIzIzM2IzNSIgc3Ryb2tlLXdpZHRoPSIxLjEiLz48cGF0aCBkPSJNMy42IDguNGw1LTUiIHN0cm9rZT0iI2NlZDJiMiIgc3Ryb2tlLXdpZHRoPSIuNiIvPjwvc3ZnPg==") center center no-repeat; }
.tl{left:4px;top:4px}.tr{right:4px;top:4px}.bl{left:4px;bottom:4px}.br{right:4px;bottom:4px}
.tm{left:50%;top:4px;margin-left:-6px}.bm{left:50%;bottom:4px;margin-left:-6px}.ml{left:4px;top:50%;margin-top:-6px}.mr{right:4px;top:50%;margin-top:-6px}
.tq{left:25%;top:4px}.tq3{left:75%;top:4px}.bq{left:25%;bottom:4px}.bq3{left:75%;bottom:4px}.lq{left:4px;top:25%}.lq3{left:4px;top:75%}.rq{right:4px;top:25%}.rq3{right:4px;top:75%}
.column { position:absolute; top:29px; bottom:112px; box-sizing:border-box; }
.left { left:30px; width:380px; padding-right:25px; border-right:1px solid #b5c8c2; box-shadow:1px 0 #4b6567; }
.right { right:30px; width:354px; }
.heading { margin:0 0 12px; padding:8px 14px; color:#d7ddd4; font-size:17px; line-height:24px; font-weight:normal; border:2px solid #6b7564; border-radius:3px; background:rgba(10,22,24,.84); box-shadow:inset 1px 1px #b5b399,inset -1px -1px #263a35; text-align:center; }
.choice { display:block; position:relative; height:52px; margin:2px 0; cursor:pointer; }
.choice input { position:absolute; left:11px; top:15px; width:27px; height:27px; margin:0; opacity:0; filter:alpha(opacity=0); }
.lamp { position:absolute; left:3px; top:7px; width:44px; height:44px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg==") no-repeat; }
.choice input:checked + .lamp, .choice:hover .lamp { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNjMWVjNTkiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzIxYjkxYiIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMTU0NjE3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.choice .name { position:absolute; left:64px; top:18px; font-size:18px; font-weight:normal; color:#d6ddd3; }
.choice input:checked ~ .name { color:#f0f3e4; }
.choice input:focus ~ .name { outline:1px dotted #dfdfc0; outline-offset:4px; }
.choice .detail { display:none; }
.choice.disabled { cursor:default; opacity:.45; }
.choice.disabled:hover .lamp { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.hudrow { height:53px; margin-top:4px; }
.hudrow .choice { display:inline-block; width:170px; height:51px; margin:0; vertical-align:top; }
.hudrow .choice .lamp { left:1px; top:3px; }
.hudrow .choice .name { left:52px; top:16px; font-size:16px; }
.hudheading { margin-top:14px; padding:8px 0 0; border:0; border-top:1px solid #b5c8c2; border-radius:0; background:none; box-shadow:inset 0 1px #4b6567; text-align:left; }
.summary { box-sizing:border-box; height:128px; margin-top:18px; padding:10px 12px; border:1px solid #a8b6a6; background:rgba(15,33,37,.55); box-shadow:inset 1px 1px 2px #183335,1px 1px #223b3c; color:#cad5cb; font-size:11px; line-height:17px; }
.summary strong { font-weight:normal; color:#eff0d7; font-size:12px; }
.current { box-sizing:border-box; margin-top:16px; min-height:60px; padding:10px 13px; border:2px solid #677567; border-radius:3px; background:rgba(12,25,26,.86); box-shadow:inset 1px 1px #a8b09b,inset -1px -1px #253c35; color:#d7dfd3; font-size:14px; line-height:19px; }
.actions { position:absolute; left:30px; right:30px; bottom:28px; height:52px; padding-top:18px; border-top:1px solid #b5c8c2; box-shadow:inset 0 1px #4b6567; }
.button { position:relative; box-sizing:border-box; height:46px; min-width:154px; margin:0 0 0 56px; padding:0 16px; border:2px solid #a9bcb6; border-radius:5px; color:#dfe5da; background:transparent; font:18px Arial,Helvetica,sans-serif; text-align:left; cursor:pointer; box-shadow:inset 1px 1px #d2d7c6,inset -1px -1px #526b64; }
.button .bulb { display:none; }
.button:before { content:""; position:absolute; left:-55px; top:0; width:44px; height:44px; background:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg==") no-repeat; }
.button.quit { background:#9b3025; }
.button.quit:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNmZmE3NzMiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iI2QzMWExMCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjNjYxNzE0Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button.apply { float:right; min-width:144px; margin-right:0; border-color:transparent; border-radius:0; box-shadow:none; }
.button.apply:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNkOGEzM2IiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzc4NTIwZCIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMjMxNzBiIi8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button.apply:hover:before, .button.apply:focus:before { background-image:url("data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI0NCIgaGVpZ2h0PSI0NCIgdmlld0JveD0iMCAwIDQ0IDQ0Ij48ZGVmcz48bGluZWFyR3JhZGllbnQgaWQ9Im1ldGFsIiB4MT0iMCIgeTE9IjAiIHgyPSIxIiB5Mj0iMSI+PHN0b3Agc3RvcC1jb2xvcj0iI2YwZjBkZSIvPjxzdG9wIG9mZnNldD0iLjI1IiBzdG9wLWNvbG9yPSIjYzdjZWJmIi8+PHN0b3Agb2Zmc2V0PSIuNDMiIHN0b3AtY29sb3I9IiM2Zjg0N2UiLz48c3RvcCBvZmZzZXQ9Ii42NyIgc3RvcC1jb2xvcj0iI2E5YjZhOCIvPjxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iIzNhNDk0NyIvPjwvbGluZWFyR3JhZGllbnQ+PHJhZGlhbEdyYWRpZW50IGlkPSJnbGFzcyIgY3g9Ii4zOCIgY3k9Ii4zIiByPSIuNzIiPjxzdG9wIHN0b3AtY29sb3I9IiNjMWVjNTkiLz48c3RvcCBvZmZzZXQ9Ii4zNiIgc3RvcC1jb2xvcj0iIzIxYjkxYiIvPjxzdG9wIG9mZnNldD0iLjc5IiBzdG9wLWNvbG9yPSIjMTU0NjE3Ii8+PHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAxNjEzIi8+PC9yYWRpYWxHcmFkaWVudD48L2RlZnM+PGVsbGlwc2UgY3g9IjI1IiBjeT0iMjciIHJ4PSIxNyIgcnk9IjE1IiBmaWxsPSIjMDcxMDE1IiBvcGFjaXR5PSIuNiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjE3IiBmaWxsPSIjMmMzZDNjIiBzdHJva2U9IiMyODM3MzUiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxNiIgZmlsbD0idXJsKCNtZXRhbCkiLz48Y2lyY2xlIGN4PSIyMCIgY3k9IjIwIiByPSIxMiIgZmlsbD0iIzc3ODU3ZSIgc3Ryb2tlPSIjZDNkOWNhIiBzdHJva2Utd2lkdGg9Ii42Ii8+PGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMTAuNSIgZmlsbD0iIzE1MjUxZiIvPjxjaXJjbGUgY3g9IjIwIiBjeT0iMjAiIHI9IjkuNSIgZmlsbD0idXJsKCNnbGFzcykiLz48ZWxsaXBzZSBjeD0iMTYuNSIgY3k9IjE1IiByeD0iMy41IiByeT0iMi40IiBmaWxsPSIjZmZmZGU4IiBvcGFjaXR5PSIuOTIiLz48Y2lyY2xlIGN4PSIyMi41IiBjeT0iMjUuNSIgcj0iMS41IiBmaWxsPSIjZTBjYzc5IiBvcGFjaXR5PSIuMzUiLz48cGF0aCBkPSJNOSAxMmwyIDFNMzEgMjVsMiAxTTE0IDMzbDEtMiIgc3Ryb2tlPSIjNGI1YjU2IiBzdHJva2Utd2lkdGg9IjEuMiIvPjwvc3ZnPg=="); }
.button:hover, .button:focus { color:#fffde5; outline:1px dotted #dddcc3; outline-offset:3px; }
.button.quit:hover { background:#b43c2d; }
.button:active { top:1px; }
.button:disabled { color:#8da097; cursor:default; opacity:.6; outline:0; }
#result { display:none; position:absolute; left:30px; right:30px; top:29px; bottom:28px; }
#statusTitle { margin:0 0 22px; padding:15px; border:2px solid #899681; border-radius:3px; background:rgba(11,25,26,.86); font-size:21px; font-weight:normal; text-align:center; }
#log { box-sizing:border-box; height:359px; overflow:auto; padding:16px; border:1px solid #a8b6a6; background:rgba(12,26,28,.82); color:#d9e0d4; font:13px/20px Consolas,monospace; white-space:pre-wrap; word-wrap:break-word; }
#result .actions { left:0; right:0; bottom:0; }
.ok { color:#bbdf9d; }.error { color:#ffb49a; }
@media screen and (max-height:700px) { .panel { top:44px; height:calc(100% - 62px); min-height:565px; } .column { top:24px; } }
</style>
<script language="javascript">
var fso, shell, root, bat, switchRoot, guiTemp, guiIconTemp;

function init() {
  window.resizeTo(1000, 760);
  window.moveTo((screen.availWidth - 1000) / 2, (screen.availHeight - 760) / 2);
  fso = new ActiveXObject('Scripting.FileSystemObject');
  shell = new ActiveXObject('WScript.Shell');
  bat = shell.Environment('PROCESS').Item('OPEN_STURMOVIK_SWITCHER_BAT');
  guiTemp = shell.Environment('PROCESS').Item('SWITCHER_GUI_TEMP');
  guiIconTemp = shell.Environment('PROCESS').Item('SWITCHER_GUI_ICON_TEMP');
  root = fso.GetParentFolderName(bat);
  switchRoot = fso.BuildPath(root, '_Game Switcher');
  var resources = fso.BuildPath(switchRoot, 'Resources');
  var background = fso.BuildPath(resources, 'Open_Sturmovik_Switcher_Background.jpg');
  if (fso.FileExists(background)) document.body.style.backgroundImage = 'url("file:///' + background.replace(/\\/g, '/') + '")';
  restoreState();
  updateSelection();
  setTimeout(cleanupGuiSource, 750);
}

function cleanupGuiSource() {
  if (!guiTemp) return;
  try { if (fso.FileExists(guiTemp)) fso.DeleteFile(guiTemp, true); } catch (ignore) {}
  try { if (guiIconTemp && fso.FileExists(guiIconTemp)) fso.DeleteFile(guiIconTemp, true); } catch (ignore) {}
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

function backToForm() {
  document.getElementById('result').style.display = 'none';
  document.getElementById('form').style.display = 'block';
  document.getElementById('apply').disabled = false;
  document.getElementById('apply').innerText = 'Appliquer';
  restoreState(); updateSelection();
}
</script>
</head>
<body onload="init()" onunload="cleanupGuiSource()">
<div class="titlebar"><div class="caption">Sélecteur de version</div><div class="pilot">Open Sturmovik v1.15 · Made by Alfly</div></div>
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
      <button class="button apply" id="apply" onclick="applyProfile()"><span class="bulb"></span>Appliquer</button>
    </div>
  </div>
  <div id="result">
    <div id="statusTitle"></div><div id="log"></div>
    <div class="actions"><button class="button quit" onclick="window.close()"><span class="bulb"></span>Quitter</button><button class="button apply" onclick="backToForm()"><span class="bulb"></span>Retour</button></div>
  </div>
</div>
</body>
</html>
