@echo off
setlocal EnableExtensions EnableDelayedExpansion
if defined OS_SWITCHER_DEBUG echo on
title IL-2 Open Sturmovik Switcher 1.15

set "ROOT=%~dp0"
set "SWITCH_ROOT=%ROOT%_Game Switcher"
set "VALIDATE_ONLY=0"
set "PROFILE="
set "HUD=standard"
set "LANGUAGE=auto"
set "PROGRESS_FILE="

if /I "%~1"=="--apply" (
    set "PROFILE=%~2"
    if not "%~3"=="" set "HUD=%~3"
    if not "%~4"=="" set "LANGUAGE=%~4"
    if /I "%~4"=="--progress" (
        set "LANGUAGE=auto"
        set "PROGRESS_FILE=%~5"
    )
    if /I "%~5"=="--progress" set "PROGRESS_FILE=%~6"
    goto prepare
)
if /I "%~1"=="--validate" (
    set "VALIDATE_ONLY=1"
    set "PROFILE=%~2"
    if not "%~3"=="" set "HUD=%~3"
    if not "%~4"=="" set "LANGUAGE=%~4"
    goto prepare
)
if not "%~1"=="" goto usage
call :openGui
exit /b %ERRORLEVEL%

:usage
echo Utilisation :
echo   Open_Sturmovik_Switcher.bat
echo   Open_Sturmovik_Switcher.bat --apply 1..9 [standard^|immersion] [fr^|us^|ru^|de^|cs^|hu^|pl]
echo   Open_Sturmovik_Switcher.bat --validate 1..9 [standard^|immersion] [fr^|us^|ru^|de^|cs^|hu^|pl]
exit /b 2

:progress
if not defined PROGRESS_FILE exit /b 0
>"%PROGRESS_FILE%.tmp" (
    echo percent=%~1
    echo message=%~2
)
move /Y "%PROGRESS_FILE%.tmp" "%PROGRESS_FILE%" >nul 2>&1
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

