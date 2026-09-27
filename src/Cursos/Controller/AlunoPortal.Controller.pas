unit AlunoPortal.Controller;

interface

type
  TAlunoPortalController = class
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
  AlunoPortal.Model,
  AlunoPortal.Service;

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

procedure AddNullableString(
  const Obj: TJSONObject;
  const Nome,
        Valor: string
);
begin
  if Trim(Valor).IsEmpty then
    Obj.AddPair(Nome, TJSONNull.Create)
  else
    Obj.AddPair(Nome, Valor);
end;

function PerfilJson(const AAluno: TAlunoContexto): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_participante', TJSONNumber.Create(AAluno.IdParticipante));
  Result.AddPair('codigo_publico', AAluno.CodigoPublico);
  Result.AddPair('nome', AAluno.Nome);
  AddNullableString(Result, 'email', AAluno.Email);
  AddNullableString(Result, 'cpf_mascarado', AAluno.CpfMascarado);
  AddNullableString(Result, 'matricula', AAluno.Matricula);
  AddNullableString(Result, 'telefone', AAluno.Telefone);
  AddNullableString(Result, 'orgao_empresa', AAluno.OrgaoEmpresa);
  AddNullableString(Result, 'cargo', AAluno.Cargo);
  Result.AddPair('instituicao_nome', AAluno.InstituicaoNome);
  Result.AddPair('instituicao_slug', AAluno.InstituicaoSlug);
end;

function InscricaoJson(const I: TAlunoInscricaoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(I.Id));
  Result.AddPair('codigo_publico', I.CodigoPublico);
  Result.AddPair('id_turma', TJSONNumber.Create(I.IdTurma));
  Result.AddPair('turma_nome', I.TurmaNome);
  Result.AddPair('id_curso', TJSONNumber.Create(I.IdCurso));
  Result.AddPair('curso_nome', I.CursoNome);
  AddNullableString(Result, 'curso_imagem_url', I.CursoImagemUrl);
  Result.AddPair('modalidade', I.Modalidade);
  Result.AddPair('situacao', I.Situacao);
  Result.AddPair('inscrito_em', ISODateTime(I.InscritoEm));

  if I.TemDataInicio then
    Result.AddPair('data_inicio', ISODateTime(I.DataInicio))
  else
    Result.AddPair('data_inicio', TJSONNull.Create);

  if I.TemDataFim then
    Result.AddPair('data_fim', ISODateTime(I.DataFim))
  else
    Result.AddPair('data_fim', TJSONNull.Create);

  if I.TemPercentualPresenca then
    Result.AddPair('percentual_presenca', TJSONNumber.Create(I.PercentualPresenca))
  else
    Result.AddPair('percentual_presenca', TJSONNull.Create);

  Result.AddPair('percentual_progresso', TJSONNumber.Create(I.PercentualProgresso));

  if I.TemNotaFinal then
    Result.AddPair('nota_final', TJSONNumber.Create(I.NotaFinal))
  else
    Result.AddPair('nota_final', TJSONNull.Create);

  Result.AddPair('elegivel_certificado', TJSONBool.Create(I.ElegivelCertificado));
end;

function CertificadoJson(const C: TAlunoCertificadoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(C.Id));
  Result.AddPair('numero_publico', C.NumeroPublico);
  Result.AddPair('versao', TJSONNumber.Create(C.Versao));
  Result.AddPair('situacao', C.Situacao);
  Result.AddPair('curso_nome', C.CursoNome);
  Result.AddPair('instituicao_nome', C.InstituicaoNome);
  Result.AddPair('carga_horaria_minutos', TJSONNumber.Create(C.CargaHorariaMinutos));
  Result.AddPair('data_conclusao', ISODateTime(C.DataConclusao));
  Result.AddPair('tem_pdf', TJSONBool.Create(C.TemPdf));

  if C.TemEmitidoEm then
    Result.AddPair('emitido_em', ISODateTime(C.EmitidoEm))
  else
    Result.AddPair('emitido_em', TJSONNull.Create);

  if C.TemCanceladoEm then
    Result.AddPair('cancelado_em', ISODateTime(C.CanceladoEm))
  else
    Result.AddPair('cancelado_em', TJSONNull.Create);
