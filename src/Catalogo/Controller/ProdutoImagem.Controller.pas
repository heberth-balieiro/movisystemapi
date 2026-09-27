unit ProdutoImagem.Controller;

interface

type
  TProdutoImagemController = class
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
  ProdutoImagem.Model,
  ProdutoImagem.Service;


function ProdutoImagemToJson(const AImagem: TProdutoImagemModel): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_imagem', TJSONNumber.Create(AImagem.IdImagem));
  Result.AddPair('id_empresa', TJSONNumber.Create(AImagem.IdEmpresa));
  Result.AddPair('id_produto', TJSONNumber.Create(AImagem.IdProduto));
  Result.AddPair('url_imagem', AImagem.UrlImagem);
  Result.AddPair('principal', AImagem.Principal);
  Result.AddPair('ordem', TJSONNumber.Create(AImagem.Ordem));
  Result.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AImagem.DataCriacao));

  if AImagem.DataAlteracao > 0 then
    Result.AddPair('data_alteracao', FormatDateTime('yyyy-mm-dd hh:nn:ss', AImagem.DataAlteracao))
  else
    Result.AddPair('data_alteracao', TJSONNull.Create);
end;

class procedure TProdutoImagemController.Registry;
begin
  THorse.Post('/v1/produtos/:id/imagens',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      Body: TJSONObject;
      Imagem: TProdutoImagemModel;
      IdImagem: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Imagem := TProdutoImagemModel.Create;
        try
          Imagem.UrlImagem  := TAppClasses.GetJsonString(Body, 'url_imagem');
          Imagem.Principal  := TAppClasses.GetJsonString(Body, 'principal', 'N');
          Imagem.Ordem      := TAppClasses.GetJsonInt(Body, 'ordem', 0);

          IdImagem := TProdutoImagemService.CriarImagem(Claims.IdEmpresa, IdProduto, Imagem);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_imagem', TJSONNumber.Create(IdImagem));

          TAppResponse.Created(Res, Retorno, 'Imagem cadastrada com sucesso.');
        finally
          Imagem.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/produtos/:id/imagens',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      Lista: TObjectList<TProdutoImagemModel>;
      Imagem: TProdutoImagemModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        Lista := TProdutoImagemService.ListarImagens(Claims.IdEmpresa, IdProduto);
        try
          Arr := TJSONArray.Create;

          for Imagem in Lista do
            Arr.AddElement(ProdutoImagemToJson(Imagem));

          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/produtos/:id/imagens/:id_imagem',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      IdImagem: Int64;
      Imagem: TProdutoImagemModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);
        IdImagem := StrToInt64Def(Req.Params['id_imagem'], 0);

        Imagem := TProdutoImagemService.BuscarImagem(Claims.IdEmpresa, IdProduto, IdImagem);
        try
          Json := ProdutoImagemToJson(Imagem);
          TAppResponse.Ok(Res, Json);
        finally
          Imagem.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/produtos/:id/imagens/:id_imagem',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      IdImagem: Int64;
      Body: TJSONObject;
      Imagem: TProdutoImagemModel;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);
        IdImagem := StrToInt64Def(Req.Params['id_imagem'], 0);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Imagem := TProdutoImagemModel.Create;
        try
          Imagem.UrlImagem  := TAppClasses.GetJsonString(Body, 'url_imagem');
          Imagem.Principal  := TAppClasses.GetJsonString(Body, 'principal', 'N');
          Imagem.Ordem      := TAppClasses.GetJsonInt(Body, 'ordem', 0);

          TProdutoImagemService.AtualizarImagem(Claims.IdEmpresa, IdProduto, IdImagem, Imagem);

          TAppResponse.Ok(Res, TJSONObject.Create, 'Imagem atualizada com sucesso.');
        finally
          Imagem.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Delete('/v1/produtos/:id/imagens/:id_imagem',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      IdImagem: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);
        IdImagem := StrToInt64Def(Req.Params['id_imagem'], 0);

        TProdutoImagemService.ExcluirImagem(Claims.IdEmpresa, IdProduto, IdImagem);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Imagem excluída com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
