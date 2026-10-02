unit InstituicaoRelatorioCertificado.Service;

interface

uses
  InstituicaoRelatorioCertificado.Model;

type
  TInstituicaoRelatorioCertificadoService = class
  private
    class procedure NormalizarFiltro(
      var AFiltro: TRelatorioCertificadoFiltro
    ); static;

    class function CsvCampo(
      const AValor: string
    ): string; static;
  public
    class function ListarFiltros(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TRelatorioCertificadoFiltros; static;

    class function Listar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioCertificadoFiltro
    ): TRelatorioCertificadoResultado; static;

    class function ExportarCsv(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const AFiltro: TRelatorioCertificadoFiltro
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoRelatorioCertificado.DAO;

class procedure TInstituicaoRelatorioCertificadoService.NormalizarFiltro(
  var AFiltro: TRelatorioCertificadoFiltro
);
begin
  AFiltro.Busca := Trim(AFiltro.Busca);
  AFiltro.Situacao := UpperCase(Trim(AFiltro.Situacao));
  AFiltro.TipoTurma := UpperCase(Trim(AFiltro.TipoTurma));

  if not AFiltro.Situacao.IsEmpty then
    if not MatchText(
      AFiltro.Situacao,
      ['PENDENTE', 'VALIDO', 'CANCELADO', 'ERRO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Situação do certificado inválida.'
      );

  if not AFiltro.TipoTurma.IsEmpty then
    if not MatchText(
      AFiltro.TipoTurma,
      ['NORMAL', 'CERTIFICACAO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Tipo de turma inválido.'
      );

  if AFiltro.Pagina <= 0 then
    AFiltro.Pagina := 1;

  if AFiltro.PorPagina <= 0 then
    AFiltro.PorPagina := 25;

  if AFiltro.PorPagina > 100 then
    AFiltro.PorPagina := 100;

  if AFiltro.TemDataInicio and
     AFiltro.TemDataFim and
     (AFiltro.DataFim <= AFiltro.DataInicio) then
    TAppErrors.RaiseBadRequest(
      'A data final deve ser posterior à data inicial.'
    );
end;

class function TInstituicaoRelatorioCertificadoService.CsvCampo(
  const AValor: string
): string;
var
  S: string;
begin
  S := AValor;

  if (Length(S) > 0) and
     CharInSet(S[1], ['=', '+', '-', '@']) then
    S := '''' + S;

  S := StringReplace(
    S,
    '"',
    '""',
    [rfReplaceAll]
  );

  Result := '"' + S + '"';
end;

class function TInstituicaoRelatorioCertificadoService.ListarFiltros(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TRelatorioCertificadoFiltros;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.certificados.visualizar'
  );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      TInstituicaoRelatorioCertificadoDAO.ListarFiltros(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioCertificadoService.Listar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioCertificadoFiltro
): TRelatorioCertificadoResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioCertificadoFiltro;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.certificados.visualizar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      TInstituicaoRelatorioCertificadoDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoRelatorioCertificadoService.ExportarCsv(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const AFiltro: TRelatorioCertificadoFiltro
): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TRelatorioCertificadoFiltro;
  Lista: TObjectList<TRelatorioCertificadoItem>;
  Item: TRelatorioCertificadoItem;
  Csv: TStringBuilder;
  EmitidoEm, CanceladoEm: string;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'relatorio.certificados.exportar'
  );

  Filtro := AFiltro;
  NormalizarFiltro(Filtro);

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Lista :=
      TInstituicaoRelatorioCertificadoDAO.Exportar(
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
          'Numero;Participante;CPF;Curso;Turma;Tipo turma;Situacao;Versao;Reemitido;Emitido em;Cancelado em;Emitido por;Carga horaria'
        );

        for Item in Lista do
        begin
          EmitidoEm := '';
          if Item.TemEmitidoEm then
            EmitidoEm :=
              FormatDateTime(
                'dd/mm/yyyy hh:nn:ss',
                Item.EmitidoEm
              );

          CanceladoEm := '';
          if Item.TemCanceladoEm then
            CanceladoEm :=
              FormatDateTime(
                'dd/mm/yyyy hh:nn:ss',
                Item.CanceladoEm
              );

          Csv.Append(
            CsvCampo(Item.NumeroPublico) + ';' +
            CsvCampo(Item.ParticipanteNome) + ';' +
            CsvCampo(Item.CpfMascarado) + ';' +
            CsvCampo(Item.CursoNome) + ';' +
            CsvCampo(Item.TurmaNome) + ';' +
            CsvCampo(Item.TipoTurma) + ';' +
            CsvCampo(Item.Situacao) + ';' +
            Item.Versao.ToString + ';' +
            CsvCampo(IfThen(Item.Reemitido, 'SIM', 'NAO')) + ';' +
            CsvCampo(EmitidoEm) + ';' +
            CsvCampo(CanceladoEm) + ';' +
            CsvCampo(Item.EmitidoPorNome) + ';' +
            CsvCampo(
              FormatFloat(
                '0.##',
                Item.CargaHorariaMinutos / 60
              )
            )
          );

          Csv.AppendLine;
        end;

        Result :=
          #$FEFF + Csv.ToString;
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
