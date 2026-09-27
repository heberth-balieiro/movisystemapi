unit InstituicaoCertificado.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoCertificado.Model;

type
  TInstituicaoCertificadoDAO = class
  private
    class function MontarWhere(
      const AFiltro: TCertificadoFiltro
    ): string; static;

    class procedure AplicarFiltro(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TCertificadoFiltro
    ); static;

    class function MapearCertificado(
      const AQry: TUniQuery
    ): TCertificadoItem; static;

  public
    class function ObterConfiguracao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TCertificadoConfiguracao; static;

    class procedure SalvarConfiguracao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AConfig: TCertificadoConfiguracao
    ); static;

    class function ModeloAtivoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64
    ): Boolean; static;

    class function BuscarContextoEmissao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TCertificadoEmissaoContexto; static;

    class function ExisteCertificadoParaInscricao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): Boolean; static;

    class function ProximaVersao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): Integer; static;

    class function ProximoSequencial(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AAno: Integer
    ): Int64; static;

    class function ExisteCodigoValidacao(
      const AConn: TUniConnection;
      const ACodigoValidacao: string
    ): Boolean; static;

    class function InserirPendente(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo,
            AIdCertificadoOrigem,
            AEmitidoPor: Int64;
      const ATemIdCertificadoOrigem: Boolean;
      const ANumeroPublico,
            ACodigoValidacao,
            AMotivoReemissao: string;
      const AVersao: Integer;
      const AContexto: TCertificadoEmissaoContexto
    ): Int64; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoItem; static;

    class function BuscarPublicoPorCodigo(
      const AConn: TUniConnection;
      const ACodigoValidacao: string
    ): TCertificadoItem; static;

    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TCertificadoFiltro
    ): TCertificadoLista; static;

    class procedure FinalizarPdf(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado,
            AEmitidoPor: Int64;
      const APdf: TCertificadoPdfFinalizacao
    ); static;

    class procedure Cancelar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64;
      const AMotivo: string
    ); static;

    class procedure InserirHistorico(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64;
      const AEvento,
            ADescricao,
            ADadosJson: string
    ); static;

    class function ListarHistorico(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoHistoricoLista; static;

    class procedure RegistrarValidacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64;
      const ATemCertificado: Boolean;
      const ACodigoHash,
            AResultado,
            AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoCertificadoDAO.MontarWhere(
  const AFiltro: TCertificadoFiltro
): string;
begin
  Result :=
    ' WHERE c.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result :=
      Result +
      ' AND (' +
      'c.numero_publico LIKE :busca ' +
      'OR c.participante_nome LIKE :busca ' +
      'OR c.curso_nome LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND c.situacao = :situacao ';

  if AFiltro.IdTurma > 0 then
    Result :=
      Result +
      ' AND c.id_turma = :id_turma ';

  if AFiltro.IdParticipante > 0 then
    Result :=
      Result +
      ' AND c.id_participante = :id_participante ';
end;

class procedure TInstituicaoCertificadoDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TCertificadoFiltro
);
begin
  AQry.ParamByName(
    'id_instituicao'
  ).AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName(
      'busca'
    ).AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName(
      'situacao'
    ).AsString :=
      UpperCase(
        Trim(AFiltro.Situacao)
      );

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AFiltro.IdTurma;

  if AFiltro.IdParticipante > 0 then
    AQry.ParamByName(
      'id_participante'
    ).AsLargeInt :=
      AFiltro.IdParticipante;
end;

