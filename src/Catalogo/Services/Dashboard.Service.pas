unit Dashboard.Service;

interface

uses
  System.JSON;

type
  TDashboardService = class
  public
    class function BuscarResumo(
      const AIdEmpresa: Int64
    ): TJSONObject; static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Dashboard.DAO,
  System.SysUtils;

class function TDashboardService.BuscarResumo(const AIdEmpresa: Int64): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TDashboardDAO.BuscarResumo(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

end.
