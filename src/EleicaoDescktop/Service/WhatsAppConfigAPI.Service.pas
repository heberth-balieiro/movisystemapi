unit WhatsAppConfigAPI.Service;

interface

uses
  WhatsAppConfigAPI.Dao;

type
  TWhatsAppConfigAPIService = class
  public
    class function BuscarConfiguracao(const AIdEmpresa: Integer): TWhatsAppConfigDados; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection;

{ TWhatsAppConfigAPIService }

class function TWhatsAppConfigAPIService.BuscarConfiguracao(const AIdEmpresa: Integer): TWhatsAppConfigDados;
var
  Config: TAppApiConfig;
  Conn  : TUniConnection;
begin
  Result := Default(TWhatsAppConfigDados);

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TWhatsAppConfigAPIDao.BuscarConfiguracao(Conn, AIdEmpresa, Result) then
      TAppErrors.RaiseBadRequest('Configuração do WhatsApp não encontrada.');

    if not SameText(Result.Ativo, 'S') then
      TAppErrors.RaiseBadRequest('Empresa inativa para envio de WhatsApp.');

    if Trim(Result.URL).IsEmpty then
      TAppErrors.RaiseBadRequest('URL do WhatsApp não configurada.');

    if Trim(Result.Instancia).IsEmpty then
      TAppErrors.RaiseBadRequest('Instância do WhatsApp não configurada.');

    if Trim(Result.Token).IsEmpty then
      TAppErrors.RaiseBadRequest('Token do WhatsApp não configurado.');

  finally
    Conn.Free;
  end;
end;

end.
