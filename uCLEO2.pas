unit uCLEO2;


interface uses
  SysUtils, Windows, Messages, SanApi, cmxMP3, uCLEO3, uCLEO31, uSTRROUTES, GlobalScope;

procedure CLEO2; stdcall;

implementation uses ProcInt, Classes;

function GetFreeTls: Byte;
var
  I: integer;
begin
  Result := 0;
  for i := 1 to TotalThreadNumber do
    if not Threads_TLS[i].used then
    begin
      Result := i;
      Threads_TLS[i].used := True;
      Exit;
    end;
end;

function SAWndHook(nCode: Integer; wParam: word; lParam: LongWord): longword; stdcall;
var
  I: Integer;
begin
  Result := CallNextHookEx(aWndHook, nCode, wParam, lParam);

  case TCWPRETSTRUCT(Pointer(LParam)^).Message of
    WM_ACTIVATE:
      begin

        if (LoWord(TCWPRETSTRUCT(Pointer(LParam)^).wParam) = WA_INACTIVE) then
        begin
          if Assigned(Mp3List) then
            for I := 0 to Mp3List.Count - 1 do
              if Assigned(Mp3List[i]) and (TcmxMP3(Mp3List[i]).State = mpPlaying) then
              begin
                TcmxMP3(Mp3List[i]).Pause;
                TcmxMP3(Mp3List[i]).autoPause := True;
              end;
        end;
{
        if (LoWord(TCWPRETSTRUCT(Pointer(LParam)^).wParam) = WA_ACTIVE) then
        begin
          if Assigned(Mp3List) then
            for I := 0 to Mp3List.Count - 1 do
              if Assigned(Mp3List[i]) and (TcmxMP3(Mp3List[i]).State = mpPaused) and TcmxMP3(Mp3List[i]).autoPause then
              begin
                TcmxMP3(Mp3List[i]).Resume;
                TcmxMP3(Mp3List[i]).autoPause := False;
              end;
        end;
}
      end;
  end;
end;

function SaKeyHookProc(nCode: Integer; wParam: word; lParam: LongWord): longword; stdcall;
var
  I: Integer;
begin
  Result := CallNextHookEx(aKeyHook, nCode, wParam, lParam);

  if (wParam = VK_ESCAPE) and Assigned(Mp3List) then
  begin
    if PBoolean(__IsMenuShown)^ then
    begin
      for I := 0 to Mp3List.Count - 1 do
        if Assigned(Mp3List[i]) and (TcmxMP3(Mp3List[i]).State = mpPlaying) then
        begin
          TcmxMP3(Mp3List[i]).Pause;
          TcmxMP3(Mp3List[i]).autoPause := True;
        end
    end else begin
      for I := 0 to Mp3List.Count - 1 do
        if Assigned(Mp3List[i]) and (TcmxMP3(Mp3List[i]).State = mpPaused) and TcmxMP3(Mp3List[i]).autoPause then
        begin
          TcmxMP3(Mp3List[i]).Resume;
          TcmxMP3(Mp3List[i]).autoPause := False;
        end;
    end;
  end;
end;

function LoadMp3(const APath: PChar): TcmxMp3; stdcall;
begin
  if not Assigned(Mp3List) then
  begin
    Mp3List := TList.Create;
    // Creating the hooks
    aKeyHook := SetWindowsHookEx(WH_KEYBOARD, @SaKeyHookProc, 0, GetCurrentThreadID);
    aWndHook := SetWindowsHookEx(WH_CALLWNDPROCRET, @SAWndHook, 0, GetCurrentThreadID);
  end;
  Result := TcmxMP3.Create(APath);
  Mp3List.Add(Result);
end;

procedure PerformMp3Action(const AMp3: TcmxMP3; const AFlag: Byte); stdcall;
begin
  if Assigned(AMp3) then
    case AFlag of
      0: AMp3.Stop;
      1: AMp3.Play;
      2: AMp3.Pause;
      3: AMp3.Resume;
    end;
end;

procedure ReleaseMp3(const AMp3: TcmxMP3); stdcall;
begin
  if Assigned(AMp3) then
  begin
    AMp3.Destroy;
    Mp3List.Remove(AMp3);
  end;
end;

function GetMp3Length(const AMp3: TcmxMP3): Integer; stdcall;
begin
  if Assigned(AMp3) then
    Result := AMp3.LengthInSeconds
  else
    Result := -1;
end;

function GetMp3State(const AMp3: TcmxMP3): Integer; stdcall;
var
  mp3state: TMPMode;
begin
  if Assigned(AMp3) then
  begin
    mp3state := AMp3.State;
    case mp3state of
      mpStopped: Result := 0;
      mpPlaying: Result := 1;
      mpPaused: Result := 2;
    else
      Result := -1;
    end;
  end else Result := -1;
end;


