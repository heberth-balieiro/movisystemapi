unit ProdutoImagem.DAO;

interface

uses
  Uni,
  ProdutoImagem.Model,
  System.Generics.Collections;

type
  TProdutoImagemDAO = class
  public
    class function ProdutoPertenceEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64
    ): Boolean; static;

    class procedure LimparImagemPrincipal(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64
    ); static;

    class function Inserir(
      const AConn: TUniConnection;
      const AImagem: TProdutoImagemModel
    ): Int64; static;

    class function ListarPorProduto(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64
    ): TObjectList<TProdutoImagemModel>; static;

    class function BuscarPorIdEmpresaProduto(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AIdImagem: Int64
    ): TProdutoImagemModel; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AImagem: TProdutoImagemModel
    ); static;

    class procedure Excluir(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AIdImagem: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TProdutoImagemDAO.ProdutoPertenceEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64
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
      'FROM produto ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TProdutoImagemDAO.LimparImagemPrincipal(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE produto_imagem SET ' +
      ' principal = ''N'', ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TProdutoImagemDAO.Inserir(
  const AConn: TUniConnection;
  const AImagem: TProdutoImagemModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO produto_imagem (' +
      ' id_empresa, id_produto, url_imagem, principal, ordem ' +
      ') VALUES (' +
      ' :id_empresa, :id_produto, :url_imagem, :principal, :ordem ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := AImagem.IdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AImagem.IdProduto;
    Qry.ParamByName('url_imagem').AsString := Trim(AImagem.UrlImagem);
    Qry.ParamByName('principal').AsString := UpperCase(Trim(AImagem.Principal));
    Qry.ParamByName('ordem').AsInteger := AImagem.Ordem;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_imagem';
    Qry.Open;

    Result := Qry.FieldByName('id_imagem').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TProdutoImagemDAO.ListarPorProduto(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64
): TObjectList<TProdutoImagemModel>;
var
  Qry: TUniQuery;
  Imagem: TProdutoImagemModel;
begin
  Result := TObjectList<TProdutoImagemModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_imagem, id_empresa, id_produto, url_imagem, principal, ordem, ' +
      ' data_criacao, data_alteracao ' +
      'FROM produto_imagem ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ' +
      'ORDER BY principal DESC, ordem, id_imagem';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;

    while not Qry.Eof do
    begin
      Imagem := TProdutoImagemModel.Create;
      Imagem.IdImagem := Qry.FieldByName('id_imagem').AsLargeInt;
      Imagem.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
      Imagem.IdProduto := Qry.FieldByName('id_produto').AsLargeInt;
      Imagem.UrlImagem := Qry.FieldByName('url_imagem').AsString;
      Imagem.Principal := Qry.FieldByName('principal').AsString;
      Imagem.Ordem := Qry.FieldByName('ordem').AsInteger;
      Imagem.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

      if not Qry.FieldByName('data_alteracao').IsNull then
        Imagem.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;

      Result.Add(Imagem);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TProdutoImagemDAO.BuscarPorIdEmpresaProduto(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AIdImagem: Int64
): TProdutoImagemModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_imagem, id_empresa, id_produto, url_imagem, principal, ordem, ' +
      ' data_criacao, data_alteracao ' +
      'FROM produto_imagem ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ' +
      'AND id_imagem = :id_imagem ' +
      'LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.ParamByName('id_imagem').AsLargeInt := AIdImagem;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TProdutoImagemModel.Create;
    Result.IdImagem := Qry.FieldByName('id_imagem').AsLargeInt;
    Result.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
    Result.IdProduto := Qry.FieldByName('id_produto').AsLargeInt;
    Result.UrlImagem := Qry.FieldByName('url_imagem').AsString;
    Result.Principal := Qry.FieldByName('principal').AsString;
    Result.Ordem := Qry.FieldByName('ordem').AsInteger;
    Result.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

    if not Qry.FieldByName('data_alteracao').IsNull then
      Result.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
  finally
    Qry.Free;
  end;
end;

class procedure TProdutoImagemDAO.Atualizar(
  const AConn: TUniConnection;
  const AImagem: TProdutoImagemModel
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE produto_imagem SET ' +
      ' url_imagem = :url_imagem, ' +
      ' principal = :principal, ' +
      ' ordem = :ordem, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ' +
      'AND id_imagem = :id_imagem';

    Qry.ParamByName('url_imagem').AsString := Trim(AImagem.UrlImagem);
    Qry.ParamByName('principal').AsString := UpperCase(Trim(AImagem.Principal));
    Qry.ParamByName('ordem').AsInteger := AImagem.Ordem;
    Qry.ParamByName('id_empresa').AsLargeInt := AImagem.IdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AImagem.IdProduto;
    Qry.ParamByName('id_imagem').AsLargeInt := AImagem.IdImagem;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TProdutoImagemDAO.Excluir(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AIdImagem: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM produto_imagem ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ' +
      'AND id_imagem = :id_imagem';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.ParamByName('id_imagem').AsLargeInt := AIdImagem;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
