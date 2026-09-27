unit PlataformaWhatsApp.Model;

interface

uses
  System.JSON;

type
  TPlataformaWhatsAppInput = record
    Habilitado: Boolean;
    ApiUrl: string;
    ApiKey: string;
  end;

  TPlataformaWhatsAppConfig = record
    Habilitado: Boolean;
    ApiUrl: string;
    ApiKeyConfigurada: String;
    ApiKeyMascarada: string;
    function ToJSON: TJSONObject;
  end;

implementation

function TPlataformaWhatsAppConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'habilitado',
    TJSONBool.Create(Habilitado)
  );

  Result.AddPair(
    'api_url',
    ApiUrl
  );

  Result.AddPair(
    'api_key_configurada',ApiKeyConfigurada
  );

  if ApiKeyConfigurada <>'' then
    Result.AddPair(
      'api_key_mascarada',
      ApiKeyMascarada
    )
  else
    Result.AddPair(
      'api_key_mascarada',
      TJSONNull.Create
    );
end;

end.
