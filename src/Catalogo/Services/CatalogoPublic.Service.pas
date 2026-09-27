unit CatalogoPublic.Service;

interface

uses
  System.JSON;

type
  TCatalogoPublicService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;
  public
    class function BuscarCatalogoPublico(const ASlug: string): TJSONObject; static;
    class function BuscarCatalogoPublicoProduto(const ASlug: string;IDProduto: Int64): TJSONObject; static;
    class function BuscarCatalogoPublicoDestaque(const ASlug: string): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  CatalogoPublic.DAO;

class function TCatalogoPublicService.NormalizarSlug(const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));

  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  if S.StartsWith('-') then
    Delete(S, 1, 1);

  if S.EndsWith('-') then
    Delete(S, Length(S), 1);

  Result := S;
end;

class function TCatalogoPublicService.BuscarCatalogoPublico(const ASlug: string): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Result := nil;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result    := TCatalogoPublicDAO.BuscarCatalogoPorSlug(Conn, Slug);

    if Result = nil then
      TAppErrors.RaiseNotFound('Catálogo não encontrado ou indisponível.');
  finally
    Conn.Free;
  end;
end;

class function TCatalogoPublicService.BuscarCatalogoPublicoProduto(const ASlug: string; IDProduto: Int64): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Result := nil;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  if IDProduto <= 0 then
    TAppErrors.RaiseBadRequest('ID do produto não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCatalogoPublicDAO.BuscarCatalogoPorSlugProduto(Conn, Slug, IDProduto);

    if Result = nil then
      TAppErrors.RaiseNotFound('Catálogo não encontrado ou indisponível.');
  finally
    Conn.Free;
  end;
end;

class function TCatalogoPublicService.BuscarCatalogoPublicoDestaque(const ASlug: string): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Result := nil;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCatalogoPublicDAO.BuscarCatalogoPorSlugDestaque(Conn, Slug);

    if Result = nil then
      TAppErrors.RaiseNotFound('Catálogo não encontrado ou indisponível.');
  finally
    Conn.Free;
  end;
end;

end.
