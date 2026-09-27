unit InstituicaoCertificadoModelo.DAO;

interface

uses
  Uni,
  InstituicaoCertificadoModelo.Model;

type
  TInstituicaoCertificadoModeloDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoCertificadoModeloFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCertificadoModeloFiltro
    ); static;

    class function MapearResumo(
      const AQry: TUniQuery
    ): TInstituicaoCertificadoModeloItem; static;

    class function MapearDetalhe(
      const AQry: TUniQuery
    ): TInstituicaoCertificadoModeloItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCertificadoModeloFiltro
    ): TInstituicaoCertificadoModeloLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64
    ): TInstituicaoCertificadoModeloItem; static;

    class function ExisteNome(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ANome: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function ExisteModeloAtivo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoCertificadoModeloCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64;
      const ADados: TInstituicaoCertificadoModeloAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64;
      const ASituacao: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoCertificadoModeloDAO.MontarWhere(
  const AFiltro: TInstituicaoCertificadoModeloFiltro
): string;
begin
  Result := ' WHERE m.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (' +
      'm.nome LIKE :busca OR ' +
      'm.descricao LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result +
      ' AND m.situacao = :situacao ';
end;

class procedure TInstituicaoCertificadoModeloDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCertificadoModeloFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoCertificadoModeloDAO.MapearResumo(
  const AQry: TUniQuery
): TInstituicaoCertificadoModeloItem;
begin
  Result := TInstituicaoCertificadoModeloItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Descricao :=
    AQry.FieldByName('descricao').AsString;

  Result.ImagemFundoUrl :=
    AQry.FieldByName('imagem_fundo_url').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoCertificadoModeloDAO.MapearDetalhe(
  const AQry: TUniQuery
): TInstituicaoCertificadoModeloItem;
begin
  Result := MapearResumo(AQry);

  Result.TemplateHtml :=
    AQry.FieldByName('template_html').AsString;

  Result.TemplateConfiguracao :=
    AQry.FieldByName('template_configuracao').AsString;
end;

class function TInstituicaoCertificadoModeloDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCertificadoModeloFiltro
): TInstituicaoCertificadoModeloLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoCertificadoModeloLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM certificado_modelo m ' +
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
        'm.id, ' +
        'm.nome, ' +
        'm.descricao, ' +
        'm.imagem_fundo_url, ' +
        'm.situacao, ' +
        'm.criado_em, ' +
        'm.atualizado_em ' +
        'FROM certificado_modelo m ' +
        WhereSQL +
        'ORDER BY m.nome, m.id ' +
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
          MapearResumo(Qry)
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

class function TInstituicaoCertificadoModeloDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64
): TInstituicaoCertificadoModeloItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'm.id, ' +
      'm.nome, ' +
      'm.descricao, ' +
      'm.template_html, ' +
      'm.template_configuracao, ' +
      'm.imagem_fundo_url, ' +
      'm.situacao, ' +
      'm.criado_em, ' +
      'm.atualizado_em ' +
      'FROM certificado_modelo m ' +
      'WHERE m.id_instituicao = :id_instituicao ' +
      'AND m.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdModelo;

    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearDetalhe(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoModeloDAO.ExisteNome(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ANome: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado_modelo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND nome = :nome ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('nome').AsString :=
      Trim(ANome);

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoModeloDAO.ExisteModeloAtivo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdModelo <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado_modelo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdModelo;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCertificadoModeloDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoCertificadoModeloCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO certificado_modelo (' +
      'id_instituicao, ' +
      'nome, ' +
      'descricao, ' +
      'template_html, ' +
      'template_configuracao, ' +
      'imagem_fundo_url, ' +
      'situacao' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':nome, ' +
      ':descricao, ' +
      ':template_html, ' +
      ':template_configuracao, ' +
      ':imagem_fundo_url, ' +
      '''ATIVO''' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao
    else
      Qry.ParamByName('descricao').Clear;

    if not ADados.TemplateHtml.IsEmpty then
      Qry.ParamByName('template_html').AsString :=
        ADados.TemplateHtml
    else
      Qry.ParamByName('template_html').Clear;

    if not ADados.TemplateConfiguracao.IsEmpty then
      Qry.ParamByName('template_configuracao').AsString :=
        ADados.TemplateConfiguracao
    else
      Qry.ParamByName('template_configuracao').Clear;

    if not ADados.ImagemFundoUrl.IsEmpty then
      Qry.ParamByName('imagem_fundo_url').AsString :=
        ADados.ImagemFundoUrl
    else
      Qry.ParamByName('imagem_fundo_url').Clear;

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

class procedure TInstituicaoCertificadoModeloDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64;
  const ADados: TInstituicaoCertificadoModeloAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE certificado_modelo SET ' +
      'nome = :nome, ' +
      'descricao = :descricao, ' +
      'template_html = :template_html, ' +
      'template_configuracao = :template_configuracao, ' +
      'imagem_fundo_url = :imagem_fundo_url ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao
    else
      Qry.ParamByName('descricao').Clear;

    if not ADados.TemplateHtml.IsEmpty then
      Qry.ParamByName('template_html').AsString :=
        ADados.TemplateHtml
    else
      Qry.ParamByName('template_html').Clear;

    if not ADados.TemplateConfiguracao.IsEmpty then
      Qry.ParamByName('template_configuracao').AsString :=
        ADados.TemplateConfiguracao
    else
      Qry.ParamByName('template_configuracao').Clear;

    if not ADados.ImagemFundoUrl.IsEmpty then
      Qry.ParamByName('imagem_fundo_url').AsString :=
        ADados.ImagemFundoUrl
    else
      Qry.ParamByName('imagem_fundo_url').Clear;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdModelo;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCertificadoModeloDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE certificado_modelo SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdModelo;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
