unit InstituicaoCursoInstrutor.Controller;

interface

type
  TInstituicaoCursoInstrutorController = class
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
  InstituicaoCursoInstrutor.Model,
  InstituicaoCursoInstrutor.Service;

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
  const AItem: TInstituicaoCursoInstrutorItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

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
  const ALista: TInstituicaoCursoInstrutorLista
): TJSONObject;
var
  Itens: TJSONArray;
  Item: TInstituicaoCursoInstrutorItem;
begin
  Result :=
    TJSONObject.Create;

  Itens :=
    TJSONArray.Create;

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

class procedure TInstituicaoCursoInstrutorController.Registry;
begin

  {$REGION 'Listar Instrutores do Curso'}

  THorse.Get(
    '/v1/certifica/instituicao/cursos/:id_curso/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      Lista: TInstituicaoCursoInstrutorLista;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCurso :=
          StrToInt64Def(
            Req.Params.Items['id_curso'],
            0
          );

        Lista :=
          TInstituicaoCursoInstrutorService.Listar(
            Claims.IdInstituicao,
            IdCurso
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutores do curso carregados com sucesso.'
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


  {$REGION 'Vincular Instrutor ao Curso'}

  THorse.Post(
    '/v1/certifica/instituicao/cursos/:id_curso/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      IdInstrutor: Int64;
      Principal: Boolean;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Lista: TInstituicaoCursoInstrutorLista;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCurso :=
          StrToInt64Def(
            Req.Params.Items['id_curso'],
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
          TInstituicaoCursoInstrutorService.Vincular(
            Claims.IdInstituicao,
            IdCurso,
            IdInstrutor,
            Principal
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutor vinculado ao curso com sucesso.'
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
    '/v1/certifica/instituicao/cursos/:id_curso/instrutores/:id_instrutor',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      IdInstrutor: Int64;
      Principal: Boolean;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Lista: TInstituicaoCursoInstrutorLista;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCurso :=
          StrToInt64Def(
            Req.Params.Items['id_curso'],
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

        Body :=
          JsonValue as TJSONObject;

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
          TInstituicaoCursoInstrutorService.AtualizarPrincipal(
            Claims.IdInstituicao,
            IdCurso,
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


  {$REGION 'Desvincular Instrutor do Curso'}

  THorse.Delete(
    '/v1/certifica/instituicao/cursos/:id_curso/instrutores/:id_instrutor',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCurso: Int64;
      IdInstrutor: Int64;
      Lista: TInstituicaoCursoInstrutorLista;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdCurso :=
          StrToInt64Def(
            Req.Params.Items['id_curso'],
            0
          );

        IdInstrutor :=
          StrToInt64Def(
            Req.Params.Items['id_instrutor'],
            0
          );

        Lista :=
          TInstituicaoCursoInstrutorService.Desvincular(
            Claims.IdInstituicao,
            IdCurso,
            IdInstrutor
          );

        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(
              Lista
            ),
            'Instrutor desvinculado do curso com sucesso.'
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
