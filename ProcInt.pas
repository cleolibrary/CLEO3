unit ProcInt;

interface uses Windows, SysUtils;

type

  TProcOrigData = packed record
    Val1: Byte;
    Val2: LongWord;
    Address: LongWord;
  end;

  PDrawer = ^TDrawer;
  TDrawer = packed record
    rgba: dword;
    lw, lh: single;
  end;


var
  TextureDraw: procedure(p1: Pointer; p2: Pointer); stdcall;

  TextDraw: procedure(X, Y: Single; text: PChar); cdecl;
  ScaleX: function(X: Single): Single; stdcall;
  ScaleY: function(Y: Single): Single; stdcall;
  SetFont: procedure(Font: Byte); cdecl;
  SetDrawAlign: procedure(Align: Byte); cdecl;

  ScrCount: Integer = 0;

  tp_newgame, tp_loadsave, tp_save: TProcOrigData;
  drawer: PDrawer;


const
  Text1 = 'CLEO 3: v%s';
  Text2 = Text1 + ' (%d scripts loaded)';

procedure HookNewGame(const Address: LongWord); stdcall;
procedure NewGameProc; stdcall;
procedure HookLoad(const Address: LongWord); stdcall;
procedure LoadSaveProc; stdcall;
procedure HookSave(const Address: LongWord); stdcall;
procedure SaveProc; stdcall;
procedure HookMenuDraw(const Address: LongWord); stdcall;
procedure DrawMenuProc(p1: Pointer; p2: Pointer); stdcall;

implementation uses uCLEO3;


procedure DrawMenuProc(p1: Pointer; p2: Pointer); stdcall;
var
  _ec: Integer;
begin
 asm
    mov _ec, ecx
  end;
  drawer^.lw := ScaleX(0.27);
  drawer^.lh := ScaleY(0.50);
  drawer^.rgba := $FF00FFFF;
  SetDrawAlign(1);
  SetFont(1);
  if ScrCount > 0 then
    TextDraw(ScaleX(10.0), ScaleY(435.0), PChar(Format(Text2, [CLEO_Version, ScrCount])))
  else
    TextDraw(ScaleX(10.0), ScaleY(435.0), PChar(Format(Text1, [CLEO_Version])));

  asm
    mov ecx, _ec
  end;

  TextureDraw(p1, p2);
end;


procedure HookMenuDraw(const Address: LongWord);
var
  d, dw: Cardinal;
begin
  VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);

  @TextureDraw := Ptr(PLongWord(Address + 1)^ + Address + 5);

  PLongWord(Address + 1)^ := LongWord(@DrawMenuProc) - Address - 5;
  VirtualProtect(Ptr(Address), 5, d, @dw);
end;

procedure NewGameProc; stdcall;
var
  d, dw: Cardinal;
begin
  CLEO3Init;
  with tp_newgame do
  begin
    VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
    PByte(Address)^ := Val1;
    PLongWord(Address + 1)^ := Val2;
    asm
      call tp_newgame.address
    end;
    HookNewGame(Address);
    VirtualProtect(Ptr(Address), 5, d, @dw);
  end;
  asm
    pop ecx
    pop edx
    pop ebx
    add esp, 4
    ret
  end;
end;

procedure HookNewGame(const Address: LongWord);
var
  d, dw: Cardinal;
begin
  VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
  tp_newgame.Val1 := PByte(Address)^;
  tp_newgame.Val2 := PLongWord(Address + 1)^;
  tp_newgame.Address := Address;

  PByte(Address)^ := $E8;
  PLongWord(Address + 1)^ := LongWord(@NewGameProc) - Address - 5;
  VirtualProtect(Ptr(Address), 5, d, @dw);
end;


procedure LoadSaveProc; stdcall;
var
  d, dw: Cardinal;
begin
  LoadCustomThreads;
  with tp_loadsave do
  begin
    VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
    PByte(Address)^ := Val1;
    PLongWord(Address + 1)^ := Val2;
    asm
      call tp_loadsave.address
    end;
    HookLoad(Address);
    VirtualProtect(Ptr(Address), 5, d, @dw);
  end;
  asm
    pop ecx
    pop edx
    pop ebx
    add esp, 4
    ret
  end;
end;

procedure HookLoad(const Address: LongWord);
var
  d, dw: Cardinal;
begin
  VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
  tp_loadsave.Val1 := PByte(Address)^;
  tp_loadsave.Val2 := PLongWord(Address + 1)^;
  tp_loadsave.Address := Address;
  PByte(Address)^ := $E8;
  PLongWord(Address + 1)^ := LongWord(@LoadSaveProc) - Address - 5;
  VirtualProtect(Ptr(Address), 5, d, @dw);
end;

procedure SaveProc; stdcall;
var
  d, dw: Cardinal;
begin
  SaveCustomThreads;
  with tp_save do
  begin
    VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
    PByte(Address)^ := Val1;
    PLongWord(Address + 1)^ := Val2;
    asm
      call tp_save.address
    end;
    HookSave(Address);
    VirtualProtect(Ptr(Address), 5, d, @dw);
  end;
  asm
    pop ecx
    pop edx
    pop ebx
    add esp, 4
    ret
  end;
end;

procedure HookSave(const Address: LongWord);
var
  d, dw: Cardinal;
begin
  VirtualProtect(Ptr(Address), 5, PAGE_READWRITE, @d);
  tp_save.Val1 := PByte(Address)^;
  tp_save.Val2 := PLongWord(Address + 1)^;
  tp_save.Address := Address;
  PByte(Address)^ := $E8;
  PLongWord(Address + 1)^ := LongWord(@SaveProc) - Address - 5;
  VirtualProtect(Ptr(Address), 5, d, @dw);
end;


end.

