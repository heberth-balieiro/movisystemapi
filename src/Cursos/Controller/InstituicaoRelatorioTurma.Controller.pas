unit InstituicaoRelatorioTurma.Controller;

interface

type
  TInstituicaoRelatorioTurmaController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoRelatorioTurma.Model,
  InstituicaoRelatorioTurma.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(Res, 'Token sem contexto válido da instituição.');
    Exit;
  end;

  Result := True;
end;

function ParseData(const AValor, ACampo: string; out AData: TDateTime): Boolean;
var
  S: string;
begin
  Result := False;
  S := Trim(AValor);
  if S.IsEmpty then
    Exit;

  if not TryISO8601ToDate(S, AData, False) then
    TAppErrors.RaiseBadRequest('Data inválida em ' + ACampo + '. Use yyyy-mm-dd.');

  Result := True;
end;

function LerFiltro(const Req: THorseRequest): TRelatorioTurmaFiltro;
begin
  Result := Default(TRelatorioTurmaFiltro);
  Result.Busca := Req.Query.Items['busca'];
  Result.Situacao := Req.Query.Items['situacao'];
  Result.Modalidade := Req.Query.Items['modalidade'];
  Result.TipoTurma := Req.Query.Items['tipo_turma'];
  Result.IdCurso := StrToInt64Def(Req.Query.Items['id_curso'], 0);

  Result.TemDataInicio := ParseData(
    Req.Query.Items['data_inicio'], 'data_inicio', Result.DataInicio);

  Result.TemDataFim := ParseData(
    Req.Query.Items['data_fim'], 'data_fim', Result.DataFim);

  if Result.TemDataFim then
    Result.DataFim := IncDay(Result.DataFim, 1);

  Result.Pagina := StrToIntDef(Req.Query.Items['page'], 1);
  Result.PorPagina := StrToIntDef(Req.Query.Items['page_size'], 25);
end;

function ItemParaJson(const AItem: TRelatorioTurmaItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('id_curso', TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('modalidade', AItem.Modalidade);
  Result.AddPair('tipo_turma', AItem.TipoTurma);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('data_hora_inicio',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.DataHoraInicio));
  Result.AddPair('data_hora_fim',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.DataHoraFim));
  Result.AddPair('total_inscritos', TJSONNumber.Create(AItem.TotalInscritos));
  Result.AddPair('total_concluidos', TJSONNumber.Create(AItem.TotalConcluidos));
  Result.AddPair('total_certificados', TJSONNumber.Create(AItem.TotalCertificados));
end;

class procedure TInstituicaoRelatorioTurmaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/relatorios/turmas/filtros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtros: TRelatorioTurmaFiltros;
      Item: TRelatorioTurmaFiltroOpcao;
      Dados, JsonItem: TJSONObject;
      Cursos: TJSONArray;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtros := TInstituicaoRelatorioTurmaService.ListarFiltros(
          Claims.IdInstituicao, Claims.IdUsuarioInstituicao);
        try
          Cursos := TJSONArray.Create;
          for Item in Filtros.Cursos do
          begin
            JsonItem := TJSONObject.Create;
            JsonItem.AddPair('id', TJSONNumber.Create(Item.Id));
            JsonItem.AddPair('nome', Item.Nome);
            Cursos.AddElement(JsonItem);
          end;

          Dados := TJSONObject.Create;
          Dados.AddPair('cursos', Cursos);
          TAppResponse.Ok(Res, Dados, 'Filtros do relatório carregados com sucesso.');
        finally
          Filtros.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/turmas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioTurmaFiltro;
      Resultado: TRelatorioTurmaResultado;
      Item: TRelatorioTurmaItem;
      Dados, Resumo, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Resultado := TInstituicaoRelatorioTurmaService.Listar(
          Claims.IdInstituicao, Claims.IdUsuarioInstituicao, Filtro);
        try
          Itens := TJSONArray.Create;
          for Item in Resultado.Itens do
            Itens.AddElement(ItemParaJson(Item));

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_turmas', TJSONNumber.Create(Resultado.Resumo.TotalTurmas));
          Resumo.AddPair('inscricoes_abertas', TJSONNumber.Create(Resultado.Resumo.InscricoesAbertas));
          Resumo.AddPair('em_andamento', TJSONNumber.Create(Resultado.Resumo.EmAndamento));
          Resumo.AddPair('encerradas', TJSONNumber.Create(Resultado.Resumo.Encerradas));
          Resumo.AddPair('participantes', TJSONNumber.Create(Resultado.Resumo.Participantes));
          Resumo.AddPair('certificados_emitidos', TJSONNumber.Create(Resultado.Resumo.CertificadosEmitidos));

          if Resultado.Total = 0 then TotalPaginas := 0
          else TotalPaginas := (Resultado.Total + Resultado.PorPagina - 1) div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Resultado.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Resultado.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Resultado.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('resumo', Resumo);
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Relatório de turmas carregado com sucesso.');
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/turmas/exportar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioTurmaFiltro;
      Csv: string;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Csv := TInstituicaoRelatorioTurmaService.ExportarCsv(
          Claims.IdInstituicao, Claims.IdUsuarioInstituicao, Filtro);

        Res.RawWebResponse.ContentType := 'text/csv; charset=utf-8';
        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition', 'attachment; filename="relatorio-turmas.csv"');
        Res.Send(Csv);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
