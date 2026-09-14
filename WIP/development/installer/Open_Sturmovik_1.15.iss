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
SetupIconFile=assets\exec-0631d7c4__avion-carte__Windows.ico
WizardStyle=modern dynamic
WizardBackColor=#101820
WizardBackColorDynamicDark=#101820
WizardBackImageFile=assets\backgrounds\01.png
WizardBackImageFileDynamicDark=assets\backgrounds\01.png
WizardBackImageOpacity=112
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
english.IncompleteMarkerFailed=Setup could not prepare interrupted-installation recovery. No Open Sturmovik file has been copied.
french.IncompleteMarkerFailed=L'installeur n'a pas pu préparer la reprise après interruption. Aucun fichier d'Open Sturmovik n'a été copié.

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

[Code]
const
  BackgroundCount = 8;
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
  BackgroundsPrepared: Boolean;
  LastBackgroundIndex: Integer;
  InstallCard: TPanel;
  InstallAccentBar: TPanel;
  InstallDivider: TPanel;
  InstallProgressTrack: TPanel;
  InstallProgressFill: TPanel;
  InstallTitleLabel: TNewStaticText;
  InstallTaglineLabel: TNewStaticText;
  InstallPercentLabel: TNewStaticText;

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

procedure PrepareInstallBackgrounds;
var
  I: Integer;
  FileName: String;
