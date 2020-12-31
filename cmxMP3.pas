unit cmxMP3;
{
--------------------------------------------------------------------------------
    .mp3 player class

    this Delphi class plays .mp3 files using mci commands
    and edits ID3 v1.1 records set at the end of the .mp3 files

    an object built from this class represents a single .mp3 file
    as such it can be played, stopped, paused, resumed, and a v1.1 ID3
    record can be edited/saved with the file.

    progress and completion events are available for use during play of
    the .mp3 file

    the code for this class compiles under Delphi 5/6; my expectation is
    that it will compile under other releases as well perhaps with minor
    adjustments.  You have the code, so.....

    this class is released as sample code; it is well commented;
    use it, learn from it; all information presented here was gleaned
    from general Delphi knowledge and various publicly available
    sites on the internet.

    if you have questions, feel free to contact me at:
        clark@clarktisdale.com
--------------------------------------------------------------------------------
    yyyy.mm.dd  ini description
    2003.08.23  cdt initial creation
--------------------------------------------------------------------------------
}

interface

uses
  Windows, Classes, SysUtils, Messages;

type

  {
    exception thrown for MCI errors
  }
  eMciDeviceError = class(Exception);

  {
    enumerated type of player states
  }
  TMPMode = (mpNotReady, mpStopped, mpPlaying, mpRecording, mpSeeking
    , mpPaused, mpOpen, mpUnknown);

  {
    enumerated type of time formats
  }
  TMPTimeFormat = (tfMilliseconds, tfHMS, tfMSF, tfFrames, tfSMPTE24, tfSMPTE25
    , tfSMPTE30, tfSMPTE30Drop, tfBytes, tfSamples, tfTMSF);

  {
    OnPlayProgress event prototype
  }
  TcmxPlayProgress = procedure(Sender: TObject; aSecs: integer) of object;

  {
    ID3 v1.1 record
  }
  TcmxID3 = packed record
    Tag: array[0..2] of Char;
    Title: array[0..29] of Char;
    Artist: array[0..29] of Char;
    Album: array[0..29] of Char;
    Year: array[0..3] of Char;
    Comment: array[0..27] of Char;
    Filler: Char;
    Track: Byte;
    Genre: Byte;
  end; // TcmxID3

  {
    .mp3 player object
  }
  TcmxMP3 = class(TObject)
  private
    fDeviceID: WORD;
    fFilePath: string;
    fHWND: HWND;
    fID3: TcmxID3;
    fLgthInSecs: integer;
    fAutoPause: Boolean;

    // getters
    function getFileName: string;
    function getFilePath: string;
    function getAlbum: string;
    function getArtist: string;
    function getComment: string;
    function getTitle: string;
    function getYear: string;
    function getTrack: byte;
    function getGenreNdx: byte;
    function getGenreText(aNdx: integer): string;
    function getLengthInSeconds: integer;
    function getState: TMPMode;

    // mci methods
    procedure mciOpen;
    procedure mciClose;
    function mciGetErrorMessage(aError: integer): string;
    procedure mciCheckError(aError: integer);
    function mciGetMode: TMPMode;
    procedure mciResume;
    procedure mciPause;
    procedure mciPlay;
    procedure mciStop;
    procedure mciNotifyEvent(var Msg: TMessage);
    procedure mciWndMethod(var Msg: TMessage);
    procedure mciSetTimeFormat(aValue: TMPTimeFormat);
    function mciGetLength: Longint;
    function mciLgthInSecs: integer;
