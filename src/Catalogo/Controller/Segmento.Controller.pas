unit Segmento.Controller;

interface

type
  TSegmentoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Horse,
  App.Response,
  APP.Errors,
  Middleware.JWT,
  Segmento.Model,
  Segmento.Service,
  App.Classes,
  App.Token,
  App.JWT;


function JsonToSegmento(const AJson: TJSONObject): TSegmentoModel;
begin
  Result            := TSegmentoModel.Create;
  Result.Nome       := TAppClasses.GetJsonString(AJson, 'nome');
  Result.Descricao  := TAppClasses.GetJsonString(AJson, 'descricao');
  Result.Ativo      := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  Result.Ordem      := TAppClasses.GetJsonInt(AJson, 'ordem', 0);
end;

function SegmentoToJson(const ASegmento: TSegmentoModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_segmento', TJSONNumber.Create(ASegmento.IdSegmento));
  Result.AddPair('nome', ASegmento.Nome);
  Result.AddPair('descricao', ASegmento.Descricao);
  Result.AddPair('ativo', ASegmento.Ativo);
  Result.AddPair('ordem', TJSONNumber.Create(ASegmento.Ordem));
end;

class procedure TSegmentoController.Registry;
begin
  THorse.Get('/v1/segmentos',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TSegmentoModel>;
      Arr: TJSONArray;
      Item: TSegmentoModel;
      Pesquisa: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Pesquisa := Req.Query.Field('pesquisa').AsString;

        Lista := TSegmentoService.Listar(Pesquisa);
        try
          Arr := TJSONArray.Create;

          for Item in Lista do
            Arr.AddElement(SegmentoToJson(Item));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/segmentos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Segmento: TSegmentoModel;
      IdSegmento: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdSegmento := StrToInt64Def(Req.Params['id'], 0);

        Segmento := TSegmentoService.Buscar(IdSegmento);
        try
          TAppResponse.Ok(Res, SegmentoToJson(Segmento));
        finally
          Segmento.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/v1/segmentos',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Segmento: TSegmentoModel;
      IdGerado: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Json := Req.Body<TJSONObject>;

        Segmento := JsonToSegmento(Json);
        try
          IdGerado := TSegmentoService.Inserir(Segmento);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_segmento', TJSONNumber.Create(IdGerado));

          TAppResponse.Created(Res, Retorno, 'Segmento cadastrado com sucesso.');
        finally
          Segmento.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/segmentos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Segmento: TSegmentoModel;
      IdSegmento: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdSegmento := StrToInt64Def(Req.Params['id'], 0);
        Json := Req.Body<TJSONObject>;

        Segmento := JsonToSegmento(Json);
        try
          TSegmentoService.Atualizar(IdSegmento, Segmento);

          TAppResponse.Ok(
            Res,
            TJSONObject.Create,
            'Segmento atualizado com sucesso.'
          );
        finally
          Segmento.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/segmentos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Claims: TJWTClaims;
      IdSegmento: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdSegmento := StrToInt64Def(Req.Params['id'], 0);

        TSegmentoService.Excluir(IdSegmento);

        TAppResponse.Ok(
          Res,
          TJSONObject.Create,
          'Segmento excluído com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
