unit PlataformaEmail.Model;

interface

uses
  System.JSON;

type
  TPlataformaEmailInput = record
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

  TPlataformaEmailConfig = record
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

implementation

function TPlataformaEmailConfig.ToJSON: TJSONObject;
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

end.
