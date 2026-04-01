unit QuickChart;

interface

uses
  Rest.Client, Rest.Types, System.SysUtils;

type
  TQCHleathCheck = record
  public
    Success: Boolean;
    Version: string;
    class function CreateDefaults: TQCHleathCheck; static;
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
  end;

implementation

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

end.

