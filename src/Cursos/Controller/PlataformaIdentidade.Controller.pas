unit PlataformaIdentidade.Controller;

interface

type
  TPlataformaIdentidadeController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.Classes,
  System.JSON,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaIdentidade.Model,
  PlataformaIdentidade.Service;

function AutorizarSuperAdmin(const Req:THorseRequest; const Res:THorseResponse; out Claims:TJWTClaims):Boolean;
begin
  Result:=False;
  if not TAppToken.ValidarToken(Req,Res,Claims) then Exit;
  if not TAppToken.PossuiRole(Claims.Roles,'SUPER_ADMIN') then
  begin TAppResponse.Forbidden(Res,'Sem permissão para administrar a identidade da plataforma.'); Exit; end;
  Result:=True;
end;

function JsonString(const O:TJSONObject; const N:string):string;
var V:TJSONValue;
begin Result:=''; V:=O.GetValue(N); if (V<>nil) and not(V is TJSONNull) then Result:=V.Value; end;

function BaseUrl(const Req:THorseRequest):string;
var Proto,Host:string;
begin
  Proto:=Trim(Req.Headers['X-Forwarded-Proto']); Host:=Trim(Req.Headers['X-Forwarded-Host']);
  if Proto.IsEmpty then Proto:='http';
  if Host.IsEmpty then Host:=Trim(Req.Headers['Host']);
  if Host.IsEmpty then TAppErrors.RaiseBadRequest('Não foi possível identificar o host da API.');
  Result:=Proto+'://'+Host;
end;

class procedure TPlataformaIdentidadeController.Registry;
begin
  THorse.Get('/v1/certifica/publico/plataforma/identidade',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var C:TPlataformaIdentidadeConfig;
    begin
      try C:=TPlataformaIdentidadeService.Buscar; TAppResponse.Ok(Res,C.ToJSON,'Identidade da plataforma carregada.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/configuracoes/identidade',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; C:TPlataformaIdentidadeConfig;
    begin
      try if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        C:=TPlataformaIdentidadeService.Buscar; TAppResponse.Ok(Res,C.ToJSON,'Identidade da plataforma carregada.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Put('/v1/certifica/plataforma/configuracoes/identidade',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; J:TJSONValue; O:TJSONObject; D:TPlataformaIdentidadeInput; C:TPlataformaIdentidadeConfig;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        J:=TJSONObject.ParseJSONValue(Req.Body);
        if not(J is TJSONObject) then begin J.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
        O:=J as TJSONObject;
        try
          D:=Default(TPlataformaIdentidadeInput);
          D.NomePlataforma:=JsonString(O,'nome_plataforma');
          D.TituloLogin:=JsonString(O,'titulo_login');
          D.SubtituloLogin:=JsonString(O,'subtitulo_login');
          D.TituloDestaqueLogin:=JsonString(O,'titulo_destaque_login');
          D.DescricaoLogin:=JsonString(O,'descricao_login');
        finally O.Free; end;
        C:=TPlataformaIdentidadeService.Atualizar(Claims.UserId,D,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        TAppResponse.Ok(Res,C.ToJSON,'Identidade da plataforma atualizada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/configuracoes/identidade/logo',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; S:TStream; C:TPlataformaIdentidadeConfig;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        if Req.ContentFields.Field('arquivo')=nil then TAppErrors.RaiseBadRequest('Arquivo não informado.');
        S:=Req.ContentFields.Field('arquivo').AsStream;
        if S=nil then TAppErrors.RaiseBadRequest('Arquivo inválido.');
        C:=TPlataformaIdentidadeService.SalvarLogo(Claims.UserId,BaseUrl(Req),S,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        TAppResponse.Ok(Res,C.ToJSON,'Logo da plataforma atualizado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/publico/plataforma/identidade/logo/:arquivo',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Caminho:string;
    begin
      try Caminho:=TPlataformaIdentidadeService.ResolverLogoPublica(Req.Params.Items['arquivo']); Res.SendFile(Caminho);
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
