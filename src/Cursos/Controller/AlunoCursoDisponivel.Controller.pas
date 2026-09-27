unit AlunoCursoDisponivel.Controller;

interface

type
  TAlunoCursoDisponivelController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  AlunoCursoDisponivel.Model,
  AlunoCursoDisponivel.Service,
  InstituicaoInscricao.Model;

function AutorizarAluno(
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

function ISODateTime(const AValue: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AValue);
end;

function CursoJson(const AItem: TAlunoCursoDisponivelItem): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('codigo_turma', AItem.CodigoTurma);
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('id_curso', TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('codigo_curso', AItem.CodigoCurso);
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('curso_descricao', AItem.CursoDescricao);
  Result.AddPair('curso_objetivo', AItem.CursoObjetivo);
  Result.AddPair('modalidade', AItem.Modalidade);
  Result.AddPair('imagem_url', AItem.ImagemUrl);
  Result.AddPair('data_hora_inicio', ISODateTime(AItem.DataHoraInicio));
  Result.AddPair('data_hora_fim', ISODateTime(AItem.DataHoraFim));

  if AItem.TemInscricaoInicio then
    Result.AddPair('inscricao_inicio', ISODateTime(AItem.InscricaoInicio))
  else
    Result.AddPair('inscricao_inicio', TJSONNull.Create);

  if AItem.TemInscricaoFim then
    Result.AddPair('inscricao_fim', ISODateTime(AItem.InscricaoFim))
  else
    Result.AddPair('inscricao_fim', TJSONNull.Create);

  if AItem.TemLimiteParticipantes then
    Result.AddPair('limite_participantes', TJSONNumber.Create(AItem.LimiteParticipantes))
  else
    Result.AddPair('limite_participantes', TJSONNull.Create);

  Result.AddPair('inscritos_confirmados', TJSONNumber.Create(AItem.InscritosConfirmados));

  if AItem.TemVagasDisponiveis then
    Result.AddPair('vagas_disponiveis', TJSONNumber.Create(AItem.VagasDisponiveis))
  else
    Result.AddPair('vagas_disponiveis', TJSONNull.Create);

  Result.AddPair('local', AItem.Local);
  Result.AddPair('carga_horaria_minutos', TJSONNumber.Create(AItem.CargaHorariaMinutos));
  Result.AddPair('ja_inscrito', TJSONBool.Create(AItem.JaInscrito));

  if AItem.TemIdInscricao then
  begin
    Result.AddPair('id_inscricao', TJSONNumber.Create(AItem.IdInscricao));
    Result.AddPair('situacao_inscricao', AItem.SituacaoInscricao);
  end
  else
  begin
    Result.AddPair('id_inscricao', TJSONNull.Create);
    Result.AddPair('situacao_inscricao', TJSONNull.Create);
  end;
end;

function InscricaoJson(const AItem: TInstituicaoInscricaoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('codigo_publico', AItem.CodigoPublico);
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('turma_nome', AItem.TurmaNome);
  Result.AddPair('id_curso', TJSONNumber.Create(AItem.IdCurso));
  Result.AddPair('curso_nome', AItem.CursoNome);
  Result.AddPair('origem', AItem.Origem);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('inscrito_em', ISODateTime(AItem.InscritoEm));
end;

class procedure TAlunoCursoDisponivelController.Registry;
begin
  THorse.Get(
    '/v1/certifica/aluno/cursos-disponiveis',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoCursoDisponivelLista;
      Item: TAlunoCursoDisponivelItem;
      Arr: TJSONArray;
      Dados, Paginacao: TJSONObject;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then
          Exit;

        Lista := TAlunoCursoDisponivelService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToIntDef(Req.Query.Items['page'], 1),
          StrToIntDef(Req.Query.Items['page_size'], 20)
        );
        try
          Arr := TJSONArray.Create;

          for Item in Lista.Itens do
            Arr.AddElement(CursoJson(Item));

          if Lista.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas := (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Lista.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Arr);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Cursos disponíveis carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/aluno/cursos-disponiveis/:id_turma',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TAlunoCursoDisponivelItem;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then
          Exit;

        Item := TAlunoCursoDisponivelService.Buscar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id_turma'], 0)
        );
        try
          TAppResponse.Ok(Res, CursoJson(Item), 'Curso disponível carregado com sucesso.');
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/aluno/cursos-disponiveis/:id_turma/inscricao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then
          Exit;

        Item := TAlunoCursoDisponivelService.AutoInscrever(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id_turma'], 0)
        );
        try
          TAppResponse.Ok(
            Res,
            InscricaoJson(Item),
            'Solicitação de inscrição enviada. Aguarde a aprovação da instituição.'
          );
        finally
          Item.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
