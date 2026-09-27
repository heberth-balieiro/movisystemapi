unit InstituicaoDashboard.Service;

interface

uses
  InstituicaoDashboard.DAO;

type
  TInstituicaoDashboardService = class
  public
    class function Buscar(
      const AIdInstituicao: Int64
    ): TInstituicaoDashboardDados; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection;

class function TInstituicaoDashboardService.Buscar(
  const AIdInstituicao: Int64
): TInstituicaoDashboardDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    Result :=
      TInstituicaoDashboardDAO.Buscar(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

end.
