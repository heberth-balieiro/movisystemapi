unit PlataformaModulo.Controller;

interface

type
  TPlataformaModuloController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaModulo.Model,
  PlataformaModulo.Service;

function AutorizarSuperAdmin(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if not TAppToken.PossuiRole(
    AClaims.Roles,
    'SUPER_ADMIN'
  ) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para administrar módulos da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

function CodigosFromBody(
  const ABody: TJSONObject
): TList<string>;
var
  V: TJSONValue;
  Arr: TJSONArray;
  Item: TJSONValue;
begin
  Result := TList<string>.Create;

  V := ABody.GetValue('modulos');
  if not (V is TJSONArray) then
    Exit;

  Arr := V as TJSONArray;

  for Item in Arr do
    if not (Item is TJSONNull) then
      Result.Add(
        UpperCase(
          Trim(
            Item.Value
          )
        )
      );
end;

function CodigosToJson(
  const ACodigos: TList<string>
): TJSONArray;
var
  Codigo: string;
begin
  Result := TJSONArray.Create;

  for Codigo in ACodigos do
    Result.Add(Codigo);
end;

class procedure TPlataformaModuloController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/modulos',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Lista: TObjectList<TPlataformaModuloItem>;
      Item: TPlataformaModuloItem;
      Arr: TJSONArray;
      Json: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Lista :=
          TPlataformaModuloService.ListarCatalogo;
        try
          Arr := TJSONArray.Create;

          for Item in Lista do
          begin
            Json := TJSONObject.Create;
            Json.AddPair(
              'id',
              TJSONNumber.Create(Item.Id)
            );
            Json.AddPair('codigo', Item.Codigo);
            Json.AddPair('nome', Item.Nome);
            Json.AddPair('descricao', Item.Descricao);
            Json.AddPair('situacao', Item.Situacao);
            Json.AddPair(
              'ordem',
              TJSONNumber.Create(Item.Ordem)
            );
            Arr.AddElement(Json);
          end;

          TAppResponse.Ok(
            Res,
            Arr,
            'Módulos carregados com sucesso.'
          );
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
    '/v1/certifica/plataforma/instituicoes/:id/modulos',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInstituicao: Int64;
      Codigos: TList<string>;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInstituicao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Codigos :=
          TPlataformaModuloService.ListarInstituicao(
            IdInstituicao
          );
        try
          Dados := TJSONObject.Create;
          Dados.AddPair(
            'modulos',
            CodigosToJson(Codigos)
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Módulos da instituição carregados com sucesso.'
          );
        finally
          Codigos.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/plataforma/instituicoes/:id/modulos',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInstituicao: Int64;
      Body: TJSONObject;
      Codigos: TList<string>;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInstituicao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest(
            'JSON inválido ou não informado.'
          );

        Codigos := CodigosFromBody(Body);
        try
          TPlataformaModuloService.SalvarInstituicao(
            IdInstituicao,
            Claims.UserId,
            Codigos,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

          Dados := TJSONObject.Create;
          Dados.AddPair(
            'modulos',
            CodigosToJson(Codigos)
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Módulos da instituição atualizados com sucesso.'
          );
        finally
          Codigos.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
