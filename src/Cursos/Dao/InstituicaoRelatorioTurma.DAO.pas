unit InstituicaoRelatorioTurma.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoRelatorioTurma.Model;

type
  TInstituicaoRelatorioTurmaDAO = class
  private
    class function MontarWhere(const AFiltro: TRelatorioTurmaFiltro): string; static;
    class procedure AplicarFiltro(const AQry: TUniQuery; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioTurmaFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TRelatorioTurmaItem; static;
  public
    class function ListarFiltros(const AConn: TUniConnection;
      const AIdInstituicao: Int64): TRelatorioTurmaFiltros; static;

    class function Listar(const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TRelatorioTurmaFiltro): TRelatorioTurmaResultado; static;

    class function Exportar(const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TRelatorioTurmaFiltro): TObjectList<TRelatorioTurmaItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoRelatorioTurmaDAO.MontarWhere(
  const AFiltro: TRelatorioTurmaFiltro): string;
begin
  Result := ' WHERE t.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (t.nome LIKE :busca OR c.nome LIKE :busca OR t.codigo_interno LIKE :busca) ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + ' AND t.situacao = :situacao ';

  if not Trim(AFiltro.Modalidade).IsEmpty then
    Result := Result + ' AND t.modalidade = :modalidade ';

  if not Trim(AFiltro.TipoTurma).IsEmpty then
    Result := Result + ' AND t.tipo_fluxo = :tipo_turma ';

  if AFiltro.IdCurso > 0 then
    Result := Result + ' AND t.id_curso = :id_curso ';

  if AFiltro.TemDataInicio then
    Result := Result + ' AND t.data_hora_inicio >= :data_inicio ';

  if AFiltro.TemDataFim then
    Result := Result + ' AND t.data_hora_inicio < :data_fim ';
end;

class procedure TInstituicaoRelatorioTurmaDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioTurmaFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.Modalidade).IsEmpty then
    AQry.ParamByName('modalidade').AsString := UpperCase(Trim(AFiltro.Modalidade));

  if not Trim(AFiltro.TipoTurma).IsEmpty then
    AQry.ParamByName('tipo_turma').AsString := UpperCase(Trim(AFiltro.TipoTurma));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt := AFiltro.IdCurso;

  if AFiltro.TemDataInicio then
    AQry.ParamByName('data_inicio').AsDateTime := AFiltro.DataInicio;

  if AFiltro.TemDataFim then
    AQry.ParamByName('data_fim').AsDateTime := AFiltro.DataFim;
end;

class function TInstituicaoRelatorioTurmaDAO.MapearItem(
  const AQry: TUniQuery): TRelatorioTurmaItem;
begin
  Result := TRelatorioTurmaItem.Create;
  Result.IdTurma := AQry.FieldByName('id_turma').AsLargeInt;
  Result.IdCurso := AQry.FieldByName('id_curso').AsLargeInt;
  Result.CursoNome := AQry.FieldByName('curso_nome').AsString;
  Result.TurmaNome := AQry.FieldByName('turma_nome').AsString;
  Result.Modalidade := AQry.FieldByName('modalidade').AsString;
  Result.TipoTurma := AQry.FieldByName('tipo_turma').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.DataHoraInicio := AQry.FieldByName('data_hora_inicio').AsDateTime;
  Result.DataHoraFim := AQry.FieldByName('data_hora_fim').AsDateTime;
  Result.TotalInscritos := AQry.FieldByName('total_inscritos').AsInteger;
  Result.TotalConcluidos := AQry.FieldByName('total_concluidos').AsInteger;
  Result.TotalCertificados := AQry.FieldByName('total_certificados').AsInteger;
end;

class function TInstituicaoRelatorioTurmaDAO.ListarFiltros(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64): TRelatorioTurmaFiltros;
var
  Qry: TUniQuery;
  Item: TRelatorioTurmaFiltroOpcao;
begin
  Result := TRelatorioTurmaFiltros.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT DISTINCT c.id, c.nome ' +
        'FROM turma t ' +
        'JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'WHERE t.id_instituicao = :id_instituicao ' +
        'ORDER BY c.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TRelatorioTurmaFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Result.Cursos.Add(Item);
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

class function TInstituicaoRelatorioTurmaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioTurmaFiltro): TRelatorioTurmaResultado;
var
  Qry: TUniQuery;
  WhereSQL, BaseSQL, SelectSQL: string;
  Offset: Integer;
  Resumo: TRelatorioTurmaResumo;
