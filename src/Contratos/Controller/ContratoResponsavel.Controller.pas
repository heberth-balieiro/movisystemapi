unit ContratoResponsavel.Controller;

interface

type
  TContratoResponsavelController = class
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
  ContratoResponsavel.Model,
  ContratoResponsavel.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
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

function ParseDate(const AValue: string): TDateTime;
var
  S: string;
  A,M,D: Word;
begin
  Result := 0;
  S := Trim(AValue);
  if S.IsEmpty then Exit;
  if Length(S)>=10 then S:=Copy(S,1,10);
  A:=StrToIntDef(Copy(S,1,4),0);
  M:=StrToIntDef(Copy(S,6,2),0);
  D:=StrToIntDef(Copy(S,9,2),0);
  if not TryEncodeDate(A,M,D,Result) then
    TAppErrors.RaiseBadRequest('Data inválida. Utilize yyyy-mm-dd.');
end;

function ListaParaJson(const ALista: TContratoResponsavelLista): TJSONObject;
var
  Arr: TJSONArray;
  Item: TContratoResponsavelItem;
  Obj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Arr := TJSONArray.Create;
  for Item in ALista do
  begin
    Obj := TJSONObject.Create;
    Obj.AddPair('id',TJSONNumber.Create(Item.Id));
    if Item.IdUsuarioInstituicao>0 then
      Obj.AddPair('id_usuario_instituicao',TJSONNumber.Create(Item.IdUsuarioInstituicao))
    else
      Obj.AddPair('id_usuario_instituicao',TJSONNull.Create);
    Obj.AddPair('nome',Item.Nome);
    Obj.AddPair('funcao',Item.Funcao);
    Obj.AddPair('numero_designacao',Item.NumeroDesignacao);
    if Item.DataInicio>0 then Obj.AddPair('data_inicio',FormatDateTime('yyyy-mm-dd',Item.DataInicio)) else Obj.AddPair('data_inicio',TJSONNull.Create);
    if Item.DataFim>0 then Obj.AddPair('data_fim',FormatDateTime('yyyy-mm-dd',Item.DataFim)) else Obj.AddPair('data_fim',TJSONNull.Create);
    Obj.AddPair('ativo',TJSONBool.Create(Item.Ativo));
    Arr.AddElement(Obj);
  end;
  Result.AddPair('itens',Arr);
end;

class procedure TContratoResponsavelController.Registry;
begin
  THorse.Get(
    '/v1/contratos/instituicao/contratos/:id/responsaveis',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TContratoResponsavelLista;
      IdContrato: Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        Lista:=TContratoResponsavelService.Listar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato);
        try
          TAppResponse.Ok(Res,ListaParaJson(Lista),'Responsáveis carregados com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos/:id/responsaveis',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TContratoResponsavelCadastro;
      Lista: TContratoResponsavelLista;
      IdContrato: Int64;
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
          Dados:=Default(TContratoResponsavelCadastro);
          Dados.IdUsuarioInstituicao:=StrToInt64Def(Body.GetValue<string>('id_usuario_instituicao','0'),0);
          Dados.Nome:=Body.GetValue<string>('nome','');
          Dados.Funcao:=Body.GetValue<string>('funcao','');
          Dados.NumeroDesignacao:=Body.GetValue<string>('numero_designacao','');
          Dados.DataInicio:=ParseDate(Body.GetValue<string>('data_inicio',''));
          Dados.DataFim:=ParseDate(Body.GetValue<string>('data_fim',''));
          Dados.Ativo:=True;
        finally
          Body.Free;
        end;

        Lista:=TContratoResponsavelService.Cadastrar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato,Dados);
        try
          TAppResponse.Ok(Res,ListaParaJson(Lista),'Responsável incluído com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Delete(
    '/v1/contratos/instituicao/contratos/:id/responsaveis/:responsavelId',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Lista: TContratoResponsavelLista;
      IdContrato, IdResponsavel: Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        IdResponsavel:=StrToInt64Def(Req.Params.Items['responsavelId'],0);
        Lista:=TContratoResponsavelService.Inativar(Claims.IdInstituicao,Claims.IdUsuarioInstituicao,IdContrato,IdResponsavel);
        try
          TAppResponse.Ok(Res,ListaParaJson(Lista),'Responsável inativado com sucesso.');
        finally
          Lista.Free;
        end;
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
