unit Marca.Controller;

interface

type
  TMarcaController = class
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
  APP.Token,
  Marca.Model,
  Marca.Service,
  Assinatura.Service;

function MarcaToJson(const AMarca: TMarcaModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_marca',    TJSONNumber.Create(AMarca.IdMarca));
  Result.AddPair('id_empresa',  TJSONNumber.Create(AMarca.IdEmpresa));
  Result.AddPair('nome',        AMarca.nome);
  Result.AddPair('descricao',   AMarca.descricao);
  Result.AddPair('ativo',       AMarca.ativo);
  Result.AddPair('ordem',       TJSONNumber.Create(AMarca.ordem));

end;

function JsonToMarca(const AJson: TJSONObject): TMarcaModel;
begin
  //Para post e put
  Result := TMarcaModel.Create;

  Result.Nome       := TAppClasses.GetJsonString(AJson, 'nome');
  Result.Descricao  := TAppClasses.GetJsonString(AJson, 'descricao');
  Result.Ativo      := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  Result.Ordem      := TAppClasses.GetJsonInt(AJson, 'ordem', 0);

end;

class procedure TMarcaController.Registry;
begin
  THorse.Get('/v1/marca',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TMarcaModel>;
      Marca: TMarcaModel;
      Arr: TJSONArray;
      Pesquisa: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Pesquisa := Req.Query.Items['pesquisa'];

        Lista := TMarcaService.Listar(Claims.IdEmpresa, Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Marca in Lista do
            Arr.AddElement(MarcaToJson(Marca));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/marca/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Marca: TMarcaModel;
      IdMarca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdMarca := StrToInt64Def(Req.Params['id'], 0);

        Marca := TMarcaService.BuscarMarca(Claims.IdEmpresa, idmarca);
        try
          TAppResponse.Ok(Res, MarcaToJson(Marca));
        finally
          marca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/marca',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Marca: TMarcaModel;
      IdMarca: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Json := Req.Body<TJSONObject>;
        Marca := JsonToMarca(Json);
        try
          IdMarca := TMarcaService.Inserir(Claims.IdEmpresa, Marca);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_marca', TJSONNumber.Create(idmarca));

          TAppResponse.Created(Res, Retorno, 'Marca cadastrado com sucesso.');
        finally
          Marca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/marca/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Marca: TMarcaModel;
      IdMarca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdMarca := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        if Json = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');
        Marca := JsonToMarca(Json);
        try
          TMarcaService.Atualizar(Claims.IdEmpresa, IdMarca, Marca);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Marca atualizado com sucesso.');
        finally
          Marca.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/marca/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdMarca: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdMarca := StrToInt64Def(Req.Params['id'], 0);

        TMarcaService.Excluir(Claims.IdEmpresa, IdMarca);
        TAppResponse.Ok(Res, TJSONObject.Create, 'Marca excluido com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

end;

end.
