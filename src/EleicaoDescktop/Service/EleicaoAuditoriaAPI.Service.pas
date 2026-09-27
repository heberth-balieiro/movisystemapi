unit EleicaoAuditoriaAPI.Service;

interface

uses
  Uni,EleicaoAuditoriaAPI.Dao,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoAdminAPI.Dao,
  System.DateUtils;

const
  // Origem
  AUDITORIA_ORIGEM_ELEITOR = 'ELEITOR';
  AUDITORIA_ORIGEM_ADMIN   = 'ADMIN';
  AUDITORIA_ORIGEM_SISTEMA = 'SISTEMA';

  // Eventos eleitor
  AUDITORIA_LOGIN_SUCESSO   = 'LOGIN_SUCESSO';
  AUDITORIA_LOGIN_FALHA     = 'LOGIN_FALHA';
  AUDITORIA_CODIGO_ENVIADO  = 'CODIGO_ENVIADO';
  AUDITORIA_CODIGO_VALIDADO = 'CODIGO_VALIDADO';
  AUDITORIA_CODIGO_INVALIDO = 'CODIGO_INVALIDO';
  AUDITORIA_VOTO_REGISTRADO = 'VOTO_REGISTRADO';

  // Eventos administrativos
  AUDITORIA_ELEICAO_ENCERRADA    = 'ELEICAO_ENCERRADA';
  AUDITORIA_APURACAO_INICIADA    = 'APURACAO_INICIADA';
  AUDITORIA_APURACAO_FINALIZADA  = 'APURACAO_FINALIZADA';
  AUDITORIA_RESULTADO_PUBLICADO  = 'RESULTADO_PUBLICADO';

type
  TEleicaoAuditoriaAPIService = class
  public
    class procedure RegistrarEvento(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer;
      const ATipoEvento: string;
      const AOrigem: string;
      const ASucesso: Boolean;
      const ADescricao: string;
      const AIP: string = '';
      const AUserAgent: string = ''
    ); static;

    class function BuscarAuditoria(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const ATipoEvento: string;
      const AOrigem: string;
      const ASucesso: string;
      const ADataInicial: string;
      const ADataFinal: string
    ): TEleicaoAuditoriaLista; static;
  end;

implementation

uses
  System.SysUtils;

{ TEleicaoAuditoriaAPIService }

class procedure TEleicaoAuditoriaAPIService.RegistrarEvento(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer;
  const ATipoEvento: string;
  const AOrigem: string;
  const ASucesso: Boolean;
  const ADescricao: string;
  const AIP: string;
  const AUserAgent: string
);
var
  Sucesso: string;
begin
  if AIdEmpresa <= 0 then
    Exit;

  if AIdEleicao <= 0 then
    Exit;

  if Trim(ATipoEvento).IsEmpty then
    Exit;

  if Trim(AOrigem).IsEmpty then
    Exit;

  if ASucesso then
    Sucesso := 'S'
  else
    Sucesso := 'N';

  TEleicaoAuditoriaAPIDao.RegistrarEvento(
    AConn,
    AIdEmpresa,
    AIdEleicao,
    AIdUsuario,
    ATipoEvento,
    AOrigem,
    Sucesso,
    ADescricao,
    AIP,
    AUserAgent
  );
end;


class function TEleicaoAuditoriaAPIService.BuscarAuditoria(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const ATipoEvento: string;
  const AOrigem: string;
  const ASucesso: string;
  const ADataInicial: string;
  const ADataFinal: string
): TEleicaoAuditoriaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
  Filtro: TEleicaoAuditoriaFiltro;
  DataTemp: TDateTime;
begin
  Result := TEleicaoAuditoriaLista.Create;

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleição não informada.');

    if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
        TAppErrors.RaiseNotFound('Eleição não encontrada.');

      Filtro := Default(TEleicaoAuditoriaFiltro);

      Filtro.TipoEvento := UpperCase(Trim(ATipoEvento));
      Filtro.Origem := UpperCase(Trim(AOrigem));
      Filtro.Sucesso := UpperCase(Trim(ASucesso));

      if (Filtro.Origem <> '') and
       (Filtro.Origem <> 'ELEITOR') and
       (Filtro.Origem <> 'ADMIN') and
       (Filtro.Origem <> 'SISTEMA') then
      TAppErrors.RaiseBadRequest('Origem inválida.');

      if (Filtro.Sucesso <> '') and
       (Filtro.Sucesso <> 'S') and
       (Filtro.Sucesso <> 'N') then
      TAppErrors.RaiseBadRequest('Status de sucesso inválido.');

      if not Trim(ADataInicial).IsEmpty then
      begin
        if not TryISO8601ToDate(Trim(ADataInicial), DataTemp, False) then
          TAppErrors.RaiseBadRequest('Data inicial inválida.');

        Filtro.DataInicial := StartOfTheDay(DataTemp);
        Filtro.TemDataInicial := True;
      end;

      if not Trim(ADataFinal).IsEmpty then
      begin
        if not TryISO8601ToDate(Trim(ADataFinal), DataTemp, False) then
          TAppErrors.RaiseBadRequest('Data final inválida.');

        Filtro.DataFinal := EndOfTheDay(DataTemp);
        Filtro.TemDataFinal := True;
      end;

      if Filtro.TemDataInicial and Filtro.TemDataFinal then
      if Filtro.DataFinal < Filtro.DataInicial then
        TAppErrors.RaiseBadRequest('Data final não pode ser menor que a data inicial.');

      TEleicaoAuditoriaAPIDao.BuscarAuditoria(Conn, AIdEmpresa, Eleicao.IdEleicao, Filtro, Result);

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
