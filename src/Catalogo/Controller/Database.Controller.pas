unit Database.Controller;

interface

type
  TDatabaseController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  Uni,
  App.Config,
  App.Response,
  APP.Errors,
  Database.Connection;

class procedure TDatabaseController.Registry;
begin
  THorse.Get('/v1/db/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LConfig: TAppApiConfig;
      LConn: TUniConnection;
      LQry: TUniQuery;
      LJson: TJSONObject;
    begin
      try
        LConfig := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        LConn := TDatabaseConnection.NewConnection(LConfig.Database);
        try
          LQry := TUniQuery.Create(nil);
          try
            LQry.Connection := LConn;
            LQry.SQL.Text := 'SELECT 1 AS conectado';
            LQry.Open;

            LJson := TJSONObject.Create;
            LJson.AddPair('database', LConfig.Database.Database);
            LJson.AddPair('server', LConfig.Database.Server);
            LJson.AddPair('status', 'conectado');
            LJson.AddPair('teste', TJSONNumber.Create(LQry.FieldByName('conectado').AsInteger));

            TAppResponse.Ok(Res, LJson, 'Banco conectado com sucesso.');
          finally
            LQry.Free;
          end;
        finally
          LConn.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
