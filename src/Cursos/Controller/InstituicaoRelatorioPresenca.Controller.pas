unit InstituicaoRelatorioPresenca.Controller;

interface

type
  TInstituicaoRelatorioPresencaController = class
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
  InstituicaoRelatorioPresenca.Model,
  InstituicaoRelatorioPresenca.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;

  if (AClaims.IdInstituicao<=0) or
     (AClaims.IdUsuarioInstituicao<=0) then
  begin
    TAppResponse.Forbidden(Res,'Token sem contexto válido da instituição.');
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
  if S.IsEmpty then Exit;

  if not TryISO8601ToDate(S,AData,False) then
    TAppErrors.RaiseBadRequest('Data inválida em ' + ACampo + '. Use yyyy-mm-dd.');

  Result := True;
end;

function LerFiltro(const Req: THorseRequest): TRelatorioPresencaFiltro;
begin
  Result := Default(TRelatorioPresencaFiltro);
  Result.Busca := Req.Query.Items['busca'];
  Result.Situacao := Req.Query.Items['situacao'];
  Result.Origem := Req.Query.Items['origem'];
  Result.ControlePresenca := Req.Query.Items['controle_presenca'];
  Result.IdCurso := StrToInt64Def(Req.Query.Items['id_curso'],0);
  Result.IdTurma := StrToInt64Def(Req.Query.Items['id_turma'],0);
  Result.IdEncontro := StrToInt64Def(Req.Query.Items['id_encontro'],0);

  Result.TemDataInicio := ParseData(
    Req.Query.Items['data_inicio'],'data_inicio',Result.DataInicio);

  Result.TemDataFim := ParseData(
    Req.Query.Items['data_fim'],'data_fim',Result.DataFim);

  if Result.TemDataFim then
    Result.DataFim := IncDay(Result.DataFim,1);

  Result.Pagina := StrToIntDef(Req.Query.Items['page'],1);
  Result.PorPagina := StrToIntDef(Req.Query.Items['page_size'],25);
end;

