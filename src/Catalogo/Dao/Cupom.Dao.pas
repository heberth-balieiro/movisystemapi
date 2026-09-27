unit Cupom.Dao;

interface

uses
  System.SysUtils,
  Uni,
  Cupom.Model,
  System.Generics.Collections;

type
  TCupomDAO = class
  private

  public
    class function ExisteNome(const AConn: TUniConnection; Const AIdEmpresa: Int64; const ACodigo: string; Const AIdCupomIgnorar: Int64 = 0): Boolean; static;
    class function CupomPossuiPedido(const AConn: TUniConnection; const AIdEmpresa, AIdCupom: Int64): Boolean; static;

    class function Inserir(const AConn: TUniConnection; const Aidempresa:Int64; Const AMarca: TCupomModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; Const AIdEmpresa, AidCupom:Int64; Const AMarca: TCupomModel):Boolean; static;
    class function Excluir(const AConn: TUniConnection; Const AIdEmpresa, AIdCupom: Int64):Boolean; static;

    class function Listar(const AConn: TUniConnection; const AIdEmpresa: Int64; const APesquisa: string): TObjectList<TCupomModel>; static;
    class function BuscarPorId(const AConn: TUniConnection; Const AIdEmpresa, AIdCupom: Int64): TCupomModel; static;

end;

implementation

{ TCupomDAO }

{$REGION 'CRUD'}

