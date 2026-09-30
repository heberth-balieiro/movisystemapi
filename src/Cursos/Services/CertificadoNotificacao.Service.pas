unit CertificadoNotificacao.Service;

interface

uses
  Uni;

type
  TCertificadoNotificacaoService = class
  private
    class function NovaConexao: TUniConnection; static;
    class function HtmlEncode(const AValor: string): string; static;
    class procedure RegistrarHistorico(
      const AIdInstituicao,
            AIdCertificado: Int64;
      const AEvento,
            ADescricao: string
    ); static;
  public
    class function Agendar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): Integer; static;

    class function ProcessarProximo: Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  App.Config,
  Database.Connection,
  CertificadoNotificacao.Model,
  CertificadoNotificacao.DAO,
  InstituicaoCertificado.DAO,
  InstituicaoEmail.Service,
  InstituicaoWhatsApp.Service;

class function TCertificadoNotificacaoService.NovaConexao: TUniConnection;
var
  Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Result := TDatabaseConnection.NewConnection(Config.Database);
end;

class function TCertificadoNotificacaoService.HtmlEncode(
  const AValor: string
): string;
begin
  Result := StringReplace(AValor, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

class procedure TCertificadoNotificacaoService.RegistrarHistorico(
  const AIdInstituicao,
        AIdCertificado: Int64;
  const AEvento,
        ADescricao: string
);
var
  C: TUniConnection;
begin
  C := NovaConexao;
  try
    TInstituicaoCertificadoDAO.InserirHistorico(
      C,
      AIdInstituicao,
      AIdCertificado,
      0,
      AEvento,
      ADescricao,
      ''
    );
  finally
    C.Free;
  end;
end;

class function TCertificadoNotificacaoService.Agendar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): Integer;
var
  Contexto: TCertificadoNotificacaoContexto;
begin
  Result := 0;

  Contexto := TCertificadoNotificacaoDAO.BuscarContexto(
    AConn,
    AIdInstituicao,
    AIdCertificado
  );
  try
    if Contexto = nil then
      Exit;

    if not Trim(Contexto.ParticipanteEmail).IsEmpty then
    begin
      TCertificadoNotificacaoDAO.Enfileirar(
        AConn,
        AIdInstituicao,
        AIdCertificado,
        'EMAIL',
        Contexto.ParticipanteEmail
      );
      Inc(Result);
    end;

    if not Trim(Contexto.ParticipanteTelefone).IsEmpty then
    begin
      TCertificadoNotificacaoDAO.Enfileirar(
        AConn,
        AIdInstituicao,
        AIdCertificado,
        'WHATSAPP',
        Contexto.ParticipanteTelefone
      );
      Inc(Result);
    end;
  finally
    Contexto.Free;
  end;
end;

class function TCertificadoNotificacaoService.ProcessarProximo: Boolean;
var
  C: TUniConnection;
  Item: TCertificadoNotificacaoItem;
  Contexto: TCertificadoNotificacaoContexto;
  Config: TAppApiConfig;
  LinkAluno: string;
  Assunto: string;
  Html: string;
  Mensagem: string;
begin
  Result := False;
  Item := nil;
  Contexto := nil;

  C := NovaConexao;
  try
    C.StartTransaction;
    try
      TCertificadoNotificacaoDAO.RecuperarTravados(C);
      Item := TCertificadoNotificacaoDAO.ReservarProximo(C);
      C.Commit;
    except
      if C.InTransaction then C.Rollback;
      raise;
    end;
  finally
    C.Free;
  end;

  if Item = nil then
    Exit;

  Result := True;

  try
    C := NovaConexao;
    try
      Contexto := TCertificadoNotificacaoDAO.BuscarContexto(
        C,
        Item.IdInstituicao,
        Item.IdCertificado
      );
    finally
      C.Free;
    end;

    if Contexto = nil then
    begin
      C := NovaConexao;
      try
        TCertificadoNotificacaoDAO.MarcarIgnorado(
          C,
          Item.Id,
          'Certificado não está mais válido para notificação.'
        );
      finally
        C.Free;
      end;

      RegistrarHistorico(
        Item.IdInstituicao,
        Item.IdCertificado,
        'NOTIFICACAO_IGNORADA',
        'Notificação não enviada porque o certificado deixou de estar válido.'
      );
      Exit;
    end;

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    LinkAluno := Config.Web.PublicURL +
      '/' + Contexto.InstituicaoSlug +
      '/aluno/certificados/' + IntToStr(Contexto.IdCertificado);

    try
      if SameText(Item.Canal, 'EMAIL') then
      begin
        Assunto := 'Seu certificado está disponível - ' + Contexto.CursoNome;
        Html :=
          '<h2>Seu certificado está disponível</h2>' +
          '<p>Olá, ' + HtmlEncode(Contexto.ParticipanteNome) + '.</p>' +
          '<p>O certificado do curso <strong>' + HtmlEncode(Contexto.CursoNome) +
          '</strong> já está disponível na sua área do participante.</p>' +
          '<p><strong>Número:</strong> ' + HtmlEncode(Contexto.NumeroPublico) + '</p>' +
          '<p><a href="' + HtmlEncode(LinkAluno) + '">Acessar meu certificado</a></p>' +
          '<p>' + HtmlEncode(Contexto.InstituicaoNome) + '</p>';

        TInstituicaoEmailService.Enviar(
          Item.IdInstituicao,
          Item.Destinatario,
          Assunto,
          Html
        );
      end
      else if SameText(Item.Canal, 'WHATSAPP') then
      begin
        Mensagem :=
          '🎓 Seu certificado está disponível!' + sLineBreak + sLineBreak +
          'Olá, ' + Contexto.ParticipanteNome + '.' + sLineBreak +
          'O certificado do curso ' + Contexto.CursoNome + ' já foi emitido.' + sLineBreak +
          'Número: ' + Contexto.NumeroPublico + sLineBreak + sLineBreak +
          'Acesse sua área do participante:' + sLineBreak +
          LinkAluno;

        TInstituicaoWhatsAppService.EnviarMensagemSistema(
          Item.IdInstituicao,
          Item.Destinatario,
          Mensagem
        );
      end
      else
        raise Exception.Create('Canal de notificação inválido.');

      C := NovaConexao;
      try
        TCertificadoNotificacaoDAO.MarcarEnviado(C, Item.Id);
      finally
        C.Free;
      end;

      RegistrarHistorico(
        Item.IdInstituicao,
        Item.IdCertificado,
        'NOTIFICACAO_' + UpperCase(Item.Canal) + '_ENVIADA',
        'Notificação de certificado disponível enviada por ' + LowerCase(Item.Canal) + '.'
      );
    except
      on E: Exception do
      begin
        C := NovaConexao;
        try
          TCertificadoNotificacaoDAO.MarcarErro(C, Item.Id, E.Message);
        finally
          C.Free;
        end;

        if Item.Tentativas >= 3 then
          RegistrarHistorico(
            Item.IdInstituicao,
            Item.IdCertificado,
            'NOTIFICACAO_' + UpperCase(Item.Canal) + '_ERRO',
            'Falha definitiva após 3 tentativas de envio: ' + Copy(E.Message, 1, 500)
          );
      end;
    end;
  finally
    Contexto.Free;
    Item.Free;
  end;
end;

end.
