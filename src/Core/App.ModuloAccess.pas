unit App.ModuloAccess;

interface

type
  TAppModuloAccess = class
  public
    class function ResolverModuloRota(
      const ACaminho: string
    ): string; static;

    class function RotaDispensadaDaValidacao(
      const ACaminho: string
    ): Boolean; static;

    class function InstituicaoPossuiModulo(
      const AIdInstituicao: Int64;
      const ACodigoModulo: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

class function TAppModuloAccess.ResolverModuloRota(
  const ACaminho: string
): string;
var
  Caminho: string;
begin
  Result := '';
  Caminho := LowerCase(Trim(ACaminho));

  if Pos('/v1/certifica/', Caminho) = 1 then
    Result := 'CERTIFICA'
  else if Pos('/v1/rh/', Caminho) = 1 then
    Result := 'RH'
  else if Pos('/v1/contratos/', Caminho) = 1 then
    Result := 'CONTRATOS'
  else if Pos('/v1/participa/', Caminho) = 1 then
    Result := 'PARTICIPA';
end;

class function TAppModuloAccess.RotaDispensadaDaValidacao(
  const ACaminho: string
): Boolean;
var
  Caminho: string;
begin
  Caminho := LowerCase(Trim(ACaminho));

  Result :=
    SameText(
      Caminho,
      '/v1/certifica/instituicao/auth/contexto'
    );
end;

class function TAppModuloAccess.InstituicaoPossuiModulo(
  const AIdInstituicao: Int64;
  const ACodigoModulo: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     Trim(ACodigoModulo).IsEmpty then
    Exit;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT 1 ' +
        'FROM instituicao_modulo im ' +
        'JOIN plataforma_modulo m ON m.id = im.id_modulo ' +
        'WHERE im.id_instituicao = :id_instituicao ' +
        'AND im.ativo = 1 ' +
        'AND m.situacao = ''ATIVO'' ' +
        'AND m.codigo = :codigo ' +
        'LIMIT 1';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('codigo').AsString :=
        UpperCase(
          Trim(
            ACodigoModulo
          )
        );

      Qry.Open;

      Result :=
        not Qry.IsEmpty;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
