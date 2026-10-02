unit InstituicaoRelatorioInscricao.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoRelatorioInscricao.Model;

type
  TInstituicaoRelatorioInscricaoDAO = class
  private
    class function MontarWhere(const AFiltro: TRelatorioInscricaoFiltro): string; static;
    class procedure AplicarFiltro(const AQry: TUniQuery; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioInscricaoFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TRelatorioInscricaoItem; static;
  public
    class function ListarFiltros(const AConn: TUniConnection;
      const AIdInstituicao: Int64): TRelatorioInscricaoFiltros; static;
    class function Listar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioInscricaoFiltro): TRelatorioInscricaoResultado; static;
    class function Exportar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioInscricaoFiltro): TObjectList<TRelatorioInscricaoItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoRelatorioInscricaoDAO.MontarWhere(
  const AFiltro: TRelatorioInscricaoFiltro): string;
begin
  Result := ' WHERE i.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (p.nome LIKE :busca OR p.cpf_mascarado LIKE :busca OR ' +
      'c.nome LIKE :busca OR t.nome LIKE :busca) ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + ' AND i.situacao = :situacao ';

  if not Trim(AFiltro.Origem).IsEmpty then
    Result := Result + ' AND i.origem = :origem ';

  if AFiltro.IdCurso > 0 then
    Result := Result + ' AND t.id_curso = :id_curso ';

  if AFiltro.IdTurma > 0 then
    Result := Result + ' AND i.id_turma = :id_turma ';

  if AFiltro.TemDataInscricaoInicio then
    Result := Result + ' AND i.inscrito_em >= :data_inscricao_inicio ';

  if AFiltro.TemDataInscricaoFim then
    Result := Result + ' AND i.inscrito_em < :data_inscricao_fim ';

  if AFiltro.TemDataConclusaoInicio then
    Result := Result + ' AND i.concluido_em >= :data_conclusao_inicio ';

  if AFiltro.TemDataConclusaoFim then
    Result := Result + ' AND i.concluido_em < :data_conclusao_fim ';
end;

class procedure TInstituicaoRelatorioInscricaoDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioInscricaoFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.Origem).IsEmpty then
    AQry.ParamByName('origem').AsString := UpperCase(Trim(AFiltro.Origem));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt := AFiltro.IdCurso;

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName('id_turma').AsLargeInt := AFiltro.IdTurma;

  if AFiltro.TemDataInscricaoInicio then
    AQry.ParamByName('data_inscricao_inicio').AsDateTime := AFiltro.DataInscricaoInicio;

  if AFiltro.TemDataInscricaoFim then
    AQry.ParamByName('data_inscricao_fim').AsDateTime := AFiltro.DataInscricaoFim;

  if AFiltro.TemDataConclusaoInicio then
    AQry.ParamByName('data_conclusao_inicio').AsDateTime := AFiltro.DataConclusaoInicio;

  if AFiltro.TemDataConclusaoFim then
    AQry.ParamByName('data_conclusao_fim').AsDateTime := AFiltro.DataConclusaoFim;
end;

class function TInstituicaoRelatorioInscricaoDAO.MapearItem(
  const AQry: TUniQuery): TRelatorioInscricaoItem;
begin
  Result := TRelatorioInscricaoItem.Create;
  Result.IdInscricao := AQry.FieldByName('id_inscricao').AsLargeInt;
  Result.ParticipanteNome := AQry.FieldByName('participante_nome').AsString;
  Result.CpfMascarado := AQry.FieldByName('cpf_mascarado').AsString;
  Result.CursoNome := AQry.FieldByName('curso_nome').AsString;
  Result.TurmaNome := AQry.FieldByName('turma_nome').AsString;
  Result.TipoTurma := AQry.FieldByName('tipo_turma').AsString;
  Result.Origem := AQry.FieldByName('origem').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.InscritoEm := AQry.FieldByName('inscrito_em').AsDateTime;
  Result.TemConcluidoEm := not AQry.FieldByName('concluido_em').IsNull;
  if Result.TemConcluidoEm then
    Result.ConcluidoEm := AQry.FieldByName('concluido_em').AsDateTime;
  Result.TemPercentualPresenca := not AQry.FieldByName('percentual_presenca').IsNull;
  if Result.TemPercentualPresenca then
    Result.PercentualPresenca := AQry.FieldByName('percentual_presenca').AsFloat;
  Result.ElegivelCertificado := AQry.FieldByName('elegivel_certificado').AsBoolean;
  Result.CertificadoEmitido := AQry.FieldByName('certificado_emitido').AsBoolean;
end;

class function TInstituicaoRelatorioInscricaoDAO.ListarFiltros(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64): TRelatorioInscricaoFiltros;
var
  Qry: TUniQuery;
  Item: TRelatorioInscricaoFiltroOpcao;
begin
  Result := TRelatorioInscricaoFiltros.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT DISTINCT c.id, c.nome ' +
        'FROM inscricao i ' +
        'JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        'JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'WHERE i.id_instituicao = :id_instituicao ORDER BY c.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TRelatorioInscricaoFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Result.Cursos.Add(Item);
        Qry.Next;
      end;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT DISTINCT t.id, t.nome, t.id_curso ' +
        'FROM inscricao i ' +
        'JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        'WHERE i.id_instituicao = :id_instituicao ORDER BY t.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TRelatorioInscricaoFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
        Result.Turmas.Add(Item);
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

class function TInstituicaoRelatorioInscricaoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioInscricaoFiltro): TRelatorioInscricaoResultado;
var
  Qry: TUniQuery;
  WhereSQL, FromSQL, SelectSQL: string;
  Offset: Integer;
  Resumo: TRelatorioInscricaoResumo;
begin
  Result := TRelatorioInscricaoResultado.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      FromSQL :=
        ' FROM inscricao i ' +
        ' JOIN participante p ON p.id_instituicao = i.id_instituicao AND p.id = i.id_participante ' +
        ' JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        ' JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ';

      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text := 'SELECT COUNT(*) AS total ' + FromSQL + WhereSQL;
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total_inscricoes, ' +
        'SUM(CASE WHEN i.situacao = ''CONFIRMADO'' THEN 1 ELSE 0 END) AS confirmadas, ' +
        'SUM(CASE WHEN i.situacao = ''EM_ANDAMENTO'' THEN 1 ELSE 0 END) AS em_andamento, ' +
        'SUM(CASE WHEN i.situacao = ''CONCLUIDO'' THEN 1 ELSE 0 END) AS concluidas, ' +
        'SUM(CASE WHEN i.situacao = ''CANCELADO'' THEN 1 ELSE 0 END) AS canceladas, ' +
        'SUM(CASE WHEN i.situacao = ''REPROVADO'' THEN 1 ELSE 0 END) AS reprovadas, ' +
        'SUM(CASE WHEN i.situacao = ''DESISTENTE'' THEN 1 ELSE 0 END) AS desistentes, ' +
        'SUM(CASE WHEN i.elegivel_certificado = 1 THEN 1 ELSE 0 END) AS elegiveis_certificado, ' +
        'SUM(CASE WHEN EXISTS (SELECT 1 FROM certificado cf ' +
        '  WHERE cf.id_instituicao = i.id_instituicao AND cf.id_inscricao = i.id ' +
        '    AND cf.situacao = ''VALIDO'') THEN 1 ELSE 0 END) AS certificados_emitidos ' +
        FromSQL + WhereSQL;

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      Resumo := Default(TRelatorioInscricaoResumo);
      Resumo.TotalInscricoes := Qry.FieldByName('total_inscricoes').AsInteger;
      Resumo.Confirmadas := Qry.FieldByName('confirmadas').AsInteger;
      Resumo.EmAndamento := Qry.FieldByName('em_andamento').AsInteger;
      Resumo.Concluidas := Qry.FieldByName('concluidas').AsInteger;
      Resumo.Canceladas := Qry.FieldByName('canceladas').AsInteger;
      Resumo.Reprovadas := Qry.FieldByName('reprovadas').AsInteger;
      Resumo.Desistentes := Qry.FieldByName('desistentes').AsInteger;
      Resumo.ElegiveisCertificado := Qry.FieldByName('elegiveis_certificado').AsInteger;
      Resumo.CertificadosEmitidos := Qry.FieldByName('certificados_emitidos').AsInteger;
      Result.Resumo := Resumo;
      Qry.Close;

      SelectSQL :=
        'SELECT i.id AS id_inscricao, p.nome AS participante_nome, p.cpf_mascarado, ' +
        'c.nome AS curso_nome, t.nome AS turma_nome, t.tipo_fluxo AS tipo_turma, ' +
        'i.origem, i.situacao, i.inscrito_em, i.concluido_em, i.percentual_presenca, ' +
        'i.elegivel_certificado, ' +
        'EXISTS (SELECT 1 FROM certificado cf ' +
        ' WHERE cf.id_instituicao = i.id_instituicao AND cf.id_inscricao = i.id ' +
        ' AND cf.situacao = ''VALIDO'') AS certificado_emitido ';

      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text := SelectSQL + FromSQL + WhereSQL +
        ' ORDER BY i.inscrito_em DESC, i.id DESC LIMIT :limite OFFSET :offset';
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

class function TInstituicaoRelatorioInscricaoDAO.Exportar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioInscricaoFiltro): TObjectList<TRelatorioInscricaoItem>;
var
  Qry: TUniQuery;
  WhereSQL, FromSQL: string;
begin
  Result := TObjectList<TRelatorioInscricaoItem>.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      FromSQL :=
        ' FROM inscricao i ' +
        ' JOIN participante p ON p.id_instituicao = i.id_instituicao AND p.id = i.id_participante ' +
        ' JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        ' JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ';

      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text :=
        'SELECT i.id AS id_inscricao, p.nome AS participante_nome, p.cpf_mascarado, ' +
        'c.nome AS curso_nome, t.nome AS turma_nome, t.tipo_fluxo AS tipo_turma, ' +
        'i.origem, i.situacao, i.inscrito_em, i.concluido_em, i.percentual_presenca, ' +
        'i.elegivel_certificado, ' +
        'EXISTS (SELECT 1 FROM certificado cf ' +
        ' WHERE cf.id_instituicao = i.id_instituicao AND cf.id_inscricao = i.id ' +
        ' AND cf.situacao = ''VALIDO'') AS certificado_emitido ' +
        FromSQL + WhereSQL +
        ' ORDER BY i.inscrito_em DESC, i.id DESC LIMIT 50001';

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
