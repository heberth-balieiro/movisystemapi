unit CatalogoPublic.Controller;

interface

Uses System.Generics.Collections;

type
  TCatalogoPublicController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Response,
  APP.Errors,
  CatalogoPublic.Service,
  Pedido.Model,
  PedidoItem.Model,
  Pedido.Service,
  APP.Classes,
  Segmento.Model,
  Segmento.Service;

function SegmentoToJsonPublico(const ASegmento: TSegmentoModel): TJSONObject;
begin
  Result      := TJSONObject.Create;
  Result.AddPair('id_segmento',     TJSONNumber.Create(ASegmento.IdSegmento));
  Result.AddPair('nome',            ASegmento.Nome);
  Result.AddPair('descricao',       ASegmento.Descricao);
  Result.AddPair('ordem',           TJSONNumber.Create(ASegmento.Ordem));
end;


class procedure TCatalogoPublicController.Registry;
begin

  {$REGION 'Rotas publicas para catalogo'}

  //Rota para carregar o catalogo pelo slug
  THorse.Get('/v1/public/catalogo/:slug',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Dados: TJSONObject;
    begin
      try
        Slug := Req.Params['slug'];

        Dados := TCatalogoPublicService.BuscarCatalogoPublico(Slug);

        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  //Buscar Produto especifico
  THorse.Get('/v1/public/catalogo/:slug/produto/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      IDProduto: Int64;
      Dados: TJSONObject;
    begin
      try
        Slug        := Req.Params['slug'];
        IdProduto   := StrToInt64Def(Req.Params['id'], 0);
        Dados       := TCatalogoPublicService.BuscarCatalogoPublicoProduto(Slug,IdProduto);

        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  //Produto em destaque
  THorse.Get('/v1/public/catalogo/:slug/destaques',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Dados: TJSONObject;
    begin
      try
        Slug        := Req.Params['slug'];
        Dados       := TCatalogoPublicService.BuscarCatalogoPublicoDestaque(Slug);

        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Rotas publicas Pedido'}

  THorse.Post('/v1/public/catalogo/:slug/pedidos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Body: TJSONObject;
      ItensJson: TJSONArray;
      ItemJson: TJSONObject;
      Pedido: TPedidoModel;
      Item: TPedidoItemModel;
      I: Integer;
      Resultado: TCriarPedidoResult;
      Retorno: TJSONObject;
    begin
      try
        Slug := Req.Params['slug'];

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Pedido := TPedidoModel.Create;
        try
          Pedido.NomeCliente      := TAppClasses.GetJsonString(Body, 'nome_cliente');
          Pedido.WhatsappCliente  := TAppClasses.GetJsonString(Body, 'whatsapp_cliente');
          Pedido.EmailCliente     := TAppClasses.GetJsonString(Body, 'email_cliente');
          Pedido.Observacao       := TAppClasses.GetJsonString(Body, 'observacao');
          Pedido.TipoEntrega      := TAppClasses.GetJsonString(Body, 'tipo_entrega', 'RETIRADA');
          Pedido.EnderecoEntrega  := TAppClasses.GetJsonString(Body, 'endereco_entrega');

          if not (Body.GetValue('itens') is TJSONArray) then
            TAppErrors.RaiseBadRequest('Informe os itens do pedido.');

          ItensJson := Body.GetValue('itens') as TJSONArray;

          for I := 0 to ItensJson.Count - 1 do
          begin
            if not (ItensJson.Items[I] is TJSONObject) then
              TAppErrors.RaiseBadRequest('Item do pedido inválido.');

            ItemJson := ItensJson.Items[I] as TJSONObject;

            Item := TPedidoItemModel.Create;
            Item.IdProduto  := TAppClasses.GetJsonInt(ItemJson, 'id_produto',0);
            Item.Quantidade := TAppClasses.GetJsonCurrency(ItemJson, 'quantidade', 1);
            Item.Observacao := TAppClasses.GetJsonString(ItemJson, 'observacao');

            Pedido.Itens.Add(Item);
          end;

          Resultado := TPedidoService.CriarPedidoPublico(Slug, Pedido);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_pedido',    TJSONNumber.Create(Resultado.IdPedido));
          Retorno.AddPair('valor_total',  TJSONNumber.Create(Resultado.ValorTotal));

          TAppResponse.Created(Res, Retorno, 'Pedido enviado com sucesso.');
        finally
          Pedido.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Segmento'}

  THorse.Get('/v1/segmento/dash',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Lista: TObjectList<TSegmentoModel>;
      Segmento: TSegmentoModel;
      Arr: TJSONArray;
    begin
      try
        Lista := TSegmentoService.ListarSegmentoDash;
        try
          Arr := TJSONArray.Create;

          for Segmento in Lista do
            Arr.AddElement(SegmentoToJsonPublico(Segmento));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;

end.
