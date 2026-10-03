unit Contrato.Controller;

interface

type
  TContratoController = class
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
  Contrato.Model,
  Contrato.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  if (AClaims.IdInstituicao <= 0) or
     (AClaims.IdUsuarioInstituicao <= 0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido de instituição e usuário.'
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
begin
  Result := StrToIntDef(JsonString(AObj, ANome), ADefault);
end;

function JsonDouble(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Double = 0
): Double;
var
  S: string;
  FS: TFormatSettings;
begin
  Result := ADefault;
  S := Trim(JsonString(AObj, ANome));
  if S.IsEmpty then
    Exit;

  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  Result := StrToFloatDef(S, ADefault, FS);
end;

function JsonDate(
  const AObj: TJSONObject;
  const ANome: string
): TDateTime;
var
  S: string;
  Ano, Mes, Dia: Word;
begin
  Result := 0;
  S := Trim(JsonString(AObj, ANome));
  if S.IsEmpty then
    Exit;

  if Length(S) >= 10 then
    S := Copy(S, 1, 10);

  Ano := StrToIntDef(Copy(S, 1, 4), 0);
  Mes := StrToIntDef(Copy(S, 6, 2), 0);
  Dia := StrToIntDef(Copy(S, 9, 2), 0);

  if not TryEncodeDate(Ano, Mes, Dia, Result) then
    TAppErrors.RaiseBadRequest(
      'Data inválida no campo ' + ANome + '. Utilize yyyy-mm-dd.'
    );
end;

function LerCadastro(const ABody: TJSONObject): TContratoCadastro;
begin
  Result := Default(TContratoCadastro);

  Result.DocumentoContratado := JsonString(ABody, 'documento_contratado');
  Result.NomeContratado := JsonString(ABody, 'nome_contratado');
  Result.Numero := JsonString(ABody, 'numero');
  Result.NumeroExterno := JsonString(ABody, 'numero_externo');
  Result.TipoGestao := JsonString(ABody, 'tipo_gestao', 'PUBLICA');
  Result.Tipo := JsonString(ABody, 'tipo', 'SERVICO');
  Result.Titulo := JsonString(ABody, 'titulo');
  Result.Objeto := JsonString(ABody, 'objeto');
  Result.NumeroProcesso := JsonString(ABody, 'numero_processo');
  Result.AnoProcesso := JsonInteger(ABody, 'ano_processo');
  Result.OrigemContratacao := JsonString(ABody, 'origem_contratacao');
  Result.Modalidade := JsonString(ABody, 'modalidade');
  Result.NumeroLicitacao := JsonString(ABody, 'numero_licitacao');
  Result.IdentificadorPncp := JsonString(ABody, 'identificador_pncp');
  Result.UrlPncp := JsonString(ABody, 'url_pncp');
  Result.DataAssinatura := JsonDate(ABody, 'data_assinatura');
  Result.DataInicio := JsonDate(ABody, 'data_inicio');
  Result.DataFim := JsonDate(ABody, 'data_fim');
  Result.ValorInicial := JsonDouble(ABody, 'valor_inicial');
  Result.ValorAtual := JsonDouble(ABody, 'valor_atual');
  Result.Periodicidade := JsonString(ABody, 'periodicidade');
  Result.UnidadeResponsavel := JsonString(ABody, 'unidade_responsavel');
  Result.Observacao := JsonString(ABody, 'observacao');
  Result.Situacao := JsonString(ABody, 'situacao', 'RASCUNHO');
end;

function ContratoParaJson(const AContrato: TContratoItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(AContrato.Id));
  Result.AddPair('codigo_publico', AContrato.CodigoPublico);
  Result.AddPair('id_entidade', TJSONNumber.Create(AContrato.IdEntidade));
  Result.AddPair('documento_contratado', AContrato.DocumentoContratado);
  Result.AddPair('nome_contratado', AContrato.NomeContratado);
  Result.AddPair('numero', AContrato.Numero);
  Result.AddPair('numero_externo', AContrato.NumeroExterno);
  Result.AddPair('tipo_gestao', AContrato.TipoGestao);
  Result.AddPair('tipo', AContrato.Tipo);
  Result.AddPair('titulo', AContrato.Titulo);
  Result.AddPair('objeto', AContrato.Objeto);
  Result.AddPair('numero_processo', AContrato.NumeroProcesso);
  Result.AddPair('ano_processo', TJSONNumber.Create(AContrato.AnoProcesso));
  Result.AddPair('origem_contratacao', AContrato.OrigemContratacao);
  Result.AddPair('modalidade', AContrato.Modalidade);
  Result.AddPair('numero_licitacao', AContrato.NumeroLicitacao);
  Result.AddPair('identificador_pncp', AContrato.IdentificadorPncp);
  Result.AddPair('url_pncp', AContrato.UrlPncp);

  if AContrato.DataAssinatura > 0 then
    Result.AddPair('data_assinatura', FormatDateTime('yyyy-mm-dd', AContrato.DataAssinatura))
  else
    Result.AddPair('data_assinatura', TJSONNull.Create);

  Result.AddPair('data_inicio', FormatDateTime('yyyy-mm-dd', AContrato.DataInicio));
  Result.AddPair('data_fim', FormatDateTime('yyyy-mm-dd', AContrato.DataFim));
  Result.AddPair('valor_inicial', TJSONNumber.Create(AContrato.ValorInicial));
  Result.AddPair('valor_atual', TJSONNumber.Create(AContrato.ValorAtual));
  Result.AddPair('periodicidade', AContrato.Periodicidade);
  Result.AddPair('unidade_responsavel', AContrato.UnidadeResponsavel);
  Result.AddPair('observacao', AContrato.Observacao);
  Result.AddPair('situacao', AContrato.Situacao);
end;

class procedure TContratoController.Registry;
begin
  THorse.Get(
    '/v1/contratos/instituicao/contratos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TContratoLista;
      Item: TContratoItem;
      Itens: TJSONArray;
      Dados, Paginacao: TJSONObject;
      Pagina, PorPagina, TotalPaginas: Integer;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        Pagina := StrToIntDef(Req.Query.Items['page'], 1);
        PorPagina := StrToIntDef(Req.Query.Items['page_size'], 20);

        Lista := TContratoService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Req.Query.Items['busca'],
          Req.Query.Items['situacao'],
          Pagina,
          PorPagina
        );
        try
          Itens := TJSONArray.Create;
          for Item in Lista.Itens do
            Itens.AddElement(ContratoParaJson(Item));

          if Lista.Total = 0 then
            TotalPaginas := 0
          else
            TotalPaginas := (Lista.Total + Lista.PorPagina - 1) div Lista.PorPagina;

          Paginacao := TJSONObject.Create;
          Paginacao.AddPair('pagina', TJSONNumber.Create(Lista.Pagina));
          Paginacao.AddPair('por_pagina', TJSONNumber.Create(Lista.PorPagina));
          Paginacao.AddPair('total', TJSONNumber.Create(Lista.Total));
          Paginacao.AddPair('total_paginas', TJSONNumber.Create(TotalPaginas));

          Dados := TJSONObject.Create;
          Dados.AddPair('itens', Itens);
          Dados.AddPair('paginacao', Paginacao);

          TAppResponse.Ok(Res, Dados, 'Contratos carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/contratos/instituicao/contratos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Contrato: TContratoItem;
      IdContrato: Int64;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        IdContrato := StrToInt64Def(Req.Params.Items['id'], 0);
        Contrato := TContratoService.BuscarPorId(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato
        );
        try
          TAppResponse.Ok(
            Res,
            ContratoParaJson(Contrato),
            'Contrato carregado com sucesso.'
          );
        finally
          Contrato.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TContratoCadastro;
      Contrato: TContratoItem;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Cadastro := LerCadastro(Body);
        finally
          Body.Free;
        end;

        Contrato := TContratoService.Cadastrar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Cadastro
        );
        try
          TAppResponse.Ok(
            Res,
            ContratoParaJson(Contrato),
            'Contrato cadastrado com sucesso.'
          );
        finally
          Contrato.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/contratos/instituicao/contratos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Cadastro: TContratoCadastro;
      Contrato: TContratoItem;
      IdContrato: Int64;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        IdContrato := StrToInt64Def(Req.Params.Items['id'], 0);

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Cadastro := LerCadastro(Body);
        finally
          Body.Free;
        end;

        Contrato := TContratoService.Atualizar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          Cadastro
        );
        try
          TAppResponse.Ok(
            Res,
            ContratoParaJson(Contrato),
            'Contrato atualizado com sucesso.'
          );
        finally
          Contrato.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos/:id/encerrar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      IdContrato:Int64;
      JsonValue:TJSONValue;
      Body:TJSONObject;
      Motivo:string;
      Contrato:TContratoItem;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);

        JsonValue:=TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body:=JsonValue as TJSONObject;
        try
          Motivo:=JsonString(Body,'motivo');
        finally
          Body.Free;
        end;

        Contrato:=TContratoService.Encerrar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          Motivo
        );
        try
          TAppResponse.Ok(
            Res,
            ContratoParaJson(Contrato),
            'Contrato encerrado com sucesso.'
          );
        finally
          Contrato.Free;
        end;
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos/:id/cancelar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      IdContrato:Int64;
      JsonValue:TJSONValue;
      Body:TJSONObject;
      Motivo:string;
      Contrato:TContratoItem;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);

        JsonValue:=TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body:=JsonValue as TJSONObject;
        try
          Motivo:=JsonString(Body,'motivo');
        finally
          Body.Free;
        end;

        Contrato:=TContratoService.Cancelar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          Motivo
        );
        try
          TAppResponse.Ok(
            Res,
            ContratoParaJson(Contrato),
            'Contrato cancelado com sucesso.'
          );
        finally
          Contrato.Free;
        end;
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

end;

end.