class function TInstituicaoCertificadoDAO.MapearCertificado(
  const AQry: TUniQuery
): TCertificadoItem;
begin
  Result :=
    TCertificadoItem.Create;

  Result.Id :=
    AQry.FieldByName(
      'id'
    ).AsLargeInt;

  Result.IdInstituicao :=
    AQry.FieldByName(
      'id_instituicao'
    ).AsLargeInt;

  Result.IdInscricao :=
    AQry.FieldByName(
      'id_inscricao'
    ).AsLargeInt;

  Result.IdTurma :=
    AQry.FieldByName(
      'id_turma'
    ).AsLargeInt;

  Result.IdParticipante :=
    AQry.FieldByName(
      'id_participante'
    ).AsLargeInt;

  Result.IdCurso :=
    AQry.FieldByName(
      'id_curso'
    ).AsLargeInt;

  Result.TemIdModelo :=
    not AQry.FieldByName(
      'id_modelo'
    ).IsNull;

  if Result.TemIdModelo then
    Result.IdModelo :=
      AQry.FieldByName(
        'id_modelo'
      ).AsLargeInt;

  Result.ModeloNome :=
    AQry.FieldByName(
      'modelo_nome'
    ).AsString;

  Result.TemIdCertificadoOrigem :=
    not AQry.FieldByName(
      'id_certificado_origem'
    ).IsNull;

  if Result.TemIdCertificadoOrigem then
    Result.IdCertificadoOrigem :=
      AQry.FieldByName(
        'id_certificado_origem'
      ).AsLargeInt;

  Result.NumeroPublico :=
    AQry.FieldByName(
      'numero_publico'
    ).AsString;

  Result.CodigoValidacao :=
    AQry.FieldByName(
      'codigo_validacao'
    ).AsString;

  Result.Versao :=
    AQry.FieldByName(
      'versao'
    ).AsInteger;

  Result.Situacao :=
    AQry.FieldByName(
      'situacao'
    ).AsString;

  Result.TemEmitidoEm :=
    not AQry.FieldByName(
      'emitido_em'
    ).IsNull;

  if Result.TemEmitidoEm then
    Result.EmitidoEm :=
      AQry.FieldByName(
        'emitido_em'
      ).AsDateTime;

  Result.TemCanceladoEm :=
    not AQry.FieldByName(
      'cancelado_em'
    ).IsNull;

  if Result.TemCanceladoEm then
    Result.CanceladoEm :=
      AQry.FieldByName(
        'cancelado_em'
      ).AsDateTime;

  Result.MotivoCancelamento :=
    AQry.FieldByName(
      'motivo_cancelamento'
    ).AsString;

  Result.MotivoReemissao :=
    AQry.FieldByName(
      'motivo_reemissao'
    ).AsString;

  Result.ParticipanteNome :=
    AQry.FieldByName(
      'participante_nome'
    ).AsString;

  Result.CursoNome :=
    AQry.FieldByName(
      'curso_nome'
    ).AsString;

  Result.InstituicaoNome :=
    AQry.FieldByName(
      'instituicao_nome'
    ).AsString;

  Result.CargaHorariaMinutos :=
    AQry.FieldByName(
      'carga_horaria_minutos'
    ).AsInteger;

  Result.DataConclusao :=
    AQry.FieldByName(
      'data_conclusao'
    ).AsDateTime;

  Result.PdfStorageKey :=
    AQry.FieldByName(
      'pdf_storage_key'
    ).AsString;

  Result.PdfSha256 :=
    AQry.FieldByName(
      'pdf_sha256'
    ).AsString;

  Result.TemPdfTamanhoBytes :=
    not AQry.FieldByName(
      'pdf_tamanho_bytes'
    ).IsNull;

  if Result.TemPdfTamanhoBytes then
    Result.PdfTamanhoBytes :=
      AQry.FieldByName(
        'pdf_tamanho_bytes'
      ).AsLargeInt;

  Result.TemPdfGeradoEm :=
    not AQry.FieldByName(
      'pdf_gerado_em'
    ).IsNull;

  if Result.TemPdfGeradoEm then
    Result.PdfGeradoEm :=
      AQry.FieldByName(
        'pdf_gerado_em'
      ).AsDateTime;

  Result.TemEmitidoPor :=
    not AQry.FieldByName(
      'emitido_por'
    ).IsNull;

  if Result.TemEmitidoPor then
    Result.EmitidoPor :=
      AQry.FieldByName(
        'emitido_por'
      ).AsLargeInt;

  Result.EmitidoPorNome :=
    AQry.FieldByName(
      'emitido_por_nome'
    ).AsString;

  Result.CriadoEm :=
    AQry.FieldByName(
      'criado_em'
    ).AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName(
      'atualizado_em'
    ).AsDateTime;
end;

class function TInstituicaoCertificadoDAO.ObterConfiguracao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TCertificadoConfiguracao;
var
  Qry: TUniQuery;
