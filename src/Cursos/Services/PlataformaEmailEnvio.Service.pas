unit PlataformaEmailEnvio.Service;

interface

uses
  System.JSON;

type
  TPlataformaEmailEnvioService = class
  public
    class function Configurado: Boolean; static;

    class procedure Enviar(
      const ADestinatario,
            AAssunto,
            AHtml: string
    ); static;

    class procedure EnviarComAnexos(
      const ADestinatario,
            AAssunto,
            AHtml: string;
      const AAnexos: TJSONArray
    ); static;
  end;

implementation

uses
  System.SysUtils,
  IdSMTP,
  IdMessage,
  IdText,
  IdAttachmentFile,
  IdSSL,
  IdExplicitTLSClientServerBase,
  TaurusTLS,
  PlataformaEmail.Model,
  PlataformaEmail.Service;

class function TPlataformaEmailEnvioService.Configurado: Boolean;
var
  Config: TPlataformaEmailConfig;
  Senha: string;
begin
  Result :=
    TPlataformaEmailService.ObterConfiguracao(
      Config,
      Senha
    );
end;

class procedure TPlataformaEmailEnvioService.Enviar(
  const ADestinatario,
        AAssunto,
        AHtml: string
);
begin
  EnviarComAnexos(
    ADestinatario,
    AAssunto,
    AHtml,
    nil
  );
end;

class procedure TPlataformaEmailEnvioService.EnviarComAnexos(
  const ADestinatario,
        AAssunto,
        AHtml: string;
  const AAnexos: TJSONArray
);
var
  Config: TPlataformaEmailConfig;
  Senha: string;
  SMTP: TIdSMTP;
  SSL: TTaurusTLSIOHandlerSocket;
  Mensagem: TIdMessage;
  HtmlPart: TIdText;
  I: Integer;
  Obj: TJSONObject;
  Caminho,
  NomeOriginal: string;
  Anexo: TIdAttachmentFile;
begin
  if not TPlataformaEmailService.ObterConfiguracao(Config, Senha) then
    raise Exception.Create(
      'Configuração global de e-mail indisponível.'
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

    Mensagem.CharSet := 'UTF-8';
    Mensagem.Encoding := meMIME;
    Mensagem.ContentType := 'multipart/mixed';
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

    if AAnexos <> nil then
      for I := 0 to AAnexos.Count - 1 do
      begin
        if not (AAnexos.Items[I] is TJSONObject) then
          Continue;

        Obj := AAnexos.Items[I] as TJSONObject;
        Caminho := Obj.GetValue<string>('caminho_storage', '');
        NomeOriginal := Obj.GetValue<string>('nome_original', '');

        if Trim(Caminho).IsEmpty or
           not FileExists(Caminho) then
          raise Exception.Create(
            'Anexo da campanha não localizado: ' +
            NomeOriginal
          );

        Anexo := TIdAttachmentFile.Create(
          Mensagem.MessageParts,
          Caminho
        );

        if not Trim(NomeOriginal).IsEmpty then
          Anexo.FileName := NomeOriginal;
      end;

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