//    function mciGetPosition: Longint;

    // ID3 methods
    function id3Init: TcmxID3;
    function id3Get: TcmxID3;
    procedure id3Put(aID3: TcmxID3);

    // method passed to progress thread
  public
    // create an object for a specific .mp3 file
    constructor Create(const aFilePath: string);
    destructor Destroy; override;

    // player methods
    procedure Play;
    procedure Stop;
    procedure Pause;
    procedure Resume;

    // change ID3 record
    procedure ChgID3(const aTitle, aArtist, aAlbum, aComment: string;
      aYear: integer; aTrack, aGenre: byte);

    // change .mp3 file path (.mp3 extension is assumed)
    function ChgFilePath(const aFilePath, aFileName: string): boolean;

    // returns largest valid GenreID (0 is the lowest value)
    function MaxGenreID: integer;

    // returns genre text given a valid index
    property GenreText[aNdx: integer]: string
    read getGenreText;

    // length of .mp3 in seconds
    property LengthInSeconds: integer
      read getLengthInSeconds;

    // state of player (see TMPMode above)
    property State: TMPMode
      read getState;

    property AutoPause: Boolean
      read fAutoPause write fAutoPause;


    // ID3 values
    property Title: string
      read getTitle;
    property Artist: string
      read getArtist;
    property Album: string
      read getAlbum;
    property Comment: string
      read getComment;
    property Year: string
      read getYear;
    property Track: byte
      read getTrack;
    property GenreNdx: byte
      read getGenreNdx;

    // .mp3 file name only (no path and no extension)
    property FileName: string
      read getFileName;
    // .mp3 file path (directory where the file resides)
    property FilePath: string
      read getFilePath;

  end; // TcmxMP3


implementation

uses
  // Forms unit needed when compiling under Delphi 5
{$IFDEF VER130 }
  Forms,
{$ENDIF}
  mmSystem, Consts;

const
  cMaxID3Genre = 147;

  cID3Genre: array[0..cMaxID3Genre] of string = (
    'Blues'
    , 'Classic Rock'
    , 'Country'
    , 'Dance'
    , 'Disco'
    , 'Funk'
    , 'Grunge'
    , 'Hip-Hop'
    , 'Jazz'
    , 'Metal'
    , 'New Age'
    , 'Oldies'
    , 'Other'
    , 'Pop'
    , 'R&B'
    , 'Rap'
    , 'Reggae'
    , 'Rock'
    , 'Techno'
    , 'Industrial'
    , 'Alternative'
    , 'Ska'
    , 'Death Metal'
    , 'Pranks'
    , 'Soundtrack'
    , 'Euro-Techno'
    , 'Ambient'
    , 'Trip-Hop'
    , 'Vocal'
    , 'Jazz+Funk'
    , 'Fusion'
    , 'Trance'
    , 'Classical'
    , 'Instrumental'
    , 'Acid'
    , 'House'
    , 'Game'
    , 'Sound Clip'
    , 'Gospel'
    , 'Noise'
    , 'AlternRock'
    , 'Bass'
    , 'Soul'
    , 'Punk'
    , 'Space'
    , 'Meditative'
    , 'Instrumental Pop'
    , 'Instrumental Rock'
    , 'Ethnic'
    , 'Gothic'
    , 'Darkwave'
    , 'Techno-Industrial'
    , 'Electronic'
    , 'Pop-Folk'
    , 'Eurodance'
    , 'Dream'
    , 'Southern Rock'
    , 'Comedy'
    , 'Cult'
    , 'Gangsta'
    , 'Top 40'
    , 'Christian Rap'
    , 'Pop/Funk'
    , 'Jungle'
    , 'Native American'
    , 'Cabaret'
    , 'New Wave'
    , 'Psychadelic'
    , 'Rave'
    , 'Showtunes'
    , 'Trailer'
    , 'Lo-Fi'
    , 'Tribal'
    , 'Acid Punk'
    , 'Acid Jazz'
    , 'Polka'
    , 'Retro'
    , 'Musical'
    , 'Rock & Roll'
    , 'Hard Rock'
    , 'Folk'
    , 'Folk-Rock'
    , 'National Folk'
    , 'Swing'
    , 'Fast Fusion'
    , 'Bebob'
    , 'Latin'
    , 'Revival'
    , 'Celtic'
    , 'Bluegrass'
    , 'Avantgarde'
    , 'Gothic Rock'
    , 'Progressive Rock'
    , 'Psychedelic Rock'
    , 'Symphonic Rock'
    , 'Slow Rock'
    , 'Big Band'
    , 'Chorus'
    , 'Easy Listening'
    , 'Acoustic'
    , 'Humour'
    , 'Speech'
    , 'Chanson'
    , 'Opera'
    , 'Chamber Music'
    , 'Sonata'
    , 'Symphony'
    , 'Booty Bass'
    , 'Primus'
    , 'Porn Groove'
    , 'Satire'
    , 'Slow Jam'
    , 'Club'
    , 'Tango'
    , 'Samba'
    , 'Folklore'
    , 'Ballad'
    , 'Power Ballad'
    , 'Rhythmic Soul'
    , 'Freestyle'
    , 'Duet'
    , 'Punk Rock'
    , 'Drum Solo'
    , 'Acapella'
    , 'Euro-House'
    , 'Dance Hall'
    , 'Goa'
    , 'Drum & Bass'
    , 'Club-House'
    , 'Hardcore'
    , 'Terror'
    , 'Indie'
    , 'BritPop'
    , 'Negerpunk'
    , 'Polsk Punk'
    , 'Beat'
    , 'Christian Gangsta Rap'
    , 'Heavy Metal'
    , 'Black Metal'
    , 'Crossover'
    , 'Contemporary Christian'
    , 'Christian Rock'
    , 'Merengue'
    , 'Salsa'
    , 'Trash Metal'
    , 'Anime'
    , 'Jpop'
    , 'Synthpop'
    );

