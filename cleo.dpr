library cleo;

uses
  Classes,
  Sysutils,
  Windows,
  uSTRROUTES,
  globalScope,
  ProcInt,
  uCLEO2,
  uCLEO3;
//  uCLEO31;
//  ProcInt


{$E .asi}
{$R *.RES}

procedure Cleo3DLLProc(Reason: Integer);
begin
  if Reason = DLL_PROCESS_DETACH then
  begin
    CLEO3Destroy;
  end;
end;

begin
  DllProc := Cleo3DLLProc;
  if Sysutils.FindFirst(CLEO_Path + '*.cleo', faAnyFile, fs) = 0 then
    repeat
      if not Q_SameText(fs.name, 'abc') then
        Windows.LoadLibrary(PChar(CLEO_Path + fs.name));
    until FindNext(fs) <> 0;

  // displays CLEO version in the main menu
  if isVersionOriginal then
    HookMenuDraw($0057B9FD)
  else
    HookMenuDraw($0057BF71);

  Sysutils.FindClose(fs);
end.

