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
DisableWelcomePage=no
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
SetupIconFile=assets\exec-0631d7c4__avion-carte__Windows.ico
WizardStyle=modern
WizardSmallImageFile=assets\exec-37073acd__logo-IL2-A__master-1024.png
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
english.IncompleteMarkerFailed=Setup could not prepare interrupted-installation recovery. No Open Sturmovik file has been copied.
french.IncompleteMarkerFailed=L'installeur n'a pas pu préparer la reprise après interruption. Aucun fichier d'Open Sturmovik n'a été copié.

[Files]

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

[Code]
const
  UninstallKey = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  SM_CXSCREEN = 0;
  SM_CYSCREEN = 1;

var
  ConfBackupCreated: Boolean;
  ConfBackupPrepared: Boolean;
  ConfBackupPath: String;
  InstallCompleted: Boolean;
  IncompleteMarkerCreated: Boolean;
  IncompleteMarkerPath: String;

function GetSystemMetrics(nIndex: Integer): Integer;
  external 'GetSystemMetrics@user32.dll stdcall';

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

  { A current installation interrupted before ssDone is explicitly resumable. }
  if FileExists(Root + '.open-sturmovik-installing') and
     not FileExists(Root + '.open-sturmovik-installed') then
  begin
    Result := False;
    Exit;
  end;

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

  IncompleteMarkerPath :=
    AddBackslash(Root) + '.open-sturmovik-installing';
  if not SaveStringToFile(
    IncompleteMarkerPath,
    'Open Sturmovik 1.15 installation in progress' + #13#10,
    False) then
  begin
    Result := ExpandConstant('{cm:IncompleteMarkerFailed}') + #13#10 + #13#10 +
      IncompleteMarkerPath;
    Exit;
  end;
  IncompleteMarkerCreated := True;
  Log('Incomplete installation marker created: ' + IncompleteMarkerPath);

  CurrentConf := AddBackslash(Root) + 'conf.ini';
  if FileExists(CurrentConf) then
  begin
    ConfBackupPath := BuildConfBackupPath(Root);
    if not RenameFile(CurrentConf, ConfBackupPath) then
    begin
      DeleteFile(IncompleteMarkerPath);
      IncompleteMarkerCreated := False;
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

procedure ConfigureWelcomePage;
var
  ContentWidth: Integer;
begin
  { Text-only welcome page before the information notice. }
  WizardForm.WizardBitmapImage.Visible := False;
  ContentWidth := WizardForm.WelcomeLabel1.Parent.ClientWidth - ScaleX(64);

  WizardForm.WelcomeLabel1.AutoSize := False;
  WizardForm.WelcomeLabel1.Left := ScaleX(32);
  WizardForm.WelcomeLabel1.Top := ScaleY(105);
  WizardForm.WelcomeLabel1.Width := ContentWidth;
  WizardForm.WelcomeLabel1.Height := ScaleY(44);
  WizardForm.WelcomeLabel1.Alignment := taCenter;
  WizardForm.WelcomeLabel1.Font.Size := 24;
  WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  WizardForm.WelcomeLabel1.Caption := 'Open Sturmovik';

  WizardForm.WelcomeLabel2.AutoSize := False;
  WizardForm.WelcomeLabel2.Left := ScaleX(32);
  WizardForm.WelcomeLabel2.Top := WizardForm.WelcomeLabel1.Top +
    WizardForm.WelcomeLabel1.Height + ScaleY(14);
  WizardForm.WelcomeLabel2.Width := ContentWidth;
  WizardForm.WelcomeLabel2.Height := ScaleY(50);
  WizardForm.WelcomeLabel2.Alignment := taCenter;
  WizardForm.WelcomeLabel2.Caption :=
    'Made possible by the community, for the community';
end;
procedure PositionWizardLogo;
var
  TextLeft: Integer;
begin
  WizardForm.WizardSmallBitmapImage.AutoSize := False;
  WizardForm.WizardSmallBitmapImage.Stretch := True;
  WizardForm.WizardSmallBitmapImage.BackColor := WizardForm.MainPanel.Color;
  WizardForm.WizardSmallBitmapImage.Left := ScaleX(10);
  WizardForm.WizardSmallBitmapImage.Top := ScaleY(8);
  WizardForm.WizardSmallBitmapImage.Width := ScaleX(48);
  WizardForm.WizardSmallBitmapImage.Height := ScaleY(48);

  TextLeft := WizardForm.WizardSmallBitmapImage.Left +
    WizardForm.WizardSmallBitmapImage.Width + ScaleX(12);
  WizardForm.PageNameLabel.Left := TextLeft;
  WizardForm.PageNameLabel.Width :=
    WizardForm.WizardSmallBitmapImage.Parent.ClientWidth -
    TextLeft - ScaleX(12);
  WizardForm.PageDescriptionLabel.Left := TextLeft;
  WizardForm.PageDescriptionLabel.Width :=
    WizardForm.WizardSmallBitmapImage.Parent.ClientWidth -
    TextLeft - ScaleX(12);
