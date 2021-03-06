{ $Id: frm_Main.pas,v 1.1 2011/08/25 10:04:33 plpolak Exp $ }

unit frm_Main;

interface

uses
  SysUtils, Types, Classes, Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdModBusClient, FMX.Edit, UITypes;

type
  TfrmMain = class(TForm)
    mctPLC: TIdModBusClient;
    Label1: TLabel;
    edtIPAddress: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    edtReadReg: TEdit;
    edtReadAmount: TEdit;
    btnRead: TButton;
    Label4: TLabel;
    Label5: TLabel;
    edtWriteReg: TEdit;
    edtValue: TEdit;
    btnWrite: TButton;
    procedure btnReadClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

procedure TfrmMain.btnReadClick(Sender: TObject);
var
  Data: array[0..4096] of Word;
  iAmount: Integer;
  i: Integer;
  sLine: String;
begin
  iAmount := StrToInt(edtReadAmount.Text);
  if (iAmount > 0) then
  begin
    mctPLC.Host := edtIPAddress.Text;
    if mctPLC.ReadHoldingRegisters(StrToInt(edtReadReg.Text), iAmount, Data) then
    begin
      sLine := 'Register value(s) read:';
      for i := 0 to (iAmount - 1) do
        sLine := sLine +
                 #13#10'     ' +
                 IntToStr(StrToInt(edtReadReg.Text) + i) +
                 ': 0x'  +
                 IntToHex(Data[i], 4);
      ShowMessage(sLine);
    end
    else
      ShowMessage('PLC read operation failed!');
  end;
end;


procedure TfrmMain.btnWriteClick(Sender: TObject);
begin
  mctPLC.Host := edtIPAddress.Text;
  if mctPLC.WriteRegister(StrToInt(edtWriteReg.Text), StrToInt(edtValue.Text)) then
    ShowMessage('PLC register write successful!')
  else
    ShowMessage('PLC register write failed!');
end;


end.