procedure CLEO2; stdcall;
asm
   MOV  eax, [esp+4]
   SUB  ax, $0A8C
   JMP  dword ptr @@CLEO_Opcodes[eax*4]


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CLEO Pointers Table
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO_Opcodes:
  DD @@CLEO2_Opcode0A8C  DD @@CLEO2_Opcode0A8D  DD @@CLEO2_Opcode0A8E  DD @@CLEO2_Opcode0A8F // 4
  DD @@CLEO2_Opcode0A90  DD @@CLEO2_Opcode0A91  DD @@CLEO2_Opcode0A92  DD @@CLEO2_Opcode0A93 // 8
  DD @@CLEO2_Opcode0A94  DD @@CLEO2_Opcode0A95  DD @@CLEO2_Opcode0A96  DD @@CLEO2_Opcode0A97 // 12
  DD @@CLEO2_Opcode0A98  DD @@CLEO2_Opcode0A99  DD @@CLEO2_Opcode0A9A  DD @@CLEO2_Opcode0A9B // 16
  DD @@CLEO2_Opcode0A9C  DD @@CLEO2_Opcode0A9D  DD @@CLEO2_Opcode0A9E  DD @@CLEO2_Opcode0A9F // 20
  DD @@CLEO2_Opcode0AA0  DD @@CLEO2_Opcode0AA1  DD @@CLEO2_Opcode0AA2  DD @@CLEO2_Opcode0AA3 // 24
  DD @@CLEO2_Opcode0AA4  DD @@CLEO2_Opcode0AA5  DD @@CLEO2_Opcode0AA6  DD @@CLEO2_Opcode0AA7 // 28
  DD @@CLEO2_Opcode0AA8  DD @@CLEO2_Opcode0AA9  DD @@CLEO2_Opcode0AAA  DD @@CLEO2_Opcode0AAB // 32
  DD @@CLEO2_Opcode0AAC  DD @@CLEO2_Opcode0AAD  DD @@CLEO2_Opcode0AAE  DD @@CLEO2_Opcode0AAF // 36
  DD @@CLEO2_Opcode0AB0  DD @@CLEO2_Opcode0AB1  DD @@CLEO2_Opcode0AB2  DD @@CLEO2_Opcode0AB3 // 40
  DD @@CLEO2_Opcode0AB4  DD @@CLEO2_Opcode0AB5  DD @@CLEO2_Opcode0AB6  DD @@CLEO2_Opcode0AB7 // 44
  DD @@CLEO2_Opcode0AB8  DD @@CLEO2_Opcode0AB9  DD @@CLEO2_Opcode0ABA  DD @@CLEO2_Opcode0ABB // 48    // ABB,ABC - reserved
  DD @@CLEO2_Opcode0ABD  DD @@CLEO2_Opcode0ABE  DD @@CLEO2_Opcode0ABF  DD @@CLEO2_Opcode0AC0 // 52

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A8C
 0A8C: write_memory <dword> size <byte> value <dword> virtual_protect <bool>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A8C:

    PUSH   ebx
    PUSH   4
    CALL   [__CollectNumberParams]
    MOV    ebx, dword ptr ParamsPtr[3*4]
    CMP    byte ptr [ebx], 1
    JNZ    @0A8CMOV
    PUSH   4
    CALL   @@VirtualProtect
    POP    eax

    @0A8CMOV:
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    ecx, dword ptr [ParamsPtr[1*4]]
    MOV    eax, dword ptr [ParamsPtr[2*4]]
    MOV    edx, [edx] // address
    MOV    ecx, [ecx] // size
    MOV    eax, [eax] // value
    CMP    ecx, 1
    JNZ    @0A8CW
    MOV    byte ptr [edx], al
    JMP    @0A8CVP

    @0A8CW:
    CMP    ecx, 2
    JNZ    @0A8CDW
    MOV    word ptr [edx], ax
    JMP    @0A8CVP

    @0A8CDW:
    MOV    dword ptr [edx], eax

    @0A8CVP:
    CMP    dword ptr [ebx], 1
    JNZ    @ret
    PUSH   dwiOldProtect
    CALL   @@VirtualProtect
    POP    eax

    @RET:
    POP    ebx
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 CLEO 2 Virtual Protect Subroutine
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@VirtualProtect:
    PUSH   offset dwiOldProtect
    PUSH   [esp+8]
    MOV    eax, dword ptr [ParamsPtr[1*4]]
    PUSH   [eax]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   VirtualProtect
    RET

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A8D
 0A8D: <var> = read_memory <dword> size <byte> virtual_protect <bool>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A8D:

    PUSH   ebx
    PUSH   3
    CALL   [__CollectNumberParams]
    MOV    ebx, dword ptr [ParamsPtr[2*4]]
    CMP    [ebx], 1
    JNZ    @0A8D_GET_PARAMS
    PUSH   4
    CALL   @@VirtualProtect
    POP    eax

    @0A8D_GET_PARAMS:
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    MOV    eax, [eax]
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], 0
    MOV    ecx, dword ptr [ParamsPtr[1*4]]
    CMP    [ecx], 1
    JNZ    @0A8D_WORD
    MOV    al, [eax]
    MOV    [edx], al
    JMP    @0A8D_VIRTUAL_PROTECT

    @0A8D_WORD:
    CMP    [ecx], 2
    JNZ    @0A8D_DWORD
    MOV    ax, [eax]
    MOV    [edx], ax
    JMP    @0A8D_VIRTUAL_PROTECT

    @0A8D_DWORD:
    MOV    eax, [eax]
    MOV    [edx], eax

    @0A8D_VIRTUAL_PROTECT:
    CMP    [ebx], 1
    JNZ    @0A8D_WRITE_RESULT
    PUSH   dwiOldProtect
    CALL   @@VirtualProtect
    POP    eax

    @0A8D_WRITE_RESULT:
    PUSH   1
    MOV    ecx, esi
    CALL   [__WriteResult]
    POP    ebx
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A8E
  0A8E: (1) = (2) + (3) // int
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A8E:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A8F
  0A8F: (1) = (2) - (3) // int
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A8F:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A90
  0A90: (1) = (2) * (3) // int
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A90:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A91
  0A91: (1) = (2) / (3) // int
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A91:

    PUSH   eax
    PUSH   2
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    MOV    eax, [eax]
    MOV    edx, dword ptr [ParamsPtr[1*4]]
    MOV    edx, [edx]
    POP    ecx
    SUB    ecx, 2
    JMP    dword ptr @OPCODES_0A8E_0A8E_TABLE[ecx*4]

    // ADD EAX, EDX
    @opcode0A8E:
    ADD    eax, edx
    JMP    @0A8E_WRITE_RESULT

    // SUB EAX, EDX
    @opcode0A8F:
    SUB    eax, edx
    JMP    @0A8E_WRITE_RESULT

    // MUL EAX, EDX
    @opcode0A90:
    IMUL   edx
    JMP    @0A8E_WRITE_RESULT

    // DIV EAX, P2
    @opcode0A91:
    CDQ
    MOV    ecx, dword ptr [ParamsPtr[1*4]]
    IDIV   [ecx]

    @0A8E_WRITE_RESULT:
    MOV    ecx, dword ptr [ParamsPtr[0*4]]
    MOV    [ecx], eax
    PUSH   1
    MOV    ecx, esi
    CALL   [__WriteResult]
    XOR    al, al
    RET    4

