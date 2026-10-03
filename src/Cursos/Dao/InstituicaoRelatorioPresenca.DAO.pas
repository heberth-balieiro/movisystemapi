unit InstituicaoRelatorioPresenca.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoRelatorioPresenca.Model;

type
  TInstituicaoRelatorioPresencaDAO = class
  private
    class function BaseSQL: string; static;
    class function MontarWhere(const AFiltro: TRelatorioPresencaFiltro): string; static;
    class procedure AplicarFiltro(const AQry: TUniQuery; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioPresencaFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TRelatorioPresencaItem; static;
  public
    class function ListarFiltros(const AConn: TUniConnection;
      const AIdInstituicao: Int64): TRelatorioPresencaFiltros; static;

    class function Listar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioPresencaFiltro): TRelatorioPresencaResultado; static;

    class function Exportar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioPresencaFiltro): TObjectList<TRelatorioPresencaItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoRelatorioPresencaDAO.BaseSQL: string;
begin
  Result :=
    ' FROM (' +
    ' SELECT i.id_instituicao, i.id AS id_inscricao, i.id_participante, ' +
    ' p.nome AS participante_nome, p.cpf_mascarado, p.cpf_hash_busca, ' +
    ' c.id AS id_curso, c.nome AS curso_nome, t.id AS id_turma, t.nome AS turma_nome, ' +
    ' ''ENCONTRO'' AS controle_presenca, e.id AS id_encontro, e.titulo AS encontro_titulo, ' +
    ' e.data_hora_inicio AS data_referencia, ' +
    ' COALESCE(pr.situacao,''SEM_REGISTRO'') AS situacao, ' +
    ' COALESCE(pr.origem,''SEM_REGISTRO'') AS origem, ' +
    ' pr.checkin_em, pr.minutos_presentes, pr.justificativa, u.nome AS registrado_por_nome ' +
    ' FROM inscricao i ' +
    ' JOIN participante p ON p.id_instituicao=i.id_instituicao AND p.id=i.id_participante ' +
    ' JOIN turma t ON t.id_instituicao=i.id_instituicao AND t.id=i.id_turma ' +
    ' JOIN curso c ON c.id_instituicao=t.id_instituicao AND c.id=t.id_curso ' +
    ' JOIN turma_encontro e ON e.id_instituicao=t.id_instituicao AND e.id_turma=t.id ' +
    '   AND e.situacao<>''CANCELADO'' ' +
    ' LEFT JOIN presenca pr ON pr.id_instituicao=i.id_instituicao ' +
    '   AND pr.id_turma=i.id_turma AND pr.id_inscricao=i.id AND pr.id_encontro=e.id ' +
    ' LEFT JOIN usuario_instituicao ui ON ui.id_instituicao=pr.id_instituicao AND ui.id=pr.registrado_por ' +
    ' LEFT JOIN usuario u ON u.id=ui.id_usuario ' +
    ' WHERE t.controle_presenca=''ENCONTRO'' AND t.tipo_fluxo=''NORMAL'' ' +
    '   AND i.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'') ' +

    ' UNION ALL ' +

    ' SELECT i.id_instituicao, i.id AS id_inscricao, i.id_participante, ' +
    ' p.nome AS participante_nome, p.cpf_mascarado, p.cpf_hash_busca, ' +
    ' c.id AS id_curso, c.nome AS curso_nome, t.id AS id_turma, t.nome AS turma_nome, ' +
    ' ''TURMA'' AS controle_presenca, NULL AS id_encontro, '''' AS encontro_titulo, ' +
    ' t.data_hora_inicio AS data_referencia, ' +
    ' COALESCE(tp.situacao,''SEM_REGISTRO'') AS situacao, ' +
    ' COALESCE(tp.origem,''SEM_REGISTRO'') AS origem, ' +
    ' tp.checkin_em, NULL AS minutos_presentes, NULL AS justificativa, u.nome AS registrado_por_nome ' +
    ' FROM inscricao i ' +
    ' JOIN participante p ON p.id_instituicao=i.id_instituicao AND p.id=i.id_participante ' +
    ' JOIN turma t ON t.id_instituicao=i.id_instituicao AND t.id=i.id_turma ' +
    ' JOIN curso c ON c.id_instituicao=t.id_instituicao AND c.id=t.id_curso ' +
    ' LEFT JOIN turma_presenca tp ON tp.id_instituicao=i.id_instituicao ' +
    '   AND tp.id_turma=i.id_turma AND tp.id_inscricao=i.id ' +
    ' LEFT JOIN usuario_instituicao ui ON ui.id_instituicao=tp.id_instituicao AND ui.id=tp.registrado_por ' +
    ' LEFT JOIN usuario u ON u.id=ui.id_usuario ' +
    ' WHERE t.controle_presenca=''TURMA'' AND t.tipo_fluxo=''NORMAL'' ' +
    '   AND i.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'') ' +
    ' ) x ';
end;

class function TInstituicaoRelatorioPresencaDAO.MontarWhere(
  const AFiltro: TRelatorioPresencaFiltro): string;
begin
  Result := ' WHERE x.id_instituicao=:id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result := Result +
      ' AND (x.participante_nome LIKE :busca OR x.curso_nome LIKE :busca ' +
      'OR x.turma_nome LIKE :busca OR x.encontro_titulo LIKE :busca ';
    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      Result := Result + 'OR x.cpf_hash_busca=:cpf_hash_busca ';
    Result := Result + ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + ' AND x.situacao=:situacao ';

  if not Trim(AFiltro.Origem).IsEmpty then
    Result := Result + ' AND x.origem=:origem ';

  if not Trim(AFiltro.ControlePresenca).IsEmpty then
    Result := Result + ' AND x.controle_presenca=:controle_presenca ';

  if AFiltro.IdCurso > 0 then
    Result := Result + ' AND x.id_curso=:id_curso ';

  if AFiltro.IdTurma > 0 then
    Result := Result + ' AND x.id_turma=:id_turma ';

  if AFiltro.IdEncontro > 0 then
    Result := Result + ' AND x.id_encontro=:id_encontro ';

  if AFiltro.TemDataInicio then
    Result := Result + ' AND x.data_referencia>=:data_inicio ';

  if AFiltro.TemDataFim then
    Result := Result + ' AND x.data_referencia<:data_fim ';
end;

class procedure TInstituicaoRelatorioPresencaDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioPresencaFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';
    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      AQry.ParamByName('cpf_hash_busca').AsString := AFiltro.CpfHashBusca;
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.Origem).IsEmpty then
    AQry.ParamByName('origem').AsString := UpperCase(Trim(AFiltro.Origem));

  if not Trim(AFiltro.ControlePresenca).IsEmpty then
    AQry.ParamByName('controle_presenca').AsString := UpperCase(Trim(AFiltro.ControlePresenca));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt := AFiltro.IdCurso;

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName('id_turma').AsLargeInt := AFiltro.IdTurma;

  if AFiltro.IdEncontro > 0 then
    AQry.ParamByName('id_encontro').AsLargeInt := AFiltro.IdEncontro;

  if AFiltro.TemDataInicio then
    AQry.ParamByName('data_inicio').AsDateTime := AFiltro.DataInicio;

  if AFiltro.TemDataFim then
    AQry.ParamByName('data_fim').AsDateTime := AFiltro.DataFim;
end;

class function TInstituicaoRelatorioPresencaDAO.MapearItem(
  const AQry: TUniQuery): TRelatorioPresencaItem;
begin
  Result := TRelatorioPresencaItem.Create;
  Result.IdInscricao := AQry.FieldByName('id_inscricao').AsLargeInt;
  Result.IdParticipante := AQry.FieldByName('id_participante').AsLargeInt;
  Result.ParticipanteNome := AQry.FieldByName('participante_nome').AsString;
  Result.CpfMascarado := AQry.FieldByName('cpf_mascarado').AsString;
  Result.IdCurso := AQry.FieldByName('id_curso').AsLargeInt;
  Result.CursoNome := AQry.FieldByName('curso_nome').AsString;
  Result.IdTurma := AQry.FieldByName('id_turma').AsLargeInt;
  Result.TurmaNome := AQry.FieldByName('turma_nome').AsString;
  Result.ControlePresenca := AQry.FieldByName('controle_presenca').AsString;
  Result.TemEncontro := not AQry.FieldByName('id_encontro').IsNull;
  if Result.TemEncontro then
    Result.IdEncontro := AQry.FieldByName('id_encontro').AsLargeInt;
  Result.EncontroTitulo := AQry.FieldByName('encontro_titulo').AsString;
  Result.DataReferencia := AQry.FieldByName('data_referencia').AsDateTime;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.Origem := AQry.FieldByName('origem').AsString;
  Result.TemCheckinEm := not AQry.FieldByName('checkin_em').IsNull;
  if Result.TemCheckinEm then
    Result.CheckinEm := AQry.FieldByName('checkin_em').AsDateTime;
  Result.RegistradoPorNome := AQry.FieldByName('registrado_por_nome').AsString;
  Result.Justificativa := AQry.FieldByName('justificativa').AsString;
  Result.TemMinutosPresentes := not AQry.FieldByName('minutos_presentes').IsNull;
  if Result.TemMinutosPresentes then
    Result.MinutosPresentes := AQry.FieldByName('minutos_presentes').AsInteger;
end;

class function TInstituicaoRelatorioPresencaDAO.ListarFiltros(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64): TRelatorioPresencaFiltros;
var
  Qry: TUniQuery;
  Item: TRelatorioPresencaFiltroOpcao;
begin
  Result := TRelatorioPresencaFiltros.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT DISTINCT c.id,c.nome FROM turma t ' +
        'JOIN curso c ON c.id_instituicao=t.id_instituicao AND c.id=t.id_curso ' +
        'WHERE t.id_instituicao=:id_instituicao AND t.tipo_fluxo=''NORMAL'' ' +
        'AND t.controle_presenca IN (''ENCONTRO'',''TURMA'') ORDER BY c.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;
      while not Qry.Eof do
      begin
        Item := TRelatorioPresencaFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Result.Cursos.Add(Item);
        Qry.Next;
      end;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT t.id,t.nome,t.id_curso FROM turma t ' +
        'WHERE t.id_instituicao=:id_instituicao AND t.tipo_fluxo=''NORMAL'' ' +
        'AND t.controle_presenca IN (''ENCONTRO'',''TURMA'') ORDER BY t.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;
      while not Qry.Eof do
      begin
        Item := TRelatorioPresencaFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
        Result.Turmas.Add(Item);
        Qry.Next;
      end;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT e.id,e.titulo AS nome,e.id_turma FROM turma_encontro e ' +
        'JOIN turma t ON t.id_instituicao=e.id_instituicao AND t.id=e.id_turma ' +
        'WHERE e.id_instituicao=:id_instituicao AND t.tipo_fluxo=''NORMAL'' ' +
        'AND t.controle_presenca=''ENCONTRO'' AND e.situacao<>''CANCELADO'' ' +
        'ORDER BY e.data_hora_inicio,e.id';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;
      while not Qry.Eof do
      begin
        Item := TRelatorioPresencaFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
        Result.Encontros.Add(Item);
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

class function TInstituicaoRelatorioPresencaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioPresencaFiltro): TRelatorioPresencaResultado;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
  Resumo: TRelatorioPresencaResumo;
begin
  Result := TRelatorioPresencaResultado.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;
      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text := 'SELECT COUNT(*) AS total ' + BaseSQL + WhereSQL;
      AplicarFiltro(Qry,AIdInstituicao,AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total_previstos, ' +
        'SUM(CASE WHEN x.situacao=''PRESENTE'' THEN 1 ELSE 0 END) AS presentes, ' +
        'SUM(CASE WHEN x.situacao=''AUSENTE'' THEN 1 ELSE 0 END) AS ausentes, ' +
        'SUM(CASE WHEN x.situacao=''JUSTIFICADA'' THEN 1 ELSE 0 END) AS justificadas, ' +
        'SUM(CASE WHEN x.situacao=''PARCIAL'' THEN 1 ELSE 0 END) AS parciais, ' +
        'SUM(CASE WHEN x.situacao=''SEM_REGISTRO'' THEN 1 ELSE 0 END) AS sem_registro, ' +
        'SUM(CASE WHEN x.origem=''AUTO_CHECKIN'' THEN 1 ELSE 0 END) AS auto_checkin, ' +
        'SUM(CASE WHEN x.origem=''QR_EQUIPE'' THEN 1 ELSE 0 END) AS qr_equipe, ' +
        'SUM(CASE WHEN x.origem=''MANUAL'' THEN 1 ELSE 0 END) AS manuais ' +
        BaseSQL + WhereSQL;
      AplicarFiltro(Qry,AIdInstituicao,AFiltro);
      Qry.Open;

      Resumo := Default(TRelatorioPresencaResumo);
      Resumo.TotalPrevistos := Qry.FieldByName('total_previstos').AsInteger;
      Resumo.Presentes := Qry.FieldByName('presentes').AsInteger;
      Resumo.Ausentes := Qry.FieldByName('ausentes').AsInteger;
      Resumo.Justificadas := Qry.FieldByName('justificadas').AsInteger;
      Resumo.Parciais := Qry.FieldByName('parciais').AsInteger;
      Resumo.SemRegistro := Qry.FieldByName('sem_registro').AsInteger;
      Resumo.AutoCheckin := Qry.FieldByName('auto_checkin').AsInteger;
      Resumo.QrEquipe := Qry.FieldByName('qr_equipe').AsInteger;
      Resumo.Manuais := Qry.FieldByName('manuais').AsInteger;
      Result.Resumo := Resumo;
      Qry.Close;

      Offset := (AFiltro.Pagina-1)*AFiltro.PorPagina;
      Qry.SQL.Text :=
        'SELECT x.id_inscricao,x.id_participante,x.participante_nome,x.cpf_mascarado,' +
        'x.id_curso,x.curso_nome,x.id_turma,x.turma_nome,x.controle_presenca,' +
        'x.id_encontro,x.encontro_titulo,x.data_referencia,x.situacao,x.origem,' +
        'x.checkin_em,x.minutos_presentes,x.justificativa,x.registrado_por_nome ' +
        BaseSQL + WhereSQL +
        'ORDER BY x.data_referencia DESC,x.turma_nome,x.participante_nome ' +
        'LIMIT :limite OFFSET :offset';
      AplicarFiltro(Qry,AIdInstituicao,AFiltro);
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

class function TInstituicaoRelatorioPresencaDAO.Exportar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioPresencaFiltro): TObjectList<TRelatorioPresencaItem>;
var
  Qry: TUniQuery;
  WhereSQL: string;
begin
  Result := TObjectList<TRelatorioPresencaItem>.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      WhereSQL := MontarWhere(AFiltro);
      Qry.SQL.Text :=
        'SELECT x.id_inscricao,x.id_participante,x.participante_nome,x.cpf_mascarado,' +
        'x.id_curso,x.curso_nome,x.id_turma,x.turma_nome,x.controle_presenca,' +
        'x.id_encontro,x.encontro_titulo,x.data_referencia,x.situacao,x.origem,' +
        'x.checkin_em,x.minutos_presentes,x.justificativa,x.registrado_por_nome ' +
        BaseSQL + WhereSQL +
        'ORDER BY x.data_referencia DESC,x.turma_nome,x.participante_nome LIMIT 50001';
      AplicarFiltro(Qry,AIdInstituicao,AFiltro);
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
