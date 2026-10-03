unit ContratoAditivo.Controller;

interface

type
  TContratoAditivoController = class
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
  ContratoAditivo.Model,
  ContratoAditivo.Service;

function AutorizarInstituicao(const Req: THorseRequest; const Res: THorseResponse; out AClaims: TJWTClaims): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;
  if (AClaims.IdInstituicao<=0) or (AClaims.IdUsuarioInstituicao<=0) then
  begin
    TAppResponse.Forbidden(Res,'Token sem contexto válido de instituição e usuário.');
    Exit;
  end;
  Result := True;
end;

function ParseDate(const S: string): TDateTime;
var
  V: string;
  A,M,D: Word;
begin
  Result := 0;
  V := Trim(S);
  if V.IsEmpty then Exit;
  if Length(V)>=10 then V:=Copy(V,1,10);
  A:=StrToIntDef(Copy(V,1,4),0);
  M:=StrToIntDef(Copy(V,6,2),0);
  D:=StrToIntDef(Copy(V,9,2),0);
  if not TryEncodeDate(A,M,D,Result) then TAppErrors.RaiseBadRequest('Data inválida. Utilize yyyy-mm-dd.');
end;

function JsonString(const AObj:TJSONObject; const ANome:string):string;
var V:TJSONValue;
begin
  Result:=''; V:=AObj.GetValue(ANome);
  if (V<>nil) and not (V is TJSONNull) then Result:=V.Value;
end;

function JsonDouble(const AObj:TJSONObject; const ANome:string):Double;
var V:TJSONValue; FS:TFormatSettings; S:string;
begin
  Result:=0; V:=AObj.GetValue(ANome); if (V=nil) or (V is TJSONNull) then Exit;
  S:=StringReplace(Trim(V.Value),',','.',[rfReplaceAll]);
  FS:=TFormatSettings.Create; FS.DecimalSeparator:='.';
  Result:=StrToFloatDef(S,0,FS);
end;

function ListaParaJson(const ALista:TContratoAditivoLista):TJSONObject;
var Arr:TJSONArray; Item:TContratoAditivoItem; Obj:TJSONObject;
begin
  Result:=TJSONObject.Create; Arr:=TJSONArray.Create;
  for Item in ALista do
  begin
    Obj:=TJSONObject.Create;
    Obj.AddPair('id',TJSONNumber.Create(Item.Id));
    Obj.AddPair('numero',Item.Numero);
    Obj.AddPair('tipo',Item.Tipo);
    if Item.DataAssinatura>0 then Obj.AddPair('data_assinatura',FormatDateTime('yyyy-mm-dd',Item.DataAssinatura)) else Obj.AddPair('data_assinatura',TJSONNull.Create);
    if Item.NovaDataFim>0 then Obj.AddPair('nova_data_fim',FormatDateTime('yyyy-mm-dd',Item.NovaDataFim)) else Obj.AddPair('nova_data_fim',TJSONNull.Create);
    Obj.AddPair('valor_acrescimo',TJSONNumber.Create(Item.ValorAcrescimo));
    Obj.AddPair('valor_supressao',TJSONNumber.Create(Item.ValorSupressao));
    Obj.AddPair('justificativa',Item.Justificativa);
    Arr.AddElement(Obj);
  end;
  Result.AddPair('itens',Arr);
end;

class procedure TContratoAditivoController.Registry;
begin
  THorse.Get('/v1/contratos/instituicao/contratos/:id/aditivos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Lista:TContratoAditivoLista; IdContrato:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        Lista:=TContratoAditivoService.Listar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato);
        try TAppResponse.Ok(Res,ListaParaJson(Lista),'Aditivos carregados com sucesso.'); finally Lista.Free; end;
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/contratos/instituicao/contratos/:id/aditivos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; JsonValue:TJSONValue; Body:TJSONObject; Dados:TContratoAditivoCadastro; Lista:TContratoAditivoLista; IdContrato:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        JsonValue:=TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then begin JsonValue.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
        Body:=JsonValue as TJSONObject;
        try
          Dados:=Default(TContratoAditivoCadastro);
          Dados.Numero:=JsonString(Body,'numero');
          Dados.Tipo:=JsonString(Body,'tipo');
          Dados.DataAssinatura:=ParseDate(JsonString(Body,'data_assinatura'));
          Dados.NovaDataFim:=ParseDate(JsonString(Body,'nova_data_fim'));
          Dados.ValorAcrescimo:=JsonDouble(Body,'valor_acrescimo');
          Dados.ValorSupressao:=JsonDouble(Body,'valor_supressao');
          Dados.Justificativa:=JsonString(Body,'justificativa');
        finally Body.Free; end;
        Lista:=TContratoAditivoService.Cadastrar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato,Dados);
        try TAppResponse.Ok(Res,ListaParaJson(Lista),'Aditivo incluído com sucesso.'); finally Lista.Free; end;
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
