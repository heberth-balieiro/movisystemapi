unit EleicaoMembroFotoAPI.Service;

interface

uses
  System.SysUtils;

type
  TEleicaoMembroFotoResult = record
    Arquivo: TBytes;
    Extensao: string;
    ContentType: string;
  end;

  TEleicaoMembroFotoAPIService = class
  private
    class function ObterContentType(const AExtensao: string): string; static;
  public
    class function BuscarFoto(const ASlug: string; const AIdMembro: Integer): TEleicaoMembroFotoResult; static;
  end;

implementation

uses
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoMembroFotoAPI.Dao;

class function TEleicaoMembroFotoAPIService.ObterContentType(const AExtensao: string): string;
var
  Ext: string;
begin
  Ext := UpperCase(Trim(AExtensao));

  if (Ext = 'JPG') or (Ext = 'JPEG') then
    Exit('image/jpeg');

  if Ext = 'PNG' then
    Exit('image/png');

  if Ext = 'WEBP' then
    Exit('image/webp');

  if Ext = 'GIF' then
    Exit('image/gif');

  Result := 'application/octet-stream';
end;

class function TEleicaoMembroFotoAPIService.BuscarFoto(const ASlug: string; const AIdMembro: Integer): TEleicaoMembroFotoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := Default(TEleicaoMembroFotoResult);

  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if AIdMembro <= 0 then
    TAppErrors.RaiseBadRequest('Membro não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoMembroFotoAPIDao.BuscarFoto(Conn, Trim(ASlug), AIdMembro, Result.Arquivo, Result.Extensao) then
      TAppErrors.RaiseNotFound('Foto não encontrada.');

    Result.ContentType := ObterContentType(Result.Extensao);
  finally
    Conn.Free;
  end;
end;

end.
