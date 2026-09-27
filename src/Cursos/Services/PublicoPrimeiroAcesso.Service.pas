unit PublicoPrimeiroAcesso.Service;

interface

uses
  PublicoPrimeiroAcesso.DAO;

type
  TPublicoPrimeiroAcessoService = class
  private
    class procedure ValidarTokenEntrada(
      const ASlug,
            AToken: string
    ); static;

  public
    class function Validar(
      const ASlug,
            AToken: string
    ): TPrimeiroAcessoDados; static;

    class function DefinirSenha(
      const ASlug,
            AToken,
            ASenha: string
    ): TPrimeiroAcessoDados; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection;

class procedure TPublicoPrimeiroAcessoService.ValidarTokenEntrada(
  const ASlug,
        AToken: string
);
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Instituição não informada.'
    );

  if Length(Trim(AToken)) < 32 then
    TAppErrors.RaiseBadRequest(
      'Link de primeiro acesso inválido.'
    );
end;

class function TPublicoPrimeiroAcessoService.Validar(
  const ASlug,
        AToken: string
): TPrimeiroAcessoDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTokenEntrada(
    ASlug,
    AToken
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
      TPublicoPrimeiroAcessoDAO.Buscar(
        Conn,
        ASlug,
        AToken
      );

    if not Result.Valido then
      TAppErrors.RaiseBadRequest(
        'Este link de primeiro acesso é inválido, expirou ou já foi utilizado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TPublicoPrimeiroAcessoService.DefinirSenha(
  const ASlug,
        AToken,
        ASenha: string
): TPrimeiroAcessoDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTokenEntrada(
    ASlug,
    AToken
  );

  if Length(ASenha) < 8 then
    TAppErrors.RaiseBadRequest(
      'A senha deve possuir pelo menos 8 caracteres.'
    );

  if Length(ASenha) > 120 then
    TAppErrors.RaiseBadRequest(
      'A senha excede o tamanho permitido.'
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
    Conn.StartTransaction;
    try
      Result :=
        TPublicoPrimeiroAcessoDAO.Buscar(
          Conn,
          ASlug,
          AToken
        );

      if not Result.Valido then
        TAppErrors.RaiseBadRequest(
          'Este link de primeiro acesso é inválido, expirou ou já foi utilizado.'
        );

      TPublicoPrimeiroAcessoDAO.DefinirSenha(
        Conn,
        Result.IdToken,
        Result.IdUsuario,
        HashSenha(ASenha)
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
