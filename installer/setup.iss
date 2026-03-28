; ══════════════════════════════════════════════
; SmartLauncher — Inno Setup Installer Script
; ══════════════════════════════════════════════

#define MyAppName "SmartLauncher"
#define MyAppVersion "1.0.3"
#define MyAppPublisher "SmartLauncher"
#define MyAppURL "https://github.com/banngaus/smart-launcher"
#define MyAppExeName "smart_launcher.exe"

; ═══ Пути к файлам на твоем компьютере ═══
; Путь к скомпилированному Flutter приложению
#define BuildDir "C:\Games\QoLWin\smart_launcher\build\windows\x64\runner\Release"
; Путь к папке со встроенным Python и библиотеками
#define PythonDir "C:\Games\QoLWin\smart_launcher\windows\python"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; Убери точку с запятой в начале следующей строки, если у тебя есть иконка
; SetupIconFile=assets\icon\app_icon.ico

OutputDir=installer_output
OutputBaseFilename=SmartLauncher_Setup_{#MyAppVersion}

Compression=lzma2/max
SolidCompression=no

WizardStyle=modern
WizardSizePercent=120

MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

AllowNoIcons=yes
DisableProgramGroupPage=yes

; Версия для свойств файла установщика
VersionInfoVersion=1.0.0.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}

UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

; Автоматическое закрытие при обновлении
CloseApplications=force
CloseApplicationsFilter=*.exe

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные задачи:"; Flags: checkedonce
Name: "startmenuicon"; Description: "Создать ярлык в меню Пуск"; GroupDescription: "Дополнительные задачи:"; Flags: checkedonce

[Files]
; 1. Главный exe файл Flutter
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; 2. Системные DLL (например, flutter_windows.dll)
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; 3. Flutter Assets (Именно здесь лежат .dat файлы, они скопируются автоматически)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; 4. Встроенный PYTHON вместе со всеми нужными библиотеками
Source: "{#PythonDir}\*"; DestDir: "{app}\python"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenuicon
Name: "{autoprograms}\Удалить {#MyAppName}"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Запустить {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{userappdata}\SmartLauncher"

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;

  // Проверка, не запущено ли приложение прямо сейчас (чтобы не было ошибок перезаписи)
  if CheckForMutexes('{#MyAppName}_Mutex') then
  begin
    if MsgBox('{#MyAppName} сейчас запущен.' + #13#10 + #13#10 +
              'Закройте приложение и нажмите "Повтор", или нажмите "Отмена" для выхода.',
              mbError, MB_RETRYCANCEL) = IDRETRY then
    begin
      Result := InitializeSetup();
    end
    else
    begin
      Result := False;
    end;
  end;
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    Log('Installation completed successfully');
  end;
end;