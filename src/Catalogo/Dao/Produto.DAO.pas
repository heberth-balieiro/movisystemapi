unit Produto.DAO;

interface

uses
  Uni,
  Produto.Model,
  System.Generics.Collections;

type
  TProdutoDAO = class
  private
    

  public
    class function ProdutoPossuiImagem(const AConn: TUniConnection;const AIdEmpresa, AIdProduto: Int64): Boolean; static;
    class function ProdutoPossuiPedido(const AConn: TUniConnection;const AIdEmpresa, AIdProduto: Int64): Boolean; static;
    class function ExisteNome(const AConn: TUniConnection;const AIdEmpresa: Int64;const ANome: string;const AIdProdutoIgnorar: Int64 = 0): Boolean; static;
    class function CategoriaPertenceEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCategoria: Int64): Boolean; static;
    class function Inserir(const AConn: TUniConnection;const AProduto: TProdutoModel): Int64; static;
    class function ListarProdutos(const AConn: TUniConnection;const AIdEmpresa: Int64): TObjectList<TProdutoModel>; static;
    class function BuscarPorIdEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64): TProdutoModel; static;
    class procedure Atualizar(const AConn: TUniConnection;const AProduto: TProdutoModel); static;
    class procedure Excluir(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64); static;
    class procedure ExcluirImagem(const AConn: TUniConnection; const AIdEmpresa,AIdProduto: Int64); static;

    class function ContarProdutosEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): Integer; static;



  end;

implementation

uses
  System.SysUtils;

