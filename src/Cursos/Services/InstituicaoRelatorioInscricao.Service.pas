unit InstituicaoRelatorioInscricao.Service;

interface

uses
  InstituicaoRelatorioInscricao.Model;

type
  TInstituicaoRelatorioInscricaoService = class
  private
    class procedure NormalizarFiltro(var AFiltro: TRelatorioInscricaoFiltro); static;
    class function CsvCampo(const AValor: string): string; static;
  public
    class function ListarFiltros(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64): TRelatorioInscricaoFiltros; static;

    class function Listar(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioInscricaoFiltro): TRelatorioInscricaoResultado; static;

    class function ExportarCsv(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioInscricaoFiltro): string; static;
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
  InstituicaoRelatorioInscricao.DAO;

class procedure TInstituicaoRelatorioInscricaoService.NormalizarFiltro(
  var AFiltro: TRelatorioInscricaoFiltro);
begin
  AFiltro.Busca := Trim(AFiltro.Busca);
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));
  AFiltro.Origem := UpperCase(Trim(AFiltro.Origem));

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(
      AFiltro.Situacao,
      ['INSCRITO', 'CONFIRMADO', 'EM_ANDAMENTO', 'CONCLUIDO',
       'CANCELADO', 'REPROVADO', 'DESISTENTE']
    ) then
      TAppErrors.RaiseBadRequest('Situação da inscrição inválida.');

  if not AFiltro.Origem.IsEmpty then
    if not MatchText(
      AFiltro.Origem,
      ['PUBLICA', 'ADMIN', 'IMPORTACAO', 'API']
    ) then
      TAppErrors.RaiseBadRequest('Origem da inscrição inválida.');

  if AFiltro.Pagina <= 0 then
    AFiltro.Pagina := 1;

  if AFiltro.PorPagina <= 0 then
    AFiltro.PorPagina := 25;

  if AFiltro.PorPagina > 100 then
    AFiltro.PorPagina := 100;

  if AFiltro.TemDataInscricaoInicio and AFiltro.TemDataInscricaoFim and
     (AFiltro.DataInscricaoFim <= AFiltro.DataInscricaoInicio) then
    TAppErrors.RaiseBadRequest('O período de inscrição é inválido.');

  if AFiltro.TemDataConclusaoInicio and AFiltro.TemDataConclusaoFim and
     (AFiltro.DataConclusaoFim <= AFiltro.DataConclusaoInicio) then
    TAppErrors.RaiseBadRequest('O período de conclusão é inválido.');
end;

class function TInstituicaoRelatorioInscricaoService.CsvCampo(
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

class function TInstituicaoRelatorioInscricaoService.ListarFiltros(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64): TRelatorioInscricaoFiltros;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.inscricoes.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioInscricaoDAO.ListarFiltros(
      Conn,
      AIdInstituicao
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioInscricaoService.Listar(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioInscricaoFiltro): TRelatorioInscricaoResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioInscricaoFiltro;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.inscricoes.visualizar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioInscricaoDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioInscricaoService.ExportarCsv(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioInscricaoFiltro): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioInscricaoFiltro;
  Lista: TObjectList<TRelatorioInscricaoItem>;
  Item: TRelatorioInscricaoItem;
  Csv: TStringBuilder;
  ConcluidoEm, Presenca: string;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.inscricoes.exportar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Lista := TInstituicaoRelatorioInscricaoDAO.Exportar(
      Conn,
      AIdInstituicao,
      Filtro
    );
    try
      if Lista.Count > 50000 then
        TAppErrors.RaiseBadRequest(
          'A exportação excede 50.000 registros. Refine os filtros e tente novamente.'
        );

      Csv := TStringBuilder.Create;
      try
        Csv.AppendLine(
          'Participante;CPF;Curso;Turma;Tipo turma;Origem;Situacao;Inscrito em;Conclusao;Presenca;Elegivel certificado;Certificado emitido'
        );

        for Item in Lista do
        begin
          ConcluidoEm := '';
          if Item.TemConcluidoEm then
            ConcluidoEm := FormatDateTime('dd/mm/yyyy hh:nn:ss', Item.ConcluidoEm);

          if SameText(Item.TipoTurma, 'CERTIFICACAO') then
            Presenca := 'NAO APLICAVEL'
          else if Item.TemPercentualPresenca then
            Presenca := FormatFloat('0.##', Item.PercentualPresenca) + '%'
          else
            Presenca := '';

          Csv.Append(
            CsvCampo(Item.ParticipanteNome) + ';' +
            CsvCampo(Item.CpfMascarado) + ';' +
            CsvCampo(Item.CursoNome) + ';' +
            CsvCampo(Item.TurmaNome) + ';' +
            CsvCampo(Item.TipoTurma) + ';' +
            CsvCampo(Item.Origem) + ';' +
            CsvCampo(Item.Situacao) + ';' +
            CsvCampo(FormatDateTime('dd/mm/yyyy hh:nn:ss', Item.InscritoEm)) + ';' +
            CsvCampo(ConcluidoEm) + ';' +
            CsvCampo(Presenca) + ';' +
            CsvCampo(IfThen(Item.ElegivelCertificado, 'SIM', 'NAO')) + ';' +
            CsvCampo(IfThen(Item.CertificadoEmitido, 'SIM', 'NAO'))
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