@OPCODES_0A8E_0A8E_TABLE:
    DD @opcode0A8E, @opcode0A8F, @opcode0A90, @opcode0A91

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A92
  0A92: create_custom_thread %1s%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A92:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]
    LEA    eax, [esp+0]
    PUSH   eax
    CALL   CreateCustomThread
    TEST   eax, eax
    JZ     @0A92_Dbg
    LEA    EAX, TCustomThread(eax).fThread

    @0A92_GetP:
    PUSH   EAX
    MOV    ecx, esi
    CALL   __GetThreadParams
    ADD    esp, 128
    XOR    al, al
    RET    4

    @0A92_Dbg:
    LEA    EAX, Temp_TLS
    JMP    @0A92_GetP

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A93
  0A93: end_custom_thread
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A93:
    PUSH   ECX
    CALL   EndCustomThread
    MOV    al, 1
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A94
  0A94: start_custom_mission %1s%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A94:
    PUSH   ESI
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]
    LEA    eax, [esp+0]
    PUSH   eax
    CALL   StartCustomMission
    ADD    esp, 128
    POP    ESI
    MOV    ECX, ESI
    PUSH   __MissionLocalsPoolOffs
    MOV    ecx, esi
    CALL   __GetThreadParams
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A95
  0A95: enable_thread_saving
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A95:
    mov    byte ptr TSAThread(esi).SaveThreadFlag, 1
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A96
  0A96: (1) = actor (2) struct
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A96:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A97
  0A97: (1) = car (2) struct
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A97:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A98
  0A98: (1) = object (2) struct
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A98:
    PUSH   eax
    PUSH   1
    CALL   [__CollectNumberParams]
    POP    ecx
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]

    SUB    ecx, 10
    JMP    dword ptr @OPCODES_0A96_0A98_TABLE[ecx*4]

@OPCODES_0A96_0A98_TABLE:
DD @opcode0A96, @opcode0A97, @opcode0A98

    // 0A96:   ACTOR.STRUCT
@opcode0A96:
    MOV    ecx, [CActors]
    MOV    ecx, [ecx]
    CALL   [__GetActorPointer]
    JMP    @0A98_WRITE_RESULT
    // 0A97:   CAR.STRUCT
@opcode0A97:
    MOV    ecx, [CVehicles]
    MOV    ecx, [ecx]
    CALL   [__GetCarPointer]
    JMP    @0A98_WRITE_RESULT
    // 0A98:   OBJECT.STRUCT
@opcode0A98:
    MOV    ecx, [CObjects]
    MOV    ecx, [ecx]
    CALL   [__GetObjectPointer]
@0A98_WRITE_RESULT:
    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A99
  0A99: chdir <flag>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A99:
    PUSH   1
    CALL   [__CollectNumberParams]
    // TEST flag
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    MOV    eax, [eax]
    TEST   eax, eax
    JZ     @opcode0A99_Root
    CMP    eax, 1
    JNZ    @opcode0A99_Exit
    // FLAG=1; UserDir
    CALL   [__SetUserDirToCurrent]
    JMP    @opcode0A99_Exit
    // FLAG=0; RootDir
@opcode0A99_Root:
    PUSH   __Null
    CALL   [__ChDir]
    ADD    esp, 4
@opcode0A99_Exit:
    XOR    al, al
    RET    4



{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9A
  0A9A: <var> = openfile "path" mode <dword>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9A:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax

    CALL   [__GetStringParam]
    PUSH   1
    MOV    ecx, esi
    CALL   [__CollectNumberParams]

    PUSH   dword ptr [ParamsPtr[0*4]]
    LEA    eax, [esp+4]
    PUSH   eax

    CALL   [__fopen]

    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    XOR    edx, edx
    TEST   eax, eax
    SETNZ  dl
    PUSH   edx
    CALL   [__SetConditionResult]
    CALL   [__WriteResult]


    ADD    esp, 136
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9B
  0A9B: closefile <hFile>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9B:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   [__fclose]
    POP    eax
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9C
  0A9C: <var> = file <hFile> size
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9C:
    PUSH   1
    CALL   [__CollectNumberParams]
    PUSH   0
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   GetFileSize
    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9D
  0A9D: readfile <hFile> size <dword> to <var>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9D:
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9E
  0A9E: writefile <hFile> size <dword> from <var>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9E:
    PUSH   eax
    PUSH   2
    CALL   [__CollectNumberParams]
    PUSH   2
    CALL   [__GetVariablePos]
    POP    ecx
    MOV    edx, dword ptr [ParamsPtr[1*4]]
    PUSH   [edx]
    PUSH   eax
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx]
    CMP    ecx, 17
    JNZ    @opcode0A9E
    CALL   [__BlockRead]
    JMP    @opcode0A9E_Exit

