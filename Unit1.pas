{ KOL MCK } // Do not remove this line!
{$DEFINE KOL_MCK}
unit Unit1;

interface

{$IFDEF KOL_MCK}
uses Windows, Messages, KOL {$IFNDEF KOL_MCK}, mirror, Classes, Controls, mckCtrls, mckObjs, Graphics {$ENDIF (place your units here->)};
{$ELSE}
{$I uses.inc}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  mirror;
{$ENDIF}

type
  {$IFDEF KOL_MCK}
  {$I MCKfakeClasses.inc}
  {$IFDEF KOLCLASSES} {$I TForm1class.inc} {$ELSE OBJECTS} PForm1 = ^TForm1; {$ENDIF CLASSES/OBJECTS}
  {$IFDEF KOLCLASSES}{$I TForm1.inc}{$ELSE} TForm1 = object(TObj) {$ENDIF}
    Form: PControl;
  {$ELSE not_KOL_MCK}
  TForm1 = class(TForm)
  {$ENDIF KOL_MCK}
    KOLProject1: TKOLProject;
    KOLForm1: TKOLForm;
    editFile: TKOLEditBox;
    btnFile: TKOLButton;
    OpenDialog1: TKOLOpenSaveDialog;
    GroupBox1: TKOLGroupBox;
    Label4: TKOLLabel;
    Label7: TKOLLabel;
    Label3: TKOLLabel;
    Label6: TKOLLabel;
    GroupBox2: TKOLGroupBox;
    btnErase: TKOLButton;
    Label9: TKOLLabel;
    lblTime: TKOLLabel;
    Label10: TKOLLabel;
    Label13: TKOLLabel;
    Label14: TKOLLabel;
    Label11: TKOLLabel;
    lblFilename: TKOLLabel;
    lblDate: TKOLLabel;
    lblOverwrite: TKOLLabel;
    lblVerify: TKOLLabel;
    Label15: TKOLLabel;
    lblOldName: TKOLLabel;
    lblOldPath: TKOLLabel;
    lblOldCreated: TKOLLabel;
    lblOldSize: TKOLLabel;
    Label2: TKOLLabel;
    lblStatus: TKOLLabel;
    Label16: TKOLLabel;
    Label17: TKOLLabel;
    lblOldModified: TKOLLabel;
    lblOldAccessed: TKOLLabel;
    Label5: TKOLLabel;
    lblDelete: TKOLLabel;
    Label8: TKOLLabel;
    procedure editFileDropFiles(Sender: PControl;
      const FileList: KOL_String; const Pt: TPoint);
    procedure btnFileClick(Sender: PObj);
    procedure GroupBox1DropFiles(Sender: PControl;
      const FileList: KOL_String; const Pt: TPoint);
    procedure btnEraseClick(Sender: PObj);
  private
    procedure Check(Sender: PControl; Good: Boolean; Text: String);
    procedure FileInformation(FileName: KOLString);
  public
    { Public declarations }
  end;

var
  Form1 {$IFDEF KOL_MCK} : PForm1 {$ELSE} : TForm1 {$ENDIF} ;

{$IFDEF KOL_MCK}
procedure NewForm1( var Result: PForm1; AParent: PControl );
{$ENDIF}

implementation

{$IFNDEF KOL_MCK} {$R *.DFM} {$ENDIF}

{$IFDEF KOL_MCK}
{$I Unit1_1.inc}
{$ENDIF}

{$R koleraser.res}



function GetFileSizeEx(hFile: THandle; var lpFileSize: I64): Boolean; stdcall;
  external 'kernel32.dll' name 'GetFileSizeEx';
function StrFormatByteSize64(dw: I64; szBuf: PChar; uiBufSize: UINT): PChar; stdcall;
  external 'shlwapi.dll' name 'StrFormatByteSize64A';


procedure TForm1.Check(Sender: PControl; Good: Boolean; Text: String);
begin
  Sender.Caption := Text;
  if Good then Sender.Font.Color := clGreen else Sender.Font.Color := clRed;
end;

procedure TForm1.FileInformation(FileName: KOLString);
var
  Buffer: array [0..255] of Char;
  F: THandle;
  FSize: I64;
  CTime, ATime, MTime: TFileTime;
  BufTime: TDateTime;
begin
  lblOverwrite.Clear;       // clearing routines
  lblVerify.Clear;
  lblDate.Clear;
  lblFilename.Clear;
  lblDelete.Clear;

  lblTime.Clear;
  lblStatus.Clear;

  lblOldName.Caption := ExtractFileName(Filename);
  lblOldPath.Caption := ExtractFilePath(Filename);

  ZeroMemory(@Buffer, SizeOf(Buffer));
  F := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if F <> INVALID_HANDLE_VALUE then
  begin
    GetFileTime(F, @CTime, @ATime, @MTime);
    FileTime2DateTime(CTime, BufTime);
    lblOldCreated.Caption := DateTime2StrShort(BufTime);
    FileTime2DateTime(ATime, BufTime);
    lblOldAccessed.Caption := DateTime2StrShort(BufTime);
    FileTime2DateTime(MTime, BufTime);
    lblOldModified.Caption := DateTime2StrShort(BufTime);

    GetFileSizeEx(F, FSize);
    StrFormatByteSize64(FSize, Buffer, SizeOf(Buffer));
    if FSize.Lo > 1024 then lblOldSize.Caption := Buffer + ' (' + Int64_2Str(FSize) + ' bytes)' else lblOldSize.Caption := Buffer;
  end else
  begin
    lblOldCreated.Caption := 'Problem occured while opening file';
    lblOldAccessed.Caption := 'Problem occured while opening file';
    lblOldModified.Caption := 'Problem occured while opening file';
    lblOldSize.Caption := 'Problem occured while opening file';
  end;
  CloseHandle(F);
  btnErase.Enabled := True;
