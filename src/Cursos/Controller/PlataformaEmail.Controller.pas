unit PlataformaEmail.Controller;

interface

type
  TPlataformaEmailController = class
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
  PlataformaEmail.Model,
  PlataformaEmail.Service;

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
      'Sem permissão para administrar o e-mail da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean = False
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := SameText(Valor.Value, 'true');
end;

class procedure TPlataformaEmailController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/configuracoes/email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Config: TPlataformaEmailConfig;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Config := TPlataformaEmailService.Buscar;

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração global de e-mail carregada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/plataforma/configuracoes/email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TPlataformaEmailInput;
      Config: TPlataformaEmailConfig;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TPlataformaEmailInput);
          Dados.Ativo := JsonBoolean(Body, 'ativo', False);
          Dados.SmtpHost := JsonString(Body, 'smtp_host');
          Dados.SmtpPorta := StrToIntDef(JsonString(Body, 'smtp_porta', '587'), 587);
          Dados.Seguranca := JsonString(Body, 'seguranca', 'STARTTLS');
          Dados.Usuario := JsonString(Body, 'usuario');
          Dados.Senha := JsonString(Body, 'senha');
          Dados.RemetenteNome := JsonString(Body, 'remetente_nome');
          Dados.RemetenteEmail := JsonString(Body, 'remetente_email');
          Dados.ResponderPara := JsonString(Body, 'responder_para');
        finally
          Body.Free;
        end;

        Config := TPlataformaEmailService.Atualizar(
          Claims.UserId,
          Dados,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração global de e-mail atualizada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
