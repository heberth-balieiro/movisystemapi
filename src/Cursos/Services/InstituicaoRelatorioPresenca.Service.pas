unit InstituicaoRelatorioPresenca.Service;

interface

uses
  InstituicaoRelatorioPresenca.Model;

type
  TInstituicaoRelatorioPresencaService = class
  private
    class procedure NormalizarFiltro(var AFiltro: TRelatorioPresencaFiltro); static;
    class function CsvCampo(const AValor: string): string; static;
  public
    class function ListarFiltros(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64): TRelatorioPresencaFiltros; static;

    class function Listar(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioPresencaFiltro): TRelatorioPresencaResultado; static;

    class function ExportarCsv(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioPresencaFiltro): string; static;
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
  App.ParticipanteSecurity,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoRelatorioPresenca.DAO;

class procedure TInstituicaoRelatorioPresencaService.NormalizarFiltro(
  var AFiltro: TRelatorioPresencaFiltro);
var
  BuscaCpf: string;
begin
  AFiltro.Busca := Trim(AFiltro.Busca);
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));
  AFiltro.Origem := UpperCase(Trim(AFiltro.Origem));
  AFiltro.ControlePresenca := UpperCase(Trim(AFiltro.ControlePresenca));

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(AFiltro.Situacao,
      ['PRESENTE','AUSENTE','JUSTIFICADA','PARCIAL','SEM_REGISTRO']) then
      TAppErrors.RaiseBadRequest('Situação de presença inválida.');

  if not AFiltro.Origem.IsEmpty then
    if not MatchText(AFiltro.Origem,
      ['AUTO_CHECKIN','QR_EQUIPE','MANUAL','LEGADO','SEM_REGISTRO']) then
      TAppErrors.RaiseBadRequest('Origem da presença inválida.');

  if not AFiltro.ControlePresenca.IsEmpty then
    if not MatchText(AFiltro.ControlePresenca,['ENCONTRO','TURMA']) then
      TAppErrors.RaiseBadRequest('Tipo de controle de presença inválido.');

  AFiltro.CpfHashBusca := '';
  BuscaCpf := TParticipanteSecurity.NormalizarCpf(AFiltro.Busca);

  if Length(BuscaCpf)=11 then
    if TParticipanteSecurity.CpfValido(BuscaCpf) then
      AFiltro.CpfHashBusca := TParticipanteSecurity.GerarCpfHashBusca(BuscaCpf);

  if AFiltro.Pagina<=0 then AFiltro.Pagina := 1;
  if AFiltro.PorPagina<=0 then AFiltro.PorPagina := 25;
  if AFiltro.PorPagina>100 then AFiltro.PorPagina := 100;

  if AFiltro.TemDataInicio and AFiltro.TemDataFim and
     (AFiltro.DataFim<=AFiltro.DataInicio) then
    TAppErrors.RaiseBadRequest('O período informado é inválido.');
end;

class function TInstituicaoRelatorioPresencaService.CsvCampo(
  const AValor: string): string;
var
  S: string;
begin
  S := AValor;

  if (Length(S)>0) and CharInSet(S[1],['=','+','-','@']) then
    S := '''' + S;

  S := StringReplace(S,'"','""',[rfReplaceAll]);
  Result := '"' + S + '"';
end;

class function TInstituicaoRelatorioPresencaService.ListarFiltros(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64): TRelatorioPresencaFiltros;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.presencas.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioPresencaDAO.ListarFiltros(Conn,AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioPresencaService.Listar(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioPresencaFiltro): TRelatorioPresencaResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioPresencaFiltro;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.presencas.visualizar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioPresencaDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioPresencaService.ExportarCsv(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioPresencaFiltro): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioPresencaFiltro;
  Lista: TObjectList<TRelatorioPresencaItem>;
  Item: TRelatorioPresencaItem;
  Csv: TStringBuilder;
  Checkin, Encontro, Minutos: string;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.presencas.exportar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Lista := TInstituicaoRelatorioPresencaDAO.Exportar(
      Conn,
      AIdInstituicao,
      Filtro
    );
    try
      if Lista.Count>50000 then
        TAppErrors.RaiseBadRequest(
          'A exportação excede 50.000 registros. Refine os filtros e tente novamente.'
        );

      Csv := TStringBuilder.Create;
      try
        Csv.AppendLine(
          'Participante;CPF;Curso;Turma;Controle;Encontro;Data referencia;Situacao;Origem;Check-in;Minutos;Registrado por;Justificativa'
        );

        for Item in Lista do
        begin
          Checkin := '';
          if Item.TemCheckinEm then
            Checkin := FormatDateTime('dd/mm/yyyy hh:nn:ss',Item.CheckinEm);

          Encontro := '';
          if Item.TemEncontro then
            Encontro := Item.EncontroTitulo;

          Minutos := '';
          if Item.TemMinutosPresentes then
            Minutos := Item.MinutosPresentes.ToString;

          Csv.Append(
            CsvCampo(Item.ParticipanteNome) + ';' +
            CsvCampo(Item.CpfMascarado) + ';' +
            CsvCampo(Item.CursoNome) + ';' +
            CsvCampo(Item.TurmaNome) + ';' +
            CsvCampo(Item.ControlePresenca) + ';' +
            CsvCampo(Encontro) + ';' +
            CsvCampo(FormatDateTime('dd/mm/yyyy hh:nn:ss',Item.DataReferencia)) + ';' +
            CsvCampo(Item.Situacao) + ';' +
            CsvCampo(Item.Origem) + ';' +
            CsvCampo(Checkin) + ';' +
            CsvCampo(Minutos) + ';' +
            CsvCampo(Item.RegistradoPorNome) + ';' +
            CsvCampo(Item.Justificativa)
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
