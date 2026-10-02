unit InstituicaoRelatorioTurma.Service;

interface

uses
  InstituicaoRelatorioTurma.Model;

type
  TInstituicaoRelatorioTurmaService = class
  private
    class procedure NormalizarFiltro(var AFiltro: TRelatorioTurmaFiltro); static;
    class function CsvCampo(const AValor: string): string; static;
  public
    class function ListarFiltros(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64): TRelatorioTurmaFiltros; static;

    class function Listar(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioTurmaFiltro): TRelatorioTurmaResultado; static;

    class function ExportarCsv(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioTurmaFiltro): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Generics.Collections,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoRelatorioTurma.DAO;

class procedure TInstituicaoRelatorioTurmaService.NormalizarFiltro(
  var AFiltro: TRelatorioTurmaFiltro);
begin
  AFiltro.Busca := Trim(AFiltro.Busca);
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));
  AFiltro.Modalidade := UpperCase(Trim(AFiltro.Modalidade));
  AFiltro.TipoTurma := UpperCase(Trim(AFiltro.TipoTurma));

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(AFiltro.Situacao,
      ['PLANEJADA', 'INSCRICOES_ABERTAS', 'EM_ANDAMENTO', 'ENCERRADA', 'CANCELADA']) then
      TAppErrors.RaiseBadRequest('Situação da turma inválida.');

  if not AFiltro.Modalidade.IsEmpty then
    if not MatchText(AFiltro.Modalidade, ['PRESENCIAL', 'ONLINE', 'HIBRIDO']) then
      TAppErrors.RaiseBadRequest('Modalidade inválida.');

  if not AFiltro.TipoTurma.IsEmpty then
    if not MatchText(AFiltro.TipoTurma, ['NORMAL', 'CERTIFICACAO']) then
      TAppErrors.RaiseBadRequest('Tipo de turma inválido.');

  if AFiltro.Pagina <= 0 then
    AFiltro.Pagina := 1;

  if AFiltro.PorPagina <= 0 then
    AFiltro.PorPagina := 25;

  if AFiltro.PorPagina > 100 then
    AFiltro.PorPagina := 100;

  if AFiltro.TemDataInicio and AFiltro.TemDataFim and
     (AFiltro.DataFim <= AFiltro.DataInicio) then
    TAppErrors.RaiseBadRequest('A data final deve ser posterior à data inicial.');
end;

class function TInstituicaoRelatorioTurmaService.CsvCampo(
  const AValor: string): string;
var
  S: string;
begin
  S := AValor;

  if (Length(S) > 0) and CharInSet(S[1], ['=', '+', '-', '@']) then
    S := '''' + S;

  S := StringReplace(S, '"', '""', [rfReplaceAll]);
  Result := '"' + S + '"';
end;

class function TInstituicaoRelatorioTurmaService.ListarFiltros(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64): TRelatorioTurmaFiltros;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.turmas.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioTurmaDAO.ListarFiltros(Conn, AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioTurmaService.Listar(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioTurmaFiltro): TRelatorioTurmaResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioTurmaFiltro;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.turmas.visualizar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioTurmaDAO.Listar(Conn, AIdInstituicao, Filtro);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioTurmaService.ExportarCsv(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioTurmaFiltro): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioTurmaFiltro;
  Lista: TObjectList<TRelatorioTurmaItem>;
  Item: TRelatorioTurmaItem;
  Csv: TStringBuilder;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.turmas.exportar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Lista := TInstituicaoRelatorioTurmaDAO.Exportar(Conn, AIdInstituicao, Filtro);
    try
      if Lista.Count > 50000 then
        TAppErrors.RaiseBadRequest(
          'A exportação excede 50.000 registros. Refine os filtros e tente novamente.'
        );

      Csv := TStringBuilder.Create;
      try
        Csv.AppendLine(
          'Curso;Turma;Modalidade;Tipo;Situacao;Inicio;Fim;Inscritos;Concluidos;Certificados'
        );

        for Item in Lista do
        begin
          Csv.Append(
            CsvCampo(Item.CursoNome) + ';' +
            CsvCampo(Item.TurmaNome) + ';' +
            CsvCampo(Item.Modalidade) + ';' +
            CsvCampo(Item.TipoTurma) + ';' +
            CsvCampo(Item.Situacao) + ';' +
            CsvCampo(FormatDateTime('dd/mm/yyyy hh:nn', Item.DataHoraInicio)) + ';' +
            CsvCampo(FormatDateTime('dd/mm/yyyy hh:nn', Item.DataHoraFim)) + ';' +
            Item.TotalInscritos.ToString + ';' +
            Item.TotalConcluidos.ToString + ';' +
            Item.TotalCertificados.ToString
          );
          Csv.AppendLine;
        end;

        Result := #$FEFF + Csv.ToString;
      finally
        Csv.Free;
      end;
    finally
      Lista.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
