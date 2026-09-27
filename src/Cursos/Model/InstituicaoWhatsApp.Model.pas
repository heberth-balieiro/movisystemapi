unit InstituicaoWhatsApp.Model;

interface

uses
  System.JSON;

type
  TInstituicaoWhatsAppStatus = record
    Disponivel: Boolean;
    InstanciaCriada: Boolean;
    InstanciaNome: string;
    Estado: string;
    Conectado: Boolean;
    Numero: string;
    function ToJSON: TJSONObject;
  end;

  TInstituicaoWhatsAppQrCode = record
    Disponivel: Boolean;
    InstanciaNome: string;
    Estado: string;
    QrCodeBase64: string;
    QrCodeTexto: string;
    function ToJSON: TJSONObject;
  end;

implementation

function TInstituicaoWhatsAppStatus.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('disponivel', TJSONBool.Create(Disponivel));
  Result.AddPair('instancia_criada', TJSONBool.Create(InstanciaCriada));
  Result.AddPair('instancia_nome', InstanciaNome);
  Result.AddPair('estado', Estado);
  Result.AddPair('conectado', TJSONBool.Create(Conectado));

  if Trim(Numero) = '' then
    Result.AddPair('numero', TJSONNull.Create)
  else
    Result.AddPair('numero', Numero);
end;

function TInstituicaoWhatsAppQrCode.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('disponivel', TJSONBool.Create(Disponivel));
  Result.AddPair('instancia_nome', InstanciaNome);
  Result.AddPair('estado', Estado);

  if Trim(QrCodeBase64) = '' then
    Result.AddPair('qrcode_base64', TJSONNull.Create)
  else
    Result.AddPair('qrcode_base64', QrCodeBase64);

  if Trim(QrCodeTexto) = '' then
    Result.AddPair('qrcode_texto', TJSONNull.Create)
  else
    Result.AddPair('qrcode_texto', QrCodeTexto);
end;

end.
