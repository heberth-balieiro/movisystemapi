unit PlataformaWhatsApp.DAO;

interface

uses
  Uni,
  PlataformaWhatsApp.Model;

type
  TPlataformaWhatsAppDAO = class
  public
    class function Buscar(
      const AConn: TUniConnection
    ): TPlataformaWhatsAppConfig; static;

    class function TemApiKey(
      const AConn: TUniConnection
    ): Boolean; static;

    class function ObterApiKey(
      const AConn: TUniConnection;
      const ASecret: string
    ): string; static;

    class procedure Salvar(
      const AConn: TUniConnection;
      const ADados: TPlataformaWhatsAppInput;
      const ASecret: string
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaWhatsAppDAO.Buscar(
  const AConn: TUniConnection
): TPlataformaWhatsAppConfig;
var
  Qry: TUniQuery;
begin
  Result :=
    Default(
      TPlataformaWhatsAppConfig
    );

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT habilitado, api_url, ' +
      '       api_key_criptografada IS NOT NULL AS api_key_configurada, ' +
      '       api_key_hint ' +
      'FROM plataforma_whatsapp_configuracao ' +
      'WHERE id = 1';

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Habilitado :=
      Qry.FieldByName('habilitado').AsBoolean;

    Result.ApiUrl :=
      Qry.FieldByName('api_url').AsString;

    Result.ApiKeyConfigurada :=
      Qry.FieldByName('api_key_configurada').asstring;

    if Result.ApiKeyConfigurada <> '' then
      Result.ApiKeyMascarada :=
        '********' +
        Qry.FieldByName('api_key_hint').AsString;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaWhatsAppDAO.TemApiKey(
  const AConn: TUniConnection
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT api_key_criptografada IS NOT NULL AS tem_key ' +
      'FROM plataforma_whatsapp_configuracao ' +
      'WHERE id = 1';

    Qry.Open;

    Result :=
      (not Qry.IsEmpty) and
      Qry.FieldByName('tem_key').AsBoolean;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaWhatsAppDAO.ObterApiKey(
  const AConn: TUniConnection;
  const ASecret: string
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT CAST(AES_DECRYPT(api_key_criptografada, :secret) AS CHAR(4096)) AS api_key ' +
      'FROM plataforma_whatsapp_configuracao ' +
      'WHERE id = 1 ' +
      '  AND api_key_criptografada IS NOT NULL';

    Qry.ParamByName('secret').AsString :=
      ASecret;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        Qry.FieldByName('api_key').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaWhatsAppDAO.Salvar(
  const AConn: TUniConnection;
  const ADados: TPlataformaWhatsAppInput;
  const ASecret: string
);
var
  Qry: TUniQuery;
  Hint: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if not Trim(ADados.ApiKey).IsEmpty then
    begin
      if Length(ADados.ApiKey) <= 4 then
        Hint := ADados.ApiKey
      else
        Hint :=
          Copy(
            ADados.ApiKey,
            Length(ADados.ApiKey) - 3,
            4
          );

      Qry.SQL.Text :=
        'INSERT INTO plataforma_whatsapp_configuracao ' +
        '(id, habilitado, api_url, api_key_criptografada, api_key_hint) ' +
        'VALUES ' +
        '(1, :habilitado, :api_url, AES_ENCRYPT(:api_key, :secret), :hint) ' +
        'ON DUPLICATE KEY UPDATE ' +
        'habilitado = VALUES(habilitado), ' +
        'api_url = VALUES(api_url), ' +
        'api_key_criptografada = VALUES(api_key_criptografada), ' +
        'api_key_hint = VALUES(api_key_hint)';
    end
    else
    begin
      Qry.SQL.Text :=
        'INSERT INTO plataforma_whatsapp_configuracao ' +
        '(id, habilitado, api_url) ' +
        'VALUES ' +
        '(1, :habilitado, :api_url) ' +
        'ON DUPLICATE KEY UPDATE ' +
        'habilitado = VALUES(habilitado), ' +
        'api_url = VALUES(api_url)';
    end;

    Qry.ParamByName('habilitado').AsInteger :=
      Ord(ADados.Habilitado);

    Qry.ParamByName('api_url').AsString :=
      ADados.ApiUrl;

    if not Trim(ADados.ApiKey).IsEmpty then
    begin
      Qry.ParamByName('api_key').AsString :=
        ADados.ApiKey;

      Qry.ParamByName('secret').AsString :=
        ASecret;

      Qry.ParamByName('hint').AsString :=
        Hint;
    end;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaWhatsAppDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, ' +
      'acao, entidade, registro_id, metodo_http, rota, ' +
      'ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ' +
      '''PLATAFORMA_WHATSAPP_CONFIG_ALTERADA'', ' +
      '''plataforma_whatsapp_configuracao'', ''1'', ''PUT'', ' +
      '''/v1/certifica/plataforma/configuracoes/whatsapp'', ' +
      ':ip, :user_agent, 1, ' +
      '''Configuração global da integração WhatsApp atualizada.'')';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ParamByName('ip').AsString :=
      Copy(
        Trim(AIP),
        1,
        45
      );

    Qry.ParamByName('user_agent').AsString :=
      Copy(
        Trim(AUserAgent),
        1,
        1000
      );

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
