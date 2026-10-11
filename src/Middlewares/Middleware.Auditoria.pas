unit Middleware.Auditoria;

interface

uses
  Horse;

type
  TMiddlewareAuditoria = class
  public
    class function Registrar: THorseCallback; static;
  end;

implementation

uses
  System.SysUtils,
  App.JWT,
  App.Config,
  Auditoria.Service;

function Contem(
  const ATexto,
        ATrecho: string
): Boolean;
begin
  Result :=
    Pos(
      LowerCase(ATrecho),
      LowerCase(ATexto)
    ) > 0;
end;

function EhRotaCertifica(
  const ACaminho: string
): Boolean;
begin
  Result :=
    Pos(
      '/v1/certifica/',
      LowerCase(ACaminho)
    ) = 1;
end;

function EhLeituraSensivel(
  const AMetodo,
        ACaminho: string
): Boolean;
begin
  Result := False;

  if not SameText(AMetodo, 'GET') then
    Exit;

  Result :=
    Contem(ACaminho, '/instituicao/participantes') or
    Contem(ACaminho, '/instituicao/usuarios') or
    Contem(ACaminho, '/instituicao/auditoria') or
    Contem(ACaminho, '/instituicao/lgpd/') or
    Contem(ACaminho, '/aluno/lgpd/') or
    SameText(ACaminho, '/v1/certifica/aluno/me') or
    (
      Contem(ACaminho, '/aluno/certificados/') and
      Contem(ACaminho, '/pdf')
    ) or
    (
      Contem(ACaminho, '/instituicao/certificados/') and
      Contem(ACaminho, '/pdf')
    );
end;

function EhAuditavel(
  const AMetodo,
        ACaminho: string
): Boolean;
begin
  if not EhRotaCertifica(ACaminho) then
    Exit(False);

  Result :=
    SameText(AMetodo, 'POST') or
    SameText(AMetodo, 'PUT') or
    SameText(AMetodo, 'PATCH') or
    SameText(AMetodo, 'DELETE') or
    EhLeituraSensivel(
      AMetodo,
      ACaminho
    );
end;

function ResolverEntidade(
  const ACaminho: string
): string;
begin
  if Contem(ACaminho, '/lgpd/') then Exit('lgpd_solicitacao');
  if Contem(ACaminho, '/auditoria') then Exit('auditoria');
  if Contem(ACaminho, '/participantes') then Exit('participante');
  if Contem(ACaminho, '/usuarios') then Exit('usuario');
  if Contem(ACaminho, '/certificados') then Exit('certificado');
  if Contem(ACaminho, '/inscricoes') then Exit('inscricao');
  if Contem(ACaminho, '/presencas') then Exit('presenca');
  if Contem(ACaminho, '/conclusao') then Exit('conclusao');
  if Contem(ACaminho, '/turmas') then Exit('turma');
  if Contem(ACaminho, '/cursos') then Exit('curso');
  if Contem(ACaminho, '/perfis') then Exit('perfil');
  if Contem(ACaminho, '/configuracoes') then Exit('configuracao');
  if Contem(ACaminho, '/whatsapp') then Exit('whatsapp');
  Result := 'api';
end;