class function TCupomDAO.Inserir(const AConn: TUniConnection;const Aidempresa: Int64; const AMarca: TCupomModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Insert into cupom(id_empresa,codigo,descricao,tipo_desconto,valor_desconto, '+
            'valor_minimo_pedido,valor_maximo_desconto,limite_total,quantidade_utilizada, '+
            'limite_por_cliente,data_inicio,data_fim,ativo)'+
            'Values(:id_empresa, :codigo, :descricao, :tipo_desconto, :valor_desconto, '+
            ':valor_minimo_pedido, :valor_maximo_desconto, :limite_total, :quantidade_utilizada, '+
            ':limite_por_cliente, :data_inicio, :data_fim, :ativo)';
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('id_empresa').AsLargeInt            := AIDempresa;
    Qry.ParamByName('codigo').AsString                  := AMarca.codigo;
    Qry.ParamByName('descricao').AsString               := AMarca.descricao;
    Qry.ParamByName('tipo_desconto').AsString           := AMarca.tipo_desconto;
    Qry.ParamByName('valor_desconto').AsFloat           := AMarca.valor_desconto;
    Qry.ParamByName('valor_minimo_pedido').AsFloat      := AMarca.valor_minimo_pedido;
    Qry.ParamByName('valor_maximo_desconto').AsFloat    := AMarca.valor_maximo_desconto;
    Qry.ParamByName('limite_total').AsInteger           := AMarca.limite_total;
    Qry.ParamByName('quantidade_utilizada').AsInteger   := AMarca.quantidade_utilizada;
    Qry.ParamByName('limite_por_cliente').AsInteger     := AMarca.limite_por_cliente;
    Qry.ParamByName('data_inicio').AsDate               := AMarca.data_inicio;
    Qry.ParamByName('data_fim').AsDate                  := AMarca.data_fim;
    Qry.ParamByName('ativo').AsString                   := AMarca.ativo;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := ' SELECT LAST_INSERT_ID() AS id_cupom ';
    Qry.Open;

    Result := Qry.FieldByName('id_cupom').AsLargeInt;
  Finally
    Qry.Free;
  End;

end;

class function TCupomDAO.Atualizar(const AConn: TUniConnection;const AIdEmpresa, AidCupom: Int64; const AMarca: TCupomModel):Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'update cupom set codigo= :codigo, descricao= :descricao, tipo_desconto= :tipo_desconto, valor_desconto= :valor_desconto, '+
            ' valor_minimo_pedido= :valor_minimo_pedido, valor_maximo_desconto= :valor_maximo_desconto, '+
            ' limite_total= :limite_total, quantidade_utilizada= :quantidade_utilizada, '+
            ' limite_por_cliente= :limite_por_cliente, data_inicio= :data_inicio, data_fim= :data_fim, ativo= :ativo '+
            ' where id_empresa= :id_empresa and id_cupom= :id_cupom';
begin
  Result := false;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('codigo').AsString                  := AMarca.codigo;
    Qry.ParamByName('descricao').AsString               := AMarca.descricao;
    Qry.ParamByName('tipo_desconto').AsString           := AMarca.tipo_desconto;
    Qry.ParamByName('valor_desconto').AsFloat           := AMarca.valor_desconto;
    Qry.ParamByName('valor_minimo_pedido').AsFloat      := AMarca.valor_minimo_pedido;
    Qry.ParamByName('valor_maximo_desconto').AsFloat    := AMarca.valor_maximo_desconto;
    Qry.ParamByName('limite_total').AsInteger           := AMarca.limite_total;
    Qry.ParamByName('quantidade_utilizada').AsInteger   := AMarca.quantidade_utilizada;
    Qry.ParamByName('limite_por_cliente').AsInteger     := AMarca.limite_por_cliente;
    Qry.ParamByName('data_inicio').AsDate               := AMarca.data_inicio;
    Qry.ParamByName('data_fim').AsDate                  := AMarca.data_fim;
    Qry.ParamByName('ativo').AsString                   := AMarca.ativo;
    Qry.ParamByName('id_empresa').AsLargeInt            := AIDempresa;
    Qry.ParamByName('id_cupom').AsLargeInt              := AidCupom;

    Qry.Execute;

    Result := Qry.RowsAffected > 0;

  Finally
    Qry.Free;
  End;
end;

class function TCupomDAO.Excluir(const AConn: TUniConnection; const AIdEmpresa,AIdCupom: Int64): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Delete from cupom where id_empresa= :id_empresa and id_cupom= :id_cupom';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;
    Qry.ParamByName('id_cupom').AsLargeInt      := AIdCupom;

    Qry.Execute;

    Result := Qry.RowsAffected > 0;

  Finally
    Qry.Free;
  End;
end;

class function TCupomDAO.BuscarPorId(const AConn: TUniConnection;const AIdEmpresa, AIdCupom: Int64): TCupomModel;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Select id_cupom, codigo,descricao,tipo_desconto,valor_desconto, '+
            'valor_minimo_pedido,valor_maximo_desconto,limite_total,quantidade_utilizada, '+
            'limite_por_cliente,data_inicio,data_fim,ativo from cupom where id_empresa= :id_empresa and id_cupom= :id_cupom';
begin

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;
    Qry.ParamByName('id_cupom').AsLargeInt      := AIdCupom;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TCupomModel.Create;

    Result.id_cupom               :=  Qry.FieldByName('id_cupom').AsLargeInt;
    Result.codigo                 :=  Qry.FieldByName('codigo').AsString;
    Result.descricao              :=  Qry.FieldByName('descricao').AsString;
    Result.tipo_desconto          :=  Qry.FieldByName('tipo_desconto').AsString;
    Result.valor_desconto         :=  Qry.FieldByName('valor_desconto').AsFloat;
    Result.valor_minimo_pedido    :=  Qry.FieldByName('valor_minimo_pedido').AsFloat;
    Result.valor_maximo_desconto  :=  Qry.FieldByName('valor_maximo_desconto').AsFloat;
    Result.limite_total           :=  Qry.FieldByName('limite_total').AsInteger;
    Result.quantidade_utilizada   :=  Qry.FieldByName('quantidade_utilizada').AsInteger;
    Result.limite_por_cliente     :=  Qry.FieldByName('limite_por_cliente').AsInteger;
    Result.data_inicio            :=  Qry.FieldByName('data_inicio').AsDateTime;
    Result.data_fim               :=  Qry.FieldByName('data_fim').AsDateTime;
    Result.ativo                  :=  Qry.FieldByName('ativo').AsString;

  Finally
    Qry.Free;
  End;
end;

class function TCupomDAO.Listar(const AConn: TUniConnection;const AIdEmpresa: Int64; const APesquisa: string): TObjectList<TCupomModel>;
var
  Qry   : TUniQuery;
  Cupom : TCupomModel;
Const
  StrSql  = 'Select id_cupom, codigo,descricao,limite_total,limite_por_cliente, ativo'+
            ' from cupom where id_empresa= :id_empresa order by descricao';
begin
  Result := TObjectList<TCupomModel>.Create(True);

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;

    Qry.Open;

    while not Qry.Eof do
    begin
      Cupom := TCupomModel.Create;

      Cupom.id_cupom            := Qry.FieldByName('id_cupom').AsLargeInt;
      Cupom.codigo              := Qry.FieldByName('codigo').AsString;
      Cupom.descricao           := Qry.FieldByName('descricao').AsString;
      Cupom.limite_total        := Qry.FieldByName('limite_total').AsInteger;
      Cupom.limite_por_cliente  := Qry.FieldByName('limite_por_cliente').AsInteger;
      Cupom.ativo               := Qry.FieldByName('ativo').AsString;

      Result.Add(Cupom);
      Qry.Next;
    end;

  Finally
    Qry.Free;
  End;
end;

{$ENDREGION}

{$REGION 'Funções'}

class function TCupomDAO.CupomPossuiPedido(const AConn: TUniConnection;const AIdEmpresa, AIdCupom: Int64): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = '';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.Execute;


  Finally
    Qry.Free;
  End;
end;

class function TCupomDAO.ExisteNome(const AConn: TUniConnection;const AIdEmpresa: Int64; const ACodigo: string;
                                    const AIdCupomIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
Const
  StrSql  = 'Select count(*) as total from cupom where id_empresa= :id_empresa and Upper(codigo) = UPPER(:codigo)';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    if AIdCupomIgnorar > 0 then
      Qry.SQL.Add(' and id_cupom <> :id_cupom ');

    Qry.ParamByName('id_empresa').AsLargeInt  := AIdEmpresa;
    Qry.ParamByName('codigo').AsString        := Trim(ACodigo);

    if AIdCupomIgnorar > 0 then
      Qry.ParamByName('id_cupom').AsLargeInt := AIdCupomIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;

  Finally
    Qry.Free;
  End;
end;

{$ENDREGION}


















end.
