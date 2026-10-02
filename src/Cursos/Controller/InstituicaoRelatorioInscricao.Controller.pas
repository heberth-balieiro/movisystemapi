unit InstituicaoRelatorioInscricao.Controller;

interface

type
  TInstituicaoRelatorioInscricaoController = class
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
  InstituicaoRelatorioInscricao.Model,
  InstituicaoRelatorioInscricao.Service;

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

function LerFiltro(const Req: THorseRequest): TRelatorioInscricaoFiltro;
begin
  Result := Default(TRelatorioInscricaoFiltro);
  Result.Busca := Req.Query.Items['busca'];
  Result.Situacao := Req.Query.Items['situacao'];
  Result.Origem := Req.Query.Items['origem'];
  Result.IdCurso := StrToInt64Def(Req.Query.Items['id_curso'], 0);
  Result.IdTurma := StrToInt64Def(Req.Query.Items['id_turma'], 0);

  Result.TemDataInscricaoInicio := ParseData(
    Req.Query.Items['inscricao_inicio'],
    'inscricao_inicio',
    Result.DataInscricaoInicio
  );

  Result.TemDataInscricaoFim := ParseData(
    Req.Query.Items['inscricao_fim'],
    'inscricao_fim',
    Result.DataInscricaoFim
  );

  if Result.TemDataInscricaoFim then
    Result.DataInscricaoFim := IncDay(Result.DataInscricaoFim, 1);

  Result.TemDataConclusaoInicio := ParseData(
    Req.Query.Items['conclusao_inicio'],
    'conclusao_inicio',
    Result.DataConclusaoInicio
  );

  Result.TemDataConclusaoFim := ParseData(
    Req.Query.Items['conclusao_fim'],
    'conclusao_fim',
    Result.DataConclusaoFim
  );

  if Result.TemDataConclusaoFim then
    Result.DataConclusaoFim := IncDay(Result.DataConclusaoFim, 1);

  Result.Pagina := StrToIntDef(Req.Query.Items['page'], 1);
  Result.PorPagina := StrToIntDef(Req.Query.Items['page_size'], 25);
end;

function ItemParaJson(const AItem: TRelatorioInscricaoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_inscricao', TJSONNumber.Create(AItem.IdInscricao));
  Result.AddPair('participante_nome', AItem.ParticipanteNome);
  Result.AddPair('cpf_mascarado', AItem.CpfMascarado);
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('tipo_turma', AItem.TipoTurma);
  Result.AddPair('origem', AItem.Origem);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('inscrito_em',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.InscritoEm));

  if AItem.TemConcluidoEm then
    Result.AddPair('concluido_em',
      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AItem.ConcluidoEm))
  else
    Result.AddPair('concluido_em', TJSONNull.Create);

  if AItem.TemPercentualPresenca then
    Result.AddPair('percentual_presenca', TJSONNumber.Create(AItem.PercentualPresenca))
  else
    Result.AddPair('percentual_presenca', TJSONNull.Create);

  Result.AddPair('elegivel_certificado', TJSONBool.Create(AItem.ElegivelCertificado));
  Result.AddPair('certificado_emitido', TJSONBool.Create(AItem.CertificadoEmitido));
end;

class procedure TInstituicaoRelatorioInscricaoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/relatorios/inscricoes/filtros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtros: TRelatorioInscricaoFiltros;
      Item: TRelatorioInscricaoFiltroOpcao;
      Dados, JsonItem: TJSONObject;
      Cursos, Turmas: TJSONArray;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtros := TInstituicaoRelatorioInscricaoService.ListarFiltros(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );
        try
          Cursos := TJSONArray.Create;
          Turmas := TJSONArray.Create;

          for Item in Filtros.Cursos do
          begin
            JsonItem := TJSONObject.Create;
            JsonItem.AddPair('id', TJSONNumber.Create(Item.Id));
            JsonItem.AddPair('nome', Item.Nome);
            Cursos.AddElement(JsonItem);
          end;

          for Item in Filtros.Turmas do
          begin
            JsonItem := TJSONObject.Create;
            JsonItem.AddPair('id', TJSONNumber.Create(Item.Id));
            JsonItem.AddPair('nome', Item.Nome);
            JsonItem.AddPair('id_curso', TJSONNumber.Create(Item.IdCurso));
            Turmas.AddElement(JsonItem);
          end;

          Dados := TJSONObject.Create;
          Dados.AddPair('cursos', Cursos);
          Dados.AddPair('turmas', Turmas);
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
    '/v1/certifica/instituicao/relatorios/inscricoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioInscricaoFiltro;
      Resultado: TRelatorioInscricaoResultado;
      Item: TRelatorioInscricaoItem;
      Dados, Resumo, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Resultado := TInstituicaoRelatorioInscricaoService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );
        try
          Itens := TJSONArray.Create;
          for Item in Resultado.Itens do
            Itens.AddElement(ItemParaJson(Item));

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_inscricoes', TJSONNumber.Create(Resultado.Resumo.TotalInscricoes));
          Resumo.AddPair('confirmadas', TJSONNumber.Create(Resultado.Resumo.Confirmadas));
          Resumo.AddPair('em_andamento', TJSONNumber.Create(Resultado.Resumo.EmAndamento));
          Resumo.AddPair('concluidas', TJSONNumber.Create(Resultado.Resumo.Concluidas));
          Resumo.AddPair('canceladas', TJSONNumber.Create(Resultado.Resumo.Canceladas));
          Resumo.AddPair('reprovadas', TJSONNumber.Create(Resultado.Resumo.Reprovadas));
          Resumo.AddPair('desistentes', TJSONNumber.Create(Resultado.Resumo.Desistentes));
          Resumo.AddPair('elegiveis_certificado', TJSONNumber.Create(Resultado.Resumo.ElegiveisCertificado));
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

          TAppResponse.Ok(Res, Dados, 'Relatório de inscrições e conclusões carregado com sucesso.');
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/inscricoes/exportar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioInscricaoFiltro;
      Csv: string;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Csv := TInstituicaoRelatorioInscricaoService.ExportarCsv(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );

        Res.RawWebResponse.ContentType := 'text/csv; charset=utf-8';
        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition',
          'attachment; filename="relatorio-inscricoes-conclusoes.csv"'
        );
        Res.Send(Csv);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