{ TcmxMP3 }
//------------------------------------------------------------------------------

constructor TcmxMP3.Create(const aFilePath: string);
begin
    // set initial values
  fDeviceID := 0;
  fFilePath := aFilePath;
  fID3 := id3Get;
  fLgthInSecs := mciLgthInSecs;
  fAutoPause := False;
    // allocate window proc to snag mci messages
  fHWND := AllocateHWND(mciWndMethod);
end; // Create

//------------------------------------------------------------------------------

destructor TcmxMP3.Destroy;
begin
    // deallocate window proc
  Stop; // todo: на версии 1.01 вызывает ошибку при выходе

  DeallocateHWND(fHWND);
    // call inherited destructor
  inherited Destroy;
end; // Destroy

//------------------------------------------------------------------------------

procedure TcmxMP3.mciCheckError(aError: integer);
var
  strMsg: string;
begin
    // exit if no error
  if (aError = 0) then Exit;

    // get error message and raise exception
  strMsg := mciGetErrorMessage(aError);
  raise eMciDeviceError.CreateFmt('%d - %s', [aError, strMsg]);
end; // mciCheckError

//------------------------------------------------------------------------------

function TcmxMP3.mciGetErrorMessage(aError: integer): string;
var
  ErrMsg: array[0..4095] of Char;
begin
  if (mciGetErrorString(aError, ErrMsg, SizeOf(ErrMsg))) then
  begin
    SetString(Result, ErrMsg, StrLen(ErrMsg));
  end // if
  else
  begin
    Result := SMCIUnknownError;
  end; // else
end; // mciGetErrorMessage

//------------------------------------------------------------------------------

function TcmxMP3.mciLgthInSecs: integer;
var
  intLength: integer;
  intMM, intSS: integer;
begin
    {
        this function is called from the constructor, so it opens and
        closes the player
    }
  mciOpen;
  try
        // set time format to milliseconds
    mciSetTimeFormat(tfMilliseconds);
        // get length of .mp3
    intLength := mciGetLength;
        // do the math to return number of seconds
    intLength := intLength div 1000;
    intMM := intLength div 60;
    intSS := intLength mod 60;
    Result := (intMM * 60) + intSS;
  finally
    mciClose;
  end; // try finally
end; // mciLgthInSecs

//------------------------------------------------------------------------------

procedure TcmxMP3.mciOpen;
var
  OpenParm: TMCI_Open_Parms;
  intFlags: integer;
  intError: integer;
begin
    // close player if active
  mciClose;

    // open player
  OpenParm.dwCallback := 0;
  OpenParm.lpstrDeviceType := 'WaveAudio';
  OpenParm.lpstrElementName := PChar(fFilePath);

  intFlags := MCI_WAIT or MCI_OPEN_ELEMENT or MCI_OPEN_SHAREABLE;

  intError := mciSendCommand(0, mci_Open, intFlags, Longint(@OpenParm));
  mciCheckError(intError);

    // save device ID
  fDeviceID := OpenParm.wDeviceID;
end; // mciOpen

//------------------------------------------------------------------------------

procedure TcmxMP3.mciClose;
var
  intFlags: integer;
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // close player
  intFlags := MCI_WAIT;
  intError := mciSendCommand(fDeviceID, mci_Close, intFlags, 0);
  mciCheckError(intError);

    // zero device ID
  fDeviceID := 0;
end; // mciClose

//------------------------------------------------------------------------------

function TcmxMP3.mciGetMode: TMPMode;
var
  StatusParm: TMCI_Status_Parms;
  intFlags: integer;
  intError: integer;
