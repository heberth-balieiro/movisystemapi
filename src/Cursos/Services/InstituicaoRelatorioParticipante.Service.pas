unit InstituicaoRelatorioParticipante.Service;

interface

uses
  InstituicaoRelatorioParticipante.Model;

type
  TInstituicaoRelatorioParticipanteService = class
  private
    class procedure NormalizarFiltro(var AFiltro: TRelatorioParticipanteFiltro); static;
    class function CsvCampo(const AValor: string): string; static;
  public
    class function ListarFiltros(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64): TRelatorioParticipanteFiltros; static;

    class function Listar(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioParticipanteFiltro): TRelatorioParticipanteResultado; static;

    class function ExportarCsv(const AIdInstituicao,
      AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioParticipanteFiltro): string; static;
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
  InstituicaoRelatorioParticipante.DAO;

class procedure TInstituicaoRelatorioParticipanteService.NormalizarFiltro(
  var AFiltro: TRelatorioParticipanteFiltro);
var
  BuscaCpf: string;
begin
  AFiltro.Busca := Trim(AFiltro.Busca);
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(AFiltro.Situacao, ['ATIVO', 'INATIVO', 'ANONIMIZADO']) then
      TAppErrors.RaiseBadRequest('Situação do participante inválida.');

  AFiltro.CpfHashBusca := '';
  BuscaCpf := TParticipanteSecurity.NormalizarCpf(AFiltro.Busca);

  if Length(BuscaCpf) = 11 then
    if TParticipanteSecurity.CpfValido(BuscaCpf) then
      AFiltro.CpfHashBusca :=
        TParticipanteSecurity.GerarCpfHashBusca(BuscaCpf);

  if AFiltro.Pagina <= 0 then
    AFiltro.Pagina := 1;

  if AFiltro.PorPagina <= 0 then
    AFiltro.PorPagina := 25;

  if AFiltro.PorPagina > 100 then
    AFiltro.PorPagina := 100;
end;

class function TInstituicaoRelatorioParticipanteService.CsvCampo(
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

class function TInstituicaoRelatorioParticipanteService.ListarFiltros(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64): TRelatorioParticipanteFiltros;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.participantes.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioParticipanteDAO.ListarFiltros(
      Conn,
      AIdInstituicao
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioParticipanteService.Listar(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioParticipanteFiltro): TRelatorioParticipanteResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioParticipanteFiltro;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.participantes.visualizar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoRelatorioParticipanteDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioParticipanteService.ExportarCsv(
  const AIdInstituicao, AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioParticipanteFiltro): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioParticipanteFiltro;
  Lista: TObjectList<TRelatorioParticipanteItem>;
  Item: TRelatorioParticipanteItem;
  Csv: TStringBuilder;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.participantes.exportar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Lista := TInstituicaoRelatorioParticipanteDAO.Exportar(
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
          'Nome;CPF;Email;Telefone;Situacao;Inscricoes;Conclusoes;Certificados'
        );

        for Item in Lista do
        begin
          Csv.Append(
            CsvCampo(Item.Nome) + ';' +
            CsvCampo(Item.CpfMascarado) + ';' +
            CsvCampo(Item.Email) + ';' +
            CsvCampo(Item.Telefone) + ';' +
            CsvCampo(Item.Situacao) + ';' +
            Item.TotalInscricoes.ToString + ';' +
            Item.TotalConclusoes.ToString + ';' +
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
