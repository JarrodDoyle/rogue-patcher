#define Name "RoguePatcher"
#define Version "1.28.3"
#define Publisher "Jarrod Doyle"
#define URL "https://jayrude.dev/"

[Setup]
AppName={#Name}
AppVersion={#Version}
AppPublisher={#Publisher}
AppPublisherURL={#URL}
AppendDefaultDirName=no
Compression=lzma/ultra64
DefaultDirName=C:\Games\Thief Gold
DirExistsWarning=no
DisableDirPage=no
DisableProgramGroupPage=yes
DisableWelcomePage=no
InfoBeforeFile=info.txt
OutputDir=Z:\work\Build
OutputBaseFilename={#Name}_{#Version}
PrivilegesRequired=lowest
SolidCompression=yes
SetupIconFile=darkicon.ico
Uninstallable=no
WizardImageFile=thiefgold.bmp
WizardSmallImageFile=darkicon.bmp
WizardStyle=modern

[Types]
Name: "custom"; Description: "Custom"; Flags: iscustom

[Components]
Name: "newdark"; Description: "NewDark"; Types: custom; Flags: fixed;
Name: "dromed"; Description: "DromEd";
Name: "dromed\toolkit"; Description: "DromEd Basic Toolkit";
Name: "multiplayer"; Description: "Multiplayer (Experimental)";
Name: "comscripts"; Description: "Common FM Scripts (NVScript, LGScript, PublicScripts)";
Name: "binds"; Description: "Modern Key Bindings";
Name: "dmm"; Description: "Dark Mod Manager";
Name: "mods"; Description: "Mods";
Name: "mods\fixedres"; Description: "Fixed Resources";
Name: "mods\fmdml"; Description: "Fan Mission DML fixes";
Name: "mods\tgremastered"; Description: "Remastered Original Missions";
Name: "mods\objectivedings"; Description: "Thief 2 Style Objective Notifications";

[Tasks]
Name: "dromedhw"; Description: "Enable hardware rendering mode"; GroupDescription: "DromEd:"; Components: dromed;
Name: "objids"; Description: "Use increased ObjID ranges"; GroupDescription: "DromEd:"; Components: dromed;

Name: "cleanupsteam"; Description: "Remove conflicting Steam template files"; GroupDescription: "Cleanup:"; Check: IsSteamInstall;
Name: "cleanuptfix"; Description: "Remove conflicting Tfix/Tfix Lite files"; GroupDescription: "Cleanup:"; Check: IsTfixInstall;
Name: "cleanupgog"; Description: "Remove GOG files"; GroupDescription: "Cleanup:"; Check: IsGogInstall;

Name: "newmantle"; Description: "Enable NewDark mantling"; GroupDescription: "General Tweaks:";
Name: "fmsel"; Description: "Enable built-in fan mission launcher"; GroupDescription: "General Tweaks:";
Name: "sfxchannels"; Description: "Set max audio channels"; GroupDescription: "General Tweaks:";

Name: "res"; Description: "Set game resolution to current display resolution"; GroupDescription: "Graphics:";
Name: "swgamma"; Description: "Fix gamma in screenshots and windowed mode"; GroupDescription: "Graphics:";
Name: "msaa"; Description: "Enable Multisample Anti-Aliasing"; GroupDescription: "Graphics:";
Name: "windowed"; Description: "Enable windowed mode"; GroupDescription: "Graphics:"; Flags: unchecked
Name: "texfilter"; Description: "Disable texture filtering for a retro look"; GroupDescription: "Graphics:"; Flags: unchecked

Name: "fpsfix"; Description: "Fix physics issues at high framerates"; GroupDescription: "Performance:";
Name: "stutterfix"; Description: "Reduce micro stutter and mouse lag (Not recommended on CrossFire/SLI setups)"; GroupDescription: "Performance:";
Name: "smallportal"; Description: "Reduce camera jolt near complex geometry and doorways"; GroupDescription: "Performance:";

[Files]
Source: "Resources\NewDark\*"; DestDir: "{app}"; Components: newdark; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Missing\*"; DestDir: "{app}"; Components: newdark; Flags: onlyifdoesntexist
Source: "Resources\DromEd\*"; DestDir: "{app}"; Components: dromed; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Basic Toolkit\*"; DestDir: "{app}"; Components: dromed\toolkit; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Multiplayer\*"; DestDir: "{app}"; Components: multiplayer; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Common Scripts\*"; DestDir: {app}; Components: comscripts; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Binds\*"; DestDir: "{app}"; Components: binds; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\DMM\*"; DestDir: {app}; Components: dmm; Flags: ignoreversion
Source: "Resources\Mods\Fixed Resources\*"; DestDir: "{app}\MODS\Fixed Resources"; Components: mods\fixedres; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Mods\TGFMDML\*"; DestDir: "{app}\MODS\TGFMDML"; Components: mods\fmdml; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Mods\TG Remastered Missions\*"; DestDir: "{app}\MODS\TG Remastered Missions"; Components: mods\tgremastered; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Mods\Objective Notifications\*"; DestDir: "{app}\MODS\Objective Notifications"; Components: mods\objectivedings; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "darkicon.ico"; DestDir: "{app}"; AfterInstall: PerformTasks

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to the {#Name} Wizard
WelcomeLabel2=This will install the latest NewDark patch for Thief: The Dark Project and Thief: Gold. A full installation of either game is required and a fresh unmodded install is assumed.%n%nThis patcher keeps the game as close to vanilla as possible and attempts to ensure maximum compatibility with fan mission projects.%n%nNote: Many changes made by this installer are irreversible. It is recommended you backup your game before continuing with the installation.

[Code]
{ Primary monitor resolution. See: https://stackoverflow.com/questions/5461674/inno-setup-how-to-get-the-primary-monitors-resolution }
function GetSystemMetrics (nIndex: Integer): Integer;
  external 'GetSystemMetrics@User32.dll stdcall setuponly';
Const
    SM_CXSCREEN = 0;
    SM_CYSCREEN = 1;

function IsSteamInstall: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\Steam_install.cfg'));
end;

function IsTfixInstall: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\miss1.mis.dml'));
end;

function IsGogInstall: Boolean;
begin
  Result := FileExists(ExpandConstant('{app}\gog.ico'));
end;

procedure EditConfigLine(File, TargetLine, NewLine: String);
var
  LineIndex: Integer;
  StringList: TStringList;
  FileName: String;
begin
  FileName := WizardDirValue + '\' + File;
  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(FileName);
    LineIndex := StringList.IndexOf(TargetLine);
    if LineIndex <> -1 then
      StringList[LineIndex] := NewLine
    else
      if StringList.IndexOf(NewLine) = -1 then
        StringList.Insert(StringList.Count, NewLine);
    StringList.SaveToFile(FileName);
  finally
    StringList.Free;
  end;
end;

procedure AddPath(var PathVar: String; NewPath: String);
begin
  if (Length(PathVar) <> 0) then
    PathVar := PathVar + '+';
  PathVar := PathVar + NewPath;
end;

function GetLineContaining(File, TargetString: String): String;
var
  i: Integer;
  StringList: TStringList;
  FileName: String;
begin
  FileName := WizardDirValue + '\' + File;
  StringList := TStringList.Create;
  try
    StringList.LoadFromFile(FileName);
    Result := '';
    for i:=0 to StringList.Count-1 do
      if Pos(TargetString, StringList[i]) <> 0 then
        begin
          Result := StringList[i];
          break;
        end;
  finally
    StringList.Free;
  end;
end;

procedure SteamCleanUp();
begin
    if IsSteamInstall() then begin
      DeleteFile(ExpandConstant('{app}\Steam_install.cfg'));
      DeleteFile(ExpandConstant('{app}\211600_install.vdf'));
      DeleteFile(ExpandConstant('{app}\unins000.exe'));
      DeleteFile(ExpandConstant('{app}\unins000.dat'));
      DeleteFile(ExpandConstant('{app}\innosetup_license.txt'));
    end;
end;

procedure TfixCleanUp();
begin
    if IsTfixInstall() then begin
      DeleteFile(ExpandConstant('{app}\gamesys.dml'));
      DeleteFile(ExpandConstant('{app}\miss1.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss2.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss3.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss4.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss5.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss6.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss7.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss9.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss10.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss11.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss12.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss13.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss14.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss15.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss16.mis.dml'));
      DeleteFile(ExpandConstant('{app}\miss17.mis.dml'));
      DeleteFile(ExpandConstant('{app}\release_notes.txt'));
      DeleteFile(ExpandConstant('{app}\TFix_readme.txt'));
      DeleteFile(ExpandConstant('{app}\!FMselect.lnk'));
      DeleteFile(ExpandConstant('{app}\enhanced.bat'));
      DeleteFile(ExpandConstant('{app}\safemode.bat'));
      DelTree(ExpandConstant('{app}\doc'), true, true, true);
      DelTree(ExpandConstant('{app}\patches'), true, true, true);
    end;
end;

procedure GogCleanUp();
begin
  if IsGogInstall() then begin
    DeleteFile(ExpandConstant('{app}\gog.ico'));
    DeleteFile(ExpandConstant('{app}\goggame-1207658997.hashdb'));
    DeleteFile(ExpandConstant('{app}\goggame-1207658997.ico'));
    DeleteFile(ExpandConstant('{app}\goggame-1207658997.info'));
    DeleteFile(ExpandConstant('{app}\goggame-galaxyFileList.ini'));
    DeleteFile(ExpandConstant('{app}\goglog.ini'));
    DeleteFile(ExpandConstant('{app}\Launch Thief Gold.lnk'));
    DeleteFile(ExpandConstant('{app}\webcache.zip'));
    DeleteFile(ExpandConstant('{app}\support.ico'));
    DeleteFile(ExpandConstant('{app}\unins000.dat'));
    DeleteFile(ExpandConstant('{app}\unins000.exe'));
    DeleteFile(ExpandConstant('{app}\unins000.ini'));
    DeleteFile(ExpandConstant('{app}\unins000.msg'));
  end;
end;

procedure PerformTasks();
var
  ResX: Integer;
  ResY: Integer;
  Mods: String;
begin
  // Make sure things work properly with T1
  EditConfigLine('cam.cfg', 'dark1', 'dark1');

  // Realistically weather and fog should always be enabled
  EditConfigLine('cam.cfg', GetLineContaining('cam.cfg', 'render_weather'), 'render_weather 1');
  EditConfigLine('cam.cfg', GetLineContaining('cam.cfg', 'enhanced_sky'), 'enhanced_sky 1');
  EditConfigLine('cam.cfg', GetLineContaining('cam.cfg', 'fogging'), 'fogging 1');

  // Fix up install.cfg to use relative paths
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'install_path'), 'install_path .\');
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'resname_base'), 'resname_base .\RES');
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'load_path'), 'load_path .\');
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'script_module_path'), 'script_module_path .\+.\OSM');
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'movie_path'), 'movie_path .\MOVIES');

  if WizardIsTaskSelected('dromedhw') then
    begin
      EditConfigLine('DromEd.cfg', 'edit_screen_depth 16', ';edit_screen_depth 16');
      EditConfigLine('DromEd.cfg', ';editor_disable_gdi', 'editor_disable_gdi');
      EditConfigLine('DromEd.cfg', ';edit_screen_depth 32', 'edit_screen_depth 32');
    end;
  if WizardIsTaskSelected('objids') then
    begin
      EditConfigLine('dark.cfg', GetLineContaining('dark.cfg', 'obj_min'), 'obj_min -18192');
      EditConfigLine('dark.cfg', GetLineContaining('dark.cfg', 'obj_max'), 'obj_max 8184');
      EditConfigLine('dark.cfg', GetLineContaining('dark.cfg', 'max_refs'), 'max_refs 47740');
    end;

  // Cleanup prior installs. Note that we delete Squirrel.osm from the root because we now install it to the OSMs folder
  DeleteFile(ExpandConstant('{app}\squirrel.osm'));
  if WizardIsTaskSelected('cleanupsteam') then
    SteamCleanUp();
  if WizardIsTaskSelected('cleanuptfix') then
    TfixCleanUp();
  if WizardIsTaskSelected('cleanupgog') then
    GogCleanUp();

  if WizardIsTaskSelected('newmantle') then
    EditConfigLine('cam_ext.cfg', ';new_mantle', 'new_mantle');
  if WizardIsTaskSelected('fmsel') then
    EditConfigLine('cam_mod.ini', ';fm', 'fm');
  if WizardIsTaskSelected('fpsfix') then
    begin
      EditConfigLine('cam_ext.cfg', 'framerate_cap 100.0', 'framerate_cap 240.0');
      EditConfigLine('cam_ext.cfg', ';phys_freq 60', 'phys_freq 60');
    end;
  if WizardIsTaskSelected('swgamma') then
    EditConfigLine('cam_ext.cfg', ';d3d_disp_sw_cc', 'd3d_disp_sw_cc');
  if WizardIsTaskSelected('stutterfix') then
    begin
      EditConfigLine('cam_ext.cfg', 'd3d_disp_limit_gpu_frames 1', ';d3d_disp_limit_gpu_frames 1');
      EditConfigLine('cam_ext.cfg', ';d3d_disp_limit_gpu_frames 1 1', 'd3d_disp_limit_gpu_frames 1 1');
    end;
  if WizardIsTaskSelected('smallportal') then
    EditConfigLine('cam_ext.cfg', ';small_portal_repel', 'small_portal_repel');
  if WizardIsTaskSelected('texfilter') then
    EditConfigLine('cam_ext.cfg', 'tex_filter_mode 16', 'tex_filter_mode 0');
  if WizardIsTaskSelected('windowed') then
    EditConfigLine('cam_ext.cfg', ';force_windowed', 'force_windowed');
  if WizardIsTaskSelected('msaa') then
    EditConfigLine('cam_ext.cfg', ';multisampletype 8', 'multisampletype 8');
  if WizardIsTaskSelected('res') then
    begin
      ResX := GetSystemMetrics(SM_CXSCREEN);
      ResY := GetSystemMetrics(SM_CYSCREEN);
      EditConfigLine('cam.cfg', GetLineContaining('cam.cfg', 'game_screen_size'), 'game_screen_size ' + IntToStr(ResX) + ' ' + IntToStr(ResY));
    end;
    if WizardIsTaskSelected('sfxchannels') then
      EditConfigLine('cam.cfg', GetLineContaining('cam.cfg', 'sfx_channels'), 'sfx_channels 48');

  if WizardIsComponentSelected('mods') then
    begin
      Mods := '';
      if WizardIsComponentSelected('mods\fixedres') then
        AddPath(Mods, '.\MODS\Fixed Resources');
      if WizardIsComponentSelected('mods\fmdml') then
        AddPath(Mods, '.\MODS\TGFMDML');
      if WizardIsComponentSelected('mods\tgremastered') then
        AddPath(Mods, '.\MODS\TG Remastered Missions');
      if WizardIsComponentSelected('mods\objectivedings') then
        AddPath(Mods, '.\MODS\Objective Notifications');

      if (Length(Mods) <> 0) then
        EditConfigLine('cam_mod.ini', ';mod_path MyBowMod+.\TexturePack', 'mod_path ' + Mods);
    end;
end;

function NextButtonClick(PageId: Integer): Boolean;
begin
  Result := True;
  if (PageId = wpSelectDir) and not FileExists(ExpandConstant('{app}\thief.exe')) then begin
    MsgBox('A Thief 1 install was not found in the specified directory.  Please select a directory in which the game is installed.', mbError, MB_OK);
    Result := False;
    exit;
  end;
end;