@opcode0A9E:
    CALL   [__BlockWrite]

@opcode0A9E_Exit:
    ADD    esp, 12
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0A9F
  0A9F: <var> = current_thread_address
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0A9F:
    PUSH   1
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], esi
    CALL   [__WriteResult]
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA0
  0AA0: gosub_if_false <label>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA0:

    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    al, [esi+$C5]
    TEST   al, al
    JNZ    @Opcode0AA0_True

    MOVZX  eax, [esi+$38]
    MOV    edx, [esi+$14]
    MOV    [esi+eax*4+$18], edx
    INC    word ptr [esi+$38]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   [__SetJumpLocation]

@Opcode0AA0_True:
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA1
  0AA1: return_if_false
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA1:

    MOV    al, [esi+$C5]
    TEST   al, al
    JNZ    @Opcode0AA1_True

    DEC    word ptr [esi+$38]
    MOVZX  eax, [esi+$38]
    MOV    edx, [esi+eax*4+$18]
    MOV    [esi+$14], edx

@Opcode0AA1_True:
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA2
  0AA2: <var> = load_library <path>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA2:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]
    LEA    eax, [esp+0]
    PUSH   eax
    CALL   LoadLibrary

    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    XOR    edx, edx
    TEST   eax, eax
    SETNZ  dl
    PUSH   edx
    CALL   [__SetConditionResult]
    CALL   [__WriteResult]
    ADD    esp, 128
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA3
  0AA3: free_library <hLib>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA3:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   FreeLibrary
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA4
  0AA4: <var> = get_proc_address "name" library <hLib>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA4:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]
    PUSH   1
    MOV    ecx, esi
    CALL   [__CollectNumberParams]

    LEA    eax, [esp+0]
    PUSH   eax
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]
    CALL   GetProcAddress

    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax

    XOR    edx, edx
    TEST   eax, eax
    SETNZ  dl
    PUSH   edx
    CALL   [__SetConditionResult]
    CALL   [__WriteResult]
    ADD    esp, 128
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA5
  0AA5: call <address> num_params <byte> pop <byte> [param1, param2...]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA5:
    PUSH    3
    CALL    [__CollectNumberParams]
    PUSH    ebx
    PUSH    edi
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    MOV     ebx, [eax]
    MOV     eax, dword ptr [ParamsPtr[1*4]]
    MOV     edi, [eax]

    @Opcode0AA5Loop:
    TEST    edi, edi
    JZ      @Opcode0AA5Call
    PUSH    1
    CALL    [__CollectNumberParams]
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    PUSH    [eax]
    DEC     edi
    JMP     @Opcode0AA5Loop

    @Opcode0AA5Call:
    CALL    EBX

    MOV     eax, dword ptr [ParamsPtr[2*4]]
    MOV     eax, [eax]
    IMUL    eax, 4
    ADD     esp, EAX

    POP     edi
    POP     ebx
    INC     dword ptr [esi+$14]
    XOR     al, al
    RET     4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA6
  0AA6: call_method <address> struct <address> num_params <byte> pop <byte> [param1, param2...]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA6:
    PUSH    4
    CALL    [__CollectNumberParams]
    PUSH    ebx
    PUSH    edi
    PUSH    ecx
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    MOV     ebx, [eax]
    MOV     eax, dword ptr [ParamsPtr[2*4]]
    MOV     edi, [eax]

    @Opcode0AA6Loop:
    TEST    edi, edi
    JZ      @Opcode0AA6Call
    PUSH    1
    CALL    [__CollectNumberParams]
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    PUSH    [eax]
    DEC     edi
    JMP     @Opcode0AA6Loop

    @Opcode0AA6Call:
    MOV     ecx, dword ptr [ParamsPtr[1*4]]
    MOV     ecx, [ecx]
    CALL    EBX

    MOV     eax, dword ptr [ParamsPtr[3*4]]
    MOV     eax, [eax]
    IMUL    eax, 4
    ADD     esp, EAX
    POP     ecx
    POP     edi
    POP     ebx
    INC     dword ptr [esi+$14]
    XOR     al, al
    RET     4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA7
  0AA7: call_function <address> num_params <byte> pop <byte> [param1, param2...] result <var>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA7:
    PUSH    3
    CALL    [__CollectNumberParams]
    PUSH    ebx
    PUSH    edi
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    MOV     ebx, [eax]
    MOV     eax, dword ptr [ParamsPtr[1*4]]
    MOV     edi, [eax]

    @Opcode0AA7Loop:
    TEST    edi, edi
    JZ      @Opcode0AA7Call
    PUSH    1
    CALL    [__CollectNumberParams]
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    PUSH    [eax]
    DEC     edi
    JMP     @Opcode0AA7Loop

    @Opcode0AA7Call:
    CALL    EBX
    PUSH    1
    MOV     ecx, esi
    MOV     edx, dword ptr [ParamsPtr[0*4]]
    MOV     [edx], eax
    CALL    [__WriteResult]

    MOV     eax, dword ptr [ParamsPtr[2*4]]
    MOV     eax, [eax]
    IMUL    eax, 4
    ADD     esp, EAX

    POP     edi
    POP     ebx
    INC     dword ptr [esi+$14]
    XOR     al, al
    RET     4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA8
  0AA8: call_function_method <address> num_params <byte> pop <byte> [param1, param2...] result <var>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA8:
    PUSH    4
    CALL    [__CollectNumberParams]
    PUSH    ebx
    PUSH    edi
    PUSH    ecx
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    MOV     ebx, [eax]
    MOV     eax, dword ptr [ParamsPtr[2*4]]
    MOV     edi, [eax]

    @Opcode0AA8Loop:
    TEST    edi, edi
    JZ      @Opcode0AA8Call
    PUSH    1
    CALL    [__CollectNumberParams]
    MOV     eax, dword ptr [ParamsPtr[0*4]]
    PUSH    [eax]
    DEC     edi
    JMP     @Opcode0AA8Loop

    @Opcode0AA8Call:
    MOV     ecx, dword ptr [ParamsPtr[1*4]]
    MOV     ecx, [ecx]
    CALL    EBX
    PUSH    1
    MOV     ecx, esi
    MOV     edx, dword ptr [ParamsPtr[0*4]]
    MOV     [edx], eax
    CALL    [__WriteResult]

    MOV     eax, dword ptr [ParamsPtr[3*4]]
    MOV     eax, [eax]
    IMUL    eax, 4
    ADD     esp, EAX
    POP     ecx
    POP     edi
    POP     ebx
    INC     dword ptr [esi+$14]
    XOR     al, al
    RET     4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AA9
  0AA9:   is_game_version_original
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AA9:

    XOR    edx, edx
    mov    al, isVersionOriginal
    TEST   al, al
    SETNZ  dl
    PUSH   edx
    CALL   [__SetConditionResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAA
  0AAA: 1@ = thread 'OTB' pointer
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAA:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    CALL   FindThreadByName
//    TEST   al, al
//    JNZ    @Opcode0AAA_Write
//    or     eax, -1
//    @Opcode0AAA_Write:
    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    ADD    esp, 128
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAB
  0AAB:  file_exists "path"
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAB:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    CALL   FileExists

    MOV    ecx, esi
    XOR    edx, edx
    TEST   al, al
    SETNZ  dl
    PUSH   edx
    CALL   [__SetConditionResult]
    ADD    esp, 132
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAC
  0AAC:  %2d% = load_mp3 "path"
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAC:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    call   LoadMp3

    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    ADD    esp, 128
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAD
  0AAD: set_mp3 %1d% perform_action %2d%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAD:
    PUSH   2
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[1*4]]
    PUSH   [eax] // aFlag
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx] // aMP3
    CALL   PerformMp3Action
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAE
  0AAE: release_mp3 %1d%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAE:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx] // aMP3
    CALL   ReleaseMp3
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AAF
  0AAF: %2d% = get_mp3_length %1d%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AAF:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx] // aMP3
    CALL   GetMp3Length
    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB0
  0AB0:  key_pressed %1d%
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AB0:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx]
    CALL   KeyPressed
    MOV    ecx, esi
    PUSH   eax
    CALL   [__SetConditionResult]
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB1
   0AB1: call_scm_func <label> [..extra parameters]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AB1:
    // GET FUNC LABEL AND PARAMS COUNT
    PUSH   EBX
    PUSH   2
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]

    // SAVE TLS
    PUSH   ECX
    CALL   GetFreeTls  // EAX - TLS #
    MOV    EDX, EAX

    PUSH   TSAThread(esi).TLS_ID // save TLS #
    MOV    TSAThread(esi).TLS_ID, DX
    
    LEA    EAX, [ESI+$3C]          // source
    IMUL   EDX, 132
    LEA    EDX, Threads_TLS[EDX]   // dest

    POP    CX // restore TLS_ID #
    MOV    WORD PTR TLS(EDX).PREV, CX

    MOV    CL, TSAThread(esi).SaveThreadFlag
    MOV    BYTE PTR TLS(EDX).SaveFlag, CL // TLS.SaveFlag=Thread.SaveFlag

    MOV    ECX, 32*4               // count
    CALL   Q_MoveMem
    POP    ECX

    // get function params (const)
    MOV    ebx, dword ptr [ParamsPtr[1*4]]
    MOVZX  EBX, byte ptr [ebx] // BH(0):BL

    @Opcode0AB1_LOOP:
    TEST   BL, BL
    JZ     @Opcode0AB1_SKIPREAD    
    DEC    BL    

    // Number or String Loop
    MOV    EAX, TSAThread(esi).CurrentIP// [ESI+$14]
    MOV    AL,  byte ptr [EAX]
    CMP    AL,  08
    JA     @Opcode0AB1_STRING8

    // number p
    PUSH   1
    CALL   [__CollectNumberParams]

    MOVZX  EAX, BH
    LEA    EDX, [ESI+$3C+EAX*4]
    MOV    EAX, dword ptr [ParamsPtr[0*4]]
    MOV    EAX, [EAX]
    MOV    [EDX], EAX
    INC    BH
    JMP    @Opcode0AB1_LOOP

    // string p8
    @opcode0AB1_STRING8:
    CMP    AL, 13
    JA     @Opcode0AB1_STRING16
    PUSH   16
    MOVZX  EAX, BH
    LEA    EDX, [ESI+$3C+EAX*4]
    PUSH   EDX
    CALL   [__GetStringParam]
    ADD    BH, 2
    MOV    ECX, ESI             // GetStringParam changes ecx
    JMP    @Opcode0AB1_LOOP

    // string p16
    @opcode0AB1_STRING16:
    PUSH   16
    MOVZX  EAX, BH
    LEA    EDX, [ESI+$3C+EAX*4]
    PUSH   EDX
    CALL   [__GetStringParam]
    ADD    BH, 4
    MOV    ECX, ESI             // GetStringParam changes ecx
    JMP    @Opcode0AB1_LOOP

