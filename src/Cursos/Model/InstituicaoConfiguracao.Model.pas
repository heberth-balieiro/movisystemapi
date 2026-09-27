unit InstituicaoConfiguracao.Model;

interface

uses
  System.JSON;

type
  TInstituicaoDadosInput = record
    Nome: string;
    RazaoSocial: string;
    Cnpj: string;
    Descricao: string;
    Email: string;
    Telefone: string;
    Site: string;
  end;

  TInstituicaoWhatsAppInput = record
    Ativo: Boolean;
    Url: string;
    Token: string;
  end;

  TInstituicaoWhatsAppConfig = record
    Ativo: Boolean;
    Url: string;
    TokenConfigurado: Boolean;
    TokenMascarado: string;
    function ToJSON: TJSONObject;
  end;

implementation

function TInstituicaoWhatsAppConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('ativo', TJSONBool.Create(Ativo));
  Result.AddPair('url', Url);
  Result.AddPair('token_configurado', TJSONBool.Create(TokenConfigurado));

  if TokenConfigurado then
    Result.AddPair('token_mascarado', TokenMascarado)
  else
    Result.AddPair('token_mascarado', TJSONNull.Create);
end;

end.
