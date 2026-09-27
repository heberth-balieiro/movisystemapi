unit PublicoRecuperacaoSenha.Service;

interface

uses
  PublicoRecuperacaoSenha.DAO;

type
  TPublicoRecuperacaoSenhaService = class
  private
    class function GerarTokenSeguro: string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
    class function MascararEmail(const AEmail: string): string; static;
    class function EscapeHtml(const AValue: string): string; static;
    class function MontarEmail(
      const ADados: TRecuperacaoSenhaDados;
      const ALink: string
    ): string; static;

  public
    class procedure Solicitar(
      const ASlug,
            AEmail: string
    ); static;

    class function Validar(
      const ASlug,
            AToken: string
    ): TRecuperacaoSenhaDados; static;

    class function Redefinir(
      const ASlug,
            AToken,
            ASenha: string
    ): TRecuperacaoSenhaDados; static;

    class function EmailMascarado(
      const AEmail: string
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  PlataformaEmail.Model,
  PlataformaEmail.Service,
  PlataformaEmailEnvio.Service;

class function TPublicoRecuperacaoSenhaService.GerarTokenSeguro: string;
var
  G1: TGUID;
  G2: TGUID;

  function Limpar(const AGuid: TGUID): string;
  begin
    Result :=
      LowerCase(
        StringReplace(
          StringReplace(
            StringReplace(
              GUIDToString(AGuid),
              '{',
              '',
              [rfReplaceAll]
            ),
            '}',
            '',
            [rfReplaceAll]
          ),
          '-',
          '',
          [rfReplaceAll]
        )
      );
  end;

begin
  CreateGUID(G1);
  CreateGUID(G2);
  Result := Limpar(G1) + Limpar(G2);
end;

class function TPublicoRecuperacaoSenhaService.EmailValido(
  const AEmail: string
): Boolean;
var
  Email: string;
  P: Integer;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);

  Result :=
    (P > 1) and
    (P < Length(Email) - 2) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

class function TPublicoRecuperacaoSenhaService.MascararEmail(
  const AEmail: string
): string;
var
  Email: string;
  P: Integer;
  Local: string;
  Dominio: string;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);

  if P <= 1 then
    Exit('');

  Local := Copy(Email, 1, P - 1);
  Dominio := Copy(Email, P + 1, MaxInt);

  if Length(Local) <= 2 then
    Result := Copy(Local, 1, 1) + '***@' + Dominio
  else
    Result :=
      Copy(Local, 1, 2) +
      '***' +
      Copy(Local, Length(Local), 1) +
      '@' +
      Dominio;
end;

class function TPublicoRecuperacaoSenhaService.EmailMascarado(
  const AEmail: string
): string;
begin
  Result := MascararEmail(AEmail);
end;

class function TPublicoRecuperacaoSenhaService.EscapeHtml(
  const AValue: string
): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

class function TPublicoRecuperacaoSenhaService.MontarEmail(
  const ADados: TRecuperacaoSenhaDados;
  const ALink: string
): string;
begin
  Result :=
    '<!doctype html><html><body style="margin:0;background:#f8fafc;font-family:Arial,sans-serif;color:#0f172a;">' +
    '<div style="max-width:620px;margin:0 auto;padding:32px 18px;">' +
    '<div style="background:#fff;border:1px solid #e2e8f0;border-radius:16px;padding:32px;">' +
    '<div style="font-size:12px;font-weight:700;letter-spacing:.14em;color:#2563eb;text-transform:uppercase;">MoviSystem Certifica</div>' +
    '<h1 style="font-size:24px;margin:14px 0 8px;">Redefinição de senha</h1>' +
    '<p style="font-size:15px;line-height:1.6;color:#475569;">Olá, ' +
    EscapeHtml(ADados.Nome) + '.</p>' +
    '<p style="font-size:15px;line-height:1.6;color:#475569;">Recebemos uma solicitação para redefinir sua senha de acesso ao portal de capacitações da ' +
    EscapeHtml(ADados.InstituicaoNome) + '.</p>' +
    '<p style="margin:28px 0;"><a href="' + EscapeHtml(ALink) +
    '" style="display:inline-block;background:#2563eb;color:#fff;text-decoration:none;font-weight:700;padding:13px 22px;border-radius:9px;">Redefinir minha senha</a></p>' +
    '<p style="font-size:14px;line-height:1.6;color:#64748b;">Este link é pessoal, de uso único e válido por 30 minutos. Se você não solicitou a alteração, ignore esta mensagem.</p>' +
    '<p style="font-size:12px;line-height:1.5;color:#94a3b8;margin-top:28px;">Por segurança, nunca envie sua senha por e-mail e não compartilhe este link.</p>' +
    '</div></div></body></html>';
