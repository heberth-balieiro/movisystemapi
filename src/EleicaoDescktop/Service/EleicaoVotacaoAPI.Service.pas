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
    class function EscapePDF(const AValor: string): string; static;
    class function GerarComprovantePDFBase64(
      const AEleicao: string;
      const ANomeEleitor: string;
      const ANomeEmpresa: string;
      const AComprovante: string;
      const ADataHora: TDateTime
    ): string; static;

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
  System.NetEncoding,
  System.Classes,
  Uni,
  WhatsApp.Service,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoAPIPublic,
  EleicaoVotacaoAPI.Dao;

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

class function TEleicaoVotacaoAPIService.EscapePDF(
  const AValor: string): string;
begin
  Result := AValor;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
  Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
end;

class function TEleicaoVotacaoAPIService.GerarComprovantePDFBase64(
  const AEleicao: string;
  const ANomeEleitor: string;
  const ANomeEmpresa: string;
  const AComprovante: string;
  const ADataHora: TDateTime): string;
var
  PDF: string;
  Conteudo: string;
  Offsets: array[1..6] of Integer;
  XRefOffset: Integer;
  I: Integer;
  Codigo1: string;
  Codigo2: string;
  Encoding1252: TEncoding;
  BytesPDF: TBytes;

  procedure AddObject(const ANumero: Integer; const AConteudo: string);
  begin
    Offsets[ANumero] := Length(PDF);
    PDF := PDF + IntToStr(ANumero) + ' 0 obj'#13#10 +
      AConteudo + #13#10'endobj'#13#10;
  end;

begin
  Codigo1 := Copy(Trim(AComprovante), 1, 32);
  Codigo2 := Copy(Trim(AComprovante), 33, MaxInt);

  Conteudo :=
    'q 0.965 g 0 0 540 350 re f Q'#13#10 +
    'q 0.88 g 18 188 504 1 re f Q'#13#10 +
    'q 0.92 g 18 48 504 112 re f Q'#13#10 +
    'BT /F2 12 Tf 26 316 Td (COMPROVANTE DE VOTAÇÃO) Tj ET'#13#10 +
    'BT /F1 10 Tf 26 298 Td (SISTEMA DE VOTAÇÃO DIGITAL) Tj ET'#13#10 +
    'BT /F2 10 Tf 26 268 Td (ELEIÇÃO:) Tj ET'#13#10 +
    'BT /F1 10 Tf 90 268 Td (' + EscapePDF(UpperCase(AEleicao)) + ') Tj ET'#13#10 +
    'BT /F2 10 Tf 26 248 Td (DATA:) Tj ET'#13#10 +
    'BT /F1 10 Tf 65 248 Td (' + EscapePDF(FormatDateTime('dd/mm/yyyy hh:nn', ADataHora)) + ') Tj ET'#13#10 +
    'BT /F2 18 Tf 26 208 Td (' + EscapePDF(UpperCase(ANomeEleitor)) + ') Tj ET'#13#10 +
    'BT /F2 9 Tf 32 137 Td (CÓDIGO DO COMPROVANTE) Tj ET'#13#10 +
    'BT /F1 11 Tf 32 111 Td (' + EscapePDF(Codigo1) + ') Tj ET'#13#10 +
    'BT /F1 11 Tf 32 91 Td (' + EscapePDF(Codigo2) + ') Tj ET'#13#10 +
    'BT /F1 8 Tf 26 26 Td (Este comprovante confirma apenas o registro da participação e não revela a opção escolhida.) Tj ET'#13#10 +
    'BT /F2 8 Tf 385 26 Td (' + EscapePDF(ANomeEmpresa) + ') Tj ET';

  PDF := '%PDF-1.4'#13#10'%Comprovante'#13#10;

  AddObject(1, '<< /Type /Catalog /Pages 2 0 R >>');
  AddObject(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  AddObject(3,
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 540 350] ' +
    '/Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> ' +
    '/Contents 6 0 R >>');
  AddObject(4, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>');
  AddObject(5, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>');
  AddObject(6,
    '<< /Length ' + IntToStr(Length(Conteudo)) + ' >>'#13#10 +
    'stream'#13#10 + Conteudo + #13#10'endstream');

  XRefOffset := Length(PDF);
  PDF := PDF + 'xref'#13#10'0 7'#13#10 +
    '0000000000 65535 f '#13#10;

  for I := 1 to 6 do
    PDF := PDF + Format('%.10d 00000 n ', [Offsets[I]]) + #13#10;

  PDF := PDF +
    'trailer'#13#10 +
    '<< /Size 7 /Root 1 0 R >>'#13#10 +
    'startxref'#13#10 +
    IntToStr(XRefOffset) + #13#10 +
    '%%EOF';

  Encoding1252 := TEncoding.GetEncoding(1252);
  try
    BytesPDF := Encoding1252.GetBytes(PDF);
    Result := TNetEncoding.Base64.EncodeBytesToString(BytesPDF);
  finally
    Encoding1252.Free;
  end;
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
  NomeEmpresa: string;
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

    NomeEleicao := Slug;
    NomeEmpresa := '';
    QryEleicao := TUniQuery.Create(nil);
    try
      QryEleicao.Connection := Conn;
      QryEleicao.SQL.Text :=
        'SELECT e.nome, COALESCE(NULLIF(emp.fantasia, ''''), emp.razao) AS empresa_nome ' +
        'FROM eleicao e ' +
        'INNER JOIN empresa emp ON emp.id = e.empresa_id ' +
        'WHERE e.id = :id AND e.empresa_id = :idempresa LIMIT 1';
      QryEleicao.ParamByName('id').AsInteger := Contexto.IdEleicao;
      QryEleicao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryEleicao.Open;

      if not QryEleicao.IsEmpty then
      begin
        NomeEleicao := QryEleicao.FieldByName('nome').AsString;
        NomeEmpresa := QryEleicao.FieldByName('empresa_nome').AsString;
      end;
    finally
      QryEleicao.Free;
    end;

    if NomeEmpresa.Trim.IsEmpty then
      NomeEmpresa := 'Sistema de Votação Digital';

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

    Conn.StartTransaction;

    try
      if TEleicaoVotacaoAPIDao.EleitorJaVotou(
        Conn,
        Contexto.IdEleicao,
        AIdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Seu voto já foi registrado nesta eleição.'
        );

      Comprovante := GerarComprovante;

      TEleicaoVotacaoAPIDao.RegistrarVoto(
        Conn,
        AIdEmpresa,
        Contexto.IdEleicao,
        AIdChapa,
        TipoVoto,
        Comprovante
      );

      TEleicaoVotacaoAPIDao.RegistrarVotante(
        Conn,
        AIdEmpresa,
        Contexto.IdEleicao,
        AIdUsuario
      );

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, AIdEmpresa, Contexto.IdEleicao, 0,
        AUDITORIA_VOTO_REGISTRADO, AUDITORIA_ORIGEM_ELEITOR, True,
        'Voto registrado com sucesso.'
      );

      Conn.Commit;

      Result.Confirmado := 'S';
      Result.TipoVoto := TipoVoto;
      Result.Comprovante := Comprovante;

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

        PDFBase64 := GerarComprovantePDFBase64(
          NomeEleicao,
          Contexto.Nome,
          NomeEmpresa,
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
          'Comprovante de votação - ' + NomeEmpresa,
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
