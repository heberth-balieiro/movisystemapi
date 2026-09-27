unit InstituicaoTurma.Controller;

interface

type
  TInstituicaoTurmaController = class
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
  InstituicaoTurma.Model,
  InstituicaoTurma.Service;

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
    AObj.GetValue(ANome);

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
    AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    StrToInt64Def(
      Valor.Value,
      ADefault
    );
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean = False
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor :=
    AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    SameText(
      Valor.Value,
      'true'
    );
end;

function JsonDateTimeObrigatorio(
  const AObj: TJSONObject;
  const ANome,
        AMensagem: string
): TDateTime;
var
  Valor: TJSONValue;
begin
  Valor :=
    AObj.GetValue(ANome);

  if
    (Valor = nil) or
    (Valor is TJSONNull) or
    Trim(Valor.Value).IsEmpty
  then
  begin
    TAppErrors.RaiseBadRequest(
      AMensagem
    );

    Exit(0);
  end;

  try
    Result :=
      ISO8601ToDate(
        Valor.Value,
        False
      );
  except
    TAppErrors.RaiseBadRequest(
      'Data/hora inválida no campo ' +
      ANome +
      '.'
    );

    Result := 0;
  end;
end;

procedure JsonDateTimeOpcional(
  const AObj: TJSONObject;
  const ANome: string;
  out AInformado: Boolean;
  out AData: TDateTime
);
var
  Valor: TJSONValue;
begin
  AInformado := False;
  AData := 0;

  Valor :=
    AObj.GetValue(ANome);

  if
    (Valor = nil) or
    (Valor is TJSONNull) or
    Trim(Valor.Value).IsEmpty
  then
    Exit;

  try
    AData :=
      ISO8601ToDate(
        Valor.Value,
        False
      );

    AInformado := True;
  except
    TAppErrors.RaiseBadRequest(
      'Data/hora inválida no campo ' +
      ANome +
      '.'
    );
  end;
end;

procedure JsonIntegerOpcional(
  const AObj: TJSONObject;
  const ANome: string;
  out AInformado: Boolean;
  out AValor: Integer
);
var
  JsonValue: TJSONValue;
  ValorConvertido: Integer;
begin
  AInformado := False;
  AValor := 0;

  JsonValue :=
    AObj.GetValue(ANome);

  if
    (JsonValue = nil) or
    (JsonValue is TJSONNull) or
    Trim(JsonValue.Value).IsEmpty
  then
    Exit;

  if not TryStrToInt(
    JsonValue.Value,
    ValorConvertido
  ) then
  begin
    TAppErrors.RaiseBadRequest(
      'Valor inválido no campo ' +
      ANome +
      '.'
    );

    Exit;
  end;

  AInformado := True;
  AValor := ValorConvertido;
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

function TurmaParaJson(
  const ATurma: TInstituicaoTurmaItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      ATurma.Id
    )
  );

  Result.AddPair(
    'id_curso',
    TJSONNumber.Create(
      ATurma.IdCurso
    )
  );

  Result.AddPair(
    'curso_nome',
    ATurma.CursoNome
  );

  if ATurma.TemModeloCertificado then
  begin
    Result.AddPair(
      'id_modelo_certificado',
      TJSONNumber.Create(
        ATurma.IdModeloCertificado
      )
    );

    AddNullableString(
      Result,
      'modelo_certificado_nome',
      ATurma.ModeloCertificadoNome
    );
  end
  else
  begin
    Result.AddPair(
      'id_modelo_certificado',
      TJSONNull.Create
    );

    Result.AddPair(
      'modelo_certificado_nome',
      TJSONNull.Create
    );
  end;

  Result.AddPair(
    'codigo_publico',
    ATurma.CodigoPublico
  );

  AddNullableString(
    Result,
    'codigo_interno',
    ATurma.CodigoInterno
  );

  Result.AddPair(
    'nome',
    ATurma.Nome
  );

  Result.AddPair(
    'modalidade',
    ATurma.Modalidade
  );

  Result.AddPair(
    'data_hora_inicio',
    DataHoraISO(
      ATurma.DataHoraInicio
    )
  );

  Result.AddPair(
    'data_hora_fim',
    DataHoraISO(
      ATurma.DataHoraFim
    )
  );

  if ATurma.TemInscricaoInicio then
    Result.AddPair(
      'inscricao_inicio',
      DataHoraISO(
        ATurma.InscricaoInicio
      )
    )
  else
    Result.AddPair(
      'inscricao_inicio',
      TJSONNull.Create
    );

  if ATurma.TemInscricaoFim then
    Result.AddPair(
      'inscricao_fim',
      DataHoraISO(
        ATurma.InscricaoFim
      )
    )
  else
    Result.AddPair(
      'inscricao_fim',
      TJSONNull.Create
    );

  if ATurma.TemLimiteParticipantes then
    Result.AddPair(
      'limite_participantes',
      TJSONNumber.Create(
        ATurma.LimiteParticipantes
      )
    )
  else
    Result.AddPair(
      'limite_participantes',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'local',
    ATurma.Local
  );

  AddNullableString(
    Result,
    'url_online',
    ATurma.UrlOnline
  );

  if ATurma.TemCargaHorariaMinutos then
  begin
    Result.AddPair(
      'carga_horaria_minutos',
      TJSONNumber.Create(
        ATurma.CargaHorariaMinutos
      )
    );

    Result.AddPair(
      'carga_horaria_horas',
      TJSONNumber.Create(
        ATurma.CargaHorariaMinutos / 60.0
      )
    );
  end
  else
  begin
    Result.AddPair(
      'carga_horaria_minutos',
      TJSONNull.Create
    );

    Result.AddPair(
      'carga_horaria_horas',
      TJSONNull.Create
    );
  end;

  Result.AddPair(
    'permitir_inscricao_publica',
    TJSONBool.Create(
      ATurma.PermitirInscricaoPublica
    )
  );

  Result.AddPair(
    'situacao',
    ATurma.Situacao
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      ATurma.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    DataHoraISO(
      ATurma.AtualizadoEm
    )
  );
