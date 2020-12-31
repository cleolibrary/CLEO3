unit globalScope;

interface uses Windows,Classes;

type

  TVars = array[0..31] of LongInt;
  PTLS = ^TLS;
  TLS = record
    vars: TVars;
    used: Boolean;
    saveFlag: Boolean;
    prev: Word;
  end;

const
  TotalThreadNumber = 255;
  TotalCLEOVars = 1000;

var
  __CollectNumberParams,
    __WriteResult,
    __GetActorPointer,
    __GetCarPointer,
    __GetObjectPointer,
    __SetUserDirToCurrent,
    __GetStringParam,
    __SetConditionResult,
    __GetVariablePos,
    __SetJumpLocation,
    __GetThreadParams,
    __ClearMissionLocals,
    __CreateNewThread,
    __ParseThread,
    __SaveID,
    __MissionLocalsPoolOffs,
    __CurrentMissionBlock,
    __ContinueMissionFlag,
    __ZeroThreadFields,
    __CLEO3_Hook, __CLEO3_CallBack,
    __BlockRead,
    __BlockWrite,
    __Null,
    __ChDir,
    __fopen,
    __fclose,
    __GetVehicleHandle, __GetPedHandle,

    __TargetMarkerHandle, CMarkers, __NumberOFGears, __GetZForXY,
    __IsMenuShown,
//    __drawRect,
    pActiveThread,
    
    CActors,
    CVehicles,
    CObjects: LongInt;

  dwiOldProtect: LongInt;
  isVersionOriginal: ByteBool;
  CallbackGot: Boolean = False;
  ParamsPtr: TVars;  

  CLEO_Global_Storage: array[0..TotalCLEOVars-1] of LongInt;
  Threads_TLS: array[0..TotalThreadNumber] of TLS;
//  FreeTLS: array[0..TotalThreadNumber] of Byte;


  Temp_TLS: array[0..33 + 60] of LongInt;

  Mp3List: TList;
  aKeyHook, aWndHook: HHOOK;


implementation



end.

