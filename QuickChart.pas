unit QuickChart;

interface

uses
{$IFDEF FrameWork_VCL}
  VCL.Graphics,
{$ELSE} // FMX and none framework apps such as console
FMX.Graphics,
{$ENDIF}
Rest.Client, Rest.Types, System.SysUtils, System.Classes;

type
  TQCHleathCheck = record
  public
    Success: Boolean;
    Version: string;
    class function CreateDefaults: TQCHleathCheck; static;
  end;

type
  TQCChartParams = record // https://quickchart.io/documentation/usage/post-endpoint/
  public
    Width: Integer;
    Height: Integer;
    DevicePixelRatio: Double;
    Format: string;
    BackgroundColor: string;
    Version: string;
    Key: string;
    ChartConfig: string;
    class function CreateDefaults: TQCChartParams; static;
  end;

type
  TQuickChartAPI = class
  private
    { Private Variables }

    // Connection
    FUseHttps: Boolean;
    FHost: string;
    FPort: Integer;
    FTimeoutMS: Integer;
  private
    { Private Methods }

    function CreateRestRequest(const Resource: string): TRESTRequest;

  public
    { Public Properties }

    // Connection
    property UseHttps: boolean read FUseHttps write FUseHttps;
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property TimeoutMS: Integer read FTimeoutMS write FTimeoutMS;

  public
    { Public Methods }

    // Construtor
    constructor Create;

    // API Methods
    function HealthCheck: TQCHleathCheck;
    function GenerateChart(const Params: TQCChartParams; const SendConfigAsString: Boolean = False): TBitmap;
  end;

implementation

uses
  System.JSON;

{ TQuickChart }

constructor TQuickChartAPI.Create;
begin
  inherited;

  // Defaults
  Self.FUseHttps := False;
  Self.FHost := '127.0.0.1';
  Self.FPort := 3400;
end;

function TQuickChartAPI.CreateRestRequest(const Resource: string): TRESTRequest;
begin
  Result := TRESTRequest.Create(nil);
  Result.Client := TRESTClient.Create(Result);
  Result.Response := TRESTResponse.Create(Result);
  Result.Client.RaiseExceptionOn500 := True;
  Result.Timeout := FTimeoutMS;

  // Build Base URL
  var baseURL := '';
  if Self.FUseHttps then
    baseURL := 'https://'
  else
    baseURL := 'http://';
  baseURL := baseURL + FHost + ':' + FPort.ToString;
  Result.Client.BaseURL := baseURL;

  // Resource
  Result.Resource := Resource;
end;

function TQuickChartAPI.GenerateChart(const Params: TQCChartParams; const SendConfigAsString: Boolean): TBitmap;
begin
  var rest := Self.CreateRestRequest('/chart');  // Fix #1: correct endpoint
  try
    rest.Method := TRESTRequestMethod.rmPOST;

    // Build JSON params
    var jData := TJSONObject.Create;
    try
      jData.AddPair('width', TJSONNumber.Create(Params.Width));
      jData.AddPair('height', TJSONNumber.Create(Params.Height));
      jData.AddPair('devicePixelRatio', TJSONNumber.Create(Params.DevicePixelRatio));
      jData.AddPair('format', Params.Format);
      jData.AddPair('backgroundColor', Params.BackgroundColor);
      jData.AddPair('version', Params.Version);

      if not Params.Key.Trim.IsEmpty then
        jData.AddPair('key', Params.Key);

      if SendConfigAsString then
        jData.AddPair('chart', Params.ChartConfig)
      else
      begin
        var jChartConfig := TJSONObject.ParseJSONValue(Params.ChartConfig);
        if Assigned(jChartConfig) then
          jData.AddPair('chart', jChartConfig)
        else
          raise Exception.Create('[TQuickChartAPI.GenerateChart] Chart config is not valid JSON!');
      end;

      // Fix #2: add body as a JSON string with explicit content type
      rest.AddBody(jData.ToJSON, TRESTContentType.ctAPPLICATION_JSON);
    finally
      jData.Free;
    end;

    rest.Execute;

    if rest.Response.StatusCode <> 200 then
      raise Exception.Create('[TQuickChartAPI.GenerateChart] Status Code: ' + rest.Response.StatusCode.ToString + sLineBreak + 'Content: ' + rest.Response.Content);

    // Fix #3: use TBytesStream and reset position before loading
    Result := TBitmap.Create;
    try
      var memStream := TBytesStream.Create(rest.Response.RawBytes);
      try
        memStream.Position := 0;
        Result.LoadFromStream(memStream);
      finally
        memStream.Free;
      end;
    except
      on E: Exception do
      begin
        FreeAndNil(Result);
        raise Exception.Create('[TQuickChartAPI.GenerateChart] EXCEPTION: ' + E.Message);
      end;
    end;

  finally
    rest.Free;
  end;
end;

function TQuickChartAPI.HealthCheck: TQCHleathCheck;
begin
  var rest := Self.CreateRestRequest('/healthcheck');
  try
    rest.Method := TRESTRequestMethod.rmGET;

    rest.Execute;

    // If not 200
    if rest.Response.StatusCode <> 200 then
      raise Exception.Create('[TQuickChart.HealthCheck] Status Code: ' + rest.Response.StatusCode.ToString + sLineBreak + 'Content: ' + rest.Response.Content);

    Result.Success := rest.Response.JSONValue.GetValue<Boolean>('success');
    Result.Version := rest.Response.JSONValue.GetValue<string>('version');
  finally
    rest.Free;
  end;
end;

{ TQCHleathCheck }

class function TQCHleathCheck.CreateDefaults: TQCHleathCheck;
begin
  Result.Success := False;
  Result.Version := '';
end;

{ TQCChartParams }

class function TQCChartParams.CreateDefaults: TQCChartParams;
begin
  Result.Width := 500;
  Result.Height := 300;
  Result.DevicePixelRatio := 2.0;
  Result.Format := 'png';
  Result.BackgroundColor := 'transparent';
  Result.Version := '2';
  Result.Key := '';
  Result.ChartConfig :=  '{' +
      '"type": "bar",' +
      '"data": {' +
        '"labels": ["Q1", "Q2", "Q3", "Q4"],' +
        '"datasets": [{' +
          '"label": "Users",' +
          '"data": [50, 60, 70, 180]' +
        '}]' +
      '},' +
      '"options": {' +
        '"title": {' +
          '"display": true,' +
          '"text": "Basic chart title"' +
        '}' +
      '}' +
    '}';
end;

end.