begin
  if BackgroundsPrepared then
    Exit;

  { Extract all images before the main file extractor starts. Calling
    ExtractTemporaryFile from CurInstallProgressChanged is recursive and can
    flood the log until Setup terminates. }
  BackgroundsPrepared := True;
  for I := 1 to BackgroundCount do
  begin
    FileName := Format('0%d.png', [I]);
    try
      ExtractTemporaryFile(FileName);
    except
      Log(Format('Could not preload installer background %s: %s', [FileName, GetExceptionMessage]));
    end;
  end;
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

  PrepareInstallBackgrounds;

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

  { Mark the interval before loading, so one bad image cannot be retried for
    every file in the payload. }
  LastBackgroundIndex := Index;
  FileName := Format('0%d.png', [Index + 1]);
  if not FileExists(ExpandConstant('{tmp}\' + FileName)) then
  begin
    Log('Installer background was not preloaded: ' + FileName);
    Exit;
  end;

  try
    SetLength(Images, 1);
    Images[0] := TPngImage.Create;
    try
      Images[0].LoadFromFile(ExpandConstant('{tmp}\' + FileName));
      WizardSetBackImage(Images, True, True, 112);
    finally
      Images[0].Free;
    end;
  except
    Log(Format('Could not display installer background %s: %s', [FileName, GetExceptionMessage]));
  end;
end;

procedure ConfigureInstallPage;
begin
  WizardForm.PageNameLabel.StyleElements :=
    WizardForm.PageNameLabel.StyleElements - [seFont];
  WizardForm.PageNameLabel.Font.Color := clWhite;
  WizardForm.PageNameLabel.Font.Style := [fsBold];
  WizardForm.PageDescriptionLabel.StyleElements :=
    WizardForm.PageDescriptionLabel.StyleElements - [seFont];
  WizardForm.PageDescriptionLabel.Font.Color := StrToColor('#DCE6EA');

  { A restrained installer card inspired by classic InstallShield layouts. }
  InstallCard := TPanel.Create(WizardForm);
  InstallCard.Parent := WizardForm.InstallingPage;
  InstallCard.Left := ScaleX(22);
  InstallCard.Top := ScaleY(26);
  InstallCard.Width :=
    WizardForm.InstallingPage.ClientWidth - ScaleX(44);
  InstallCard.Height := ScaleY(210);
  InstallCard.Caption := '';
  InstallCard.Color := StrToColor('#17242C');
  InstallCard.BevelKind := bkFlat;
  InstallCard.BevelOuter := bvNone;
  InstallCard.ParentBackground := False;

  InstallAccentBar := TPanel.Create(WizardForm);
  InstallAccentBar.Parent := InstallCard;
  InstallAccentBar.Left := 0;
  InstallAccentBar.Top := 0;
  InstallAccentBar.Width := ScaleX(4);
  InstallAccentBar.Height := InstallCard.Height;
  InstallAccentBar.Caption := '';
  InstallAccentBar.Color := StrToColor('#9C332D');
  InstallAccentBar.BevelOuter := bvNone;
  InstallAccentBar.ParentBackground := False;

  InstallTitleLabel := TNewStaticText.Create(WizardForm);
  InstallTitleLabel.Parent := InstallCard;
  InstallTitleLabel.AutoSize := False;
  InstallTitleLabel.Left := ScaleX(24);
  InstallTitleLabel.Top := ScaleY(16);
  InstallTitleLabel.Width := InstallCard.Width - ScaleX(48);
  InstallTitleLabel.Height := ScaleY(38);
  InstallTitleLabel.Caption := 'Open Sturmovik';
  InstallTitleLabel.StyleElements :=
    InstallTitleLabel.StyleElements - [seFont];
  InstallTitleLabel.Font.Name := 'Segoe UI';
  InstallTitleLabel.Font.Size := 24;
  InstallTitleLabel.Font.Style := [fsBold];
  InstallTitleLabel.Font.Color := clWhite;

  InstallTaglineLabel := TNewStaticText.Create(WizardForm);
  InstallTaglineLabel.Parent := InstallCard;
  InstallTaglineLabel.AutoSize := False;
  InstallTaglineLabel.Left := ScaleX(26);
  InstallTaglineLabel.Top := ScaleY(55);
  InstallTaglineLabel.Width := InstallCard.Width - ScaleX(52);
  InstallTaglineLabel.Height := ScaleY(20);
  InstallTaglineLabel.Caption :=
    'Made possible by the community, for the community';
  InstallTaglineLabel.StyleElements :=
    InstallTaglineLabel.StyleElements - [seFont];
  InstallTaglineLabel.Font.Name := 'Segoe UI';
  InstallTaglineLabel.Font.Size := 9;
  InstallTaglineLabel.Font.Color := StrToColor('#B9C7CD');

  InstallDivider := TPanel.Create(WizardForm);
  InstallDivider.Parent := InstallCard;
  InstallDivider.Left := ScaleX(24);
  InstallDivider.Top := ScaleY(82);
  InstallDivider.Width := InstallCard.Width - ScaleX(48);
  InstallDivider.Height := 1;
  InstallDivider.Caption := '';
  InstallDivider.Color := StrToColor('#52616A');
  InstallDivider.BevelOuter := bvNone;
  InstallDivider.ParentBackground := False;

  WizardForm.StatusLabel.Parent := InstallCard;
  WizardForm.StatusLabel.AutoSize := False;
  WizardForm.StatusLabel.Left := ScaleX(24);
  WizardForm.StatusLabel.Top := ScaleY(98);
  WizardForm.StatusLabel.Width := InstallCard.Width - ScaleX(126);
  WizardForm.StatusLabel.Height := ScaleY(20);
  WizardForm.StatusLabel.StyleElements :=
    WizardForm.StatusLabel.StyleElements - [seFont];
  WizardForm.StatusLabel.Font.Color := clWhite;
  WizardForm.StatusLabel.Font.Style := [fsBold];

  InstallPercentLabel := TNewStaticText.Create(WizardForm);
  InstallPercentLabel.Parent := InstallCard;
  InstallPercentLabel.AutoSize := False;
  InstallPercentLabel.Left := InstallCard.Width - ScaleX(94);
  InstallPercentLabel.Top := ScaleY(95);
  InstallPercentLabel.Width := ScaleX(70);
  InstallPercentLabel.Height := ScaleY(24);
  InstallPercentLabel.Alignment := taRightJustify;
  InstallPercentLabel.Caption := '0 %';
  InstallPercentLabel.StyleElements :=
    InstallPercentLabel.StyleElements - [seFont];
  InstallPercentLabel.Font.Color := clWhite;
  InstallPercentLabel.Font.Style := [fsBold];
  InstallPercentLabel.Font.Size := 11;

  WizardForm.FilenameLabel.Parent := InstallCard;
  WizardForm.FilenameLabel.AutoSize := False;
  WizardForm.FilenameLabel.Left := ScaleX(24);
  WizardForm.FilenameLabel.Top := ScaleY(124);
  WizardForm.FilenameLabel.Width := InstallCard.Width - ScaleX(48);
  WizardForm.FilenameLabel.Height := ScaleY(34);
  WizardForm.FilenameLabel.WordWrap := True;
  WizardForm.FilenameLabel.StyleElements :=
    WizardForm.FilenameLabel.StyleElements - [seFont];
  WizardForm.FilenameLabel.Font.Color := StrToColor('#DCE6EA');

  WizardForm.ProgressGauge.Visible := False;

  InstallProgressTrack := TPanel.Create(WizardForm);
  InstallProgressTrack.Parent := InstallCard;
  InstallProgressTrack.Left := ScaleX(24);
  InstallProgressTrack.Top := ScaleY(170);
  InstallProgressTrack.Width := InstallCard.Width - ScaleX(48);
  InstallProgressTrack.Height := ScaleY(18);
  InstallProgressTrack.Caption := '';
  InstallProgressTrack.Color := StrToColor('#34434C');
  InstallProgressTrack.BevelKind := bkFlat;
  InstallProgressTrack.BevelOuter := bvNone;
  InstallProgressTrack.ParentBackground := False;

  InstallProgressFill := TPanel.Create(WizardForm);
  InstallProgressFill.Parent := InstallProgressTrack;
  InstallProgressFill.Left := 1;
  InstallProgressFill.Top := 1;
  InstallProgressFill.Width := 1;
  InstallProgressFill.Height := InstallProgressTrack.Height - 2;
  InstallProgressFill.Caption := '';
  InstallProgressFill.Color := StrToColor('#568A4B');
  InstallProgressFill.BevelOuter := bvNone;
  InstallProgressFill.ParentBackground := False;
end;
procedure CurInstallProgressChanged(
  CurProgress, MaxProgress: Integer);
var
  Index: Integer;
  FillWidth: Integer;
begin
  if MaxProgress <= 0 then
    Exit;

  FillWidth :=
    ((InstallProgressTrack.Width - 2) * CurProgress) div MaxProgress;
  if FillWidth < 1 then
    FillWidth := 1;
  if FillWidth > InstallProgressTrack.Width - 2 then
    FillWidth := InstallProgressTrack.Width - 2;
  InstallProgressFill.Width := FillWidth;
  InstallPercentLabel.Caption :=
    Format('%d %%', [(CurProgress * 100) div MaxProgress]);

  Index := (CurProgress * BackgroundCount) div MaxProgress;
  SetInstallBackground(Index);
end;

procedure InitializeWizard;
begin
  ConfBackupCreated := False;
  ConfBackupPrepared := False;
  InstallCompleted := False;
  IncompleteMarkerCreated := False;
  IncompleteMarkerPath := '';
  BackgroundsPrepared := False;
  LastBackgroundIndex := -1;
  ConfigureInstallPage;
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
  if CurStep = ssInstall then
    SetInstallBackground(0);

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
