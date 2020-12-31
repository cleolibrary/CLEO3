unit uCLEO3;

interface uses Windows, SysUtils, Classes, uSTRROUTES, cmxMP3;

const
  SaveStamp = $01234567;
  CLEO_Path = 'cleo\';
  SavePath = CLEO_Path + 'cleo_saves\';
  MissionPath = CLEO_Path;

  DefaultExt = '.cs';
  ScriptExt = DefaultExt;
  MissionExt = '.cm';
  SaveExt = '.sav';

  SaveNameMask = 'cs%d';

  CLEO_Version = '3.0.952';
  CLEO_Version_Num = 30952;

type

{$A4}
  PSAThread = ^TSAThread;
  PCustomThread = ^TCustomThread;
  TSAThread = record
    NextThread, PrevThread: DWORD;
    Name: array[0..7] of Char;
    BaseIP, CurrentIP: DWORD;
    ReturnStack: array[0..7] of DWORD;
    StackIndex: WORD;
    TLS_ID: WORD; // added!
    LocalVars: array[0..31] of DWORD;
    TimerA, TimerB: DWORD;
    ThreadActiveFlag, IF_result, MissionCleanupFlag, ExternalFlag: Boolean;
    InMenu, UnknownScriptAssigned: Boolean; // unknown
    WakeupTime: DWORD;
    IfNumber: WORD;
    NotFlag, WBcheckFlag, WastedOrBustedFlag: Boolean;
    SaveThreadFlag: Boolean; // added!
    SkipScenePos: DWORD;
    MissionFlag: Boolean;

    ScriptFileName: ShortString;
    ClassPtr: PCustomThread;
  end;

   { TCustomThread }

  TCustomThread = class
    fThread: TSAThread;
  protected
    fData: array of Byte;
    function Compile(const aFile: string): Boolean;
    function CreateThread(const aFile: string): Boolean;
  public
    constructor Create(const aFile: string);
    destructor Destroy; override;
  end;


var
  ActiveThreadIndex, fTickTime: Integer;
  CustomThreadList: TList;
  InactiveThreads2bSaved: TStringList;
  fs: TSearchRec;
  pKey: array[0..6] of Byte = ($52, $47, $41, $45, $51, $6E, $E);

  


function FindThreadByName(pName: PChar): LongInt; stdcall;
function FindThreadByFileName(pName: PChar): LongInt; stdcall;
function CreateCustomThread(const aFile: PChar): TCustomThread; stdcall;
procedure EndCustomThread(const ThreadPtr: PSAThread); stdcall;
procedure WriteMemoryVP(const Offset: Pointer; const Value: LongInt); stdcall;
function ReadMemoryVP(const Offset: Pointer): LongInt; stdcall;
procedure CustomThreadsProcessor; stdcall;
procedure StartCustomMission(const aFile: PChar); stdcall;
procedure CLEO3Init;
procedure CLEO3Destroy;
procedure SaveCustomThreads;
procedure LoadCustomThreads;

implementation uses uCLEO2, globalScope, ProcInt;

function ReadMemoryVP(const Offset: Pointer): LongInt; stdcall;
var
  d, dw: Cardinal;
begin
  VirtualProtect(Offset, 4, 4, @d);
  Result := PLongInt(Offset)^;
  VirtualProtect(Offset, 4, d, @dw);
end;

procedure WriteMemoryVP(const Offset: Pointer; const Value: LongInt); stdcall;
var
  d, dw: Cardinal;
begin
  VirtualProtect(Offset, 4, 4, @d);
  PLongInt(Offset)^ := Value;
  VirtualProtect(Offset, 4, d, @dw);
end;

function SameShortStr(P1, P2: Pointer; Len: Integer=8): Boolean;
asm
        PUSH    ESI
        PUSH    EDI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        XOR     EBX, EBX
@@01:
        MOVZX   EAX,BYTE PTR [ESI+EBX]
        MOVZX   EDX,BYTE PTR [EDI+EBX]
        CMP     AL,DL
        JE      @@NEXT
        MOV     AL,BYTE PTR [EAX+ToUpperChars]
        XOR     AL,BYTE PTR [EDX+ToUpperChars]
        JE      @@NEXT
        POP     EBX
        POP     EDI
        POP     ESI
        XOR     EAX,EAX
        RET
