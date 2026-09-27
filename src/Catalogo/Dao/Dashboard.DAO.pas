unit Dashboard.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TDashboardDAO = class
  public
    class function BuscarResumo(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils;

function GetCount(
  const AConn: TUniConnection;
  const ASQL: string;
  const AIdEmpresa: Int64
): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ASQL;
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    Result := Qry.Fields[0].AsInteger;
  finally
    Qry.Free;
  end;
end;

function GetCurrency(
  const AConn: TUniConnection;
  const ASQL: string;
  const AIdEmpresa: Int64
): Currency;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ASQL;
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    Result := Qry.Fields[0].AsCurrency;
  finally
    Qry.Free;
  end;
end;

function BuscarUltimosPedidos(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
): TJSONArray;
var
  Qry: TUniQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_pedido, nome_cliente, whatsapp_cliente, status, valor_total, data_criacao ' +
      'FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY data_criacao DESC, id_pedido DESC ' +
      'LIMIT 5';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('id_pedido', TJSONNumber.Create(Qry.FieldByName('id_pedido').AsLargeInt));
      Item.AddPair('nome_cliente', Qry.FieldByName('nome_cliente').AsString);
      Item.AddPair('whatsapp_cliente', Qry.FieldByName('whatsapp_cliente').AsString);
      Item.AddPair('status', Qry.FieldByName('status').AsString);
      Item.AddPair('valor_total', TJSONNumber.Create(Qry.FieldByName('valor_total').AsCurrency));
      Item.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Qry.FieldByName('data_criacao').AsDateTime));

      Result.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function BuscarUltimosEventos(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
): TJSONArray;
var
  Qry: TUniQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_registro, origem, tipo, entidade, id_entidade, titulo, nivel, data_criacao ' +
      'FROM registro_evento ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY data_criacao DESC, id_registro DESC ' +
      'LIMIT 5';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('id_registro', TJSONNumber.Create(Qry.FieldByName('id_registro').AsLargeInt));
      Item.AddPair('origem', Qry.FieldByName('origem').AsString);
      Item.AddPair('tipo', Qry.FieldByName('tipo').AsString);
      Item.AddPair('entidade', Qry.FieldByName('entidade').AsString);

      if not Qry.FieldByName('id_entidade').IsNull then
        Item.AddPair('id_entidade', TJSONNumber.Create(Qry.FieldByName('id_entidade').AsLargeInt))
      else
        Item.AddPair('id_entidade', TJSONNull.Create);

      Item.AddPair('titulo', Qry.FieldByName('titulo').AsString);
      Item.AddPair('nivel', Qry.FieldByName('nivel').AsString);
      Item.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Qry.FieldByName('data_criacao').AsDateTime));

      Result.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TDashboardDAO.BuscarResumo(const AConn: TUniConnection;const AIdEmpresa: Int64): TJSONObject;
var
  Indicadores: TJSONObject;
  Pedidos: TJSONObject;
  Cadastros: TJSONObject;
  Notificacoes: TJSONObject;
begin
  Result := TJSONObject.Create;

  Indicadores   := TJSONObject.Create;
  Pedidos       := TJSONObject.Create;
  Cadastros     := TJSONObject.Create;
  Notificacoes  := TJSONObject.Create;

  Pedidos.AddPair('total_hoje', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND DATE(data_criacao) = CURDATE()',
      AIdEmpresa
    )
  ));

  Pedidos.AddPair('total_novos', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND status = ''NOVO''',
      AIdEmpresa
    )
  ));

  Pedidos.AddPair('total_em_atendimento', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND status = ''EM_ATENDIMENTO''',
      AIdEmpresa
    )
  ));

  Pedidos.AddPair('total_finalizados_mes', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND status = ''FINALIZADO'' ' +
      'AND YEAR(data_criacao) = YEAR(CURDATE()) ' +
      'AND MONTH(data_criacao) = MONTH(CURDATE())',
      AIdEmpresa
    )
  ));

  Pedidos.AddPair('valor_total_mes', TJSONNumber.Create(
    GetCurrency(
      AConn,
      'SELECT COALESCE(SUM(valor_total), 0) FROM pedido ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND YEAR(data_criacao) = YEAR(CURDATE()) ' +
      'AND MONTH(data_criacao) = MONTH(CURDATE())',
      AIdEmpresa
    )
  ));

  Cadastros.AddPair('categorias_ativas', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM categoria ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND ativo = ''S''',
      AIdEmpresa
    )
  ));

  Cadastros.AddPair('produtos_ativos', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM produto ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND ativo = ''S''',
      AIdEmpresa
    )
  ));

  Notificacoes.AddPair('pendentes', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM notificacao_fila ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND status = ''PENDENTE''',
      AIdEmpresa
    )
  ));

  Notificacoes.AddPair('com_erro', TJSONNumber.Create(
    GetCount(
      AConn,
      'SELECT COUNT(*) FROM notificacao_fila ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND status = ''ERRO''',
      AIdEmpresa
    )
  ));

  Indicadores.AddPair('pedidos', Pedidos);
  Indicadores.AddPair('cadastros', Cadastros);
  Indicadores.AddPair('notificacoes', Notificacoes);

  Result.AddPair('indicadores', Indicadores);
  Result.AddPair('ultimos_pedidos', BuscarUltimosPedidos(AConn, AIdEmpresa));
  Result.AddPair('ultimos_eventos', BuscarUltimosEventos(AConn, AIdEmpresa));
end;

end.
