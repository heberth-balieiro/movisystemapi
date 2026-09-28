unit InstituicaoPresenca.Controller;

interface

type
  TInstituicaoPresencaController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  System.Generics.Collections,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoPermissao.Service,
  InstituicaoPresenca.Model,
  InstituicaoPresenca.Service;

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

procedure JsonNullableInteger(
  const AObj: TJSONObject;
  const ANome: string;
  out ATemValor: Boolean;
  out AValor: Integer
);
var
  Valor: TJSONValue;
begin
  ATemValor := False;
  AValor := 0;

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  AValor :=
    StrToIntDef(
      Valor.Value,
      -1
    );

  if AValor < 0 then
    TAppErrors.RaiseBadRequest(
      'Valor inválido para ' +
      ANome +
      '.'
    );

  ATemValor := True;
end;

procedure JsonNullableDateTime(
  const AObj: TJSONObject;
  const ANome: string;
  out ATemValor: Boolean;
  out AValor: TDateTime
);
var
  JsonValor: TJSONValue;
  Texto: string;
begin
  ATemValor := False;
  AValor := 0;

  JsonValor :=
    AObj.GetValue(
      ANome
    );

  if (JsonValor = nil) or
     (JsonValor is TJSONNull) then
    Exit;

  Texto :=
    Trim(
      JsonValor.Value
    );

  if Texto.IsEmpty then
    Exit;

  try
    AValor :=
      ISO8601ToDate(
        Texto,
        False
      );
  except
    TAppErrors.RaiseBadRequest(
      'Formato inválido para ' +
      ANome +
      '. Utilize ISO 8601.'
    );

    AValor := 0;
  end;

  ATemValor := True;
end;

