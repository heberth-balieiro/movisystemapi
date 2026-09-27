unit InstituicaoWhatsApp.Service;

interface

uses
  InstituicaoWhatsApp.Model;

type
  TInstituicaoWhatsAppService = class
  private
    class function NovaInstancia(
      const AConn: TObject;
      const AIdInstituicao: Int64
    ): string; static;

  public
    class function Status(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoWhatsAppStatus; static;

    class function CriarInstancia(
      const AIdInstituicao,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const AIP,
            AUserAgent: string
    ): TInstituicaoWhatsAppStatus; static;

    class function ObterQrCode(
      const AIdInstituicao,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const AIP,
            AUserAgent: string
    ): TInstituicaoWhatsAppQrCode; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoWhatsApp.DAO,
  PlataformaWhatsApp.Service,
  EvolutionApi.Service;

class function TInstituicaoWhatsAppService.NovaInstancia(
  const AConn: TObject;
  const AIdInstituicao: Int64
): string;
var
  Conn: TUniConnection;
  G: TGUID;
  Codigo: string;
begin
  Conn := TUniConnection(AConn);

  repeat
    CreateGUID(G);

    Codigo :=
      LowerCase(
        StringReplace(
          StringReplace(
            StringReplace(
              GUIDToString(G),
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
        )
      );

    Result :=
      'certifica_' +
      AIdInstituicao.ToString +
      '_' +
      Copy(Codigo, 1, 10);
  until not TInstituicaoWhatsAppDAO.NomeInstanciaExiste(
    Conn,
    Result
  );
end;

class function TInstituicaoWhatsAppService.Status(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoWhatsAppStatus;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ApiUrl: string;
  ApiKey: string;
  NomeInstancia: string;
  Retorno: TJSONValue;
begin
  Result :=
    Default(
      TInstituicaoWhatsAppStatus
    );

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'whatsapp.visualizar'
  );

  Result.Disponivel :=
    TPlataformaWhatsAppService.ObterCredenciais(
      ApiUrl,
      ApiKey
    );

  if not Result.Disponivel then
    Exit;

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
    NomeInstancia :=
      TInstituicaoWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdInstituicao
      );

    Result.InstanciaNome :=
      NomeInstancia;

    Result.InstanciaCriada :=
      not NomeInstancia.IsEmpty;

    if not Result.InstanciaCriada then
    begin
      Result.Estado := 'NAO_CRIADA';
      Exit;
    end;

    Retorno :=
      TEvolutionApiService.EstadoInstancia(
        ApiUrl,
        ApiKey,
        NomeInstancia
      );
    try
      Result.Estado :=
        TEvolutionApiService.ExtrairEstado(
          Retorno
        );

      if Result.Estado.IsEmpty then
        Result.Estado := 'DESCONHECIDO';

      Result.Numero :=
        TEvolutionApiService.ExtrairNumero(
          Retorno
        );

      Result.Conectado :=
        SameText(Result.Estado, 'OPEN') or
        SameText(Result.Estado, 'CONNECTED');

      TInstituicaoWhatsAppDAO.AtualizarEstado(
        Conn,
        AIdInstituicao,
        Result.Estado,
        Result.Numero
      );
    finally
      Retorno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoWhatsAppService.CriarInstancia(
  const AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const AIP,
        AUserAgent: string
): TInstituicaoWhatsAppStatus;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ApiUrl: string;
  ApiKey: string;
  NomeInstancia: string;
  Retorno: TJSONValue;
begin
  Result :=
    Default(
      TInstituicaoWhatsAppStatus
    );

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'whatsapp.gerenciar'
  );

  if not TPlataformaWhatsAppService.ObterCredenciais(
    ApiUrl,
    ApiKey
  ) then
    TAppErrors.RaiseForbidden(
      'A integração WhatsApp não está habilitada pela MoviSystem.'
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
    NomeInstancia :=
      TInstituicaoWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdInstituicao
      );

    if not NomeInstancia.IsEmpty then
      TAppErrors.RaiseBadRequest(
        'A instituição já possui uma instância WhatsApp.'
      );

    NomeInstancia :=
      NovaInstancia(
        Conn,
        AIdInstituicao
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
      TInstituicaoWhatsAppDAO.SalvarInstancia(
        Conn,
        AIdInstituicao,
        NomeInstancia,
        'CREATED'
      );

      TInstituicaoWhatsAppDAO.RegistrarAuditoria(
        Conn,
        AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao,
        'WHATSAPP_INSTANCIA_CRIADA',
        'Instância WhatsApp criada para a instituição.',
        'POST',
        '/v1/certifica/configuracoes/whatsapp/instancia',
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result.Disponivel := True;
    Result.InstanciaCriada := True;
    Result.InstanciaNome := NomeInstancia;
    Result.Estado := 'CREATED';
    Result.Conectado := False;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoWhatsAppService.ObterQrCode(
  const AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const AIP,
        AUserAgent: string
): TInstituicaoWhatsAppQrCode;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ApiUrl: string;
  ApiKey: string;
  NomeInstancia: string;
  Retorno: TJSONValue;
begin
  Result :=
    Default(
      TInstituicaoWhatsAppQrCode
    );

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'whatsapp.gerenciar'
  );

  Result.Disponivel :=
    TPlataformaWhatsAppService.ObterCredenciais(
      ApiUrl,
      ApiKey
    );

  if not Result.Disponivel then
    TAppErrors.RaiseForbidden(
      'A integração WhatsApp não está habilitada pela MoviSystem.'
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
    NomeInstancia :=
      TInstituicaoWhatsAppDAO.BuscarNomeInstancia(
        Conn,
        AIdInstituicao
      );

    if NomeInstancia.IsEmpty then
      TAppErrors.RaiseBadRequest(
        'Crie a instância WhatsApp antes de solicitar o QR Code.'
      );

    Retorno :=
      TEvolutionApiService.ConectarInstancia(
        ApiUrl,
        ApiKey,
        NomeInstancia
      );
    try
      Result.InstanciaNome := NomeInstancia;
      Result.Estado :=
        TEvolutionApiService.ExtrairEstado(
          Retorno
        );

      if Result.Estado.IsEmpty then
        Result.Estado := 'AGUARDANDO_QRCODE';

      Result.QrCodeBase64 :=
        TEvolutionApiService.ExtrairQrBase64(
          Retorno
        );

      Result.QrCodeTexto :=
        TEvolutionApiService.ExtrairQrTexto(
          Retorno
        );
    finally
      Retorno.Free;
    end;

    TInstituicaoWhatsAppDAO.RegistrarAuditoria(
      Conn,
      AIdInstituicao,
      AIdUsuario,
      AIdUsuarioInstituicao,
      'WHATSAPP_QRCODE_SOLICITADO',
      'QR Code solicitado para conexão da instância WhatsApp.',
      'POST',
      '/v1/certifica/configuracoes/whatsapp/qrcode',
      AIP,
      AUserAgent
    );
  finally
    Conn.Free;
  end;
end;

end.
