unit EleicaoEmail.Service;

interface

uses
  EleicaoEmail.Contracts;

type
  TEleicaoEmailService = class(TInterfacedObject, IEmailService)
  private
    function EmailValido(const AEmail: string): Boolean;
    function ClassificarErroSMTP(const AMensagem: string): string;
    function MensagemErroSMTP(const ACategoria: string): string;
    procedure RegistrarLogSeguro(
      const AEvento: string;
      const AIdEmpresa: Integer;
      const AHost: string;
      const APorta: Integer;
      const ASeguranca,
            ACategoria,
            AClasseErro: string
    );
  public
    class function New: IEmailService; static;

    procedure Enviar(
      const AIdEmpresa: Integer;
      const ADestinatario,
            AAssunto,
            AHtml: string
    );

    procedure EnviarTeste(
      const AIdEmpresa: Integer;
      const ADestinatario: string
    );
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

class function TEleicaoEmailService.New: IEmailService;
begin
  Result := TEleicaoEmailService.Create;
end;

function TEleicaoEmailService.EmailValido(const AEmail: string): Boolean;
var
  Email: string;
  P: Integer;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);
  Result := (P > 1) and (P < Length(Email) - 2) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

function TEleicaoEmailService.ClassificarErroSMTP(
  const AMensagem: string): string;
var
  Msg: string;
begin
  Msg := LowerCase(Trim(AMensagem));

  if (Pos('auth', Msg) > 0) or
     (Pos('535', Msg) > 0) or
     (Pos('password', Msg) > 0) or
     (Pos('credential', Msg) > 0) or
     (Pos('senha', Msg) > 0) then
    Exit('AUTENTICACAO');

  if (Pos('timeout', Msg) > 0) or
     (Pos('timed out', Msg) > 0) or
     (Pos('10060', Msg) > 0) then
    Exit('TIMEOUT');

  if (Pos('ssl', Msg) > 0) or
     (Pos('tls', Msg) > 0) or
     (Pos('certificate', Msg) > 0) or
     (Pos('handshake', Msg) > 0) or
     (Pos('negotiation', Msg) > 0) then
    Exit('TLS');

  if (Pos('host not found', Msg) > 0) or
     (Pos('getaddrinfo', Msg) > 0) or
     (Pos('11001', Msg) > 0) then
    Exit('HOST');

  if (Pos('refused', Msg) > 0) or
     (Pos('unreachable', Msg) > 0) or
     (Pos('10061', Msg) > 0) or
     (Pos('connection closed', Msg) > 0) then
    Exit('INDISPONIVEL');

  Result := 'SMTP';
end;

function TEleicaoEmailService.MensagemErroSMTP(
  const ACategoria: string): string;
begin
  if SameText(ACategoria, 'AUTENTICACAO') then
    Exit('Falha na autenticação SMTP. Verifique o usuário e a senha configurados.');

  if SameText(ACategoria, 'TIMEOUT') then
    Exit('Tempo limite excedido ao conectar ou comunicar com o servidor SMTP.');

  if SameText(ACategoria, 'TLS') then
    Exit('Falha na negociação SSL/TLS com o servidor SMTP. Verifique o tipo de segurança configurado.');

  if SameText(ACategoria, 'HOST') then
    Exit('Não foi possível localizar o servidor SMTP configurado. Verifique o host.');

  if SameText(ACategoria, 'INDISPONIVEL') then
    Exit('O servidor SMTP está indisponível ou recusou a conexão.');

  Result := 'Falha ao enviar e-mail pelo servidor SMTP.';
end;

procedure TEleicaoEmailService.RegistrarLogSeguro(
  const AEvento: string;
  const AIdEmpresa: Integer;
  const AHost: string;
  const APorta: Integer;
  const ASeguranca,
        ACategoria,
        AClasseErro: string
);
begin
  try
    Writeln(
      Format(
        '[EMAIL] evento=%s empresa=%d host=%s porta=%d seguranca=%s categoria=%s classe=%s',
        [
          AEvento,
          AIdEmpresa,
          Trim(AHost),
          APorta,
          Trim(ASeguranca),
          Trim(ACategoria),
          Trim(AClasseErro)
        ]
      )
    );
  except
    // Falha de log nunca deve interferir no envio.
  end;
end;

procedure TEleicaoEmailService.Enviar(
  const AIdEmpresa: Integer;
  const ADestinatario,
        AAssunto,
        AHtml: string
);
var
  Config: TEleicaoEmailConfig;
  Senha: string;
  SMTP: TIdSMTP;
  SSL: TTaurusTLSIOHandlerSocket;
  Mensagem: TIdMessage;
  HtmlPart: TIdText;
  Destinatario: string;
  Categoria: string;
begin
  Destinatario := LowerCase(Trim(ADestinatario));

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada para envio de e-mail.');

  if not EmailValido(Destinatario) then
    TAppErrors.RaiseBadRequest('Informe um e-mail de destinatário válido.');

  if Trim(AAssunto).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o assunto do e-mail.');

  if Trim(AHtml).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o conteúdo do e-mail.');

  if not TEleicaoEmailConfigService.ObterConfiguracaoParaEnvio(
    AIdEmpresa,
    Config,
    Senha
  ) then
  begin
    RegistrarLogSeguro(
      'CONFIGURACAO_INVALIDA',
      AIdEmpresa,
      Config.SmtpHost,
      Config.SmtpPorta,
      Config.Seguranca,
      'CONFIGURACAO',
      ''
    );

    TAppErrors.RaiseBadRequest(
      'A configuração SMTP está incompleta ou o envio de e-mail está desativado.'
    );
  end;

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
    else if SameText(Config.Seguranca, 'NONE') then
      SMTP.UseTLS := utNoTLSSupport
    else
      TAppErrors.RaiseBadRequest('Tipo de segurança SMTP inválido.');

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

      RegistrarLogSeguro(
        'ENVIADO',
        AIdEmpresa,
        Config.SmtpHost,
        Config.SmtpPorta,
        Config.Seguranca,
        'SUCESSO',
        ''
      );
    except
      on E: Exception do
      begin
        Categoria := ClassificarErroSMTP(E.Message);

        RegistrarLogSeguro(
          'ERRO',
          AIdEmpresa,
          Config.SmtpHost,
          Config.SmtpPorta,
          Config.Seguranca,
          Categoria,
          E.ClassName
        );

        TAppErrors.RaiseBadRequest(MensagemErroSMTP(Categoria));
      end;
    end;
  finally
    Senha := '';

    if SMTP.Connected then
      SMTP.Disconnect;

    Mensagem.Free;
    SSL.Free;
    SMTP.Free;
  end;
end;

procedure TEleicaoEmailService.EnviarTeste(
  const AIdEmpresa: Integer;
  const ADestinatario: string
);
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