@@NEXT:
        TEST    DL,DL
        JZ      @@qt
        INC     EBX
        CMP     EBX, ECX
        JNZ     @@01
@@qt:   POP     EBX
        POP     EDI
        POP     ESI
@@08:   MOV     EAX, 1
end;

function FindThreadByFileName(pName: PChar): LongInt; stdcall;
var
  I: Integer;
  filePath: string;
begin
  Result := 0;
  filePath := CLEO_Path + pName;
  // search thru CLEO scripts
  if Assigned(CustomThreadList) then
  begin
    for I := 0 to CustomThreadList.Count - 1 do
      if SameShortStr(@PSAThread(CustomThreadList[i])^.ScriptFileName[1], PChar(filePath), 255) then
      begin
        Result := LongInt(CustomThreadList[i]);
        Break;
      end;
  end;
end;


function FindThreadByName(pName: PChar): LongInt; stdcall;
var
  I: Integer;
begin
  Result := PLongInt(pActiveThread)^;
  while Result <> 0 do
  begin
    if SameShortStr(@PSAThread(Result).Name[0], pName) then
      Break;
    Result := PLongInt(Result)^;
  end;
  // search thru CLEO scripts
  if (Result = 0) and Assigned(CustomThreadList) then
  begin
    for I := 0 to CustomThreadList.Count - 1 do
      if SameShortStr(@PSAThread(CustomThreadList[i])^.Name[0], pName) then
      begin
        Result := LongInt(CustomThreadList[i]);
        Break;
      end;
  end;
end;

procedure EndCustomThread(const ThreadPtr: PSAThread); stdcall;
var
  Index: Integer;
begin
  if Assigned(CustomThreadList) then
  begin
    Index := CustomThreadList.IndexOf(ThreadPtr);
    if Index > -1 then
    begin
      if PSAThread(CustomThreadList[Index]).SaveThreadFlag then
        InactiveThreads2bSaved.Add(PSAThread(CustomThreadList[Index]).ScriptFileName);
      TCustomThread(PSAThread(CustomThreadList[Index]).ClassPtr).Free;
      CustomThreadList.Delete(Index);
      Dec(ActiveThreadIndex);
    end;
  end;
end;

procedure CustomThreadsProcessor; stdcall;
  procedure Parse; stdcall;
  var
    fActiveThread: PSAThread;
  begin
    if ActiveThreadIndex < 0 then ActiveThreadIndex := 0; // end_custom_thread_named called from the main.scm makes the ActiveThreadIndex = -1

    if Assigned(CustomThreadList) and (CustomThreadList.Count > ActiveThreadIndex) and Assigned(CustomThreadList[ActiveThreadIndex]) and PSAThread(CustomThreadList[ActiveThreadIndex])^.ThreadActiveFlag then
    begin
      fActiveThread := PSAThread(CustomThreadList[ActiveThreadIndex]);
      Inc(fActiveThread^.TimerA, fTickTime);
      Inc(fActiveThread^.TimerB, fTickTime);
      // call parsing
      asm
        mov ecx, [fActiveThread]
        call __ParseThread
        Inc ActiveThreadIndex;
        call Parse;
      end;
    end else ActiveThreadIndex := 0;
  end;
asm
      mov eax, [esp+20]
      mov [fTickTime], eax
      call Parse
      jmp __CLEO3_CallBack
end;

function CreateCustomThread(const aFile: PChar): TCustomThread; stdcall;
begin
  Result := TCustomThread.Create(CLEO_Path + aFile);
end;

procedure StartCustomMission(const aFile: PChar); stdcall;
var
  BinFile: file of Byte;
  MissionPtr: Pointer;
  lpName: string;
