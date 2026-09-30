unit PublicoInstituicao.DAO;

interface

uses
  Uni,
  PublicoInstituicao.Model;

type
  TPublicoInstituicaoDAO = class
  public
    class function BuscarPorSlug(
      const AConn: TUniConnection;
      const ASlug: string
    ): TPublicoInstituicao; static;

    class function ListarCursosDisponiveis(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const APagina, APorPagina: Integer
    ): TPublicoCursoLista; static;

    class function BuscarCursoDisponivelPorCodigo(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigoTurma: string
    ): TPublicoCurso; static;
  end;

implementation

class function TPublicoInstituicaoDAO.BuscarPorSlug(
  const AConn: TUniConnection;
  const ASlug: string
): TPublicoInstituicao;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT i.id, i.slug, i.razao_social, i.nome_fantasia, i.cnpj, i.email, i.telefone, i.site, ' +
      'COALESCE(ic.nome_exibicao, i.nome_fantasia) AS nome_exibicao, ' +
      'COALESCE(ic.mensagem_boas_vindas, '''') AS mensagem_boas_vindas, ' +
      'COALESCE(ic.email_contato, i.email, '''') AS email_contato, ' +
      'COALESCE(ic.telefone_contato, i.telefone, '''') AS telefone_contato, ' +
      'COALESCE(ic.logo_url, '''') AS logo_url, ' +
      'COALESCE(ic.favicon_url, '''') AS favicon_url, ' +
      'COALESCE(ic.imagem_login_url, '''') AS imagem_login_url, ' +
      'COALESCE(ic.cor_primaria, ''#2563EB'') AS cor_primaria, ' +
      'COALESCE(ic.cor_secundaria, ''#1E40AF'') AS cor_secundaria, ' +
      'COALESCE(ic.cor_destaque, ''#F59E0B'') AS cor_destaque, ' +
      'COALESCE(ic.cor_fundo, ''#F8FAFC'') AS cor_fundo, ' +
      'COALESCE(ic.cor_texto, ''#0F172A'') AS cor_texto ' +
      'FROM instituicao i ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'WHERE i.slug = :slug AND i.situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := ASlug;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TPublicoInstituicao.Create;
    Result.Id := Qry.FieldByName('id').AsLargeInt;
    Result.Slug := Qry.FieldByName('slug').AsString;
    Result.Nome := Qry.FieldByName('nome_fantasia').AsString;
    Result.RazaoSocial := Qry.FieldByName('razao_social').AsString;
    Result.Cnpj := Qry.FieldByName('cnpj').AsString;
    Result.Descricao := Qry.FieldByName('mensagem_boas_vindas').AsString;
    Result.Email := Qry.FieldByName('email_contato').AsString;
    Result.Telefone := Qry.FieldByName('telefone_contato').AsString;
    Result.Site := Qry.FieldByName('site').AsString;
    Result.NomeExibicao := Qry.FieldByName('nome_exibicao').AsString;
    Result.LogoUrl := Qry.FieldByName('logo_url').AsString;
    Result.FaviconUrl := Qry.FieldByName('favicon_url').AsString;
    Result.ImagemLoginUrl := Qry.FieldByName('imagem_login_url').AsString;
    Result.CorPrimaria := Qry.FieldByName('cor_primaria').AsString;
    Result.CorSecundaria := Qry.FieldByName('cor_secundaria').AsString;
    Result.CorDestaque := Qry.FieldByName('cor_destaque').AsString;
    Result.CorFundo := Qry.FieldByName('cor_fundo').AsString;
    Result.CorTexto := Qry.FieldByName('cor_texto').AsString;
  finally
    Qry.Free;
  end;
end;

class function TPublicoInstituicaoDAO.ListarCursosDisponiveis(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const APagina, APorPagina: Integer
): TPublicoCursoLista;
var
  Qry: TUniQuery;
  Item: TPublicoCurso;
  Offset, Limite, Ocupados: Integer;
