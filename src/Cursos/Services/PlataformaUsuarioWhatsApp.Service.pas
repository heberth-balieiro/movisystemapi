unit PlataformaUsuarioWhatsApp.Service;

interface

uses
  System.JSON,
  Uni;

type
  TPlataformaUsuarioWhatsAppService = class
  private
    class function NovaConexao: TUniConnection; static;
    class function NovaInstancia(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ): string; static;
    class procedure ExigirModoUsuario; static;

  public
    class function BuscarStatus(
      const AIdUsuario: Int64
    ): TJSONObject; static;

    class function CriarInstancia(
      const AIdUsuarioAcao,
            AIdUsuarioAlvo: Int64;
      const AIP,
            AUserAgent: string
    ): TJSONObject; static;

    class function ObterQrCode(
      const AIdUsuarioAcao,
            AIdUsuarioAlvo: Int64;
      const AIP,
            AUserAgent: string
    ): TJSONObject; static;

    class function AtualizarStatus(
      const AIdUsuarioAlvo: Int64
    ): TJSONObject; static;

    class function Logout(
      const AIdUsuarioAcao,
            AIdUsuarioAlvo: Int64;
      const AIP,
            AUserAgent: string
    ): TJSONObject; static;

    class function ObterInstanciaParaEnvio(
      const AIdUsuario: Int64;
      out AApiUrl,
          AApiKey,
          ANomeInstancia: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaWhatsApp.Model,
  PlataformaWhatsApp.Service,
  PlataformaUsuarioWhatsApp.DAO,
  EvolutionApi.Service;

class function TPlataformaUsuarioWhatsAppService.NovaConexao: TUniConnection;
var
  Config: TAppApiConfig;
begin
  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Result :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
end;

class procedure TPlataformaUsuarioWhatsAppService.ExigirModoUsuario;
var
  Config: TPlataformaWhatsAppConfig;
begin
  Config := TPlataformaWhatsAppService.Buscar;

  if not Config.Habilitado then
    TAppErrors.RaiseBadRequest(
      'A integração WhatsApp da plataforma está desabilitada.'
    );

  if not SameText(Config.ModoInstancia, 'USUARIO') then
    TAppErrors.RaiseBadRequest(
      'A configuração atual utiliza uma única conexão WhatsApp da empresa.'
    );
end;

class function TPlataformaUsuarioWhatsAppService.NovaInstancia(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
): string;
var
  G: TGUID;
  S: string;
  Tentativa: Integer;
begin
  for Tentativa := 1 to 10 do
  begin
    CreateGUID(G);
    S := LowerCase(GUIDToString(G));
    S := StringReplace(S, '{', '', [rfReplaceAll]);
    S := StringReplace(S, '}', '', [rfReplaceAll]);
    S := StringReplace(S, '-', '', [rfReplaceAll]);

    Result :=
      'movisystem-u' +
      AIdUsuario.ToString +
      '-' +
      Copy(S, 1, 10);

    if not TPlataformaUsuarioWhatsAppDAO.NomeInstanciaExiste(
      AConn,
      Result
    ) then
      Exit;
  end;

  raise Exception.Create(
    'Não foi possível gerar uma instância WhatsApp exclusiva.'
  );
end;

class function TPlataformaUsuarioWhatsAppService.BuscarStatus(
  const AIdUsuario: Int64
): TJSONObject;
var
  Conn: TUniConnection;
begin
  ExigirModoUsuario;

  Conn := NovaConexao;
  try
    if not TPlataformaUsuarioWhatsAppDAO.UsuarioPlataformaExiste(
      Conn,
      AIdUsuario
    ) then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );

    Result :=
      TPlataformaUsuarioWhatsAppDAO.Buscar(
        Conn,
        AIdUsuario
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppService.CriarInstancia(
  const AIdUsuarioAcao,
        AIdUsuarioAlvo: Int64;
  const AIP,
        AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  ApiUrl,
  ApiKey,
  NomeInstancia: string;
  Retorno: TJSONValue;
begin
  ExigirModoUsuario;

  if not TPlataformaWhatsAppService.ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Conn := NovaConexao;
  try
    if not TPlataformaUsuarioWhatsAppDAO.UsuarioPlataformaExiste(
      Conn,
      AIdUsuarioAlvo
    ) then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );

    NomeInstancia :=
      TPlataformaUsuarioWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdUsuarioAlvo
      );

    if not NomeInstancia.IsEmpty then
      TAppErrors.RaiseBadRequest(
        'O usuário já possui uma instância WhatsApp.'
      );

    NomeInstancia :=
      NovaInstancia(
        Conn,
        AIdUsuarioAlvo
      );

    Retorno :=
      TEvolutionApiService.CriarInstancia(
        ApiUrl,
        ApiKey,
        NomeInstancia
      );
    Retorno.Free;

    Conn.StartTransaction;
    try
      TPlataformaUsuarioWhatsAppDAO.SalvarInstancia(
        Conn,
        AIdUsuarioAlvo,
        NomeInstancia,
        'CREATED'
      );

      TPlataformaUsuarioWhatsAppDAO.RegistrarAuditoria(
        Conn,
        AIdUsuarioAcao,
        AIdUsuarioAlvo,
        'PLATAFORMA_WHATSAPP_USUARIO_INSTANCIA_CRIADA',
        'Instância WhatsApp criada para o usuário da plataforma.',
        'POST',
        '/v1/certifica/plataforma/usuarios/' +
          AIdUsuarioAlvo.ToString +
          '/whatsapp/instancia',
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
      TPlataformaUsuarioWhatsAppDAO.Buscar(
        Conn,
        AIdUsuarioAlvo
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppService.ObterQrCode(
  const AIdUsuarioAcao,
        AIdUsuarioAlvo: Int64;
  const AIP,
        AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  ApiUrl,
  ApiKey,
  NomeInstancia,
  Estado,
  Numero: string;
  Retorno: TJSONValue;
begin
  ExigirModoUsuario;

  if not TPlataformaWhatsAppService.ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Conn := NovaConexao;
  try
    NomeInstancia :=
      TPlataformaUsuarioWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdUsuarioAlvo
      );

    if NomeInstancia.IsEmpty then
      TAppErrors.RaiseBadRequest(
        'Crie a instância WhatsApp do usuário antes de gerar o QR Code.'
      );

    Retorno :=
      TEvolutionApiService.ConectarInstancia(
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
        Estado := 'AGUARDANDO_QRCODE';

      Numero :=
        TEvolutionApiService.ExtrairNumero(
          Retorno
        );

      TPlataformaUsuarioWhatsAppDAO.AtualizarEstado(
        Conn,
        AIdUsuarioAlvo,
        Estado,
        Numero
      );

      Result := TJSONObject.Create;
      Result.AddPair('id_usuario', TJSONNumber.Create(AIdUsuarioAlvo));
      Result.AddPair('nome_instancia', NomeInstancia);
      Result.AddPair('estado', Estado);

      if Trim(
        TEvolutionApiService.ExtrairQrBase64(
          Retorno
        )
      ).IsEmpty then
        Result.AddPair('qrcode_base64', TJSONNull.Create)
      else
        Result.AddPair(
          'qrcode_base64',
          TEvolutionApiService.ExtrairQrBase64(
            Retorno
          )
        );

      if Trim(
        TEvolutionApiService.ExtrairQrTexto(
          Retorno
        )
      ).IsEmpty then
        Result.AddPair('qrcode_texto', TJSONNull.Create)
      else
        Result.AddPair(
          'qrcode_texto',
          TEvolutionApiService.ExtrairQrTexto(
            Retorno
          )
        );
    finally
      Retorno.Free;
    end;

    TPlataformaUsuarioWhatsAppDAO.RegistrarAuditoria(
      Conn,
      AIdUsuarioAcao,
      AIdUsuarioAlvo,
      'PLATAFORMA_WHATSAPP_USUARIO_QRCODE_GERADO',
      'QR Code solicitado para a instância WhatsApp do usuário.',
      'GET',
      '/v1/certifica/plataforma/usuarios/' +
        AIdUsuarioAlvo.ToString +
        '/whatsapp/qrcode',
      AIP,
      AUserAgent
    );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppService.AtualizarStatus(
  const AIdUsuarioAlvo: Int64
): TJSONObject;
var
  Conn: TUniConnection;
  ApiUrl,
  ApiKey,
  NomeInstancia,
  Estado,
  Numero: string;
  Retorno: TJSONValue;
begin
  ExigirModoUsuario;

  if not TPlataformaWhatsAppService.ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Conn := NovaConexao;
  try
    NomeInstancia :=
      TPlataformaUsuarioWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdUsuarioAlvo
      );

    if NomeInstancia.IsEmpty then
    begin
      Result :=
        TPlataformaUsuarioWhatsAppDAO.Buscar(
          Conn,
          AIdUsuarioAlvo
        );
      Exit;
    end;

    Retorno :=
      TEvolutionApiService.EstadoInstancia(
        ApiUrl,
        ApiKey,
        NomeInstancia
      );
    try
      Estado :=
        TEvolutionApiService.ExtrairEstado(
          Retorno
        );

      Numero :=
        TEvolutionApiService.ExtrairNumero(
          Retorno
        );
    finally
      Retorno.Free;
    end;

    if Estado.IsEmpty then
      Estado := 'UNKNOWN';

    TPlataformaUsuarioWhatsAppDAO.AtualizarEstado(
      Conn,
      AIdUsuarioAlvo,
      Estado,
      Numero
    );

    Result :=
      TPlataformaUsuarioWhatsAppDAO.Buscar(
        Conn,
        AIdUsuarioAlvo
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppService.Logout(
  const AIdUsuarioAcao,
        AIdUsuarioAlvo: Int64;
  const AIP,
        AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  ApiUrl,
  ApiKey,
  NomeInstancia: string;
  Retorno: TJSONValue;
begin
  ExigirModoUsuario;

  if not TPlataformaWhatsAppService.ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseBadRequest(
      'Configuração global da Evolution API indisponível.'
    );

  Conn := NovaConexao;
  try
    NomeInstancia :=
      TPlataformaUsuarioWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdUsuarioAlvo
      );

    if NomeInstancia.IsEmpty then
      TAppErrors.RaiseBadRequest(
        'O usuário ainda não possui uma instância WhatsApp.'
      );

    Retorno :=
      TEvolutionApiService.LogoutInstancia(
        ApiUrl,
        ApiKey,
        NomeInstancia
      );
    Retorno.Free;

    Conn.StartTransaction;
    try
      TPlataformaUsuarioWhatsAppDAO.AtualizarEstado(
        Conn,
        AIdUsuarioAlvo,
        'LOGGED_OUT',
        ''
      );

      TPlataformaUsuarioWhatsAppDAO.RegistrarAuditoria(
        Conn,
        AIdUsuarioAcao,
        AIdUsuarioAlvo,
        'PLATAFORMA_WHATSAPP_USUARIO_DESCONECTADO',
        'Sessão WhatsApp do usuário desconectada.',
        'POST',
        '/v1/certifica/plataforma/usuarios/' +
          AIdUsuarioAlvo.ToString +
          '/whatsapp/logout',
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
      TPlataformaUsuarioWhatsAppDAO.Buscar(
        Conn,
        AIdUsuarioAlvo
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioWhatsAppService.ObterInstanciaParaEnvio(
  const AIdUsuario: Int64;
  out AApiUrl,
      AApiKey,
      ANomeInstancia: string
): Boolean;
var
  Status: TJSONObject;
  Estado: string;
begin
  Result := False;
  AApiUrl := '';
  AApiKey := '';
  ANomeInstancia := '';

  ExigirModoUsuario;

  if not TPlataformaWhatsAppService.ObterCredenciais(
    AApiUrl,
    AApiKey
  ) then
    Exit;

  Status :=
    AtualizarStatus(
      AIdUsuario
    );
  try
    Estado :=
      Status.GetValue<string>(
        'estado',
        ''
      );

    if not (
      SameText(Estado, 'OPEN') or
      SameText(Estado, 'CONNECTED')
    ) then
      Exit;

    ANomeInstancia :=
      Status.GetValue<string>(
        'nome_instancia',
        ''
      );

    Result :=
      not Trim(ANomeInstancia).IsEmpty;
  finally
    Status.Free;
  end;
end;

end.
