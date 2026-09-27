unit InstituicaoTurmaEncontro.Controller;

interface

type
  TInstituicaoTurmaEncontroController = class
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
  InstituicaoTurmaEncontro.Model,
  InstituicaoTurmaEncontro.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(Res, 'Token sem contexto de instituição.');
    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function JsonInteger(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Integer = 0): Integer;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := StrToIntDef(Valor.Value, ADefault);
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean = False): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := SameText(Valor.Value, 'true');
end;

function JsonDateTimeObrigatorio(
  const AObj: TJSONObject;
  const ANome, AMensagem: string): TDateTime;
var
  Valor: string;
begin
  Valor := Trim(JsonString(AObj, ANome));

  if Valor.IsEmpty then
    TAppErrors.RaiseBadRequest(AMensagem);

  try
    Result := ISO8601ToDate(Valor, False);
  except
    TAppErrors.RaiseBadRequest(
      'Formato inválido para ' + ANome + '. Utilize ISO 8601.');
    Result := 0;
  end;
end;

procedure AddNullableString(
  const AObj: TJSONObject;
  const ANome, AValor: string);
begin
  if Trim(AValor).IsEmpty then
    AObj.AddPair(ANome, TJSONNull.Create)
  else
    AObj.AddPair(ANome, AValor);
end;

function DataHoraISO(const AData: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AData);
end;

function EncontroParaJson(
  const AItem: TInstituicaoTurmaEncontroItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('titulo', AItem.Titulo);
  AddNullableString(Result, 'descricao', AItem.Descricao);
  Result.AddPair('data_hora_inicio', DataHoraISO(AItem.DataHoraInicio));
  Result.AddPair('data_hora_fim', DataHoraISO(AItem.DataHoraFim));

  if AItem.TemCargaHoraria then
    Result.AddPair('carga_horaria_minutos', TJSONNumber.Create(AItem.CargaHorariaMinutos))
  else
    Result.AddPair('carga_horaria_minutos', TJSONNull.Create);

  AddNullableString(Result, 'local', AItem.Local);
  AddNullableString(Result, 'url_online', AItem.UrlOnline);
  Result.AddPair('obrigatorio', TJSONBool.Create(AItem.Obrigatorio));
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('criado_em', DataHoraISO(AItem.CriadoEm));
  Result.AddPair('atualizado_em', DataHoraISO(AItem.AtualizadoEm));
end;

class procedure TInstituicaoTurmaEncontroController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Resultado: TInstituicaoTurmaEncontroLista;
      Item: TInstituicaoTurmaEncontroItem;
      Dados, Paginacao: TJSONObject;
      Itens: TJSONArray;
      Pagina, PorPagina, TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        Pagina := StrToIntDef(Req.Query.Items['page'], 1);
        PorPagina := StrToIntDef(Req.Query.Items['page_size'], 20);

        Resultado := TInstituicaoTurmaEncontroService.Listar(
          Claims.IdInstituicao,
          IdTurma,
          Req.Query.Items['busca'],
          Req.Query.Items['situacao'],
          Pagina,
          PorPagina
        );

        try
          Itens := TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(EncontroParaJson(Item));

          if Resultado.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas := (Resultado.Total + Resultado.PorPagina - 1) div Resultado.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Resultado.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Resultado.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Resultado.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Encontros carregados com sucesso.');
        finally
          Resultado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoTurmaEncontroCadastro;
      Encontro: TInstituicaoTurmaEncontroItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoTurmaEncontroCadastro);
          Dados.Titulo := JsonString(Body, 'titulo');
          Dados.Descricao := JsonString(Body, 'descricao');
          Dados.DataHoraInicio := JsonDateTimeObrigatorio(
            Body, 'data_hora_inicio', 'Informe a data/hora de início.');
          Dados.DataHoraFim := JsonDateTimeObrigatorio(
            Body, 'data_hora_fim', 'Informe a data/hora de término.');
          Dados.CargaHorariaMinutos := JsonInteger(Body, 'carga_horaria_minutos', 0);
          Dados.Local := JsonString(Body, 'local');
          Dados.UrlOnline := JsonString(Body, 'url_online');
          Dados.Obrigatorio := JsonBoolean(Body, 'obrigatorio', True);
        finally
          Body.Free;
        end;

        Encontro := TInstituicaoTurmaEncontroService.Cadastrar(
          Claims.IdInstituicao, IdTurma, Dados);

        try
          TAppResponse.Ok(Res, EncontroParaJson(Encontro), 'Encontro cadastrado com sucesso.');
        finally
          Encontro.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdEncontro: Int64;
      Encontro: TInstituicaoTurmaEncontroItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdEncontro := StrToInt64Def(Req.Params.Items['id_encontro'], 0);

        Encontro := TInstituicaoTurmaEncontroService.BuscarPorId(
          Claims.IdInstituicao, IdTurma, IdEncontro);

        try
          TAppResponse.Ok(Res, EncontroParaJson(Encontro), 'Encontro carregado com sucesso.');
        finally
          Encontro.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdEncontro: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoTurmaEncontroAlteracao;
      Encontro: TInstituicaoTurmaEncontroItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdEncontro := StrToInt64Def(Req.Params.Items['id_encontro'], 0);
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoTurmaEncontroAlteracao);
          Dados.Titulo := JsonString(Body, 'titulo');
          Dados.Descricao := JsonString(Body, 'descricao');
          Dados.DataHoraInicio := JsonDateTimeObrigatorio(
            Body, 'data_hora_inicio', 'Informe a data/hora de início.');
          Dados.DataHoraFim := JsonDateTimeObrigatorio(
            Body, 'data_hora_fim', 'Informe a data/hora de término.');
          Dados.CargaHorariaMinutos := JsonInteger(Body, 'carga_horaria_minutos', 0);
          Dados.Local := JsonString(Body, 'local');
          Dados.UrlOnline := JsonString(Body, 'url_online');
          Dados.Obrigatorio := JsonBoolean(Body, 'obrigatorio', True);
        finally
          Body.Free;
        end;

        Encontro := TInstituicaoTurmaEncontroService.Atualizar(
          Claims.IdInstituicao, IdTurma, IdEncontro, Dados);

        try
          TAppResponse.Ok(Res, EncontroParaJson(Encontro), 'Encontro atualizado com sucesso.');
        finally
          Encontro.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Patch(
    '/v1/certifica/instituicao/turmas/:id_turma/encontros/:id_encontro/situacao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdEncontro: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Encontro: TInstituicaoTurmaEncontroItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdEncontro := StrToInt64Def(Req.Params.Items['id_encontro'], 0);
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Situacao := JsonString(Body, 'situacao');
        finally
          Body.Free;
        end;

        Encontro := TInstituicaoTurmaEncontroService.AlterarSituacao(
          Claims.IdInstituicao, IdTurma, IdEncontro, Situacao);

        try
          TAppResponse.Ok(Res, EncontroParaJson(Encontro),
            'Situação do encontro atualizada com sucesso.');
        finally
          Encontro.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