begin
  Result := TPublicoCursoLista.Create;
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
      'INNER JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
      'WHERE t.id_instituicao = :id_instituicao ' +
      'AND c.situacao = ''ATIVO'' ' +
      'AND c.permitir_inscricao_publica = 1 ' +
      'AND t.situacao = ''INSCRICOES_ABERTAS'' ' +
      'AND t.permitir_inscricao_publica = 1 ' +
      'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio <= CURRENT_TIMESTAMP(3)) ' +
      'AND (t.inscricao_fim IS NULL OR t.inscricao_fim >= CURRENT_TIMESTAMP(3)) ' +
      'AND t.data_hora_fim >= CURRENT_TIMESTAMP(3)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;
    Result.Total := Qry.FieldByName('total').AsInteger;
    Qry.Close;

    Qry.SQL.Text :=
      'SELECT t.id AS id_turma, t.codigo_publico AS codigo_turma, t.nome AS turma_nome, ' +
      'c.id AS id_curso, c.codigo_publico AS codigo_curso, c.nome AS curso_nome, ' +
      'COALESCE(c.descricao, '''') AS curso_descricao, t.modalidade, c.imagem_url, ' +
      't.data_hora_inicio, t.data_hora_fim, t.inscricao_fim, t.limite_participantes, t.local, ' +
      'COALESCE(t.carga_horaria_minutos, c.carga_horaria_minutos) AS carga_horaria_minutos, ' +
      '(SELECT COUNT(*) FROM inscricao i ' +
      ' WHERE i.id_instituicao = t.id_instituicao AND i.id_turma = t.id ' +
      ' AND i.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'')) AS inscritos_confirmados ' +
      'FROM turma t ' +
      'INNER JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
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

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('limite').AsInteger := APorPagina;
    Qry.ParamByName('offset').AsInteger := Offset;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TPublicoCurso.Create;
      Item.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
      Item.CodigoTurma := Qry.FieldByName('codigo_turma').AsString;
      Item.TurmaNome := Qry.FieldByName('turma_nome').AsString;
      Item.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
      Item.CodigoCurso := Qry.FieldByName('codigo_curso').AsString;
      Item.CursoNome := Qry.FieldByName('curso_nome').AsString;
      Item.CursoDescricao := Qry.FieldByName('curso_descricao').AsString;
      Item.Modalidade := Qry.FieldByName('modalidade').AsString;
      Item.ImagemUrl := Qry.FieldByName('imagem_url').AsString;
      Item.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;
      Item.DataHoraFim := Qry.FieldByName('data_hora_fim').AsDateTime;
      Item.TemInscricaoFim := not Qry.FieldByName('inscricao_fim').IsNull;
      if Item.TemInscricaoFim then
        Item.InscricaoFim := Qry.FieldByName('inscricao_fim').AsDateTime;
      Item.TemLimiteParticipantes := not Qry.FieldByName('limite_participantes').IsNull;
      Item.InscritosConfirmados := Qry.FieldByName('inscritos_confirmados').AsInteger;
      if Item.TemLimiteParticipantes then
      begin
        Limite := Qry.FieldByName('limite_participantes').AsInteger;
        Ocupados := Item.InscritosConfirmados;
        Item.LimiteParticipantes := Limite;
        Item.TemVagasDisponiveis := True;
        Item.VagasDisponiveis := Limite - Ocupados;
        if Item.VagasDisponiveis < 0 then
          Item.VagasDisponiveis := 0;
      end;
      Item.Local := Qry.FieldByName('local').AsString;
      Item.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
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

class function TPublicoInstituicaoDAO.BuscarCursoDisponivelPorCodigo(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigoTurma: string
): TPublicoCurso;
var
  Qry: TUniQuery;
  Limite, Ocupados: Integer;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT t.id AS id_turma, t.codigo_publico AS codigo_turma, t.nome AS turma_nome, ' +
      'c.id AS id_curso, c.codigo_publico AS codigo_curso, c.nome AS curso_nome, ' +
      'COALESCE(c.descricao, '''') AS curso_descricao, t.modalidade, c.imagem_url, ' +
      't.data_hora_inicio, t.data_hora_fim, t.inscricao_fim, t.limite_participantes, t.local, ' +
      'COALESCE(t.carga_horaria_minutos, c.carga_horaria_minutos) AS carga_horaria_minutos, ' +
      '(SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao=t.id_instituicao ' +
      'AND i.id_turma=t.id AND i.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'')) AS inscritos_confirmados ' +
      'FROM turma t INNER JOIN curso c ON c.id_instituicao=t.id_instituicao AND c.id=t.id_curso ' +
      'WHERE t.id_instituicao=:id_instituicao AND t.codigo_publico=:codigo_turma ' +
      'AND c.situacao=''ATIVO'' AND c.permitir_inscricao_publica=1 ' +
      'AND t.situacao=''INSCRICOES_ABERTAS'' AND t.permitir_inscricao_publica=1 ' +
      'AND (t.inscricao_inicio IS NULL OR t.inscricao_inicio<=CURRENT_TIMESTAMP(3)) ' +
      'AND (t.inscricao_fim IS NULL OR t.inscricao_fim>=CURRENT_TIMESTAMP(3)) ' +
      'AND t.data_hora_fim>=CURRENT_TIMESTAMP(3) LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('codigo_turma').AsString := Trim(ACodigoTurma);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TPublicoCurso.Create;
    Result.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
    Result.CodigoTurma := Qry.FieldByName('codigo_turma').AsString;
    Result.TurmaNome := Qry.FieldByName('turma_nome').AsString;
    Result.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
    Result.CodigoCurso := Qry.FieldByName('codigo_curso').AsString;
    Result.CursoNome := Qry.FieldByName('curso_nome').AsString;
    Result.CursoDescricao := Qry.FieldByName('curso_descricao').AsString;
    Result.Modalidade := Qry.FieldByName('modalidade').AsString;
    Result.ImagemUrl := Qry.FieldByName('imagem_url').AsString;
    Result.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;
    Result.DataHoraFim := Qry.FieldByName('data_hora_fim').AsDateTime;
    Result.TemInscricaoFim := not Qry.FieldByName('inscricao_fim').IsNull;
    if Result.TemInscricaoFim then
      Result.InscricaoFim := Qry.FieldByName('inscricao_fim').AsDateTime;
    Result.TemLimiteParticipantes := not Qry.FieldByName('limite_participantes').IsNull;
    Result.InscritosConfirmados := Qry.FieldByName('inscritos_confirmados').AsInteger;
    if Result.TemLimiteParticipantes then
    begin
      Limite := Qry.FieldByName('limite_participantes').AsInteger;
      Ocupados := Result.InscritosConfirmados;
      Result.LimiteParticipantes := Limite;
      Result.TemVagasDisponiveis := True;
      Result.VagasDisponiveis := Limite - Ocupados;
      if Result.VagasDisponiveis < 0 then
        Result.VagasDisponiveis := 0;
    end;
    Result.Local := Qry.FieldByName('local').AsString;
    Result.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
  finally
    Qry.Free;
  end;
end;

end;

end.