function LerRegistro(
  const AObj: TJSONObject;
  const AIdInscricaoPadrao: Int64 = 0
): TInstituicaoPresencaRegistro;
begin
  Result :=
    Default(
      TInstituicaoPresencaRegistro
    );

  Result.IdInscricao :=
    JsonInt64(
      AObj,
      'id_inscricao',
      AIdInscricaoPadrao
    );

  Result.Situacao :=
    JsonString(
      AObj,
      'situacao'
    );

  JsonNullableDateTime(
    AObj,
    'checkin_em',
    Result.TemCheckinEm,
    Result.CheckinEm
  );

  JsonNullableDateTime(
    AObj,
    'checkout_em',
    Result.TemCheckoutEm,
    Result.CheckoutEm
  );

  JsonNullableInteger(
    AObj,
    'minutos_presentes',
    Result.TemMinutosPresentes,
    Result.MinutosPresentes
  );

  Result.Justificativa :=
    JsonString(
      AObj,
      'justificativa'
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

function PresencaParaJson(
  const AItem: TInstituicaoPresencaItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  if AItem.TemPresenca then
    Result.AddPair(
      'id',
      TJSONNumber.Create(
        AItem.Id
      )
    )
  else
    Result.AddPair(
      'id',
      TJSONNull.Create
    );

  Result.AddPair(
    'registrada',
    TJSONBool.Create(
      AItem.TemPresenca
    )
  );

  Result.AddPair(
    'id_turma',
    TJSONNumber.Create(
      AItem.IdTurma
    )
  );

  Result.AddPair(
    'id_encontro',
    TJSONNumber.Create(
      AItem.IdEncontro
    )
  );

  Result.AddPair(
    'encontro_titulo',
    AItem.EncontroTitulo
  );

  Result.AddPair(
    'encontro_inicio',
    DataHoraISO(
      AItem.EncontroInicio
    )
  );

  Result.AddPair(
    'encontro_fim',
    DataHoraISO(
      AItem.EncontroFim
    )
  );

  Result.AddPair(
    'id_inscricao',
    TJSONNumber.Create(
      AItem.IdInscricao
    )
  );

  Result.AddPair(
    'inscricao_situacao',
    AItem.InscricaoSituacao
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

  AddNullableString(
    Result,
    'situacao',
    AItem.Situacao
  );

  AddNullableDateTime(
    Result,
    'checkin_em',
    AItem.TemCheckinEm,
    AItem.CheckinEm
  );

  AddNullableDateTime(
    Result,
    'checkout_em',
    AItem.TemCheckoutEm,
    AItem.CheckoutEm
  );

  if AItem.TemMinutosPresentes then
    Result.AddPair(
      'minutos_presentes',
      TJSONNumber.Create(
        AItem.MinutosPresentes
      )
    )
  else
    Result.AddPair(
      'minutos_presentes',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'justificativa',
    AItem.Justificativa
  );

  if AItem.TemRegistradoPor then
    Result.AddPair(
      'registrado_por',
      TJSONNumber.Create(
        AItem.RegistradoPor
      )
    )
  else
    Result.AddPair(
      'registrado_por',
      TJSONNull.Create
    );

  AddNullableString(
    Result,
    'registrado_por_nome',
    AItem.RegistradoPorNome
  );

  AddNullableDateTime(
    Result,
    'criado_em',
    AItem.TemCriadoEm,
    AItem.CriadoEm
  );

  AddNullableDateTime(
    Result,
    'atualizado_em',
    AItem.TemAtualizadoEm,
    AItem.AtualizadoEm
  );
end;

class procedure TInstituicaoPresencaController.Registry;
begin

  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/presencas',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdEncontro: Int64;
      Pagina: Integer;
      PorPagina: Integer;
      TotalPaginas: Integer;
      Resultado: TInstituicaoPresencaLista;
      Item: TInstituicaoPresencaItem;
      Itens: TJSONArray;
      Paginacao: TJSONObject;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        TInstituicaoPermissaoService.Exigir(Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao, 'presenca.visualizar');

        IdTurma :=
          StrToInt64Def(
            Req.Params.Items['id_turma'],
            0
          );

        IdEncontro :=
          StrToInt64Def(
            Req.Params.Items['id_encontro'],
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
            50
          );

        Resultado :=
          TInstituicaoPresencaService.ListarPorEncontro(
            Claims.IdInstituicao,
            IdTurma,
            IdEncontro,
            Req.Query.Items['busca'],
            Req.Query.Items['situacao'],
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(
              PresencaParaJson(
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
            'Presenças carregadas com sucesso.'
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


  THorse.Put(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/presencas/:id_inscricao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdEncontro: Int64;
      IdInscricao: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Registro: TInstituicaoPresencaRegistro;
      Presenca: TInstituicaoPresencaItem;
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
            Req.Params.Items['id_turma'],
            0
          );

        IdEncontro :=
          StrToInt64Def(
            Req.Params.Items['id_encontro'],
            0
          );

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items['id_inscricao'],
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
          Registro :=
            LerRegistro(
              Body,
              IdInscricao
            );

          Registro.IdInscricao :=
            IdInscricao;

        finally
          Body.Free;
        end;

        Presenca :=
          TInstituicaoPresencaService.Salvar(
            Claims.IdInstituicao,
            IdTurma,
            IdEncontro,
            Claims.IdUsuarioInstituicao,
            Registro
          );

        try
          TAppResponse.Ok(
            Res,
            PresencaParaJson(
              Presenca
            ),
            'Presença salva com sucesso.'
          );

        finally
          Presenca.Free;
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
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/presencas',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdEncontro: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      ArrayValue: TJSONValue;
      ArrayItens: TJSONArray;
      ItemValue: TJSONValue;
      ItemObj: TJSONObject;
      Lista: TInstituicaoPresencaRegistroLista;
      Registro: TInstituicaoPresencaRegistro;
      Dados: TJSONObject;
      I: Integer;
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
            Req.Params.Items['id_turma'],
            0
          );

        IdEncontro :=
          StrToInt64Def(
            Req.Params.Items['id_encontro'],
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

        Lista :=
          TInstituicaoPresencaRegistroLista.Create;

        try
          ArrayValue :=
            Body.GetValue(
              'itens'
            );

          if not (ArrayValue is TJSONArray) then
            TAppErrors.RaiseBadRequest(
              'Informe o array itens.'
            );

          ArrayItens :=
            ArrayValue as TJSONArray;

          for I := 0 to ArrayItens.Count - 1 do
          begin
            ItemValue :=
              ArrayItens.Items[I];

            if not (ItemValue is TJSONObject) then
              TAppErrors.RaiseBadRequest(
                'Item de presença inválido.'
              );

            ItemObj :=
              ItemValue as TJSONObject;

            Registro :=
              LerRegistro(
                ItemObj
              );

            Lista.Add(
              Registro
            );
          end;

          TInstituicaoPresencaService.SalvarLote(
            Claims.IdInstituicao,
            IdTurma,
            IdEncontro,
            Claims.IdUsuarioInstituicao,
            Lista
          );

          Dados :=
            TJSONObject.Create;

          Dados.AddPair(
            'salvos',
            TJSONNumber.Create(
              Lista.Count
            )
          );

          TAppResponse.Ok(
            Res,
            Dados,
            'Presenças salvas com sucesso.'
          );

        finally
          Lista.Free;
          Body.Free;
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
    '/v1/certifica/instituicao/inscricoes/:id_inscricao/presencas',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInscricao: Int64;
      Resultado: TObjectList<TInstituicaoPresencaItem>;
      Item: TInstituicaoPresencaItem;
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

        TInstituicaoPermissaoService.Exigir(Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao, 'presenca.visualizar');

        IdInscricao :=
          StrToInt64Def(
            Req.Params.Items['id_inscricao'],
            0
          );

        Resultado :=
          TInstituicaoPresencaService.ListarPorInscricao(
            Claims.IdInstituicao,
            IdInscricao
          );

        try
          Itens :=
            TJSONArray.Create;

          for Item in Resultado do
            Itens.AddElement(
              PresencaParaJson(
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
            'Presenças da inscrição carregadas com sucesso.'
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

end;

end.