{
    @opcode0AB1_TLS:
    //  PARAMS -> TLS
    PUSH   ECX
    LEA    EAX, ParamsPtr
    MOV    EAX, [EAX]
    LEA    EDX, [ESI+$3C]
    LEA    ECX, EBX*4
    CALL   Q_MoveMem
    POP    ECX
}
    @Opcode0AB1_SKIPREAD:
    // CALL FUNC
    MOVZX  eax, [esi+$38]
    MOV    edx, TSAThread(esi).CurrentIP
    MOV    [esi+eax*4+$18], edx
    INC    word ptr [esi+$38]
    CALL   [__SetJumpLocation]

    POP    EBX
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB2
  0AB3: ret [ret_vals]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AB2:

    PUSH   EBX
    // get RET params
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    ebx, dword ptr [ParamsPtr[0*4]]
    MOV    ebx, [ebx]
    TEST   ebx, ebx
    JZ     @Opcode0AB2_SKIPCOLLECT
    PUSH   ebx
    CALL   [__CollectNumberParams]

    @Opcode0AB2_SKIPCOLLECT:
    // restore caller pos
    DEC    word ptr [esi+$38]
    MOVZX  eax, [esi+$38]
    MOV    edx, [esi+eax*4+$18]
    MOV    [esi+$14], edx

    // restore TLS
    PUSH   ECX
    MOVZX  EAX, WORD PTR TSAThread(esi).TLS_ID
    IMUL   EAX, 132
    LEA    EAX, Threads_TLS[EAX]   // source

    MOV    BYTE PTR TLS(EAX).USED, False
    MOV    CX, WORD PTR TLS(EAX).PREV
    MOV    WORD PTR TSAThread(esi).TLS_ID, CX    
            
    LEA    EDX, [ESI+$3C]          // dest
    MOV    ECX, 32*4               // count
    CALL   Q_MoveMem
    POP    ECX

    // PARAMS -> VARS
    TEST   ebx, ebx
    JZ     @Opcode0AB2_SKIPWRITE
    PUSH   ebx
    CALL   [__WriteResult]

    @Opcode0AB2_SKIPWRITE:

    INC    dword ptr [esi+$14] // skip 0
    POP    EBX
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB3
  0AB3: var [id] = value
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AB3:
    PUSH   2
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    MOV    eax, [eax]                       //varID
    MOV    edx, dword ptr [ParamsPtr[1*4]]
    MOV    edx, [edx]                       //value

    LEA    EAX, CLEO_Global_Storage[EAX*4]
    MOV    [EAX], EDX
    XOR    al, al
    RET    4


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB4
  0AB4: var [id] = value
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AB4:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    MOV    eax, [eax]                      // varID
    LEA    EAX, CLEO_Global_Storage[EAX*4]
    MOV    EAX, [EAX]                      //varValue
    PUSH   1
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB5
  0AB5: store_actor [actor] closest_vehicle_to [var] closest_ped_to [var]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0AB5:
    PUSH   EDI
    PUSH   EBX
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [eax]                            // actorHandle
    MOV    ecx, [CActors]
    MOV    ecx, [ecx]
    CALL   [__GetActorPointer]
    MOV    ebx, [eax+$47C]

    MOV    edi, dword ptr [ParamsPtr[0*4]]
    MOV    edx, [ebx+$E0]
    TEST   EDX, EDX
    JNZ    @Opcode0AB5_WriteVehicle
    MOV    [edi], -1
    JMP    @Opcode0AB5_GetPed

    @Opcode0AB5_WriteVehicle:
    PUSH   EDX
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetVehicleHandle]
    MOV    [edi], eax

    @Opcode0AB5_GetPed:
    MOV    edi, dword ptr [ParamsPtr[1*4]]
    MOV    edx, [ebx+$130]
    TEST   EDX, EDX
    JNZ    @Opcode0AB5_WritePed
    MOV    [edi], -1
    JMP    @Opcode0AB5_WriteResult

    @Opcode0AB5_WritePed:
    PUSH   EDX
    MOV    ECX, [CActors]
    MOV    ECX, [ECX]
    CALL   [__GetPedHandle]
    MOV    [edi], eax

    @Opcode0AB5_WriteResult:
    PUSH   2
    MOV    ecx, esi
    CALL   [__WriteResult]
    POP    EBX
    POP    EDI
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB6
  0AB6: store_target_marker_coords_to [var] [var] [var] // IF_AND_SET
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0AB6:
    PUSH   EBX
    MOV    EAX, __TargetMarkerHandle
    MOV    EAX, [EAX]

    TEST   EAX, EAX
    JZ     @Opcode0AB6_No_Marker

    MOV    ECX, EAX
    AND    ECX, $FFFF
    LEA    ECX, [ECX+ECX*4]
    SHL    ECX, 3
    SHR    EAX, 16
    MOV    EBX, CMarkers
    CMP    AX, WORD PTR [ebx+$14][ECX]
    JNZ    @Opcode0AB6_No_Marker
    TEST   BYTE PTR [ebx+$25][ECX], 2
    JZ     @Opcode0AB6_No_Marker

    MOV    EAX, dword ptr [ParamsPtr[1*4]]
    MOV    EDX, [ebx+ecx+$8+4]
    MOV    [EAX], EDX
    PUSH   EDX     // Y

    MOV    EAX, dword ptr [ParamsPtr[0*4]]
    MOV    EDX, [ebx+ecx+$8+0]
    MOV    [EAX], EDX
    PUSH   EDX    // X

    CALL   [__GetZForXY]
    ADD    ESP, 8
    FSTP   [ESP-4]
    MOV    EAX, [ESP-4]  //correct??
    MOV    EDX, dword ptr [ParamsPtr[2*4]]
    MOV    [EDX], EAX

    PUSH   3
    MOV    ECX, ESI
    CALL   [__WriteResult]
    PUSH   1
    JMP    @Opcode0AB6_SetResult

    @Opcode0AB6_No_Marker:
    PUSH   3
    MOV    ECX, ESI
    CALL   [__CollectNumberParams]
    PUSH   0

    @Opcode0AB6_SetResult:
    CALL   [__SetConditionResult]
    POP    EBX
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB7
  0AB7: get_vehicle [hCar] number_of_gears_to [var]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0AB7:
    PUSH   1
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]

    MOVZX  EAX, WORD PTR [EAX+$22]
    IMUL   EAX, 224
    ADD    EAX, __NumberOFGears
    MOVZX  EAX, BYTE PTR [EAX]

    MOV    EDX, dword ptr [ParamsPtr[0*4]]
    MOV    [EDX], EAX

    MOV    ECX, ESI
    PUSH   1
    CALL   [__WriteResult]

    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB8
  0AB8: get_vehicle [hCar] current_gear_to [var]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0AB8:
    PUSH   1
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]

    MOV    EDX, dword ptr [ParamsPtr[0*4]]
    MOV    EAX, [EAX+$4B4]
    MOV    [EDX], EAX

    MOV    ECX, ESI
    PUSH   1
    CALL   [__WriteResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AB9
  0AB9: get_mp3 [hMp3] state_to [var]
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0AB9:
    PUSH   1
    CALL   [__CollectNumberParams]
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    PUSH   [edx] // aMP3
    CALL   GetMp3State
    PUSH   1
    MOV    ecx, esi
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], eax
    CALL   [__WriteResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABA
  0ABA: end_custom_thread_named "thread"
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}

