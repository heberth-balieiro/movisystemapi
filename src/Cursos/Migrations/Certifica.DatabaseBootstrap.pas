unit Certifica.DatabaseBootstrap;

interface

uses
  System.SysUtils, System.Character, Data.DB, DBAccess, Uni, MySQLUniProvider;

type
  TCursosDatabaseBootstrap = class
  private
    class function IsValidDatabaseName(const AName: string): Boolean; static;
  public
    class procedure EnsureDatabase(AConn: TUniConnection; const ADatabase: string); static;
  end;

implementation

class function TCursosDatabaseBootstrap.IsValidDatabaseName(const AName: string): Boolean;
var
  C: Char;
begin
  Result := AName <> '';
  if not Result then Exit;

  for C in AName do
    if not (C.IsLetterOrDigit or (C = '_')) then
      Exit(False);
end;

class procedure TCursosDatabaseBootstrap.EnsureDatabase(AConn: TUniConnection; const ADatabase: string);
var
  Qry: TUniQuery;
begin
  if not IsValidDatabaseName(ADatabase) then
    raise Exception.Create('Nome do banco de dados inválido.');

  // Para criar o database precisamos primeiro conectar somente no servidor MySQL.
  if AConn.Connected then
    AConn.Disconnect;

  AConn.Database := '';
  AConn.Connect;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // O nome do banco não pode ser parâmetro SQL, por isso ele é validado acima.
    Qry.SQL.Text :=
      Format(
        'CREATE DATABASE IF NOT EXISTS `%s` ' +
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci',
        [ADatabase]
      );

    Qry.ExecSQL;
  finally
    Qry.Free;
    AConn.Disconnect;
  end;

  // Após garantir a existência do banco, conecta normalmente nele.
  AConn.Database := ADatabase;
  AConn.Connect;
end;

end.
