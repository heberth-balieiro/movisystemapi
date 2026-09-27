unit Database.Connection;

interface

uses
  Uni,
  App.Config;

type
  TDatabaseConnection = class
  public
    class function NewConnection(const ACfg: TAppDatabaseConfig): TUniConnection; static;
  end;

implementation

uses
  System.SysUtils,
  MySQLUniProvider;

class function TDatabaseConnection.NewConnection(const ACfg: TAppDatabaseConfig): TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  try
    Result.ProviderName := ACfg.Driver;
    Result.Server       := ACfg.Server;
    Result.Port         := ACfg.Port;
    Result.Database     := ACfg.Database;
    Result.Username     := ACfg.Username;
    Result.Password     := ACfg.Password;
    Result.LoginPrompt  := False;

    Result.SpecificOptions.Values['UseUnicode'] := 'True';
    Result.SpecificOptions.Values['Charset'] := 'utf8mb4';

    Result.Connect;
  except
    Result.Free;
    raise;
  end;
end;

end.
