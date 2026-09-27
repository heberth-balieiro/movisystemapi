unit InstituicaoInscricao.Controller;

interface

type
  TInstituicaoInscricaoController = class
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
  InstituicaoInscricao.Model,
  InstituicaoInscricao.Service;

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

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );

    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
end;

function JsonInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Int64 = 0
): Int64;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    StrToInt64Def(
      Valor.Value,
      ADefault
    );
end;

function DataHoraISO(
  const AData: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AData
    );
end;

procedure AddNullableString(
  const AObj: TJSONObject;
  const ANome,
        AValor: string
);
begin
  if Trim(AValor).IsEmpty then
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    )
  else
    AObj.AddPair(
      ANome,
      AValor
    );
end;

procedure AddNullableDateTime(
  const AObj: TJSONObject;
  const ANome: string;
  const ATemValor: Boolean;
  const AValor: TDateTime
);
begin
  if ATemValor then
    AObj.AddPair(
      ANome,
      DataHoraISO(
        AValor
      )
    )
  else
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );
end;

procedure AddNullableDouble(
  const AObj: TJSONObject;
  const ANome: string;
  const ATemValor: Boolean;
  const AValor: Double
);
begin
  if ATemValor then
    AObj.AddPair(
      ANome,
      TJSONNumber.Create(
        AValor
      )
    )
  else
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );
end;

function InscricaoParaJson(
  const AItem: TInstituicaoInscricaoItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AItem.Id
    )
  );

  Result.AddPair(
    'id_turma',
    TJSONNumber.Create(
      AItem.IdTurma
    )
  );

  Result.AddPair(
    'id_curso',
    TJSONNumber.Create(
      AItem.IdCurso
    )
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
    'id_participante',
    TJSONNumber.Create(
      AItem.IdParticipante
    )
  );

  Result.AddPair(
    'participante_nome',
    AItem.ParticipanteNome
  );

  AddNullableString(
    Result,
    'participante_cpf_mascarado',
    AItem.ParticipanteCpfMascarado
  );

  AddNullableString(
    Result,
    'participante_matricula',
    AItem.ParticipanteMatricula
  );

  Result.AddPair(
    'codigo_publico',
    AItem.CodigoPublico
  );

  Result.AddPair(
    'origem',
    AItem.Origem
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'inscrito_em',
    DataHoraISO(
      AItem.InscritoEm
    )
  );

  AddNullableDateTime(
    Result,
    'confirmado_em',
    AItem.TemConfirmadoEm,
    AItem.ConfirmadoEm
  );

  AddNullableDateTime(
    Result,
    'iniciado_em',
    AItem.TemIniciadoEm,
    AItem.IniciadoEm
  );

  AddNullableDateTime(
    Result,
    'concluido_em',
    AItem.TemConcluidoEm,
    AItem.ConcluidoEm
  );

  AddNullableDateTime(
    Result,
    'cancelado_em',
    AItem.TemCanceladoEm,
    AItem.CanceladoEm
  );

  AddNullableString(
    Result,
    'motivo_cancelamento',
    AItem.MotivoCancelamento
  );

  AddNullableDouble(
    Result,
    'percentual_presenca',
    AItem.TemPercentualPresenca,
    AItem.PercentualPresenca
  );

  Result.AddPair(
    'percentual_progresso',
    TJSONNumber.Create(
      AItem.PercentualProgresso
    )
  );

  AddNullableDouble(
    Result,
    'nota_final',
    AItem.TemNotaFinal,
    AItem.NotaFinal
  );

  Result.AddPair(
    'elegivel_certificado',
    TJSONBool.Create(
      AItem.ElegivelCertificado
    )
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AItem.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    DataHoraISO(
      AItem.AtualizadoEm
    )
  );
end;

function HistoricoParaJson(
  const AItem: TInstituicaoInscricaoHistoricoItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AItem.Id
    )
  );

  if AItem.TemSituacaoAnterior then
    Result.AddPair(
      'situacao_anterior',
      AItem.SituacaoAnterior
    )
  else
    Result.AddPair(
      'situacao_anterior',
      TJSONNull.Create
    );

  Result.AddPair(
    'situacao_nova',
    AItem.SituacaoNova
  );

  AddNullableString(
    Result,
    'observacao',
    AItem.Observacao
  );

  if AItem.TemAlteradoPor then
    Result.AddPair(
      'alterado_por',
      TJSONNumber.Create(
        AItem.AlteradoPor
      )
    )
  else
    Result.AddPair(
      'alterado_por',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'alterado_por_nome',
    AItem.AlteradoPorNome
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AItem.CriadoEm
    )
  );
