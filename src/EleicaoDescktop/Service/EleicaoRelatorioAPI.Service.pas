unit EleicaoRelatorioAPI.Service;

interface

uses
  EleicaoRelatorioAPI.Dao;

type
  TEleicaoRelatorioAPIService = class
  public
    class function BuscarEleitores(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const ASituacao: string
    ): TEleicaoRelatorioListaEleitores; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoAdminAPI.Dao;

{ TEleicaoRelatorioAPIService }

class function TEleicaoRelatorioAPIService.BuscarEleitores(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const ASituacao: string
): TEleicaoRelatorioListaEleitores;
var
  Config  : TAppApiConfig;
  Conn    : TUniConnection;
  Eleicao : TEleicaoAdminDados;
  Situacao: string;
begin
  Result := TEleicaoRelatorioListaEleitores.Create;

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleição não informada.');

    if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

    Situacao := UpperCase(Trim(ASituacao));

    if Situacao.IsEmpty then
      Situacao := 'TODOS';

    if (Situacao <> 'TODOS') and
       (Situacao <> 'VOTARAM') and
       (Situacao <> 'NAO_VOTARAM') then
      TAppErrors.RaiseBadRequest('Situação de eleitor inválida.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
        TAppErrors.RaiseNotFound('Eleição não encontrada.');

      TEleicaoRelatorioAPIDao.BuscarEleitores(
        Conn,
        AIdEmpresa,
        Eleicao.IdEleicao,
        Situacao,
        Result
      );

    finally
      Conn.Free;
    end;

  except
    Result.Free;
    Result := nil;
    raise;
  end;
end;

end.
