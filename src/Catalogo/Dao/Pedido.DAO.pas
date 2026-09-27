unit Pedido.DAO;

interface

uses
  Uni,
  Pedido.Model,
  PedidoItem.Model,
  System.Generics.Collections;

type
  TPedidoProdutoDTO = record
    IdProduto: Int64;
    Nome: string;
    Preco: Currency;
    Ativo: string;
  end;

  TPedidoDAO = class
  public
    class function BuscarEmpresaPorSlug(
      const AConn: TUniConnection;
      const ASlug: string;
      out AIdEmpresa: Int64
    ): Boolean; static;

    class function BuscarProdutoAtivo(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      out AProduto: TPedidoProdutoDTO
    ): Boolean; static;

    class function InserirPedido(
      const AConn: TUniConnection;
      const APedido: TPedidoModel
    ): Int64; static;

    class function InserirItem(
      const AConn: TUniConnection;
      const AItem: TPedidoItemModel
    ): Int64; static;

    class procedure AtualizarValorTotal(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdPedido: Int64;
      const AValorTotal: Currency
    ); static;

    class function ListarPorEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ): TObjectList<TPedidoModel>; static;

    class function BuscarPorIdEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdPedido: Int64
    ): TPedidoModel; static;

    class function ListarItens(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdPedido: Int64
    ): TObjectList<TPedidoItemModel>; static;

    class procedure AtualizarStatus(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdPedido: Int64;
      const AStatus: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPedidoDAO.BuscarEmpresaPorSlug(const AConn: TUniConnection;const ASlug: string;out AIdEmpresa: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AIdEmpresa := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT cc.id_empresa ' +
      ' FROM catalogo_config cc ' +
      ' INNER JOIN empresa e ON e.id_empresa = cc.id_empresa ' +
      ' WHERE LOWER(TRIM(cc.slug)) = LOWER(TRIM(:slug)) ' +
      ' AND cc.ativo = ''S'' ' +
      ' AND e.ativo = ''S'' ' +
      //' AND e.data_validade >= CURDATE() ' +
      ' LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit(False);

    AIdEmpresa    := Qry.FieldByName('id_empresa').AsLargeInt;
    Result        := AIdEmpresa > 0;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.BuscarProdutoAtivo(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  out AProduto: TPedidoProdutoDTO
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  AProduto.IdProduto := 0;
  AProduto.Nome := '';
  AProduto.Preco := 0;
  AProduto.Ativo := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id_produto, nome, preco, ativo ' +
      'FROM produto ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_produto = :id_produto ' +
      'AND ativo = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt := AIdProduto;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(False);

    AProduto.IdProduto := Qry.FieldByName('id_produto').AsLargeInt;
    AProduto.Nome := Qry.FieldByName('nome').AsString;
    AProduto.Preco := Qry.FieldByName('preco').AsCurrency;
    AProduto.Ativo := Qry.FieldByName('ativo').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.InserirPedido(const AConn: TUniConnection;const APedido: TPedidoModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO pedido (' +
      ' id_empresa, nome_cliente, whatsapp_cliente, email_cliente, observacao, ' +
      ' tipo_entrega, endereco_entrega, status, valor_total ' +
      ') VALUES (' +
      ' :id_empresa, :nome_cliente, :whatsapp_cliente, :email_cliente, :observacao, ' +
      ' :tipo_entrega, :endereco_entrega, :status, :valor_total ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt      := APedido.IdEmpresa;
    Qry.ParamByName('nome_cliente').AsString      := Trim(APedido.NomeCliente);
    Qry.ParamByName('whatsapp_cliente').AsString  := Trim(APedido.WhatsappCliente);
    Qry.ParamByName('email_cliente').AsString     := LowerCase(Trim(APedido.EmailCliente));
    Qry.ParamByName('observacao').AsString        := Trim(APedido.Observacao);
    Qry.ParamByName('tipo_entrega').AsString      := UpperCase(Trim(APedido.TipoEntrega));
    Qry.ParamByName('endereco_entrega').AsString  := Trim(APedido.EnderecoEntrega);
    Qry.ParamByName('status').AsString            := UpperCase(Trim(APedido.Status));
    Qry.ParamByName('valor_total').AsCurrency     := APedido.ValorTotal;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_pedido';
    Qry.Open;

    Result := Qry.FieldByName('id_pedido').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.InserirItem(const AConn: TUniConnection;const AItem: TPedidoItemModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO pedido_item (' +
      ' id_pedido, id_empresa, id_produto, nome_produto, quantidade, ' +
      ' valor_unitario, valor_total, observacao ' +
      ') VALUES (' +
      ' :id_pedido, :id_empresa, :id_produto, :nome_produto, :quantidade, ' +
      ' :valor_unitario, :valor_total, :observacao ' +
      ')';

    Qry.ParamByName('id_pedido').AsLargeInt       := AItem.IdPedido;
    Qry.ParamByName('id_empresa').AsLargeInt      := AItem.IdEmpresa;
    Qry.ParamByName('id_produto').AsLargeInt      := AItem.IdProduto;
    Qry.ParamByName('nome_produto').AsString      := Trim(AItem.NomeProduto);
    Qry.ParamByName('quantidade').AsCurrency      := AItem.Quantidade;
    Qry.ParamByName('valor_unitario').AsCurrency  := AItem.ValorUnitario;
    Qry.ParamByName('valor_total').AsCurrency     := AItem.ValorTotal;
    Qry.ParamByName('observacao').AsString        := Trim(AItem.Observacao);

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_item';
    Qry.Open;

    Result := Qry.FieldByName('id_item').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TPedidoDAO.AtualizarValorTotal(const AConn: TUniConnection;const AIdEmpresa: Int64;
                                  const AIdPedido: Int64;const AValorTotal: Currency);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE pedido SET ' +
      ' valor_total = :valor_total, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_pedido = :id_pedido';

    Qry.ParamByName('valor_total').AsCurrency   := AValorTotal;
    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;
    Qry.ParamByName('id_pedido').AsLargeInt     := AIdPedido;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.ListarPorEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
): TObjectList<TPedidoModel>;
var
  Qry: TUniQuery;
  Pedido: TPedidoModel;
begin
  Result := TObjectList<TPedidoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_pedido, id_empresa, nome_cliente, whatsapp_cliente, email_cliente, ' +
      ' observacao, tipo_entrega, endereco_entrega, status, valor_total, ' +
      ' data_criacao, data_alteracao ' +
      'FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY data_criacao DESC, id_pedido DESC';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Pedido := TPedidoModel.Create;
      Pedido.IdPedido := Qry.FieldByName('id_pedido').AsLargeInt;
      Pedido.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
      Pedido.NomeCliente := Qry.FieldByName('nome_cliente').AsString;
      Pedido.WhatsappCliente := Qry.FieldByName('whatsapp_cliente').AsString;
      Pedido.EmailCliente := Qry.FieldByName('email_cliente').AsString;
      Pedido.Observacao := Qry.FieldByName('observacao').AsString;
      Pedido.TipoEntrega := Qry.FieldByName('tipo_entrega').AsString;
      Pedido.EnderecoEntrega := Qry.FieldByName('endereco_entrega').AsString;
      Pedido.Status := Qry.FieldByName('status').AsString;
      Pedido.ValorTotal := Qry.FieldByName('valor_total').AsCurrency;
      Pedido.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

      if not Qry.FieldByName('data_alteracao').IsNull then
        Pedido.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;

      Result.Add(Pedido);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.BuscarPorIdEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdPedido: Int64
): TPedidoModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_pedido, id_empresa, nome_cliente, whatsapp_cliente, email_cliente, ' +
      ' observacao, tipo_entrega, endereco_entrega, status, valor_total, ' +
      ' data_criacao, data_alteracao ' +
      'FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_pedido = :id_pedido ' +
      'LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_pedido').AsLargeInt := AIdPedido;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TPedidoModel.Create;
    Result.IdPedido := Qry.FieldByName('id_pedido').AsLargeInt;
    Result.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
    Result.NomeCliente := Qry.FieldByName('nome_cliente').AsString;
    Result.WhatsappCliente := Qry.FieldByName('whatsapp_cliente').AsString;
    Result.EmailCliente := Qry.FieldByName('email_cliente').AsString;
    Result.Observacao := Qry.FieldByName('observacao').AsString;
    Result.TipoEntrega := Qry.FieldByName('tipo_entrega').AsString;
    Result.EnderecoEntrega := Qry.FieldByName('endereco_entrega').AsString;
    Result.Status := Qry.FieldByName('status').AsString;
    Result.ValorTotal := Qry.FieldByName('valor_total').AsCurrency;
    Result.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

    if not Qry.FieldByName('data_alteracao').IsNull then
      Result.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
  finally
    Qry.Free;
  end;
end;

class function TPedidoDAO.ListarItens(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdPedido: Int64
): TObjectList<TPedidoItemModel>;
var
  Qry: TUniQuery;
  Item: TPedidoItemModel;
begin
  Result := TObjectList<TPedidoItemModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_item, id_pedido, id_empresa, id_produto, nome_produto, quantidade, ' +
      ' valor_unitario, valor_total, observacao, data_criacao ' +
      'FROM pedido_item ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_pedido = :id_pedido ' +
      'ORDER BY id_item';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_pedido').AsLargeInt := AIdPedido;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TPedidoItemModel.Create;
      Item.IdItem := Qry.FieldByName('id_item').AsLargeInt;
      Item.IdPedido := Qry.FieldByName('id_pedido').AsLargeInt;
      Item.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
      Item.IdProduto := Qry.FieldByName('id_produto').AsLargeInt;
      Item.NomeProduto := Qry.FieldByName('nome_produto').AsString;
      Item.Quantidade := Qry.FieldByName('quantidade').AsCurrency;
      Item.ValorUnitario := Qry.FieldByName('valor_unitario').AsCurrency;
      Item.ValorTotal := Qry.FieldByName('valor_total').AsCurrency;
      Item.Observacao := Qry.FieldByName('observacao').AsString;
      Item.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

      Result.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TPedidoDAO.AtualizarStatus(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdPedido: Int64;
  const AStatus: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE pedido SET ' +
      ' status = :status, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_pedido = :id_pedido';

    Qry.ParamByName('status').AsString := UpperCase(Trim(AStatus));
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_pedido').AsLargeInt := AIdPedido;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
