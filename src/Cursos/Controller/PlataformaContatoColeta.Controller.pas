unit PlataformaContatoColeta.Controller;

interface

type
  TPlataformaContatoColetaController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Config,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  PlataformaContatoColeta.Service;

function AutorizarSuperAdmin(const Req:THorseRequest; const Res:THorseResponse; out AClaims:TJWTClaims):Boolean;
begin
  Result:=False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;
  if not TAppToken.PossuiRole(AClaims.Roles,'SUPER_ADMIN') then begin
    TAppResponse.Forbidden(Res,'Sem permissão para administrar coletas de contatos.');
    Exit;
  end;
  Result:=True;
end;

function AutorizarWorker(const Req:THorseRequest; const Res:THorseResponse):Boolean;
var C:TAppApiConfig; Token:string;
begin
  Result:=False;
  C:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  if Trim(C.CollectorToken).IsEmpty then begin TAppResponse.Unauthorized(Res,'Token técnico do coletor não configurado.'); Exit; end;
  Token:=TAppJWT.ExtrairBearerToken(Req.Headers['Authorization']);
  if (Token.IsEmpty) or (Token<>C.CollectorToken) then begin TAppResponse.Unauthorized(Res,'Token técnico do coletor inválido.'); Exit; end;
  Result:=True;
end;

function ParseBody(const Req:THorseRequest):TJSONObject;
var V:TJSONValue;
begin
  V:=TJSONObject.ParseJSONValue(Req.Body);
  if not (V is TJSONObject) then begin V.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
  Result:=V as TJSONObject;
end;

function JStr(const O:TJSONObject; const N:string):string;
var V:TJSONValue;
begin Result:=''; V:=O.GetValue(N); if (V<>nil) and not (V is TJSONNull) then Result:=V.Value; end;

function JInt(const O:TJSONObject; const N:string):Integer;
begin Result:=StrToIntDef(JStr(O,N),0); end;

function JInt64(const O:TJSONObject; const N:string):Int64;
begin Result:=StrToInt64Def(JStr(O,N),0); end;

class procedure TPlataformaContatoColetaController.Registry;
begin
  THorse.Post('/v1/certifica/plataforma/contato-coletas',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try
          Dados:=TPlataformaContatoColetaService.Criar(
            Claims.UserId,
            JStr(Body,'nome'),
            JStr(Body,'tipo'),
            JStr(Body,'uf'),
            JStr(Body,'modo_alvo'),
            JStr(Body,'municipio'),
            JInt(Body,'limite'),
            JInt(Body,'workers')
          );
        finally Body.Free; end;
        TAppResponse.Created(Res,Dados,'Coleta criada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/contato-coletas',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoColetaService.Listar(Req.Query.Items['situacao'],Req.Query.Items['tipo'],Req.Query.Items['uf'],StrToIntDef(Req.Query.Items['page'],1),StrToIntDef(Req.Query.Items['page_size'],50));
        TAppResponse.Ok(Res,Dados,'Coletas carregadas com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/contato-coletas/:id',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoColetaService.Buscar(StrToInt64Def(Req.Params.Items['id'],0));
        TAppResponse.Ok(Res,Dados,'Coleta carregada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/contato-coletas/:id/itens',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoColetaService.ListarItens(StrToInt64Def(Req.Params.Items['id'],0),Req.Query.Items['classificacao'],Req.Query.Items['situacao_revisao'],StrToIntDef(Req.Query.Items['page'],1),StrToIntDef(Req.Query.Items['page_size'],100));
        TAppResponse.Ok(Res,Dados,'Itens da coleta carregados com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contato-coletas/:id/cancelar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoColetaService.Cancelar(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0));
        TAppResponse.Ok(Res,Dados,'Coleta cancelada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contato-coletas/:id/itens/:item/revisar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try Dados:=TPlataformaContatoColetaService.RevisarItem(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),StrToInt64Def(Req.Params.Items['item'],0),JStr(Body,'situacao')); finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Item revisado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contato-coletas/:id/importar-aprovados',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject; IdLista:Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try IdLista:=JInt64(Body,'id_lista'); Dados:=TPlataformaContatoColetaService.ImportarAprovados(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),IdLista); finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Contatos aprovados importados com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/integracao/contato-coletas/proxima',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Dados:TJSONObject;
    begin
      try
        if not AutorizarWorker(Req,Res) then Exit;
        Dados:=TPlataformaContatoColetaService.ProximaPendente;
        if Dados=nil then Dados:=TJSONObject.Create;
        TAppResponse.Ok(Res,Dados,'Consulta da fila realizada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/integracao/contato-coletas/:id/iniciar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarWorker(Req,Res) then Exit;
        Body:=ParseBody(Req); try Dados:=TPlataformaContatoColetaService.Iniciar(StrToInt64Def(Req.Params.Items['id'],0),JInt(Body,'total_alvos')); finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Coleta iniciada pelo worker.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/integracao/contato-coletas/:id/resultados',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Body,Progresso,Dados:TJSONObject; V:TJSONValue; Itens:TJSONArray;
    begin
      try
        if not AutorizarWorker(Req,Res) then Exit;
        Body:=ParseBody(Req); Itens:=nil; Progresso:=nil;
        try
          V:=Body.GetValue('itens'); if V is TJSONArray then Itens:=V as TJSONArray;
          V:=Body.GetValue('progresso'); if V is TJSONObject then Progresso:=V as TJSONObject;
          Dados:=TPlataformaContatoColetaService.ReceberResultados(StrToInt64Def(Req.Params.Items['id'],0),Itens,Progresso);
        finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Resultados recebidos com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/integracao/contato-coletas/:id/finalizar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarWorker(Req,Res) then Exit;
        Body:=ParseBody(Req); try Dados:=TPlataformaContatoColetaService.Finalizar(StrToInt64Def(Req.Params.Items['id'],0),Body); finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Coleta finalizada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/integracao/contato-coletas/:id/erro',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarWorker(Req,Res) then Exit;
        Body:=ParseBody(Req); try Dados:=TPlataformaContatoColetaService.MarcarErro(StrToInt64Def(Req.Params.Items['id'],0),JStr(Body,'mensagem')); finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Erro da coleta registrado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