begin
    // set initial result
  Result := mpUnknown;

    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // get current state
  intFlags := mci_Wait or mci_Status_Item;
  StatusParm.dwItem := mci_Status_Mode;
  intError := mciSendCommand(fDeviceID
    , mci_Status, intFlags, Longint(@StatusParm));
  mciCheckError(intError);

    // set result
  case StatusParm.dwReturn of
    MCI_MODE_NOT_READY:
      begin
        Result := mpNotReady;
      end; // MCI_MODE_NOT_READY
    MCI_MODE_STOP:
      begin
        Result := mpStopped;
      end; // MCI_MODE_STOP
    MCI_MODE_PLAY:
      begin
        Result := mpPlaying;
      end; // MCI_MODE_PLAY
    MCI_MODE_RECORD:
      begin
        Result := mpRecording;
      end; // MCI_MODE_RECORD
    MCI_MODE_SEEK:
      begin
        Result := mpSeeking;
      end; // MCI_MODE_SEEK
    MCI_MODE_PAUSE:
      begin
        Result := mpPaused;
      end; //
    MCI_MODE_OPEN:
      begin
        Result := mpOpen;
      end; // MCI_MODE_OPEN
  end; // case
end; // mciGetMode

//------------------------------------------------------------------------------

procedure TcmxMP3.mciSetTimeFormat(aValue: TMPTimeFormat);
var
  SetParm: TMCI_Set_Parms;
  intFlags: integer;
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // set player to return specified time format
  intFlags := mci_Set_Time_Format;
  SetParm.dwTimeFormat := Longint(aValue);
  intError := mciSendCommand(fDeviceID
    , mci_Set, intFlags, Longint(@SetParm));
  mciCheckError(intError);
end; // mciSetTimeFormat

//------------------------------------------------------------------------------

function TcmxMP3.mciGetLength: Longint;
var
  StatusParm: TMCI_Status_Parms;
  intFlags: integer;
  intError: integer;
begin
    // set initial result
  Result := 0;

    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // get length of .mp3
  intFlags := mci_Wait or mci_Status_Item;
  StatusParm.dwItem := mci_Status_Length;
  intError := mciSendCommand(fDeviceID
    , mci_Status, intFlags, Longint(@StatusParm));
  mciCheckError(intError);
  Result := StatusParm.dwReturn;
end; // mciGetLength

//------------------------------------------------------------------------------

{
function TcmxMP3.mciGetPosition: Longint;
var
  StatusParm: TMCI_Status_Parms;
  intFlags: integer;
  intError: integer;
begin
    // set initial result
  Result := 0;

    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // get current position
  intFlags := mci_Wait or mci_Status_Item;
  StatusParm.dwItem := mci_Status_Position;
  intError := mciSendCommand(fDeviceID
    , mci_Status, intFlags, Longint(@StatusParm));
  mciCheckError(intError);
  Result := StatusParm.dwReturn;
end; // mciGetPosition
}
//------------------------------------------------------------------------------

procedure TcmxMP3.mciPlay;
var
  PlayParm: TMCI_Play_Parms;
  intFlags: integer;
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    {
        do play; set notify flag and give callback window
        this tells the player to send mci_Notify messages, so that
        a notification is given when the player finishes the .mp3
    }
  intFlags := mci_Notify;
  PlayParm.dwCallback := fHWND;
  intError := mciSendCommand(
    fDeviceID, mci_Play, intFlags, Longint(@PlayParm));
  mciCheckError(intError);
end; // mciPlay

//------------------------------------------------------------------------------

procedure TcmxMP3.mciWndMethod(var Msg: TMessage);
begin
  // snag MCI notify message
  if (Msg.Msg = MM_MCINOTIFY) then
  begin
    mciNotifyEvent(Msg);
  end // if
    // sink all other messages in the default window proc
  else
  begin
    Msg.Result := DefWindowProc(fHWND, Msg.Msg, Msg.wParam, Msg.lParam);
  end; // else
end; // mciWndMethod

//------------------------------------------------------------------------------

procedure TcmxMP3.mciNotifyEvent(var Msg: TMessage);
var
  intError: integer;
begin
  case Msg.wParam of
    // end of play has been reached
    mci_Notify_Successful:
      begin
        // stop and close player
      Stop;
