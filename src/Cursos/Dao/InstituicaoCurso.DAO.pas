unit InstituicaoCurso.DAO;

interface

uses
  Uni,
  InstituicaoCurso.Model;

type
  TInstituicaoCursoDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoCursoFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCursoFiltro
    ); static;
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCursoFiltro
    ): TInstituicaoCursoLista; static;

    class function ExisteCodigoPublico(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function ExisteCodigoInterno(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigoInterno: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function ExisteSlug(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ASlug: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoCursoCadastro
    ): Int64; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdCurso: Int64
    ): TInstituicaoCursoItem; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdCurso: Int64;
      const ADados: TInstituicaoCursoAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso: Int64;
      const ASituacao: string
    ); static;

  end;

implementation

uses
  System.SysUtils;

class procedure TInstituicaoCursoDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE curso SET ' +
      'situacao = :situacao, ' +
      'inativado_em = CASE ' +
      '  WHEN :situacao = ''INATIVO'' THEN ' +
      '    COALESCE(inativado_em, CURRENT_TIMESTAMP(3)) ' +
      '  ELSE NULL ' +
      'END ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdCurso;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;


class function TInstituicaoCursoDAO.ExisteCodigoPublico(
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
      'FROM curso ' +
      'WHERE codigo_publico = :codigo_publico ' +
      'LIMIT 1';

    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoDAO.ExisteCodigoInterno(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigoInterno: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ACodigoInterno).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM curso ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND codigo_interno = :codigo_interno ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add('AND id <> :id_ignorar ');

    Qry.SQL.Add('LIMIT 1');

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('codigo_interno').AsString := ACodigoInterno;

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt := AIdIgnorar;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoDAO.ExisteSlug(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ASlug: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ASlug).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM curso ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND slug = :slug ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add('AND id <> :id_ignorar ');

    Qry.SQL.Add('LIMIT 1');

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('slug').AsString := ASlug;

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt := AIdIgnorar;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoCursoCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO curso (' +
      'id_instituicao, ' +
      'id_categoria, ' +
      'id_entidade_atendida, ' +
      'codigo_publico, ' +
      'codigo_interno, ' +
      'slug, ' +
      'nome, ' +
      'descricao, ' +
      'objetivo, ' +
      'conteudo_programatico, ' +
      'carga_horaria_minutos, ' +
      'modalidade, ' +
      'imagem_url, ' +
      'permitir_inscricao_publica, ' +
      'situacao, ' +
      'criado_por, ' +
      'inativado_em' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_categoria, ' +
      ':id_entidade_atendida, ' +
      ':codigo_publico, ' +
      ':codigo_interno, ' +
      ':slug, ' +
      ':nome, ' +
      ':descricao, ' +
      ':objetivo, ' +
      ':conteudo_programatico, ' +
      ':carga_horaria_minutos, ' +
      ':modalidade, ' +
      ':imagem_url, ' +
      ':permitir_inscricao_publica, ' +
      ':situacao, ' +
      ':criado_por, ' +
      'IF(:situacao_inativo = ''INATIVO'', CURRENT_TIMESTAMP(3), NULL)' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

    if ADados.IdCategoria > 0 then
      Qry.ParamByName('id_categoria').AsLargeInt := ADados.IdCategoria
    else
      Qry.ParamByName('id_categoria').Clear;

    if ADados.IdEntidadeAtendida > 0 then
      Qry.ParamByName('id_entidade_atendida').AsLargeInt := ADados.IdEntidadeAtendida
    else
      Qry.ParamByName('id_entidade_atendida').Clear;

    Qry.ParamByName('codigo_publico').AsString := ADados.CodigoPublico;

    if not ADados.CodigoInterno.IsEmpty then
      Qry.ParamByName('codigo_interno').AsString := ADados.CodigoInterno
    else
      Qry.ParamByName('codigo_interno').Clear;

    if not ADados.Slug.IsEmpty then
      Qry.ParamByName('slug').AsString := ADados.Slug
    else
      Qry.ParamByName('slug').Clear;

    Qry.ParamByName('nome').AsString := ADados.Nome;

    if not ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').AsString := ADados.Descricao
    else
      Qry.ParamByName('descricao').Clear;

    if not ADados.Objetivo.IsEmpty then
      Qry.ParamByName('objetivo').AsString := ADados.Objetivo
    else
      Qry.ParamByName('objetivo').Clear;

    if not ADados.ConteudoProgramatico.IsEmpty then
      Qry.ParamByName('conteudo_programatico').AsString := ADados.ConteudoProgramatico
    else
      Qry.ParamByName('conteudo_programatico').Clear;

    Qry.ParamByName('carga_horaria_minutos').AsInteger := ADados.CargaHorariaMinutos;
    Qry.ParamByName('modalidade').AsString := ADados.Modalidade;

    if not ADados.ImagemUrl.IsEmpty then
      Qry.ParamByName('imagem_url').AsString := ADados.ImagemUrl
    else
      Qry.ParamByName('imagem_url').Clear;

    Qry.ParamByName('permitir_inscricao_publica').AsBoolean := ADados.PermitirInscricaoPublica;
    Qry.ParamByName('situacao').AsString := ADados.Situacao;
    Qry.ParamByName('situacao_inativo').AsString := ADados.Situacao;
    Qry.ParamByName('criado_por').AsLargeInt := ADados.CriadoPor;

    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;

    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdCurso: Int64
): TInstituicaoCursoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'c.id, ' +
      'c.id_categoria, ' +
      'c.id_entidade_atendida, ' +
      'ea.nome AS entidade_atendida_nome, ' +
      'c.codigo_publico, ' +
      'c.codigo_interno, ' +
      'c.slug, ' +
      'c.nome, ' +
      'c.descricao, ' +
      'c.objetivo, ' +
      'c.conteudo_programatico, ' +
      'c.carga_horaria_minutos, ' +
      'c.modalidade, ' +
      'c.imagem_url, ' +
      'c.permitir_inscricao_publica, ' +
      'c.situacao ' +
      'FROM curso c ' +
      'LEFT JOIN entidade_atendida ea ' +
      '  ON ea.id_instituicao = c.id_instituicao ' +
      ' AND ea.id = c.id_entidade_atendida ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdCurso;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TInstituicaoCursoItem.Create;

    Result.Id := Qry.FieldByName('id').AsLargeInt;

    if not Qry.FieldByName('id_categoria').IsNull then
      Result.IdCategoria := Qry.FieldByName('id_categoria').AsLargeInt;

    Result.TemEntidadeAtendida := not Qry.FieldByName('id_entidade_atendida').IsNull;
    if Result.TemEntidadeAtendida then
      Result.IdEntidadeAtendida := Qry.FieldByName('id_entidade_atendida').AsLargeInt;
    Result.EntidadeAtendidaNome := Qry.FieldByName('entidade_atendida_nome').AsString;

    Result.CodigoPublico := Qry.FieldByName('codigo_publico').AsString;
    Result.CodigoInterno := Qry.FieldByName('codigo_interno').AsString;
    Result.Slug := Qry.FieldByName('slug').AsString;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Descricao := Qry.FieldByName('descricao').AsString;
    Result.Objetivo := Qry.FieldByName('objetivo').AsString;
    Result.ConteudoProgramatico := Qry.FieldByName('conteudo_programatico').AsString;
    Result.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
    Result.Modalidade := Qry.FieldByName('modalidade').AsString;
    Result.ImagemUrl := Qry.FieldByName('imagem_url').AsString;
    Result.PermitirInscricaoPublica := Qry.FieldByName('permitir_inscricao_publica').AsBoolean;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCursoDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdCurso: Int64;
  const ADados: TInstituicaoCursoAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE curso SET ' +
      'id_categoria = :id_categoria, ' +
      'id_entidade_atendida = :id_entidade_atendida, ' +
      'codigo_interno = :codigo_interno, ' +
      'slug = :slug, ' +
      'nome = :nome, ' +
      'descricao = :descricao, ' +
      'objetivo = :objetivo, ' +
      'conteudo_programatico = :conteudo_programatico, ' +
      'carga_horaria_minutos = :carga_horaria_minutos, ' +
      'modalidade = :modalidade, ' +
      'imagem_url = :imagem_url, ' +
      'permitir_inscricao_publica = :permitir_inscricao_publica, ' +
      'situacao = :situacao, ' +
      'inativado_em = CASE ' +
      'WHEN :situacao_inativo = ''INATIVO'' ' +
      'THEN COALESCE(inativado_em, CURRENT_TIMESTAMP(3)) ' +
      'ELSE NULL END ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    if ADados.IdCategoria > 0 then
      Qry.ParamByName('id_categoria').AsLargeInt := ADados.IdCategoria
    else
      Qry.ParamByName('id_categoria').Clear;

    if ADados.IdEntidadeAtendida > 0 then
      Qry.ParamByName('id_entidade_atendida').AsLargeInt := ADados.IdEntidadeAtendida
    else
      Qry.ParamByName('id_entidade_atendida').Clear;

    if not ADados.CodigoInterno.IsEmpty then
      Qry.ParamByName('codigo_interno').AsString := ADados.CodigoInterno
    else
      Qry.ParamByName('codigo_interno').Clear;

    if not ADados.Slug.IsEmpty then
      Qry.ParamByName('slug').AsString := ADados.Slug
    else
      Qry.ParamByName('slug').Clear;

    Qry.ParamByName('nome').AsString := ADados.Nome;

    if not ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').AsString := ADados.Descricao
    else
      Qry.ParamByName('descricao').Clear;

    if not ADados.Objetivo.IsEmpty then
      Qry.ParamByName('objetivo').AsString := ADados.Objetivo
    else
      Qry.ParamByName('objetivo').Clear;

    if not ADados.ConteudoProgramatico.IsEmpty then
      Qry.ParamByName('conteudo_programatico').AsString := ADados.ConteudoProgramatico
    else
      Qry.ParamByName('conteudo_programatico').Clear;

    Qry.ParamByName('carga_horaria_minutos').AsInteger :=
      ADados.CargaHorariaMinutos;

    Qry.ParamByName('modalidade').AsString :=
      ADados.Modalidade;

    if not ADados.ImagemUrl.IsEmpty then
      Qry.ParamByName('imagem_url').AsString := ADados.ImagemUrl
    else
      Qry.ParamByName('imagem_url').Clear;

    Qry.ParamByName('permitir_inscricao_publica').AsBoolean :=
      ADados.PermitirInscricaoPublica;

    Qry.ParamByName('situacao').AsString :=
      ADados.Situacao;

    Qry.ParamByName('situacao_inativo').AsString :=
      ADados.Situacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdCurso;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoDAO.MontarWhere(
  const AFiltro: TInstituicaoCursoFiltro
): string;
begin
  Result := ' WHERE c.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (' +
      'c.nome LIKE :busca OR ' +
      'c.codigo_interno LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + ' AND c.situacao = :situacao ';

  if not Trim(AFiltro.Modalidade).IsEmpty then
    Result := Result + ' AND c.modalidade = :modalidade ';
end;

class procedure TInstituicaoCursoDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCursoFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.Modalidade).IsEmpty then
    AQry.ParamByName('modalidade').AsString := UpperCase(Trim(AFiltro.Modalidade));
