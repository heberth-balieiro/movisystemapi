unit InstituicaoCursoCategoria.DAO;

interface

uses
  Uni,
  InstituicaoCursoCategoria.Model;

type
  TInstituicaoCursoCategoriaDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoCursoCategoriaFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCursoCategoriaFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoCursoCategoriaItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoCursoCategoriaFiltro
    ): TInstituicaoCursoCategoriaLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCategoria: Int64
    ): TInstituicaoCursoCategoriaItem; static;

    class function ExisteNome(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ANome: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoCursoCategoriaCadastro
    ): Int64; static;

    class function Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCategoria: Int64;
      const ADados: TInstituicaoCursoCategoriaAlteracao
    ): Boolean; static;

    class function AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCategoria: Int64;
      const ASituacao: string
    ): Boolean; static;

    class function ExisteCategoriaAtiva(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCategoria: Int64
    ): Boolean; static;


  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoCursoCategoriaDAO.ExisteCategoriaAtiva(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCategoria: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdCategoria <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM curso_categoria ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_categoria ' +
      'AND situacao = ''ATIVA'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_categoria').AsLargeInt :=
      AIdCategoria;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoCategoriaDAO.MontarWhere(
  const AFiltro: TInstituicaoCursoCategoriaFiltro
): string;
begin
  Result :=
    ' WHERE c.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result :=
      Result +
      ' AND (' +
      'c.nome LIKE :busca OR ' +
      'c.descricao LIKE :busca' +
      ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
  begin
    Result :=
      Result +
      ' AND c.situacao = :situacao ';
  end;
end;

class procedure TInstituicaoCursoCategoriaDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCursoCategoriaFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
  begin
    AQry.ParamByName('situacao').AsString :=
      UpperCase(
        Trim(AFiltro.Situacao)
      );
  end;
end;

class function TInstituicaoCursoCategoriaDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoCursoCategoriaItem;
begin
  Result :=
    TInstituicaoCursoCategoriaItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Descricao :=
    AQry.FieldByName('descricao').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoCursoCategoriaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoCursoCategoriaFiltro
): TInstituicaoCursoCategoriaLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TInstituicaoCursoCategoriaLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina :=
        AFiltro.Pagina;

      Result.PorPagina :=
        AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(AFiltro);

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      // Total
      Qry.SQL.Text :=
        'SELECT COUNT(*) total ' +
        'FROM curso_categoria c ' +
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

      // Registros
      Qry.SQL.Text :=
        'SELECT ' +
        'c.id, ' +
        'c.nome, ' +
        'c.descricao, ' +
        'c.situacao, ' +
        'c.criado_em, ' +
        'c.atualizado_em ' +
        'FROM curso_categoria c ' +
        WhereSQL +
        'ORDER BY c.nome, c.id ' +
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

class function TInstituicaoCursoCategoriaDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCategoria: Int64
): TInstituicaoCursoCategoriaItem;
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
      'c.nome, ' +
      'c.descricao, ' +
      'c.situacao, ' +
      'c.criado_em, ' +
      'c.atualizado_em ' +
      'FROM curso_categoria c ' +
      'WHERE c.id_instituicao = :id_instituicao ' +
      'AND c.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdCategoria;

    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoCategoriaDAO.ExisteNome(
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
      'FROM curso_categoria ' +
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
    begin
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;
    end;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoCategoriaDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoCursoCategoriaCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO curso_categoria (' +
      'id_instituicao, ' +
      'nome, ' +
      'descricao, ' +
      'situacao' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':nome, ' +
      ':descricao, ' +
      '''ATIVA''' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not Trim(ADados.Descricao).IsEmpty then
    begin
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao;
    end
    else
      Qry.ParamByName('descricao').Clear;

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

class function TInstituicaoCursoCategoriaDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCategoria: Int64;
  const ADados: TInstituicaoCursoCategoriaAlteracao
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE curso_categoria SET ' +
      'nome = :nome, ' +
      'descricao = :descricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    if not Trim(ADados.Descricao).IsEmpty then
      Qry.ParamByName('descricao').AsString :=
        ADados.Descricao
    else
      Qry.ParamByName('descricao').Clear;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdCategoria;

    Qry.ExecSQL;

    Result :=
      Qry.RowsAffected > 0;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoCategoriaDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCategoria: Int64;
  const ASituacao: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE curso_categoria SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdCategoria;

    Qry.ExecSQL;

    Result :=
      Qry.RowsAffected > 0;

  finally
    Qry.Free;
  end;
end;

end.
