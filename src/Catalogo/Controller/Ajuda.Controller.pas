unit Ajuda.Controller;

interface

type
  TAjudaController = class
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
  Ajuda.Model,
  Ajuda.Service;


function AjudaToJson(const AAjuda: TAjudaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_ajuda', TJSONNumber.Create(AAjuda.IdAjuda));
  Result.AddPair('id_empresa', TJSONNumber.Create(AAjuda.IdEmpresa));
  Result.AddPair('ordem', TJSONNumber.Create(AAjuda.Ordem));
  Result.AddPair('titulo', AAjuda.Titulo);
  Result.AddPair('url', AAjuda.Url);
  Result.AddPair('descricao', AAjuda.Descricao);
  Result.AddPair('ativo', AAjuda.Ativo);
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AAjuda.DataCriacao));

  if AAjuda.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AAjuda.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);
end;

class procedure TAjudaController.Registry;
begin
  // Precisa ficar antes de /v1/ajudas/:id
  THorse.Get('/v1/ajudas/minhas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TAjudaModel>;
      Ajuda: TAjudaModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TAjudaService.ListarAjudas(Claims.IdEmpresa, True);
        try
          Arr := TJSONArray.Create;

          for Ajuda in Lista do
            Arr.AddElement(AjudaToJson(Ajuda));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/ajudas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TAjudaModel>;
      Ajuda: TAjudaModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TAjudaService.ListarAjudas(Claims.IdEmpresa, False);
        try
          Arr := TJSONArray.Create;

          for Ajuda in Lista do
            Arr.AddElement(AjudaToJson(Ajuda));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/ajudas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdAjuda: Int64;
      Ajuda: TAjudaModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAjuda := StrToInt64Def(Req.Params['id'], 0);

        Ajuda := TAjudaService.BuscarAjuda(Claims.IdEmpresa, IdAjuda);
        try
          Json := AjudaToJson(Ajuda);
          TAppResponse.Ok(Res, Json);
        finally
          Ajuda.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/ajudas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Ajuda: TAjudaModel;
      IdAjuda: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Ajuda := TAjudaModel.Create;
        try
          Ajuda.Ordem     := TAppClasses.GetJsonInt(Body, 'ordem', 0);
          Ajuda.Titulo    := TAppClasses.GetJsonString(Body, 'titulo');
          Ajuda.Url       := TAppClasses.GetJsonString(Body, 'url');
          Ajuda.Descricao := TAppClasses.GetJsonString(Body, 'descricao');
          Ajuda.Ativo     := TAppClasses.GetJsonString(Body, 'ativo', 'S');

          IdAjuda := TAjudaService.CriarAjuda(Claims.IdEmpresa, Ajuda);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_ajuda', TJSONNumber.Create(IdAjuda));

          TAppResponse.Created(Res, Retorno, 'Ajuda cadastrada com sucesso.');
        finally
          Ajuda.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/ajudas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdAjuda: Int64;
      Body: TJSONObject;
      Ajuda: TAjudaModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAjuda := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Ajuda := TAjudaModel.Create;
        try
          Ajuda.Ordem   := TAppClasses.GetJsonInt(Body, 'ordem', 0);
          Ajuda.Titulo  := TAppClasses.GetJsonString(Body, 'titulo');
          Ajuda.Url     := TAppClasses.GetJsonString(Body, 'url');
          Ajuda.Descricao := TAppClasses.GetJsonString(Body, 'descricao');
          Ajuda.Ativo     := TAppClasses.GetJsonString(Body, 'ativo', 'S');

          TAjudaService.AtualizarAjuda(Claims.IdEmpresa, IdAjuda, Ajuda);

          TAppResponse.Ok(Res, TJSONObject.Create, 'Ajuda atualizada com sucesso.');
        finally
          Ajuda.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/ajudas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdAjuda: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdAjuda := StrToInt64Def(Req.Params['id'], 0);

        TAjudaService.ExcluirAjuda(Claims.IdEmpresa, IdAjuda);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Ajuda excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
