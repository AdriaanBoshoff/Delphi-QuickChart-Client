# Delphi-QuickChart-Client
Delphi Library to access the [QuickChart.io](https://quickchart.io/) API. Self hosted or `https://quickchart.io/`

## Provided Methods
```pascal
function HealthCheck: TQCHealthCheck;
function GenerateChart(const Params: TQCChartParams; const SendConfigAsString: Boolean = False): TBitmap;
```

## Health Check Example:
```pascal
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

      // To use the quickchart.io public API configure as follows:
      // qc.UseHttps := True;
      // qc.Host := 'quickchart.io';
      // qc.Port := 443;

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
```

## Chart Generate Example:

`TQCChartParams.CreateDefaults` Returns a default record with default values from quickchart.io's examples. This means you can run it out of the box without having to configure anything to test with.

```pascal
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

    // To use the quickchart.io public API configure as follows:
    // qc.UseHttps := True;
    // qc.Host := 'quickchart.io';
    // qc.Port := 443;
    // chartParams.Key := '<YOUR API KEY HERE IF NEEDED>';

    // Loads default params and config from quickchart.
    // Modify as needed Example: "chartParams.Format := 'svg';"
    var chartParams := TQCChartParams.CreateDefaults;
    imgChartOutput.Bitmap := qc.GenerateChart(chartParams, false);
  finally
    qc.Free;
  end;
end;
```

### TQCChartParams
```pascal
// https://quickchart.io/documentation/usage/post-endpoint/
type
  TQCChartParams = record
  public
    Width: Integer;
    Height: Integer;
    DevicePixelRatio: Double;
    Format: string;
    BackgroundColor: string;
    Version: string;
    Key: string;
    ChartConfig: string; // This is the Chart.js config that needs to be passed.
    class function CreateDefaults: TQCChartParams; static;
  end;
  ```