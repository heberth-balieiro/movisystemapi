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

  TInstituicaoEmailInput = record
    Ativo: Boolean;
    SmtpHost: string;
    SmtpPorta: Integer;
    Seguranca: string;
    Usuario: string;
    Senha: string;
    RemetenteNome: string;
    RemetenteEmail: string;
    ResponderPara: string;
  end;

  TInstituicaoEmailConfig = record
    Ativo: Boolean;
    SmtpHost: string;
    SmtpPorta: Integer;
    Seguranca: string;
    Usuario: string;
    SenhaConfigurada: Boolean;
    SenhaMascarada: string;
    RemetenteNome: string;
    RemetenteEmail: string;
    ResponderPara: string;
    function ToJSON: TJSONObject;
  end;

  TInstituicaoAcessoEnvioInput = record
    EnviarEmail: Boolean;
    EnviarWhatsApp: Boolean;
  end;

  TInstituicaoAcessoEnvioConfig = record
    EnviarEmail: Boolean;
    EnviarWhatsApp: Boolean;
    function ToJSON: TJSONObject;
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

function TInstituicaoEmailConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('ativo', TJSONBool.Create(Ativo));
  Result.AddPair('smtp_host', SmtpHost);
  Result.AddPair('smtp_porta', TJSONNumber.Create(SmtpPorta));
  Result.AddPair('seguranca', Seguranca);
  Result.AddPair('usuario', Usuario);
  Result.AddPair('senha_configurada', TJSONBool.Create(SenhaConfigurada));

  if SenhaConfigurada then
    Result.AddPair('senha_mascarada', SenhaMascarada)
  else
    Result.AddPair('senha_mascarada', TJSONNull.Create);

  Result.AddPair('remetente_nome', RemetenteNome);
  Result.AddPair('remetente_email', RemetenteEmail);
  Result.AddPair('responder_para', ResponderPara);
end;

function TInstituicaoAcessoEnvioConfig.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('enviar_email', TJSONBool.Create(EnviarEmail));
  Result.AddPair('enviar_whatsapp', TJSONBool.Create(EnviarWhatsApp));
end;

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
