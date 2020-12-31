unit uCLEO31;

interface uses Windows, uCLEO3;

function ExecuteScript(s: PChar): Boolean; stdcall;

var
  ABCHandle: THandle;
  ScriptExec: function(s: PChar): Boolean; stdcall;

implementation

{
 ABC script
}

function ExecuteScript(s: PChar): Boolean; stdcall;
begin
  Result := (addr(ScriptExec) <> nil) and ScriptExec(s);
end;

initialization
  ABCHandle := loadLibrary(CLEO_Path + 'ABC.cleo');
  if ABCHandle <> 0 then
    @ScriptExec := getProcAddress(ABCHandle, 'ExecuteScript');

finalization
  freeLibrary(ABCHandle);

end.

