unit PlataformaEmail.Service;

interface

uses
  PlataformaEmail.Model;

type
  TPlataformaEmailService = class
  private
    class function EmailValido(
      const AEmail: string
    ): Boolean; static;

  public
    class function Buscar: TPlataformaEmailConfig; static;

    class function Atualizar(
      const AIdUsuario: Int64;
      const ADados: TPlataformaEmailInput;
      const AIP,
            AUserAgent: string
    ): TPlataformaEmailConfig; static;

    class function ObterConfiguracao(
      out AConfig: TPlataformaEmailConfig;
      out ASenha: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Certifica.Secrets,
  PlataformaEmail.DAO;

class function TPlataformaEmailService.EmailValido(
  const AEmail: string
): Boolean;
var
  Email: string;
  PosArroba: Integer;
begin
  Email := Trim(AEmail);
  PosArroba := Pos('@', Email);

  Result :=
    (PosArroba > 1) and
    (PosArroba < Length(Email) - 2) and
    (Pos('.', Copy(Email, PosArroba + 2, MaxInt)) > 0);
end;

class function TPlataformaEmailService.Buscar:
  TPlataformaEmailConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaEmailDAO.Buscar(Conn);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaEmailService.Atualizar(
  const AIdUsuario: Int64;
  const ADados: TPlataformaEmailInput;
  const AIP,
        AUserAgent: string
): TPlataformaEmailConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TPlataformaEmailInput;
  TemSenha: Boolean;
begin
  Result := Default(TPlataformaEmailConfig);

  if AIdUsuario <= 0 then
    TAppErrors.RaiseForbidden(
      'Usuário responsável pela operação não identificado.'
    );

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

  if (Dados.RemetenteEmail <> '') and not EmailValido(Dados.RemetenteEmail) then
    TAppErrors.RaiseBadRequest('E-mail do remetente inválido.');

  if (Dados.ResponderPara <> '') and not EmailValido(Dados.ResponderPara) then
    TAppErrors.RaiseBadRequest('E-mail de resposta inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TemSenha := not Dados.Senha.IsEmpty;

    if not TemSenha then
      TemSenha := TPlataformaEmailDAO.TemSenha(Conn);

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
      TPlataformaEmailDAO.Salvar(
        Conn,
        Dados,
        TCertificaSecrets.EmailSmtpSecret
      );

      TPlataformaEmailDAO.RegistrarAuditoria(
        Conn,
        AIdUsuario,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result := TPlataformaEmailDAO.Buscar(Conn);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaEmailService.ObterConfiguracao(
  out AConfig: TPlataformaEmailConfig;
  out ASenha: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := False;
  AConfig := Default(TPlataformaEmailConfig);
  ASenha := '';

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    AConfig := TPlataformaEmailDAO.Buscar(Conn);

    if not AConfig.Ativo or
       AConfig.SmtpHost.IsEmpty or
       AConfig.Usuario.IsEmpty or
       not AConfig.SenhaConfigurada or
       AConfig.RemetenteEmail.IsEmpty then
      Exit;

    ASenha := TPlataformaEmailDAO.ObterSenha(
      Conn,
      TCertificaSecrets.EmailSmtpSecret
    );

    Result := not ASenha.IsEmpty;
  finally
    Conn.Free;
  end;
end;

end.
