unit EvolutionApi.Service;

interface

uses
  System.JSON;

type
  TEvolutionApiService = class
  private
    class function Request(
      const AMethod,
            AUrl,
            AApiKey: string;
      const ABody: TJSONObject = nil
    ): TJSONValue; static;

    class function JsonStringDeep(
      const AJson: TJSONValue;
      const APaths: array of string
    ): string; static;

  public
    class function CriarInstancia(
      const AApiUrl,
            AApiKey,
            ANomeInstancia: string
    ): TJSONValue; static;

    class function ConectarInstancia(
      const AApiUrl,
            AApiKey,
            ANomeInstancia: string
    ): TJSONValue; static;

    class function EstadoInstancia(
      const AApiUrl,
            AApiKey,
            ANomeInstancia: string
    ): TJSONValue; static;

    class function LogoutInstancia(
      const AApiUrl,
            AApiKey,
            ANomeInstancia: string
    ): TJSONValue; static;

    class function ExtrairEstado(
      const AJson: TJSONValue
    ): string; static;

    class function ExtrairNumero(
      const AJson: TJSONValue
    ): string; static;

    class function ExtrairQrBase64(
      const AJson: TJSONValue
    ): string; static;

    class function ExtrairQrTexto(
      const AJson: TJSONValue
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  APP.Errors;

class function TEvolutionApiService.Request(
  const AMethod,
        AUrl,
        AApiKey: string;
  const ABody: TJSONObject
): TJSONValue;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  Stream: TStringStream;
  Headers: TNetHeaders;
  Texto: string;
begin
  Result := nil;
  Client := THTTPClient.Create;
  Stream := nil;
  try
    Client.ConnectionTimeout := 10000;
    Client.ResponseTimeout := 20000;

    if SameText(AMethod, 'POST') then
      SetLength(Headers, 3)
    else
      SetLength(Headers, 2);

    Headers[0].Name := 'apikey';
    Headers[0].Value := AApiKey;
    Headers[1].Name := 'Accept';
    Headers[1].Value := 'application/json';

    if Length(Headers) = 3 then
    begin
      Headers[2].Name := 'Content-Type';
      Headers[2].Value := 'application/json';
    end;

    if SameText(AMethod, 'GET') then
      Response :=
        Client.Get(
          AUrl,
          nil,
          Headers
        )
    else if SameText(AMethod, 'POST') then
    begin
      Stream :=
        TStringStream.Create(
          IfThen(
            Assigned(ABody),
            ABody.ToJSON,
            '{}'
          ),
          TEncoding.UTF8
        );

      Response :=
        Client.Post(
          AUrl,
          Stream,
          nil,
          Headers
        );
    end
    else if SameText(AMethod, 'DELETE') then
      Response :=
        Client.Delete(
          AUrl,
          nil,
          Headers
        )
    else
      raise Exception.Create(
        'Método HTTP não suportado.'
      );

    Texto :=
      Response.ContentAsString(
        TEncoding.UTF8
      );

    if (Response.StatusCode < 200) or
       (Response.StatusCode >= 300) then
      TAppErrors.RaiseBadRequest(
        'Evolution API retornou HTTP ' +
        Response.StatusCode.ToString +
        IfThen(
          Trim(Texto) <> '',
          ': ' + Copy(Texto, 1, 500),
          '.'
        )
      );

    if Trim(Texto) = '' then
      Exit(
        TJSONObject.Create
      );

    Result :=
      TJSONObject.ParseJSONValue(
        Texto
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Resposta inválida da Evolution API.'
      );
  finally
    Stream.Free;
    Client.Free;
  end;
end;

class function TEvolutionApiService.JsonStringDeep(
  const AJson: TJSONValue;
  const APaths: array of string
): string;
var
  Path: string;
  Value: TJSONValue;
begin
  Result := '';

  if AJson = nil then
    Exit;

  for Path in APaths do
  begin
    Value := AJson.FindValue(Path);

    if (Value <> nil) and
       not (Value is TJSONNull) then
    begin
      Result := Value.Value;
      if Trim(Result) <> '' then
        Exit;
    end;
  end;
end;

class function TEvolutionApiService.CriarInstancia(
  const AApiUrl,
        AApiKey,
        ANomeInstancia: string
): TJSONValue;
var
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  try
    Body.AddPair(
      'instanceName',
      ANomeInstancia
    );

    Body.AddPair(
      'qrcode',
      TJSONBool.Create(True)
    );

    Body.AddPair(
      'integration',
      'WHATSAPP-BAILEYS'
    );

    Result :=
      Request(
        'POST',
        AApiUrl + '/instance/create',
        AApiKey,
        Body
      );
  finally
    Body.Free;
  end;
end;

class function TEvolutionApiService.ConectarInstancia(
  const AApiUrl,
        AApiKey,
        ANomeInstancia: string
): TJSONValue;
begin
  Result :=
    Request(
      'GET',
      AApiUrl +
      '/instance/connect/' +
      TNetEncoding.URL.Encode(ANomeInstancia),
      AApiKey
    );
end;

class function TEvolutionApiService.EstadoInstancia(
  const AApiUrl,
        AApiKey,
        ANomeInstancia: string
): TJSONValue;
begin
  Result :=
    Request(
      'GET',
      AApiUrl +
      '/instance/connectionState/' +
      TNetEncoding.URL.Encode(ANomeInstancia),
      AApiKey
    );
end;

class function TEvolutionApiService.LogoutInstancia(
  const AApiUrl,
        AApiKey,
        ANomeInstancia: string
): TJSONValue;
begin
  Result :=
    Request(
      'DELETE',
      AApiUrl +
      '/instance/logout/' +
      TNetEncoding.URL.Encode(ANomeInstancia),
      AApiKey
    );
end;

class function TEvolutionApiService.ExtrairEstado(
  const AJson: TJSONValue
): string;
begin
  Result :=
    JsonStringDeep(
      AJson,
      [
        'instance.state',
        'instance.status',
        'state',
        'status'
      ]
    );

  Result :=
    UpperCase(
      Trim(Result)
    );
end;

class function TEvolutionApiService.ExtrairNumero(
  const AJson: TJSONValue
): string;
begin
  Result :=
    JsonStringDeep(
      AJson,
      [
        'instance.ownerJid',
        'instance.number',
        'ownerJid',
        'number'
      ]
    );
end;

class function TEvolutionApiService.ExtrairQrBase64(
  const AJson: TJSONValue
): string;
begin
  Result :=
    JsonStringDeep(
      AJson,
      [
        'base64',
        'qrcode.base64',
        'qr.base64'
      ]
    );
end;

class function TEvolutionApiService.ExtrairQrTexto(
  const AJson: TJSONValue
): string;
begin
  Result :=
    JsonStringDeep(
      AJson,
      [
        'code',
        'qrcode.code',
        'qr.code',
        'pairingCode'
      ]
    );
end;

end.