end;

class function TInstituicaoCursoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCursoFiltro
): TInstituicaoCursoLista;
var
  Qry: TUniQuery;
  Item: TInstituicaoCursoItem;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoCursoLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) total ' +
        'FROM curso c ' +
        WhereSQL;

      AplicarParametros(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'c.id, ' +
        'c.id_categoria, ' +
        'c.id_entidade_atendida, ' +
        'ea.nome AS entidade_atendida_nome, ' +
        'c.codigo_publico, ' +
        'c.codigo_interno, ' +
        'c.slug, ' +
        'c.nome, ' +
        'c.carga_horaria_minutos, ' +
        'c.modalidade, ' +
        'c.permitir_inscricao_publica, ' +
        'c.situacao ' +
        'FROM curso c ' +
        'LEFT JOIN entidade_atendida ea ' +
        '  ON ea.id_instituicao = c.id_instituicao ' +
        ' AND ea.id = c.id_entidade_atendida ' +
        WhereSQL +
        'ORDER BY c.nome, c.id ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(Qry, AIdInstituicao, AFiltro);
      Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
      Qry.ParamByName('offset').AsInteger := Offset;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TInstituicaoCursoItem.Create;

        Item.Id := Qry.FieldByName('id').AsLargeInt;

        if not Qry.FieldByName('id_categoria').IsNull then
          Item.IdCategoria := Qry.FieldByName('id_categoria').AsLargeInt;

        Item.TemEntidadeAtendida := not Qry.FieldByName('id_entidade_atendida').IsNull;
        if Item.TemEntidadeAtendida then
          Item.IdEntidadeAtendida := Qry.FieldByName('id_entidade_atendida').AsLargeInt;
        Item.EntidadeAtendidaNome := Qry.FieldByName('entidade_atendida_nome').AsString;

        Item.CodigoPublico := Qry.FieldByName('codigo_publico').AsString;
        Item.CodigoInterno := Qry.FieldByName('codigo_interno').AsString;
        Item.Slug := Qry.FieldByName('slug').AsString;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.CargaHorariaMinutos := Qry.FieldByName('carga_horaria_minutos').AsInteger;
        Item.Modalidade := Qry.FieldByName('modalidade').AsString;
        Item.PermitirInscricaoPublica := Qry.FieldByName('permitir_inscricao_publica').AsBoolean;
        Item.Situacao := Qry.FieldByName('situacao').AsString;

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

end.
