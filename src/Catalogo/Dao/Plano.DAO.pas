unit Plano.DAO;

interface

uses
  Uni,
  Plano.Model,
  System.Generics.Collections;

type
  TPlanoDAO = class
  public
    class function ExisteDescricao(const AConn: TUniConnection;const ADescricao: string;const AIdPlanoIgnorar: Int64 = 0): Boolean; static;
    class function Inserir(const AConn: TUniConnection;const APlano: TPlanoModel): Int64; static;
    class function Listar(const AConn: TUniConnection;const APesquisa: string = ''): TObjectList<TPlanoModel>; static;
    class function ListarDash(const AConn: TUniConnection): TObjectList<TPlanoModel>; static;
    class function BuscarPorId(const AConn: TUniConnection;const AIdPlano: Int64): TPlanoModel; static;
    class procedure Atualizar(const AConn: TUniConnection;const APlano: TPlanoModel); static;
    class procedure Excluir(const AConn: TUniConnection;const AIdPlano: Int64); static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const APlano: TPlanoModel; const ATipo:Integer=0);
begin

  case Atipo of
    0:begin
      APlano.IdPlano                  := Qry.FieldByName('id_plano').AsLargeInt;
      APlano.Descricao                := Qry.FieldByName('descricao').AsString;
      APlano.Valor                    := Qry.FieldByName('valor').AsCurrency;
      APlano.Catalogo                 := Qry.FieldByName('catalogo').AsString;
      APlano.CatalogoQtde             := Qry.FieldByName('catalogo_qtde').AsInteger;
      APlano.Interno                  := Qry.FieldByName('interno').AsString;
      APlano.Ativo                    := Qry.FieldByName('ativo').AsString;
      APlano.DataCriacao              := Qry.FieldByName('data_criacao').AsDateTime;

      if not Qry.FieldByName('data_alteracao').IsNull then
        APlano.DataAlteracao          := Qry.FieldByName('data_alteracao').AsDateTime;

      APlano.valoranual               := Qry.FieldByName('valoranual').AsCurrency;
      APlano.produtoqtde              := Qry.FieldByName('produtoqtde').AsInteger;
      APlano.recursos                 := Qry.FieldByName('recursos').AsString;

      APlano.PermiteProdutoIlimitado  := Qry.FieldByName('permite_produto_ilimitado').AsString;
      APlano.PermiteWhatsapp          := Qry.FieldByName('permite_whatsapp').AsString;
      APlano.PermiteEmail             := Qry.FieldByName('permite_email').AsString;
      APlano.PermitePedido            := Qry.FieldByName('permite_pedido').AsString;
      APlano.PermiteEcommerce         := Qry.FieldByName('permite_ecommerce').AsString;
      APlano.PermitePagSeguro         := Qry.FieldByName('permite_pagseguro').AsString;
      APlano.PermitePedidoFicha       := Qry.FieldByName('permite_pedido_ficha').AsString;
      APlano.PermiteConfigVisual      := Qry.FieldByName('permite_config_visual').AsString;
      Aplano.permiteconfigcupom       := Qry.FieldByName('permite_config_cupom').AsString;
    end;
    1:begin
      APlano.IdPlano                  := Qry.FieldByName('id_plano').AsLargeInt;
      APlano.Descricao                := Qry.FieldByName('descricao').AsString;
      APlano.Valor                    := Qry.FieldByName('valor').AsCurrency;
      APlano.Catalogo                 := Qry.FieldByName('catalogo').AsString;
      APlano.valoranual               := Qry.FieldByName('valoranual').AsCurrency;
      APlano.produtoqtde              := Qry.FieldByName('produtoqtde').AsInteger;
      APlano.recursos                 := Qry.FieldByName('recursos').AsString;
      APlano.PermiteProdutoIlimitado  := Qry.FieldByName('permite_produto_ilimitado').AsString;
      APlano.PermiteWhatsapp          := Qry.FieldByName('permite_whatsapp').AsString;
      APlano.PermiteEmail             := Qry.FieldByName('permite_email').AsString;
      APlano.PermitePedido            := Qry.FieldByName('permite_pedido').AsString;
      APlano.PermiteEcommerce         := Qry.FieldByName('permite_ecommerce').AsString;
      APlano.PermitePagSeguro         := Qry.FieldByName('permite_pagseguro').AsString;
      APlano.PermitePedidoFicha       := Qry.FieldByName('permite_pedido_ficha').AsString;
      APlano.PermiteConfigVisual      := Qry.FieldByName('permite_config_visual').AsString;
      APlano.permiteconfigcupom       := Qry.FieldByName('permite_config_cupom').AsString;
    end;
  end;




end;

