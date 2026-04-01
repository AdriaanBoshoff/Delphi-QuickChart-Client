unit ufrmMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, Web.HTTPApp,
  FMX.TabControl, FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox, FMX.Edit,
  FMX.EditBox, FMX.NumberBox, FMX.Memo.Types, FMX.Layouts, FMX.ScrollBox,
  FMX.Memo, FMX.Objects;

type
  TForm1 = class(TForm)
    tlbHeader: TToolBar;
    tbcMethods: TTabControl;
    tbtmHealthCheck: TTabItem;
    edtHost: TEdit;
    cbbSSL: TComboBox;
    nmbrbxPort: TNumberBox;
    mmoHealthCheck: TMemo;
    lytHealthCheckControls: TLayout;
    btnRunHealthCheck: TButton;
    tbtmChart: TTabItem;
    lytChartControls: TLayout;
    btnGenerateChart: TButton;
    grpChartOutput: TGroupBox;
    imgChartOutput: TImage;
    procedure btnGenerateChartClick(Sender: TObject);
    procedure btnRunHealthCheckClick(Sender: TObject);
  private
    { Private declarations }
    procedure LogHealthCheck(const Text: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  QuickChart;

{$R *.fmx}

procedure TForm1.btnGenerateChartClick(Sender: TObject);
begin
  var qc := TQuickChartAPI.Create;
  try
    case cbbSSL.ItemIndex of
      0: // http
        qc.UseHttps := False;
      1: // https
        qc.UseHttps := True;
    end;

    qc.Host := edtHost.Text;
    qc.Port := Round(nmbrbxPort.Value);

    var chartParams := TQCChartParams.CreateDefaults;
    imgChartOutput.Bitmap := qc.GenerateChart(chartParams, false);
  finally
    qc.Free;
  end;
end;

procedure TForm1.btnRunHealthCheckClick(Sender: TObject);
begin
  LogHealthCheck('Running HealthCheck...');

  var qc := TQuickChartAPI.Create;
  try
    try
      case cbbSSL.ItemIndex of
        0: // http
          qc.UseHttps := False;
        1: // https
          qc.UseHttps := True;
      end;

      qc.Host := edtHost.Text;
      qc.Port := Round(nmbrbxPort.Value);

      var healthResult := qc.HealthCheck;
      LogHealthCheck('Success: ' + BoolToStr(healthResult.Success, True));
      LogHealthCheck('Version: ' + healthResult.Version);
    except
      on E: Exception do
        LogHealthCheck('Health Check Failed: ' + E.Message);
    end;
  finally
    qc.Free;
  end;
end;

procedure TForm1.LogHealthCheck(const Text: string);
begin
  mmoHealthCheck.Lines.Add(Text);
end;

end.