end;

class procedure TPublicoRecuperacaoSenhaService.Solicitar(
  const ASlug,
        AEmail: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TRecuperacaoSenhaDados;
  EmailConfig: TPlataformaEmailConfig;
  EmailSenha: string;
  Token: string;
  Link: string;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Instituição não informada.');

  if not EmailValido(AEmail) then
    TAppErrors.RaiseBadRequest('Informe um e-mail válido.');

  if not TPlataformaEmailService.ObterConfiguracao(
    EmailConfig,
    EmailSenha
  ) then
    TAppErrors.RaiseBadRequest(
      'O serviço de recuperação de senha está temporariamente indisponível.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Dados := TPublicoRecuperacaoSenhaDAO.BuscarUsuario(
      Conn,
      ASlug,
      AEmail
    );

    // Não revela se o e-mail existe ou não.
    if not Dados.Valido then
      Exit;

    Token := GerarTokenSeguro;

    Conn.StartTransaction;
    try
      TPublicoRecuperacaoSenhaDAO.RevogarTokens(
        Conn,
        Dados.IdUsuario,
        Dados.IdInstituicao
      );

      TPublicoRecuperacaoSenhaDAO.CriarToken(
        Conn,
        Dados.IdUsuario,
        Dados.IdInstituicao,
        Token
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Link :=
      Config.Web.PublicURL +
      '/' +
      Dados.InstituicaoSlug +
      '/redefinir-senha#token=' +
      Token;

    try
      TPlataformaEmailEnvioService.Enviar(
        Dados.Email,
        'Redefinição de senha - ' + Dados.InstituicaoNome,
        MontarEmail(Dados, Link)
      );
    except
      // A resposta pública continua neutra para não facilitar enumeração de contas.
    end;
  finally
    Conn.Free;
  end;
end;

class function TPublicoRecuperacaoSenhaService.Validar(
  const ASlug,
        AToken: string
): TRecuperacaoSenhaDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if Trim(ASlug).IsEmpty or
     (Length(Trim(AToken)) < 32) then
    TAppErrors.RaiseBadRequest(
      'Link de recuperação inválido.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPublicoRecuperacaoSenhaDAO.BuscarToken(
      Conn,
      ASlug,
      AToken
    );

    if not Result.Valido then
      TAppErrors.RaiseBadRequest(
        'Este link de recuperação é inválido, expirou ou já foi utilizado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TPublicoRecuperacaoSenhaService.Redefinir(
  const ASlug,
        AToken,
        ASenha: string
): TRecuperacaoSenhaDados;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if Length(Trim(AToken)) < 32 then
    TAppErrors.RaiseBadRequest(
      'Link de recuperação inválido.'
    );

  if Length(ASenha) < 8 then
    TAppErrors.RaiseBadRequest(
      'A senha deve possuir pelo menos 8 caracteres.'
    );

  if Length(ASenha) > 120 then
    TAppErrors.RaiseBadRequest(
      'A senha excede o tamanho permitido.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Result := TPublicoRecuperacaoSenhaDAO.BuscarToken(
        Conn,
        ASlug,
        AToken
      );

      if not Result.Valido then
        TAppErrors.RaiseBadRequest(
          'Este link de recuperação é inválido, expirou ou já foi utilizado.'
        );

      TPublicoRecuperacaoSenhaDAO.RedefinirSenha(
        Conn,
        Result.IdToken,
        Result.IdUsuario,
        Result.IdInstituicao,
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