@@CLEO2_Opcode0ABA:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    CALL   FindThreadByName
    
    @CLEO2_Opcode0ABA_End:
    TEST   EAX, EAX
    JZ     @Opcode0ABA_EXIT

    PUSH   EAX
    CALL   EndCustomThread

    @Opcode0ABA_EXIT:
    ADD    esp, 128
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABB
  0ABA: end_custom_thread_from_file "file_name"
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0ABB:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    CALL   FindThreadByFileName

    JMP    @CLEO2_Opcode0ABA_End

(*
{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABC
  0ABC: call "script"
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0ABC:
    SUB    esp, 128
    PUSH   100
    LEA    eax, [esp+4]
    PUSH   eax
    CALL   [__GetStringParam]

    LEA    eax, [esp+0]
    PUSH   eax
    CALL   CallABCScript

    ADD    esp, 128
    XOR    al, al
    RET    4
*)


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABD
  0ABD:   vehicle [hCar] siren_on
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}    
@@CLEO2_Opcode0ABD:
    PUSH   1
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]

    XOR    EDX, EDX
    MOV    DL, [EAX+$42D] // car+42D, 7th bit - siren status
    BT     EDX, 7
    SETC   AL
    PUSH   EAX
    MOV    ECX, ESI    
    CALL   [__SetConditionResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABE
  0ABE:   vehicle [hCar] engine_on
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}    
@@CLEO2_Opcode0ABE:
    PUSH   1
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]

    XOR    EDX, EDX
    MOV    DL, [EAX+$428] // 4th bit - engine status
    BT     EDX, 4
    SETC   AL
    PUSH   EAX
    MOV    ECX, ESI    
    CALL   [__SetConditionResult]
    XOR    al, al
    RET    4

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0ABF
  0ABF: set_vehicle [hCar] engine_state_to
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}  
@@CLEO2_Opcode0ABF:
    PUSH   2
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]

    MOV    EDX, dword ptr [ParamsPtr[1*4]]
    MOV    DL, byte ptr [EDX]
    TEST   DL, DL                 // set or zero 4th bit
    JZ     @CLEO2_Opcode0ABF_zero
    OR    [eax+$428], $10
    JMP    @CLEO2_Opcode0ABF_EXIT

