unit AssinaturaCobranca.Controller;

interface

type
  TAssinaturaCobrancaController = class
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
  AssinaturaCobranca.Model,
  AssinaturaCobranca.Service;

function DateToJsonValue(const AData: TDateTime): TJSONValue;
begin
  if AData > 0 then
    Result := TJSONString.Create(FormatDateTime('yyyy-mm-dd hh:nn:ss', AData))
  else
    Result := TJSONNull.Create;
end;

function CobrancaToJson(const ACobranca: TAssinaturaCobrancaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_cobranca', TJSONNumber.Create(ACobranca.IdCobranca));
  Result.AddPair('id_assinatura', TJSONNumber.Create(ACobranca.IdAssinatura));
  Result.AddPair('id_empresa', TJSONNumber.Create(ACobranca.IdEmpresa));
  Result.AddPair('vencimento', DateToJsonValue(ACobranca.Vencimento));
  Result.AddPair('pago_em', DateToJsonValue(ACobranca.PagoEm));
  Result.AddPair('situacao', ACobranca.Situacao);
  Result.AddPair('valor', TJSONNumber.Create(ACobranca.Valor));
  Result.AddPair('descricao', ACobranca.Descricao);
  Result.AddPair('referencia', ACobranca.Referencia);
  Result.AddPair('forma_pagamento', ACobranca.FormaPagamento);
  Result.AddPair('id_transacao', ACobranca.IdTransacao);
  Result.AddPair('link_pagamento', ACobranca.LinkPagamento);
  Result.AddPair('data_criacao', DateToJsonValue(ACobranca.DataCriacao));
  Result.AddPair('data_alteracao', DateToJsonValue(ACobranca.DataAlteracao));
end;

function JsonToCobranca(const AJson: TJSONObject): TAssinaturaCobrancaModel;
begin
  Result := TAssinaturaCobrancaModel.Create;

  Result.IdAssinatura   := TAppClasses.GetJsonInt(AJson, 'id_assinatura',0);
  Result.Vencimento     := TAppClasses.GetJsonDate(AJson, 'vencimento');
  Result.PagoEm         := TAppClasses.GetJsonDate(AJson, 'pago_em');
  Result.Situacao       := TAppClasses.GetJsonString(AJson, 'situacao', 'ABERTA');
  Result.Valor          := TAppClasses.GetJsonCurrency(AJson, 'valor', 0);
  Result.Descricao      := TAppClasses.GetJsonString(AJson, 'descricao');
  Result.Referencia     := TAppClasses.GetJsonString(AJson, 'referencia');
  Result.FormaPagamento := TAppClasses.GetJsonString(AJson, 'forma_pagamento');
  Result.IdTransacao    := TAppClasses.GetJsonString(AJson, 'id_transacao');
  Result.LinkPagamento  := TAppClasses.GetJsonString(AJson, 'link_pagamento');
end;

class procedure TAssinaturaCobrancaController.Registry;
begin
  THorse.Get('/v1/assinatura-cobrancas',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TAssinaturaCobrancaModel>;
      Cobranca: TAssinaturaCobrancaModel;
      Arr: TJSONArray;
      Pesquisa: string;
      IdAssinatura: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Pesquisa := Req.Query.Items['pesquisa'];
        IdAssinatura := StrToInt64Def(Req.Query.Items['id_assinatura'], 0);

        Lista := TAssinaturaCobrancaService.Listar(Claims.IdEmpresa, IdAssinatura, Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Cobranca in Lista do
            Arr.AddElement(CobrancaToJson(Cobranca));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/assinatura-cobrancas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Cobranca: TAssinaturaCobrancaModel;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        Cobranca := TAssinaturaCobrancaService.Buscar(Claims.IdEmpresa, IdCobranca);
        try
          TAppResponse.Ok(Res, CobrancaToJson(Cobranca));
        finally
          Cobranca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/assinatura-cobrancas',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cobranca: TAssinaturaCobrancaModel;
      IdCobranca: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Json := Req.Body<TJSONObject>;
        Cobranca := JsonToCobranca(Json);
        try
          IdCobranca := TAssinaturaCobrancaService.Inserir(Claims.IdEmpresa, Cobranca);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_cobranca', TJSONNumber.Create(IdCobranca));

          TAppResponse.Created(Res, Retorno, 'Cobrança cadastrada com sucesso.');
        finally
          Cobranca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinatura-cobrancas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Cobranca: TAssinaturaCobrancaModel;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        Cobranca := JsonToCobranca(Json);
        try
          TAssinaturaCobrancaService.Atualizar(Claims.IdEmpresa, IdCobranca, Cobranca);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança atualizada com sucesso.');
        finally
          Cobranca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/assinatura-cobrancas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaCobrancaService.Excluir(Claims.IdEmpresa, IdCobranca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinatura-cobrancas/:id/pagar',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaCobrancaService.MarcarComoPaga(Claims.IdEmpresa, IdCobranca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança marcada como paga.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinatura-cobrancas/:id/vencer',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaCobrancaService.MarcarComoVencida(Claims.IdEmpresa, IdCobranca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança marcada como vencida.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinatura-cobrancas/:id/cancelar',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaCobrancaService.Cancelar(Claims.IdEmpresa, IdCobranca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança cancelada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/assinatura-cobrancas/:id/reabrir',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdCobranca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCobranca := StrToInt64Def(Req.Params['id'], 0);

        TAssinaturaCobrancaService.Reabrir(Claims.IdEmpresa, IdCobranca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Cobrança reaberta com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
