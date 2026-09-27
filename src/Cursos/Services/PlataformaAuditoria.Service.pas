unit PlataformaAuditoria.Service;

interface

uses
  PlataformaAuditoria.Model;

type
  TPlataformaAuditoriaService = class
  private
    class function TryParseDataISO(
      const AValue: string;
      out AData: TDateTime
    ): Boolean; static;
  public
    class function Listar(
      const ABusca, AAcao, ADataInicio, ADataFim: string;
      const APagina, APorPagina: Integer
    ): TPlataformaAuditoriaResultado; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaAuditoria.DAO;

class function TPlataformaAuditoriaService.TryParseDataISO(
  const AValue: string;
  out AData: TDateTime
): Boolean;
var
  Ano, Mes, Dia: Integer;
begin
  Result := False;

  if Length(Trim(AValue)) <> 10 then
    Exit;

  if (AValue[5] <> '-') or (AValue[8] <> '-') then
    Exit;

  if not TryStrToInt(Copy(AValue, 1, 4), Ano) then Exit;
  if not TryStrToInt(Copy(AValue, 6, 2), Mes) then Exit;
  if not TryStrToInt(Copy(AValue, 9, 2), Dia) then Exit;

  Result := TryEncodeDate(Ano, Mes, Dia, AData);
end;

class function TPlataformaAuditoriaService.Listar(
  const ABusca, AAcao, ADataInicio, ADataFim: string;
  const APagina, APorPagina: Integer
): TPlataformaAuditoriaResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TPlataformaAuditoriaFiltro;
begin
  Filtro := Default(TPlataformaAuditoriaFiltro);

  Filtro.Busca := Trim(ABusca);
  Filtro.Acao := UpperCase(Trim(AAcao));

  Filtro.Pagina := APagina;
  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina := APorPagina;
  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 50;

  // Evita consultas administrativas excessivamente grandes.
  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Trim(ADataInicio).IsEmpty then
  begin
    if not TryParseDataISO(ADataInicio, Filtro.DataInicio) then
      TAppErrors.RaiseBadRequest(
        'Data inicial inválida. Utilize o formato AAAA-MM-DD.'
      );

    Filtro.TemDataInicio := True;
  end;

  if not Trim(ADataFim).IsEmpty then
  begin
    if not TryParseDataISO(ADataFim, Filtro.DataFim) then
      TAppErrors.RaiseBadRequest(
        'Data final inválida. Utilize o formato AAAA-MM-DD.'
      );

    Filtro.TemDataFim := True;
  end;

  if Filtro.TemDataInicio and
     Filtro.TemDataFim and
     (Filtro.DataInicio > Filtro.DataFim) then
    TAppErrors.RaiseBadRequest(
      'A data inicial não pode ser maior que a data final.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaAuditoriaDAO.Listar(
      Conn,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

end.