function ResolverAcao(
  const AMetodo,
        ACaminho: string
): string;
begin
  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/importar-csv') then
    Exit('CAMPANHA_CSV_IMPORTADO');

  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/anexos') then
  begin
    if SameText(AMetodo, 'DELETE') then
      Exit('CAMPANHA_ANEXO_EXCLUIDO')
    else
      Exit('CAMPANHA_ANEXO_ADICIONADO');
  end;

  if Contem(ACaminho, '/plataforma/campanhas/testar-email') then
    Exit('CAMPANHA_TESTE_EMAIL_ENVIADO');

  if Contem(ACaminho, '/plataforma/campanhas/testar-whatsapp') then
    Exit('CAMPANHA_TESTE_WHATSAPP_ENVIADO');

  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/iniciar') then
    Exit('CAMPANHA_INICIADA');

  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/cancelar') then
    Exit('CAMPANHA_CANCELADA');

  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/reprocessar-falhas') then
    Exit('CAMPANHA_FALHAS_REPROCESSADAS');

  if Contem(ACaminho, '/plataforma/campanhas/') and
     Contem(ACaminho, '/destinatarios') then
  begin
    if SameText(AMetodo, 'DELETE') then
      Exit('CAMPANHA_DESTINATARIO_EXCLUIDO')
    else
      Exit('CAMPANHA_DESTINATARIO_ADICIONADO');
  end;

  if Contem(ACaminho, '/plataforma/contatos-bloqueados') then
    Exit('CAMPANHA_SUPRESSAO_ALTERADA');

  if Contem(ACaminho, '/plataforma/campanhas') then
  begin
    if SameText(AMetodo, 'POST') then
      Exit('CAMPANHA_CRIADA');

    if SameText(AMetodo, 'PUT') then
      Exit('CAMPANHA_ALTERADA');
  end;

  if Contem(ACaminho, '/plataforma/usuarios/') and
     Contem(ACaminho, '/whatsapp/instancia') then
    Exit('PLATAFORMA_WHATSAPP_USUARIO_INSTANCIA_CRIADA');

  if Contem(ACaminho, '/plataforma/usuarios/') and
     Contem(ACaminho, '/whatsapp/logout') then
    Exit('PLATAFORMA_WHATSAPP_USUARIO_DESCONECTADO');

  if Contem(ACaminho, '/plataforma/usuarios/') and
     Contem(ACaminho, '/whatsapp/qrcode') then
    Exit('PLATAFORMA_WHATSAPP_USUARIO_QRCODE_GERADO');

  if SameText(AMetodo, 'GET') and
     Contem(ACaminho, '/instituicao/auditoria') then
    Exit('AUDITORIA_CONSULTADA');

  if SameText(AMetodo, 'GET') and
     SameText(ACaminho, '/v1/certifica/aluno/me') then
    Exit('DADOS_PESSOAIS_CONSULTADOS');

  if SameText(AMetodo, 'GET') and
     Contem(ACaminho, '/aluno/certificados/') and
     Contem(ACaminho, '/pdf') then
    Exit('CERTIFICADO_DOWNLOAD_ALUNO');

  if Contem(ACaminho, '/certificados/') and
     Contem(ACaminho, '/reprocessar') then
    Exit('CERTIFICADO_REPROCESSADO');

  if Contem(ACaminho, '/lgpd/solicitacoes') then
  begin
    if SameText(AMetodo, 'GET') then
      Exit('LGPD_SOLICITACOES_CONSULTADAS');

    if SameText(AMetodo, 'POST') then
      Exit('LGPD_SOLICITACAO_CRIADA');

    if SameText(AMetodo, 'PATCH') and
       Contem(ACaminho, '/cancelar') then
      Exit('LGPD_SOLICITACAO_CANCELADA');

    if SameText(AMetodo, 'PATCH') then
      Exit('LGPD_SOLICITACAO_ATUALIZADA');
  end;

  if Contem(ACaminho, '/auth/login') then
    Exit('LOGIN');

  if Contem(ACaminho, '/recuperacao-senha/solicitar') then
    Exit('RECUPERACAO_SENHA_SOLICITADA');

  if Contem(ACaminho, '/recuperacao-senha/redefinir') then
    Exit('RECUPERACAO_SENHA_REDEFINIDA');

  if Contem(ACaminho, '/primeiro-acesso/definir-senha') then
    Exit('PRIMEIRO_ACESSO_SENHA_DEFINIDA');

  if Contem(ACaminho, '/certificados/') and
     Contem(ACaminho, '/cancelar') then
    Exit('CERTIFICADO_CANCELADO');

  if Contem(ACaminho, '/certificados/') and
     Contem(ACaminho, '/reemitir') then
    Exit('CERTIFICADO_REEMITIDO');

  if Contem(ACaminho, '/certificados/') and
     Contem(ACaminho, '/gerar-pdf') then
    Exit('CERTIFICADO_PDF_GERADO');

  if SameText(AMetodo, 'POST') and
     Contem(ACaminho, '/inscricoes/') and
     Contem(ACaminho, '/certificados') then
    Exit('CERTIFICADO_EMITIDO');

  if Contem(ACaminho, '/participantes/') and
     Contem(ACaminho, '/acesso/reenviar') then
    Exit('PARTICIPANTE_ACESSO_REENVIADO');

  if Contem(ACaminho, '/participantes/') and
     Contem(ACaminho, '/acesso') and
     SameText(AMetodo, 'DELETE') then
    Exit('PARTICIPANTE_ACESSO_REVOGADO');

  if Contem(ACaminho, '/participantes/') and
     Contem(ACaminho, '/acesso') and
     SameText(AMetodo, 'POST') then
    Exit('PARTICIPANTE_ACESSO_LIBERADO');

  if Contem(ACaminho, '/participantes') then
  begin
    if SameText(AMetodo, 'GET') then Exit('PARTICIPANTE_CONSULTADO');
    if SameText(AMetodo, 'POST') then Exit('PARTICIPANTE_CADASTRADO');
    if SameText(AMetodo, 'PUT') then Exit('PARTICIPANTE_ALTERADO');
    if SameText(AMetodo, 'PATCH') then Exit('PARTICIPANTE_SITUACAO_ALTERADA');
  end;

  if Contem(ACaminho, '/usuarios') then
  begin
    if SameText(AMetodo, 'GET') then Exit('USUARIO_CONSULTADO');
    if SameText(AMetodo, 'POST') then Exit('USUARIO_CADASTRADO');
    if Contem(ACaminho, '/perfis') then Exit('USUARIO_PERFIS_ALTERADOS');
    if SameText(AMetodo, 'PUT') then Exit('USUARIO_ALTERADO');
    if SameText(AMetodo, 'PATCH') then Exit('USUARIO_SITUACAO_ALTERADA');
  end;

  if Contem(ACaminho, '/presencas') or
     Contem(ACaminho, '/checkin') then
    Exit('PRESENCA_ALTERADA');

  if Contem(ACaminho, '/conclusao') then
    Exit('CONCLUSAO_ALTERADA');

  if Contem(ACaminho, '/configuracoes') then
    Exit('CONFIGURACAO_ALTERADA');

  if Contem(ACaminho, '/perfis') then
    Exit('PERFIL_ALTERADO');

  if Contem(ACaminho, '/inscricoes') then
    Exit('INSCRICAO_ALTERADA');

  Result :=
    'HTTP_' +
    UpperCase(
      Trim(AMetodo)
    );