function ItemParaJson(const AItem: TRelatorioPresencaItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_inscricao',TJSONNumber.Create(AItem.IdInscricao));
  Result.AddPair('id_participante',TJSONNumber.Create(AItem.IdParticipante));
  Result.AddPair('participante_nome',AItem.ParticipanteNome);
  Result.AddPair('cpf_mascarado',AItem.CpfMascarado);
  Result.AddPair('id_curso',TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('curso_nome',AItem.CursoNome);
  Result.AddPair('id_turma',TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('turma_nome',AItem.TurmaNome);
  Result.AddPair('controle_presenca',AItem.ControlePresenca);

  if AItem.TemEncontro then
  begin
    Result.AddPair('id_encontro',TJSONNumber.Create(AItem.IdEncontro));
    Result.AddPair('encontro_titulo',AItem.EncontroTitulo);
  end
  else
  begin
    Result.AddPair('id_encontro',TJSONNull.Create);
    Result.AddPair('encontro_titulo',TJSONNull.Create);
  end;

  Result.AddPair('data_referencia',
    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',AItem.DataReferencia));
  Result.AddPair('situacao',AItem.Situacao);
  Result.AddPair('origem',AItem.Origem);

  if AItem.TemCheckinEm then
    Result.AddPair('checkin_em',
      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',AItem.CheckinEm))
  else
    Result.AddPair('checkin_em',TJSONNull.Create);

  if AItem.TemMinutosPresentes then
    Result.AddPair('minutos_presentes',TJSONNumber.Create(AItem.MinutosPresentes))
  else
    Result.AddPair('minutos_presentes',TJSONNull.Create);

  Result.AddPair('registrado_por_nome',AItem.RegistradoPorNome);
  Result.AddPair('justificativa',AItem.Justificativa);
end;

class procedure TInstituicaoRelatorioPresencaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/relatorios/presencas/filtros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtros: TRelatorioPresencaFiltros;
      Item: TRelatorioPresencaFiltroOpcao;
      Dados, Obj: TJSONObject;
      Cursos, Turmas, Encontros: TJSONArray;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control','private, no-store');
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;

        Filtros := TInstituicaoRelatorioPresencaService.ListarFiltros(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );
        try
          Cursos := TJSONArray.Create;
          Turmas := TJSONArray.Create;
          Encontros := TJSONArray.Create;

          for Item in Filtros.Cursos do
          begin
            Obj := TJSONObject.Create;
            Obj.AddPair('id',TJSONNumber.Create(Item.Id));
            Obj.AddPair('nome',Item.Nome);
            Cursos.AddElement(Obj);
          end;

          for Item in Filtros.Turmas do
          begin
            Obj := TJSONObject.Create;
            Obj.AddPair('id',TJSONNumber.Create(Item.Id));
            Obj.AddPair('nome',Item.Nome);
            Obj.AddPair('id_curso',TJSONNumber.Create(Item.IdCurso));
            Turmas.AddElement(Obj);
          end;

          for Item in Filtros.Encontros do
          begin
            Obj := TJSONObject.Create;
            Obj.AddPair('id',TJSONNumber.Create(Item.Id));
            Obj.AddPair('nome',Item.Nome);
            Obj.AddPair('id_turma',TJSONNumber.Create(Item.IdTurma));
            Encontros.AddElement(Obj);
          end;

          Dados := TJSONObject.Create;
          Dados.AddPair('cursos',Cursos);
          Dados.AddPair('turmas',Turmas);
          Dados.AddPair('encontros',Encontros);

          TAppResponse.Ok(Res,Dados,'Filtros do relatório carregados com sucesso.');
        finally
          Filtros.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/presencas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioPresencaFiltro;
      Resultado: TRelatorioPresencaResultado;
      Item: TRelatorioPresencaItem;
      Dados, Resumo, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control','private, no-store');
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;

        Filtro := LerFiltro(Req);
        Resultado := TInstituicaoRelatorioPresencaService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );
        try
          Itens := TJSONArray.Create;
          for Item in Resultado.Itens do
            Itens.AddElement(ItemParaJson(Item));

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_previstos',TJSONNumber.Create(Resultado.Resumo.TotalPrevistos));
          Resumo.AddPair('presentes',TJSONNumber.Create(Resultado.Resumo.Presentes));
          Resumo.AddPair('ausentes',TJSONNumber.Create(Resultado.Resumo.Ausentes));
          Resumo.AddPair('justificadas',TJSONNumber.Create(Resultado.Resumo.Justificadas));
          Resumo.AddPair('parciais',TJSONNumber.Create(Resultado.Resumo.Parciais));
          Resumo.AddPair('sem_registro',TJSONNumber.Create(Resultado.Resumo.SemRegistro));
          Resumo.AddPair('auto_checkin',TJSONNumber.Create(Resultado.Resumo.AutoCheckin));
          Resumo.AddPair('qr_equipe',TJSONNumber.Create(Resultado.Resumo.QrEquipe));
          Resumo.AddPair('manuais',TJSONNumber.Create(Resultado.Resumo.Manuais));

          if Resultado.Total=0 then TotalPaginas := 0
          else TotalPaginas := (Resultado.Total + Resultado.PorPagina - 1) div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina',TJSONNumber.Create(Resultado.Pagina));
          Paginacao.AddPair('por_pagina',TJSONNumber.Create(Resultado.PorPagina));
          Paginacao.AddPair('total',TJSONNumber.Create(Resultado.Total));
          Paginacao.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('resumo',Resumo);
          Dados.AddPair('itens',Itens);
          Dados.AddPair('paginacao',Paginacao);

          TAppResponse.Ok(Res,Dados,'Relatório de presenças carregado com sucesso.');
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/presencas/exportar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioPresencaFiltro;
      Csv: string;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control','private, no-store');
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options','nosniff');
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;

        Filtro := LerFiltro(Req);
        Csv := TInstituicaoRelatorioPresencaService.ExportarCsv(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );

        Res.RawWebResponse.ContentType := 'text/csv; charset=utf-8';
        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition',
          'attachment; filename="relatorio-presencas.csv"'
        );
        Res.Send(Csv);
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
