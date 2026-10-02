unit InstituicaoRelatorioCertificado.Controller;

interface

type
  TInstituicaoRelatorioCertificadoController = class
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
  InstituicaoRelatorioCertificado.Model,
  InstituicaoRelatorioCertificado.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido da instituição.'
    );
    Exit;
  end;

  Result := True;
end;

function DataHoraISO(
  const AValor: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss',
      AValor
    );
end;

function ParseData(
  const AValor,
        ACampo: string;
  out AData: TDateTime
): Boolean;
var
  S: string;
begin
  Result := False;
  S := Trim(AValor);

  if S.IsEmpty then
    Exit;

  if not TryISO8601ToDate(
    S,
    AData,
    False
  ) then
    TAppErrors.RaiseBadRequest(
      'Data inválida em ' + ACampo + '. Use yyyy-mm-dd.'
    );

  Result := True;
end;

function LerFiltro(
  const Req: THorseRequest
): TRelatorioCertificadoFiltro;
begin
  Result := Default(TRelatorioCertificadoFiltro);

  Result.Busca :=
    Req.Query.Items['busca'];

  Result.Situacao :=
    Req.Query.Items['situacao'];

  Result.TipoTurma :=
    Req.Query.Items['tipo_turma'];

  Result.IdCurso :=
    StrToInt64Def(
      Req.Query.Items['id_curso'],
      0
    );

  Result.IdTurma :=
    StrToInt64Def(
      Req.Query.Items['id_turma'],
      0
    );

  Result.IdParticipante :=
    StrToInt64Def(
      Req.Query.Items['id_participante'],
      0
    );

  Result.TemDataInicio :=
    ParseData(
      Req.Query.Items['data_inicio'],
      'data_inicio',
      Result.DataInicio
    );

  Result.TemDataFim :=
    ParseData(
      Req.Query.Items['data_fim'],
      'data_fim',
      Result.DataFim
    );

  if Result.TemDataFim then
    Result.DataFim :=
      IncDay(
        Result.DataFim,
        1
      );

  Result.Pagina :=
    StrToIntDef(
      Req.Query.Items['page'],
      1
    );

  Result.PorPagina :=
    StrToIntDef(
      Req.Query.Items['page_size'],
      25
    );
end;

function ItemParaJson(
  const AItem: TRelatorioCertificadoItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id_certificado',
    TJSONNumber.Create(AItem.IdCertificado)
  );

  Result.AddPair(
    'numero_publico',
    AItem.NumeroPublico
  );

  Result.AddPair(
    'participante_nome',
    AItem.ParticipanteNome
  );

  Result.AddPair(
    'cpf_mascarado',
    AItem.CpfMascarado
  );

  Result.AddPair(
    'curso_nome',
    AItem.CursoNome
  );

  Result.AddPair(
    'turma_nome',
    AItem.TurmaNome
  );

  Result.AddPair(
    'tipo_turma',
    AItem.TipoTurma
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'versao',
    TJSONNumber.Create(AItem.Versao)
  );

  Result.AddPair(
    'reemitido',
    TJSONBool.Create(AItem.Reemitido)
  );

  if AItem.TemEmitidoEm then
    Result.AddPair(
      'emitido_em',
      DataHoraISO(AItem.EmitidoEm)
    )
  else
    Result.AddPair(
      'emitido_em',
      TJSONNull.Create
    );

  if AItem.TemCanceladoEm then
    Result.AddPair(
      'cancelado_em',
      DataHoraISO(AItem.CanceladoEm)
    )
  else
    Result.AddPair(
      'cancelado_em',
      TJSONNull.Create
    );

  Result.AddPair(
    'emitido_por_nome',
    AItem.EmitidoPorNome
  );

  Result.AddPair(
    'carga_horaria_minutos',
    TJSONNumber.Create(AItem.CargaHorariaMinutos)
  );
end;

class procedure TInstituicaoRelatorioCertificadoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/relatorios/certificados/filtros',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Filtros: TRelatorioCertificadoFiltros;
      Item: TRelatorioCertificadoFiltroOpcao;
      Dados: TJSONObject;
      Cursos, Turmas: TJSONArray;
      JsonItem: TJSONObject;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Filtros :=
          TInstituicaoRelatorioCertificadoService.ListarFiltros(
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

          TAppResponse.Ok(
            Res,
            Dados,
            'Filtros do relatório carregados com sucesso.'
          );
        finally
          Filtros.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/certificados',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioCertificadoFiltro;
      Resultado: TRelatorioCertificadoResultado;
      Item: TRelatorioCertificadoItem;
      Dados, Resumo, Paginacao: TJSONObject;
      Itens: TJSONArray;
      TotalPaginas: Integer;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );

      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Filtro := LerFiltro(Req);

        Resultado :=
          TInstituicaoRelatorioCertificadoService.Listar(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Filtro
          );

        try
          Itens := TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(
              ItemParaJson(Item)
            );

          Resumo := TJSONObject.Create;
          Resumo.AddPair(
            'total',
            TJSONNumber.Create(Resultado.Resumo.Total)
          );
          Resumo.AddPair(
            'validos',
            TJSONNumber.Create(Resultado.Resumo.Validos)
          );
          Resumo.AddPair(
            'cancelados',
            TJSONNumber.Create(Resultado.Resumo.Cancelados)
          );
          Resumo.AddPair(
            'pendentes',
            TJSONNumber.Create(Resultado.Resumo.Pendentes)
          );
          Resumo.AddPair(
            'erros',
            TJSONNumber.Create(Resultado.Resumo.Erros)
          );
          Resumo.AddPair(
            'reemitidos',
            TJSONNumber.Create(Resultado.Resumo.Reemitidos)
          );

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas :=
              (
                Resultado.Total +
                Resultado.PorPagina -
                1
              ) div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(Resultado.Pagina)
          );
          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(Resultado.PorPagina)
          );
          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(Resultado.Total)
          );
          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(TotalPaginas)
          );

          Dados := TJSONObject.Create;
          Dados.AddPair('resumo', Resumo);
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(
            Res,
            Dados,
            'Relatório de certificados carregado com sucesso.'
          );
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/relatorios/certificados/exportar',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Filtro: TRelatorioCertificadoFiltro;
      Csv: string;
    begin
      Res.RawWebResponse.SetCustomHeader(
        'Cache-Control',
        'private, no-store'
      );
      Res.RawWebResponse.SetCustomHeader(
        'X-Content-Type-Options',
        'nosniff'
      );

      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Filtro := LerFiltro(Req);

        Csv :=
          TInstituicaoRelatorioCertificadoService.ExportarCsv(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Filtro
          );

        Res.RawWebResponse.ContentType :=
          'text/csv; charset=utf-8';

        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition',
          'attachment; filename="relatorio-certificados.csv"'
        );

        Res.Send(Csv);
      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );
end;

end.
