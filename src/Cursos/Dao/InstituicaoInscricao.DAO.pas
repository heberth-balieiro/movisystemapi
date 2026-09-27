unit InstituicaoInscricao.DAO;

interface

uses
  Uni,
  InstituicaoInscricao.Model;

type
  TInstituicaoInscricaoDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoInscricaoFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoInscricaoFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoInscricaoItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoInscricaoFiltro
    ): TInstituicaoInscricaoLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TInstituicaoInscricaoItem; static;

    class function ExisteCodigoPublico(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function TurmaExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Boolean; static;

    class function ParticipanteAtivoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): Boolean; static;

    class function ParticipanteJaInscrito(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdParticipante: Int64
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            ACriadoPor: Int64;
      const ACodigoPublico,
            AOrigem: string;
      const ADados: TInstituicaoInscricaoCadastro
    ): Int64; static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao,
            AAtualizadoPor: Int64;
      const ASituacao,
            AMotivoCancelamento: string
    ); static;

    class procedure InserirHistorico(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao,
            AAlteradoPor: Int64;
      const ASituacaoAnterior,
            ASituacaoNova,
            AObservacao: string
    ); static;

    class function ListarHistorico(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TInstituicaoInscricaoHistoricoLista; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoInscricaoDAO.MontarWhere(
  const AFiltro: TInstituicaoInscricaoFiltro
): string;
begin
  Result :=
    ' WHERE i.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result :=
      Result +
      ' AND (' +
      'p.nome LIKE :busca ' +
      'OR p.email LIKE :busca ' +
      'OR p.matricula LIKE :busca ' +
      'OR t.nome LIKE :busca ' +
      'OR c.nome LIKE :busca ' +
      'OR i.codigo_publico LIKE :busca' +
      ') ';

  if AFiltro.IdTurma > 0 then
    Result :=
      Result +
      ' AND i.id_turma = :id_turma ';

  if AFiltro.IdParticipante > 0 then
    Result :=
      Result +
      ' AND i.id_participante = :id_participante ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND i.situacao = :situacao ';

  if not Trim(AFiltro.Origem).IsEmpty then
    Result :=
      Result +
      ' AND i.origem = :origem ';
end;

class procedure TInstituicaoInscricaoDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoInscricaoFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName('id_turma').AsLargeInt :=
      AFiltro.IdTurma;

  if AFiltro.IdParticipante > 0 then
    AQry.ParamByName('id_participante').AsLargeInt :=
      AFiltro.IdParticipante;

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(
        Trim(AFiltro.Situacao)
      );

  if not Trim(AFiltro.Origem).IsEmpty then
    AQry.ParamByName('origem').AsString :=
      UpperCase(
        Trim(AFiltro.Origem)
      );
end;

class function TInstituicaoInscricaoDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoInscricaoItem;
begin
  Result :=
    TInstituicaoInscricaoItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.IdTurma :=
    AQry.FieldByName('id_turma').AsLargeInt;

  Result.IdCurso :=
    AQry.FieldByName('id_curso').AsLargeInt;

  Result.CursoNome :=
    AQry.FieldByName('curso_nome').AsString;

  Result.TurmaNome :=
    AQry.FieldByName('turma_nome').AsString;

  Result.IdParticipante :=
    AQry.FieldByName('id_participante').AsLargeInt;

  Result.ParticipanteNome :=
    AQry.FieldByName('participante_nome').AsString;

  Result.ParticipanteCpfMascarado :=
    AQry.FieldByName('participante_cpf_mascarado').AsString;

  Result.ParticipanteMatricula :=
    AQry.FieldByName('participante_matricula').AsString;

  Result.CodigoPublico :=
    AQry.FieldByName('codigo_publico').AsString;

  Result.Origem :=
    AQry.FieldByName('origem').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.InscritoEm :=
    AQry.FieldByName('inscrito_em').AsDateTime;

  Result.TemConfirmadoEm :=
    not AQry.FieldByName('confirmado_em').IsNull;

  if Result.TemConfirmadoEm then
    Result.ConfirmadoEm :=
      AQry.FieldByName('confirmado_em').AsDateTime;

  Result.TemIniciadoEm :=
    not AQry.FieldByName('iniciado_em').IsNull;

  if Result.TemIniciadoEm then
    Result.IniciadoEm :=
      AQry.FieldByName('iniciado_em').AsDateTime;

  Result.TemConcluidoEm :=
    not AQry.FieldByName('concluido_em').IsNull;

  if Result.TemConcluidoEm then
    Result.ConcluidoEm :=
      AQry.FieldByName('concluido_em').AsDateTime;

  Result.TemCanceladoEm :=
    not AQry.FieldByName('cancelado_em').IsNull;

  if Result.TemCanceladoEm then
    Result.CanceladoEm :=
      AQry.FieldByName('cancelado_em').AsDateTime;

  Result.MotivoCancelamento :=
    AQry.FieldByName('motivo_cancelamento').AsString;

  Result.TemPercentualPresenca :=
    not AQry.FieldByName('percentual_presenca').IsNull;

  if Result.TemPercentualPresenca then
    Result.PercentualPresenca :=
      AQry.FieldByName('percentual_presenca').AsFloat;

  Result.PercentualProgresso :=
    AQry.FieldByName('percentual_progresso').AsFloat;

  Result.TemNotaFinal :=
    not AQry.FieldByName('nota_final').IsNull;

  if Result.TemNotaFinal then
    Result.NotaFinal :=
      AQry.FieldByName('nota_final').AsFloat;

  Result.ElegivelCertificado :=
    AQry.FieldByName('elegivel_certificado').AsBoolean;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoInscricaoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoInscricaoFiltro
): TInstituicaoInscricaoLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TInstituicaoInscricaoLista.Create;

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
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
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
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'i.id, ' +
        'i.id_turma, ' +
        't.id_curso, ' +
        'c.nome AS curso_nome, ' +
        't.nome AS turma_nome, ' +
        'i.id_participante, ' +
        'p.nome AS participante_nome, ' +
        'p.cpf_mascarado AS participante_cpf_mascarado, ' +
        'p.matricula AS participante_matricula, ' +
        'i.codigo_publico, ' +
        'i.origem, ' +
        'i.situacao, ' +
        'i.inscrito_em, ' +
        'i.confirmado_em, ' +
        'i.iniciado_em, ' +
        'i.concluido_em, ' +
        'i.cancelado_em, ' +
        'i.motivo_cancelamento, ' +
        'i.percentual_presenca, ' +
        'i.percentual_progresso, ' +
        'i.nota_final, ' +
        'i.elegivel_certificado, ' +
        'i.criado_em, ' +
        'i.atualizado_em ' +
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
        WhereSQL +
        'ORDER BY i.inscrito_em DESC, i.id DESC ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.ParamByName('limite').AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName('offset').AsInteger :=
        Offset;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(
          MapearItem(Qry)
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

class function TInstituicaoInscricaoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TInstituicaoInscricaoItem;
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
      'i.id, ' +
      'i.id_turma, ' +
      't.id_curso, ' +
      'c.nome AS curso_nome, ' +
      't.nome AS turma_nome, ' +
      'i.id_participante, ' +
      'p.nome AS participante_nome, ' +
      'p.cpf_mascarado AS participante_cpf_mascarado, ' +
      'p.matricula AS participante_matricula, ' +
      'i.codigo_publico, ' +
      'i.origem, ' +
      'i.situacao, ' +
      'i.inscrito_em, ' +
      'i.confirmado_em, ' +
      'i.iniciado_em, ' +
      'i.concluido_em, ' +
      'i.cancelado_em, ' +
      'i.motivo_cancelamento, ' +
      'i.percentual_presenca, ' +
      'i.percentual_progresso, ' +
      'i.nota_final, ' +
      'i.elegivel_certificado, ' +
      'i.criado_em, ' +
      'i.atualizado_em ' +
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
      'WHERE i.id_instituicao = :id_instituicao ' +
      'AND i.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.ExisteCodigoPublico(
  const AConn: TUniConnection;
  const ACodigoPublico: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM inscricao ' +
      'WHERE codigo_publico = :codigo_publico ' +
      'LIMIT 1';

    Qry.ParamByName('codigo_publico').AsString :=
      ACodigoPublico;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.TurmaExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdTurma <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM turma ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdTurma;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.ParticipanteAtivoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if AIdParticipante <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdParticipante;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.ParticipanteJaInscrito(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdParticipante: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id_participante = :id_participante ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_participante').AsLargeInt :=
      AIdParticipante;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        ACriadoPor: Int64;
  const ACodigoPublico,
        AOrigem: string;
  const ADados: TInstituicaoInscricaoCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO inscricao (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_participante, ' +
      'codigo_publico, ' +
      'origem, ' +
      'situacao, ' +
      'criado_por, ' +
      'atualizado_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_participante, ' +
      ':codigo_publico, ' +
      ':origem, ' +
      '''INSCRITO'', ' +
      ':criado_por, ' +
      ':atualizado_por' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      ADados.IdTurma;

    Qry.ParamByName('id_participante').AsLargeInt :=
      ADados.IdParticipante;

    Qry.ParamByName('codigo_publico').AsString :=
      ACodigoPublico;

    Qry.ParamByName('origem').AsString :=
      AOrigem;

    Qry.ParamByName('criado_por').AsLargeInt :=
      ACriadoPor;

    Qry.ParamByName('atualizado_por').AsLargeInt :=
      ACriadoPor;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoInscricaoDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao,
        AAtualizadoPor: Int64;
  const ASituacao,
        AMotivoCancelamento: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE inscricao SET ' +
      'situacao = :situacao, ' +
      'atualizado_por = :atualizado_por ';

    if SameText(ASituacao, 'CONFIRMADO') then
      Qry.SQL.Add(
        ', confirmado_em = COALESCE(confirmado_em, CURRENT_TIMESTAMP(3)) '
      );

    if SameText(ASituacao, 'EM_ANDAMENTO') then
      Qry.SQL.Add(
        ', iniciado_em = COALESCE(iniciado_em, CURRENT_TIMESTAMP(3)) '
      );

    if SameText(ASituacao, 'CONCLUIDO') then
      Qry.SQL.Add(
        ', concluido_em = COALESCE(concluido_em, CURRENT_TIMESTAMP(3)) '
      );

    if SameText(ASituacao, 'CANCELADO') then
    begin
      Qry.SQL.Add(
        ', cancelado_em = CURRENT_TIMESTAMP(3) ' +
        ', motivo_cancelamento = :motivo_cancelamento '
      );
    end;

    Qry.SQL.Add(
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id'
    );

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('atualizado_por').AsLargeInt :=
      AAtualizadoPor;

    if SameText(ASituacao, 'CANCELADO') then
    begin
      if Trim(AMotivoCancelamento).IsEmpty then
        Qry.ParamByName('motivo_cancelamento').Clear
      else
        Qry.ParamByName('motivo_cancelamento').AsString :=
          Trim(AMotivoCancelamento);
    end;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdInscricao;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoInscricaoDAO.InserirHistorico(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao,
        AAlteradoPor: Int64;
  const ASituacaoAnterior,
        ASituacaoNova,
        AObservacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO inscricao_historico (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_inscricao, ' +
      'situacao_anterior, ' +
      'situacao_nova, ' +
      'observacao, ' +
      'alterado_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_inscricao, ' +
      ':situacao_anterior, ' +
      ':situacao_nova, ' +
      ':observacao, ' +
      ':alterado_por' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_inscricao').AsLargeInt :=
      AIdInscricao;

    if Trim(ASituacaoAnterior).IsEmpty then
      Qry.ParamByName('situacao_anterior').Clear
    else
      Qry.ParamByName('situacao_anterior').AsString :=
        ASituacaoAnterior;

    Qry.ParamByName('situacao_nova').AsString :=
      ASituacaoNova;

    if Trim(AObservacao).IsEmpty then
      Qry.ParamByName('observacao').Clear
    else
      Qry.ParamByName('observacao').AsString :=
        Trim(AObservacao);

    if AAlteradoPor > 0 then
      Qry.ParamByName('alterado_por').AsLargeInt :=
        AAlteradoPor
    else
      Qry.ParamByName('alterado_por').Clear;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoDAO.ListarHistorico(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TInstituicaoInscricaoHistoricoLista;
var
  Qry: TUniQuery;
  Item: TInstituicaoInscricaoHistoricoItem;
begin
  Result :=
    TInstituicaoInscricaoHistoricoLista.Create(
      True
    );

  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'h.id, ' +
        'h.situacao_anterior, ' +
        'h.situacao_nova, ' +
        'h.observacao, ' +
        'h.alterado_por, ' +
        'u.nome AS alterado_por_nome, ' +
        'h.criado_em ' +
        'FROM inscricao_historico h ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = h.id_instituicao ' +
        ' AND ui.id = h.alterado_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        'WHERE h.id_instituicao = :id_instituicao ' +
        'AND h.id_inscricao = :id_inscricao ' +
        'ORDER BY h.criado_em DESC, h.id DESC';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_inscricao').AsLargeInt :=
        AIdInscricao;

      Qry.Open;

      while not Qry.Eof do
      begin
        Item :=
          TInstituicaoInscricaoHistoricoItem.Create;

        Item.Id :=
          Qry.FieldByName('id').AsLargeInt;

        Item.TemSituacaoAnterior :=
          not Qry.FieldByName(
            'situacao_anterior'
          ).IsNull;

        if Item.TemSituacaoAnterior then
          Item.SituacaoAnterior :=
            Qry.FieldByName(
              'situacao_anterior'
            ).AsString;

        Item.SituacaoNova :=
          Qry.FieldByName(
            'situacao_nova'
          ).AsString;

        Item.Observacao :=
          Qry.FieldByName(
            'observacao'
          ).AsString;

        Item.TemAlteradoPor :=
          not Qry.FieldByName(
            'alterado_por'
          ).IsNull;

        if Item.TemAlteradoPor then
          Item.AlteradoPor :=
            Qry.FieldByName(
              'alterado_por'
            ).AsLargeInt;

        Item.AlteradoPorNome :=
          Qry.FieldByName(
            'alterado_por_nome'
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

end.
