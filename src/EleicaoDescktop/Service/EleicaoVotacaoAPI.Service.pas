unit EleicaoVotacaoAPI.Service;

interface

Uses  EleicaoAuditoriaAPI.Service,
      WhatsAppConfigAPI.Service,
      WhatsAppConfigAPI.Dao;

type
  TVotacaoResult = record
    Confirmado: string;
    TipoVoto: string;
    Comprovante: string;
  end;

  TEleicaoVotacaoAPIService = class
  private
    class function NormalizarTipoVoto(
      const ATipoVoto: string
    ): string; static;

    class function GerarComprovante: string; static;

  public
    class function RegistrarVoto(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const ATipoVoto: string;
      const AIdChapa: Integer
    ): TVotacaoResult; static;
  end;

var
  MsgWhatsApp: string;
  WhatsConfig: TWhatsAppConfigDados;
implementation

uses
  System.SysUtils,
  System.Hash,
  Uni,
  WhatsApp.Service,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoAPIPublic,
  EleicaoVotacaoAPI.Dao,
  EleicaoComprovantePDF.Service;

{ TEleicaoVotacaoAPIService }

class function TEleicaoVotacaoAPIService.NormalizarTipoVoto(const ATipoVoto: string): string;
begin
  Result := UpperCase(Trim(ATipoVoto));

  if not (
    (Result = 'CHAPA') or
    (Result = 'BRANCO') or
    (Result = 'NULO')
  ) then
    TAppErrors.RaiseBadRequest(
      'Tipo de voto inválido.'
    );
end;

class function TEleicaoVotacaoAPIService.GerarComprovante: string;
var
  G: TGUID;
begin
  CreateGUID(G);

  Result :=
    UpperCase(
      THashSHA2.GetHashString(
        GUIDToString(G)
      )
    );
end;

class function TEleicaoVotacaoAPIService.RegistrarVoto(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const ATipoVoto: string;
  const AIdChapa: Integer
): TVotacaoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  QryEleicao: TUniQuery;

  Contexto: TEleicaoConfirmacaoContexto;

  Slug: string;
  TipoVoto: string;
  Comprovante: string;
  NomeEleicao: string;
  PDFBase64: string;
  NomeArquivoPDF: string;
begin
  Result := Default(TVotacaoResult);

  Slug := Trim(ASlug);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Eleição não informada.'
    );

  if (AIdUsuario <= 0) or
     (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized(
      'Acesso à votação não autorizado.'
    );

  TipoVoto :=
    NormalizarTipoVoto(
      ATipoVoto
    );

  //
  // CHAPA exige uma chapa válida
  //
  if (TipoVoto = 'CHAPA') and
     (AIdChapa <= 0) then
    TAppErrors.RaiseBadRequest(
      'Chapa não informada.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try

    //
    // Valida eleição + usuário + empresa
    //
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn,
      Slug,
      AIdEmpresa,
      AIdUsuario,
      Contexto
    ) then
      TAppErrors.RaiseUnauthorized(
        'Não foi possível acessar esta votação.'
      );

    // Nome da eleição usado somente no comprovante visual.
    NomeEleicao := Slug;
    QryEleicao := TUniQuery.Create(nil);
    try
      QryEleicao.Connection := Conn;
      QryEleicao.SQL.Text :=
        'SELECT nome FROM eleicao ' +
        'WHERE id = :id AND empresa_id = :idempresa LIMIT 1';
      QryEleicao.ParamByName('id').AsInteger := Contexto.IdEleicao;
      QryEleicao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryEleicao.Open;

      if not QryEleicao.IsEmpty then
        NomeEleicao := QryEleicao.FieldByName('nome').AsString;
    finally
      QryEleicao.Free;
    end;

    //
    // Validação da chapa antes de iniciar a gravação
    //
    if TipoVoto = 'CHAPA' then
    begin
      if not TEleicaoVotacaoAPIDao.ChapaValida(
        Conn,
        AIdEmpresa,
        Contexto.IdEleicao,
        AIdChapa
      ) then
        TAppErrors.RaiseBadRequest(
          'Chapa inválida para esta eleição.'
        );
    end;

    //
    // Inicia transação
    //
    Conn.StartTransaction;

    try

      //
      // Impedir voto duplicado
      //
      if TEleicaoVotacaoAPIDao.EleitorJaVotou(
        Conn,
        Contexto.IdEleicao,
        AIdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Seu voto já foi registrado nesta eleição.'
        );

      Comprovante :=
        GerarComprovante;

      //
      // Registrar voto sem usuário
      //
      TEleicaoVotacaoAPIDao.RegistrarVoto(
        Conn,
        AIdEmpresa,
        Contexto.IdEleicao,
        AIdChapa,
        TipoVoto,
        Comprovante
      );

      //
      // Registrar que o usuário já votou
      //
      TEleicaoVotacaoAPIDao.RegistrarVotante(
        Conn,
        AIdEmpresa,
        Contexto.IdEleicao,
        AIdUsuario
      );

      // Auditoria sem identificar o eleitor
      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, AIdEmpresa, Contexto.IdEleicao, 0,
        AUDITORIA_VOTO_REGISTRADO, AUDITORIA_ORIGEM_ELEITOR, True,
        'Voto registrado com sucesso.'
      );

      Conn.Commit;

      Result.Confirmado := 'S';
      Result.TipoVoto := TipoVoto;
      Result.Comprovante := Comprovante;

      //
      // WhatsApp é pós-commit. Qualquer falha aqui não invalida o voto.
      // Envia a mensagem textual já existente e, em seguida, o PDF.
      //
      try
        WhatsConfig := TWhatsAppConfigAPIService.BuscarConfiguracao(AIdEmpresa);

        TWhatsAppService.EnviarComprovanteVotacao(
          WhatsConfig.URL,
          WhatsConfig.Instancia,
          WhatsConfig.Token,
          Contexto.Whatsapp,
          Contexto.Nome,
          Comprovante,
          MsgWhatsApp
        );

        PDFBase64 := TEleicaoComprovantePDFService.GerarBase64(
          NomeEleicao,
          Contexto.Nome,
          Comprovante,
          Now
        );

        NomeArquivoPDF :=
          'comprovante_votacao_' +
          LowerCase(Copy(Comprovante, 1, 12)) +
          '.pdf';

        TWhatsAppService.EnviarDocumentoBase64(
          WhatsConfig.URL,
          WhatsConfig.Instancia,
          WhatsConfig.Token,
          Contexto.Whatsapp,
          PDFBase64,
          NomeArquivoPDF,
          'Comprovante de votação - MoviSystem',
          MsgWhatsApp
        );
      except
        // O voto já foi confirmado.
        // Falha no PDF ou WhatsApp não pode desfazer nem invalidar o voto.
      end;

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
