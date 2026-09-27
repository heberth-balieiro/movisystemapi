unit Categoria.Controller;

interface

type
  TCategoriaController = class
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
  app.Classes,
  App.Token,
  Categoria.Model,
  Categoria.Service;

function CategoriaToJsonList(const ACategoria: TCategoriaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_categoria',    TJSONNumber.Create(ACategoria.IdCategoria));
  Result.AddPair('nome',            ACategoria.Nome);
  Result.AddPair('descricao',       ACategoria.Descricao);
  Result.AddPair('ativo',           ACategoria.Ativo);
  Result.AddPair('ordem',           TJSONNumber.Create(ACategoria.Ordem));
end;

function CategoriaToJsonID(const ACategoria: TCategoriaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_categoria',    TJSONNumber.Create(ACategoria.IdCategoria));
  Result.AddPair('nome',            ACategoria.Nome);
  Result.AddPair('descricao',       ACategoria.Descricao);
  Result.AddPair('ativo',           ACategoria.Ativo);
  Result.AddPair('ordem',           TJSONNumber.Create(ACategoria.Ordem));
  Result.AddPair('ImagemUrl',       ACategoria.ImagemUrl);

end;

class procedure TCategoriaController.Registry;
begin
  THorse.Post('/v1/categorias',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Categoria: TCategoriaModel;
      IdCategoria: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Categoria := TCategoriaModel.Create;
        try
          Categoria.Nome      := TAppClasses.GetJsonString(Body, 'nome');
          Categoria.Descricao := TAppClasses.GetJsonString(Body, 'descricao');
          Categoria.Ativo     := TAppClasses.GetJsonString(Body, 'ativo', 'S');
          Categoria.Ordem     := TAppClasses.GetJsonInt(Body, 'ordem', 0);
          Categoria.ImagemUrl := TAppClasses.GetJsonString(Body, 'ImagemUrl');

          IdCategoria := TCategoriaService.CriarCategoria(Claims.IdEmpresa, Categoria);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_categoria', TJSONNumber.Create(IdCategoria));

          TAppResponse.Created(Res, Retorno, 'Categoria cadastrada com sucesso.');
        finally
          Categoria.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/categorias',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TCategoriaModel>;
      Categoria: TCategoriaModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Lista := TCategoriaService.ListarCategorias(Claims.IdEmpresa);
        try
          Arr := TJSONArray.Create;

          for Categoria in Lista do
            Arr.AddElement(CategoriaToJsonList(Categoria));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/categorias/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;
      Categoria: TCategoriaModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCategoria := StrToInt64Def(Req.Params['id'], 0);

        Categoria := TCategoriaService.BuscarCategoria(Claims.IdEmpresa, IdCategoria);
        try
          Json := CategoriaToJsonID(Categoria);
          TAppResponse.Ok(Res, Json);
        finally
          Categoria.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/categorias/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;
      Body: TJSONObject;
      Categoria: TCategoriaModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCategoria := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Categoria := TCategoriaModel.Create;
        try
          Categoria.Nome      := TAppClasses.GetJsonString(Body, 'nome');
          Categoria.Descricao := TAppClasses.GetJsonString(Body, 'descricao');
          Categoria.Ativo     := TAppClasses.GetJsonString(Body, 'ativo', 'S');
          Categoria.Ordem     := TAppClasses.GetJsonInt(Body, 'ordem', 0);
          Categoria.ImagemUrl := TAppClasses.GetJsonString(Body, 'ImagemUrl');

          TCategoriaService.AtualizarCategoria(Claims.IdEmpresa, IdCategoria, Categoria);

          TAppResponse.Ok(Res, TJSONObject.Create, 'Categoria atualizada com sucesso.');
        finally
          Categoria.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/categorias/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdCategoria: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdCategoria := StrToInt64Def(Req.Params['id'], 0);

        TCategoriaService.ExcluirCategoria(Claims.IdEmpresa, IdCategoria);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Categoria excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
