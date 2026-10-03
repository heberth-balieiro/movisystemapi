unit ContratoProjecao.Controller;

interface

type
  TContratoProjecaoController = class
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
  ContratoProjecao.Model,
  ContratoProjecao.Service;

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

function ParseDate(const AValue: string): TDateTime;
var
  S: string;
  Ano, Mes, Dia: Word;
begin
  Result := 0;
  S := Trim(AValue);
  if Length(S) >= 10 then
    S := Copy(S, 1, 10);

  Ano := StrToIntDef(Copy(S, 1, 4), 0);
  Mes := StrToIntDef(Copy(S, 6, 2), 0);
  Dia := StrToIntDef(Copy(S, 9, 2), 1);

  if not TryEncodeDate(Ano, Mes, Dia, Result) then
    TAppErrors.RaiseBadRequest('Competência inválida. Utilize yyyy-mm-dd.');
end;

function JsonDouble(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Double = 0
): Double;
var
  Valor: TJSONValue;
  S: string;
  FS: TFormatSettings;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);
  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;

  S := StringReplace(Trim(Valor.Value), ',', '.', [rfReplaceAll]);
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';
  Result := StrToFloatDef(S, ADefault, FS);
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  Valor := AObj.GetValue(ANome);
  if (Valor <> nil) and not (Valor is TJSONNull) then
    Result := Valor.Value;
end;

function ListaParaJson(const ALista: TContratoProjecaoLista): TJSONObject;
var
  Arr: TJSONArray;
  Item: TContratoProjecaoItem;
  Obj: TJSONObject;
  TotalPrevisto, TotalRealizado: Double;
begin
  Result := TJSONObject.Create;
  Arr := TJSONArray.Create;
  TotalPrevisto := 0;
  TotalRealizado := 0;

  for Item in ALista do
  begin
    Obj := TJSONObject.Create;
    Obj.AddPair('id', TJSONNumber.Create(Item.Id));
    Obj.AddPair('competencia', FormatDateTime('yyyy-mm-dd', Item.Competencia));
    Obj.AddPair('valor_previsto', TJSONNumber.Create(Item.ValorPrevisto));
    Obj.AddPair('valor_realizado', TJSONNumber.Create(Item.ValorRealizado));
    Obj.AddPair('saldo', TJSONNumber.Create(Item.ValorPrevisto - Item.ValorRealizado));
    Obj.AddPair('origem', Item.Origem);
    Obj.AddPair('observacao', Item.Observacao);
    Arr.AddElement(Obj);

    TotalPrevisto := TotalPrevisto + Item.ValorPrevisto;
    TotalRealizado := TotalRealizado + Item.ValorRealizado;
  end;

  Result.AddPair('itens', Arr);
  Result.AddPair('total_previsto', TJSONNumber.Create(TotalPrevisto));
  Result.AddPair('total_realizado', TJSONNumber.Create(TotalRealizado));
  Result.AddPair('saldo_projetado', TJSONNumber.Create(TotalPrevisto - TotalRealizado));
end;

class procedure TContratoProjecaoController.Registry;
begin
  THorse.Get(
    '/v1/contratos/instituicao/contratos/:id/projecoes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdContrato: Int64;
      Lista: TContratoProjecaoLista;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        IdContrato := StrToInt64Def(Req.Params.Items['id'], 0);
        Lista := TContratoProjecaoService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato
        );
        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(Lista),
            'Projeção contratual carregada com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos/:id/projecoes/recalcular',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdContrato: Int64;
      Lista: TContratoProjecaoLista;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        IdContrato := StrToInt64Def(Req.Params.Items['id'], 0);
        Lista := TContratoProjecaoService.Recalcular(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato
        );
        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(Lista),
            'Projeção contratual recalculada com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/contratos/instituicao/contratos/:id/projecoes/:competencia',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdContrato: Int64;
      Competencia: TDateTime;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      ValorPrevisto, ValorRealizado: Double;
      Observacao: string;
      Lista: TContratoProjecaoLista;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;

        IdContrato := StrToInt64Def(Req.Params.Items['id'], 0);
        Competencia := ParseDate(Req.Params.Items['competencia']);

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          ValorPrevisto := JsonDouble(Body, 'valor_previsto');
          ValorRealizado := JsonDouble(Body, 'valor_realizado');
          Observacao := JsonString(Body, 'observacao');
        finally
          Body.Free;
        end;

        Lista := TContratoProjecaoService.AjustarManual(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          Competencia,
          ValorPrevisto,
          ValorRealizado,
          Observacao
        );
        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(Lista),
            'Projeção ajustada com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