end;

class procedure TInstituicaoInscricaoController.Registry;
begin

  THorse.Get(
    '/v1/certifica/instituicao/inscricoes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoInscricaoLista;
      Item: TInstituicaoInscricaoItem;
      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;
      Pagina: Integer;
      PorPagina: Integer;
      IdTurma: Int64;
      IdParticipante: Int64;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Pagina :=
          StrToIntDef(
            Req.Query.Items['page'],
            1
          );

        PorPagina :=
          StrToIntDef(
            Req.Query.Items['page_size'],
            20
          );

        IdTurma :=
          StrToInt64Def(
            Req.Query.Items['id_turma'],
            0
          );

        IdParticipante :=
          StrToInt64Def(
            Req.Query.Items['id_participante'],
            0
          );

        Resultado :=
          TInstituicaoInscricaoService.Listar(
            Claims.IdInstituicao,
            Req.Query.Items['busca'],
            IdTurma,
            IdParticipante,
            Req.Query.Items['situacao'],
            Req.Query.Items['origem'],
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(
              InscricaoParaJson(
                Item
              )
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

          Paginacao :=
            TJSONObject.Create;

          Paginacao.AddPair(
            'pagina',
            TJSONNumber.Create(
              Resultado.Pagina
            )
          );

          Paginacao.AddPair(
            'por_pagina',
            TJSONNumber.Create(
              Resultado.PorPagina
            )
          );

          Paginacao.AddPair(
            'total',
            TJSONNumber.Create(
              Resultado.Total
            )
          );

          Paginacao.AddPair(
            'total_paginas',
            TJSONNumber.Create(
              TotalPaginas
            )
          );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          Dados.AddPair(
            'paginacao',
            Paginacao
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Inscrições carregadas com sucesso.'
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


  THorse.Post(
    '/v1/certifica/instituicao/inscricoes',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoInscricaoCadastro;
      Inscricao: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoInscricaoCadastro
            );

          Dados.IdTurma :=
            JsonInt64(
              Body,
              'id_turma',
              0
            );

          Dados.IdParticipante :=
            JsonInt64(
              Body,
              'id_participante',
              0
            );

        finally
          Body.Free;
        end;

        Inscricao :=
          TInstituicaoInscricaoService.CadastrarAdministrativa(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        try
          TAppResponse.Ok(
            Res,
            InscricaoParaJson(
              Inscricao
            ),
            'Inscrição realizada com sucesso.'
          );

        finally
          Inscricao.Free;
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
    '/v1/certifica/instituicao/inscricoes/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Inscricao: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Inscricao :=
          TInstituicaoInscricaoService.BuscarPorId(
            Claims.IdInstituicao,
            IdInscricao
          );

        try
          TAppResponse.Ok(
            Res,
            InscricaoParaJson(
              Inscricao
            ),
            'Inscrição carregada com sucesso.'
          );

        finally
          Inscricao.Free;
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


  THorse.Patch(
    '/v1/certifica/instituicao/inscricoes/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoInscricaoSituacaoAlteracao;
      Inscricao: TInstituicaoInscricaoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoInscricaoSituacaoAlteracao
            );

          Dados.Situacao :=
            JsonString(
              Body,
              'situacao'
            );

          Dados.Observacao :=
            JsonString(
              Body,
              'observacao'
            );

          Dados.MotivoCancelamento :=
            JsonString(
              Body,
              'motivo_cancelamento'
            );

        finally
          Body.Free;
        end;

        Inscricao :=
          TInstituicaoInscricaoService.AlterarSituacao(
            Claims.IdInstituicao,
            IdInscricao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        try
          TAppResponse.Ok(
            Res,
            InscricaoParaJson(
              Inscricao
            ),
            'Situação da inscrição atualizada com sucesso.'
          );

        finally
          Inscricao.Free;
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
    '/v1/certifica/instituicao/inscricoes/:id/historico',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Historico: TInstituicaoInscricaoHistoricoLista;
      Item: TInstituicaoInscricaoHistoricoItem;
      Itens: TJSONArray;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Historico :=
          TInstituicaoInscricaoService.ListarHistorico(
            Claims.IdInstituicao,
            IdInscricao
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Historico do
            Itens.AddElement(
              HistoricoParaJson(
                Item
              )
            );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'itens',
            Itens
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Histórico da inscrição carregado com sucesso.'
          );

        finally
          Historico.Free;
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

end;

end.
