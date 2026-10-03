unit ContratoFiscalizacao.Controller;

interface

type
  TContratoFiscalizacaoController = class
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
  ContratoFiscalizacao.Model,
  ContratoFiscalizacao.Service;

function AutorizarInstituicao(const Req:THorseRequest; const Res:THorseResponse; out AClaims:TJWTClaims):Boolean;
begin
  Result:=False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;
  if (AClaims.IdInstituicao<=0) or (AClaims.IdUsuarioInstituicao<=0) then
  begin
    TAppResponse.Forbidden(Res,'Token sem contexto válido de instituição e usuário.');
    Exit;
  end;
  Result:=True;
end;

function JsonString(const AObj:TJSONObject; const ANome:string; const ADefault:string=''):string;
var V:TJSONValue;
begin
  Result:=ADefault; V:=AObj.GetValue(ANome);
  if (V<>nil) and not (V is TJSONNull) then Result:=V.Value;
end;

function ParseDate(const S:string):TDateTime;
var V:string; A,M,D:Word;
begin
  Result:=0; V:=Trim(S); if V.IsEmpty then Exit;
  if Length(V)>=10 then V:=Copy(V,1,10);
  A:=StrToIntDef(Copy(V,1,4),0); M:=StrToIntDef(Copy(V,6,2),0); D:=StrToIntDef(Copy(V,9,2),0);
  if not TryEncodeDate(A,M,D,Result) then TAppErrors.RaiseBadRequest('Data inválida. Utilize yyyy-mm-dd.');
end;

function ListaParaJson(const ALista:TContratoFiscalizacaoLista):TJSONObject;
var Arr:TJSONArray; Item:TContratoFiscalizacaoItem; Obj:TJSONObject;
begin
  Result:=TJSONObject.Create; Arr:=TJSONArray.Create;
  for Item in ALista do
  begin
    Obj:=TJSONObject.Create;
    Obj.AddPair('id',TJSONNumber.Create(Item.Id));
    Obj.AddPair('data_ocorrencia',FormatDateTime('yyyy-mm-dd',Item.DataOcorrencia));
    Obj.AddPair('tipo',Item.Tipo);
    Obj.AddPair('descricao',Item.Descricao);
    Obj.AddPair('providencia',Item.Providencia);
    Obj.AddPair('situacao',Item.Situacao);
    Obj.AddPair('registrado_por',TJSONNumber.Create(Item.RegistradoPor));
    Arr.AddElement(Obj);
  end;
  Result.AddPair('itens',Arr);
end;

class procedure TContratoFiscalizacaoController.Registry;
begin
  THorse.Get('/v1/contratos/instituicao/contratos/:id/fiscalizacoes',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Lista:TContratoFiscalizacaoLista; IdContrato:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        Lista:=TContratoFiscalizacaoService.Listar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato);
        try TAppResponse.Ok(Res,ListaParaJson(Lista),'Fiscalizações carregadas com sucesso.'); finally Lista.Free; end;
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/contratos/instituicao/contratos/:id/fiscalizacoes',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; JsonValue:TJSONValue; Body:TJSONObject; Dados:TContratoFiscalizacaoCadastro; Lista:TContratoFiscalizacaoLista; IdContrato:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        JsonValue:=TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then begin JsonValue.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
        Body:=JsonValue as TJSONObject;
        try
          Dados:=Default(TContratoFiscalizacaoCadastro);
          Dados.DataOcorrencia:=ParseDate(JsonString(Body,'data_ocorrencia'));
          Dados.Tipo:=JsonString(Body,'tipo');
          Dados.Descricao:=JsonString(Body,'descricao');
          Dados.Providencia:=JsonString(Body,'providencia');
          Dados.Situacao:=JsonString(Body,'situacao','ABERTA');
        finally Body.Free; end;
        Lista:=TContratoFiscalizacaoService.Cadastrar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato,Dados);
        try TAppResponse.Ok(Res,ListaParaJson(Lista),'Fiscalização registrada com sucesso.'); finally Lista.Free; end;
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Patch('/v1/contratos/instituicao/contratos/:id/fiscalizacoes/:fiscalizacaoId',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; JsonValue:TJSONValue; Body:TJSONObject; Situacao,Providencia:string; Lista:TContratoFiscalizacaoLista; IdContrato,IdFiscalizacao:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        IdFiscalizacao:=StrToInt64Def(Req.Params.Items['fiscalizacaoId'],0);
        JsonValue:=TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then begin JsonValue.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
        Body:=JsonValue as TJSONObject;
        try
          Situacao:=JsonString(Body,'situacao');
          Providencia:=JsonString(Body,'providencia');
        finally Body.Free; end;
        Lista:=TContratoFiscalizacaoService.AtualizarSituacao(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato,IdFiscalizacao,Situacao,Providencia);
        try TAppResponse.Ok(Res,ListaParaJson(Lista),'Fiscalização atualizada com sucesso.'); finally Lista.Free; end;
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
