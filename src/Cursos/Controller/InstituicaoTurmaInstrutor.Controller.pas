unit InstituicaoTurmaInstrutor.Controller;

interface

type
  TInstituicaoTurmaInstrutorController = class
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
  InstituicaoTurmaInstrutor.Model,
  InstituicaoTurmaInstrutor.Service;

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

function JsonInt64(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Int64 = 0
): Int64;
var
  Valor: TJSONValue;
begin
  Result := ADefault;

  Valor := AObj.GetValue(ANome);

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

  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    SameText(
      Valor.Value,
      'true'
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

function ItemParaJson(
  const AItem: TInstituicaoTurmaInstrutorItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id_instrutor',
    TJSONNumber.Create(
      AItem.IdInstrutor
    )
  );

  Result.AddPair(
    'nome',
    AItem.InstrutorNome
  );

  AddNullableString(
    Result,
    'email',
    AItem.InstrutorEmail
  );

  AddNullableString(
    Result,
    'telefone',
    AItem.InstrutorTelefone
  );

  Result.AddPair(
    'situacao',
    AItem.InstrutorSituacao
  );

  Result.AddPair(
    'principal',
    TJSONBool.Create(
      AItem.Principal
    )
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AItem.CriadoEm
    )
  );
end;

function ListaParaJson(
  const ALista: TInstituicaoTurmaInstrutorLista
): TJSONObject;
var
  Itens: TJSONArray;
  Item: TInstituicaoTurmaInstrutorItem;
begin
  Result := TJSONObject.Create;

  Itens := TJSONArray.Create;

  for Item in ALista.Itens do
    Itens.AddElement(
      ItemParaJson(Item)
    );

  Result.AddPair(
    'itens',
    Itens
  );

  Result.AddPair(
    'total',
    TJSONNumber.Create(
      ALista.Itens.Count
    )
  );
end;

class procedure TInstituicaoTurmaInstrutorController.Registry;
begin

  {$REGION 'Listar Instrutores da Turma'}

  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Lista: TInstituicaoTurmaInstrutorLista;
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

        Lista :=
          TInstituicaoTurmaInstrutorService.Listar(
            Claims.IdInstituicao,
            IdTurma
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutores da turma carregados com sucesso.'
          );
        finally
          Lista.Free;
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


  {$REGION 'Vincular Instrutor à Turma'}

  THorse.Post(
    '/v1/certifica/instituicao/turmas/:id_turma/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdInstrutor: Int64;
      Principal: Boolean;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Lista: TInstituicaoTurmaInstrutorLista;
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

        Body := JsonValue as TJSONObject;

        try
          IdInstrutor :=
            JsonInt64(
              Body,
              'id_instrutor'
            );

          Principal :=
            JsonBoolean(
              Body,
              'principal',
              False
            );

        finally
          Body.Free;
        end;

        Lista :=
          TInstituicaoTurmaInstrutorService.Vincular(
            Claims.IdInstituicao,
            IdTurma,
            IdInstrutor,
            Principal
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutor vinculado à turma com sucesso.'
          );
        finally
          Lista.Free;
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


  {$REGION 'Atualizar Principal'}

  THorse.Put(
    '/v1/certifica/instituicao/turmas/:id_turma/instrutores/:id_instrutor',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdInstrutor: Int64;
      Principal: Boolean;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Lista: TInstituicaoTurmaInstrutorLista;
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

        IdInstrutor :=
          StrToInt64Def(
            Req.Params.Items['id_instrutor'],
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

        Body := JsonValue as TJSONObject;

        try
          Principal :=
            JsonBoolean(
              Body,
              'principal',
              False
            );
        finally
          Body.Free;
        end;

        Lista :=
          TInstituicaoTurmaInstrutorService.AtualizarPrincipal(
            Claims.IdInstituicao,
            IdTurma,
            IdInstrutor,
            Principal
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Vínculo do instrutor atualizado com sucesso.'
          );
        finally
          Lista.Free;
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


  {$REGION 'Desvincular Instrutor da Turma'}

  THorse.Delete(
    '/v1/certifica/instituicao/turmas/:id_turma/instrutores/:id_instrutor',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      IdInstrutor: Int64;
      Lista: TInstituicaoTurmaInstrutorLista;
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

        IdInstrutor :=
          StrToInt64Def(
            Req.Params.Items['id_instrutor'],
            0
          );

        Lista :=
          TInstituicaoTurmaInstrutorService.Desvincular(
            Claims.IdInstituicao,
            IdTurma,
            IdInstrutor
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutor desvinculado da turma com sucesso.'
          );
        finally
          Lista.Free;
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
