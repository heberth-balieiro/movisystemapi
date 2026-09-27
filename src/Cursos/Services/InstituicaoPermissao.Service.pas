unit InstituicaoPermissao.Service;

interface

type
  TInstituicaoPermissaoService = class
  public
    class function TemPermissao(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const APermissao: string
    ): Boolean; static;

    class procedure Exigir(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const APermissao: string
    ); static;

    class function ListarDoUsuario(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.DAO;

class function TInstituicaoPermissaoService.TemPermissao(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const APermissao: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) or
     Trim(APermissao).IsEmpty then
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
    Result :=
      TInstituicaoPermissaoDAO.UsuarioTemPermissao(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao,
        APermissao
      );
  finally
    Conn.Free;
  end;
end;

class procedure TInstituicaoPermissaoService.Exigir(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const APermissao: string
);
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if Trim(APermissao).IsEmpty then
    TAppErrors.RaiseForbidden(
      'Permissão não informada.'
    );

  if not TemPermissao(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    APermissao
  ) then
    TAppErrors.RaiseForbidden(
      'Usuário sem permissão para executar esta operação.'
    );
end;

class function TInstituicaoPermissaoService.ListarDoUsuario(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TArray<string>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  SetLength(Result, 0);

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

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
    Result :=
      TInstituicaoPermissaoDAO.ListarPermissoesUsuario(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );
  finally
    Conn.Free;
  end;
end;

end.
