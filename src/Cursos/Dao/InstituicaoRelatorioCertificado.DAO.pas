unit InstituicaoRelatorioCertificado.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoRelatorioCertificado.Model;

type
  TInstituicaoRelatorioCertificadoDAO = class
  private
    class function MontarWhere(
      const AFiltro: TRelatorioCertificadoFiltro
    ): string; static;

    class procedure AplicarFiltro(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TRelatorioCertificadoFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TRelatorioCertificadoItem; static;
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TRelatorioCertificadoFiltro
    ): TRelatorioCertificadoResultado; static;

    class function Exportar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TRelatorioCertificadoFiltro
    ): TObjectList<TRelatorioCertificadoItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoRelatorioCertificadoDAO.MontarWhere(
  const AFiltro: TRelatorioCertificadoFiltro
): string;
begin
  Result :=
    ' WHERE c.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (' +
      'c.numero_publico LIKE :busca ' +
      'OR c.participante_nome LIKE :busca ' +
      'OR c.curso_nome LIKE :busca ' +
      'OR t.nome LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result +
      ' AND c.situacao = :situacao ';

  if not Trim(AFiltro.TipoTurma).IsEmpty then
    Result := Result +
      ' AND t.tipo_fluxo = :tipo_turma ';

  if AFiltro.IdCurso > 0 then
    Result := Result +
      ' AND c.id_curso = :id_curso ';

  if AFiltro.IdTurma > 0 then
    Result := Result +
      ' AND c.id_turma = :id_turma ';

  if AFiltro.IdParticipante > 0 then
    Result := Result +
      ' AND c.id_participante = :id_participante ';

  if AFiltro.TemDataInicio then
    Result := Result +
      ' AND c.emitido_em >= :data_inicio ';

  if AFiltro.TemDataFim then
    Result := Result +
      ' AND c.emitido_em < :data_fim ';
end;

class procedure TInstituicaoRelatorioCertificadoDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioCertificadoFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.TipoTurma).IsEmpty then
    AQry.ParamByName('tipo_turma').AsString :=
      UpperCase(Trim(AFiltro.TipoTurma));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt := AFiltro.IdCurso;

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName('id_turma').AsLargeInt := AFiltro.IdTurma;

  if AFiltro.IdParticipante > 0 then
    AQry.ParamByName('id_participante').AsLargeInt := AFiltro.IdParticipante;

  if AFiltro.TemDataInicio then
    AQry.ParamByName('data_inicio').AsDateTime := AFiltro.DataInicio;

  if AFiltro.TemDataFim then
    AQry.ParamByName('data_fim').AsDateTime := AFiltro.DataFim;
end;

class function TInstituicaoRelatorioCertificadoDAO.MapearItem(
  const AQry: TUniQuery
): TRelatorioCertificadoItem;
begin
  Result := TRelatorioCertificadoItem.Create;

  Result.IdCertificado :=
    AQry.FieldByName('id_certificado').AsLargeInt;

  Result.NumeroPublico :=
    AQry.FieldByName('numero_publico').AsString;

  Result.ParticipanteNome :=
    AQry.FieldByName('participante_nome').AsString;

  Result.CpfMascarado :=
    AQry.FieldByName('cpf_mascarado').AsString;

  Result.CursoNome :=
    AQry.FieldByName('curso_nome').AsString;

  Result.TurmaNome :=
    AQry.FieldByName('turma_nome').AsString;

  Result.TipoTurma :=
    AQry.FieldByName('tipo_turma').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.Versao :=
    AQry.FieldByName('versao').AsInteger;

  Result.Reemitido :=
    not AQry.FieldByName('id_certificado_origem').IsNull;

  Result.TemEmitidoEm :=
    not AQry.FieldByName('emitido_em').IsNull;

  if Result.TemEmitidoEm then
    Result.EmitidoEm :=
      AQry.FieldByName('emitido_em').AsDateTime;

  Result.TemCanceladoEm :=
    not AQry.FieldByName('cancelado_em').IsNull;

  if Result.TemCanceladoEm then
    Result.CanceladoEm :=
      AQry.FieldByName('cancelado_em').AsDateTime;

  Result.EmitidoPorNome :=
    AQry.FieldByName('emitido_por_nome').AsString;

  Result.CargaHorariaMinutos :=
    AQry.FieldByName('carga_horaria_minutos').AsInteger;
end;

class function TInstituicaoRelatorioCertificadoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioCertificadoFiltro
): TRelatorioCertificadoResultado;
var
  Qry: TUniQuery;
  WhereSQL, FromSQL, SelectSQL: string;
  Offset: Integer;
  Resumo: TRelatorioCertificadoResumo;
begin
  Result := TRelatorioCertificadoResultado.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      FromSQL :=
        ' FROM certificado c ' +
        ' JOIN turma t ' +
        '   ON t.id_instituicao = c.id_instituicao ' +
        '  AND t.id = c.id_turma ' +
        ' JOIN participante p ' +
        '   ON p.id_instituicao = c.id_instituicao ' +
        '  AND p.id = c.id_participante ' +
        ' LEFT JOIN usuario_instituicao ui ' +
        '   ON ui.id_instituicao = c.id_instituicao ' +
        '  AND ui.id = c.emitido_por ' +
        ' LEFT JOIN usuario u ' +
        '   ON u.id = ui.id_usuario ';

      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        FromSQL +
        WhereSQL;

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'SUM(CASE WHEN c.situacao = ''VALIDO'' THEN 1 ELSE 0 END) AS validos, ' +
        'SUM(CASE WHEN c.situacao = ''CANCELADO'' THEN 1 ELSE 0 END) AS cancelados, ' +
        'SUM(CASE WHEN c.situacao = ''PENDENTE'' THEN 1 ELSE 0 END) AS pendentes, ' +
        'SUM(CASE WHEN c.situacao = ''ERRO'' THEN 1 ELSE 0 END) AS erros, ' +
        'SUM(CASE WHEN c.id_certificado_origem IS NOT NULL THEN 1 ELSE 0 END) AS reemitidos ' +
        FromSQL +
        WhereSQL;

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      Resumo := Default(TRelatorioCertificadoResumo);
      Resumo.Total := Result.Total;
      Resumo.Validos := Qry.FieldByName('validos').AsInteger;
      Resumo.Cancelados := Qry.FieldByName('cancelados').AsInteger;
      Resumo.Pendentes := Qry.FieldByName('pendentes').AsInteger;
      Resumo.Erros := Qry.FieldByName('erros').AsInteger;
      Resumo.Reemitidos := Qry.FieldByName('reemitidos').AsInteger;
      Result.Resumo := Resumo;

      Qry.Close;

      SelectSQL :=
        'SELECT ' +
        'c.id AS id_certificado, ' +
        'c.numero_publico, ' +
        'c.participante_nome, ' +
        'p.cpf_mascarado, ' +
        'c.curso_nome, ' +
        't.nome AS turma_nome, ' +
        't.tipo_fluxo AS tipo_turma, ' +
        'c.situacao, ' +
        'c.versao, ' +
        'c.id_certificado_origem, ' +
        'c.emitido_em, ' +
        'c.cancelado_em, ' +
        'u.nome AS emitido_por_nome, ' +
        'c.carga_horaria_minutos ';

      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text :=
        SelectSQL +
        FromSQL +
        WhereSQL +
        ' ORDER BY COALESCE(c.emitido_em, c.criado_em) DESC, c.id DESC ' +
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

class function TInstituicaoRelatorioCertificadoDAO.Exportar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioCertificadoFiltro
): TObjectList<TRelatorioCertificadoItem>;
var
  Qry: TUniQuery;
  WhereSQL: string;
begin
  Result := TObjectList<TRelatorioCertificadoItem>.Create(True);
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;
      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text :=
        'SELECT ' +
        'c.id AS id_certificado, ' +
        'c.numero_publico, ' +
        'c.participante_nome, ' +
        'p.cpf_mascarado, ' +
        'c.curso_nome, ' +
        't.nome AS turma_nome, ' +
        't.tipo_fluxo AS tipo_turma, ' +
        'c.situacao, ' +
        'c.versao, ' +
        'c.id_certificado_origem, ' +
        'c.emitido_em, ' +
        'c.cancelado_em, ' +
        'u.nome AS emitido_por_nome, ' +
        'c.carga_horaria_minutos ' +
        'FROM certificado c ' +
        'JOIN turma t ' +
        '  ON t.id_instituicao = c.id_instituicao ' +
        ' AND t.id = c.id_turma ' +
        'JOIN participante p ' +
        '  ON p.id_instituicao = c.id_instituicao ' +
        ' AND p.id = c.id_participante ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = c.id_instituicao ' +
        ' AND ui.id = c.emitido_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY COALESCE(c.emitido_em, c.criado_em) DESC, c.id DESC ' +
        'LIMIT 50000';

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
