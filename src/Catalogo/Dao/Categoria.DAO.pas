unit Categoria.DAO;

interface

uses
  Uni,
  Categoria.Model,
  System.Generics.Collections;

type
  TCategoriaDAO = class
  public
    class function ExisteNome(const AConn: TUniConnection; const AIdEmpresa: Int64; const ANome: string; const AIdCategoriaIgnorar: Int64 = 0): Boolean; static;

    class function Inserir(const AConn: TUniConnection; const ACategoria: TCategoriaModel): Int64; static;

    class function ListarPorEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TObjectList<TCategoriaModel>; static;

    class function BuscarPorIdEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCategoria: Int64): TCategoriaModel; static;

    class procedure Atualizar(const AConn: TUniConnection;const ACategoria: TCategoriaModel); static;class procedure Excluir(
      const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCategoria: Int64); static;

    class procedure AtualizarImagem(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCategoria: Int64;const AImagemUrl: string); static;

  end;

implementation

uses
  System.SysUtils;

class function TCategoriaDAO.ExisteNome(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const ANome: string;
  const AIdCategoriaIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM categoria ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND LOWER(TRIM(nome)) = LOWER(TRIM(:nome)) ';

    if AIdCategoriaIgnorar > 0 then
      Qry.SQL.Add('AND id_categoria <> :id_categoria');

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('nome').AsString := Trim(ANome);

    if AIdCategoriaIgnorar > 0 then
      Qry.ParamByName('id_categoria').AsLargeInt := AIdCategoriaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TCategoriaDAO.Inserir(
  const AConn: TUniConnection;
  const ACategoria: TCategoriaModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO categoria (' +
      ' id_empresa, nome, descricao, ativo, ordem, imagem_url ' +
      ') VALUES (' +
      ' :id_empresa, :nome, :descricao, :ativo, :ordem, :imagem_url ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := ACategoria.IdEmpresa;
    Qry.ParamByName('nome').AsString := Trim(ACategoria.Nome);
    Qry.ParamByName('descricao').AsString := Trim(ACategoria.Descricao);
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(ACategoria.Ativo));
    Qry.ParamByName('ordem').AsInteger := ACategoria.Ordem;
    Qry.ParamByName('imagem_url').AsString := Trim(ACategoria.imagemurl);

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_categoria';
    Qry.Open;

    Result := Qry.FieldByName('id_categoria').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TCategoriaDAO.ListarPorEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TObjectList<TCategoriaModel>;
var
  Qry: TUniQuery;
  Categoria: TCategoriaModel;
begin
  Result := TObjectList<TCategoriaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Select id_categoria, nome, descricao, ativo, ordem from categoria ' +
      ' where id_empresa = :id_empresa order by ordem, nome';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Categoria                 := TCategoriaModel.Create;
      Categoria.IdCategoria     := Qry.FieldByName('id_categoria').AsLargeInt;
      Categoria.Nome            := Qry.FieldByName('nome').AsString;
      Categoria.Descricao       := Qry.FieldByName('descricao').AsString;
      Categoria.Ativo           := Qry.FieldByName('ativo').AsString;
      Categoria.Ordem           := Qry.FieldByName('ordem').AsInteger;

      Result.Add(Categoria);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TCategoriaDAO.AtualizarImagem(const AConn: TUniConnection;
  const AIdEmpresa, AIdCategoria: Int64; const AImagemUrl: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE categoria SET ' +
      ' imagem_url = :imagem_url, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_categoria = :id_categoria';
    Qry.ParamByName('imagem_url').AsString      := AImagemUrl;
    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt  := AIdCategoria;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TCategoriaDAO.BuscarPorIdEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdCategoria: Int64
): TCategoriaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Select id_categoria, nome, descricao, ativo, ordem, imagem_url from categoria ' +
      ' where id_empresa = :id_empresa and id_categoria = :id_categoria LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt := AIdCategoria;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result                := TCategoriaModel.Create;
    Result.IdCategoria    := Qry.FieldByName('id_categoria').AsLargeInt;
    Result.Nome           := Qry.FieldByName('nome').AsString;
    Result.Descricao      := Qry.FieldByName('descricao').AsString;
    Result.Ativo          := Qry.FieldByName('ativo').AsString;
    Result.Ordem          := Qry.FieldByName('ordem').AsInteger;
   Result.ImagemUrl       := Qry.FieldByName('imagem_url').AsString;

  finally
    Qry.Free;
  end;
end;

class procedure TCategoriaDAO.Atualizar(
  const AConn: TUniConnection;
  const ACategoria: TCategoriaModel
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE categoria SET ' +
      ' nome = :nome, ' +
      ' descricao = :descricao, ' +
      ' ativo = :ativo, ' +
      ' ordem = :ordem, ' +
      ' data_alteracao = NOW(), ' +
      ' imagem_url = :imagem_url '+
      ' WHERE id_empresa = :id_empresa ' +
      ' AND id_categoria = :id_categoria';

    Qry.ParamByName('nome').AsString            := Trim(ACategoria.Nome);
    Qry.ParamByName('descricao').AsString       := Trim(ACategoria.Descricao);
    Qry.ParamByName('ativo').AsString           := UpperCase(Trim(ACategoria.Ativo));
    Qry.ParamByName('ordem').AsInteger          := ACategoria.Ordem;
    Qry.ParamByName('id_empresa').AsLargeInt    := ACategoria.IdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt  := ACategoria.IdCategoria;
    Qry.ParamByName('imagem_url').AsString      := Trim(ACategoria.imagemurl);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TCategoriaDAO.Excluir(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdCategoria: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM categoria ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_categoria = :id_categoria';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt := AIdCategoria;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