end;

function ExtrairClaims(
  const AReq: THorseRequest;
  out AClaims: TJWTClaims
): Boolean;
var
  Config: TAppApiConfig;
  Token: string;
begin
  AClaims := Default(TJWTClaims);
  Result := False;

  Token :=
    TAppJWT.ExtrairBearerToken(
      AReq.Headers['Authorization']
    );

  if Trim(Token).IsEmpty then
    Exit;

  try
    Config :=
      TAppConfig.Carregar(
        ExtractFilePath(ParamStr(0)) + 'Config.ini'
      );

    Result :=
      TAppJWT.ValidarEExtrair(
        Config.JWT,
        Token,
        AClaims
      );
  except
    AClaims := Default(TJWTClaims);
    Result := False;
  end;
end;

class function TMiddlewareAuditoria.Registrar: THorseCallback;
begin
  Result :=
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Metodo: string;
      Caminho: string;
      Acao: string;
      Entidade: string;
      Mensagem: string;
      Claims: TJWTClaims;
      StatusCode: Integer;
      StatusConsole: Integer;
      Sucesso: Boolean;
      HouveExcecao: Boolean;
      Auditavel: Boolean;
    begin
      Metodo := UpperCase(Trim(Req.RawWebRequest.Method));
      Caminho := Trim(Req.RawWebRequest.PathInfo);
      Auditavel := EhAuditavel(Metodo, Caminho);
      HouveExcecao := False;
      Claims := Default(TJWTClaims);

      Writeln(
        FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
        ' [API] INICIO ' + Metodo + ' ' + Caminho
      );

      if Auditavel then
        ExtrairClaims(Req, Claims);

      try
        try
          Next;
        except
          HouveExcecao := True;
          raise;
        end;
      finally
        StatusCode := Res.RawWebResponse.StatusCode;

        if StatusCode <= 0 then
          StatusCode := 200;

        StatusConsole := StatusCode;
        if HouveExcecao and (StatusConsole < 400) then
          StatusConsole := 500;

        Writeln(
          FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
          ' [API] FIM ' + Metodo + ' ' + Caminho +
          ' -> HTTP ' + IntToStr(StatusConsole)
        );

        if Auditavel then
        begin
          Sucesso :=
            (StatusCode >= 200) and
            (StatusCode < 400) and
            (not HouveExcecao);

          Acao :=
            ResolverAcao(
              Metodo,
              Caminho
            );

          Entidade :=
            ResolverEntidade(
              Caminho
            );

          Mensagem :=
            'HTTP ' +
            IntToStr(StatusCode) +
            ' - operacao auditada sem persistir o corpo da requisicao.';

          TAuditoriaService.TryRegistrarRequest(
            Req,
            Claims,
            Acao,
            Entidade,
            '',
            Mensagem,
            Sucesso
          );
        end;
      end;
    end;
end;

end.
