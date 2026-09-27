unit InstituicaoInstrutor.Controller;

interface

type
  TInstituicaoInstrutorController = class
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
  InstituicaoInstrutor.Model,
  InstituicaoInstrutor.Service;

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

function InstrutorParaJson(
  const AInstrutor: TInstituicaoInstrutorItem
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AInstrutor.Id
    )
  );

  if AInstrutor.TemParticipante then
  begin
    Result.AddPair(
      'id_participante',
      TJSONNumber.Create(
        AInstrutor.IdParticipante
      )
    );

    AddNullableString(
      Result,
      'participante_nome',
      AInstrutor.ParticipanteNome
    );
  end
  else
  begin
    Result.AddPair(
      'id_participante',
      TJSONNull.Create
    );

    Result.AddPair(
      'participante_nome',
      TJSONNull.Create
    );
  end;

  Result.AddPair(
    'codigo_publico',
    AInstrutor.CodigoPublico
  );

  Result.AddPair(
    'nome',
    AInstrutor.Nome
  );

  AddNullableString(
    Result,
    'email',
    AInstrutor.Email
  );

  AddNullableString(
    Result,
    'telefone',
    AInstrutor.Telefone
  );

  AddNullableString(
    Result,
    'biografia',
    AInstrutor.Biografia
  );

  Result.AddPair(
    'situacao',
    AInstrutor.Situacao
  );

  Result.AddPair(
    'criado_em',
    DataHoraISO(
      AInstrutor.CriadoEm
    )
  );

  Result.AddPair(
    'atualizado_em',
    DataHoraISO(
      AInstrutor.AtualizadoEm
    )
  );
end;

class procedure TInstituicaoInstrutorController.Registry;
begin

  {$REGION 'Listar Instrutores'}

  THorse.Get(
    '/v1/certifica/instituicao/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Resultado: TInstituicaoInstrutorLista;
      Instrutor: TInstituicaoInstrutorItem;
      Dados: TJSONObject;
      Paginacao: TJSONObject;
      Itens: TJSONArray;
      Busca: string;
      Situacao: string;
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
          TInstituicaoInstrutorService.Listar(
            Claims.IdInstituicao,
            Busca,
            Situacao,
            Pagina,
            PorPagina
          );

        try
          Itens :=
            TJSONArray.Create;

          for Instrutor in Resultado.Itens do
            Itens.AddElement(
              InstrutorParaJson(
                Instrutor
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
            'Instrutores carregados com sucesso.'
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


  {$REGION 'Buscar Instrutor'}

  THorse.Get(
    '/v1/certifica/instituicao/instrutores/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInstrutor: Int64;
      Instrutor: TInstituicaoInstrutorItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInstrutor :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        Instrutor :=
          TInstituicaoInstrutorService.BuscarPorId(
            Claims.IdInstituicao,
            IdInstrutor
          );

        try
          TAppResponse.Ok(
            Res,
            InstrutorParaJson(
              Instrutor
            ),
            'Instrutor carregado com sucesso.'
          );
        finally
          Instrutor.Free;
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


  {$REGION 'Cadastrar Instrutor'}

  THorse.Post(
    '/v1/certifica/instituicao/instrutores',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TInstituicaoInstrutorCadastro;
      Instrutor: TInstituicaoInstrutorItem;
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
          Cadastro :=
            Default(
              TInstituicaoInstrutorCadastro
            );

          Cadastro.IdParticipante :=
            JsonInt64(
              Body,
              'id_participante'
            );

          Cadastro.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Cadastro.Email :=
            JsonString(
              Body,
              'email'
            );

          Cadastro.Telefone :=
            JsonString(
              Body,
              'telefone'
            );

          Cadastro.Biografia :=
            JsonString(
              Body,
              'biografia'
            );

        finally
          Body.Free;
        end;

        Instrutor :=
          TInstituicaoInstrutorService.Cadastrar(
            Claims.IdInstituicao,
            Cadastro
          );

        try
          TAppResponse.Ok(
            Res,
            InstrutorParaJson(
              Instrutor
            ),
            'Instrutor cadastrado com sucesso.'
          );
        finally
          Instrutor.Free;
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


  {$REGION 'Atualizar Instrutor'}

  THorse.Put(
    '/v1/certifica/instituicao/instrutores/:id',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInstrutor: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Alteracao: TInstituicaoInstrutorAlteracao;
      Instrutor: TInstituicaoInstrutorItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInstrutor :=
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
              TInstituicaoInstrutorAlteracao
            );

          Alteracao.IdParticipante :=
            JsonInt64(
              Body,
              'id_participante'
            );

          Alteracao.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Alteracao.Email :=
            JsonString(
              Body,
              'email'
            );

          Alteracao.Telefone :=
            JsonString(
              Body,
              'telefone'
            );

          Alteracao.Biografia :=
            JsonString(
              Body,
              'biografia'
            );

        finally
          Body.Free;
        end;

        Instrutor :=
          TInstituicaoInstrutorService.Atualizar(
            Claims.IdInstituicao,
            IdInstrutor,
            Alteracao
          );

        try
          TAppResponse.Ok(
            Res,
            InstrutorParaJson(
              Instrutor
            ),
            'Instrutor atualizado com sucesso.'
          );
        finally
          Instrutor.Free;
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
    '/v1/certifica/instituicao/instrutores/:id/situacao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdInstrutor: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Instrutor: TInstituicaoInstrutorItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        IdInstrutor :=
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

        Instrutor :=
          TInstituicaoInstrutorService.AlterarSituacao(
            Claims.IdInstituicao,
            IdInstrutor,
            Situacao
          );

        try
          TAppResponse.Ok(
            Res,
            InstrutorParaJson(
              Instrutor
            ),
            'Situação do instrutor atualizada com sucesso.'
          );
        finally
          Instrutor.Free;
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
