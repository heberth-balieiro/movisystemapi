unit ContratoDashboard.Service;

interface

uses
  ContratoDashboard.DAO;

type
  TContratoDashboardService = class
  public
    class function Buscar(
      const AIdInstituicao, AIdUsuario: Int64
    ): TContratoDashboardDados; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  InstituicaoPermissao.Service;

class function TContratoDashboardService.Buscar(
  const AIdInstituicao, AIdUsuario: Int64
): TContratoDashboardDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuario,
    'contrato.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TContratoDashboardDAO.Buscar(Conn,AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

end.
