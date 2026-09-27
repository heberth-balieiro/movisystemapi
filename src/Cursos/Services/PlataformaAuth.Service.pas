unit PlataformaAuth.Service;

interface
type
  // Resultado já no formato necessário para o controller montar a sessão do frontend.
  TPlataformaLoginResult = record
    IdUsuario: Int64;
    Nome: string;
    Email: string;
    Token: string;
  end;
  TPlataformaAuthService = class
  public
    class function Login(const AEmail, ASenha, AIP, AUserAgent: string): TPlataformaLoginResult; static;
  end;
implementation
uses
  System.SysUtils,
  Uni,
  App.Config,
  App.JWT,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  PlataformaAuth.DAO;
class function TPlataformaAuthService.Login(const AEmail, ASenha, AIP,
  AUserAgent: string): TPlataformaLoginResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Usuario: TPlataformaAuthUsuario;
  Roles: TArray<string>;
begin
  Result := Default(TPlataformaLoginResult);
  if Trim(AEmail).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o e-mail.');
  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TPlataformaAuthDAO.BuscarSuperAdminPorEmail(Conn, AEmail, Usuario) then
    begin
      TPlataformaAuthDAO.RegistrarAuditoriaLogin(Conn, 0, False, 'Usuário ou senha inválidos.', AIP, AUserAgent);
      TAppErrors.RaiseUnauthorized('Usuário ou senha inválidos.');
    end;
    if not VerifySenha(ASenha, Usuario.SenhaHash) then
    begin
      TPlataformaAuthDAO.RegistrarAuditoriaLogin(Conn, Usuario.IdUsuario, False, 'Usuário ou senha inválidos.', AIP, AUserAgent);
      TAppErrors.RaiseUnauthorized('Usuário ou senha inválidos.');
    end;
    if not SameText(Trim(Usuario.Situacao), 'ATIVO') then
    begin
      TPlataformaAuthDAO.RegistrarAuditoriaLogin(Conn, Usuario.IdUsuario, False, 'Usuário bloqueado.', AIP, AUserAgent);
      TAppErrors.RaiseForbidden('Usuário bloqueado.');
    end;
    if not Usuario.IsSuperAdmin then
      TAppErrors.RaiseForbidden('Usuário sem permissão para administrar a plataforma.');
    SetLength(Roles, 1);
    Roles[0]          := 'SUPER_ADMIN';
    Result.IdUsuario := Usuario.IdUsuario;
    Result.Nome      := Usuario.Nome;
    Result.Email     := Usuario.Email;
    Result.Token     := TAppJWT.GerarTokenGlobal(Config.JWT, Usuario.IdUsuario, Roles, Config.JWT.TtlAdminMinutos);
    // Último acesso e auditoria são persistidos juntos após a autenticação ser validada.
    Conn.StartTransaction;
    try
      TPlataformaAuthDAO.AtualizarUltimoLogin(Conn, Usuario.IdUsuario);
      TPlataformaAuthDAO.RegistrarAuditoriaLogin(Conn, Usuario.IdUsuario, True, 'Login realizado com sucesso.', AIP, AUserAgent);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;
end.