:prepare
if "%PROFILE%"=="1" (
    set "LABEL=4.08m Original"
    set "VERSION=4.08m"
    set "VERSION_ID=408"
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
    set "VERSION_ID=408"
    set "PROFILE_FOLDER=4.08 Mods ON (NO 6DOF)"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80"
    set "FILES_HASH=E00F86B80183313B846F72F153A9102A1DC40AFBB90323DE8AC7DE34DED0D5FD"
)
if "%PROFILE%"=="3" (
    set "LABEL=4.08m Open Sturmovik avec 6DOF"
    set "VERSION=4.08m"
    set "VERSION_ID=408"
    set "PROFILE_FOLDER=4.08 Mods ON 6DOF"
    set "AIR=408m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=1"
    set "EXE_HASH=7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21"
    set "FILES_HASH=E00F86B80183313B846F72F153A9102A1DC40AFBB90323DE8AC7DE34DED0D5FD"
)
if "%PROFILE%"=="4" (
    set "LABEL=4.09b Original"
    set "VERSION=4.09b"
    set "VERSION_ID=409b"
    set "PROFILE_FOLDER=4.09b Mods OFF (Original)"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=1"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=9ACE9A542AC7203D8A66961570B6854C11FB0BF721F0234DA9D6095D69D2525C"
    set "FILES_HASH=945443B0A53E7544A674911F9CFDA3122B1A3D95570724754E29A693EC5AD737"
)
if "%PROFILE%"=="5" (
    set "LABEL=4.09b Open Sturmovik sans 6DOF"
    set "VERSION=4.09b"
    set "VERSION_ID=409b"
    set "PROFILE_FOLDER=4.09b Mods ON (NO 6DOF)"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80"
    set "FILES_HASH=53B97E4993C17DECDEEC6E4E46E70F42ED01A625AE9AEB274A14327C399F890E"
)
if "%PROFILE%"=="6" (
    set "LABEL=4.09b Open Sturmovik avec 6DOF"
    set "VERSION=4.09b"
    set "VERSION_ID=409b"
    set "PROFILE_FOLDER=4.09b Mods ON 6DOF"
    set "AIR=409b air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\408 & 409b\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21"
    set "FILES_HASH=53B97E4993C17DECDEEC6E4E46E70F42ED01A625AE9AEB274A14327C399F890E"
)
if "%PROFILE%"=="7" (
    set "LABEL=4.09m Original"
    set "VERSION=4.09m"
    set "VERSION_ID=409m"
    set "PROFILE_FOLDER=4.09m Mods OFF (Original)"
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
    set "VERSION_ID=409m"
    set "PROFILE_FOLDER=4.09m Mods ON (NO 6DOF)"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=BA1C702C1FC0DCC3D760FAEE46F74AD8BDF3D8CB5CE44B2CA40DAA3F75343C80"
    set "FILES_HASH=5CB81D4FAE005429B701CE3DCAC001892DB2C66D0AECEE0A00E918D5E8892E71"
)
if "%PROFILE%"=="9" (
    set "LABEL=4.09m Open Sturmovik avec 6DOF"
    set "VERSION=4.09m"
    set "VERSION_ID=409m"
    set "PROFILE_FOLDER=4.09m Mods ON 6DOF"
    set "AIR=409m air.ini\Air.ini\air.ini"
    set "STATIONARY=Stationary\409m\stationary.ini"
    set "ORIGINAL=0"
    set "REMOVE_VERSION_SFS=0"
    set "EXE_HASH=7EBC80C47CDC9EB1C8AF3F740E5D8347551D12521D2E0CE02D1106383A2EFD21"
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

if /I not "%LANGUAGE%"=="auto" if /I not "%LANGUAGE%"=="fr" if /I not "%LANGUAGE%"=="us" if /I not "%LANGUAGE%"=="ru" if /I not "%LANGUAGE%"=="de" if /I not "%LANGUAGE%"=="cs" if /I not "%LANGUAGE%"=="hu" if /I not "%LANGUAGE%"=="pl" (
    echo [ERREUR] Choix de langue invalide : %LANGUAGE%
    call :progress 100 "Echec : langue invalide"
    exit /b 2
)
call :detectLanguage
if errorlevel 1 exit /b 2
call :progress 5 "Verification des fichiers"
for /D %%T in ("%SWITCH_ROOT%\_transaction-*") do if exist "%%~fT" (
    echo [ERREUR] Transaction precedente incomplete : "%%~fT". Sauvegardes conservees.
    exit /b 7
)

set "PROFILE_DIR=%SWITCH_ROOT%\%PROFILE_FOLDER%"
set "LANGUAGE_VERSION_DIR=%SWITCH_ROOT%\Languages\%VERSION%\i18n"
set "LANGUAGE_MODDED_DIR=%SWITCH_ROOT%\Languages\%VERSION%\Modded Aliases\%LANGUAGE%\i18n"
set "PRESENTATION_DIR=%PROFILE_DIR%\Profiles"
set "PRESENTATION_BACKGROUND=%PRESENTATION_DIR%\Missions\Background.tga"
set "PRESENTATION_MUSIC=%PRESENTATION_DIR%\samples\Music\Menu"
if "%ORIGINAL%"=="1" (
    set "PRESENTATION_BACKGROUND_HASH=07F94BD46D063CCA7363F6C5D62676ABC749C875FBE88277FD0CB4EE732E7591"
    set "PRESENTATION_MUSIC_EXPECTED=13"
) else (
    set "PRESENTATION_BACKGROUND_HASH=88C63E7A103AEA84076E710500255F21D5536B3ECAEB40149615E40A83A2B3B8"
    set "PRESENTATION_MUSIC_EXPECTED=14"
)
set "WRAPPER_HASH=8B6091C38F1241F2CB7D4EAF239DE662A2C862B57B14D7ACA9074C5C37A03F78"
set "PROFILE_PLANE=Profiles\Files\2B9A89D62FA5D19A"
if %PROFILE% LEQ 6 (
    set "PLANE_HASH=CFCC074266A0EDFF44D439884D92667EAD6EAC84FE3B59E8BBA97B08244634BB"
) else (
    set "PLANE_HASH=FA44E0BC633E6152116E96D571DAFFECB604D940913D3ABF31D0A59FC0602059"
)

set "PROFILE_LOADING=Profiles\Files\B44652EE36C23D32"
set "LOADING_HASH="
if "%PROFILE%"=="2" set "LOADING_HASH=24DE629468DF28AAE8B67F9D6865586F039705B10AD6220B1F29CAF51883377E"
if "%PROFILE%"=="3" set "LOADING_HASH=9FCED298BAC9D2F2F936FA368A761189B35C25F2D691AA92A56322D5576D8DC2"
if "%PROFILE%"=="5" set "LOADING_HASH=7483519C3711AA8DA0B8524BDB157B2562851FF1CDC0DFAD1979C4015AF17D81"
if "%PROFILE%"=="6" set "LOADING_HASH=5A2BFCFF7302B1F52E115C9B15BAA256A8341D902CA9C13B549F055E62416302"
if "%PROFILE%"=="8" set "LOADING_HASH=A357B5E5B8F4EE8CC42D65A155096B9DDC229733C64679A10F3A24696CD894F9"
if "%PROFILE%"=="9" set "LOADING_HASH=C376AA67E0C5E12D39B75C957615DC80778B3414D2D2BDCF3B0BF0911AF82BC4"
if "%VALIDATE_ONLY%"=="0" (
    tasklist /FI "IMAGENAME eq il2fb.exe" /NH 2>nul | find /I "il2fb.exe" >nul
    if not errorlevel 1 (
        echo [ERREUR] IL-2 est en cours. Fermez le jeu avant de changer de profil.
        exit /b 3
    )
)

if not exist "%ROOT%conf.ini" (
    echo [ERREUR] conf.ini absent a la racine du jeu.
    call :progress 100 "Echec : conf.ini absent"
    exit /b 4
)
call :verify "%SWITCH_ROOT%\Set-OpenSturmovikLanguage.ps1" "65B3D623E66B10B3E34B738FFB8CD20AE602A67C3BBD8FB77566B55B10E7E7F2" "Outil de langue"
if errorlevel 1 exit /b 4
call :verify "%SWITCH_ROOT%\Refresh-OpenSturmovikIconCache.ps1" "3A0471775A443F373F5F08573DA6A5B09E6F5015E45668DB084DD6CE1EAE5D16" "Outil de rafraichissement des icones"
if errorlevel 1 exit /b 4
call :verify "%SWITCH_ROOT%\Resources\Menu Backgrounds\Open Sturmovik\Background.tga" "0CB0E846175E36FECBCB18CC02B6206BB0000FBA8F54A4B61418F8BE3824A7B4" "Fond de menu Open Sturmovik"
if errorlevel 1 exit /b 4
call :verify "%PRESENTATION_BACKGROUND%" "%PRESENTATION_BACKGROUND_HASH%" "Fond Missions du profil"
if errorlevel 1 exit /b 4
set /A PRESENTATION_MUSIC_COUNT=0
if exist "%PRESENTATION_MUSIC%\*.wav" for %%F in ("%PRESENTATION_MUSIC%\*.wav") do set /A PRESENTATION_MUSIC_COUNT+=1
if not "!PRESENTATION_MUSIC_COUNT!"=="%PRESENTATION_MUSIC_EXPECTED%" (
    echo [ERREUR] Le profil %LABEL% contient !PRESENTATION_MUSIC_COUNT! musiques de menu au lieu de %PRESENTATION_MUSIC_EXPECTED%.
    exit /b 4
)
if "%ORIGINAL%"=="0" (
    set /A MODDED_LANGUAGE_COUNT=0
    if exist "%LANGUAGE_MODDED_DIR%\*_ru.properties" for %%F in ("%LANGUAGE_MODDED_DIR%\*_ru.properties") do set /A MODDED_LANGUAGE_COUNT+=1
    if not "!MODDED_LANGUAGE_COUNT!"=="36" (
        echo [ERREUR] Le jeu de langue modde %VERSION%/%LANGUAGE% contient !MODDED_LANGUAGE_COUNT! catalogues au lieu de 36.
        exit /b 4
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
call :verify "%PROFILE_DIR%\%PROFILE_PLANE%" "%PLANE_HASH%" "Registre Plane compatible du profil"
if errorlevel 1 exit /b 4
if defined LOADING_HASH (
    call :verify "%PROFILE_DIR%\%PROFILE_LOADING%" "%LOADING_HASH%" "Libelle de chargement du profil"
    if errorlevel 1 exit /b 4
)
if "%ORIGINAL%"=="0" (
    call :verify "%PROFILE_DIR%\wrapper.dll" "%WRAPPER_HASH%" "Wrapper du profil"
    if errorlevel 1 exit /b 4
)
call :profileDataCheck
if errorlevel 1 exit /b 4
call :versionFilesCheck%VERSION_ID%
if errorlevel 1 exit /b 4
call :detectBackground
if errorlevel 1 exit /b 4
call :verify "%SWITCH_ROOT%\Resources\Loading Backgrounds\Maddox\%BACKGROUND_FORMAT%\Background.tga" "%BACKGROUND_HASH%" "Fond de chargement %BACKGROUND_FORMAT%"
if errorlevel 1 exit /b 4
set "HUD_STANDARD_HASH="
set "HUD_IMMERSION_HASH="
if /I "%LANGUAGE%"=="fr" set "HUD_STANDARD_HASH=932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862"
if /I "%LANGUAGE%"=="fr" set "HUD_IMMERSION_HASH=F7B2C346B5DC184DB6FED8113A2906C56E923003EF45B1100862E1BC827D2DAC"
if /I "%LANGUAGE%"=="us" set "HUD_IMMERSION_HASH=ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C"
if /I "%LANGUAGE%"=="ru" set "HUD_STANDARD_HASH=15EE35897F3B074DD5410CBB2070285DA235C7AD257BC9B96CBEE3C0A0144AB3"
if /I "%LANGUAGE%"=="ru" set "HUD_IMMERSION_HASH=B174028E7F9D6ED6A05F8D21396AF33C79D2581E880DE429F9DF3A10527770B8"
if /I "%LANGUAGE%"=="de" set "HUD_STANDARD_HASH=8F46CC0D2C691ABA26130831E666654268D7E24C0B379A18626151036B677DBA"
if /I "%LANGUAGE%"=="de" set "HUD_IMMERSION_HASH=A06C2FBC654A5A41FD7230E2B2C233EBC8FA1F36F6C9691D9443B498543A270A"
if /I "%LANGUAGE%"=="cs" set "HUD_STANDARD_HASH=242C595AE61E3FA6EDB78B426673F011D4691FFF3FFF823C8D402F392AC150EF"
if /I "%LANGUAGE%"=="cs" set "HUD_IMMERSION_HASH=6B30433CE0E3E352ACC09E755C56CAA3DD3799043BE0152D7D01B4C8C56D1B4E"
if /I "%LANGUAGE%"=="hu" set "HUD_STANDARD_HASH=822B695DD0D07DE62EB251E36E270A4106BD2005483FF1429CF46A99DA58E36F"
if /I "%LANGUAGE%"=="hu" set "HUD_IMMERSION_HASH=46A546197A184C79DED66CA18CB5C86F00F4BBA2B1568A7338BFE7A0A3FFD231"
if /I "%LANGUAGE%"=="pl" set "HUD_STANDARD_HASH=AF260FFF51B6CD6831C5F72555A86CB1AF5506C3B1BD2E8B8C2D087A05662067"
if /I "%LANGUAGE%"=="pl" set "HUD_IMMERSION_HASH=B996BCB93D71315586F8512F4EF5EAC07C1A65D2010A354A53FD28B0E5450B19"
if /I "%HUD%"=="standard" if defined HUD_STANDARD_HASH (
    call :verify "%SWITCH_ROOT%\HudLogStock\MODS\STD\i18n\hud_log_%LANGUAGE%.properties" "%HUD_STANDARD_HASH%" "HUD standard %LANGUAGE%"
    if errorlevel 1 exit /b 4
)
if /I "%HUD%"=="immersion" (
    call :verify "%SWITCH_ROOT%\HudLogImmersion\MODS\STD\i18n\hud_log_%LANGUAGE%.properties" "%HUD_IMMERSION_HASH%" "HUD immersion %LANGUAGE%"
    if errorlevel 1 exit /b 4
)

if "%VALIDATE_ONLY%"=="1" (
    echo [OK] Profil valide sans modification : %LABEL%
    echo [OK] Fond de chargement valide : %BACKGROUND_FORMAT% pour %BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
    exit /b 0
)

call :progress 35 "Profil verifie"
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
call :progress 45 "Preparation de la transaction"
>"%TX%\next-profile.txt" (
    echo profile=%PROFILE%
    echo version=%VERSION%
    echo label=%LABEL%
    echo hud=%EFFECTIVE_HUD%
    echo modhud=%MOD_HUD%
    echo background=%BACKGROUND_FORMAT%
    echo resolution=%BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
    echo language=%LANGUAGE%
)
if errorlevel 1 goto stage_failed

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SWITCH_ROOT%\Set-OpenSturmovikLanguage.ps1" -Source "%ROOT%conf.ini" -Destination "%TX%\stage\conf.ini" -Language "%LANGUAGE%" >nul
if errorlevel 1 goto stage_failed

call :stage "%PROFILE_DIR%\il2fb.exe" "il2fb.exe"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\files.SFS" "files.SFS"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%AIR%" "Files\com\maddox\il2\objects\air.ini"
if errorlevel 1 goto stage_failed
call :stage "%SWITCH_ROOT%\%STATIONARY%" "Files\com\maddox\il2\objects\stationary.ini"
if errorlevel 1 goto stage_failed
call :stage "%PRESENTATION_BACKGROUND%" "Missions\Background.tga"
if errorlevel 1 goto stage_failed
for %%F in ("%PRESENTATION_MUSIC%\*.wav") do (
    call :stage "%%~fF" "samples\Music\Menu\%%~nxF"
    if errorlevel 1 goto stage_failed
)
call :stage "%SWITCH_ROOT%\Resources\Loading Backgrounds\Maddox\%BACKGROUND_FORMAT%\Background.tga" "Files\background0.tga"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\%PROFILE_PLANE%" "Files\2B9A89D62FA5D19A"
if errorlevel 1 goto stage_failed
if "%ORIGINAL%"=="0" (
    call :stage "%SWITCH_ROOT%\Resources\Menu Backgrounds\Open Sturmovik\Background.tga" "Files\gui\Background.tga"
    if errorlevel 1 goto stage_failed
)
if defined LOADING_HASH (
    call :stage "%PROFILE_DIR%\%PROFILE_LOADING%" "Files\B44652EE36C23D32"
    if errorlevel 1 goto stage_failed
)
if "%ORIGINAL%"=="0" (
    call :stage "%PROFILE_DIR%\wrapper.dll" "wrapper.dll"
    if errorlevel 1 goto stage_failed
)
call :stage "%PROFILE_DIR%\il2_core.dll" "il2_core.dll"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\il2_corep4.dll" "il2_corep4.dll"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\mg_snd.dll" "mg_snd.dll"
if errorlevel 1 goto stage_failed
call :stage "%PROFILE_DIR%\mg_snd_sse.dll" "mg_snd_sse.dll"
if errorlevel 1 goto stage_failed
if "%REMOVE_VERSION_SFS%"=="0" (
    call :stage "%PROFILE_DIR%\fb_3do19.SFS" "fb_3do19.SFS"
    if errorlevel 1 goto stage_failed
    call :stage "%PROFILE_DIR%\fb_3do20.SFS" "fb_3do20.SFS"
    if errorlevel 1 goto stage_failed
    call :stage "%PROFILE_DIR%\fb_maps15.SFS" "fb_maps15.SFS"
    if errorlevel 1 goto stage_failed
)
if exist "%LANGUAGE_VERSION_DIR%\*_%LANGUAGE%.properties" for %%F in ("%LANGUAGE_VERSION_DIR%\*_%LANGUAGE%.properties") do (
    call :stage "%%~fF" "Files\i18n\%%~nxF"
    if errorlevel 1 goto stage_failed
)
if "%ORIGINAL%"=="0" for %%F in ("%LANGUAGE_MODDED_DIR%\*_ru.properties") do (
    call :stage "%%~fF" "Files\i18n\%%~nxF"
    if errorlevel 1 goto stage_failed
)
set "HUD_SOURCE="
set "HUD_TARGET="
if /I "%EFFECTIVE_HUD%"=="stock" if /I not "%LANGUAGE%"=="us" (
    set "HUD_SOURCE=%SWITCH_ROOT%\HudLogStock\MODS\STD\i18n\hud_log_%LANGUAGE%.properties"
    set "HUD_TARGET=Files\i18n\hud_log_%LANGUAGE%.properties"
)
if /I "%EFFECTIVE_HUD%"=="standard" if /I not "%LANGUAGE%"=="us" (
    set "HUD_SOURCE=%SWITCH_ROOT%\HudLogStock\MODS\STD\i18n\hud_log_%LANGUAGE%.properties"
    set "HUD_TARGET=Files\i18n\hud_log_%LANGUAGE%.properties"
)
if /I "%EFFECTIVE_HUD%"=="immersion" (
    set "HUD_SOURCE=%SWITCH_ROOT%\HudLogImmersion\MODS\STD\i18n\hud_log_%LANGUAGE%.properties"
    set "HUD_TARGET=Files\i18n\hud_log_%LANGUAGE%.properties"
    if /I "%LANGUAGE%"=="us" set "HUD_TARGET=Files\i18n\hud_log.properties"
)
if defined HUD_SOURCE if "%ORIGINAL%"=="0" set "HUD_TARGET=Files\i18n\hud_log_ru.properties"
if defined HUD_SOURCE (
    call :stage "%HUD_SOURCE%" "%HUD_TARGET%"
    if errorlevel 1 goto stage_failed
)
call :progress 60 "Fichiers prepares"

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
call :backup 13 "Files\i18n\hud_log_ru.properties"
if errorlevel 1 goto backup_failed
call :backup 14 "Files\i18n\hud_log_fr.properties"
if errorlevel 1 goto backup_failed
call :backup 15 "Files\i18n\hud_log.properties"
if errorlevel 1 goto backup_failed
call :backup 16 "_Game Switcher\active-profile.txt"
if errorlevel 1 goto backup_failed
call :backup 17 "Files\background0.tga"
if errorlevel 1 goto backup_failed
call :backup 18 "Files\2B9A89D62FA5D19A"
if errorlevel 1 goto backup_failed
call :backup 19 "conf.ini"
if errorlevel 1 goto backup_failed
call :backup 20 "Files\gui\Background.tga"
if errorlevel 1 goto backup_failed
call :backup 21 "Files\B44652EE36C23D32"
if errorlevel 1 goto backup_failed
call :backup 22 "Files\i18n\hud_log_cs.properties"
if errorlevel 1 goto backup_failed
call :backup 23 "Files\i18n\hud_log_de.properties"
if errorlevel 1 goto backup_failed
call :backup 24 "Files\i18n\hud_log_hu.properties"
if errorlevel 1 goto backup_failed
call :backup 25 "Files\i18n\hud_log_pl.properties"
if errorlevel 1 goto backup_failed
call :backup 26 "Missions\Background.tga"
if errorlevel 1 goto backup_failed
set /A PRESENTATION_BACKUP_INDEX=100
if exist "%ROOT%samples\Music\Menu\*.wav" for %%F in ("%ROOT%samples\Music\Menu\*.wav") do (
    set /A PRESENTATION_BACKUP_INDEX+=1
    call :backup P!PRESENTATION_BACKUP_INDEX! "samples\Music\Menu\%%~nxF"
    if errorlevel 1 goto backup_failed
    >>"%TX%\presentation-backups.txt" echo P!PRESENTATION_BACKUP_INDEX!^|samples\Music\Menu\%%~nxF
)
if exist "%PRESENTATION_MUSIC%\*.wav" for %%F in ("%PRESENTATION_MUSIC%\*.wav") do (
    set /A PRESENTATION_BACKUP_INDEX+=1
    call :backup P!PRESENTATION_BACKUP_INDEX! "samples\Music\Menu\%%~nxF"
    if errorlevel 1 goto backup_failed
    >>"%TX%\presentation-backups.txt" echo P!PRESENTATION_BACKUP_INDEX!^|samples\Music\Menu\%%~nxF
)
set /A LANGUAGE_BACKUP_INDEX=30
if exist "%LANGUAGE_VERSION_DIR%\*_%LANGUAGE%.properties" for %%F in ("%LANGUAGE_VERSION_DIR%\*_%LANGUAGE%.properties") do (
    set /A LANGUAGE_BACKUP_INDEX+=1
    call :backup L!LANGUAGE_BACKUP_INDEX! "Files\i18n\%%~nxF"
    if errorlevel 1 goto backup_failed
    >>"%TX%\language-backups.txt" echo L!LANGUAGE_BACKUP_INDEX!^|Files\i18n\%%~nxF
)
if "%ORIGINAL%"=="0" for %%F in ("%LANGUAGE_MODDED_DIR%\*_ru.properties") do if /I not "%%~nxF"=="hud_log_ru.properties" (
    set /A LANGUAGE_BACKUP_INDEX+=1
    call :backup L!LANGUAGE_BACKUP_INDEX! "Files\i18n\%%~nxF"
    if errorlevel 1 goto backup_failed
    >>"%TX%\language-backups.txt" echo L!LANGUAGE_BACKUP_INDEX!^|Files\i18n\%%~nxF
)
call :progress 72 "Configuration active sauvegardee"

if exist "%ROOT%samples\Music\Menu\*.wav" for %%F in ("%ROOT%samples\Music\Menu\*.wav") do del /F /Q "%%~fF" >nul 2>&1
if exist "%ROOT%samples\Music\Menu\*.wav" goto commit_failed
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
    call :remove "Files\gui\Background.tga"
    if errorlevel 1 goto commit_failed
    if not defined LOADING_HASH (
        call :remove "Files\B44652EE36C23D32"
        if errorlevel 1 goto commit_failed
    )
)
if /I not "%EFFECTIVE_HUD%"=="immersion" if /I "%LANGUAGE%"=="us" (
    call :remove "Files\i18n\hud_log.properties"
    if errorlevel 1 goto commit_failed
)
call :progress 88 "Profil copie"
if "%REMOVE_VERSION_SFS%"=="1" (
    call :remove "fb_3do19.SFS"
    if errorlevel 1 goto commit_failed
    call :remove "fb_3do20.SFS"
    if errorlevel 1 goto commit_failed
    call :remove "fb_maps15.SFS"
    if errorlevel 1 goto commit_failed
)

call :progress 96 "Enregistrement du profil"
copy /B /Y "%TX%\next-profile.txt" "%SWITCH_ROOT%\active-profile.txt" >nul || goto commit_failed
fc /B "%TX%\next-profile.txt" "%SWITCH_ROOT%\active-profile.txt" >nul || goto commit_failed
call :progress 98 "Rafraichissement des icones"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SWITCH_ROOT%\Refresh-OpenSturmovikIconCache.ps1" -GameRoot "%ROOT%" >nul 2>&1
if errorlevel 1 echo [AVERTISSEMENT] Windows n a pas pu rafraichir immediatement le cache d icones.
rmdir /S /Q "%TX%"
echo [OK] Profil active : %LABEL%
echo [OK] HUD du profil : %EFFECTIVE_HUD%
echo [OK] Fond de chargement : %BACKGROUND_FORMAT% pour %BACKGROUND_WIDTH%x%BACKGROUND_HEIGHT%
echo [OK] Langue du jeu : %LANGUAGE%
call :progress 100 "Configuration installee"
exit /b 0

:stage_failed
call :progress 100 "Echec pendant la preparation"
echo [ERREUR] Preparation de la transaction impossible. Aucun fichier actif modifie.
rmdir /S /Q "%TX%"
exit /b 5

:backup_failed
call :progress 100 "Echec pendant la sauvegarde"
echo [ERREUR] Sauvegarde de la configuration active impossible. Aucun remplacement effectue.
rmdir /S /Q "%TX%"
exit /b 6

:commit_failed
call :progress 100 "Echec pendant le remplacement"
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

:versionFilesCheck408
call :verify "%PROFILE_DIR%\il2_core.dll" "AE1B06F2D4F6CC14A535FC47DF66D53A3DB1AE2BBA49A20F94BD109A03E6CE9C" "il2_core.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\il2_corep4.dll" "9D7D89C664D490EDBED97836FA810BB88BBAFA7D37A7B8D1DC76D15050F79A15" "il2_corep4.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.08m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.08m"
if errorlevel 1 exit /b 1
exit /b 0

:versionFilesCheck409b
call :verify "%PROFILE_DIR%\fb_3do19.SFS" "F4EBF76EA04511E57D75AC9F7D3E68953A6D85EF5093AFE35486DDBC10D81007" "fb_3do19.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\fb_maps15.SFS" "35742CA5476DA955C6B544303739F4E3F4BFD54D6EF9505B993BBA4ACC7C2522" "fb_maps15.SFS 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\il2_core.dll" "F8DDE5FC6C10BCA94481875BBAA4DA07F408CD5168E7E7DEECDD0B08C0B1992D" "il2_core.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\il2_corep4.dll" "B5D014D457107EFB86F740055692A5923C0E6A14B4C147CD7965EA007101277B" "il2_corep4.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd.dll" "A7DA1C4EA4E6A9239CFE2176D1DD3436EFD2D90D41DA3E9ACEC49507C76CE37C" "mg_snd.dll 4.09b"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd_sse.dll" "3FF5D0CDD6AD7571A8E5453D882E671190B03EE340DE525D37FB25A3D487B93F" "mg_snd_sse.dll 4.09b"
if errorlevel 1 exit /b 1
exit /b 0

:versionFilesCheck409m
call :verify "%PROFILE_DIR%\fb_3do19.SFS" "4527FC779F188364E2FC8739E53D74C85B3A47471B01F169586E4F1AFBB6B670" "fb_3do19.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\fb_3do20.SFS" "02FB0095B9FE4882FB17054F4F11460D49F61B80AF78F9B6EBAF687251E4E283" "fb_3do20.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\fb_maps15.SFS" "AF87651FBCA2450A57735ED2013F12FC9F307ABFB8B2913F22EB5543322D8AD9" "fb_maps15.SFS 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\il2_core.dll" "3145F63A53061C40604B57DED2F96313559BD69692123E7479D8C409339ECEB3" "il2_core.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\il2_corep4.dll" "0B4CD130051E7D853219480606A1508C0FBB3C7FD29FA8AF87BB72BBD37BB979" "il2_corep4.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd.dll" "2FBE1180129806CC978A48879969E592918EA26C42EB235D62FC874BAD886421" "mg_snd.dll 4.09m"
if errorlevel 1 exit /b 1
call :verify "%PROFILE_DIR%\mg_snd_sse.dll" "FDDD6924853306C94C9B8844703D4718F45CF22828975406E3C67DE40DFDE1C4" "mg_snd_sse.dll 4.09m"
if errorlevel 1 exit /b 1
exit /b 0

:detectLanguage
if /I not "%LANGUAGE%"=="auto" exit /b 0
set "LANGUAGE=fr"
set "LANGUAGE_IN_RTS=0"
if not exist "%ROOT%conf.ini" exit /b 0
for /F "usebackq tokens=* delims=" %%L in ("%ROOT%conf.ini") do (
    set "LANGUAGE_LINE=%%L"
    if /I "!LANGUAGE_LINE!"=="[rts]" (
        set "LANGUAGE_IN_RTS=1"
    ) else if "!LANGUAGE_LINE:~0,1!"=="[" (
        set "LANGUAGE_IN_RTS=0"
    ) else if "!LANGUAGE_IN_RTS!"=="1" (
        for /F "tokens=1,* delims==" %%A in ("!LANGUAGE_LINE!") do if /I "%%A"=="locale" (
            if /I "%%B"=="fr" set "LANGUAGE=fr"
            if /I "%%B"=="us" set "LANGUAGE=us"
            if /I "%%B"=="en" set "LANGUAGE=us"
            if /I "%%B"=="ru" set "LANGUAGE=ru"
            if /I "%%B"=="de" set "LANGUAGE=de"
            if /I "%%B"=="cs" set "LANGUAGE=cs"
            if /I "%%B"=="hu" set "LANGUAGE=hu"
            if /I "%%B"=="pl" set "LANGUAGE=pl"
        )
    )
)
exit /b 0

:detectHud
set "MOD_HUD=custom"
set "ACTUAL_HASH="
set "ACTIVE_HUD=Files\i18n\hud_log_%LANGUAGE%.properties"
if /I "%LANGUAGE%"=="us" set "ACTIVE_HUD=Files\i18n\hud_log.properties"
if not exist "%ROOT%%ACTIVE_HUD%" (
    if exist "%ROOT%wrapper.dll" (set "MOD_HUD=standard") else (set "MOD_HUD=stock")
    exit /b 0
)
for /F "skip=1 tokens=* delims=" %%H in ('certutil -hashfile "%ROOT%%ACTIVE_HUD%" SHA256 2^>nul') do if not defined ACTUAL_HASH set "ACTUAL_HASH=%%H"
set "ACTUAL_HASH=!ACTUAL_HASH: =!"
for %%H in (932A3925C8C624B1948AEB96C3F4B466EAD6A1108F61494335558F2A116E7862 15EE35897F3B074DD5410CBB2070285DA235C7AD257BC9B96CBEE3C0A0144AB3 8F46CC0D2C691ABA26130831E666654268D7E24C0B379A18626151036B677DBA 242C595AE61E3FA6EDB78B426673F011D4691FFF3FFF823C8D402F392AC150EF 822B695DD0D07DE62EB251E36E270A4106BD2005483FF1429CF46A99DA58E36F AF260FFF51B6CD6831C5F72555A86CB1AF5506C3B1BD2E8B8C2D087A05662067) do if /I "!ACTUAL_HASH!"=="%%H" set "MOD_HUD=standard"
for %%H in (ABD3E33F35F4ACC0421788E6974C587E9E3A861256CD39DD3F36A76FFF29B32C F7B2C346B5DC184DB6FED8113A2906C56E923003EF45B1100862E1BC827D2DAC B174028E7F9D6ED6A05F8D21396AF33C79D2581E880DE429F9DF3A10527770B8 A06C2FBC654A5A41FD7230E2B2C233EBC8FA1F36F6C9691D9443B498543A270A 6B30433CE0E3E352ACC09E755C56CAA3DD3799043BE0152D7D01B4C8C56D1B4E 46A546197A184C79DED66CA18CB5C86F00F4BBA2B1568A7338BFE7A0A3FFD231 B996BCB93D71315586F8512F4EF5EAC07C1A65D2010A354A53FD28B0E5450B19) do if /I "!ACTUAL_HASH!"=="%%H" set "MOD_HUD=immersion"
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
    if "%~1"=="16" (
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
call :restore 14 "Files\i18n\hud_log_fr.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 15 "Files\i18n\hud_log.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 16 "_Game Switcher\active-profile.txt"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 17 "Files\background0.tga"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 18 "Files\2B9A89D62FA5D19A"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 19 "conf.ini"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 20 "Files\gui\Background.tga"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 21 "Files\B44652EE36C23D32"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 22 "Files\i18n\hud_log_cs.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 23 "Files\i18n\hud_log_de.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 24 "Files\i18n\hud_log_hu.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 25 "Files\i18n\hud_log_pl.properties"
if errorlevel 1 set "ROLLBACK_FAILED=1"
call :restore 26 "Missions\Background.tga"
if errorlevel 1 set "ROLLBACK_FAILED=1"
if exist "%TX%\presentation-backups.txt" for /F "usebackq tokens=1,* delims=|" %%I in ("%TX%\presentation-backups.txt") do (
    call :restore %%I "%%J"
    if errorlevel 1 set "ROLLBACK_FAILED=1"
)
if exist "%TX%\language-backups.txt" for /F "usebackq tokens=1,* delims=|" %%I in ("%TX%\language-backups.txt") do (
    call :restore %%I "%%J"
    if errorlevel 1 set "ROLLBACK_FAILED=1"
)
if "%ROLLBACK_FAILED%"=="1" exit /b 1
exit /b 0

:openGui
set "OPEN_STURMOVIK_SWITCHER_BAT=%~f0"
set "SWITCHER_GUI_FILE=%SWITCH_ROOT%\Open_Sturmovik_Switcher.hta"
if not exist "%SWITCHER_GUI_FILE%" (
    echo [ERREUR] Interface graphique absente : "%SWITCHER_GUI_FILE%".
    exit /b 2
)
start "" /NORMAL "%SystemRoot%\System32\mshta.exe" "%SWITCHER_GUI_FILE%"
if errorlevel 1 (
    echo [ERREUR] Impossible de lancer l'interface graphique.
    exit /b 2
)
exit /b 0
