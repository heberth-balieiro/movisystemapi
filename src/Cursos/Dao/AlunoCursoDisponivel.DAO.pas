unit AlunoCursoDisponivel.DAO;

interface

uses
  Uni,
  AlunoPortal.Model,
  AlunoCursoDisponivel.Model;

type
  TAlunoCursoDisponivelDAO = class
  private
    class function MapearItem(
      const AQry: TUniQuery
    ): TAlunoCursoDisponivelItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const APagina,
            APorPagina: Integer
    ): TAlunoCursoDisponivelLista; static;

    class function Buscar(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdTurma: Int64
    ): TAlunoCursoDisponivelItem; static;

    class function BloquearTurmaDisponivel(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TAlunoCursoDisponivelDAO.MapearItem(
  const AQry: TUniQuery
): TAlunoCursoDisponivelItem;
var
  Limite: Integer;
  Ocupados: Integer;
begin
  Result := TAlunoCursoDisponivelItem.Create;

  Result.IdTurma := AQry.FieldByName('id_turma').AsLargeInt;
  Result.CodigoTurma := AQry.FieldByName('codigo_turma').AsString;
  Result.TurmaNome := AQry.FieldByName('turma_nome').AsString;
  Result.IdCurso := AQry.FieldByName('id_curso').AsLargeInt;
  Result.CodigoCurso := AQry.FieldByName('codigo_curso').AsString;
  Result.CursoNome := AQry.FieldByName('curso_nome').AsString;
  Result.CursoDescricao := AQry.FieldByName('curso_descricao').AsString;
  Result.CursoObjetivo := AQry.FieldByName('curso_objetivo').AsString;
  Result.Modalidade := AQry.FieldByName('modalidade').AsString;
  Result.ImagemUrl := AQry.FieldByName('imagem_url').AsString;
  Result.DataHoraInicio := AQry.FieldByName('data_hora_inicio').AsDateTime;
  Result.DataHoraFim := AQry.FieldByName('data_hora_fim').AsDateTime;

  Result.TemInscricaoInicio := not AQry.FieldByName('inscricao_inicio').IsNull;
  if Result.TemInscricaoInicio then
    Result.InscricaoInicio := AQry.FieldByName('inscricao_inicio').AsDateTime;

  Result.TemInscricaoFim := not AQry.FieldByName('inscricao_fim').IsNull;
  if Result.TemInscricaoFim then
    Result.InscricaoFim := AQry.FieldByName('inscricao_fim').AsDateTime;

  Result.TemLimiteParticipantes := not AQry.FieldByName('limite_participantes').IsNull;
  if Result.TemLimiteParticipantes then
  begin
    Limite := AQry.FieldByName('limite_participantes').AsInteger;
    Ocupados := AQry.FieldByName('inscritos_confirmados').AsInteger;

    Result.LimiteParticipantes := Limite;
    Result.InscritosConfirmados := Ocupados;
    Result.TemVagasDisponiveis := True;

    Result.VagasDisponiveis := Limite - Ocupados;
    if Result.VagasDisponiveis < 0 then
      Result.VagasDisponiveis := 0;
  end
  else
  begin
    Result.InscritosConfirmados := AQry.FieldByName('inscritos_confirmados').AsInteger;
    Result.TemVagasDisponiveis := False;
  end;

  Result.Local := AQry.FieldByName('local').AsString;
  Result.CargaHorariaMinutos := AQry.FieldByName('carga_horaria_minutos').AsInteger;

  Result.TemIdInscricao := not AQry.FieldByName('id_inscricao').IsNull;
  Result.JaInscrito := Result.TemIdInscricao;

  if Result.TemIdInscricao then
  begin
    Result.IdInscricao := AQry.FieldByName('id_inscricao').AsLargeInt;
    Result.SituacaoInscricao := AQry.FieldByName('situacao_inscricao').AsString;
  end;
end;

class function TAlunoCursoDisponivelDAO.Listar(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const APagina,
        APorPagina: Integer
): TAlunoCursoDisponivelLista;
var
  Qry: TUniQuery;
  Offset: Integer;
begin
  Result := TAlunoCursoDisponivelLista.Create;
  Result.Pagina := APagina;
  Result.PorPagina := APorPagina;
  Offset := (APagina - 1) * APorPagina;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM turma t ' +
        'INNER JOIN curso c ' +
        '  ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'WHERE t.id_instituicao = :id_instituicao ' +
        'AND c.situacao = ''ATIVO'' ' +
        'AND c.permitir_inscricao_publica = 1 ' +
        'AND t.situacao = ''INSCRICOES_ABERTAS'' ' +
        'AND t.permitir_inscricao_publica = 1 ' +
        'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio <= CURRENT_TIMESTAMP(3)) ' +
        'AND (t.inscricao_fim IS NULL OR t.inscricao_fim >= CURRENT_TIMESTAMP(3)) ' +
        'AND t.data_hora_fim >= CURRENT_TIMESTAMP(3)';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        't.id AS id_turma, t.codigo_publico AS codigo_turma, t.nome AS turma_nome, ' +
        'c.id AS id_curso, c.codigo_publico AS codigo_curso, c.nome AS curso_nome, ' +
        'c.descricao AS curso_descricao, c.objetivo AS curso_objetivo, ' +
        't.modalidade, c.imagem_url, t.data_hora_inicio, t.data_hora_fim, ' +
        't.inscricao_inicio, t.inscricao_fim, t.limite_participantes, t.local, ' +
        'COALESCE(t.carga_horaria_minutos, c.carga_horaria_minutos) AS carga_horaria_minutos, ' +
        '(SELECT COUNT(*) FROM inscricao io ' +
        '  WHERE io.id_instituicao = t.id_instituicao AND io.id_turma = t.id ' +
        '  AND io.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'')) AS inscritos_confirmados, ' +
        'ia.id AS id_inscricao, ia.situacao AS situacao_inscricao ' +
        'FROM turma t ' +
        'INNER JOIN curso c ' +
        '  ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'LEFT JOIN inscricao ia ' +
        '  ON ia.id_instituicao = t.id_instituicao ' +
        ' AND ia.id_turma = t.id ' +
        ' AND ia.id_participante = :id_participante ' +
        'WHERE t.id_instituicao = :id_instituicao ' +
        'AND c.situacao = ''ATIVO'' ' +
        'AND c.permitir_inscricao_publica = 1 ' +
        'AND t.situacao = ''INSCRICOES_ABERTAS'' ' +
        'AND t.permitir_inscricao_publica = 1 ' +
        'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio <= CURRENT_TIMESTAMP(3)) ' +
        'AND (t.inscricao_fim IS NULL OR t.inscricao_fim >= CURRENT_TIMESTAMP(3)) ' +
        'AND t.data_hora_fim >= CURRENT_TIMESTAMP(3) ' +
        'ORDER BY t.data_hora_inicio, c.nome, t.id ' +
        'LIMIT :limite OFFSET :offset';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      Qry.ParamByName('limite').AsInteger := APorPagina;
      Qry.ParamByName('offset').AsInteger := Offset;
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(MapearItem(Qry));
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

class function TAlunoCursoDisponivelDAO.Buscar(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdTurma: Int64
): TAlunoCursoDisponivelItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      't.id AS id_turma, t.codigo_publico AS codigo_turma, t.nome AS turma_nome, ' +
      'c.id AS id_curso, c.codigo_publico AS codigo_curso, c.nome AS curso_nome, ' +
      'c.descricao AS curso_descricao, c.objetivo AS curso_objetivo, ' +
      't.modalidade, c.imagem_url, t.data_hora_inicio, t.data_hora_fim, ' +
      't.inscricao_inicio, t.inscricao_fim, t.limite_participantes, t.local, ' +
      'COALESCE(t.carga_horaria_minutos, c.carga_horaria_minutos) AS carga_horaria_minutos, ' +
      '(SELECT COUNT(*) FROM inscricao io ' +
      '  WHERE io.id_instituicao = t.id_instituicao AND io.id_turma = t.id ' +
      '  AND io.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'')) AS inscritos_confirmados, ' +
      'ia.id AS id_inscricao, ia.situacao AS situacao_inscricao ' +
      'FROM turma t ' +
      'INNER JOIN curso c ' +
      '  ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
      'LEFT JOIN inscricao ia ' +
      '  ON ia.id_instituicao = t.id_instituicao ' +
      ' AND ia.id_turma = t.id ' +
      ' AND ia.id_participante = :id_participante ' +
      'WHERE t.id_instituicao = :id_instituicao ' +
      'AND t.id = :id_turma ' +
      'AND c.situacao = ''ATIVO'' ' +
      'AND c.permitir_inscricao_publica = 1 ' +
      'AND t.situacao = ''INSCRICOES_ABERTAS'' ' +
      'AND t.permitir_inscricao_publica = 1 ' +
      'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio <= CURRENT_TIMESTAMP(3)) ' +
      'AND (t.inscricao_fim IS NULL OR t.inscricao_fim >= CURRENT_TIMESTAMP(3)) ' +
      'AND t.data_hora_fim >= CURRENT_TIMESTAMP(3) ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);
  finally
    Qry.Free;
  end;
end;

class function TAlunoCursoDisponivelDAO.BloquearTurmaDisponivel(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT t.id ' +
      'FROM turma t ' +
      'INNER JOIN curso c ' +
      '  ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
      'WHERE t.id_instituicao = :id_instituicao ' +
      'AND t.id = :id_turma ' +
      'AND c.situacao = ''ATIVO'' ' +
      'AND c.permitir_inscricao_publica = 1 ' +
      'AND t.situacao = ''INSCRICOES_ABERTAS'' ' +
      'AND t.permitir_inscricao_publica = 1 ' +
      'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio <= CURRENT_TIMESTAMP(3)) ' +
      'AND (t.inscricao_fim IS NULL OR t.inscricao_fim >= CURRENT_TIMESTAMP(3)) ' +
      'AND t.data_hora_fim >= CURRENT_TIMESTAMP(3) ' +
      'FOR UPDATE';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

end.
