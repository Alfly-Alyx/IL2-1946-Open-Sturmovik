#define AppName "Open Sturmovik"
#define AppVersion "1.15"
#define OutputBaseName "Open-Sturmovik-1.15-Setup"

[Setup]
AppId={{9BC05C3D-4BE5-4AC0-BA30-F08699F0D115}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Open Sturmovik
AppPublisherURL=https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik
AppSupportURL=https://github.com/Alfly-Alyx/IL2-1946-Open-Sturmovik/issues
VersionInfoVersion=1.15.0.0
DefaultDirName={code:GetDefaultInstallDir}
DisableDirPage=no
DirExistsWarning=no
DisableProgramGroupPage=yes
AllowNoIcons=no
AllowUNCPath=no
PrivilegesRequired=admin
UsePreviousAppDir=no
Uninstallable=no
OutputDir=Output
OutputBaseFilename={#OutputBaseName}
InfoBeforeFile=NOTICE_INSTALLATION.txt
SetupIconFile=assets\OpenSturmovik-Setup.ico
WizardStyle=modern dynamic
WizardBackColor=#101820
WizardBackColorDynamicDark=#101820
WizardBackImageFile=assets\backgrounds\01.png
WizardBackImageFileDynamicDark=assets\backgrounds\01.png
WizardBackImageOpacity=150
WizardSmallImageFile=assets\exec-d2e28692__logo-IL2-B__master-1024.png
WizardImageFile=
Compression=lzma2/ultra64
SolidCompression=yes
DiskSpanning=yes
SlicesPerDisk=1
DiskSliceSize=1000000000
CloseApplications=yes
CloseApplicationsFilter=il2fb.exe
RestartApplications=no
SetupLogging=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[CustomMessages]
english.OldOpenSturmovikTitle=Open Sturmovik is already installed
english.OldOpenSturmovikBody=The selected folder already contains Open Sturmovik. This complete installer can only be applied over an IL-2 installation that does not already contain Open Sturmovik.
english.ConfBackupFailed=Setup could not back up the existing conf.ini. No Open Sturmovik file has been copied.
french.OldOpenSturmovikTitle=Open Sturmovik est déjà installé
french.OldOpenSturmovikBody=Le dossier choisi contient déjà Open Sturmovik. Cet installeur complet ne peut être appliqué que sur une installation d'IL-2 qui ne contient pas déjà Open Sturmovik.
french.ConfBackupFailed=L'installeur n'a pas pu sauvegarder le conf.ini existant. Aucun fichier d'Open Sturmovik n'a été copié.

[Files]
; Images placees avant le gros bloc solide pour une extraction temporaire rapide.
Source: "assets\backgrounds\01.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\02.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\03.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\04.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\05.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\06.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\07.png"; Flags: dontcopy noencryption
Source: "assets\backgrounds\08.png"; Flags: dontcopy noencryption

; Fichiers situes directement a la racine du jeu.
Source: "Payload\*"; DestDir: "{app}"; Excludes: "conf.ini"; Flags: ignoreversion overwritereadonly uninsneveruninstall

; Dossiers complets du pack. Users n'est volontairement jamais inclus.
Source: "Payload\_Documentations\*"; DestDir: "{app}\_Documentations"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\_Game Switcher\*"; DestDir: "{app}\_Game Switcher"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\_Game_Enhancements\*"; DestDir: "{app}\_Game_Enhancements"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\_Utilities\*"; DestDir: "{app}\_Utilities"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\DGen\*"; DestDir: "{app}\DGen"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\Files\*"; DestDir: "{app}\Files"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\i18n\*"; DestDir: "{app}\i18n"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\Intros\*"; DestDir: "{app}\Intros"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\NGen\*"; DestDir: "{app}\NGen"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\samples\*"; DestDir: "{app}\samples"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall
Source: "Payload\docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion overwritereadonly recursesubdirs createallsubdirs uninsneveruninstall

; Les missions, campagnes et peintures ajoutees par le joueur sont conservees.
Source: "Payload\Missions\*"; DestDir: "{app}\Missions"; Excludes: "Background.tga"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall
; Le fond de menu des missions appartient au profil actif et doit suivre le profil 8 livre par defaut.
Source: "Payload\Missions\Background.tga"; DestDir: "{app}\Missions"; Flags: ignoreversion overwritereadonly uninsneveruninstall
Source: "Payload\PaintSchemes\*"; DestDir: "{app}\PaintSchemes"; Flags: ignoreversion recursesubdirs createallsubdirs onlyifdoesntexist uninsneveruninstall

; Le conf.ini valide du pack est copie a la racine apres sauvegarde de l'ancien.
Source: "Payload\_Game Switcher\conf.ini"; DestDir: "{app}"; DestName: "conf.ini"; Flags: ignoreversion overwritereadonly uninsneveruninstall

[Icons]
Name: "{autodesktop}\Open Sturmovik"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\_Game Switcher\Open_Sturmovik_Game.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\il2fb.exe"; Comment: "Lancer Open Sturmovik dans la resolution active de l ecran principal"
Name: "{autodesktop}\Open Sturmovik Switcher"; Filename: "{sys}\wscript.exe"; Parameters: """{app}\_Game Switcher\Open_Sturmovik_Switcher.vbs"""; WorkingDir: "{app}"; IconFilename: "{app}\_Game Switcher\Resources\Icons\Open_Sturmovik_Switcher.ico"; Comment: "Configurer et lancer Open Sturmovik"
Name: "{autodesktop}\Bombsight Table 2"; Filename: "{app}\_Utilities\Bombsight Table 2\Bombsight Table 2.exe"; WorkingDir: "{app}\_Utilities\Bombsight Table 2"; Comment: "Table de bombardement pour Open Sturmovik"
Name: "{autodesktop}\HardBall 4.08"; Filename: "{app}\_Utilities\HardBall408\HardBall408.exe"; WorkingDir: "{app}\_Utilities\HardBall408"; Comment: "Encyclopedie HardBall pour IL-2 1946"
Name: "{autodesktop}\IL2 Sticks"; Filename: "{app}\_Utilities\IL2 Sticks\IL2-Sticks.exe"; WorkingDir: "{app}\_Utilities\IL2 Sticks"; Comment: "Configuration des commandes IL-2"
Name: "{autodesktop}\IL2 Compare"; Filename: "{app}\_Utilities\IL2C\ILC2.exe"; WorkingDir: "{app}\_Utilities\IL2C"; Comment: "Comparateur d'appareils IL-2"
Name: "{autodesktop}\JoyCtrl"; Filename: "{app}\_Utilities\JoyCtrl\JoyCtrl.exe"; WorkingDir: "{app}\_Utilities\JoyCtrl"; Comment: "Reglage des commandes de vol IL-2"
Name: "{autodesktop}\Mission Mate 6"; Filename: "{app}\_Utilities\Mission Mate 6\Mission Mate v6.0.exe"; WorkingDir: "{app}\_Utilities\Mission Mate 6"; Comment: "Generateur de missions Mission Mate pour IL-2"
Name: "{autodesktop}\Quick Mission Tuner"; Filename: "{app}\_Utilities\Quick Mission Tuner\MissionTuner V2.exe"; WorkingDir: "{app}\_Utilities\Quick Mission Tuner"; Comment: "Editeur de missions rapides pour IL-2"
Name: "{autodesktop}\WeatherSet"; Filename: "{app}\_Utilities\WeatherSet\WeatherSet.exe"; WorkingDir: "{app}\_Utilities\WeatherSet"; Comment: "Editeur de meteo pour les missions IL-2"
Name: "{autodesktop}\ZipNav"; Filename: "{app}\_Utilities\ZipNav\ZipNavV1.1.exe"; WorkingDir: "{app}\_Utilities\ZipNav"; Comment: "Outil de navigation ZipNav pour IL-2"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File ""{app}\_Game Switcher\Set-OpenSturmovikNativeResolution.ps1"" -GameRoot ""{app}"""; StatusMsg: "Adaptation de la resolution a l ecran principal..."; Flags: runhidden waituntilterminated

[Code]
const
  BackgroundCount = 8;
  UninstallKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';

var
  ConfBackupCreated: Boolean;
  ConfBackupPrepared: Boolean;
  ConfBackupPath: String;
  InstallCompleted: Boolean;
  LastBackgroundIndex: Integer;

function NormalizeDirectory(Path: String): String;
begin
  Result := Trim(Path);
  if (Length(Result) >= 2) and
     (Result[1] = '"') and
     (Result[Length(Result)] = '"') then
  begin
    Delete(Result, Length(Result), 1);
    Delete(Result, 1, 1);
  end;

  while (Length(Result) > 3) and
        (Result[Length(Result)] = '\') do
    Delete(Result, Length(Result), 1);
end;

function IsIL2Directory(const Path: String): Boolean;
begin
  Result := FileExists(AddBackslash(Path) + 'il2fb.exe');
end;

function FindIL2InUninstallKey(
  RootKey: Integer;
  const BaseKey: String;
  var InstallPath: String): Boolean;
var
  SubKeys: TArrayOfString;
  DisplayName: String;
  Candidate: String;
  I: Integer;
begin
  Result := False;
  if not RegGetSubkeyNames(RootKey, BaseKey, SubKeys) then
    Exit;

  for I := 0 to GetArrayLength(SubKeys) - 1 do
  begin
    if RegQueryStringValue(
         RootKey, BaseKey + '\' + SubKeys[I], 'DisplayName', DisplayName) and
       (Pos('il-2 sturmovik 1946', Lowercase(DisplayName)) > 0) and
       RegQueryStringValue(
         RootKey, BaseKey + '\' + SubKeys[I], 'InstallLocation', Candidate) then
    begin
      Candidate := NormalizeDirectory(Candidate);
      if IsIL2Directory(Candidate) then
      begin
        InstallPath := Candidate;
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function GetDefaultInstallDir(Param: String): String;
var
  Candidate: String;
begin
  if FindIL2InUninstallKey(HKCU, UninstallKey, Candidate) or
     FindIL2InUninstallKey(HKLM32, UninstallKey, Candidate) or
     FindIL2InUninstallKey(HKLM64, UninstallKey, Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Candidate := ExpandConstant(
    '{autopf32}\Steam\steamapps\common\IL 2 Sturmovik 1946');
  if IsIL2Directory(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Candidate := ExpandConstant(
    '{autopf32}\Ubisoft\IL-2 Sturmovik 1946');
  if IsIL2Directory(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Candidate := ExpandConstant('{sd}\GOG Games\IL-2 Sturmovik 1946');
  if IsIL2Directory(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  Result := ExpandConstant(
    '{autopf32}\Ubisoft\IL-2 Sturmovik 1946');
end;

function ContainsOpenSturmovik(const Path: String): Boolean;
var
  Root: String;
begin
  Root := AddBackslash(Path);
  Result :=
    FileExists(Root + '.open-sturmovik-installed') or
    FileExists(Root + 'Open Sturmovik Switcher.exe') or
    FileExists(Root + 'Open_Sturmovik_Switcher.bat') or
    DirExists(Root + '_Game Switchers') or
    DirExists(Root + '_Game Switcher') or
    DirExists(Root + '_Game_Enhancements');
end;

function OldOpenSturmovikError(const Path: String): String;
begin
  Result :=
    ExpandConstant('{cm:OldOpenSturmovikBody}') + #13#10 + #13#10 +
    Path;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and
     ContainsOpenSturmovik(WizardDirValue) then
  begin
    MsgBox(
      OldOpenSturmovikError(WizardDirValue),
      mbError, MB_OK);
    Result := False;
  end;
end;

function BuildConfBackupPath(const Root: String): String;
var
  BasePath: String;
  Stamp: String;
  Candidate: String;
  Suffix: Integer;
begin
  BasePath := AddBackslash(Root) + 'conf.ini.bak';
  if not FileExists(BasePath) then
  begin
    Result := BasePath;
    Exit;
  end;

  Stamp := GetDateTimeString('yyyymmdd-hhnnss', '-', ':');
  Candidate := AddBackslash(Root) + 'conf.ini.' + Stamp + '.bak';
  Suffix := 2;
  while FileExists(Candidate) do
  begin
    Candidate :=
      AddBackslash(Root) + 'conf.ini.' + Stamp + '-' +
      IntToStr(Suffix) + '.bak';
    Suffix := Suffix + 1;
  end;
  Result := Candidate;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Root: String;
  CurrentConf: String;
begin
  Result := '';
  Root := WizardDirValue;

  if ContainsOpenSturmovik(Root) then
  begin
    Result := OldOpenSturmovikError(Root);
    Exit;
  end;

  if ConfBackupPrepared then
    Exit;

  CurrentConf := AddBackslash(Root) + 'conf.ini';
  if FileExists(CurrentConf) then
  begin
    ConfBackupPath := BuildConfBackupPath(Root);
    if not RenameFile(CurrentConf, ConfBackupPath) then
    begin
      Result :=
        ExpandConstant('{cm:ConfBackupFailed}') + #13#10 + #13#10 +
        ConfBackupPath;
      Exit;
    end;
    ConfBackupCreated := True;
    Log('Existing conf.ini backed up to: ' + ConfBackupPath);
  end;

  ConfBackupPrepared := True;
end;

procedure SetInstallBackground(Index: Integer);
var
  Images: TArrayOfGraphic;
  FileName: String;
begin
  if Index < 0 then
    Index := 0;
  if Index >= BackgroundCount then
    Index := BackgroundCount - 1;
  if Index = LastBackgroundIndex then
    Exit;

  FileName := Format('0%d.png', [Index + 1]);
  try
    ExtractTemporaryFile(FileName);
    SetLength(Images, 1);
    Images[0] := TPngImage.Create;
    try
      Images[0].LoadFromFile(ExpandConstant('{tmp}\' + FileName));
      WizardSetBackImage(Images, True, True, 150);
      LastBackgroundIndex := Index;
    finally
      Images[0].Free;
    end;
  except
    Log(Format('Could not display installer background %s: %s', [FileName, GetExceptionMessage]));
  end;
end;

procedure CurInstallProgressChanged(
  CurProgress, MaxProgress: Integer);
var
  Index: Integer;
begin
  if MaxProgress <= 0 then
    Exit;
  Index := (CurProgress * BackgroundCount) div MaxProgress;
  SetInstallBackground(Index);
end;

procedure InitializeWizard;
begin
  ConfBackupCreated := False;
  ConfBackupPrepared := False;
  InstallCompleted := False;
  LastBackgroundIndex := -1;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  MarkerPath: String;
begin
  if CurStep = ssInstall then
    SetInstallBackground(0);

  if CurStep = ssDone then
  begin
    MarkerPath :=
      AddBackslash(ExpandConstant('{app}')) +
      '.open-sturmovik-installed';
    if not SaveStringToFile(
      MarkerPath, 'Open Sturmovik {#AppVersion}' + #13#10, False) then
      Log('Could not write the Open Sturmovik installation marker.');
    InstallCompleted := True;
  end;
end;

procedure DeinitializeSetup;
var
  InstalledConf: String;
begin
  if (not InstallCompleted) and ConfBackupCreated then
  begin
    InstalledConf := AddBackslash(WizardDirValue) + 'conf.ini';
    if FileExists(InstalledConf) and not DeleteFile(InstalledConf) then
      Log('Could not remove the incomplete replacement conf.ini.');

    if RenameFile(ConfBackupPath, InstalledConf) then
      Log('Original conf.ini restored after incomplete installation.')
    else
      Log('Could not restore the original conf.ini from: ' + ConfBackupPath);
  end;
end;
