#define Name "RoguePatcher"
#define Version "1.28.2"
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
Name: "dmm"; Description: "Dark Mod Manager";
Name: "mods"; Description: "Mods";
Name: "mods\fmdml"; Description: "Fan Mission DML fixes";
Name: "mods\am16sfixed"; Description: "AM16's Bugfixed Original Missions";

[Tasks]
Name: "dromedhw"; Description: "Enable hardware rendering mode"; GroupDescription: "DromEd:"; Components: dromed;
Name: "objids"; Description: "Use increased ObjID ranges"; GroupDescription: "DromEd:"; Components: dromed;

Name: "newmantle"; Description: "Enable NewDark mantling"; GroupDescription: "General Tweaks:";
Name: "fmsel"; Description: "Enable built-in fan mission launcher"; GroupDescription: "General Tweaks:";
Name: "fpsfix"; Description: "Fix physics issues at high framerates"; GroupDescription: "General Tweaks:";
Name: "swgamma"; Description: "Enable gamma correct screenshots and windowed mode"; GroupDescription: "General Tweaks:";
Name: "stutterfix"; Description: "Reduce micro stutter and mouse lag (Not recommended on CrossFire/SLI setups)"; GroupDescription: "General Tweaks:";
Name: "smallportal"; Description: "Reduce camera jolt near complex geometry and doorways"; GroupDescription: "General Tweaks:";
Name: "texfilter"; Description: "Disable texture filtering for a retro look"; GroupDescription: "General Tweaks:"; Flags: unchecked
Name: "windowed"; Description: "Enable windowed mode"; GroupDescription: "General Tweaks:"; Flags: unchecked

[Files]
Source: "Resources\NewDark\*"; DestDir: "{app}"; Components: newdark; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Missing\*"; DestDir: "{app}"; Components: newdark; Flags: onlyifdoesntexist
Source: "Resources\DromEd\*"; DestDir: "{app}"; Components: dromed; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Basic Toolkit\*"; DestDir: "{app}"; Components: dromed\toolkit; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Multiplayer\*"; DestDir: "{app}"; Components: multiplayer; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\DMM\*"; DestDir: {app}; Components: dmm; Flags: ignoreversion
Source: "Resources\Mods\TGFMDML\*"; DestDir: "{app}\MODS\TGFMDML"; Components: mods\fmdml; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "Resources\Mods\AM16s Thief1 Fixed\*"; DestDir: "{app}\MODS\AM16s Thief1 Fixed"; Components: mods\am16sfixed; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "darkicon.ico"; DestDir: "{app}"; AfterInstall: PerformTasks

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to the {#Name} Wizard
WelcomeLabel2=This will install the latest NewDark patch for Thief: The Dark Project and Thief: Gold. A full installation of either game is required and a fresh unmodded install is assumed.%n%nThis patcher keeps the game as close to vanilla as possible and attempts to ensure maximum compatibility with fan mission projects.%n%nNote: Many changes made by this installer are irreversible. It is recommended you backup your game before continuing with the installation.

[Code]
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

procedure PerformTasks();
var
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
  EditConfigLine('install.cfg', GetLineContaining('install.cfg', 'script_module_path'), 'script_module_path .\');
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

  if WizardIsComponentSelected('mods') then
    begin
      Mods := '';
      if WizardIsComponentSelected('mods\fmdml') then
        AddPath(Mods, '.\MODS\TGFMDML');
      if WizardIsComponentSelected('mods\am16sfixed') then
        AddPath(Mods, '.\MODS\AM16s Thief1 Fixed');

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
