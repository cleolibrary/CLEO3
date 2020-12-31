unit SanApi;

interface uses Windows;

function KeyPressed(const Key: Smallint): Boolean; stdcall;
var ShowTextBox: procedure(Text: PChar; Flag1, Infinite, Flag3: Byte); cdecl;
procedure RemoveTextBox;


implementation

procedure RemoveTextBox;
begin
  ShowTextBox(Nil, 1, 0, 0);
end;

function KeyPressed(const Key: Smallint): Boolean; stdcall;
begin
  Result := Hi(GetKeyState(Key))=$FF;
end;


begin

  if PLongInt(Ptr($008A6168))^ = $465E60 then
  begin
    @ShowTextBox := Ptr($00588BE0);

  end else begin
    @ShowTextBox := Ptr($005893B0);

  end;
end.
