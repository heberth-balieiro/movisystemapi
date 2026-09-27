unit InstituicaoTurmaCriterioConclusao.Controller;

interface

type
  TInstituicaoTurmaCriterioConclusaoController = class
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
  InstituicaoTurmaCriterioConclusao.Model,
  InstituicaoTurmaCriterioConclusao.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
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
  const ADefault: string = ''
): string;
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
  const ADefault: Integer = 0
): Integer;
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
  const ADefault: Boolean = False
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  Result := SameText(Valor.Value, 'true');
end;

procedure LerConfiguracao(
  const AObj: TJSONObject;
  out ATemConfiguracao: Boolean;
  out AConfiguracao: string
);
var
  Valor: TJSONValue;
begin
  ATemConfiguracao := False;
  AConfiguracao := '';

  Valor := AObj.GetValue('configuracao');

  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  ATemConfiguracao := True;
  AConfiguracao := Valor.ToJSON;
end;

function DataHoraISO(const AData: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AData);
end;

function ConfiguracaoParaJson(
  const AItem: TInstituicaoTurmaCriterioConclusaoItem
): TJSONValue;
begin
  if not AItem.TemConfiguracao then
    Exit(TJSONNull.Create);

  Result := TJSONObject.ParseJSONValue(AItem.Configuracao);

  if Result = nil then
    Result := TJSONNull.Create;
end;

function CriterioParaJson(
  const AItem: TInstituicaoTurmaCriterioConclusaoItem
): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AItem.Id));
  Result.AddPair('id_turma', TJSONNumber.Create(AItem.IdTurma));
  Result.AddPair('tipo', AItem.Tipo);
  Result.AddPair('nome', AItem.Nome);
  Result.AddPair('obrigatorio', TJSONBool.Create(AItem.Obrigatorio));
  Result.AddPair('configuracao', ConfiguracaoParaJson(AItem));
  Result.AddPair('ordem', TJSONNumber.Create(AItem.Ordem));
  Result.AddPair('situacao', AItem.Situacao);
  Result.AddPair('criado_em', DataHoraISO(AItem.CriadoEm));
  Result.AddPair('atualizado_em', DataHoraISO(AItem.AtualizadoEm));
end;

class procedure TInstituicaoTurmaCriterioConclusaoController.Registry;
begin
  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/criterios-conclusao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      Resultado: TInstituicaoTurmaCriterioConclusaoLista;
      Item: TInstituicaoTurmaCriterioConclusaoItem;
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

        Resultado := TInstituicaoTurmaCriterioConclusaoService.Listar(
          Claims.IdInstituicao,
          IdTurma,
          Req.Query.Items['busca'],
          Req.Query.Items['tipo'],
          Req.Query.Items['situacao'],
          Pagina,
          PorPagina
        );

        try
          Itens := TJSONArray.Create;

          for Item in Resultado.Itens do
            Itens.AddElement(CriterioParaJson(Item));

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

          TAppResponse.Ok(
            Res,
            Dados,
            'Critérios de conclusão carregados com sucesso.'
          );
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
    '/v1/certifica/instituicao/turmas/:id_turma/criterios-conclusao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoTurmaCriterioConclusaoCadastro;
      Criterio: TInstituicaoTurmaCriterioConclusaoItem;
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
          Dados := Default(TInstituicaoTurmaCriterioConclusaoCadastro);
          Dados.Tipo := JsonString(Body, 'tipo');
          Dados.Nome := JsonString(Body, 'nome');
          Dados.Obrigatorio := JsonBoolean(Body, 'obrigatorio', True);
          LerConfiguracao(Body, Dados.TemConfiguracao, Dados.Configuracao);
          Dados.Ordem := JsonInteger(Body, 'ordem', 1);
        finally
          Body.Free;
        end;

        Criterio := TInstituicaoTurmaCriterioConclusaoService.Cadastrar(
          Claims.IdInstituicao,
          IdTurma,
          Dados
        );

        try
          TAppResponse.Ok(
            Res,
            CriterioParaJson(Criterio),
            'Critério de conclusão cadastrado com sucesso.'
          );
        finally
          Criterio.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/instituicao/turmas/:id_turma/criterios-conclusao/:id_criterio',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdCriterio: Int64;
      Criterio: TInstituicaoTurmaCriterioConclusaoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdCriterio := StrToInt64Def(Req.Params.Items['id_criterio'], 0);

        Criterio := TInstituicaoTurmaCriterioConclusaoService.BuscarPorId(
          Claims.IdInstituicao,
          IdTurma,
          IdCriterio
        );

        try
          TAppResponse.Ok(
            Res,
            CriterioParaJson(Criterio),
            'Critério de conclusão carregado com sucesso.'
          );
        finally
          Criterio.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/instituicao/turmas/:id_turma/criterios-conclusao/:id_criterio',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdCriterio: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoTurmaCriterioConclusaoAlteracao;
      Criterio: TInstituicaoTurmaCriterioConclusaoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdCriterio := StrToInt64Def(Req.Params.Items['id_criterio'], 0);
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoTurmaCriterioConclusaoAlteracao);
          Dados.Tipo := JsonString(Body, 'tipo');
          Dados.Nome := JsonString(Body, 'nome');
          Dados.Obrigatorio := JsonBoolean(Body, 'obrigatorio', True);
          LerConfiguracao(Body, Dados.TemConfiguracao, Dados.Configuracao);
          Dados.Ordem := JsonInteger(Body, 'ordem', 1);
        finally
          Body.Free;
        end;

        Criterio := TInstituicaoTurmaCriterioConclusaoService.Atualizar(
          Claims.IdInstituicao,
          IdTurma,
          IdCriterio,
          Dados
        );

        try
          TAppResponse.Ok(
            Res,
            CriterioParaJson(Criterio),
            'Critério de conclusão atualizado com sucesso.'
          );
        finally
          Criterio.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Patch(
    '/v1/certifica/instituicao/turmas/:id_turma/criterios-conclusao/:id_criterio/situacao',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdTurma, IdCriterio: Int64;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Situacao: string;
      Criterio: TInstituicaoTurmaCriterioConclusaoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        IdTurma := StrToInt64Def(Req.Params.Items['id_turma'], 0);
        IdCriterio := StrToInt64Def(Req.Params.Items['id_criterio'], 0);
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

        Criterio := TInstituicaoTurmaCriterioConclusaoService.AlterarSituacao(
          Claims.IdInstituicao,
          IdTurma,
          IdCriterio,
          Situacao
        );

        try
          TAppResponse.Ok(
            Res,
            CriterioParaJson(Criterio),
            'Situação do critério atualizada com sucesso.'
          );
        finally
          Criterio.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