//      play;
{    // exit if player is not active
        if (fDeviceID = 0) then Exit;

        intError := mciSendCommand(fDeviceID, MCI_SEEK, MCI_SEEK_TO_START, 0);
        mciCheckError(intError);
        mciPlay;
}
      end;
  end; // case
end; // mciNotifyEvent

//------------------------------------------------------------------------------

procedure TcmxMP3.mciStop;
var
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // do stop
  intError := mciSendCommand(fDeviceID, mci_Stop, 0, 0);
  mciCheckError(intError);
end; // mciStop

//------------------------------------------------------------------------------

procedure TcmxMP3.mciPause;
var
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;
    // do pause
  intError := mciSendCommand(fDeviceID, mci_Pause, 0, 0);
  mciCheckError(intError);
end; // mciPause

//------------------------------------------------------------------------------

procedure TcmxMP3.mciResume;
var
  intError: integer;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // do resume
  intError := mciSendCommand(fDeviceID, mci_Resume, 0, 0);
  mciCheckError(intError);
end; // mciResume

//------------------------------------------------------------------------------

procedure TcmxMP3.Play;
var
  lMode: TMPMode;
begin
    // open player if not already open
  if (fDeviceID = 0) then mciOpen;

    // get current state
  lMode := State;

    // if currently playing; stop player (to restart at the beginning)
  if (lMode = mpPlaying) then Stop;

    // play the .mp3
  mciPlay;

{    // start progress thread
  if (Assigned(fOnPlayProgress)) then
  begin
    fProgressTimer := TcmxProgressThread.Create(OnProgressTimer);
  end; // if
}
end; // Play

//------------------------------------------------------------------------------

procedure TcmxMP3.Stop;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // stop the player
  mciStop;

    // close the player
  mciClose;
end; // Stop

//------------------------------------------------------------------------------

procedure TcmxMP3.Pause;
var
  lMode: TMPMode;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // get current state
  lMode := State;

  if (lMode = mpPlaying) then
    mciPause;
end; // Pause

//------------------------------------------------------------------------------

procedure TcmxMP3.Resume;
var
  lMode: TMPMode;
begin
    // exit if player is not active
  if (fDeviceID = 0) then Exit;

    // get current state
  lMode := State;

    {
        if paused; resume play
        resume progress thread if it is running
    }
  if (lMode = mpPaused) then
    mciResume;
end; // Resume

//------------------------------------------------------------------------------

function TcmxMP3.getState: TMPMode;
begin
    // get current state
  Result := mciGetMode;
end; // getState

//------------------------------------------------------------------------------

function TcmxMP3.id3Init: TcmxID3;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Tag := 'TAG';
end; // id3Init

//------------------------------------------------------------------------------

function TcmxMP3.id3Get: TcmxID3;
var
  lMP3: TFileStream;
begin
    // read the end of the file
  lMP3 := TFileStream.Create(fFilePath, fmOpenRead);
  try
    lMP3.Position := lMP3.Size - SizeOf(Result);
    lMP3.Read(Result, SizeOf(Result));
  finally
    lMP3.Free;
  end; // try finally

    // if result isn't a valid ID3 record; return initialized record
  if (Result.Tag <> 'TAG') then
  begin
    Result := id3Init;
  end; // if
end; // id3Get

//------------------------------------------------------------------------------

procedure TcmxMP3.id3Put(aID3: TcmxID3);
var
  lMP3: file of Byte;
  OldID3: TcmxID3;
begin
    // open the .mp3 file
  AssignFile(lMP3, fFilePath);
  Reset(lMP3);
  try
        // find the end of the file
    Seek(lMP3, FileSize(lMP3) - SizeOf(OldID3));
        // read the ID3 record
    BlockRead(lMP3, OldID3, SizeOf(OldID3));
        // is the record valid?
    if (OldID3.Tag = 'TAG') then
    begin
            // re-position for write
      Seek(lMP3, FileSize(lMP3) - SizeOf(OldID3));
    end // if
    else
    begin
            // position to the end for write
      Seek(lMP3, FileSize(lMP3));
    end; // else
        // write the new ID3 record
    BlockWrite(lMP3, aID3, SizeOf(aID3));
  finally
        // close the .mp3 file
    CloseFile(lMP3);
  end; // try finally
end; // id3Put

//------------------------------------------------------------------------------