begin
  Result := TRelatorioTurmaResultado.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      BaseSQL :=
        ' FROM turma t ' +
        ' JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ';

      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text := 'SELECT COUNT(*) AS total ' + BaseSQL + WhereSQL;
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'COUNT(*) AS total_turmas, ' +
        'SUM(CASE WHEN t.situacao = ''INSCRICOES_ABERTAS'' THEN 1 ELSE 0 END) AS inscricoes_abertas, ' +
        'SUM(CASE WHEN t.situacao = ''EM_ANDAMENTO'' THEN 1 ELSE 0 END) AS em_andamento, ' +
        'SUM(CASE WHEN t.situacao = ''ENCERRADA'' THEN 1 ELSE 0 END) AS encerradas, ' +
        'COALESCE(SUM((SELECT COUNT(*) FROM inscricao i ' +
        '  WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id)),0) AS participantes, ' +
        'COALESCE(SUM((SELECT COUNT(*) FROM certificado cf ' +
        '  WHERE cf.id_instituicao = t.id_instituicao AND cf.id_turma = t.id ' +
        '    AND cf.situacao = ''VALIDO'')),0) AS certificados_emitidos ' +
        BaseSQL + WhereSQL;

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      Resumo := Default(TRelatorioTurmaResumo);
      Resumo.TotalTurmas := Qry.FieldByName('total_turmas').AsInteger;
      Resumo.InscricoesAbertas := Qry.FieldByName('inscricoes_abertas').AsInteger;
      Resumo.EmAndamento := Qry.FieldByName('em_andamento').AsInteger;
      Resumo.Encerradas := Qry.FieldByName('encerradas').AsInteger;
      Resumo.Participantes := Qry.FieldByName('participantes').AsInteger;
      Resumo.CertificadosEmitidos := Qry.FieldByName('certificados_emitidos').AsInteger;
      Result.Resumo := Resumo;
      Qry.Close;

      SelectSQL :=
        'SELECT ' +
        't.id AS id_turma, t.id_curso, c.nome AS curso_nome, t.nome AS turma_nome, ' +
        't.modalidade, t.tipo_fluxo AS tipo_turma, t.situacao, ' +
        't.data_hora_inicio, t.data_hora_fim, ' +
        '(SELECT COUNT(*) FROM inscricao i ' +
        ' WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id) AS total_inscritos, ' +
        '(SELECT COUNT(*) FROM inscricao i ' +
        ' WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id ' +
        '   AND i.situacao = ''CONCLUIDO'') AS total_concluidos, ' +
        '(SELECT COUNT(*) FROM certificado cf ' +
        ' WHERE cf.id_instituicao = t.id_instituicao AND cf.id_turma = t.id ' +
        '   AND cf.situacao = ''VALIDO'') AS total_certificados ';

      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text := SelectSQL + BaseSQL + WhereSQL +
        ' ORDER BY t.data_hora_inicio DESC, t.id DESC ' +
        ' LIMIT :limite OFFSET :offset';

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
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

class function TInstituicaoRelatorioTurmaDAO.Exportar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioTurmaFiltro): TObjectList<TRelatorioTurmaItem>;
var
  Qry: TUniQuery;
  WhereSQL: string;
begin
  Result := TObjectList<TRelatorioTurmaItem>.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text :=
        'SELECT ' +
        't.id AS id_turma, t.id_curso, c.nome AS curso_nome, t.nome AS turma_nome, ' +
        't.modalidade, t.tipo_fluxo AS tipo_turma, t.situacao, ' +
        't.data_hora_inicio, t.data_hora_fim, ' +
        '(SELECT COUNT(*) FROM inscricao i ' +
        ' WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id) AS total_inscritos, ' +
        '(SELECT COUNT(*) FROM inscricao i ' +
        ' WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id ' +
        '   AND i.situacao = ''CONCLUIDO'') AS total_concluidos, ' +
        '(SELECT COUNT(*) FROM certificado cf ' +
        ' WHERE cf.id_instituicao = t.id_instituicao AND cf.id_turma = t.id ' +
        '   AND cf.situacao = ''VALIDO'') AS total_certificados ' +
        'FROM turma t ' +
        'JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        WhereSQL +
        'ORDER BY t.data_hora_inicio DESC, t.id DESC LIMIT 50001';

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Add(MapearItem(Qry));
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
