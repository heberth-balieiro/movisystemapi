unit Plano.Controller;

interface

type
  TPlanoController = class
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
  App.Classes,
  App.Token,
  Plano.Model,
  Plano.Service;


function PlanoToJson(const APlano: TPlanoModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_plano', TJSONNumber.Create(APlano.IdPlano));
  Result.AddPair('descricao', APlano.Descricao);
  Result.AddPair('valor', TJSONNumber.Create(APlano.Valor));
  Result.AddPair('catalogo', APlano.Catalogo);
  Result.AddPair('catalogo_qtde', TJSONNumber.Create(APlano.CatalogoQtde));
  Result.AddPair('interno', APlano.Interno);
  Result.AddPair('ativo', APlano.Ativo);
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', APlano.DataCriacao));

  if APlano.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', APlano.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);

  Result.AddPair('valor_anual', TJSONNumber.Create(APlano.valoranual));
  Result.AddPair('produto_qtde', TJSONNumber.Create(APlano.produtoqtde));
  Result.AddPair('recursos', APlano.recursos);
  Result.AddPair('PermiteProdutoIlimitado',      APlano.PermiteProdutoIlimitado);

  Result.AddPair('whatsapp',      APlano.PermiteWhatsapp);
  Result.AddPair('email',         APlano.PermiteEmail);
  Result.AddPair('pedido',        APlano.PermitePedido);
  Result.AddPair('ecommerce',     APlano.PermiteEcommerce);
  Result.AddPair('pagseguro',     APlano.PermitePagSeguro);
  Result.AddPair('pedido_ficha',  APlano.PermitePedidoFicha);
  Result.AddPair('config_visual', APlano.PermiteConfigVisual);
  Result.AddPair('permite_config_cupom', Aplano.permiteconfigcupom);

end;

function SNToBoolean(const AValor: string): Boolean;
begin
  Result := SameText(Trim(AValor), 'S');
end;

procedure PreencherPlanoFromJson(const AJson: TJSONObject; const APlano: TPlanoModel);
begin
  //Preencimento de novo e alteracao
  APlano.Descricao              := TAppClasses.GetJsonString(AJson, 'descricao');
  APlano.Valor                  := TAppClasses.GetJsonCurrency(AJson, 'valor', 0);
  APlano.Catalogo               := TAppClasses.GetJsonString(AJson, 'catalogo', 'S');
  APlano.CatalogoQtde           := TAppClasses.GetJsonInt(AJson, 'catalogo_qtde', 0);
  APlano.Interno                := TAppClasses.GetJsonString(AJson, 'interno', 'N');
  APlano.Ativo                  := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  APlano.valoranual             := TAppClasses.GetJsonCurrency(AJson, 'valor_anual', 0);
  APlano.produtoqtde            := TAppClasses.GetJsonInt(AJson, 'produto_qtde', 0);
  APlano.recursos               := TAppClasses.GetJsonString(AJson, 'recursos');
  APlano.PermiteProdutoIlimitado:= TAppClasses.GetJsonString(AJson, 'PermiteProdutoIlimitado', 'N');
  APlano.PermiteWhatsapp        := TAppClasses.GetJsonString(AJson, 'whatsapp', 'N');
  APlano.PermiteEmail           := TAppClasses.GetJsonString(AJson, 'email', 'N');
  APlano.PermitePedido          := TAppClasses.GetJsonString(AJson, 'pedido', 'N');
  APlano.PermiteEcommerce       := TAppClasses.GetJsonString(AJson, 'ecommerce', 'N');
  APlano.PermitePagSeguro       := TAppClasses.GetJsonString(AJson, 'pagseguro', 'N');
  APlano.PermitePedidoFicha     := TAppClasses.GetJsonString(AJson, 'pedido_ficha', 'N');
  APlano.PermiteConfigVisual    := TAppClasses.GetJsonString(AJson, 'config_visual', 'N');
  Aplano.permiteconfigcupom     := TAppClasses.GetJsonString(Ajson, 'permite_config_cupom', 'N');

end;

function GerarRecursosPlano(const APlano: TPlanoModel): TJSONArray;
begin
  Result := TJSONArray.Create;
  if SNToBoolean(APlano.Catalogo) then
    Result.Add('Catálogo personalizado');
  if SNToBoolean(APlano.PermiteProdutoIlimitado) then
    Result.Add('Produtos ilimitados')
  else if APlano.ProdutoQtde > 0 then
    Result.Add('Até ' + APlano.ProdutoQtde.ToString + ' produtos');
  if SNToBoolean(APlano.PermitePedido) then
    Result.Add('Pedidos pelo catálogo');
  if SNToBoolean(APlano.PermiteWhatsapp) then
    Result.Add('WhatsApp');
  if SNToBoolean(APlano.PermiteEmail) then
    Result.Add('E-mail');
  if SNToBoolean(APlano.PermiteEcommerce) then
    Result.Add('E-commerce');
  if SNToBoolean(APlano.PermitePagSeguro) then
    Result.Add('Integração PagSeguro');
  if SNToBoolean(APlano.PermitePedidoFicha) then
    Result.Add('Pedido com número de ficha');
  if SNToBoolean(APlano.PermiteConfigVisual) then
    Result.Add('Configuração visual');
end;

function PlanoToJsonPublico(const APlano: TPlanoModel): TJSONObject;
var
  Permissoes: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_plano', TJSONNumber.Create(APlano.IdPlano));
  Result.AddPair('nome', APlano.Descricao);
  if not Trim(APlano.Recursos).IsEmpty then
    Result.AddPair('descricao', APlano.Recursos)
  else
    Result.AddPair('descricao', APlano.Descricao);
  Result.AddPair('valor_mensal', TJSONNumber.Create(APlano.Valor));
  Result.AddPair('valor_anual', TJSONNumber.Create(APlano.ValorAnual));
  Result.AddPair('produto_qtde', TJSONNumber.Create(APlano.ProdutoQtde));
  Result.AddPair('produto_ilimitado', TJSONBool.Create(SNToBoolean(APlano.PermiteProdutoIlimitado)));
  Result.AddPair('recursos', GerarRecursosPlano(APlano));
  Permissoes := TJSONObject.Create;
  Permissoes.AddPair('catalogo', TJSONBool.Create(SNToBoolean(APlano.Catalogo)));
  Permissoes.AddPair('whatsapp', TJSONBool.Create(SNToBoolean(APlano.PermiteWhatsapp)));
  Permissoes.AddPair('email', TJSONBool.Create(SNToBoolean(APlano.PermiteEmail)));
  Permissoes.AddPair('pedido', TJSONBool.Create(SNToBoolean(APlano.PermitePedido)));
  Permissoes.AddPair('ecommerce', TJSONBool.Create(SNToBoolean(APlano.PermiteEcommerce)));
  Permissoes.AddPair('pagseguro', TJSONBool.Create(SNToBoolean(APlano.PermitePagSeguro)));
  Permissoes.AddPair('pedido_ficha', TJSONBool.Create(SNToBoolean(APlano.PermitePedidoFicha)));
  Permissoes.AddPair('config_visual', TJSONBool.Create(SNToBoolean(APlano.PermiteConfigVisual)));
  Permissoes.AddPair('permite_config_cupom', TJsonBool.Create(SNToBoolean(Aplano.permiteconfigcupom)));

  Result.AddPair('permissoes', Permissoes);
end;


class procedure TPlanoController.Registry;
begin
  {$REGION 'Rota publica'}

  THorse.Get('/v1/plano/dash',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Lista: TObjectList<TPlanoModel>;
      Plano: TPlanoModel;
      Arr: TJSONArray;
    begin
      try
        Lista := TPlanoService.ListarPlanosDash;
        try
          Arr := TJSONArray.Create;

          for Plano in Lista do
            Arr.AddElement(PlanoToJsonPublico(Plano));

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

  THorse.Get('/v1/plano',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Pesquisa: string;
      Lista: TObjectList<TPlanoModel>;
      Plano: TPlanoModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Pesquisa := Req.Query['pesquisa'];

        Lista := TPlanoService.ListarPlanos(Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Plano in Lista do
            Arr.AddElement(PlanoToJson(Plano));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/plano/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdPlano: Int64;
      Plano: TPlanoModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdPlano := StrToInt64Def(Req.Params['id'], 0);

        Plano := TPlanoService.BuscarPlano(IdPlano);
        try
          TAppResponse.Ok(Res, PlanoToJson(Plano));
        finally
          Plano.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/plano',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Plano: TPlanoModel;
      IdPlano: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Plano := TPlanoModel.Create;
        try
          PreencherPlanoFromJson(Body, Plano);

          IdPlano := TPlanoService.CriarPlano(Plano);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_plano', TJSONNumber.Create(IdPlano));

          TAppResponse.Created(Res, Retorno, 'Plano cadastrado com sucesso.');
        finally
          Plano.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/plano/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdPlano: Int64;
      Body: TJSONObject;
      Plano: TPlanoModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdPlano := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Plano := TPlanoModel.Create;
        try
          PreencherPlanoFromJson(Body, Plano);

          TPlanoService.AtualizarPlano(IdPlano, Plano);

          TAppResponse.Ok(Res, TJSONObject.Create, 'Plano atualizado com sucesso.');
        finally
          Plano.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/plano/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdPlano: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdPlano := StrToInt64Def(Req.Params['id'], 0);

        TPlanoService.ExcluirPlano(IdPlano);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Plano excluído com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
