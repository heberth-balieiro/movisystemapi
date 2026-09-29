unit PlataformaWhatsApp.Model;

interface

uses
  System.JSON;

type
  TPlataformaWhatsAppInput = record
    Habilitado: Boolean;
    ModoInstancia: string;
    ApiUrl: string;
    NomeInstancia: string;
    ApiKey: string;
  end;

  TPlataformaWhatsAppConfig = record
    Habilitado: Boolean;
    ModoInstancia: string;
    ApiUrl: string;
    NomeInstancia: string;
    ApiKeyConfigurada: String;
    ApiKeyMascarada: string;
    EstadoEmpresa: string;
    NumeroEmpresa: string;
    function ToJSON: TJSONObject;
  end;

implementation

uses
  System.SysUtils;

function TPlataformaWhatsAppConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'habilitado',
    TJSONBool.Create(Habilitado)
  );

  Result.AddPair(
    'modo_instancia',
    ModoInstancia
  );

  Result.AddPair(
    'api_url',
    ApiUrl
  );

  Result.AddPair(
    'nome_instancia',
    NomeInstancia
  );

  Result.AddPair(
    'estado_empresa',
    EstadoEmpresa
  );

  if Trim(NumeroEmpresa).IsEmpty then
    Result.AddPair('numero_empresa', TJSONNull.Create)
  else
    Result.AddPair('numero_empresa', NumeroEmpresa);

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
