unit Produto.Controller;

interface

type
  TProdutoController = class
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
  Produto.Model,
  Produto.Service,
  Assinatura.Service;


function ProdutoToJsonList(const AProduto: TProdutoModel): TJSONObject;
begin
  //Retorno para rota json Listagem
  Result := TJSONObject.Create;

  Result.AddPair('id_produto',    TJSONNumber.Create(AProduto.IdProduto));
  Result.AddPair('nome',          AProduto.Nome);
  Result.AddPair('preco',         TJSONNumber.Create(AProduto.Preco));
  Result.AddPair('promocao',      TJSONNumber.Create(AProduto.promocao));
  Result.AddPair('destaque',      AProduto.Destaque);
  Result.AddPair('ordem',         TJSONNumber.Create(AProduto.Ordem));
  Result.AddPair('ativo',         AProduto.Ativo);
  Result.AddPair('sigla',         AProduto.sigla);
  Result.AddPair('referencia',    AProduto.referencia);
  Result.AddPair('nmcategoria',   AProduto.nmcategoria);
  Result.AddPair('nmmarca',       AProduto.nmmarca);


end;


function ProdutoToJsonID(const AProduto: TProdutoModel): TJSONObject;
begin
  //Retorno para rota json Listagem
  Result := TJSONObject.Create;

  Result.AddPair('id_produto',    TJSONNumber.Create(AProduto.IdProduto));
  Result.AddPair('id_categoria',  TJSONNumber.Create(AProduto.IdCategoria));
  Result.AddPair('nome',          TAppClasses.SafeStr(AProduto.Nome));
  Result.AddPair('descricao',     TAppClasses.SafeStr(AProduto.Descricao));
  Result.AddPair('preco',         TJSONNumber.Create(AProduto.Preco));
  Result.AddPair('ativo',         AProduto.Ativo);
  Result.AddPair('destaque',      AProduto.Destaque);
  Result.AddPair('ordem',         TJSONNumber.Create(AProduto.Ordem));
  Result.AddPair('codigo',        TAppClasses.SafeStr(AProduto.codigo));
  Result.AddPair('id_unidade',     TJSONNumber.Create(AProduto.idunidade));
  Result.AddPair('id_marca',         TJSONNumber.Create(AProduto.idmarca));
  Result.AddPair('promocao',      TJSONNumber.Create(AProduto.promocao));
  Result.AddPair('referencia',    TAppClasses.SafeStr(AProduto.referencia));
  Result.AddPair('tags',          TAppClasses.SafeStr(AProduto.tags));
  Result.AddPair('imagem_principal', TAppClasses.SafeStr(AProduto.imagem_principal));

end;

function JsonToProduto(const AJson: TJSONObject): TProdutoModel;
begin
  //De Json para modelproduto post e put
  Result := TProdutoModel.Create;

  Result.IdCategoria    := TAppClasses.GetJsonInt(AJson,'id_categoria',0);
  Result.Nome           := TAppClasses.GetJsonString(AJson,'nome');
  Result.Descricao      := TAppClasses.GetJsonString(AJson,'descricao');
  Result.Preco          := TAppClasses.GetJsonCurrency(AJson,'preco',0);
  Result.Ativo          := TAppClasses.GetJsonString(AJson,'ativo','S');
  Result.Destaque       := TAppClasses.GetJsonString(AJson,'destaque','N');
  Result.Ordem          := TAppClasses.GetJsonInt(AJson,'ordem',0);
  Result.DataCriacao    := date;
  Result.codigo         := TAppClasses.GetJsonString(AJson,'codigo');
  Result.idmarca        := TAppClasses.GetJsonInt(AJson,'id_marca',0);
  Result.idunidade      := TAppClasses.GetJsonInt(AJson,'id_unidade',0);
  Result.promocao       := TAppClasses.GetJsonCurrency(AJson,'promocao',0);
  Result.referencia     := TAppClasses.GetJsonString(AJson,'referencia');
  Result.tags           := TAppClasses.GetJsonString(AJson,'tags');

end;


class procedure TProdutoController.Registry;
begin
  {$REGION 'Criar Produto'}

  THorse.Post('/v1/produtos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Json: TJSONObject;
      Produto: TProdutoModel;
      IdProduto: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);


        Json := Req.Body<TJSONObject>;
        if Json = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Produto := JsonToProduto(Json);
        try
          IdProduto := TProdutoService.CriarProduto(Claims.IdEmpresa, Produto);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_produto', TJSONNumber.Create(idproduto));

          TAppResponse.Created(Res, Retorno, 'Produto cadastrado com sucesso.');
        finally
          Produto.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Listar Produto'}

  THorse.Get('/v1/produtos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TProdutoModel>;
      Produto: TProdutoModel;
      Arr: TJSONArray;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Lista := TProdutoService.ListarProdutos(Claims.IdEmpresa);
        try
          Arr := TJSONArray.Create;

          for Produto in Lista do
            Arr.AddElement(ProdutoToJsonList(Produto));

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

  {$REGION 'Listar Produto por ID'}

  THorse.Get('/v1/produtos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      Produto: TProdutoModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        Produto := TProdutoService.BuscarProduto(Claims.IdEmpresa, IdProduto);
        try
          Json := ProdutoToJsonID(Produto);
          TAppResponse.Ok(Res, Json);
        finally
          Produto.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Atualizar Produto'}

  THorse.Put('/v1/produtos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      Json: TJSONObject;
      Produto: TProdutoModel;
    begin

      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        Json := Req.Body<TJSONObject>;
        if Json = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');
        Produto := JsonToProduto(Json);
        try
          TProdutoService.AtualizarProduto(Claims.IdEmpresa, IdProduto, Produto);
          TAppResponse.Ok(Res, TJSONObject.Create, 'Produto atualizado com sucesso.');
        finally
          Produto.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Excluir Produto'}

  THorse.Delete('/v1/produtos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        TProdutoService.ExcluirProduto(Claims.IdEmpresa, IdProduto);

        TAppResponse.Ok(Res, TJSONObject.Create, 'Produto excluído com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);


  {$ENDREGION}

end;

end.
