unit EleicaoEmail.Service;

interface

type
  TEleicaoEmailService = class
  private
    class function EmailValido(const AEmail: string): Boolean; static;
  public
    class procedure Enviar(const AIdEmpresa: Integer;
      const ADestinatario, AAssunto, AHtml: string); static;
    class procedure EnviarTeste(const AIdEmpresa: Integer;
      const ADestinatario: string); static;
  end;

implementation

uses
  System.SysUtils,
  IdSMTP,
  IdMessage,
  IdText,
  IdSSL,
  IdExplicitTLSClientServerBase,
  TaurusTLS,
  APP.Errors,
  App.TextEncoding,
  EleicaoEmailConfigAPI.Model,
  EleicaoEmailConfigAPI.Service;

class function TEleicaoEmailService.EmailValido(const AEmail: string): Boolean;
var
  Email: string;
  P: Integer;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);
  Result := (P > 1) and (P < Length(Email) - 2) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

class procedure TEleicaoEmailService.Enviar(const AIdEmpresa: Integer;
  const ADestinatario, AAssunto, AHtml: string);
var
  Config: TEleicaoEmailConfig;
  Senha: string;
  SMTP: TIdSMTP;
  SSL: TTaurusTLSIOHandlerSocket;
  Mensagem: TIdMessage;
  HtmlPart: TIdText;
  Destinatario: string;
begin
  Destinatario := LowerCase(Trim(ADestinatario));

  if not EmailValido(Destinatario) then
    TAppErrors.RaiseBadRequest('Informe um e-mail de destinatário válido.');

  if not TEleicaoEmailConfigService.ObterConfiguracaoParaEnvio(
    AIdEmpresa,
    Config,
    Senha
  ) then
    TAppErrors.RaiseBadRequest(
      'A configuração SMTP está incompleta ou o envio de e-mail está desativado.'
    );

  SMTP := TIdSMTP.Create(nil);
  SSL := TTaurusTLSIOHandlerSocket.Create(nil);
  Mensagem := TIdMessage.Create(nil);
  try
    SMTP.Host := Config.SmtpHost;
    SMTP.Port := Config.SmtpPorta;
    SMTP.Username := Config.Usuario;
    SMTP.Password := Senha;
    SMTP.ConnectTimeout := 15000;
    SMTP.ReadTimeout := 20000;

    SSL.SSLOptions.Mode := sslmClient;
    SSL.SSLOptions.MinTLSVersion := TLSv1_2;

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
    Mensagem.Encoding := meMIME;
    Mensagem.From.Name := Config.RemetenteNome;
    Mensagem.From.Address := Config.RemetenteEmail;
    Mensagem.Recipients.Add.Address := Destinatario;

    if not Trim(Config.ResponderPara).IsEmpty then
      Mensagem.ReplyTo.Add.Address := Config.ResponderPara;

    Mensagem.Subject := TAppTextEncoding.NormalizarUtf8Legado(AAssunto);

    HtmlPart := TIdText.Create(Mensagem.MessageParts, nil);
    HtmlPart.ContentType := 'text/html; charset=UTF-8';
    HtmlPart.CharSet := 'UTF-8';
    HtmlPart.ContentTransfer := 'quoted-printable';
    HtmlPart.Body.Text := TAppTextEncoding.NormalizarUtf8Legado(AHtml);

    try
      SMTP.Connect;
      SMTP.Send(Mensagem);
    except
      on E: Exception do
        TAppErrors.RaiseBadRequest(
          'Falha ao enviar e-mail pelo servidor SMTP: ' + E.Message +
          ' | Servidor: ' + Config.SmtpHost + ':' + Config.SmtpPorta.ToString +
          ' | Segurança: ' + Config.Seguranca
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

class procedure TEleicaoEmailService.EnviarTeste(const AIdEmpresa: Integer;
  const ADestinatario: string);
begin
  Enviar(
    AIdEmpresa,
    ADestinatario,
    'Teste de configuração de e-mail - Eleição',
    '<h2>Configuração SMTP validada</h2>' +
    '<p>Este e-mail confirma que a configuração SMTP da empresa foi utilizada com sucesso.</p>' +
    '<p>Servidor, autenticação, remetente e segurança SMTP foram validados no envio.</p>'
  );
end;

end.
