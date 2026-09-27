unit InstituicaoConclusao.Controller;

interface

type
  TInstituicaoConclusaoController = class
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
  InstituicaoConclusao.Model,
  InstituicaoConclusao.Service;

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

procedure AddJsonRawOrNull(
  const AObj: TJSONObject;
  const ANome,
        AJson: string
);
var
  Valor: TJSONValue;
begin
  if Trim(AJson).IsEmpty then
  begin
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    );

    Exit;
  end;

  Valor :=
    TJSONObject.ParseJSONValue(
      AJson
    );

  if Valor = nil then
    AObj.AddPair(
      ANome,
      TJSONNull.Create
    )
  else
    AObj.AddPair(
      ANome,
      Valor
    );
end;

function CriterioParaJson(
  const AItem: TConclusaoCriterioItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id_criterio',
    TJSONNumber.Create(
      AItem.IdCriterio
    )
  );

  Result.AddPair(
    'tipo',
    AItem.Tipo
  );

  Result.AddPair(
    'nome',
    AItem.Nome
  );

  Result.AddPair(
    'obrigatorio',
    TJSONBool.Create(
      AItem.Obrigatorio
    )
  );

  Result.AddPair(
    'ordem',
    TJSONNumber.Create(
      AItem.Ordem
    )
  );

  AddJsonRawOrNull(
    Result,
    'configuracao',
    AItem.Configuracao
  );

  if AItem.TemAtendido then
    Result.AddPair(
      'atendido',
      TJSONBool.Create(
        AItem.Atendido
      )
    )
  else
    Result.AddPair(
      'atendido',
      TJSONNull.Create
    );

  AddJsonRawOrNull(
    Result,
    'resultado',
    AItem.Resultado
  );

  if AItem.TemAvaliadoPor then
    Result.AddPair(
      'avaliado_por',
      TJSONNumber.Create(
        AItem.AvaliadoPor
      )
    )
  else
    Result.AddPair(
      'avaliado_por',
      TJSONNull.Create
    );

  if Trim(
    AItem.AvaliadoPorNome
  ).IsEmpty then
    Result.AddPair(
      'avaliado_por_nome',
      TJSONNull.Create
    )
  else
    Result.AddPair(
      'avaliado_por_nome',
      AItem.AvaliadoPorNome
    );

  if AItem.TemAvaliadoEm then
    Result.AddPair(
      'avaliado_em',
      DataHoraISO(
        AItem.AvaliadoEm
      )
    )
  else
    Result.AddPair(
      'avaliado_em',
      TJSONNull.Create
    );
end;

function ResumoParaJson(
  const AResumo: TConclusaoResumo
): TJSONObject;
var
  Criterio: TConclusaoCriterioItem;
  ArrayCriterios: TJSONArray;
  Totais: TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id_inscricao',
    TJSONNumber.Create(
      AResumo.IdInscricao
    )
  );

  Result.AddPair(
    'id_turma',
    TJSONNumber.Create(
      AResumo.IdTurma
    )
  );

  Result.AddPair(
    'id_curso',
    TJSONNumber.Create(
      AResumo.IdCurso
    )
  );

  Result.AddPair(
    'participante_nome',
    AResumo.ParticipanteNome
  );

  Result.AddPair(
    'curso_nome',
    AResumo.CursoNome
  );

  Result.AddPair(
    'turma_nome',
    AResumo.TurmaNome
  );

  Result.AddPair(
    'situacao_inscricao',
    AResumo.SituacaoInscricao
  );

  if AResumo.TemPercentualPresenca then
    Result.AddPair(
      'percentual_presenca',
      TJSONNumber.Create(
        AResumo.PercentualPresenca
      )
    )
  else
    Result.AddPair(
      'percentual_presenca',
      TJSONNull.Create
    );

  Result.AddPair(
    'percentual_progresso',
    TJSONNumber.Create(
      AResumo.PercentualProgresso
    )
  );

  Result.AddPair(
    'elegivel_certificado',
    TJSONBool.Create(
      AResumo.ElegivelCertificado
    )
  );

  Totais :=
    TJSONObject.Create;

  Totais.AddPair(
    'obrigatorios',
    TJSONNumber.Create(
      AResumo.CriteriosObrigatorios
    )
  );

  Totais.AddPair(
    'atendidos',
    TJSONNumber.Create(
      AResumo.CriteriosObrigatoriosAtendidos
    )
  );

  Totais.AddPair(
    'pendentes',
    TJSONNumber.Create(
      AResumo.CriteriosObrigatoriosPendentes
    )
  );

  Totais.AddPair(
    'nao_atendidos',
    TJSONNumber.Create(
      AResumo.CriteriosObrigatoriosNaoAtendidos
    )
  );

  Result.AddPair(
    'totais_criterios',
    Totais
  );

  ArrayCriterios :=
    TJSONArray.Create;

  for Criterio in AResumo.Criterios do
    ArrayCriterios.AddElement(
      CriterioParaJson(
        Criterio
      )
    );

  Result.AddPair(
    'criterios',
    ArrayCriterios
  );
