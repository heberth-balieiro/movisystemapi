unit EleicaoEmailConfigAPI.Service;

interface

uses
  EleicaoEmailConfigAPI.Model;

type
  TEleicaoEmailConfigService = class
  private
    class function EmailValido(const AEmail: string): Boolean; static;
  public
    class function Buscar(const AIdEmpresa: Integer): TEleicaoEmailConfig; static;
    class function Atualizar(const AIdEmpresa: Integer;
      const ADados: TEleicaoEmailInput): TEleicaoEmailConfig; static;
    class function ObterConfiguracaoParaEnvio(const AIdEmpresa: Integer;
      out AConfig: TEleicaoEmailConfig; out ASenha: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Eleicao.Secrets,
  EleicaoEmailConfigAPI.Repository;

class function TEleicaoEmailConfigService.EmailValido(const AEmail: string): Boolean;
var
  Email: string;
  P: Integer;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);
  Result := (P > 1) and (P < Length(Email) - 2) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

class function TEleicaoEmailConfigService.Buscar(
  const AIdEmpresa: Integer): TEleicaoEmailConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoEmailConfigRepository.GarantirSchema(Conn);
    Result := TEleicaoEmailConfigRepository.Buscar(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class function TEleicaoEmailConfigService.Atualizar(const AIdEmpresa: Integer;
  const ADados: TEleicaoEmailInput): TEleicaoEmailConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TEleicaoEmailInput;
  TemSenha: Boolean;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Dados := ADados;
  Dados.SmtpHost := Trim(Dados.SmtpHost);
  Dados.Seguranca := UpperCase(Trim(Dados.Seguranca));
  Dados.Usuario := Trim(Dados.Usuario);
  Dados.Senha := Trim(Dados.Senha);
  Dados.RemetenteNome := Trim(Dados.RemetenteNome);
  Dados.RemetenteEmail := LowerCase(Trim(Dados.RemetenteEmail));
  Dados.ResponderPara := LowerCase(Trim(Dados.ResponderPara));

  if Dados.SmtpPorta <= 0 then
    Dados.SmtpPorta := 587;

  if (Dados.SmtpPorta < 1) or (Dados.SmtpPorta > 65535) then
    TAppErrors.RaiseBadRequest('Porta SMTP inválida.');

  if not SameText(Dados.Seguranca, 'STARTTLS') and
     not SameText(Dados.Seguranca, 'SSL_TLS') and
     not SameText(Dados.Seguranca, 'NONE') then
    TAppErrors.RaiseBadRequest('Tipo de segurança SMTP inválido.');

  if Length(Dados.SmtpHost) > 255 then
    TAppErrors.RaiseBadRequest('Servidor SMTP inválido.');

  if Length(Dados.Usuario) > 254 then
    TAppErrors.RaiseBadRequest('Usuário SMTP inválido.');

  if Length(Dados.Senha) > 4096 then
    TAppErrors.RaiseBadRequest('Senha SMTP inválida.');

  if Length(Dados.RemetenteNome) > 180 then
    TAppErrors.RaiseBadRequest('Nome do remetente excede o tamanho permitido.');

  if (not Dados.RemetenteEmail.IsEmpty) and (not EmailValido(Dados.RemetenteEmail)) then
    TAppErrors.RaiseBadRequest('E-mail do remetente inválido.');

  if (not Dados.ResponderPara.IsEmpty) and (not EmailValido(Dados.ResponderPara)) then
    TAppErrors.RaiseBadRequest('E-mail de resposta inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoEmailConfigRepository.GarantirSchema(Conn);

    TemSenha := not Dados.Senha.IsEmpty;
    if not TemSenha then
      TemSenha := TEleicaoEmailConfigRepository.TemSenha(Conn, AIdEmpresa);

    if Dados.Ativo then
    begin
      if Dados.SmtpHost.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o servidor SMTP antes de ativar o envio.');
      if Dados.Usuario.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o usuário SMTP antes de ativar o envio.');
      if not TemSenha then
        TAppErrors.RaiseBadRequest('Informe a senha SMTP antes de ativar o envio.');
      if Dados.RemetenteNome.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o nome do remetente.');
      if Dados.RemetenteEmail.IsEmpty or not EmailValido(Dados.RemetenteEmail) then
        TAppErrors.RaiseBadRequest('Informe um e-mail válido para o remetente.');
    end;

    Conn.StartTransaction;
    try
      TEleicaoEmailConfigRepository.Salvar(
        Conn,
        AIdEmpresa,
        Dados,
        TEleicaoSecrets.EmailSmtpSecret
      );
      Result := TEleicaoEmailConfigRepository.Buscar(Conn, AIdEmpresa);
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

class function TEleicaoEmailConfigService.ObterConfiguracaoParaEnvio(
  const AIdEmpresa: Integer; out AConfig: TEleicaoEmailConfig;
  out ASenha: string): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := False;
  ASenha := '';
  AConfig := Default(TEleicaoEmailConfig);

  if AIdEmpresa <= 0 then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoEmailConfigRepository.GarantirSchema(Conn);
    AConfig := TEleicaoEmailConfigRepository.Buscar(Conn, AIdEmpresa);

    if not AConfig.Ativo or
       AConfig.SmtpHost.IsEmpty or
       AConfig.Usuario.IsEmpty or
       not AConfig.SenhaConfigurada or
       AConfig.RemetenteEmail.IsEmpty then
      Exit;

    ASenha := TEleicaoEmailConfigRepository.ObterSenha(
      Conn,
      AIdEmpresa,
      TEleicaoSecrets.EmailSmtpSecret
    );

    Result := not ASenha.IsEmpty;
  finally
    Conn.Free;
  end;
end;

end.
