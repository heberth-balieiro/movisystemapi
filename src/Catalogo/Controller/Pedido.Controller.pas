unit Pedido.Controller;

interface

type
  TPedidoController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  APP.Classes,
  App.Token,
  Pedido.Model,
  PedidoItem.Model,
  Pedido.Service,
  Assinatura.Service;

function PedidoItemToJson(const AItem: TPedidoItemModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_item', TJSONNumber.Create(AItem.IdItem));
  Result.AddPair('id_pedido', TJSONNumber.Create(AItem.IdPedido));
  Result.AddPair('id_empresa', TJSONNumber.Create(AItem.IdEmpresa));
  Result.AddPair('id_produto', TJSONNumber.Create(AItem.IdProduto));
  Result.AddPair('nome_produto', AItem.NomeProduto);
  Result.AddPair('quantidade', TJSONNumber.Create(AItem.Quantidade));
  Result.AddPair('valor_unitario', TJSONNumber.Create(AItem.ValorUnitario));
  Result.AddPair('valor_total', TJSONNumber.Create(AItem.ValorTotal));
  Result.AddPair('observacao', AItem.Observacao);
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AItem.DataCriacao));
end;

function PedidoToJson(const APedido: TPedidoModel; const AComItens: Boolean = False): TJSONObject;
var
  ItensArray: TJSONArray;
  Item: TPedidoItemModel;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_pedido', TJSONNumber.Create(APedido.IdPedido));
  Result.AddPair('id_empresa', TJSONNumber.Create(APedido.IdEmpresa));
  Result.AddPair('nome_cliente', APedido.NomeCliente);
  Result.AddPair('whatsapp_cliente', APedido.WhatsappCliente);
  Result.AddPair('email_cliente', APedido.EmailCliente);
  Result.AddPair('observacao', APedido.Observacao);
  Result.AddPair('tipo_entrega', APedido.TipoEntrega);
  Result.AddPair('endereco_entrega', APedido.EnderecoEntrega);
  Result.AddPair('status', APedido.Status);
  Result.AddPair('valor_total', TJSONNumber.Create(APedido.ValorTotal));
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', APedido.DataCriacao));

  if APedido.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', APedido.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);

  if AComItens then
  begin
    ItensArray := TJSONArray.Create;

    for Item in APedido.Itens do
      ItensArray.AddElement(PedidoItemToJson(Item));

    Result.AddPair('itens', ItensArray);
  end;
end;

class procedure TPedidoController.Registry;
begin


  THorse.Get('/v1/pedidos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TPedidoModel>;
      Pedido: TPedidoModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Lista := TPedidoService.ListarPedidos(Claims.IdEmpresa);
        try
          Arr := TJSONArray.Create;

          for Pedido in Lista do
            Arr.AddElement(PedidoToJson(Pedido, False));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/pedidos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdPedido: Int64;
      Pedido: TPedidoModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdPedido := StrToInt64Def(Req.Params['id'], 0);

        Pedido := TPedidoService.BuscarPedido(Claims.IdEmpresa, IdPedido);
        try
          Json := PedidoToJson(Pedido, True);
          TAppResponse.Ok(Res, Json);
        finally
          Pedido.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/pedidos/:id/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdPedido: Int64;
      Body: TJSONObject;
      Status: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdPedido := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Status := TAppClasses.GetJsonString(Body, 'status');

        TPedidoService.AtualizarStatus(Claims.IdEmpresa, IdPedido, Status);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Status do pedido atualizado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
