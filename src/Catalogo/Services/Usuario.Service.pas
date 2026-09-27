unit Usuario.Service;

interface

uses
  System.SysUtils,
  Uni,
  Usuario.Model;

type
  TLoginResult = record
    IdUsuario: Int64;
    IdEmpresa: Int64;
    NomeUsuario: string;
    Email: string;
    Perfil: string;
    EmpresaNome: string;
    Token: string;
    DataValidade: TDate;
  end;

  TUsuarioService = class
  private
    class procedure ValidarUsuario(const AUsuario: TUsuarioModel); static;
  public
    class function CriarUsuario(
      const AConn: TUniConnection;
      const AUsuario: TUsuarioModel;
      const ASenha: string
    ): Int64; static;

    class function Login(
      const AEmail: string;
      const ASenha: string
    ): TLoginResult; static;
  end;

implementation

uses
  APP.Errors,
  Usuario.DAO,
  Auth.Passwords,
  App.Config,
  App.JWT,
  Database.Connection;

class procedure TUsuarioService.ValidarUsuario(const AUsuario: TUsuarioModel);
begin
  if AUsuario = nil then
    TAppErrors.RaiseBadRequest('Dados do usuário não informados.');

  if AUsuario.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa do usuário não informada.');

  if Trim(AUsuario.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do usuário.');

  if Trim(AUsuario.Email).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o email do usuário.');

  if Trim(AUsuario.Perfil).IsEmpty then
    AUsuario.Perfil := 'OPERADOR';

  if Trim(AUsuario.Ativo).IsEmpty then
    AUsuario.Ativo := 'S';
end;

class function TUsuarioService.CriarUsuario(
  const AConn: TUniConnection;
  const AUsuario: TUsuarioModel;
  const ASenha: string
): Int64;
begin
  Result := 0;

  if AConn = nil then
    TAppErrors.RaiseBadRequest('Conexão com banco não informada.');

  ValidarUsuario(AUsuario);

  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha do usuário.');

  if Length(Trim(ASenha)) < 6 then
    TAppErrors.RaiseBadRequest('A senha deve possuir no mínimo 6 caracteres.');

  if TUsuarioDAO.ExisteEmail(AConn, AUsuario.Email) then
    TAppErrors.RaiseBadRequest('Email já cadastrado para outro usuário.');

  AUsuario.Email := LowerCase(Trim(AUsuario.Email));
  AUsuario.Perfil := UpperCase(Trim(AUsuario.Perfil));
  AUsuario.Ativo := UpperCase(Trim(AUsuario.Ativo));
  AUsuario.SenhaHash := HashSenha(ASenha);

  Result := TUsuarioDAO.Inserir(AConn, AUsuario);
end;

class function TUsuarioService.Login(const AEmail: string;const ASenha: string): TLoginResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  UsuarioLogin: TUsuarioLoginDTO;
  Roles: TArray<string>;
begin
  Result.IdUsuario := 0;
  Result.IdEmpresa := 0;
  Result.NomeUsuario := '';
  Result.Email := '';
  Result.Perfil := '';
  Result.EmpresaNome := '';
  Result.Token := '';
  Result.DataValidade := 0;

  if Trim(AEmail).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o email.');

  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TUsuarioDAO.BuscarLoginPorEmail(Conn, AEmail, UsuarioLogin) then
      TAppErrors.RaiseUnauthorized('Email ou senha inválidos.');

    if not VerifySenha(ASenha, UsuarioLogin.SenhaHash) then
      TAppErrors.RaiseUnauthorized('Email ou senha inválidos.');

    if UpperCase(Trim(UsuarioLogin.UsuarioAtivo)) <> 'S' then
      TAppErrors.RaiseForbidden('Usuário bloqueado.');

    if UpperCase(Trim(UsuarioLogin.EmpresaAtivo)) <> 'S' then
      TAppErrors.RaiseForbidden('Empresa bloqueada.');

    if UsuarioLogin.Perfil<>'ADMIN' then
    begin
      if UsuarioLogin.LicencaSituacao='TRIAL' then
      begin
        if UsuarioLogin.Licencatrialtermina < Date then
          TAppErrors.RaiseForbidden('O seu período de teste acabou.');
      end;

      if UsuarioLogin.LicencaSituacao <> 'TRIAL' then
      begin
      if UsuarioLogin.EmpresaDataValidade < Date then
        TAppErrors.RaiseForbidden('Empresa com mensalidade vencida.');
      end;
    end;

    SetLength(Roles, 1);
    Roles[0] := UpperCase(Trim(UsuarioLogin.Perfil));

    Result.IdUsuario      := UsuarioLogin.IdUsuario;
    Result.IdEmpresa      := UsuarioLogin.IdEmpresa;
    Result.NomeUsuario    := UsuarioLogin.NomeUsuario;
    Result.Email          := UsuarioLogin.Email;
    Result.Perfil         := UpperCase(Trim(UsuarioLogin.Perfil));
    Result.EmpresaNome    := UsuarioLogin.EmpresaNome;
    Result.DataValidade   := UsuarioLogin.EmpresaDataValidade;
    Result.Token          := TAppJWT.GerarToken(Config.JWT, UsuarioLogin.IdUsuario, UsuarioLogin.IdEmpresa, Roles);
  finally
    Conn.Free;
  end;
end;

end.
