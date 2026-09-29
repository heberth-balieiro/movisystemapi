unit PlataformaWhatsApp.Service;

interface

uses
  System.JSON,
  PlataformaWhatsApp.Model;

type
  TPlataformaWhatsAppService = class
  private
    class function NormalizarUrl(
      const AUrl: string
    ): string; static;

  public
    class function Buscar: TPlataformaWhatsAppConfig; static;

    class function ObterCredenciais(
      out AApiUrl,
          AApiKey: string
    ): Boolean; overload; static;

    class function ObterCredenciais(
      out AApiUrl,
          AApiKey,
          ANomeInstancia: string
    ): Boolean; overload; static;

    class function Atualizar(
      const AIdUsuario: Int64;
      const ADados: TPlataformaWhatsAppInput;
      const AIP,
            AUserAgent: string
    ): TPlataformaWhatsAppConfig; static;

    class function CriarInstanciaEmpresa(
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TPlataformaWhatsAppConfig; static;

    class function ObterQrCodeEmpresa(
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TJSONObject; static;

    class function AtualizarStatusEmpresa:
      TPlataformaWhatsAppConfig; static;

    class function LogoutEmpresa(
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TPlataformaWhatsAppConfig; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Certifica.Secrets,
  PlataformaWhatsApp.DAO,
  EvolutionApi.Service;

class function TPlataformaWhatsAppService.NormalizarUrl(
  const AUrl: string
): string;
begin
  Result :=
    Trim(AUrl);

  while Result.EndsWith('/') do
    Delete(
      Result,
      Length(Result),
      1
    );

  if Result.IsEmpty then
    Exit;

  if not (
    Result.ToLower.StartsWith('http://') or
    Result.ToLower.StartsWith('https://')
  ) then
    TAppErrors.RaiseBadRequest(
      'Informe uma URL HTTP ou HTTPS válida.'
    );

  if Length(Result) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL da API excede o tamanho permitido.'
    );
end;

class function TPlataformaWhatsAppService.Buscar:
  TPlataformaWhatsAppConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      TPlataformaWhatsAppDAO.Buscar(
        Conn
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaWhatsAppService.ObterCredenciais(
  out AApiUrl,
      AApiKey: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  WhatsAppConfig: TPlataformaWhatsAppConfig;
begin
  Result := False;
  AApiUrl := '';
  AApiKey := '';

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    WhatsAppConfig :=
      TPlataformaWhatsAppDAO.Buscar(
        Conn
      );

    if not WhatsAppConfig.Habilitado then
      Exit;

    if Trim(WhatsAppConfig.ApiUrl).IsEmpty then
      Exit;

    AApiKey :=
      TPlataformaWhatsAppDAO.ObterApiKey(
        Conn,
        TCertificaSecrets.WhatsAppTokenSecret
      );

    if Trim(AApiKey).IsEmpty then
      Exit;

    AApiUrl :=
      WhatsAppConfig.ApiUrl;

    Result := True;
  finally
    Conn.Free;
  end;
end;

class function TPlataformaWhatsAppService.ObterCredenciais(
  out AApiUrl,
      AApiKey,
      ANomeInstancia: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  WhatsAppConfig: TPlataformaWhatsAppConfig;
begin
  Result := False;
  AApiUrl := '';
  AApiKey := '';
  ANomeInstancia := '';

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    WhatsAppConfig :=
      TPlataformaWhatsAppDAO.Buscar(
        Conn
      );

    if not WhatsAppConfig.Habilitado then
      Exit;

    if Trim(WhatsAppConfig.ApiUrl).IsEmpty then
      Exit;

    AApiKey :=
      TPlataformaWhatsAppDAO.ObterApiKey(
        Conn,
        TCertificaSecrets.WhatsAppTokenSecret
      );

    if Trim(AApiKey).IsEmpty then
      Exit;

    if not SameText(WhatsAppConfig.ModoInstancia, 'EMPRESA') then
      Exit;

    if Trim(WhatsAppConfig.NomeInstancia).IsEmpty then
      Exit;

    AApiUrl := WhatsAppConfig.ApiUrl;
    ANomeInstancia := WhatsAppConfig.NomeInstancia;

    Result := True;
  finally
    Conn.Free;
  end;
end;

class function TPlataformaWhatsAppService.Atualizar(
  const AIdUsuario: Int64;
  const ADados: TPlataformaWhatsAppInput;
  const AIP,
        AUserAgent: string
): TPlataformaWhatsAppConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TPlataformaWhatsAppInput;
  TemApiKey: Boolean;
begin
  Result :=
    Default(
      TPlataformaWhatsAppConfig
    );

  if AIdUsuario <= 0 then
    TAppErrors.RaiseForbidden(
      'Usuário responsável pela operação não identificado.'
    );

  Dados := ADados;
  Dados.ApiUrl :=
    NormalizarUrl(
      Dados.ApiUrl
    );

  Dados.ModoInstancia :=
    UpperCase(
      Trim(
        Dados.ModoInstancia
      )
    );

  if Dados.ModoInstancia.IsEmpty then
    Dados.ModoInstancia := 'EMPRESA';

  if (Dados.ModoInstancia <> 'EMPRESA') and
     (Dados.ModoInstancia <> 'USUARIO') then
    TAppErrors.RaiseBadRequest(
      'Modo de conexão WhatsApp inválido.'
    );

  Dados.ApiKey :=
    Trim(
      Dados.ApiKey
    );

  Dados.NomeInstancia :=
    Trim(
      Dados.NomeInstancia
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    TemApiKey :=
      not Dados.ApiKey.IsEmpty;

    if not TemApiKey then
      TemApiKey :=
        TPlataformaWhatsAppDAO.TemApiKey(
          Conn
        );

    if Dados.Habilitado then
    begin
      if Dados.ApiUrl.IsEmpty then
        TAppErrors.RaiseBadRequest(
          'Informe a URL da API WhatsApp antes de habilitar a integração.'
        );

      if not TemApiKey then
        TAppErrors.RaiseBadRequest(
          'Informe a Key da API WhatsApp antes de habilitar a integração.'
        );
    end;

    Conn.StartTransaction;
    try
      TPlataformaWhatsAppDAO.Salvar(
        Conn,
        Dados,
        TCertificaSecrets.WhatsAppTokenSecret
      );

      TPlataformaWhatsAppDAO.RegistrarAuditoria(
        Conn,
        AIdUsuario,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result :=
      TPlataformaWhatsAppDAO.Buscar(
        Conn
      );
  finally
    Conn.Free;
  end;
end;


class function TPlataformaWhatsAppService.CriarInstanciaEmpresa(
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TPlataformaWhatsAppConfig;
var
  Conn: TUniConnection;
  Config: TPlataformaWhatsAppConfig;
  ApiUrl,
  ApiKey,
  NomeInstancia,
  Estado,
  Numero: string;
  Retorno: TJSONValue;
  G: TGUID;
begin
  Config := Buscar;

  if not Config.Habilitado then
    TAppErrors.RaiseBadRequest(
      'A integração WhatsApp da plataforma está desabilitada.'
    );

  if not SameText(Config.ModoInstancia, 'EMPRESA') then
    TAppErrors.RaiseBadRequest(
      'A configuração atual utiliza conexão WhatsApp por usuário.'
    );

  if not ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  if not (
    Trim(Config.EstadoEmpresa).IsEmpty or
    SameText(Config.EstadoEmpresa, 'NAO_CRIADA')
  ) then
    TAppErrors.RaiseBadRequest(
      'A empresa já possui uma instância WhatsApp criada.'
    );

  NomeInstancia := Trim(Config.NomeInstancia);

  if NomeInstancia.IsEmpty then
  begin
    CreateGUID(G);
    NomeInstancia :=
      'movisystem-empresa-' +
      Copy(
        StringReplace(
          StringReplace(
            StringReplace(
              LowerCase(GUIDToString(G)),
              '{',
              '',
              [rfReplaceAll]
            ),
            '}',
            '',
            [rfReplaceAll]
          ),
          '-',
          '',
          [rfReplaceAll]
        ),
        1,
        12
      );
  end;

  Retorno :=
    TEvolutionApiService.CriarInstancia(
      ApiUrl,
      ApiKey,
      NomeInstancia
    );
  try
    Estado :=
      TEvolutionApiService.ExtrairEstado(
        Retorno
      );

    if Estado.IsEmpty then
      Estado := 'CREATED';

    Numero :=
      TEvolutionApiService.ExtrairNumero(
        Retorno
      );
  finally
    Retorno.Free;
  end;

  Conn := TDatabaseConnection.NewConnection(
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    ).Database
  );
  try
    Conn.StartTransaction;
    try
      TPlataformaWhatsAppDAO.AtualizarEmpresa(
        Conn,
        NomeInstancia,
        Estado,
        Numero
      );

      TPlataformaWhatsAppDAO.RegistrarAuditoriaOperacao(
        Conn,
        AIdUsuario,
        'PLATAFORMA_WHATSAPP_EMPRESA_INSTANCIA_CRIADA',
        'Instância WhatsApp da empresa criada.',
        'POST',
        '/v1/certifica/plataforma/configuracoes/whatsapp/empresa/instancia',
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;

  Result := Buscar;
end;

class function TPlataformaWhatsAppService.ObterQrCodeEmpresa(
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  Config: TPlataformaWhatsAppConfig;
  ApiUrl,
  ApiKey,
  Estado,
  Numero,
  QrBase64,
  QrTexto: string;
  Retorno: TJSONValue;
begin
  Config := Buscar;

  if not SameText(Config.ModoInstancia, 'EMPRESA') then
    TAppErrors.RaiseBadRequest(
      'A configuração atual utiliza conexão WhatsApp por usuário.'
    );

  if not ObterCredenciais(
    ApiUrl,
    ApiKey,
    Config.NomeInstancia
  ) then
    TAppErrors.RaiseBadRequest(
      'Crie a instância WhatsApp da empresa antes de gerar o QR Code.'
    );

  Retorno :=
    TEvolutionApiService.ConectarInstancia(
      ApiUrl,
      ApiKey,
      Config.NomeInstancia
    );
  try
    Estado := TEvolutionApiService.ExtrairEstado(Retorno);
    if Estado.IsEmpty then
      Estado := 'AGUARDANDO_QRCODE';

    Numero := TEvolutionApiService.ExtrairNumero(Retorno);
    QrBase64 := TEvolutionApiService.ExtrairQrBase64(Retorno);
    QrTexto := TEvolutionApiService.ExtrairQrTexto(Retorno);
  finally
    Retorno.Free;
  end;

  Conn := TDatabaseConnection.NewConnection(
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    ).Database
  );
  try
    TPlataformaWhatsAppDAO.AtualizarEmpresa(
      Conn,
      Config.NomeInstancia,
      Estado,
      Numero
    );

    TPlataformaWhatsAppDAO.RegistrarAuditoriaOperacao(
      Conn,
      AIdUsuario,
      'PLATAFORMA_WHATSAPP_EMPRESA_QRCODE_GERADO',
      'QR Code solicitado para a instância WhatsApp da empresa.',
      'GET',
      '/v1/certifica/plataforma/configuracoes/whatsapp/empresa/qrcode',
      AIP,
      AUserAgent
    );
  finally
    Conn.Free;
  end;

  Result := TJSONObject.Create;
  Result.AddPair('nome_instancia', Config.NomeInstancia);
  Result.AddPair('estado', Estado);

  if QrBase64.IsEmpty then
    Result.AddPair('qrcode_base64', TJSONNull.Create)
  else
    Result.AddPair('qrcode_base64', QrBase64);

  if QrTexto.IsEmpty then
    Result.AddPair('qrcode_texto', TJSONNull.Create)
  else
    Result.AddPair('qrcode_texto', QrTexto);
end;

class function TPlataformaWhatsAppService.AtualizarStatusEmpresa:
  TPlataformaWhatsAppConfig;
var
  Conn: TUniConnection;
  Config: TPlataformaWhatsAppConfig;
  ApiUrl,
  ApiKey,
  Estado,
  Numero: string;
  Retorno: TJSONValue;
begin
  Config := Buscar;

  if not SameText(Config.ModoInstancia, 'EMPRESA') then
    TAppErrors.RaiseBadRequest(
      'A configuração atual utiliza conexão WhatsApp por usuário.'
    );

  if Trim(Config.NomeInstancia).IsEmpty then
  begin
    Result := Config;
    Exit;
  end;

  if not ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Retorno :=
    TEvolutionApiService.EstadoInstancia(
      ApiUrl,
      ApiKey,
      Config.NomeInstancia
    );
  try
    Estado := TEvolutionApiService.ExtrairEstado(Retorno);
    Numero := TEvolutionApiService.ExtrairNumero(Retorno);
  finally
    Retorno.Free;
  end;

  if Estado.IsEmpty then
    Estado := 'UNKNOWN';

  Conn := TDatabaseConnection.NewConnection(
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    ).Database
  );
  try
    TPlataformaWhatsAppDAO.AtualizarEmpresa(
      Conn,
      Config.NomeInstancia,
      Estado,
      Numero
    );
  finally
    Conn.Free;
  end;

  Result := Buscar;
end;

class function TPlataformaWhatsAppService.LogoutEmpresa(
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TPlataformaWhatsAppConfig;
var
  Conn: TUniConnection;
  Config: TPlataformaWhatsAppConfig;
  ApiUrl,
  ApiKey: string;
  Retorno: TJSONValue;
begin
  Config := Buscar;

  if not SameText(Config.ModoInstancia, 'EMPRESA') then
    TAppErrors.RaiseBadRequest(
      'A configuração atual utiliza conexão WhatsApp por usuário.'
    );

  if Trim(Config.NomeInstancia).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'A empresa ainda não possui uma instância WhatsApp.'
    );

  if not ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Retorno :=
    TEvolutionApiService.LogoutInstancia(
      ApiUrl,
      ApiKey,
      Config.NomeInstancia
    );
  Retorno.Free;

  Conn := TDatabaseConnection.NewConnection(
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    ).Database
  );
  try
    Conn.StartTransaction;
    try
      TPlataformaWhatsAppDAO.AtualizarEmpresa(
        Conn,
        Config.NomeInstancia,
        'LOGGED_OUT',
        ''
      );

      TPlataformaWhatsAppDAO.RegistrarAuditoriaOperacao(
        Conn,
        AIdUsuario,
        'PLATAFORMA_WHATSAPP_EMPRESA_DESCONECTADO',
        'Sessão WhatsApp da empresa desconectada.',
        'POST',
        '/v1/certifica/plataforma/configuracoes/whatsapp/empresa/logout',
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;

  Result := Buscar;
end;

end.
