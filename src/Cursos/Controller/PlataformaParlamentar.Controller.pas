unit PlataformaParlamentar.Controller;

interface

type
  TPlataformaParlamentarController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaParlamentar.Service;

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
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para sincronizar contatos parlamentares.'
    );
    Exit;
  end;

  Result := True;
end;

function ParseBodyOpcional(const Req: THorseRequest): TJSONObject;
var
  Raw: TJSONValue;
begin
  Result := TJSONObject.Create;
  if Trim(Req.Body).IsEmpty then
    Exit;

  Raw := TJSONObject.ParseJSONValue(Req.Body);
  if not (Raw is TJSONObject) then
  begin
    Raw.Free;
    Result.Free;
    TAppErrors.RaiseBadRequest('JSON inválido.');
  end;

  Result.Free;
  Result := Raw as TJSONObject;
end;

function JsonString(const AObj: TJSONObject; const ANome: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  if AObj = nil then
    Exit;
  V := AObj.GetValue(ANome);
  if (V <> nil) and not (V is TJSONNull) then
    Result := V.Value;
end;

class procedure TPlataformaParlamentarController.Registry;
begin
  THorse.Post(
    '/v1/certifica/plataforma/contatos/sincronizar/deputados-federais',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body, Dados: TJSONObject;
      UF: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Body := ParseBodyOpcional(Req);
        try
          UF := JsonString(Body, 'uf');
          Dados := TPlataformaParlamentarService.SincronizarDeputadosFederais(
            Claims.UserId,
            UF,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );
        finally
          Body.Free;
        end;

        TAppResponse.Ok(
          Res,
          Dados,
          'Deputados federais sincronizados com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/contatos/sincronizar/senadores',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body, Dados: TJSONObject;
      UF: string;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Body := ParseBodyOpcional(Req);
        try
          UF := JsonString(Body, 'uf');
          Dados := TPlataformaParlamentarService.SincronizarSenadores(
            Claims.UserId,
            UF,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );
        finally
          Body.Free;
        end;

        TAppResponse.Ok(
          Res,
          Dados,
          'Senadores sincronizados com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