function TcmxMP3.ChgFilePath(const aFilePath, aFileName: string): boolean;
var
  strNewPath: string;
begin
    {
        build new file path variable
        note: ifdef is for Delphi 5 support
    }
{$IFDEF VER130 }
  strNewPath := IncludeTrailingBackSlash(aFilePath)
    + aFileName + '.mp3';
{$ELSE}
  strNewPath := IncludeTrailingPathDelimiter(aFilePath)
    + aFileName + '.mp3';
{$ENDIF}

    // rename (or move) the file
  Result := MoveFile(PChar(fFilePath), PChar(strNewPath));

    // if rename is successful; save new path name
  if (Result) then
  begin
    fFilePath := strNewPath;
  end; // if
end; // ChgFilePath

//------------------------------------------------------------------------------

function TcmxMP3.getFileName: string;
begin
    // return name of file (no path;  no extension)
  Result := ChangeFileExt(ExtractFileName(fFilePath), '');
end; // getFileName

//------------------------------------------------------------------------------

function TcmxMP3.getFilePath: string;
begin
    // return file path only
  Result := ExtractFilePath(fFilePath);
end; // getFilePath

//------------------------------------------------------------------------------

function TcmxMP3.getAlbum: string;
begin
  Result := fID3.Album;
end; // getAlbum

//------------------------------------------------------------------------------

function TcmxMP3.getArtist: string;
begin
  Result := fID3.Artist;
end; // getArtist

//------------------------------------------------------------------------------

function TcmxMP3.getComment: string;
begin
  Result := fID3.Comment;
end; // getComment

//------------------------------------------------------------------------------

function TcmxMP3.getTitle: string;
begin
  Result := fID3.Title;
end; // getTitle

//------------------------------------------------------------------------------

function TcmxMP3.getYear: string;
begin
  Result := fID3.Year;
end; // getYear

//------------------------------------------------------------------------------

function TcmxMP3.getTrack: byte;
begin
  Result := fID3.Track;
end; // getTrack

//------------------------------------------------------------------------------

function TcmxMP3.getGenreNdx: byte;
begin
  Result := fID3.Genre;
end; // getGenreNdx

//------------------------------------------------------------------------------

procedure TcmxMP3.ChgID3(const aTitle, aArtist, aAlbum, aComment: string;
  aYear: integer; aTrack, aGenre: byte);
var
  lID3: TcmxID3;
begin
    // initialize ID3 record structure
  lID3 := id3Init;

    // fill values
  StrPCopy(lID3.Title, aTitle);
  StrPCopy(lID3.Artist, aArtist);
  StrPCopy(lID3.Album, aAlbum);
  StrPCopy(lID3.Year, IntToStr(aYear));
  StrPCopy(lID3.Comment, aComment);
  lID3.Track := aTrack;
  lID3.Genre := aGenre;

    // write ID3 record to file
  id3Put(lID3);
end; // ChgID3

//------------------------------------------------------------------------------

function TcmxMP3.MaxGenreID: integer;
begin
  Result := cMaxID3Genre;
end; // MaxGenreID

//------------------------------------------------------------------------------

function TcmxMP3.getGenreText(aNdx: integer): string;
begin
    // insure index is within valid range
  if (aNdx in [0..cMaxID3Genre]) then
  begin
        // return text for specified index
    Result := cID3Genre[aNdx];
  end // if
  else
  begin
        // return index value if out-of-range
    Result := IntToStr(aNdx);
  end; // else
end; // getGenreText

//------------------------------------------------------------------------------

function TcmxMP3.getLengthInSeconds: integer;
begin
  Result := fLgthInSecs;
end; // getLengthInSeconds

//------------------------------------------------------------------------------

{
procedure TcmxMP3.OnProgressTimer(Sender: TObject);
var
  intSecs: integer;
  intPos: integer;
  intMM, intSS: integer;
begin
    // determine position
  mciSetTimeFormat(tfMilliseconds);
  intPos := mciGetPosition;
  intPos := intPos div 1000;
  intMM := intPos div 60;
  intSS := intPos mod 60;
  intSecs := (intMM * 60) + intSS;

    // fire event (pass current position)
  if (Assigned(fOnPlayProgress)) then
  begin
    fOnPlayProgress(self, intSecs);
  end; // if
end; // OnProgressTimer
}

//------------------------------------------------------------------------------
end.

