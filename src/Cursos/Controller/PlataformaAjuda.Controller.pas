unit PlataformaAjuda.Controller;

interface

type
  TPlataformaAjudaController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Classes,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaAjuda.Model,
  PlataformaAjuda.Service;

function AutorizarSuperAdmin(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if not TAppToken.PossuiRole(AClaims.Roles, 'SUPER_ADMIN') then
  begin
    TAppResponse.Forbidden(Res, 'Sem permissao para administrar a plataforma.');
    Exit;
  end;

  Result := True;
end;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(Res, 'Token sem contexto de instituicao.');
    Exit;
  end;

  Result := True;
end;

function AjudaToJson(const AModel: TPlataformaAjudaModel): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AModel.Id));
  Result.AddPair('url_youtube', AModel.UrlYoutube);
  Result.AddPair('assunto', AModel.Assunto);
  Result.AddPair('descricao', AModel.Descricao);
  Result.AddPair('situacao', AModel.Situacao);
  Result.AddPair('ordem', TJSONNumber.Create(AModel.Ordem));
  Result.AddPair('criado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AModel.CriadoEm));
  Result.AddPair('atualizado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AModel.AtualizadoEm));
end;

procedure PreencherFromJson(
  const AJson: TJSONObject;
  const AModel: TPlataformaAjudaModel
);
begin
  AModel.UrlYoutube := TAppClasses.GetJsonString(AJson, 'url_youtube');
  AModel.Assunto := TAppClasses.GetJsonString(AJson, 'assunto');
  AModel.Descricao := TAppClasses.GetJsonString(AJson, 'descricao');
  AModel.Situacao := TAppClasses.GetJsonString(AJson, 'situacao', 'ATIVO');
  AModel.Ordem := AJson.GetValue<Integer>('ordem', 0);
end;

class procedure TPlataformaAjudaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/ajudas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TPlataformaAjudaModel>;
      Item: TPlataformaAjudaModel;
      Arr: TJSONArray;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Lista := TPlataformaAjudaService.Listar(
          Req.Query['pesquisa'],
          Req.Query['situacao']
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista do
            Arr.AddElement(AjudaToJson(Item));
          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/plataforma/ajudas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TPlataformaAjudaModel;
      Id: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Id := StrToInt64Def(Req.Params.Items['id'], 0);
        Item := TPlataformaAjudaService.Buscar(Id);
        try
          TAppResponse.Ok(Res, AjudaToJson(Item));
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/ajudas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Entrada, Salva: TPlataformaAjudaModel;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON invalido ou nao informado.');

        Entrada := TPlataformaAjudaModel.Create;
        try
          PreencherFromJson(Body, Entrada);
          Salva := TPlataformaAjudaService.Criar(
            Entrada,
            Claims.UserId,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );
          try
            TAppResponse.Created(
              Res,
              AjudaToJson(Salva),
              'Ajuda cadastrada com sucesso.'
            );
          finally
            Salva.Free;
          end;
        finally
          Entrada.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/plataforma/ajudas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Entrada, Salva: TPlataformaAjudaModel;
      Id: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Id := StrToInt64Def(Req.Params.Items['id'], 0);
        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON invalido ou nao informado.');

        Entrada := TPlataformaAjudaModel.Create;
        try
          PreencherFromJson(Body, Entrada);
          Salva := TPlataformaAjudaService.Atualizar(
            Id,
            Entrada,
            Claims.UserId,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );
          try
            TAppResponse.Ok(
              Res,
              AjudaToJson(Salva),
              'Ajuda atualizada com sucesso.'
            );
          finally
            Salva.Free;
          end;
        finally
          Entrada.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Patch(
    '/v1/certifica/plataforma/ajudas/:id/situacao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Salva: TPlataformaAjudaModel;
      Id: Int64;
      Situacao: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Id := StrToInt64Def(Req.Params.Items['id'], 0);
        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON invalido ou nao informado.');

        Situacao := TAppClasses.GetJsonString(Body, 'situacao');
        Salva := TPlataformaAjudaService.AlterarSituacao(
          Id,
          Situacao,
          Claims.UserId,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );
        try
          TAppResponse.Ok(
            Res,
            AjudaToJson(Salva),
            'Situacao da ajuda atualizada com sucesso.'
          );
        finally
          Salva.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  // Conteudo global de ajuda exibido dentro dos tenants.
  // Somente itens ativos sao retornados ao cliente.
  THorse.Get(
    '/v1/certifica/instituicao/ajudas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TPlataformaAjudaModel>;
      Item: TPlataformaAjudaModel;
      Arr: TJSONArray;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        Lista := TPlataformaAjudaService.ListarAtivas;
        try
          Arr := TJSONArray.Create;
          for Item in Lista do
            Arr.AddElement(AjudaToJson(Item));
          TAppResponse.Ok(Res, Arr);
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
