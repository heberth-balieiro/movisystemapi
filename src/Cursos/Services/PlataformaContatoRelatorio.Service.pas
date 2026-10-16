unit PlataformaContatoRelatorio.Service;

interface

uses
  PlataformaContatoRelatorio.Model;

type
  TPlataformaContatoRelatorioService = class
  private
    class procedure NormalizarFiltro(
      var AFiltro: TPlataformaContatoRelatorioFiltro
    ); static;
  public
    class function Listar(
      const AIdUsuario: Int64;
      const AFiltro: TPlataformaContatoRelatorioFiltro;
      const AIP, AUserAgent: string
    ): TPlataformaContatoRelatorioResultado; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaContato.DAO,
  PlataformaContatoRelatorio.DAO;

class procedure TPlataformaContatoRelatorioService.NormalizarFiltro(
  var AFiltro: TPlataformaContatoRelatorioFiltro
);
begin
  AFiltro.Tipo := UpperCase(Trim(AFiltro.Tipo));
  AFiltro.UF := UpperCase(Trim(AFiltro.UF));
  AFiltro.Municipio := Trim(AFiltro.Municipio);
  AFiltro.Partido := UpperCase(Trim(AFiltro.Partido));
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));

  if not MatchText(AFiltro.Tipo, [
    'CAMARA',
    'PREFEITURA',
    'SINDICATO',
    'ASSOCIACAO',
    'VEREADOR',
    'DEPUTADO_ESTADUAL',
    'DEPUTADO_FEDERAL',
    'SENADOR',
    'UNALE_ASSOCIADO'
  ]) then
    TAppErrors.RaiseBadRequest('Tipo de relatório inválido.');

  if (not AFiltro.UF.IsEmpty) and (Length(AFiltro.UF) <> 2) then
    TAppErrors.RaiseBadRequest('UF inválida.');

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(AFiltro.Situacao, ['ATIVO', 'INATIVO']) then
      TAppErrors.RaiseBadRequest('Situação inválida.');

  if (AFiltro.EmExercicio <> -1) and
     (AFiltro.EmExercicio <> 0) and
     (AFiltro.EmExercicio <> 1) then
    AFiltro.EmExercicio := -1;

  if (AFiltro.TemEmail <> -1) and
     (AFiltro.TemEmail <> 0) and
     (AFiltro.TemEmail <> 1) then
    AFiltro.TemEmail := -1;
end;

class function TPlataformaContatoRelatorioService.Listar(
  const AIdUsuario: Int64;
  const AFiltro: TPlataformaContatoRelatorioFiltro;
  const AIP, AUserAgent: string
): TPlataformaContatoRelatorioResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TPlataformaContatoRelatorioFiltro;
begin
  Result := nil;

  if AIdUsuario <= 0 then
    TAppErrors.RaiseForbidden('Usuário não identificado.');

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaContatoRelatorioDAO.Listar(Conn, Filtro);

    TPlataformaContatoDAO.RegistrarAuditoria(
      Conn,
      AIdUsuario,
      'RELATORIO_CONTATOS_GERADO',
      'plataforma_contato',
      '',
      'Relatório analítico gerado: ' + Filtro.Tipo,
      AIP,
      AUserAgent
    );
  finally
    Conn.Free;
  end;
end;

end.