begin
  lpName := MissionPath + aFile + MissionExt;
  if FileExists(lpName) then
  begin
    AssignFile(BinFile, lpName);
    Reset(BinFile);
    MissionPtr := Ptr(__CurrentMissionBlock);
    BlockRead(BinFile, MissionPtr^, FileSize(BinFile));
    CloseFile(BinFile);
    asm
      call    __ClearMissionLocals
      push    __CurrentMissionBlock
      call    __CreateNewThread
      mov     TSAThread(eax).MissionCleanupFlag, 1
      mov     TSAThread(eax).MissionFlag, 1
      mov     edx, __CurrentMissionBlock
      mov     TSAThread(eax).BaseIP, edx
      mov     edx, __ContinueMissionFlag
      mov     byte ptr [edx], 1
    end;
  end;
end;


{ TCustomThread }

constructor TCustomThread.Create(const aFile: string);
begin
  inherited Create;
  Inc(ScrCount);
//  FileName := aFile;
  if not Compile(aFile) then Destroy;
end;

destructor TCustomThread.Destroy;
begin
  SetLength(fData, 0);
  Dec(ScrCount);
  inherited;
end;

function TCustomThread.Compile(const aFile: string): Boolean;
var
  fFile: file of Byte;
begin
  Result := False;

  if FileExists(aFile) then
  begin
    AssignFile(fFile, aFile);
    Reset(fFile);
    SetLength(fData, FileSize(fFile));
    BlockRead(fFile, fData[0], Length(fData));
    CloseFile(fFile);
    Result := CreateThread(aFile);
  end;
end;


function TCustomThread.CreateThread(const aFile: string): Boolean; // creates a thread using Data
var
  fn: string;