begin
  Result :=
    TCertificadoConfiguracao.Create;

  Result.Existe := False;
  Result.TemIdModeloPadrao := False;
  Result.Prefixo := 'CERT';
  Result.UsarAno := True;
  Result.DigitosSequencia := 6;
  Result.TextoValidacao := 'Valide este certificado';

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'id_modelo_padrao, ' +
      'prefixo, ' +
      'usar_ano, ' +
      'digitos_sequencia, ' +
      'texto_validacao ' +
      'FROM certificado_configuracao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Existe := True;

    Result.TemIdModeloPadrao :=
      not Qry.FieldByName(
        'id_modelo_padrao'
      ).IsNull;

    if Result.TemIdModeloPadrao then
      Result.IdModeloPadrao :=
        Qry.FieldByName(
          'id_modelo_padrao'
        ).AsLargeInt;

    Result.Prefixo :=
      Qry.FieldByName(
        'prefixo'
      ).AsString;

    Result.UsarAno :=
      Qry.FieldByName(
        'usar_ano'
      ).AsBoolean;

    Result.DigitosSequencia :=
      Qry.FieldByName(
        'digitos_sequencia'
      ).AsInteger;

    Result.TextoValidacao :=
      Qry.FieldByName(
        'texto_validacao'
      ).AsString;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoDAO.SalvarConfiguracao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AConfig: TCertificadoConfiguracao
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado_configuracao (' +
      'id_instituicao, ' +
      'id_modelo_padrao, ' +
      'prefixo, ' +
      'usar_ano, ' +
      'digitos_sequencia, ' +
      'texto_validacao' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_modelo_padrao, ' +
      ':prefixo, ' +
      ':usar_ano, ' +
      ':digitos_sequencia, ' +
      ':texto_validacao' +
      ') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'id_modelo_padrao = VALUES(id_modelo_padrao), ' +
      'prefixo = VALUES(prefixo), ' +
      'usar_ano = VALUES(usar_ano), ' +
      'digitos_sequencia = VALUES(digitos_sequencia), ' +
      'texto_validacao = VALUES(texto_validacao)';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    if AConfig.TemIdModeloPadrao then
      Qry.ParamByName(
        'id_modelo_padrao'
      ).AsLargeInt :=
        AConfig.IdModeloPadrao
    else
      Qry.ParamByName(
        'id_modelo_padrao'
      ).Clear;

    if Trim(AConfig.Prefixo).IsEmpty then
      Qry.ParamByName(
        'prefixo'
      ).Clear
    else
      Qry.ParamByName(
        'prefixo'
      ).AsString :=
        Trim(
          AConfig.Prefixo
        );

    Qry.ParamByName(
      'usar_ano'
    ).AsBoolean :=
      AConfig.UsarAno;

    Qry.ParamByName(
      'digitos_sequencia'
    ).AsInteger :=
      AConfig.DigitosSequencia;

    Qry.ParamByName(
      'texto_validacao'
    ).AsString :=
      Trim(
        AConfig.TextoValidacao
      );

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ModeloAtivoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdModelo <= 0 then
    Exit;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado_modelo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_modelo ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_modelo'
    ).AsLargeInt :=
      AIdModelo;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.BuscarContextoEmissao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TCertificadoEmissaoContexto;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'i.id AS id_inscricao, ' +
      'i.id_turma, ' +
      'i.id_participante, ' +
      't.id_curso, ' +
      't.id_modelo_certificado, ' +
      'p.nome AS participante_nome, ' +
      'c.nome AS curso_nome, ' +
      'inst.nome AS instituicao_nome, ' +
      'COALESCE(t.carga_horaria_minutos, c.carga_horaria_minutos) AS carga_horaria_minutos, ' +
      'i.concluido_em, ' +
      'i.situacao AS situacao_inscricao, ' +
      'i.elegivel_certificado ' +
      'FROM inscricao i ' +
      'INNER JOIN turma t ' +
      '  ON t.id_instituicao = i.id_instituicao ' +
      ' AND t.id = i.id_turma ' +
      'INNER JOIN curso c ' +
      '  ON c.id_instituicao = t.id_instituicao ' +
      ' AND c.id = t.id_curso ' +
      'INNER JOIN participante p ' +
      '  ON p.id_instituicao = i.id_instituicao ' +
      ' AND p.id = i.id_participante ' +
      'INNER JOIN instituicao inst ' +
      '  ON inst.id = i.id_instituicao ' +
      'WHERE i.id_instituicao = :id_instituicao ' +
      'AND i.id = :id_inscricao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result :=
      TCertificadoEmissaoContexto.Create;

    Result.IdInscricao :=
      Qry.FieldByName(
        'id_inscricao'
      ).AsLargeInt;

    Result.IdTurma :=
      Qry.FieldByName(
        'id_turma'
      ).AsLargeInt;

    Result.IdParticipante :=
      Qry.FieldByName(
        'id_participante'
      ).AsLargeInt;

    Result.IdCurso :=
      Qry.FieldByName(
        'id_curso'
      ).AsLargeInt;

    Result.TemIdModeloTurma :=
      not Qry.FieldByName(
        'id_modelo_certificado'
      ).IsNull;

    if Result.TemIdModeloTurma then
      Result.IdModeloTurma :=
        Qry.FieldByName(
          'id_modelo_certificado'
        ).AsLargeInt;

    Result.ParticipanteNome :=
      Qry.FieldByName(
        'participante_nome'
      ).AsString;

    Result.CursoNome :=
      Qry.FieldByName(
        'curso_nome'
      ).AsString;

    Result.InstituicaoNome :=
      Qry.FieldByName(
        'instituicao_nome'
      ).AsString;

    Result.CargaHorariaMinutos :=
      Qry.FieldByName(
        'carga_horaria_minutos'
      ).AsInteger;

    Result.TemDataConclusao :=
      not Qry.FieldByName(
        'concluido_em'
      ).IsNull;

    if Result.TemDataConclusao then
      Result.DataConclusao :=
        Qry.FieldByName(
          'concluido_em'
        ).AsDateTime;

    Result.SituacaoInscricao :=
      Qry.FieldByName(
        'situacao_inscricao'
      ).AsString;

    Result.ElegivelCertificado :=
      Qry.FieldByName(
        'elegivel_certificado'
      ).AsBoolean;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ExisteCertificadoParaInscricao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_inscricao = :id_inscricao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ProximaVersao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): Integer;
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT COALESCE(MAX(versao), 0) + 1 AS proxima ' +
      'FROM certificado ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_inscricao = :id_inscricao';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    Result :=
      Qry.FieldByName(
        'proxima'
      ).AsInteger;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ProximoSequencial(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AAno: Integer
): Int64;
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado_sequencia (' +
      'id_instituicao, ano, ultimo_numero' +
      ') VALUES (' +
      ':id_instituicao, :ano, 0' +
      ') ON DUPLICATE KEY UPDATE ' +
      'ultimo_numero = ultimo_numero';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'ano'
    ).AsInteger :=
      AAno;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT ultimo_numero ' +
      'FROM certificado_sequencia ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND ano = :ano ' +
      'FOR UPDATE';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'ano'
    ).AsInteger :=
      AAno;

    Qry.Open;

    Result :=
      Qry.FieldByName(
        'ultimo_numero'
      ).AsLargeInt +
      1;

    Qry.Close;

    Qry.SQL.Text :=
      'UPDATE certificado_sequencia SET ' +
      'ultimo_numero = :ultimo_numero ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND ano = :ano';

    Qry.ParamByName(
      'ultimo_numero'
    ).AsLargeInt :=
      Result;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'ano'
    ).AsInteger :=
      AAno;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ExisteCodigoValidacao(
  const AConn: TUniConnection;
  const ACodigoValidacao: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado ' +
      'WHERE codigo_validacao = :codigo_validacao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'codigo_validacao'
    ).AsString :=
      ACodigoValidacao;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.InserirPendente(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo,
        AIdCertificadoOrigem,
        AEmitidoPor: Int64;
  const ATemIdCertificadoOrigem: Boolean;
  const ANumeroPublico,
        ACodigoValidacao,
        AMotivoReemissao: string;
  const AVersao: Integer;
  const AContexto: TCertificadoEmissaoContexto
): Int64;
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado (' +
      'id_instituicao, ' +
      'id_inscricao, ' +
      'id_turma, ' +
      'id_participante, ' +
      'id_curso, ' +
      'id_modelo, ' +
      'id_certificado_origem, ' +
      'numero_publico, ' +
      'codigo_validacao, ' +
      'versao, ' +
      'situacao, ' +
      'motivo_reemissao, ' +
      'participante_nome, ' +
      'curso_nome, ' +
      'instituicao_nome, ' +
      'carga_horaria_minutos, ' +
      'data_conclusao, ' +
      'emitido_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_inscricao, ' +
      ':id_turma, ' +
      ':id_participante, ' +
      ':id_curso, ' +
      ':id_modelo, ' +
      ':id_certificado_origem, ' +
      ':numero_publico, ' +
      ':codigo_validacao, ' +
      ':versao, ' +
      '''PENDENTE'', ' +
      ':motivo_reemissao, ' +
      ':participante_nome, ' +
      ':curso_nome, ' +
      ':instituicao_nome, ' +
      ':carga_horaria_minutos, ' +
      ':data_conclusao, ' +
      ':emitido_por' +
      ')';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AContexto.IdInscricao;

    Qry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AContexto.IdTurma;

    Qry.ParamByName(
      'id_participante'
    ).AsLargeInt :=
      AContexto.IdParticipante;

    Qry.ParamByName(
      'id_curso'
    ).AsLargeInt :=
      AContexto.IdCurso;

    Qry.ParamByName(
      'id_modelo'
    ).AsLargeInt :=
      AIdModelo;

    if ATemIdCertificadoOrigem then
      Qry.ParamByName(
        'id_certificado_origem'
      ).AsLargeInt :=
        AIdCertificadoOrigem
    else
      Qry.ParamByName(
        'id_certificado_origem'
      ).Clear;

    Qry.ParamByName(
      'numero_publico'
    ).AsString :=
      ANumeroPublico;

    Qry.ParamByName(
      'codigo_validacao'
    ).AsString :=
      ACodigoValidacao;

    Qry.ParamByName(
      'versao'
    ).AsInteger :=
      AVersao;

    if Trim(AMotivoReemissao).IsEmpty then
      Qry.ParamByName(
        'motivo_reemissao'
      ).Clear
    else
      Qry.ParamByName(
        'motivo_reemissao'
      ).AsString :=
        Trim(
          AMotivoReemissao
        );

    Qry.ParamByName(
      'participante_nome'
    ).AsString :=
      AContexto.ParticipanteNome;

    Qry.ParamByName(
      'curso_nome'
    ).AsString :=
      AContexto.CursoNome;

    Qry.ParamByName(
      'instituicao_nome'
    ).AsString :=
      AContexto.InstituicaoNome;

    Qry.ParamByName(
      'carga_horaria_minutos'
    ).AsInteger :=
      AContexto.CargaHorariaMinutos;

    Qry.ParamByName(
      'data_conclusao'
    ).AsDateTime :=
      AContexto.DataConclusao;

    Qry.ParamByName(
      'emitido_por'
    ).AsLargeInt :=
      AEmitidoPor;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName(
        'id'
      ).AsLargeInt;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'c.*, ' +
      'm.nome AS modelo_nome, ' +
      'u.nome AS emitido_por_nome ' +
      'FROM certificado c ' +
      'LEFT JOIN certificado_modelo m ' +
      '  ON m.id_instituicao = c.id_instituicao ' +
      ' AND m.id = c.id_modelo ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = c.id_instituicao ' +
      ' AND ui.id = c.emitido_por ' +
      'LEFT JOIN usuario u ' +
      '  ON u.id = ui.id_usuario ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdCertificado;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearCertificado(
          Qry
        );

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.BuscarPublicoPorCodigo(
  const AConn: TUniConnection;
  const ACodigoValidacao: string
): TCertificadoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'c.*, ' +
      'm.nome AS modelo_nome, ' +
      'u.nome AS emitido_por_nome ' +
      'FROM certificado c ' +
      'LEFT JOIN certificado_modelo m ' +
      '  ON m.id_instituicao = c.id_instituicao ' +
      ' AND m.id = c.id_modelo ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = c.id_instituicao ' +
      ' AND ui.id = c.emitido_por ' +
      'LEFT JOIN usuario u ' +
      '  ON u.id = ui.id_usuario ' +
      'WHERE c.codigo_validacao = :codigo_validacao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'codigo_validacao'
    ).AsString :=
      ACodigoValidacao;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearCertificado(
          Qry
        );

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TCertificadoFiltro
): TCertificadoLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TCertificadoLista.Create;

  Qry :=
    TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina :=
        AFiltro.Pagina;

      Result.PorPagina :=
        AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(
          AFiltro
        );

      Offset :=
        (
          AFiltro.Pagina -
          1
        ) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM certificado c ' +
        WhereSQL;

      AplicarFiltro(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName(
          'total'
        ).AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'c.*, ' +
        'm.nome AS modelo_nome, ' +
        'u.nome AS emitido_por_nome ' +
        'FROM certificado c ' +
        'LEFT JOIN certificado_modelo m ' +
        '  ON m.id_instituicao = c.id_instituicao ' +
        ' AND m.id = c.id_modelo ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = c.id_instituicao ' +
        ' AND ui.id = c.emitido_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY c.criado_em DESC, c.id DESC ' +
        'LIMIT :limite OFFSET :offset';

      AplicarFiltro(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.ParamByName(
        'limite'
      ).AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName(
        'offset'
      ).AsInteger :=
        Offset;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(
          MapearCertificado(
            Qry
          )
        );

        Qry.Next;
      end;

    except
      Result.Free;
      raise;
    end;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoDAO.FinalizarPdf(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado,
        AEmitidoPor: Int64;
  const APdf: TCertificadoPdfFinalizacao
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE certificado SET ' +
      'situacao = ''VALIDO'', ' +
      'emitido_em = CURRENT_TIMESTAMP(3), ' +
      'pdf_storage_key = :pdf_storage_key, ' +
      'pdf_sha256 = :pdf_sha256, ' +
      'pdf_tamanho_bytes = :pdf_tamanho_bytes, ' +
      'pdf_gerado_em = CURRENT_TIMESTAMP(3), ' +
      'emitido_por = :emitido_por ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName(
      'pdf_storage_key'
    ).AsString :=
      Trim(
        APdf.PdfStorageKey
      );

    Qry.ParamByName(
      'pdf_sha256'
    ).AsString :=
      LowerCase(
        Trim(
          APdf.PdfSha256
        )
      );

    Qry.ParamByName(
      'pdf_tamanho_bytes'
    ).AsLargeInt :=
      APdf.PdfTamanhoBytes;

    Qry.ParamByName(
      'emitido_por'
    ).AsLargeInt :=
      AEmitidoPor;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdCertificado;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoDAO.Cancelar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64;
  const AMotivo: string
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE certificado SET ' +
      'situacao = ''CANCELADO'', ' +
      'cancelado_em = CURRENT_TIMESTAMP(3), ' +
      'motivo_cancelamento = :motivo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName(
      'motivo'
    ).AsString :=
      Trim(
        AMotivo
      );

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id'
    ).AsLargeInt :=
      AIdCertificado;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoDAO.InserirHistorico(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64;
  const AEvento,
        ADescricao,
        ADadosJson: string
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado_historico (' +
      'id_instituicao, ' +
      'id_certificado, ' +
      'evento, ' +
      'descricao, ' +
      'dados, ' +
      'id_usuario_instituicao' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_certificado, ' +
      ':evento, ' +
      ':descricao, ' +
      ':dados, ' +
      ':id_usuario_instituicao' +
      ')';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_certificado'
    ).AsLargeInt :=
      AIdCertificado;

    Qry.ParamByName(
      'evento'
    ).AsString :=
      AEvento;

    if Trim(ADescricao).IsEmpty then
      Qry.ParamByName(
        'descricao'
      ).Clear
    else
      Qry.ParamByName(
        'descricao'
      ).AsString :=
        Trim(
          ADescricao
        );

    if Trim(ADadosJson).IsEmpty then
      Qry.ParamByName(
        'dados'
      ).Clear
    else
      Qry.ParamByName(
        'dados'
      ).AsString :=
        ADadosJson;

    if AUsuarioInstituicao > 0 then
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).AsLargeInt :=
        AUsuarioInstituicao
    else
      Qry.ParamByName(
        'id_usuario_instituicao'
      ).Clear;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoDAO.ListarHistorico(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoHistoricoLista;
var
  Qry: TUniQuery;
  Item: TCertificadoHistoricoItem;
begin
  Result :=
    TCertificadoHistoricoLista.Create(
      True
    );

  Qry :=
    TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'h.id, ' +
        'h.evento, ' +
        'h.descricao, ' +
        'h.dados, ' +
        'h.id_usuario_instituicao, ' +
        'u.nome AS usuario_nome, ' +
        'h.criado_em ' +
        'FROM certificado_historico h ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = h.id_instituicao ' +
        ' AND ui.id = h.id_usuario_instituicao ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        'WHERE h.id_instituicao = :id_instituicao ' +
        'AND h.id_certificado = :id_certificado ' +
        'ORDER BY h.criado_em DESC, h.id DESC';

      Qry.ParamByName(
        'id_instituicao'
      ).AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName(
        'id_certificado'
      ).AsLargeInt :=
        AIdCertificado;

      Qry.Open;

      while not Qry.Eof do
      begin
        Item :=
          TCertificadoHistoricoItem.Create;

        Item.Id :=
          Qry.FieldByName(
            'id'
          ).AsLargeInt;

        Item.Evento :=
          Qry.FieldByName(
            'evento'
          ).AsString;

        Item.Descricao :=
          Qry.FieldByName(
            'descricao'
          ).AsString;

        Item.Dados :=
          Qry.FieldByName(
            'dados'
          ).AsString;

        Item.TemIdUsuarioInstituicao :=
          not Qry.FieldByName(
            'id_usuario_instituicao'
          ).IsNull;

        if Item.TemIdUsuarioInstituicao then
          Item.IdUsuarioInstituicao :=
            Qry.FieldByName(
              'id_usuario_instituicao'
            ).AsLargeInt;

        Item.UsuarioNome :=
          Qry.FieldByName(
            'usuario_nome'
          ).AsString;

        Item.CriadoEm :=
          Qry.FieldByName(
            'criado_em'
          ).AsDateTime;

        Result.Add(
          Item
        );

        Qry.Next;
      end;

    except
      Result.Free;
      raise;
    end;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoDAO.RegistrarValidacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64;
  const ATemCertificado: Boolean;
  const ACodigoHash,
        AResultado,
        AIP,
        AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado_validacao_acesso (' +
      'id_instituicao, ' +
      'id_certificado, ' +
      'codigo_consultado_hash, ' +
      'resultado, ' +
      'ip, ' +
      'user_agent' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_certificado, ' +
      ':codigo_hash, ' +
      ':resultado, ' +
      ':ip, ' +
      ':user_agent' +
      ')';

    if ATemCertificado then
    begin
      Qry.ParamByName(
        'id_instituicao'
      ).AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName(
        'id_certificado'
      ).AsLargeInt :=
        AIdCertificado;
    end
    else
    begin
      Qry.ParamByName(
        'id_instituicao'
      ).Clear;

      Qry.ParamByName(
        'id_certificado'
      ).Clear;
    end;

    if Trim(ACodigoHash).IsEmpty then
      Qry.ParamByName(
        'codigo_hash'
      ).Clear
    else
      Qry.ParamByName(
        'codigo_hash'
      ).AsString :=
        ACodigoHash;

    Qry.ParamByName(
      'resultado'
    ).AsString :=
      AResultado;

    if Trim(AIP).IsEmpty then
      Qry.ParamByName(
        'ip'
      ).Clear
    else
      Qry.ParamByName(
        'ip'
      ).AsString :=
        Copy(
          Trim(AIP),
          1,
          45
        );

    if Trim(AUserAgent).IsEmpty then
      Qry.ParamByName(
        'user_agent'
      ).Clear
    else
      Qry.ParamByName(
        'user_agent'
      ).AsString :=
        Copy(
          Trim(AUserAgent),
          1,
          1000
        );

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
