unit PublicoInstituicao.Service;

interface

uses
  PublicoInstituicao.Model;

type
  TPublicoInstituicaoService = class
  public
    class function BuscarPorSlug(const ASlug: string): TPublicoInstituicao; static;
    class function ListarCursosDisponiveis(
      const ASlug: string;
      const APagina, APorPagina: Integer
    ): TPublicoCursoLista; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PublicoInstituicao.DAO;

class function TPublicoInstituicaoService.BuscarPorSlug(
  const ASlug: string
): TPublicoInstituicao;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Slug := LowerCase(Trim(ASlug));
  if Slug = '' then
    TAppErrors.RaiseBadRequest('Instituição não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPublicoInstituicaoDAO.BuscarPorSlug(Conn, Slug);
    if Result = nil then
      TAppErrors.RaiseBadRequest('Instituição não encontrada ou indisponível.');
  finally
    Conn.Free;
  end;
end;

class function TPublicoInstituicaoService.ListarCursosDisponiveis(
  const ASlug: string;
  const APagina, APorPagina: Integer
): TPublicoCursoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Instituicao: TPublicoInstituicao;
  Pagina, PorPagina: Integer;
begin
  Pagina := APagina;
  PorPagina := APorPagina;
  if Pagina <= 0 then Pagina := 1;
  if PorPagina <= 0 then PorPagina := 6;
  if PorPagina > 24 then PorPagina := 24;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Instituicao := TPublicoInstituicaoDAO.BuscarPorSlug(Conn, LowerCase(Trim(ASlug)));
    try
      if Instituicao = nil then
        TAppErrors.RaiseBadRequest('Instituição não encontrada ou indisponível.');

      Result := TPublicoInstituicaoDAO.ListarCursosDisponiveis(
        Conn,
        Instituicao.Id,
        Pagina,
        PorPagina
      );
    finally
      Instituicao.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