begin
  Result := True;
  asm
       mov ecx, Self
       lea ecx, [ecx].TCustomThread.FThread
       call __ZeroThreadFields
  end;
  with fThread do
  begin
    ScriptFileName := aFile;
    fn := Q_CopyRange(ScriptFileName, Q_PosLastStr('\', ScriptFileName) + 1, Q_PosLastStr('.', ScriptFileName) - 1);

    Q_MoveMem(PChar(fn), @Name[0], 7);
    BaseIP := LongWord(@fData[0]);
    CurrentIP := LongWord(@fData[0]);
    ThreadActiveFlag := True;
  end;
  CustomThreadList.Add(@fThread);
  fThread.ClassPtr := PCustomThread(Self);
end;

procedure CLEO3Init;
begin
  CLEO3Destroy;
  CustomThreadList := TList.Create;
  InactiveThreads2bSaved := TStringList.Create;
  ActiveThreadIndex := 0;
  if Sysutils.FindFirst(CLEO_Path + '*' + DefaultExt, faAnyFile, fs) = 0 then
  begin
    if not CallbackGot then
    begin
      __CLEO3_CallBack := __CLEO3_Hook + 4 + PLongInt(__CLEO3_Hook)^;
      CallbackGot := True;
    end;
    WriteMemoryVP(Ptr(__CLEO3_Hook), LongInt(@CustomThreadsProcessor) - __CLEO3_Hook - 4);
    repeat
      TCustomThread.Create(PChar(CLEO_Path + fs.Name));
    until FindNext(fs) <> 0;
  end;
  Sysutils.FindClose(fs);
end;

procedure CLEO3Destroy;
var
  I: Integer;
begin
  if Assigned(CustomThreadList) then
    for I := 0 to CustomThreadList.Count - 1 do
    begin
      TCustomThread(PSAThread(CustomThreadList[I]).ClassPtr).Free;
      CustomThreadList[i] := nil;
    end;
  FreeAndNil(CustomThreadList);
  FreeAndNil(InactiveThreads2bSaved);
  // destroy all mp3s
  if Assigned(Mp3List) then
  begin
    for I := 0 to Mp3List.Count - 1 do
      if Assigned(Mp3List[i]) then
        TcmxMP3(Mp3List[i]).Destroy;
  end;
  UnhookWindowsHookEx(aKeyHook);
  UnhookWindowsHookEx(aWndHook);
  FreeAndNil(Mp3List);
end;

{$DEFINE USEHASH}

procedure LoadCustomThreads;
var
  fFile: file of Byte;
  i, j, p, Count, dPos, dLen, hPos: integer;
  fByteData: array of Byte;
  pRCID: TRC4ID;
  lpName: string;
  dwBase, dwpStorage: Cardinal;
  SaveSlot: Byte;
  CsScriptFound: Boolean;
begin
  SaveSlot := PByte(__SaveID)^;
  lpName := SavePath + Format(SaveNameMask, [SaveSlot + 1]) + SaveExt;
  if FileExists(lpName) then
  begin
    AssignFile(fFile, lpName);
    try
      Reset(fFile);
      SetLength(fByteData, FileSize(fFile));
      BlockRead(fFile, fByteData[0], Length(fByteData));
{$IFDEF USEHASH}
      Q_XORByChar(@fByteData[0], Length(fByteData), 'S');
      Q_RC4Init(pRCID, @pkey[0], 7);
      Q_RC4Apply(pRCID, @fByteData[0], Length(fByteData));
      Q_RC4Done(pRCID);
{$ENDIF}
      if (PLongInt(@fByteData[0])^ = $4F454C43 xor SaveStamp) or // new
        (PLongInt(@fByteData[0])^ = $4F454C43 xor $0C0D0E0F) then // old
      begin
        Count := PWord(@fByteData[4])^;
        dPos := 6;

        for J := 0 to Count - 1 do
        begin
          dLen := PByte(@fByteData[dPos])^;
          SetString(lpName, PChar(@fByteData[dPos + 1]), dLen);

          Inc(dPos, dLen + 1);
          hPos := PLongInt(@fByteData[dPos])^;
          CsScriptFound := False;
          if FileExists(lpName) then
          begin
            for I := 0 to CustomThreadList.Count - 1 do
            begin
              if not SameText(PSAThread(CustomThreadList[I])^.ScriptFileName, PSAThread(@fByteData[hPos])^.ScriptFileName) then
                Continue;
              dwBase := PSAThread(CustomThreadList[I])^.BaseIP;
              Q_CopyMem(@fByteData[PLongInt(@fByteData[dPos])^], PSAThread(CustomThreadList[I]), (SizeOf(TSAThread) - 4));
              with PSAThread(CustomThreadList[I])^ do
              begin
                for P := 0 to StackIndex - 1 do
                  ReturnStack[P] := ReturnStack[P] - BaseIP + dwBase;

                CurrentIP := CurrentIP - BaseIP + dwBase;
                BaseIP := dwBase;
              end;
              CsScriptFound := True;
              Break;
            end;
            if not CsScriptFound then
              TCustomThread.Create(lpName); { TODO? : ���� CM - �� ��������� ������ }
          end;
          Inc(dPos, 4);
        end;
        // CLEO Global Storage
        dwpStorage := PLongInt(@fByteData[dPos])^;
        Q_CopyMem(@fByteData[dwpStorage], @CLEO_Global_Storage[0], TotalCLEOVars * 4);
        Inc(dPos, 4);

        // Inactive Saved Threads
        Count := PWord(@fByteData[dPos])^;
        Inc(dPos, 2);

        for J := 0 to Count - 1 do
        begin
          dLen := PByte(@fByteData[dPos])^;
          lpName := string(Copy(fByteData, dPos + 1, dLen));
          Inc(dPos, dLen + 1);

          I := 0;
          while I < CustomThreadList.Count do
            if Q_SameText(PSAThread(CustomThreadList[i]).ScriptFileName, lpName) then
            begin
              PSAThread(CustomThreadList[i]).SaveThreadFlag := True;
              EndCustomThread(CustomThreadList[i]);
              I := 0;
            end
            else Inc(I);

        end;

        if (PLongInt(@fByteData[0])^ = $4F454C43 xor SaveStamp) then // old save format doesn't have this block
        begin
          // Thread TLS
          dPos := dwpStorage + TotalCLEOVars * 4;
          Count := PWord(@fByteData[dPos])^;
          Inc(dPos, 2);

          for I := 0 to Count - 1 do
          begin
            if PTLS(@fByteData[dPos])^.saveFlag and PTLS(@fByteData[dPos])^.used then
              Q_CopyMem(@fByteData[dPos], @Threads_TLS[i + 1], SizeOf(TLS));
            Inc(dPos, SizeOf(TLS));
          end;
        end

      end;
    finally
      SetLength(fByteData, 0);
      CloseFile(fFile);
    end;
  end;
  ActiveThreadIndex := 0;
end;

procedure SaveCustomThreads;
var
  fFile: file of Byte;
  i, hSize, aOf, Count: integer;
  fByteData: array of Byte;
  pRCID: TRC4ID;
  lpName: ShortString;
  SaveSlot: Byte;
begin
  if not DirectoryExists(SavePath) then CreateDir(SavePath);

  SaveSlot := PByte(__SaveID)^;
  lpName := SavePath + Format(SaveNameMask, [SaveSlot + 1]) + SaveExt;
  AssignFile(fFile, lpName);

  try
    Rewrite(fFile);

    hSize := 12; // HeaderStamp(4)+ActiveThreadCount(2)+globalStorageOffset(4)+InactiveThreadsCount(2)
    Count := 0;
    for I := 0 to CustomThreadList.Count - 1 do
      if PSAThread(CustomThreadList[i])^.SaveThreadFlag then
      begin
        Inc(hSize, Length(PSAThread(CustomThreadList[i]).ScriptFileName) + 1);
        Inc(Count);
      end;

    for I := 0 to InactiveThreads2bSaved.Count - 1 do
      Inc(hSize, Length(InactiveThreads2bSaved[i]) + 1);

    Inc(hSize, Count * 4);

      // stamp
    aOf := $4F454C43 xor SaveStamp;
    BlockWrite(fFile, aOf, 4);

      // Count
    BlockWrite(fFile, Count, 2);

      // scripts offsets and names
    Count := 0;
    for I := 0 to CustomThreadList.Count - 1 do
      if PSAThread(CustomThreadList[i])^.SaveThreadFlag then
      begin
        lpName := PSAThread(CustomThreadList[i]).ScriptFileName;
        BlockWrite(fFile, lpName, Length(lpName) + 1);
        aOf := (SizeOf(TSAThread) - 4) * Count + HSize;
        BlockWrite(fFile, aOf, 4);
        Inc(Count);
      end;

      // CLEO Global Storage Offset
    if Count = 0 then
      aOf := HSize
    else
      Inc(aOf, (SizeOf(TSAThread) - 4));
    BlockWrite(fFile, aOf, 4);

      // Inactive Saved Threads
    aOf := InactiveThreads2bSaved.Count;
    BlockWrite(fFile, aOf, 2);
    for I := 0 to aOf - 1 do
    begin
      lpName := InactiveThreads2bSaved[i];
      BlockWrite(fFile, lpName, Length(lpName) + 1);
    end;

      // threads dump
    for I := 0 to CustomThreadList.Count - 1 do
      if PSAThread(CustomThreadList[i])^.SaveThreadFlag then
        BlockWrite(fFile, PSAThread(CustomThreadList[I])^, (SizeOf(TSAThread) - 4));

    // CLEO GS dump
    BlockWrite(fFile, CLEO_Global_Storage, TotalCLEOVars * 4);

    // Threads TLS dump
    Count := 0;
    for i := 1 to TotalThreadNumber do
      if Threads_TLS[i].used then
        Count := i;
    BlockWrite(fFile, Count, 2);

    for I := 1 to Count do
      BlockWrite(fFile, Threads_TLS[i], SizeOf(TLS));

{$IFDEF USEHASH}
    Reset(fFile);
    SetLength(fByteData, FileSize(fFile));
    BlockRead(fFile, fByteData[0], FileSize(fFile));
    Q_XORByChar(@fByteData[0], Length(fByteData), 'S');
    Q_RC4Init(pRCID, @pkey[0], 7);
    Q_RC4Apply(pRCID, @fByteData[0], Length(fByteData));
    Q_RC4Done(pRCID);
    Rewrite(fFile);
    BlockWrite(fFile, fByteData[0], Length(fByteData));
{$ENDIF}

  finally
    SetLength(fByteData, 0);
    CloseFile(fFile);
  end;
end;


end.