end;

class procedure TInstituicaoTurmaController.Registry;
begin

  {$REGION 'Listar Turmas'}

  THorse.Get(
    '/v1/certifica/instituicao/turmas',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoTurmaLista;
      Turma: TInstituicaoTurmaItem;

      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;

      Busca: string;
      Situacao: string;
      Modalidade: string;
      IdCurso: Int64;
      Pagina: Integer;
      PorPagina: Integer;
      TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Busca :=
          Trim(
            Req.Query.Items['busca']
          );

        Situacao :=
          Trim(
            Req.Query.Items['situacao']
          );

        Modalidade :=
          Trim(
            Req.Query.Items['modalidade']
          );

        IdCurso :=
          StrToInt64Def(
            Req.Query.Items['id_curso'],
            0
          );

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

        Resultado :=
          TInstituicaoTurmaService.Listar(
            Claims.IdInstituicao,
            Busca,
            Situacao,
            Modalidade,
            IdCurso,
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Turma in Resultado.Itens do
            Itens.AddElement(
              TurmaParaJson(
                Turma
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
            'Turmas carregadas com sucesso.'
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

  {$ENDREGION}


  {$REGION 'Buscar Turma'}

  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Turma: TInstituicaoTurmaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdTurma :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Turma :=
          TInstituicaoTurmaService.BuscarPorId(
            Claims.IdInstituicao,
            IdTurma
          );

        try
          TAppResponse.Ok(
            Res,
            TurmaParaJson(
              Turma
            ),
            'Turma carregada com sucesso.'
          );
        finally
          Turma.Free;
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

  {$ENDREGION}


  {$REGION 'Cadastrar Turma'}

  THorse.Post(
    '/v1/certifica/instituicao/turmas',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoTurmaCadastro;
      Turma: TInstituicaoTurmaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );

          Exit;
        end;

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
          Cadastro :=
            Default(
              TInstituicaoTurmaCadastro
            );

          Cadastro.IdCurso :=
            JsonInt64(
              Body,
              'id_curso'
            );

          Cadastro.IdModeloCertificado :=
            JsonInt64(
              Body,
              'id_modelo_certificado'
            );

          Cadastro.CodigoInterno :=
            JsonString(
              Body,
              'codigo_interno'
            );

          Cadastro.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Cadastro.Modalidade :=
            JsonString(
              Body,
              'modalidade'
            );

          Cadastro.DataHoraInicio :=
            JsonDateTimeObrigatorio(
              Body,
              'data_hora_inicio',
              'Informe a data/hora de início da turma.'
            );

          Cadastro.DataHoraFim :=
            JsonDateTimeObrigatorio(
              Body,
              'data_hora_fim',
              'Informe a data/hora de término da turma.'
            );

          JsonDateTimeOpcional(
            Body,
            'inscricao_inicio',
            Cadastro.TemInscricaoInicio,
            Cadastro.InscricaoInicio
          );

          JsonDateTimeOpcional(
            Body,
            'inscricao_fim',
            Cadastro.TemInscricaoFim,
            Cadastro.InscricaoFim
          );

          JsonIntegerOpcional(
            Body,
            'limite_participantes',
            Cadastro.TemLimiteParticipantes,
            Cadastro.LimiteParticipantes
          );

          Cadastro.Local :=
            JsonString(
              Body,
              'local'
            );

          Cadastro.UrlOnline :=
            JsonString(
              Body,
              'url_online'
            );

          JsonIntegerOpcional(
            Body,
            'carga_horaria_minutos',
            Cadastro.TemCargaHorariaMinutos,
            Cadastro.CargaHorariaMinutos
          );

          Cadastro.PermitirInscricaoPublica :=
            JsonBoolean(
              Body,
              'permitir_inscricao_publica',
              False
            );

          Cadastro.Situacao :=
            JsonString(
              Body,
              'situacao',
              'PLANEJADA'
            );

        finally
          Body.Free;
        end;

        Turma :=
          TInstituicaoTurmaService.Cadastrar(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Cadastro
          );

        try
          TAppResponse.Ok(
            Res,
            TurmaParaJson(
              Turma
            ),
            'Turma cadastrada com sucesso.'
          );
        finally
          Turma.Free;
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

  {$ENDREGION}


  {$REGION 'Atualizar Turma'}

  THorse.Put(
    '/v1/certifica/instituicao/turmas/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoTurmaAlteracao;
      Turma: TInstituicaoTurmaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdTurma :=
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
          Alteracao :=
            Default(
              TInstituicaoTurmaAlteracao
            );

          Alteracao.IdCurso :=
            JsonInt64(
              Body,
              'id_curso'
            );

          Alteracao.IdModeloCertificado :=
            JsonInt64(
              Body,
              'id_modelo_certificado'
            );

          Alteracao.CodigoInterno :=
            JsonString(
              Body,
              'codigo_interno'
            );

          Alteracao.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Alteracao.Modalidade :=
            JsonString(
              Body,
              'modalidade'
            );

          Alteracao.DataHoraInicio :=
            JsonDateTimeObrigatorio(
              Body,
              'data_hora_inicio',
              'Informe a data/hora de início da turma.'
            );

          Alteracao.DataHoraFim :=
            JsonDateTimeObrigatorio(
              Body,
              'data_hora_fim',
              'Informe a data/hora de término da turma.'
            );

          JsonDateTimeOpcional(
            Body,
            'inscricao_inicio',
            Alteracao.TemInscricaoInicio,
            Alteracao.InscricaoInicio
          );

          JsonDateTimeOpcional(
            Body,
            'inscricao_fim',
            Alteracao.TemInscricaoFim,
            Alteracao.InscricaoFim
          );

          JsonIntegerOpcional(
            Body,
            'limite_participantes',
            Alteracao.TemLimiteParticipantes,
            Alteracao.LimiteParticipantes
          );

          Alteracao.Local :=
            JsonString(
              Body,
              'local'
            );

          Alteracao.UrlOnline :=
            JsonString(
              Body,
              'url_online'
            );

          JsonIntegerOpcional(
            Body,
            'carga_horaria_minutos',
            Alteracao.TemCargaHorariaMinutos,
            Alteracao.CargaHorariaMinutos
          );

          Alteracao.PermitirInscricaoPublica :=
            JsonBoolean(
              Body,
              'permitir_inscricao_publica',
              False
            );

          Alteracao.Situacao :=
            JsonString(
              Body,
              'situacao'
            );

        finally
          Body.Free;
        end;

        Turma :=
          TInstituicaoTurmaService.Atualizar(
            Claims.IdInstituicao,
            IdTurma,
            Alteracao
          );

        try
          TAppResponse.Ok(
            Res,
            TurmaParaJson(
              Turma
            ),
            'Turma atualizada com sucesso.'
          );
        finally
          Turma.Free;
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

  {$ENDREGION}


  {$REGION 'Alterar Situação'}

  THorse.Patch(
    '/v1/certifica/instituicao/turmas/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Turma: TInstituicaoTurmaItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdTurma :=
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
          Situacao :=
            JsonString(
              Body,
              'situacao'
            );
        finally
          Body.Free;
        end;

        Turma :=
          TInstituicaoTurmaService.AlterarSituacao(
            Claims.IdInstituicao,
            IdTurma,
            Situacao
          );

        try
          TAppResponse.Ok(
            Res,
            TurmaParaJson(
              Turma
            ),
            'Situação da turma atualizada com sucesso.'
          );
        finally
          Turma.Free;
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

  {$ENDREGION}

end;

end.
