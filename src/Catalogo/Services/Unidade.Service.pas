unit Unidade.Service;

interface

uses
  System.Generics.Collections,
  Unidade.Model;

type
  TUnidadeService = class
  public
    class function ListarUnidades: TObjectList<TUnidadeModel>; static;
  end;

implementation

uses
  Uni,
  System.SysUtils,
  App.Config,
  Database.Connection,
  Unidade.DAO;

class function TUnidadeService.ListarUnidades: TObjectList<TUnidadeModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TUnidadeDAO.ListarAtivas(Conn);
  finally
    Conn.Free;
  end;
end;

end.
