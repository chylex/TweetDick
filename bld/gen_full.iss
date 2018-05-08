; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "TweetDuck"
#define MyAppPublisher "chylex"
#define MyAppURL "https://tweetduck.chylex.com"
#define MyAppShortURL "https://td.chylex.com"
#define MyAppExeName "TweetDuck.exe"

#define MyAppVersion GetFileVersion("..\bin\x86\Release\TweetDuck.exe")
#define VCRedistLink "releases/download/1.13/vc_redist.x86.exe"

[Setup]
AppId={{8C25A716-7E11-4AAD-9992-8B5D0C78AE06}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputBaseFilename={#MyAppName}
VersionInfoVersion={#MyAppVersion}
SetupIconFile=.\Resources\icon.ico
CloseApplicationsFilter=*.exe,*.dll,*.pak
RestartApplications=False
Uninstallable=TDIsUninstallable
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/ultra
LZMADictionarySize=15360
SolidCompression=yes
InternalCompressLevel=normal
MinVersion=0,6.1

#include <idp.iss>

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalTasks}"; Flags: unchecked
Name: "devtools"; Description: "{cm:TaskDevTools}"; GroupDescription: "{cm:AdditionalTasks}"; Flags: unchecked

[Files]
Source: "..\bin\x86\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\bin\x86\Release\devtools_resources.pak"; DestDir: "{app}"; Flags: ignoreversion; Tasks: devtools
Source: "..\bin\x86\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "devtools_resources.pak"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Check: TDIsUninstallable
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall shellexec skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\*.*"
Type: filesandordirs; Name: "{app}\locales"
Type: filesandordirs; Name: "{app}\scripts"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}\Cache"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}\GPUCache"

[CustomMessages]
AdditionalTasks=Additional shortcuts and components:
TaskDevTools=Install dev tools

[Code]
var UpdatePath: String;
var ForceRedistPrompt: String;
var VisitedTasksPage: Boolean;

function TDGetNetFrameworkVersion: Cardinal; forward;
function TDIsVCMissing: Boolean; forward;
procedure TDInstallVCRedist; forward;

{ Check .NET Framework version on startup, ask user if they want to proceed if older than 4.5.2. }
function InitializeSetup: Boolean;
begin
  UpdatePath := ExpandConstant('{param:UPDATEPATH}')
  ForceRedistPrompt := ExpandConstant('{param:PROMPTREDIST}')
  VisitedTasksPage := False
  
  if (TDGetNetFrameworkVersion() < 379893) and (MsgBox('{#MyAppName} requires .NET Framework 4.5.2 or newer,'+#13+#10+'please visit {#MyAppShortURL} for a download link.'+#13+#10+#13+#10'Do you want to proceed with the setup anyway?', mbCriticalError, MB_YESNO or MB_DEFBUTTON2) = IDNO) then
  begin
    Result := False
    Exit
  end;
  
  if (TDIsVCMissing() or (ForceRedistPrompt = '1')) and (MsgBox('Microsoft Visual C++ 2015 appears to be missing, would you like to automatically install it?', mbConfirmation, MB_YESNO) = IDYES) then
  begin
    idpAddFile('https://github.com/{#MyAppPublisher}/{#MyAppName}/{#VCRedistLink}', ExpandConstant('{tmp}\{#MyAppName}.VC.exe'))
  end;
  
  Result := True
end;

{ Set the installation path if updating, and prepare download plugin if there are any files to download. }
procedure InitializeWizard();
begin
  if (UpdatePath <> '') then
  begin
    WizardForm.DirEdit.Text := UpdatePath
  end;
  
  if (idpFilesCount <> 0) then
  begin
    idpDownloadAfter(wpReady)
  end;
end;

{ Skip the install path selection page if running from an update installer. }
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := (PageID = wpSelectDir) and (UpdatePath <> '')
end;

{ Check the desktop icon task if not updating, and dev tools task if already installed. }
procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpSelectTasks) and (not VisitedTasksPage) then
  begin
    WizardForm.TasksList.Checked[WizardForm.TasksList.Items.Count-2] := (UpdatePath = '')
    WizardForm.TasksList.Checked[WizardForm.TasksList.Items.Count-1] := FileExists(ExpandConstant('{app}\devtools_resources.pak'))
    VisitedTasksPage := True
  end;
end;

{ Install VC++ if downloaded. }
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
  begin
    TDInstallVCRedist()
  end;
end;

{ Ask user if they want to delete 'AppData\TweetDuck' and 'plugins' folders after uninstallation. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var ProfileDataFolder: String;
var PluginDataFolder: String;

begin
  if CurUninstallStep = usPostUninstall then
  begin
    ProfileDataFolder := ExpandConstant('{localappdata}\{#MyAppName}')
    PluginDataFolder := ExpandConstant('{app}\plugins')
    
    if (DirExists(ProfileDataFolder) or DirExists(PluginDataFolder)) and (MsgBox('Do you also want to delete your {#MyAppName} profile and plugins?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES) then
    begin
      DelTree(ProfileDataFolder, True, True, True)
      DelTree(PluginDataFolder, True, True, True)
      DelTree(ExpandConstant('{app}'), True, False, False)
    end;
  end;
end;

{ Returns true if the installer should create uninstallation entries (i.e. not running in full update mode). }
function TDIsUninstallable: Boolean;
begin
  Result := (UpdatePath = '')
end;

{ Return DWORD value containing the build version of .NET Framework. }
function TDGetNetFrameworkVersion: Cardinal;
var FrameworkVersion: Cardinal;

begin
  if RegQueryDWordValue(HKEY_LOCAL_MACHINE, 'Software\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', FrameworkVersion) then
  begin
    Result := FrameworkVersion
    Exit
  end;
  
  Result := 0
end;

{ Check if Visual C++ 2015 or 2017 is installed. }
function TDIsVCMissing: Boolean;
var Keys: TArrayOfString;
var Index: Integer;
var Key: String;
var DisplayName: String;

begin
  if RegGetSubkeyNames(HKEY_LOCAL_MACHINE, 'Software\Classes\Installer\Dependencies', Keys) then
  begin
    for Index := 0 to GetArrayLength(Keys)-1 do
    begin
      Key := Keys[Index]
      
      if RegQueryStringValue(HKEY_LOCAL_MACHINE, 'Software\Classes\Installer\Dependencies\'+Key, 'DisplayName', DisplayName) then
      begin
        if (Pos('Microsoft Visual C++', DisplayName) = 1) and (Pos('(x86)', DisplayName) > 1) and ((Pos(' 2015 ', DisplayName) > 1) or (Pos(' 2017 ', DisplayName) > 1)) then
        begin
          Result := False
          Exit
        end;
      end;
    end;
  end;
  
  Result := True
end;

{ Run the Visual C++ installer if downloaded. }
procedure TDInstallVCRedist;
var InstallFile: String;
var ResultCode: Integer;

begin
  InstallFile := ExpandConstant('{tmp}\{#MyAppName}.VC.exe')
  
  if FileExists(InstallFile) then
  begin
    WizardForm.ProgressGauge.Style := npbstMarquee
    
    try
      if Exec(InstallFile, '/passive /norestart', '', SW_SHOW, ewWaitUntilTerminated, ResultCode) then
      begin
        if ResultCode <> 0 then
        begin
          DeleteFile(InstallFile)
          Exit
        end;
      end else
      begin
        MsgBox('Could not run the Visual C++ installer, please visit https://github.com/{#MyAppPublisher}/{#MyAppName}/{#VCRedistLink} and download the latest version manually. Error: '+SysErrorMessage(ResultCode), mbCriticalError, MB_OK);
        
        DeleteFile(InstallFile)
        Exit
      end;
    finally
      WizardForm.ProgressGauge.Style := npbstNormal
      DeleteFile(InstallFile)
    end;
  end;
end;
