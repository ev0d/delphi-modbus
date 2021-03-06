{===============================================================================

The contents of this file are subject to the Mozilla Public License Version 1.1
(the "License"); you may not use this file except in compliance with the
License. You may obtain a copy of the License at http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above. If you wish to
allow use of your version of this file only under the terms of the GPL and not
to allow others to use your version of this file under the MPL, indicate your
decision by deleting the provisions above and replace them with the notice and
other provisions required by the GPL. If you do not delete the provisions
above, a recipient may use your version of this file under either the MPL or
the GPL.

$Id: frm_Main.pas,v 1.6 2010/09/14 10:02:50 plpolak Exp $

===============================================================================}

unit frm_Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  IdBaseComponent, IdComponent, IdModBusServer, Grids, ExtCtrls,
  StdCtrls, Buttons, IdContext, IdCustomTCPServer, ModbusTypes;

type
  TfrmMain = class(TForm)
    pnlInput: TPanel;
    btnStart: TBitBtn;
    Label1: TLabel;
    edtFirstReg: TEdit;
    edtLastReg: TEdit;
    Label2: TLabel;
    pnlMain: TPanel;
    sgdRegisters: TStringGrid;
    mmoErrorLog: TMemo;
    Splitter1: TSplitter;
    msrPLC: TIdModBusServer;
    procedure msrPLCReadHoldingRegisters(const Sender: TIdContext; const RegNr,
      Count: Integer; var Data: TModRegisterData; const RequestBuffer: TModBusRequestBuffer);
    procedure msrPLCWriteRegisters(const Sender: TIdContext;
      const RegNr, Count: Integer; const Data: TModRegisterData;
      const RequestBuffer: TModBusRequestBuffer);
    procedure btnStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sgdRegistersSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: String);
  private
    FFirstReg: Integer;
    FLastReg: Integer;
    FRegisterValues: array of Integer;
    procedure ClearRegisters;
    procedure FillRegisters;
    procedure Convert(const Index: Integer);
    procedure SetRegisterValue(const RegNo: Integer; const Value: Word);
    function GetRegisterValue(const RegNo: Integer): Word;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

function IntToBinary(const Value: Int64; const ALength: Integer): String;
var
  iWork: Int64;
begin
  Result := '';
  iWork := Value;
  while (iWork > 0) do
  begin
    Result := IntToStr(iWork mod 2) + Result;
    iWork := iWork div 2;
  end;
  while (Length(Result) < ALength) do
    Result := '0' + Result;
end;


procedure TfrmMain.msrPLCReadHoldingRegisters(const Sender: TIdContext;
  const RegNr, Count: Integer; var Data: TModRegisterData;
  const RequestBuffer: TModBusRequestBuffer);
var
  i: Integer;
begin
  for i := 0 to (Count - 1) do
    Data[i] := GetRegisterValue(RegNr + i);
end;


procedure TfrmMain.msrPLCWriteRegisters(const Sender: TIdContext;
  const RegNr, Count: Integer; const Data: TModRegisterData;
  const RequestBuffer: TModBusRequestBuffer);
var
  i: Integer;
begin
  for i := 0 to (Count - 1) do
    SetRegisterValue(RegNr + i, Data[i]);
end;


procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if msrPLC.Active then
  begin
    msrPLC.Active := False;
    edtFirstReg.Enabled := True;
    edtLastReg.Enabled := True;
    btnStart.Caption := '&Start';
    ClearRegisters;
  end
  else
  begin
    FFirstReg := StrToInt(edtFirstReg.Text);
    FLastReg := StrToInt(edtLastReg.Text);
    msrPLC.MinRegister := FFirstReg;
    msrPLC.MaxRegister := FLastReg;
    btnStart.Caption := '&Stop';
    msrPLC.Active := True;
    FillRegisters; 
  end;
end;


procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FFirstReg := 0;
  FLastReg := 0;
{ Set grid headers titles }
  sgdRegisters.Cells[0, 0] := 'RegNo';
  sgdRegisters.Cells[1, 0] := 'Decimal';
  sgdRegisters.Cells[2, 0] := 'Hex.';
  sgdRegisters.Cells[3, 0] := 'Binary';
{ Set the column width }
  sgdRegisters.ColWidths[3] := 120;
end;


procedure TfrmMain.ClearRegisters;
var
  i: Integer;
begin
  sgdRegisters.RowCount := 2;
  for i := 0 to (sgdRegisters.ColCount - 1) do
    sgdRegisters.Cells[i, 1] := '';
end;


procedure TfrmMain.FillRegisters;
var
  i: Integer;
begin
  ClearRegisters;
  if (FLastReg >= FFirstReg) then
  begin
    sgdRegisters.RowCount := (FLastReg - FFirstReg) + 2;
    for i := FFirstReg to FLastReg do
    begin
      sgdRegisters.Cells[0, i - FFirstReg + 1] := IntToStr(i);
      SetRegisterValue(i, Random(2000) + 3000);
    end;
  end;
end;


procedure TfrmMain.Convert(const Index: Integer);
begin
  sgdRegisters.Cells[2, Index + 1] := IntToHex(FRegisterValues[Index], 4);
  sgdRegisters.Cells[3, Index + 1] := IntToBinary(FRegisterValues[Index], 16);
end;


procedure TfrmMain.SetRegisterValue(const RegNo: Integer; const Value: Word);
var
 Index: Integer;
begin
  if (RegNo >= FFirstReg) and (RegNo <= FLastReg) then
  begin
    Index := RegNo - FFirstReg;
    if (Index >= Length(FRegisterValues)) then
      SetLength(FRegisterValues, (Index + 1) * 2);
    FRegisterValues[Index] := Value;
    sgdRegisters.Cells[1, Index + 1] := IntToStr(Value);
    Convert(Index);
  end;
end;


function TfrmMain.GetRegisterValue(const RegNo: Integer): Word;

 function WordRange(const i: Integer):Word;
 begin
   if (i < 0) and (i >= -32767) then
     Result := Word(i)
   else if (i <= MAXWORD) then
     Result := Word(i)
   else
     Result := MAXWORD;
 end;
 
var
  Index: Integer;
begin
  if (RegNo >= FFirstReg) and (RegNo <= FLastReg) then
  begin
    Index := RegNo - FFirstReg;
    Assert(Index >= 0);
    Assert(Index < Length(FRegisterValues));
    if (Index >= 0) and (Index < Length(FRegisterValues)) then
      Result := WordRange(FRegisterValues[Index])
    else
      Result := 0;
  end
  else
    Result := 0;
end;


procedure TfrmMain.FormShow(Sender: TObject);
begin
  btnStartClick(Sender);
end;


procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  msrPLC.Pause := True;
  if msrPLC.Active then
    btnStartClick(Sender);
end;


procedure TfrmMain.sgdRegistersSetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: String);
var
  Index: Integer;
begin
  if (ACol = 1) then
  begin
    Index := ARow - 1;
    FRegisterValues[Index] := StrToIntDef(Value, 0);
    Convert(Index);
  end;
end;


end.