class function TProdutoDAO.ExisteNome(const AConn: TUniConnection;const AIdEmpresa: Int64;const ANome: string;const AIdProdutoIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from produto ' +
      ' where id_empresa = :id_empresa ' +
      ' and lower(trim(nome)) = lower(trim(:nome)) ';

    if AIdProdutoIgnorar > 0 then
      Qry.SQL.Add('and id_produto <> :id_produto');

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('nome').AsString := Trim(ANome);

    if AIdProdutoIgnorar > 0 then
      Qry.ParamByName('id_produto').AsLargeInt := AIdProdutoIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.CategoriaPertenceEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCategoria: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Select Count(*) as total ' +
      ' from categoria ' +
      ' where id_empresa = :id_empresa ' +
      ' and id_categoria = :id_categoria';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt := AIdCategoria;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.ContarProdutosEmpresa(const AConn: TUniConnection; const AIdEmpresa: Int64): Integer;
var
  Qry: TUniQuery;
const
  QryStr =
    ' select count(*) as total ' +
    ' from produto ' +
    ' where id_empresa = :id_empresa ';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.Inserir(const AConn: TUniConnection;const AProduto: TProdutoModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Insert into produto (' +
      ' id_empresa,id_categoria,nome,descricao,preco,ativo,destaque,ordem, '+
      ' codigo, id_marca, id_unidade, promocao, referencia, tags '+
      ') values (' +
      ' :id_empresa, :id_categoria, :nome, :descricao, :preco, :ativo, :destaque,'+
      ' :ordem, :codigo, :id_marca, :id_unidade, :promocao, :referencia, :tags' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt        := AProduto.IdEmpresa;
    Qry.ParamByName('id_categoria').AsLargeInt      := AProduto.IdCategoria;
    Qry.ParamByName('nome').AsString                := Trim(AProduto.Nome);
    Qry.ParamByName('descricao').AsString           := Trim(AProduto.Descricao);
    Qry.ParamByName('preco').AsCurrency             := AProduto.Preco;
    Qry.ParamByName('ativo').AsString               := UpperCase(Trim(AProduto.Ativo));
    Qry.ParamByName('destaque').AsString            := UpperCase(Trim(AProduto.Destaque));
    Qry.ParamByName('ordem').AsInteger              := AProduto.Ordem;
    Qry.ParamByName('codigo').AsString              := Trim(AProduto.codigo);
    Qry.ParamByName('id_marca').AsLargeInt          := AProduto.idmarca;
    Qry.ParamByName('id_unidade').AsLargeInt        := AProduto.idunidade;
    Qry.ParamByName('promocao').AsCurrency          := AProduto.promocao;
    Qry.ParamByName('referencia').AsString          := Trim(AProduto.referencia);
    Qry.ParamByName('tags').AsString                := Trim(AProduto.tags);

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'Select last_insert_id() as id_produto';
    Qry.Open;

    Result := Qry.FieldByName('id_produto').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.ListarProdutos(const AConn: TUniConnection;const AIdEmpresa: Int64): TObjectList<TProdutoModel>;
var
  Qry: TUniQuery;
  Produto: TProdutoModel;
begin
  Result := TObjectList<TProdutoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' p.id_produto, p.nome, Coalesce(p.preco,0) as preco, Coalesce(p.promocao,0) as promocao, p.destaque, p.ordem, ' +
      ' p.ativo, u.sigla, p.referencia, c.nome as nmcategoria, m.nome as nmmarca '+
      ' from produto p ' +
      ' left join unidade u   '+
      ' on p.id_unidade = u.id_unidade '+
      ' Left join categoria c '+
      ' on p.id_categoria = c.id_categoria'+
      ' Left join marca m '+
      ' on p.id_marca = m.id_marca '+
      ' where p.id_empresa = :id_empresa ' +
      ' order by p.nome, c.nome';

    Qry.ParamByName('id_empresa').AsLargeInt      := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Produto                   := TProdutoModel.Create;
      Produto.IdProduto         := Qry.FieldByName('id_produto').AsLargeInt;
      Produto.Nome              := Qry.FieldByName('nome').AsString;
      Produto.Preco             := Qry.FieldByName('preco').AsCurrency;
      Produto.promocao          := Qry.FieldByName('promocao').AsCurrency;
      Produto.Destaque          := Qry.FieldByName('destaque').AsString;
      Produto.Ordem             := Qry.FieldByName('ordem').AsInteger;
      Produto.Ativo             := Qry.FieldByName('ativo').AsString;
      Produto.sigla             := Qry.FieldByName('sigla').AsString;
      Produto.referencia        := Qry.FieldByName('referencia').AsString;
      Produto.nmcategoria       := Qry.FieldByName('nmcategoria').AsString;
      Produto.nmmarca           := Qry.FieldByName('nmmarca').AsString;


//      Produto.IdEmpresa         := Qry.FieldByName('id_empresa').AsLargeInt;
//      Produto.IdCategoria       := Qry.FieldByName('id_categoria').AsLargeInt;
//      Produto.Descricao         := Qry.FieldByName('descricao').AsString;
//      Produto.DataCriacao       := Qry.FieldByName('data_criacao').AsDateTime;
//      if not Qry.FieldByName('data_alteracao').IsNull then
//        Produto.DataAlteracao   := Qry.FieldByName('data_alteracao').AsDateTime;
//      Produto.imagem_principal  := Qry.FieldByName('imagem_principal').AsString;
//      Produto.codigo            := Qry.FieldByName('codigo').AsString;
//      Produto.idmarca             := Qry.FieldByName('id_marca').AsLargeInt;
//      Produto.idunidade         := Qry.FieldByName('id_unidade').AsLargeInt;
//      Produto.tags              := Qry.FieldByName('tags').AsString;



      Result.Add(Produto);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.BuscarPorIdEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64): TProdutoModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Select ' +
      ' p.id_produto, p.id_empresa, p.id_categoria, p.nome, p.descricao, p.preco, ' +
      ' p.ativo, p.destaque, p.ordem, p.data_criacao, p.data_alteracao, '+
      ' pi.url_imagem as imagem_principal, p.codigo, p.id_marca, p.id_unidade, u.sigla, ' +
      ' p.promocao, p.referencia, p.tags '+
      ' from produto p ' +
      ' left join produto_imagem pi  '+
      ' on p.id_produto = pi.id_produto  ' +
      ' left join unidade u  '+
      ' on p.id_unidade = u.id_unidade  '+
      ' where p.id_empresa = :id_empresa ' +
      ' and p.id_produto = :id_produto ' +
      ' limit 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result                    := TProdutoModel.Create;
    Result.IdProduto          := Qry.FieldByName('id_produto').AsLargeInt;
    //Result.IdEmpresa          := Qry.FieldByName('id_empresa').AsLargeInt;
    Result.IdCategoria        := Qry.FieldByName('id_categoria').AsLargeInt;
    Result.Nome               := Qry.FieldByName('nome').AsString;
    Result.Descricao          := Qry.FieldByName('descricao').AsString;
    Result.Preco              := Qry.FieldByName('preco').AsCurrency;
    Result.Ativo              := Qry.FieldByName('ativo').AsString;
    Result.Destaque           := Qry.FieldByName('destaque').AsString;
    Result.Ordem              := Qry.FieldByName('ordem').AsInteger;
    Result.imagem_principal   := Qry.FieldByName('imagem_principal').AsString;
    Result.codigo             := Qry.FieldByName('codigo').AsString;
    Result.idmarca            := Qry.FieldByName('id_marca').AsLargeInt;
    Result.idunidade          := Qry.FieldByName('id_unidade').AsLargeInt;
    Result.sigla              := Qry.FieldByName('sigla').AsString;
    Result.promocao           := Qry.FieldByName('promocao').AsCurrency;
    Result.referencia         := Qry.FieldByName('referencia').AsString;
    Result.tags               := Qry.FieldByName('tags').AsString;

  finally
    Qry.Free;
  end;
end;

class procedure TProdutoDAO.Atualizar(const AConn: TUniConnection;const AProduto: TProdutoModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'update produto set ' +
      ' id_categoria = :id_categoria, ' +
      ' nome = :nome, ' +
      ' descricao = :descricao, ' +
      ' preco = :preco, ' +
      ' ativo = :ativo, ' +
      ' destaque = :destaque, ' +
      ' ordem = :ordem, ' +
      ' data_alteracao = NOW(), ' +
      ' codigo = :codigo,  '+
      ' id_marca = :idmarca,   '+
      ' id_unidade = :id_unidade,  '+
      ' promocao = :promocao,'+
      ' referencia = :referencia,'+
      ' tags = :tags '+
      ' where id_empresa = :id_empresa ' +
      ' and id_produto = :id_produto';

    Qry.ParamByName('id_categoria').AsLargeInt  := AProduto.IdCategoria;
    Qry.ParamByName('nome').AsString            := Trim(AProduto.Nome);
    Qry.ParamByName('descricao').AsString       := Trim(AProduto.Descricao);
    Qry.ParamByName('preco').AsCurrency         := AProduto.Preco;
    Qry.ParamByName('ativo').AsString           := UpperCase(Trim(AProduto.Ativo));
    Qry.ParamByName('destaque').AsString        := UpperCase(Trim(AProduto.Destaque));
    Qry.ParamByName('ordem').AsInteger          := AProduto.Ordem;
    Qry.ParamByName('codigo').AsString          := Trim(AProduto.codigo);
    Qry.ParamByName('idmarca').AsLargeInt       := AProduto.idmarca;
    Qry.ParamByName('id_unidade').AsLargeInt    := AProduto.idunidade;
    Qry.ParamByName('id_empresa').AsLargeInt    := AProduto.IdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt    := AProduto.IdProduto;
    Qry.ParamByName('promocao').AsCurrency      := AProduto.promocao;
    Qry.ParamByName('referencia').AsString      := Trim(AProduto.referencia);
    Qry.ParamByName('tags').AsString            := Trim(AProduto.tags);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

{$REGION 'Funcao para exclusao'}

class function TProdutoDAO.ProdutoPossuiImagem(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from produto_imagem ' +
      ' where id_empresa = :id_empresa ' +
      ' and id_produto = :id_produto';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TProdutoDAO.ProdutoPossuiPedido(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from pedido_item ' +
      ' where id_empresa = :id_empresa ' +
      ' and id_produto = :id_produto';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TProdutoDAO.Excluir(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Delete from produto ' +
      ' where id_empresa = :id_empresa ' +
      ' and id_produto = :id_produto';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;


class procedure TProdutoDAO.ExcluirImagem(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdProduto: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM produto_imagem ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;



{$ENDREGION}


end.
