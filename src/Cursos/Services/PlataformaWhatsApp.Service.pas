unit PlataformaWhatsApp.Service;

interface

uses
  PlataformaWhatsApp.Model;

type
  TPlataformaWhatsAppService = class
  private
    class function NormalizarUrl(
      const AUrl: string
    ): string; static;

  public
    class function Buscar: TPlataformaWhatsAppConfig; static;

    class function Atualizar(
      const AIdUsuario: Int64;
      const ADados: TPlataformaWhatsAppInput;
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
  PlataformaWhatsApp.DAO;

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

  Dados.ApiKey :=
    Trim(
      Dados.ApiKey
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

end.