class function TPlanoDAO.ExisteDescricao(const AConn: TUniConnection;const ADescricao: string;const AIdPlanoIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from plano ' +
      ' where lower(trim(descricao)) = lower(trim(:descricao)) ';

    if AIdPlanoIgnorar > 0 then
      Qry.SQL.Add('and id_plano <> :id_plano');

    Qry.ParamByName('descricao').AsString := Trim(ADescricao);

    if AIdPlanoIgnorar > 0 then
      Qry.ParamByName('id_plano').AsLargeInt := AIdPlanoIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TPlanoDAO.Inserir(const AConn: TUniConnection;const APlano: TPlanoModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'insert into plano (' +
      ' descricao, valor, catalogo, catalogo_qtde, interno, ativo, valor_anual, produto_qtde, recursos, ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, permite_ecommerce, '+
      ' permite_pagseguro, permite_pedido_ficha, permite_config_visual, permite_config_cupom'+
      ') VALUES (' +
      ' :descricao, :valor, :catalogo, :catalogo_qtde, :interno, :ativo, :valoranual, :produtoqtde, :recursos, ' +
      ' :permite_produto_ilimitado, :permite_whatsapp, :permite_email, :permite_pedido, '+
      ' :permite_ecommerce, :permite_pagseguro, :permite_pedido_ficha, :permite_config_visual, :permite_config_cupom'+
      ')';

    Qry.ParamByName('descricao').AsString               := Trim(APlano.Descricao);
    Qry.ParamByName('valor').AsCurrency                 := APlano.Valor;
    Qry.ParamByName('catalogo').AsString                := UpperCase(Trim(APlano.Catalogo));
    Qry.ParamByName('catalogo_qtde').AsInteger          := APlano.CatalogoQtde;
    Qry.ParamByName('interno').AsString                 := UpperCase(Trim(APlano.Interno));
    Qry.ParamByName('ativo').AsString                   := UpperCase(Trim(APlano.Ativo));
    Qry.ParamByName('valoranual').AsCurrency            := APlano.valoranual;
    Qry.ParamByName('produtoqtde').AsInteger            := APlano.produtoqtde;
    Qry.ParamByName('recursos').AsString                := Trim(APlano.recursos);
    Qry.ParamByName('permite_produto_ilimitado').AsString := UpperCase(Trim(APlano.permiteprodutoilimitado));
    Qry.ParamByName('permite_whatsapp').AsString        := UpperCase(Trim(APlano.permitewhatsapp));
    Qry.ParamByName('permite_email').AsString           := UpperCase(Trim(APlano.permiteemail));
    Qry.ParamByName('permite_pedido').AsString          := UpperCase(Trim(APlano.permitepedido));
    Qry.ParamByName('permite_ecommerce').AsString       := UpperCase(Trim(APlano.permiteecommerce));
    Qry.ParamByName('permite_pagseguro').AsString       := UpperCase(Trim(APlano.permitepagseguro));
    Qry.ParamByName('permite_pedido_ficha').AsString    := UpperCase(Trim(APlano.permitepedidoficha));
    Qry.ParamByName('permite_config_visual').AsString   := UpperCase(Trim(APlano.permiteconfigvisual));
    qry.ParamByName('permite_config_cupom').AsString    := UpperCase(Aplano.permiteconfigcupom);

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'select last_insert_id() as id_plano';
    Qry.Open;

    Result := Qry.FieldByName('id_plano').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TPlanoDAO.Listar(const AConn: TUniConnection;const APesquisa: string): TObjectList<TPlanoModel>;
var
  Qry: TUniQuery;
  Plano: TPlanoModel;
begin
  Result := TObjectList<TPlanoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' id_plano, descricao, valor, catalogo, catalogo_qtde, interno, ativo, ' +
      ' data_criacao, data_alteracao, valor_anual as valoranual, produto_qtde as produtoqtde, recursos, ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, permite_ecommerce, '+
      ' permite_pagseguro, permite_pedido_ficha, permite_config_visual, permite_config_cupom '+
      ' from plano ' +
      ' where 1 = 1 ';

    if not Trim(APesquisa).IsEmpty then
      Qry.SQL.Add('and loser(descricao) like lower(:pesquisa) ');

    Qry.SQL.Add('order by descricao');

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Plano := TPlanoModel.Create;
      PreencherModel(Qry, Plano);
      Result.Add(Plano);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPlanoDAO.ListarDash(const AConn: TUniConnection): TObjectList<TPlanoModel>;
var
  Qry: TUniQuery;
  Plano: TPlanoModel;
begin
  // Rota para exibir o plano na page principal
  Result := TObjectList<TPlanoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' id_plano, descricao, valor, catalogo, produto_qtde as produtoqtde, ' +
      ' valor_anual as valoranual, recursos, ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, permite_ecommerce, '+
      ' permite_pagseguro, permite_pedido_ficha, permite_config_visual, permite_config_cupom '+
      ' from plano ' +
      ' where ativo = ''S'' ' +
      ' and catalogo = ''S'' ' +
      ' and interno = ''N'' '+
      ' order by valor, descricao';

    Qry.Open;

    while not Qry.Eof do
    begin
      Plano := TPlanoModel.Create;
      PreencherModel(Qry, Plano, 1);
      Result.Add(Plano);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPlanoDAO.BuscarPorId(const AConn: TUniConnection;const AIdPlano: Int64): TPlanoModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' id_plano, descricao, valor, catalogo, catalogo_qtde, interno, ativo, ' +
      ' data_criacao, data_alteracao, valor_anual as valoranual, produto_qtde as produtoqtde, recursos, ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, permite_ecommerce, '+
      ' permite_pagseguro, permite_pedido_ficha, permite_config_visual, permite_config_cupom '+
      ' from plano ' +
      ' where id_plano = :id_plano ' +
      ' limit 1';

    Qry.ParamByName('id_plano').AsLargeInt := AIdPlano;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TPlanoModel.Create;
    PreencherModel(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class procedure TPlanoDAO.Atualizar(const AConn: TUniConnection;const APlano: TPlanoModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'update plano SET ' +
      ' descricao = :descricao, ' +
      ' valor = :valor, ' +
      ' catalogo = :catalogo, ' +
      ' catalogo_qtde = :catalogo_qtde, ' +
      ' interno = :interno, ' +
      ' ativo = :ativo, ' +
      ' data_alteracao = NOW(), ' +
      ' valor_anual = :valor_anual, '+
      ' produto_qtde = :produto_qtde, '+
      ' recursos = :recursos, '+
      ' permite_produto_ilimitado = :permite_produto_ilimitado, '+
      ' permite_whatsapp = :permite_whatsapp, '+
      ' permite_email = :permite_email, '+
      ' permite_pedido = :permite_pedido, '+
      ' permite_ecommerce = :permite_ecommerce, '+
      ' permite_pagseguro = :permite_pagseguro, '+
      ' permite_pedido_ficha = :permite_pedido_ficha, '+
      ' permite_config_visual = :permite_config_visual,'+
      ' permite_config_cupom = :permite_config_cupom  '+
      ' where id_plano = :id_plano';

    Qry.ParamByName('id_plano').AsLargeInt              := APlano.IdPlano;
    Qry.ParamByName('descricao').AsString               := Trim(APlano.Descricao);
    Qry.ParamByName('valor').AsCurrency                 := APlano.Valor;
    Qry.ParamByName('catalogo').AsString                := UpperCase(Trim(APlano.Catalogo));
    Qry.ParamByName('catalogo_qtde').AsInteger          := APlano.CatalogoQtde;
    Qry.ParamByName('interno').AsString                 := UpperCase(Trim(APlano.Interno));
    Qry.ParamByName('ativo').AsString                   := UpperCase(Trim(APlano.Ativo));
    Qry.ParamByName('valor_anual').AsCurrency           := APlano.valoranual;
    Qry.ParamByName('produto_qtde').AsInteger           := APlano.produtoqtde;
    Qry.ParamByName('recursos').AsString                := Trim(APlano.recursos);
    Qry.ParamByName('permite_produto_ilimitado').AsString := UpperCase(Trim(APlano.permiteprodutoilimitado));
    Qry.ParamByName('permite_whatsapp').AsString        := UpperCase(Trim(APlano.permitewhatsapp));
    Qry.ParamByName('permite_email').AsString           := UpperCase(Trim(APlano.permiteemail));
    Qry.ParamByName('permite_pedido').AsString          := UpperCase(Trim(APlano.permitepedido));
    Qry.ParamByName('permite_ecommerce').AsString       := UpperCase(Trim(APlano.permiteecommerce));
    Qry.ParamByName('permite_pagseguro').AsString       := UpperCase(Trim(APlano.permitepagseguro));
    Qry.ParamByName('permite_pedido_ficha').AsString    := UpperCase(Trim(APlano.permitepedidoficha));
    Qry.ParamByName('permite_config_visual').AsString   := UpperCase(Trim(APlano.permiteconfigvisual));
    Qry.ParamByName('permite_config_cupom').AsString    := UpperCase(Aplano.permiteconfigcupom);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlanoDAO.Excluir(const AConn: TUniConnection;const AIdPlano: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'delete from plano ' +
      ' where id_plano = :id_plano';

    Qry.ParamByName('id_plano').AsLargeInt := AIdPlano;
    Qry.Execute;

  finally
    Qry.Free;
  end;
end;

end.
