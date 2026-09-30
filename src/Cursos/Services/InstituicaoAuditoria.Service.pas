unit InstituicaoAuditoria.Service;

interface

uses
  InstituicaoAuditoria.Model;

type
  TInstituicaoAuditoriaService = class
  private
    class function TryParseDataISO(
      const AValue: string;
      out AData: TDateTime
    ): Boolean; static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            AAcao,
            AEntidade,
            ASucesso,
            ADataInicio,
            ADataFim: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoAuditoriaResultado; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoAuditoria.DAO;

class function TInstituicaoAuditoriaService.TryParseDataISO(
  const AValue: string;
  out AData: TDateTime
): Boolean;
var
  Ano, Mes, Dia: Integer;
  Valor: string;
begin
  Result := False;
  Valor := Trim(AValue);

  if Length(Valor) <> 10 then
    Exit;

  if (Valor[5] <> '-') or (Valor[8] <> '-') then
    Exit;

  if not TryStrToInt(Copy(Valor, 1, 4), Ano) then Exit;
  if not TryStrToInt(Copy(Valor, 6, 2), Mes) then Exit;
  if not TryStrToInt(Copy(Valor, 9, 2), Dia) then Exit;

  Result := TryEncodeDate(Ano, Mes, Dia, AData);
end;

class function TInstituicaoAuditoriaService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        AAcao,
        AEntidade,
        ASucesso,
        ADataInicio,
        ADataFim: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoAuditoriaResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoAuditoriaFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro := Default(TInstituicaoAuditoriaFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Acao := UpperCase(Trim(AAcao));
  Filtro.Entidade := LowerCase(Trim(AEntidade));

  if not Trim(ASucesso).IsEmpty then
  begin
    if SameText(Trim(ASucesso), 'S') or
       SameText(Trim(ASucesso), 'TRUE') or
       SameText(Trim(ASucesso), '1') then
    begin
      Filtro.TemSucesso := True;
      Filtro.Sucesso := True;
    end
    else if SameText(Trim(ASucesso), 'N') or
            SameText(Trim(ASucesso), 'FALSE') or
            SameText(Trim(ASucesso), '0') then
    begin
      Filtro.TemSucesso := True;
      Filtro.Sucesso := False;
    end
    else
      TAppErrors.RaiseBadRequest(
        'Filtro de resultado inválido. Utilize S ou N.'
      );
  end;

  Filtro.Pagina := APagina;
  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina := APorPagina;
  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 50;

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

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Result :=
      TInstituicaoAuditoriaDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

end.
