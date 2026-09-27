unit PlataformaEmailEnvio.Service;

interface

type
  TPlataformaEmailEnvioService = class
  public
    class procedure Enviar(
      const ADestinatario,
            AAssunto,
            AHtml: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  IdSMTP,
  IdMessage,
  IdText,
  IdSSL,
  IdSSLOpenSSL,
  IdExplicitTLSClientServerBase,
  PlataformaEmail.Model,
  PlataformaEmail.Service;

class procedure TPlataformaEmailEnvioService.Enviar(
  const ADestinatario,
        AAssunto,
        AHtml: string
);
var
  Config: TPlataformaEmailConfig;
  Senha: string;
  SMTP: TIdSMTP;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  Mensagem: TIdMessage;
  HtmlPart: TIdText;
begin
  if not TPlataformaEmailService.ObterConfiguracao(Config, Senha) then
    raise Exception.Create(
      'Configuração global de e-mail indisponível.'
    );

  if not LoadOpenSSLLibrary then
    raise Exception.Create(
      'Biblioteca OpenSSL não disponível para envio SMTP.'
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

    Mensagem.CharSet := 'UTF-8';
    Mensagem.Encoding := meMIME;
    Mensagem.From.Name := Config.RemetenteNome;
    Mensagem.From.Address := Config.RemetenteEmail;
    Mensagem.Recipients.Add.Address := LowerCase(Trim(ADestinatario));

    if not Trim(Config.ResponderPara).IsEmpty then
      Mensagem.ReplyTo.Add.Address := Config.ResponderPara;

    Mensagem.Subject := AAssunto;

    HtmlPart := TIdText.Create(
      Mensagem.MessageParts,
      nil
    );

    HtmlPart.ContentType := 'text/html';
    HtmlPart.CharSet := 'UTF-8';
    HtmlPart.ContentTransfer := 'quoted-printable';
    HtmlPart.Body.Text := AHtml;

    SMTP.Connect;
    try
      SMTP.Send(Mensagem);
    finally
      if SMTP.Connected then
        SMTP.Disconnect;
    end;
  finally
    Mensagem.Free;
    SSL.Free;
    SMTP.Free;
  end;
end;

end.
