unit PlataformaCampanhaPublico.Controller;

interface

type
  TPlataformaCampanhaPublicoController = class
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
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaCampanhaPublico.Service;

function AutorizarSuperAdmin(const Req:THorseRequest; const Res:THorseResponse; out AClaims:TJWTClaims):Boolean;
begin
  Result:=False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;
  if not TAppToken.PossuiRole(AClaims.Roles,'SUPER_ADMIN') then begin
    TAppResponse.Forbidden(Res,'Sem permissão para administrar campanhas da plataforma.');
    Exit;
  end;
  Result:=True;
end;

function QueryFlag(const S:string):Integer;
begin
  if Trim(S).IsEmpty then Exit(-1);
  if SameText(Trim(S),'1') or SameText(Trim(S),'true') or SameText(Trim(S),'sim') then Exit(1);
  if SameText(Trim(S),'0') or SameText(Trim(S),'false') or SameText(Trim(S),'nao') then Exit(0);
  Result:=-2;
end;

function JsonString(const AObj:TJSONObject; const ANome:string):string;
var V:TJSONValue;
begin
  Result:=''; V:=AObj.GetValue(ANome); if (V<>nil) and not (V is TJSONNull) then Result:=V.Value;
end;

function JsonFlag(const AObj:TJSONObject; const ANome:string):Integer;
var V:TJSONValue; S:string;
begin
  V:=AObj.GetValue(ANome); if (V=nil) or (V is TJSONNull) then Exit(-1);
  S:=V.Value;
  if SameText(S,'true') or SameText(S,'1') then Exit(1);
  if SameText(S,'false') or SameText(S,'0') then Exit(0);
  Result:=-2;
end;

function ParseBody(const Req:THorseRequest):TJSONObject;
var Raw:TJSONValue;
begin
  Raw:=TJSONObject.ParseJSONValue(Req.Body);
  if not (Raw is TJSONObject) then begin Raw.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
  Result:=Raw as TJSONObject;
end;

class procedure TPlataformaCampanhaPublicoController.Registry;
begin
  THorse.Get('/v1/certifica/plataforma/campanhas/:id/publico',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaCampanhaPublicoService.Listar(
          StrToInt64Def(Req.Params.Items['id'],0),
          Req.Query.Items['tipo'],Req.Query.Items['busca'],Req.Query.Items['uf'],Req.Query.Items['municipio'],Req.Query.Items['partido'],
          QueryFlag(Req.Query.Items['em_exercicio']),QueryFlag(Req.Query.Items['unale_associado']),QueryFlag(Req.Query.Items['tem_email']),QueryFlag(Req.Query.Items['tem_whatsapp']),
          StrToIntDef(Req.Query.Items['page'],1),StrToIntDef(Req.Query.Items['page_size'],50)
        );
        TAppResponse.Ok(Res,Dados,'Público da campanha carregado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/campanhas/:id/publico/adicionar-filtro',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try
          Dados:=TPlataformaCampanhaPublicoService.AdicionarTodos(
            Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),
            JsonString(Body,'tipo'),JsonString(Body,'busca'),JsonString(Body,'uf'),JsonString(Body,'municipio'),JsonString(Body,'partido'),
            JsonFlag(Body,'em_exercicio'),JsonFlag(Body,'unale_associado'),JsonFlag(Body,'tem_email'),JsonFlag(Body,'tem_whatsapp'),
            TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req)
          );
        finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Público adicionado à campanha com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
