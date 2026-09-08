#define AppVersion "1.15"
#define InstallerRoot SourcePath
#define PayloadRoot AddBackslash(SourcePath) + "Payload"

[Setup]
AppId={{1E0AF160-7F67-4A55-906B-AE2F2D511115}
AppName=Open Sturmovik
AppVersion={#AppVersion}
AppVerName=Open Sturmovik Update {#AppVersion}
VersionInfoDescription=Open Sturmovik Update 1.15
VersionInfoProductName=Open Sturmovik
VersionInfoVersion=1.15.0.0
DefaultDirName={code:FindPreviousInstallation|{autopf}\Ubisoft\IL-2 Sturmovik 1946}
AppendDefaultDirName=no
DisableProgramGroupPage=yes
DisableReadyMemo=no
DisableWelcomePage=no
OutputDir=Output
OutputBaseFilename=Open_Sturmovik_Update_1.15
SetupIconFile=assets\OpenSturmovik-Setup.ico
WizardImageFile=assets\OpenSturmovik-Wizard.bmp
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x86 x64compatible
PrivilegesRequired=admin
CloseApplications=yes
CloseApplicationsFilter=il2fb.exe
RestartApplications=no
SetupLogging=yes
Uninstallable=no
WizardStyle=modern

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Files]
; Preserve every existing player profile, setting and campaign.
Source: "{#PayloadRoot}\*"; DestDir: "{app}"; Excludes: "\Users\*"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
Type: files; Name: "{app}\Files\3do\Effects\clouds\Cloud.mat"
Type: files; Name: "{app}\Files\3do\Effects\clouds\Cloud4x4.mat"
Type: files; Name: "{app}\Files\3do\Effects\clouds\Cloud4x4_nosort.mat"
Type: files; Name: "{app}\Files\3do\Effects\clouds\cloboard.tga"
Type: files; Name: "{app}\Files\3do\Effects\clouds\clouds4x4.tga"
Type: files; Name: "{app}\Files\3do\Effects\clouds\cloudsA.tga"
Type: files; Name: "{app}\Files\Effects\clouds\Cloud4x4_nosort.mat"
Type: files; Name: "{app}\Files\Effects\clouds\clouds4x4.tga"
Type: filesandordirs; Name: "{app}\Mod_AOC_Public"
Type: filesandordirs; Name: "{app}\_Runtime_Addons"
Type: filesandordirs; Name: "{app}\_Documentation"
; Retire l'ancien nom pluriel apres migration vers _Game Switcher.
Type: filesandordirs; Name: "{app}\_Game Switchers"
Type: files; Name: "{app}\Open_Sturmovik_Switcher.ps1"
Type: dirifempty; Name: "{app}\Files\3do\Effects\clouds"

[Icons]
Name: "{userdesktop}\Bombsight Table 2"; Filename: "{app}\_Utilities\Bombsight Table 2\Bombsight Table 2.exe"; WorkingDir: "{app}\_Utilities\Bombsight Table 2"; Comment: "Table de bombardement pour Open Sturmovik"
Name: "{userdesktop}\HardBall 4.08"; Filename: "{app}\_Utilities\HardBall408\HardBall408.exe"; WorkingDir: "{app}\_Utilities\HardBall408"; Comment: "Encyclopedie HardBall pour IL-2 1946"
Name: "{userdesktop}\IL2 Compare"; Filename: "{app}\_Utilities\IL2C\ILC2.exe"; WorkingDir: "{app}\_Utilities\IL2C"; Comment: "Comparateur d'appareils IL-2"
Name: "{userdesktop}\JoyCtrl"; Filename: "{app}\_Utilities\JoyCtrl\JoyCtrl.exe"; WorkingDir: "{app}\_Utilities\JoyCtrl"; Comment: "Reglage des commandes de vol IL-2"
Name: "{userdesktop}\Lowengrin DCG"; Filename: "{app}\_Utilities\Lowegrin_DCG\il2dcg.exe"; WorkingDir: "{app}\_Utilities\Lowegrin_DCG"; Comment: "Lowengrin Dynamic Campaign Generator"
Name: "{userdesktop}\Mission Mate 6"; Filename: "{app}\_Utilities\Mission Mate 6\Mission Mate v6.0.exe"; WorkingDir: "{app}\_Utilities\Mission Mate 6"; Comment: "Generateur de missions Mission Mate pour IL-2"
Name: "{userdesktop}\WeatherSet"; Filename: "{app}\_Utilities\WeatherSet\WeatherSet.exe"; WorkingDir: "{app}\_Utilities\WeatherSet"; Comment: "Editeur de meteo pour les missions IL-2"
Name: "{userdesktop}\ZipNav"; Filename: "{app}\_Utilities\ZipNav\ZipNavV1.1.exe"; WorkingDir: "{app}\_Utilities\ZipNav"; Comment: "Outil de navigation ZipNav pour IL-2"
Name: "{userdesktop}\San's IL2 FOV Changer"; Filename: "{app}\_Game_Enhancements\San's IL2 FOV Changer\San's_IL2_FovChanger_RC.exe"; WorkingDir: "{app}\_Game_Enhancements\San's IL2 FOV Changer"; Comment: "Reglage du champ de vision d'IL-2"
Name: "{userdesktop}\Open Sturmovik Switcher"; Filename: "{sys}\mshta.exe"; Parameters: "javascript:new/**/ActiveXObject('WScript.Shell').Run('cmd.exe\x20/D\x20/C\x20""""Open_Sturmovik_Switcher.bat""""',0,false);close()"; WorkingDir: "{app}"; IconFilename: "{app}\_Game Switcher\Resources\Open_Sturmovik_Switcher_Original.ico"; Comment: "Choix securise des profils IL-2 4.08m, 4.09b et 4.09m"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ""{app}\tools\Initialize-OpenSturmovikUtilities.ps1"" -InstallationRoot ""{app}"""; WorkingDir: "{app}"; StatusMsg: "Configuration des utilitaires Open Sturmovik..."; Flags: runhidden waituntilterminated

[Code]
function FindPreviousInstallation(Default: string): string;
var
  InstallPath: string;
begin
  if RegQueryStringValue(HKLM, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Open Sturmovik', 'InstallLocation', InstallPath) and DirExists(InstallPath) then
    Result := InstallPath
  else if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\Open Sturmovik', 'InstallLocation', InstallPath) and DirExists(InstallPath) then
    Result := InstallPath
  else
    Result := Default;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  GameExe: string;
begin
  Result := True;
  if CurPageID = wpSelectDir then
  begin
    GameExe := AddBackslash(WizardDirValue) + 'il2fb.exe';
    if not FileExists(GameExe) then
    begin
      MsgBox(
        'Selectionnez le dossier existant d''IL-2 Sturmovik 1946 contenant il2fb.exe.' + #13#10 +
        'Aucun fichier ne sera installe tant que cette base n''est pas reconnue.',
        mbError,
        MB_OK
      );
      Result := False;
    end;
  end;
end;