end;

procedure LerAtendido(
  const ABody: TJSONObject;
  out ATemAtendido: Boolean;
  out AAtendido: Boolean
);
var
  Valor: TJSONValue;
begin
  ATemAtendido := False;
  AAtendido := False;

  Valor :=
    ABody.GetValue(
      'atendido'
    );

  if Valor = nil then
    TAppErrors.RaiseBadRequest(
      'Informe o campo atendido.'
    );

  if Valor is TJSONNull then
    Exit;

  if SameText(
    Valor.Value,
    'true'
  ) then
  begin
    ATemAtendido := True;
    AAtendido := True;
    Exit;
  end;

  if SameText(
    Valor.Value,
    'false'
  ) then
  begin
    ATemAtendido := True;
    AAtendido := False;
    Exit;
  end;

  TAppErrors.RaiseBadRequest(
    'O campo atendido deve ser true, false ou null.'
  );
end;

function LerResultadoJson(
  const ABody: TJSONObject
): string;
var
  Valor: TJSONValue;
begin
  Result := '';

  Valor :=
    ABody.GetValue(
      'resultado'
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.ToJSON;
end;

class procedure TInstituicaoConclusaoController.Registry;
begin

  THorse.Get(
    '/v1/certifica/instituicao/inscricoes/:id_inscricao/conclusao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Resumo: TConclusaoResumo;
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
            Req.Params.Items[
              'id_inscricao'
            ],
            0
          );

        Resumo :=
          TInstituicaoConclusaoService.Consultar(
            Claims.IdInstituicao,
            IdInscricao
          );

        try
          TAppResponse.Ok(
            Res,
            ResumoParaJson(
              Resumo
            ),
            'Conclusão carregada com sucesso.'
          );

        finally
          Resumo.Free;
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
    '/v1/certifica/instituicao/inscricoes/:id_inscricao/conclusao/avaliar',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Resumo: TConclusaoResumo;
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
            Req.Params.Items[
              'id_inscricao'
            ],
            0
          );

        Resumo :=
          TInstituicaoConclusaoService.Avaliar(
            Claims.IdInstituicao,
            IdInscricao,
            Claims.IdUsuarioInstituicao
          );

        try
          TAppResponse.Ok(
            Res,
            ResumoParaJson(
              Resumo
            ),
            'Conclusão avaliada com sucesso.'
          );

        finally
          Resumo.Free;
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


  THorse.Put(
    '/v1/certifica/instituicao/inscricoes/:id_inscricao/criterios/:id_criterio',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      IdCriterio: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TConclusaoAvaliacaoManual;
      Resumo: TConclusaoResumo;
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
            Req.Params.Items[
              'id_inscricao'
            ],
            0
          );

        IdCriterio :=
          StrToInt64Def(
            Req.Params.Items[
              'id_criterio'
            ],
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
              TConclusaoAvaliacaoManual
            );

          LerAtendido(
            Body,
            Dados.TemAtendido,
            Dados.Atendido
          );

          Dados.ResultadoJson :=
            LerResultadoJson(
              Body
            );

        finally
          Body.Free;
        end;

        Resumo :=
          TInstituicaoConclusaoService.AvaliarCriterioManual(
            Claims.IdInstituicao,
            IdInscricao,
            IdCriterio,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        try
          TAppResponse.Ok(
            Res,
            ResumoParaJson(
              Resumo
            ),
            'Critério avaliado com sucesso.'
          );

        finally
          Resumo.Free;
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
