unit EleicaoListaPublicaAPI.Service;

interface

uses
  System.JSON;

type
  TEleicaoListaPublicaAPIService = class
  public
    class function ListarProcessosPublicos: TJSONArray; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  EleicaoListaPublicaAPI.Dao;

class function TEleicaoListaPublicaAPIService.ListarProcessosPublicos: TJSONArray;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TEleicaoListaPublicaAPIDao.ListarProcessosPublicos(Conn);
  finally
    Conn.Free;
  end;
end;

end.
