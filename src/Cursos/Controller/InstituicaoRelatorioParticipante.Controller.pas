unit InstituicaoRelatorioParticipante.Controller;

interface

type
  TInstituicaoRelatorioParticipanteController = class
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
  InstituicaoRelatorioParticipante.Model,
  InstituicaoRelatorioParticipante.Service;

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

function LerFiltro(const Req: THorseRequest): TRelatorioParticipanteFiltro;
begin
  Result := Default(TRelatorioParticipanteFiltro);
  Result.Busca := Req.Query.Items['busca'];
  Result.Situacao := Req.Query.Items['situacao'];
  Result.IdCurso := StrToInt64Def(Req.Query.Items['id_curso'], 0);
  Result.IdTurma := StrToInt64Def(Req.Query.Items['id_turma'], 0);
  Result.Pagina := StrToIntDef(Req.Query.Items['page'], 1);
  Result.PorPagina := StrToIntDef(Req.Query.Items['page_size'], 25);
end;

function ItemParaJson(const AItem: TRelatorioParticipanteItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id_participante', TJSONNumber.Create(AItem.IdParticipante));
  Result.AddPair('nome', AItem.Nome);
  Result.AddPair('cpf_mascarado', AItem.CpfMascarado);
  Result.AddPair('email', AItem.Email);
  Result.AddPair('telefone', AItem.Telefone);
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('total_inscricoes', TJSONNumber.Create(AItem.TotalInscricoes));
  Result.AddPair('total_conclusoes', TJSONNumber.Create(AItem.TotalConclusoes));
  Result.AddPair('total_certificados', TJSONNumber.Create(AItem.TotalCertificados));
end;

class procedure TInstituicaoRelatorioParticipanteController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/relatorios/participantes/filtros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtros: TRelatorioParticipanteFiltros;
      Item: TRelatorioParticipanteFiltroOpcao;
      Dados, JsonItem: TJSONObject;
      Cursos, Turmas: TJSONArray;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtros := TInstituicaoRelatorioParticipanteService.ListarFiltros(
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
    '/v1/certifica/instituicao/relatorios/participantes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioParticipanteFiltro;
      Resultado: TRelatorioParticipanteResultado;
      Item: TRelatorioParticipanteItem;
      Dados, Resumo, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Resultado := TInstituicaoRelatorioParticipanteService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );
        try
          Itens := TJSONArray.Create;
          for Item in Resultado.Itens do
            Itens.AddElement(ItemParaJson(Item));

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_participantes', TJSONNumber.Create(Resultado.Resumo.TotalParticipantes));
          Resumo.AddPair('ativos', TJSONNumber.Create(Resultado.Resumo.Ativos));
          Resumo.AddPair('inativos', TJSONNumber.Create(Resultado.Resumo.Inativos));
          Resumo.AddPair('anonimizados', TJSONNumber.Create(Resultado.Resumo.Anonimizados));
          Resumo.AddPair('total_inscricoes', TJSONNumber.Create(Resultado.Resumo.TotalInscricoes));
          Resumo.AddPair('total_conclusoes', TJSONNumber.Create(Resultado.Resumo.TotalConclusoes));
          Resumo.AddPair('total_certificados', TJSONNumber.Create(Resultado.Resumo.TotalCertificados));

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

          TAppResponse.Ok(Res, Dados, 'Relatório de participantes carregado com sucesso.');
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/participantes/exportar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioParticipanteFiltro;
      Csv: string;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Filtro := LerFiltro(Req);
        Csv := TInstituicaoRelatorioParticipanteService.ExportarCsv(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Filtro
        );

        Res.RawWebResponse.ContentType := 'text/csv; charset=utf-8';
        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition',
          'attachment; filename="relatorio-participantes.csv"'
        );
        Res.Send(Csv);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
