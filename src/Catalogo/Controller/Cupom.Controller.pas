unit Cupom.Controller;

interface

type
  TCupomController = class
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
  APP.Token,
  Cupom.Model,
  Cupom.Service,
  Assinatura.Service;

function DateToJsonValue(const AData: TDateTime): TJSONValue;
begin
  if AData > 0 then
    Result := TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', AData))
  else
    Result := TJSONNull.Create;
end;

function CupomToJsonList(const ACupom: TCupomModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_cupom',            TJSONNumber.Create(ACupom.id_cupom));
  Result.AddPair('codigo',              ACupom.codigo);
  Result.AddPair('descricao',           ACupom.descricao);
  Result.AddPair('limite_total',        TJSONNumber.Create(ACupom.limite_total));
  Result.AddPair('limite_por_cliente',  TJSONNumber.Create(ACupom.limite_por_cliente));
  Result.AddPair('ativo',               ACupom.ativo);

end;

function CupomToJsonID(const ACupom: TCupomModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_cupom',            TJSONNumber.Create(ACupom.id_cupom));
  Result.AddPair('codigo',              ACupom.codigo);
  Result.AddPair('descricao',           ACupom.descricao);
  Result.AddPair('tipo_desconto',       ACupom.tipo_desconto);
  Result.AddPair('valor_desconto',      TJSONNumber.Create(ACupom.valor_desconto));
  Result.AddPair('valor_minimo_pedido', TJSONNumber.Create(ACupom.valor_minimo_pedido));
  Result.AddPair('valor_maximo_desconto',TJSONNumber.Create(ACupom.valor_maximo_desconto));
  Result.AddPair('limite_total',        TJSONNumber.Create(ACupom.limite_total));
  Result.AddPair('quantidade_utilizada',TJSONNumber.Create(ACupom.quantidade_utilizada));
  Result.AddPair('limite_por_cliente',  TJSONNumber.Create(ACupom.limite_por_cliente));
  Result.AddPair('data_inicio',         DateToJsonValue(ACupom.data_inicio));
  Result.AddPair('data_fim',            DateToJsonValue(ACupom.data_fim));
  Result.AddPair('ativo',               ACupom.ativo);

end;

function JsonToCupom(const AJson: TJSONObject): TCupomModel;
begin
  //Para post e put
  Result := TCupomModel.Create;

  Result.codigo               := TAppClasses.GetJsonString(AJson, 'codigo');
  Result.Descricao            := TAppClasses.GetJsonString(AJson, 'descricao');
  Result.tipo_desconto        := TAppClasses.GetJsonString(AJson, 'tipo_desconto');
  Result.valor_desconto       := TAppClasses.GetJsonCurrency(AJson,'valor_desconto',0);
  Result.valor_minimo_pedido  := TAppClasses.GetJsonCurrency(AJson,'valor_minimo_pedido',0);
  Result.valor_maximo_desconto:= TAppClasses.GetJsonCurrency(AJson,'valor_maximo_desconto',0);
  Result.limite_total         := TAppClasses.GetJsonInt(AJson, 'limite_total', 0);
  Result.quantidade_utilizada := TAppClasses.GetJsonInt(AJson, 'quantidade_utilizada', 0);
  Result.limite_por_cliente   := TAppClasses.GetJsonInt(AJson, 'limite_por_cliente', 0);
  Result.data_inicio          := TAppClasses.GetJsonDate(AJson, 'data_inicio');
  Result.data_fim             := TAppClasses.GetJsonDate(AJson, 'data_fim');
  Result.Ativo                := TAppClasses.GetJsonString(AJson, 'ativo', 'S');

end;

class procedure TCupomController.Registry;
begin
  THorse.Get('/v1/cupom',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TCupomModel>;
      Cupom: TCupomModel;
      Arr: TJSONArray;
      Pesquisa: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Pesquisa := Req.Query.Items['pesquisa'];

        Lista := TCupomService.Listar(Claims.IdEmpresa, Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Cupom in Lista do
            Arr.AddElement(CupomToJsonList(Cupom));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/cupom/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Cupom: TCupomModel;
      IdCupom: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Idcupom := StrToInt64Def(Req.Params['id'], 0);

        Cupom := TCupomService.Buscar(Claims.IdEmpresa, idcupom);
        try
          TAppResponse.Ok(Res, CupomToJsonID(Cupom));
        finally
          Cupom.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/cupom',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cupom: TCupomModel;
      IdCupom: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Json := Req.Body<TJSONObject>;
        Cupom := JsonToCupom(Json);
        try
          IdCupom := TCupomService.Inserir(Claims.IdEmpresa, Cupom);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_cupom', TJSONNumber.Create(idcupom));

          TAppResponse.Created(Res, Retorno, 'Cupom cadastrado com sucesso.');
        finally
          Cupom.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/cupom/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cupom: TCupomModel;
      IdCupom: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCupom := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        if Json = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');
        Cupom := JsonToCupom(Json);

        try
          TCupomService.Atualizar(Claims.IdEmpresa, IdCupom, Cupom);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Cupom atualizado com sucesso.');
        finally
          Cupom.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/cupom/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCupom: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdCupom := StrToInt64Def(Req.Params['id'], 0);

        TCupomService.Excluir(Claims.IdEmpresa, IdCupom);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cupom excluido com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

end;

end.
       