end;
procedure InitializeWizard;
begin
  ConfBackupCreated := False;
  ConfBackupPrepared := False;
  InstallCompleted := False;
  IncompleteMarkerCreated := False;
  IncompleteMarkerPath := '';
  PositionWizardLogo;
  ConfigureWelcomePage;
end;

procedure UpdateActiveProfileResolution(
  const StatePath, BackgroundFormat: String; Width, Height: Integer);
var
  Lines: TArrayOfString;
  I: Integer;
  BackgroundFound: Boolean;
  ResolutionFound: Boolean;
begin
  if not FileExists(StatePath) then
  begin
    Log('Active profile state absent; resolution state was not updated.');
    Exit;
  end;

  if not LoadStringsFromFile(StatePath, Lines) then
  begin
    Log('Could not read active-profile.txt.');
    Exit;
  end;

  BackgroundFound := False;
  ResolutionFound := False;
  for I := 0 to GetArrayLength(Lines) - 1 do
  begin
    if Pos('background=', Lines[I]) = 1 then
    begin
      Lines[I] := 'background=' + BackgroundFormat;
      BackgroundFound := True;
    end
    else if Pos('resolution=', Lines[I]) = 1 then
    begin
      Lines[I] := 'resolution=' + IntToStr(Width) + 'x' + IntToStr(Height);
      ResolutionFound := True;
    end;
  end;

  if BackgroundFound and ResolutionFound then
  begin
    if not SaveStringsToFile(StatePath, Lines, False) then
      Log('Could not update active-profile.txt.');
  end
  else
    Log('active-profile.txt does not contain the expected resolution fields.');
end;

procedure ApplyNativeResolution;
var
  Root: String;
  ConfPath: String;
  StatePath: String;
  BackgroundFormat: String;
  BackgroundSource: String;
  BackgroundDestination: String;
  Width: Integer;
  Height: Integer;
begin
  Width := GetSystemMetrics(SM_CXSCREEN);
  Height := GetSystemMetrics(SM_CYSCREEN);
  if (Width < 640) or (Height < 480) then
  begin
    Log('Native display resolution could not be detected.');
    Exit;
  end;

  Root := AddBackslash(ExpandConstant('{app}'));
  ConfPath := Root + 'conf.ini';
  if not FileExists(ConfPath) then
  begin
    Log('conf.ini absent; native resolution was not applied.');
    Exit;
  end;

  if not SetIniString('window', 'width', IntToStr(Width), ConfPath) then
    Log('Could not update conf.ini width.');
  if not SetIniString('window', 'height', IntToStr(Height), ConfPath) then
    Log('Could not update conf.ini height.');
  if not SetIniString('window', 'ChangeScreenRes', '1', ConfPath) then
    Log('Could not update conf.ini ChangeScreenRes.');
  if not SetIniString('window', 'FullScreen', '1', ConfPath) then
    Log('Could not update conf.ini FullScreen.');
  if not SetIniString('window', 'SaveAspect', '0', ConfPath) then
    Log('Could not update conf.ini SaveAspect.');

  if Width * 1000 <= Height * 1420 then
    BackgroundFormat := '4x3'
  else if Width * 1000 <= Height * 1700 then
    BackgroundFormat := '16x10'
  else if Width * 1000 <= Height * 2050 then
    BackgroundFormat := '16x9'
  else if Width * 1000 <= Height * 2800 then
    BackgroundFormat := '21x9'
  else
    BackgroundFormat := '32x9';

  BackgroundSource := Root + '_Game Switcher\Resources\Loading Backgrounds\Maddox\' +
    BackgroundFormat + '\Background.tga';
  BackgroundDestination := Root + 'Files\background0.tga';
  if not FileExists(BackgroundSource) then
    Log('Native loading background absent: ' + BackgroundSource)
  else
  begin
    ForceDirectories(ExtractFileDir(BackgroundDestination));
    if not FileCopy(BackgroundSource, BackgroundDestination, False) then
      Log('Could not apply native loading background: ' + BackgroundSource);
  end;

  StatePath := Root + '_Game Switcher\active-profile.txt';
  UpdateActiveProfileResolution(
    StatePath, BackgroundFormat, Width, Height);
  Log('Native resolution applied: ' + IntToStr(Width) + 'x' +
    IntToStr(Height) + ', loading background ' + BackgroundFormat + '.');
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  MarkerPath: String;
begin
  if CurStep = ssPostInstall then
    ApplyNativeResolution;

  if CurStep = ssDone then
  begin
    MarkerPath :=
      AddBackslash(ExpandConstant('{app}')) +
      '.open-sturmovik-installed';
    if not SaveStringToFile(
      MarkerPath, 'Open Sturmovik {#AppVersion}' + #13#10, False) then
      Log('Could not write the Open Sturmovik installation marker.');
    if IncompleteMarkerCreated and FileExists(IncompleteMarkerPath) and
       not DeleteFile(IncompleteMarkerPath) then
      Log('Could not remove the incomplete installation marker.');
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