end;

procedure TForm1.editFileDropFiles(Sender: PControl; const FileList: KOL_String; const Pt: TPoint);
begin
  editFile.Caption := FileList;
  FileInformation(editFile.Caption);
end;

procedure TForm1.btnFileClick(Sender: PObj);
begin
  if OpenDialog1.Execute then
  begin
    editFile.Caption := OpenDialog1.Filename;
    FileInformation(editFile.Caption);
  end;
end;

procedure TForm1.GroupBox1DropFiles(Sender: PControl; const FileList: KOL_String; const Pt: TPoint);
begin
  editFile.Caption := FileList;
  FileInformation(editFile.Caption);
end;

procedure TForm1.btnEraseClick(Sender: PObj);
const
  Ext: array[0..3] of String = ('.bak', '.chk', '.log', '.tmp');
  FO_DELETE = $0003;
  FO_MOVE = $0001;
  FOF_NOCONFIRMATION = $0010;
  FOF_SILENT = $0004;
var
  i, Counter, FirstTime: Cardinal;
  Name: array[0..15] of Char;
  FileBuffer, ReadBuffer: array[0..4095] of Char;
  FileName, NewName: String;
  Data: Double;
  Bytes: Cardinal;
  NBytes: DWORD;
  NSize: I64;
  N: THandle;
  Verify1, Verify2: Boolean;
  FileTime: TFileTime;
  SystemDate: TSystemTime;
  BufTime: TDateTime;
begin
  FirstTime := GetTickCount;
  Bytes := 0;
  Randomize;

  FileName := editFile.Text;
  N := CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if N <> INVALID_HANDLE_VALUE then
  begin
    GetFileSizeEx(N, NSize);
    SetFilePointer(N, 0, nil, FILE_BEGIN);
    ZeroMemory(@FileBuffer, SizeOf(FileBuffer));
    Counter := NSize.Lo div 4096;
    if Counter = 0 then Inc(Counter);
    for i:=0 to Counter do
    begin
      WriteFile(N, FileBuffer, 4096, NBytes, nil);
      Bytes := Bytes + NBytes;
      Check(lblOverwrite, True, Int2Str(Bytes) + ' bytes written');
    end;

    ZeroMemory(@FileBuffer, SizeOf(FileBuffer));
    ZeroMemory(@ReadBuffer, SizeOf(ReadBuffer));
    SetFilePointer(N, 0, nil, FILE_BEGIN);
    ReadFile(N, ReadBuffer, 4096, NBytes, nil);
    if lstrcmp(ReadBuffer, FileBuffer) = 0 then Verify1 := True else Verify1 := False;

    ZeroMemory(@ReadBuffer, SizeOf(ReadBuffer));
    SetFilePointer(N, 0, nil, FILE_END);
    ReadFile(N, ReadBuffer, 4096, NBytes, nil);
    if lstrcmp(ReadBuffer, FileBuffer) = 0 then Verify2:= True else Verify2 := False;
    if (Verify1) and (Verify2) then Check(lblVerify, True, 'OK') else Check(lblVerify, False, 'Error');

    Data := 728340 + Random(4000) + Random;
    DateTime2SystemTime(Data, SystemDate);
    SystemTimeToFileTime(SystemDate, FileTime);
    SetFileTime(N, @FileTime, @FileTime, @FileTime);
    FileTime2DateTime(FileTime, BufTime);
    Check(lblDate, True, DateTime2StrShort(BufTime));
  end

  else
  begin
    Check(lblOverwrite, False, 'Error');
    Check(lblDate, False, 'Error');
  end;
  FlushFileBuffers(N);
  CloseHandle(N);

  ZeroMemory(@Name, SizeOf(Name));
  Counter := Random(6) + 5;
  for i:=0 to Counter-1 do Name[i] := Char(Random(25) + 97);
  NewName := Name + Ext[Random(4)];

  if MoveFile(PChar(FileName), PChar(ExtractFilePath(FileName) + NewName)) then
  begin
    Check(lblFilename, True, NewName);
    FileName := PChar(ExtractFilePath(FileName) + NewName);
  end
  else Check(lblFilename, False, 'Error');

  if DeleteFile(PChar(FileName)) then Check(lblDelete, True, 'OK') else Check(lblDelete, False, 'Error');

  editFile.Clear;
  btnErase.Enabled := False;
  lblTime.Caption := Int2Str(GetTickCount - FirstTime) + ' ms';
  if (lblOverwrite.Font.Color = clGreen) and (lblVerify.Font.Color = clGreen) and (lblDate.Font.Color = clGreen) and
     (lblFilename.Font.Color = clGreen) and (lblDelete.Font.Color = clGreen) then
     Check(lblStatus, True, 'All tasks completed successfully')
  else Check(lblStatus, False, 'An error occured while performing tasks');
end;

end.
