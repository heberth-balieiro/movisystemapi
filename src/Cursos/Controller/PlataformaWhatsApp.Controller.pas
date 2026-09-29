unit PlataformaWhatsApp.Controller;

interface

type
  TPlataformaWhatsAppController = class
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
  PlataformaWhatsApp.Model,
  PlataformaWhatsApp.Service;

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
      'Sem permissão para administrar a integração WhatsApp da plataforma.'
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

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
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

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    SameText(
      Valor.Value,
      'true'
    );
end;

class procedure TPlataformaWhatsAppController.Registry;
begin

  {$REGION 'Buscar Configuracao'}

  THorse.Get(
    '/v1/certifica/plataforma/configuracoes/whatsapp',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Config: TPlataformaWhatsAppConfig;
    begin
      try
        if not AutorizarSuperAdmin(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Config :=
          TPlataformaWhatsAppService.Buscar;

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração global do WhatsApp carregada com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Atualizar Configuracao'}

  THorse.Put(
    '/v1/certifica/plataforma/configuracoes/whatsapp',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TPlataformaWhatsAppInput;
      Config: TPlataformaWhatsAppConfig;
    begin
      try
        if not AutorizarSuperAdmin(
          Req,
          Res,
          Claims
        ) then
          Exit;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TPlataformaWhatsAppInput
            );

          Dados.Habilitado :=
            JsonBoolean(
              Body,
              'habilitado',
              False
            );

          Dados.ModoInstancia :=
            JsonString(
              Body,
              'modo_instancia',
              'EMPRESA'
            );

          Dados.ApiUrl :=
            JsonString(
              Body,
              'api_url'
            );

          Dados.NomeInstancia :=
            JsonString(
              Body,
              'nome_instancia'
            );

          Dados.ApiKey :=
            JsonString(
              Body,
              'api_key'
            );
        finally
          Body.Free;
        end;

        Config :=
          TPlataformaWhatsAppService.Atualizar(
            Claims.UserId,
            Dados,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração global do WhatsApp atualizada com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}

end;

end.