@CLEO2_Opcode0ABF_ZERO:
    AND    [eax+$428], $EF

@CLEO2_Opcode0ABF_EXIT:
    XOR    al, al
    RET    4    


{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AC0
  0AC0:   vehicle [hCar] light [light] on
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
{
@@CLEO2_Opcode0AC0:
    PUSH   2
    CALL   [__CollectNumberParams]

    MOV    eax, dword ptr [ParamsPtr[0*4]]
    PUSH   [EAX]
    MOV    ECX, [CVehicles]
    MOV    ECX, [ECX]
    CALL   [__GetCarPointer]
    
    MOV    EDX, [EAX+$584] // render lights

    MOV    EAX, dword ptr [ParamsPtr[1*4]]
    MOV    EAX, [EAX]
    DEC    EAX

    BT     EDX, EAX
    SETC   AL
    PUSH   EAX
    MOV    ECX, ESI    
    CALL   [__SetConditionResult]
    XOR    al, al
    RET    4
}

{
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Opcode 0AC0
  0AC0: store_CLEO_version_to <var>
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
}
@@CLEO2_Opcode0AC0:
    PUSH   1
    MOV    edx, dword ptr [ParamsPtr[0*4]]
    MOV    [edx], CLEO_Version_Num
    CALL   [__WriteResult]
    XOR    al, al
    RET    4


  end;

var
  C: Integer;

begin
  if PLongInt(Ptr($008A6168))^ = $465E60 then
  begin
    isVersionOriginal := True;
    __CollectNumberParams := $464080;
    __WriteResult := $464370;
    __GetObjectPointer := $465040;
    __SetUserDirToCurrent := $538860;
    __Null := $858B54;
    __ChDir := $5387D0;
    __GetStringParam := $463D50;
    __fopen := $538900;
    __SetConditionResult := $4859D0;
    __fclose := $5389D0;
    __GetVariablePos := $464790;
    __BlockRead := $538950;
    __BlockWrite := $538970;
    __SetJumpLocation := $464DA0;
    __GetThreadParams := $464500;

    CActors := $B74490;
    CVehicles := $B74494;
    CObjects := $B7449C;
    ParamsPtr[0] := $A43C78;

     // CLEO 3 Routines
    __ClearMissionLocals := $00464BB0;
    __CreateNewThread := $00464C20;
    __ParseThread := $00469F00;
    __CurrentMissionBlock := $00A7A6A0;
    __ContinueMissionFlag := $00A444B1;
    __ZeroThreadFields := $004648E0;
    __CLEO3_Hook := $0046A22F;
    __SaveID := $BA68A7;
    __MissionLocalsPoolOffs := $00A48960 - $3C; // -offset thread.locals
    pActiveThread := $00A8B42C;

    __GetVehicleHandle := $424160;
    __GetPedHandle := $4442D0;
    __TargetMarkerHandle := $00BA6774;
    CMarkers := $00BA86F0;
    __NumberOFGears := $C15C52;
    __GetZForXY := $569660;
    __IsMenuShown := $BA67A4;
//    __drawRect := $00727B60;

  end
  else
  begin
    isVersionOriginal := False;
    __CollectNumberParams := $464100;
    __WriteResult := $4643F0;
    __Null := $859B54;
    __GetObjectPointer := $4650C0;
    __ChDir := $538C70;
    __SetUserDirToCurrent := $538D00;
    __GetStringParam := $463DD0;
    __fopen := $538DA0;
    __SetConditionResult := $485A50;
    __fclose := $538E70;
    __GetVariablePos := $464810;
    __BlockRead := $538DF0;
    __BlockWrite := $538E10;
    __SetJumpLocation := $464E20;
    __GetThreadParams := $464580;

    CActors := $B76B10;
    CVehicles := $B76B14;
    CObjects := $B76B1C;
    ParamsPtr[0] := $A462F8;

     // CLEO 3 Routines
    __ParseThread := $00469F80;
    __CreateNewThread := $00464CA0;
    __ClearMissionLocals := $00464C30;
    __CurrentMissionBlock := $00A7CD20;
    __ContinueMissionFlag := $00A46B31;
    __ZeroThreadFields := $00464960;
    __CLEO3_Hook := $0046A2AF;
    __SaveID := $BA8F27;
    __MissionLocalsPoolOffs := $00A4AFE0 - $3C;
    pActiveThread := $00A8DAAC;

    __GetVehicleHandle := $4241E0;
    __GetPedHandle := $444350;
    __TargetMarkerHandle := $BA8DF4;
    CMarkers := $00BAAD70;
    __NumberOFGears := $C18412;
    __GetZForXY := $569B00;
    __IsMenuShown := $BA8E24;
//    __drawRect := $00728390;

  end;

  __GetCarPointer := $4048E0;
  __GetActorPointer := $404910;

  for C := 1 to 31 do
    ParamsPtr[c] := ParamsPtr[c - 1] + 4;

  if isVersionOriginal then
  begin
    PLongInt(Ptr($008A61D4))^ := Integer(@CLEO2);
    HookNewGame($005DE680); // cleo3 setup
    HookLoad($005D4FD0);
    HookSave($005D4C40);
    @TextDraw := Ptr($0071A700);
    @ScaleX := Ptr($005733E0);
    @ScaleY := Ptr($00573410);
    @SetFont := Ptr($00719490);
    @SetDrawAlign := Ptr($00719610);
    drawer := PDrawer($00C71A60);
  end
  else begin
    PLongInt(Ptr($008A74BC))^ := Integer(@CLEO2);
    HookNewGame($005DEEA0);
    HookSave($005D5420);
    HookLoad($005D57B0);
    @TextDraw := Ptr($0071AF30);
    @ScaleX := Ptr($00573950);
    @ScaleY := Ptr($00573980);
    @SetFont := Ptr($00719CC0);
    @SetDrawAlign := Ptr($00719E40);
    drawer := PDrawer($00C74220);
  end;


end.

