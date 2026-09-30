unit AlunoPortal.DAO;

interface

uses
  Uni,
  AlunoPortal.Model;

type
  TAlunoPortalDAO = class
  public
    class function BuscarContexto(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TAlunoContexto; static;

    class function Dashboard(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto
    ): TAlunoDashboard; static;

    class function ListarInscricoes(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TAlunoInscricaoLista; static;

    class function BuscarInscricao(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdInscricao: Int64
    ): TAlunoInscricaoItem; static;

    class function ListarPresencas(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdInscricao: Int64
    ): TAlunoPresencaLista; static;

    class function ListarAulas(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdInscricao: Int64
    ): TAlunoAulaLista; static;

    class function ListarCriterios(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdInscricao: Int64
    ): TAlunoCriterioLista; static;

    class function ListarCertificados(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto
    ): TAlunoCertificadoLista; static;

    class function BuscarCertificado(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdCertificado: Int64
    ): TAlunoCertificadoItem; static;

    class function BuscarPdfStorageKey(
      const AConn: TUniConnection;
      const AAluno: TAlunoContexto;
      const AIdCertificado: Int64
    ): string; static;
  end;

implementation

uses
  System.SysUtils;

class function TAlunoPortalDAO.BuscarContexto(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TAlunoContexto;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT p.id, p.codigo_publico, p.nome, p.email, p.cpf_mascarado, ' +
      'p.matricula, p.telefone, p.orgao_empresa, p.cargo, ' +
      'i.nome_fantasia AS instituicao_nome, i.slug AS instituicao_slug ' +
      'FROM participante p ' +
      'INNER JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = p.id_instituicao AND ui.id = p.id_usuario_instituicao ' +
      'INNER JOIN usuario u ON u.id = ui.id_usuario ' +
      'INNER JOIN instituicao i ON i.id = p.id_instituicao ' +
      'WHERE p.id_instituicao = :id_instituicao ' +
      'AND p.id_usuario_instituicao = :id_usuario_instituicao ' +
      'AND p.situacao = ''ATIVO'' ' +
      'AND ui.situacao = ''ATIVO'' ' +
      'AND u.situacao = ''ATIVO'' ' +
      'AND i.situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TAlunoContexto.Create;
    Result.IdParticipante := Qry.FieldByName('id').AsLargeInt;
    Result.IdInstituicao := AIdInstituicao;
    Result.IdUsuarioInstituicao := AIdUsuarioInstituicao;
    Result.CodigoPublico := Qry.FieldByName('codigo_publico').AsString;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.CpfMascarado := Qry.FieldByName('cpf_mascarado').AsString;
    Result.Matricula := Qry.FieldByName('matricula').AsString;
    Result.Telefone := Qry.FieldByName('telefone').AsString;
    Result.OrgaoEmpresa := Qry.FieldByName('orgao_empresa').AsString;
    Result.Cargo := Qry.FieldByName('cargo').AsString;
    Result.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug := Qry.FieldByName('instituicao_slug').AsString;
  finally
    Qry.Free;
  end;
end;

class function TAlunoPortalDAO.Dashboard(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto
): TAlunoDashboard;
var
  Qry: TUniQuery;
begin
  Result := TAlunoDashboard.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'COUNT(*) AS total, ' +
      'SUM(CASE WHEN situacao IN (''INSCRITO'',''CONFIRMADO'',''EM_ANDAMENTO'') THEN 1 ELSE 0 END) AS andamento, ' +
      'SUM(CASE WHEN situacao = ''CONCLUIDO'' THEN 1 ELSE 0 END) AS concluidas ' +
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao AND id_participante = :id_participante';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.Open;

    Result.TotalInscricoes        := Qry.FieldByName('total').AsInteger;
    Result.InscricoesEmAndamento  := Qry.FieldByName('andamento').AsInteger;
    Result.InscricoesConcluidas   := Qry.FieldByName('concluidas').AsInteger;

    Qry.Close;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total FROM certificado c ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id_participante = :id_participante AND c.situacao = ''VALIDO'' ' +
      'AND NOT EXISTS (' +
      ' SELECT 1 FROM certificado c2 ' +
      ' WHERE c2.id_instituicao=c.id_instituicao ' +
      ' AND c2.id_inscricao=c.id_inscricao ' +
      ' AND c2.situacao=''VALIDO'' AND c2.versao>c.versao' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.Open;

    Result.CertificadosValidos := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

class function TAlunoPortalDAO.ListarInscricoes(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const ASituacao: string;
  const APagina,
        APorPagina: Integer
): TAlunoInscricaoLista;
var
  Qry: TUniQuery;
  WhereSituacao: string;
  Offset: Integer;
  Item: TAlunoInscricaoItem;
begin
  Result := TAlunoInscricaoLista.Create;
  Result.Pagina := APagina;
  Result.PorPagina := APorPagina;
  Offset := (APagina - 1) * APorPagina;

  if Trim(ASituacao).IsEmpty then
    WhereSituacao := ''
  else
    WhereSituacao := ' AND ins.situacao = :situacao ';

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM inscricao ins ' +
        'WHERE ins.id_instituicao = :id_instituicao ' +
        'AND ins.id_participante = :id_participante ' +
        WhereSituacao;

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      if not Trim(ASituacao).IsEmpty then
        Qry.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));

      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ins.id, ins.codigo_publico, ins.id_turma, ins.situacao, ins.inscrito_em, ' +
        'ins.percentual_presenca, ins.percentual_progresso, ins.nota_final, ins.elegivel_certificado, ' +
        't.nome AS turma_nome, t.data_hora_inicio, t.data_hora_fim, t.modalidade, ' +
        'c.id AS id_curso, c.nome AS curso_nome, c.imagem_url ' +
        'FROM inscricao ins ' +
        'INNER JOIN turma t ON t.id_instituicao = ins.id_instituicao AND t.id = ins.id_turma ' +
        'INNER JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'WHERE ins.id_instituicao = :id_instituicao ' +
        'AND ins.id_participante = :id_participante ' +
        WhereSituacao +
        'ORDER BY ins.inscrito_em DESC, ins.id DESC LIMIT :limite OFFSET :offset';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      if not Trim(ASituacao).IsEmpty then
        Qry.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
      Qry.ParamByName('limite').AsInteger := APorPagina;
      Qry.ParamByName('offset').AsInteger := Offset;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TAlunoInscricaoItem.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.CodigoPublico := Qry.FieldByName('codigo_publico').AsString;
        Item.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
        Item.TurmaNome := Qry.FieldByName('turma_nome').AsString;
        Item.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
        Item.CursoNome := Qry.FieldByName('curso_nome').AsString;
        Item.CursoImagemUrl := Qry.FieldByName('imagem_url').AsString;
        Item.Modalidade := Qry.FieldByName('modalidade').AsString;
        Item.Situacao := Qry.FieldByName('situacao').AsString;
        Item.InscritoEm := Qry.FieldByName('inscrito_em').AsDateTime;

        Item.TemDataInicio := not Qry.FieldByName('data_hora_inicio').IsNull;
        if Item.TemDataInicio then
          Item.DataInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;

        Item.TemDataFim := not Qry.FieldByName('data_hora_fim').IsNull;
        if Item.TemDataFim then
          Item.DataFim := Qry.FieldByName('data_hora_fim').AsDateTime;

        Item.TemPercentualPresenca := not Qry.FieldByName('percentual_presenca').IsNull;
        if Item.TemPercentualPresenca then
          Item.PercentualPresenca := Qry.FieldByName('percentual_presenca').AsFloat;

        Item.PercentualProgresso := Qry.FieldByName('percentual_progresso').AsFloat;
        Item.TemNotaFinal := not Qry.FieldByName('nota_final').IsNull;
        if Item.TemNotaFinal then
          Item.NotaFinal := Qry.FieldByName('nota_final').AsFloat;

        Item.ElegivelCertificado := Qry.FieldByName('elegivel_certificado').AsBoolean;

        Result.Itens.Add(Item);
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

class function TAlunoPortalDAO.BuscarInscricao(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdInscricao: Int64
): TAlunoInscricaoItem;
var
  Lista: TAlunoInscricaoLista;
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ins.id, ins.codigo_publico, ins.id_turma, ins.situacao, ins.inscrito_em, ' +
      'ins.percentual_presenca, ins.percentual_progresso, ins.nota_final, ins.elegivel_certificado, ' +
      't.nome AS turma_nome, t.data_hora_inicio, t.data_hora_fim, t.modalidade, ' +
      'c.id AS id_curso, c.nome AS curso_nome, c.imagem_url ' +
      'FROM inscricao ins ' +
      'INNER JOIN turma t ON t.id_instituicao = ins.id_instituicao AND t.id = ins.id_turma ' +
      'INNER JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
      'WHERE ins.id_instituicao = :id_instituicao ' +
      'AND ins.id_participante = :id_participante AND ins.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.ParamByName('id').AsLargeInt := AIdInscricao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TAlunoInscricaoItem.Create;
    Result.Id := Qry.FieldByName('id').AsLargeInt;
    Result.CodigoPublico := Qry.FieldByName('codigo_publico').AsString;
    Result.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
    Result.TurmaNome := Qry.FieldByName('turma_nome').AsString;
    Result.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
    Result.CursoNome := Qry.FieldByName('curso_nome').AsString;
    Result.CursoImagemUrl := Qry.FieldByName('imagem_url').AsString;
    Result.Modalidade := Qry.FieldByName('modalidade').AsString;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
    Result.InscritoEm := Qry.FieldByName('inscrito_em').AsDateTime;

    Result.TemDataInicio := not Qry.FieldByName('data_hora_inicio').IsNull;
    if Result.TemDataInicio then
      Result.DataInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;

    Result.TemDataFim := not Qry.FieldByName('data_hora_fim').IsNull;
    if Result.TemDataFim then
      Result.DataFim := Qry.FieldByName('data_hora_fim').AsDateTime;

    Result.TemPercentualPresenca := not Qry.FieldByName('percentual_presenca').IsNull;
    if Result.TemPercentualPresenca then
      Result.PercentualPresenca := Qry.FieldByName('percentual_presenca').AsFloat;

    Result.PercentualProgresso := Qry.FieldByName('percentual_progresso').AsFloat;
    Result.TemNotaFinal := not Qry.FieldByName('nota_final').IsNull;
    if Result.TemNotaFinal then
      Result.NotaFinal := Qry.FieldByName('nota_final').AsFloat;

    Result.ElegivelCertificado := Qry.FieldByName('elegivel_certificado').AsBoolean;
  finally
    Qry.Free;
  end;
end;

class function TAlunoPortalDAO.ListarPresencas(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdInscricao: Int64
): TAlunoPresencaLista;
var
  Qry: TUniQuery;
  Item: TAlunoPresencaItem;
begin
  Result := TAlunoPresencaLista.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT e.id AS id_encontro, e.titulo, e.data_hora_inicio, e.data_hora_fim, ' +
        'e.obrigatorio, e.situacao AS situacao_encontro, ' +
        'pr.id AS id_presenca, pr.situacao AS situacao_presenca, ' +
        'pr.minutos_presentes, pr.justificativa ' +
        'FROM inscricao ins ' +
        'INNER JOIN turma_encontro e ' +
        '  ON e.id_instituicao = ins.id_instituicao AND e.id_turma = ins.id_turma ' +
        'LEFT JOIN presenca pr ' +
        '  ON pr.id_instituicao = ins.id_instituicao ' +
        ' AND pr.id_turma = ins.id_turma ' +
        ' AND pr.id_encontro = e.id ' +
        ' AND pr.id_inscricao = ins.id ' +
        'WHERE ins.id_instituicao = :id_instituicao ' +
        'AND ins.id_participante = :id_participante ' +
        'AND ins.id = :id_inscricao ' +
        'ORDER BY e.data_hora_inicio, e.id';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TAlunoPresencaItem.Create;
        Item.IdEncontro := Qry.FieldByName('id_encontro').AsLargeInt;
        Item.Titulo := Qry.FieldByName('titulo').AsString;
        Item.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;
        Item.DataHoraFim := Qry.FieldByName('data_hora_fim').AsDateTime;
        Item.Obrigatorio := Qry.FieldByName('obrigatorio').AsBoolean;
        Item.SituacaoEncontro := Qry.FieldByName('situacao_encontro').AsString;
        Item.Registrada := not Qry.FieldByName('id_presenca').IsNull;
        Item.SituacaoPresenca := Qry.FieldByName('situacao_presenca').AsString;
        Item.TemMinutosPresentes := not Qry.FieldByName('minutos_presentes').IsNull;
        if Item.TemMinutosPresentes then
          Item.MinutosPresentes := Qry.FieldByName('minutos_presentes').AsInteger;
        Item.Justificativa := Qry.FieldByName('justificativa').AsString;
        Result.Add(Item);
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

class function TAlunoPortalDAO.ListarAulas(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdInscricao: Int64
): TAlunoAulaLista;
var
  Qry: TUniQuery;
  Item: TAlunoAulaItem;
begin
  Result := TAlunoAulaLista.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT a.id AS id_aula, m.nome AS modulo_titulo, a.titulo, a.tipo, ' +
        'a.duracao_minutos, a.obrigatoria, COALESCE(ap.percentual,0) AS percentual, ' +
        'COALESCE(ap.duracao_assistida_segundos,0) AS duracao_assistida_segundos, ' +
        'ap.concluido_em ' +
        'FROM inscricao ins ' +
        'INNER JOIN turma t ON t.id_instituicao = ins.id_instituicao AND t.id = ins.id_turma ' +
        'INNER JOIN curso_aula a ON a.id_instituicao = t.id_instituicao AND a.id_curso = t.id_curso ' +
        'INNER JOIN curso_modulo m ' +
        '  ON m.id_instituicao = a.id_instituicao AND m.id_curso = a.id_curso AND m.id = a.id_modulo ' +
        'LEFT JOIN inscricao_aula_progresso ap ' +
        '  ON ap.id_instituicao = ins.id_instituicao AND ap.id_turma = ins.id_turma ' +
        ' AND ap.id_inscricao = ins.id AND ap.id_curso = t.id_curso AND ap.id_aula = a.id ' +
        'WHERE ins.id_instituicao = :id_instituicao ' +
        'AND ins.id_participante = :id_participante AND ins.id = :id_inscricao ' +
        'AND a.situacao = ''ATIVA'' ' +
        'ORDER BY m.ordem, m.id, a.ordem, a.id';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TAlunoAulaItem.Create;
        Item.IdAula := Qry.FieldByName('id_aula').AsLargeInt;
        Item.ModuloTitulo := Qry.FieldByName('modulo_titulo').AsString;
        Item.Titulo := Qry.FieldByName('titulo').AsString;
        Item.Tipo := Qry.FieldByName('tipo').AsString;
        Item.TemDuracaoMinutos := not Qry.FieldByName('duracao_minutos').IsNull;
        if Item.TemDuracaoMinutos then
          Item.DuracaoMinutos := Qry.FieldByName('duracao_minutos').AsInteger;
        Item.Obrigatoria := Qry.FieldByName('obrigatoria').AsBoolean;
        Item.Percentual := Qry.FieldByName('percentual').AsFloat;
        Item.DuracaoAssistidaSegundos := Qry.FieldByName('duracao_assistida_segundos').AsInteger;
        Item.Concluida := not Qry.FieldByName('concluido_em').IsNull or (Item.Percentual >= 100);
        Result.Add(Item);
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

class function TAlunoPortalDAO.ListarCriterios(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdInscricao: Int64
): TAlunoCriterioLista;
var
  Qry: TUniQuery;
  Item: TAlunoCriterioItem;
begin
  Result := TAlunoCriterioLista.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT c.id AS id_criterio, c.tipo, c.nome, c.obrigatorio, r.atendido, r.resultado ' +
        'FROM inscricao ins ' +
        'INNER JOIN turma_criterio_conclusao c ' +
        '  ON c.id_instituicao = ins.id_instituicao AND c.id_turma = ins.id_turma ' +
        'LEFT JOIN inscricao_criterio_resultado r ' +
        '  ON r.id_instituicao = ins.id_instituicao AND r.id_turma = ins.id_turma ' +
        ' AND r.id_inscricao = ins.id AND r.id_criterio = c.id ' +
        'WHERE ins.id_instituicao = :id_instituicao ' +
        'AND ins.id_participante = :id_participante AND ins.id = :id_inscricao ' +
        'AND c.situacao = ''ATIVO'' ' +
        'ORDER BY c.ordem, c.id';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TAlunoCriterioItem.Create;
        Item.IdCriterio := Qry.FieldByName('id_criterio').AsLargeInt;
        Item.Tipo := Qry.FieldByName('tipo').AsString;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.Obrigatorio := Qry.FieldByName('obrigatorio').AsBoolean;
        Item.TemAtendido := not Qry.FieldByName('atendido').IsNull;
        if Item.TemAtendido then
          Item.Atendido := Qry.FieldByName('atendido').AsBoolean;
        Item.ResultadoJson := Qry.FieldByName('resultado').AsString;
        Result.Add(Item);
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

class function TAlunoPortalDAO.ListarCertificados(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto
): TAlunoCertificadoLista;
var
  Qry: TUniQuery;
  Item: TAlunoCertificadoItem;
begin
  Result := TAlunoCertificadoLista.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT id, numero_publico, versao, situacao, curso_nome, instituicao_nome, ' +
        'carga_horaria_minutos, data_conclusao, emitido_em, cancelado_em, pdf_storage_key ' +
        'FROM certificado c ' +
        'WHERE c.id_instituicao = :id_instituicao AND c.id_participante = :id_participante ' +
        'AND c.situacao = ''VALIDO'' ' +
        'AND NOT EXISTS (' +
        ' SELECT 1 FROM certificado c2 ' +
        ' WHERE c2.id_instituicao=c.id_instituicao ' +
        ' AND c2.id_inscricao=c.id_inscricao ' +
        ' AND c2.situacao=''VALIDO'' AND c2.versao>c.versao' +
        ') ' +
        'ORDER BY COALESCE(c.emitido_em, c.criado_em) DESC, c.id DESC';

      Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
      Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TAlunoCertificadoItem.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.NumeroPublico := Qry.FieldByName('numero_publico').AsString;
        Item.Versao := Qry.FieldByName('versao').AsInteger;
        Item.Situacao := Qry.FieldByName('situacao').AsString;
        Item.CursoNome := Qry.FieldByName('curso_nome').AsString;
        Item.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
        Item.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
        Item.DataConclusao := Qry.FieldByName('data_conclusao').AsDateTime;
        Item.TemEmitidoEm := not Qry.FieldByName('emitido_em').IsNull;
        if Item.TemEmitidoEm then
          Item.EmitidoEm := Qry.FieldByName('emitido_em').AsDateTime;
        Item.TemCanceladoEm := not Qry.FieldByName('cancelado_em').IsNull;
        if Item.TemCanceladoEm then
          Item.CanceladoEm := Qry.FieldByName('cancelado_em').AsDateTime;
        Item.TemPdf := not Qry.FieldByName('pdf_storage_key').IsNull and
                       not Trim(Qry.FieldByName('pdf_storage_key').AsString).IsEmpty;
        Result.Add(Item);
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

class function TAlunoPortalDAO.BuscarCertificado(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdCertificado: Int64
): TAlunoCertificadoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, numero_publico, versao, situacao, curso_nome, instituicao_nome, ' +
      'carga_horaria_minutos, data_conclusao, emitido_em, cancelado_em, pdf_storage_key ' +
      'FROM certificado c ' +
      'WHERE c.id_instituicao = :id_instituicao AND c.id_participante = :id_participante ' +
      'AND c.id = :id AND c.situacao = ''VALIDO'' ' +
      'AND NOT EXISTS (' +
      ' SELECT 1 FROM certificado c2 ' +
      ' WHERE c2.id_instituicao=c.id_instituicao ' +
      ' AND c2.id_inscricao=c.id_inscricao ' +
      ' AND c2.situacao=''VALIDO'' AND c2.versao>c.versao' +
      ') LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.ParamByName('id').AsLargeInt := AIdCertificado;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TAlunoCertificadoItem.Create;
    Result.Id := Qry.FieldByName('id').AsLargeInt;
    Result.NumeroPublico := Qry.FieldByName('numero_publico').AsString;
    Result.Versao := Qry.FieldByName('versao').AsInteger;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
    Result.CursoNome := Qry.FieldByName('curso_nome').AsString;
    Result.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
    Result.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
    Result.DataConclusao := Qry.FieldByName('data_conclusao').AsDateTime;
    Result.TemEmitidoEm := not Qry.FieldByName('emitido_em').IsNull;
    if Result.TemEmitidoEm then
      Result.EmitidoEm := Qry.FieldByName('emitido_em').AsDateTime;
    Result.TemCanceladoEm := not Qry.FieldByName('cancelado_em').IsNull;
    if Result.TemCanceladoEm then
      Result.CanceladoEm := Qry.FieldByName('cancelado_em').AsDateTime;
    Result.TemPdf := not Qry.FieldByName('pdf_storage_key').IsNull and
                     not Trim(Qry.FieldByName('pdf_storage_key').AsString).IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TAlunoPortalDAO.BuscarPdfStorageKey(
  const AConn: TUniConnection;
  const AAluno: TAlunoContexto;
  const AIdCertificado: Int64
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.pdf_storage_key FROM certificado c ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id_participante = :id_participante ' +
      'AND c.id = :id AND c.situacao = ''VALIDO'' ' +
      'AND c.pdf_storage_key IS NOT NULL ' +
      'AND NOT EXISTS (' +
      ' SELECT 1 FROM certificado c2 ' +
      ' WHERE c2.id_instituicao=c.id_instituicao ' +
      ' AND c2.id_inscricao=c.id_inscricao ' +
      ' AND c2.situacao=''VALIDO'' AND c2.versao>c.versao' +
      ') LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AAluno.IdInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AAluno.IdParticipante;
    Qry.ParamByName('id').AsLargeInt := AIdCertificado;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('pdf_storage_key').AsString;
  finally
    Qry.Free;
  end;
end;

end.