end;

class procedure TAlunoPortalController.Registry;
begin
  THorse.Get('/v1/certifica/aluno/me',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Aluno: TAlunoContexto;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Aluno := TAlunoPortalService.MeuPerfil(Claims.IdInstituicao, Claims.IdUsuarioInstituicao);
        try
          TAppResponse.Ok(Res, PerfilJson(Aluno), 'Perfil carregado com sucesso.');
        finally
          Aluno.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/dashboard',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      D: TAlunoDashboard;
      Json: TJSONObject;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        D := TAlunoPortalService.Dashboard(Claims.IdInstituicao, Claims.IdUsuarioInstituicao);
        try
          Json := TJSONObject.Create;
          Json.AddPair('total_inscricoes', TJSONNumber.Create(D.TotalInscricoes));
          Json.AddPair('inscricoes_em_andamento', TJSONNumber.Create(D.InscricoesEmAndamento));
          Json.AddPair('inscricoes_concluidas', TJSONNumber.Create(D.InscricoesConcluidas));
          Json.AddPair('certificados_validos', TJSONNumber.Create(D.CertificadosValidos));
          TAppResponse.Ok(Res, Json, 'Dashboard carregado com sucesso.');
        finally
          D.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/inscricoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoInscricaoLista;
      Item: TAlunoInscricaoItem;
      Dados, Pag: TJSONObject;
      Arr: TJSONArray;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;

        Lista := TAlunoPortalService.ListarInscricoes(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Req.Query.Items['situacao'],
          StrToIntDef(Req.Query.Items['page'], 1),
          StrToIntDef(Req.Query.Items['page_size'], 20)
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista.Itens do
            Arr.AddElement(InscricaoJson(Item));

          if Lista.Total = 0 then TotalPaginas := 0
          else TotalPaginas := (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Pag := TJSONObject.Create;
          Pag.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Pag.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Pag.AddPair('total', TJSONNumber.Create(Lista.Total));
          Pag.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Arr);
          Dados.AddPair('paginacao', Pag);

          TAppResponse.Ok(Res, Dados, 'Inscrições carregadas com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/inscricoes/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TAlunoInscricaoItem;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Item := TAlunoPortalService.BuscarInscricao(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );
        try
          TAppResponse.Ok(Res, InscricaoJson(Item), 'Inscrição carregada com sucesso.');
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/inscricoes/:id/presencas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoPresencaLista;
      Item: TAlunoPresencaItem;
      Arr: TJSONArray;
      J: TJSONObject;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Lista := TAlunoPortalService.ListarPresencas(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista do
          begin
            J := TJSONObject.Create;
            J.AddPair('id_encontro', TJSONNumber.Create(Item.IdEncontro));
            J.AddPair('titulo', Item.Titulo);
            J.AddPair('data_hora_inicio', ISODateTime(Item.DataHoraInicio));
            J.AddPair('data_hora_fim', ISODateTime(Item.DataHoraFim));
            J.AddPair('obrigatorio', TJSONBool.Create(Item.Obrigatorio));
            J.AddPair('situacao_encontro', Item.SituacaoEncontro);
            J.AddPair('registrada', TJSONBool.Create(Item.Registrada));
            if Item.Registrada then J.AddPair('situacao_presenca', Item.SituacaoPresenca)
            else J.AddPair('situacao_presenca', TJSONNull.Create);
            if Item.TemMinutosPresentes then J.AddPair('minutos_presentes', TJSONNumber.Create(Item.MinutosPresentes))
            else J.AddPair('minutos_presentes', TJSONNull.Create);
            AddNullableString(J, 'justificativa', Item.Justificativa);
            Arr.AddElement(J);
          end;
          J := TJSONObject.Create;
          J.AddPair('itens', Arr);
          TAppResponse.Ok(Res, J, 'Presenças carregadas com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/inscricoes/:id/aulas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoAulaLista;
      Item: TAlunoAulaItem;
      Arr: TJSONArray;
      J: TJSONObject;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Lista := TAlunoPortalService.ListarAulas(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista do
          begin
            J := TJSONObject.Create;
            J.AddPair('id_aula', TJSONNumber.Create(Item.IdAula));
            J.AddPair('modulo_titulo', Item.ModuloTitulo);
            J.AddPair('titulo', Item.Titulo);
            J.AddPair('tipo', Item.Tipo);
            if Item.TemDuracaoMinutos then J.AddPair('duracao_minutos', TJSONNumber.Create(Item.DuracaoMinutos))
            else J.AddPair('duracao_minutos', TJSONNull.Create);
            J.AddPair('obrigatoria', TJSONBool.Create(Item.Obrigatoria));
            J.AddPair('percentual', TJSONNumber.Create(Item.Percentual));
            J.AddPair('duracao_assistida_segundos', TJSONNumber.Create(Item.DuracaoAssistidaSegundos));
            J.AddPair('concluida', TJSONBool.Create(Item.Concluida));
            Arr.AddElement(J);
          end;
          J := TJSONObject.Create;
          J.AddPair('itens', Arr);
          TAppResponse.Ok(Res, J, 'Aulas carregadas com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/inscricoes/:id/criterios',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoCriterioLista;
      Item: TAlunoCriterioItem;
      Arr: TJSONArray;
      J: TJSONObject;
      Raw: TJSONValue;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Lista := TAlunoPortalService.ListarCriterios(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista do
          begin
            J := TJSONObject.Create;
            J.AddPair('id_criterio', TJSONNumber.Create(Item.IdCriterio));
            J.AddPair('tipo', Item.Tipo);
            J.AddPair('nome', Item.Nome);
            J.AddPair('obrigatorio', TJSONBool.Create(Item.Obrigatorio));
            if Item.TemAtendido then J.AddPair('atendido', TJSONBool.Create(Item.Atendido))
            else J.AddPair('atendido', TJSONNull.Create);

            if Trim(Item.ResultadoJson).IsEmpty then
              J.AddPair('resultado', TJSONNull.Create)
            else
            begin
              Raw := TJSONObject.ParseJSONValue(Item.ResultadoJson);
              if Raw = nil then J.AddPair('resultado', TJSONNull.Create)
              else J.AddPair('resultado', Raw);
            end;
            Arr.AddElement(J);
          end;
          J := TJSONObject.Create;
          J.AddPair('itens', Arr);
          TAppResponse.Ok(Res, J, 'Critérios carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/certificados',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TAlunoCertificadoLista;
      Item: TAlunoCertificadoItem;
      Arr: TJSONArray;
      J: TJSONObject;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Lista := TAlunoPortalService.ListarCertificados(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );
        try
          Arr := TJSONArray.Create;
          for Item in Lista do Arr.AddElement(CertificadoJson(Item));
          J := TJSONObject.Create;
          J.AddPair('itens', Arr);
          TAppResponse.Ok(Res, J, 'Certificados carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/certificados/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Item: TAlunoCertificadoItem;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;
        Item := TAlunoPortalService.BuscarCertificado(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );
        try
          TAppResponse.Ok(Res, CertificadoJson(Item), 'Certificado carregado com sucesso.');
        finally
          Item.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/certifica/aluno/certificados/:id/pdf',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Caminho: string;
    begin
      try
        if not AutorizarAluno(Req, Res, Claims) then Exit;

        Caminho := TAlunoPortalService.CaminhoPdf(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          StrToInt64Def(Req.Params.Items['id'], 0)
        );

        Res.SendFile(Caminho);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
