unit InstituicaoEmail.Service;

interface

type
  TInstituicaoEmailService = class
  private
    class function EmailValido(
      const AEmail: string
    ): Boolean; static;

  public
    class procedure Enviar(
      const AIdInstituicao: Int64;
      const ADestinatario,
            AAssunto,
            AHtml: string
    ); static;

    class procedure EnviarTeste(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADestinatario: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  IdSMTP,
  IdMessage,
  IdSSL,
  IdSSLOpenSSL,
  IdExplicitTLSClientServerBase,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoConfiguracao.Model,
  InstituicaoConfiguracao.DAO,
  InstituicaoConfiguracao.Service,
  InstituicaoPermissao.Service;

class function TInstituicaoEmailService.EmailValido(
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

class procedure TInstituicaoEmailService.Enviar(
  const AIdInstituicao: Int64;
  const ADestinatario,
        AAssunto,
        AHtml: string
);
var
  Config: TInstituicaoEmailConfig;
  Senha: string;
  SMTP: TIdSMTP;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  Mensagem: TIdMessage;
  Destinatario: string;
begin
  Destinatario := LowerCase(Trim(ADestinatario));

  if not EmailValido(Destinatario) then
    TAppErrors.RaiseBadRequest(
      'Informe um e-mail de destinatário válido.'
    );

  if not TInstituicaoConfiguracaoService.ObterEmailConfigurado(
    AIdInstituicao,
    Config,
    Senha
  ) then
    TAppErrors.RaiseBadRequest(
      'A configuração SMTP está incompleta ou o envio de e-mail está desativado.'
    );

  SMTP := TIdSMTP.Create(nil);
  SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  Mensagem := TIdMessage.Create(nil);
  try
    SMTP.Host := Config.SmtpHost;
    SMTP.Port := Config.SmtpPorta;
    SMTP.Username := Config.Usuario;
    SMTP.Password := Senha;
    SMTP.ConnectTimeout := 15000;
    SMTP.ReadTimeout := 20000;

    // Zoho e demais provedores modernos exigem TLS atual.
    // O Indy pode negociar versões antigas por padrão dependendo das DLLs
    // do OpenSSL disponíveis no servidor, resultando em "SSL negotiation failed".
    SSL.SSLOptions.Mode := sslmClient;
    SSL.SSLOptions.SSLVersions := [sslvTLSv1_2];

    if SameText(Config.Seguranca, 'SSL_TLS') then
    begin
      SMTP.IOHandler := SSL;
      SMTP.UseTLS := utUseImplicitTLS;
    end
    else if SameText(Config.Seguranca, 'STARTTLS') then
    begin
      SMTP.IOHandler := SSL;
      SMTP.UseTLS := utUseExplicitTLS;
    end
    else
      SMTP.UseTLS := utNoTLSSupport;

    Mensagem.Clear;
    Mensagem.CharSet := 'UTF-8';
    Mensagem.ContentType := 'text/html';
    Mensagem.From.Name := Config.RemetenteNome;
    Mensagem.From.Address := Config.RemetenteEmail;
    Mensagem.Recipients.Add.Address := Destinatario;

    if not Trim(Config.ResponderPara).IsEmpty then
      Mensagem.ReplyTo.Add.Address := Config.ResponderPara;

    Mensagem.Subject := AAssunto;
    Mensagem.Body.Text := AHtml;

    try
      SMTP.Connect;
      SMTP.Send(Mensagem);
    except
      on E: Exception do
        TAppErrors.RaiseBadRequest(
          'Falha ao enviar e-mail pelo servidor SMTP: ' +
          E.Message
        );
    end;
  finally
    if SMTP.Connected then
      SMTP.Disconnect;

    Mensagem.Free;
    SSL.Free;
    SMTP.Free;
  end;
end;

class procedure TInstituicaoEmailService.EnviarTeste(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADestinatario: string
);
var
  AppConfig: TAppApiConfig;
  Conn: TUniConnection;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'configuracao.editar'
  );

  Enviar(
    AIdInstituicao,
    ADestinatario,
    'Teste de configuração de e-mail',
    '<h2>Configuração SMTP validada</h2>' +
    '<p>Este e-mail confirma que a instituição conseguiu enviar uma mensagem pela plataforma.</p>' +
    '<p>Servidor, autenticação e segurança SMTP foram utilizados com sucesso.</p>'
  );

  AppConfig :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      AppConfig.Database
    );
  try
    TInstituicaoConfiguracaoDAO.RegistrarTesteEmail(
      Conn,
      AIdInstituicao,
      AIdUsuarioInstituicao,
      LowerCase(Trim(ADestinatario))
    );
  finally
    Conn.Free;
  end;
end;

end.
