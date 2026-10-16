unit PlataformaContato.Controller;

interface

type
  TPlataformaContatoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Classes,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaContato.Service;

function AutorizarSuperAdmin(const Req:THorseRequest; const Res:THorseResponse; out AClaims:TJWTClaims):Boolean;
begin
  Result:=False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;
  if not TAppToken.PossuiRole(AClaims.Roles,'SUPER_ADMIN') then begin
    TAppResponse.Forbidden(Res,'Sem permissão para administrar a base de contatos da plataforma.');
    Exit;
  end;
  Result:=True;
end;

function JsonString(const AObj:TJSONObject; const ANome:string):string;
var V:TJSONValue;
begin
  Result:=''; V:=AObj.GetValue(ANome); if (V<>nil) and not (V is TJSONNull) then Result:=V.Value;
end;

function JsonInt64(const AObj:TJSONObject; const ANome:string):Int64;
var V:TJSONValue;
begin
  Result:=0; V:=AObj.GetValue(ANome); if (V<>nil) and not (V is TJSONNull) then Result:=StrToInt64Def(V.Value,0);
end;

function QueryFlag(const S:string):Integer;
begin
  if Trim(S).IsEmpty then Exit(-1);
  if SameText(Trim(S),'1') or SameText(Trim(S),'true') or SameText(Trim(S),'sim') then Exit(1);
  if SameText(Trim(S),'0') or SameText(Trim(S),'false') or SameText(Trim(S),'nao') then Exit(0);
  Result:=-1;
end;

function ParseBody(const Req:THorseRequest):TJSONObject;
var Raw:TJSONValue;
begin
  Raw:=TJSONObject.ParseJSONValue(Req.Body);
  if not (Raw is TJSONObject) then begin Raw.Free; TAppErrors.RaiseBadRequest('JSON inválido.'); end;
  Result:=Raw as TJSONObject;
end;

class procedure TPlataformaContatoController.Registry;
begin
  THorse.Get('/v1/certifica/plataforma/contatos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoService.Listar(
          Req.Query.Items['busca'],Req.Query.Items['cidade'],Req.Query.Items['uf'],Req.Query.Items['orgao'],Req.Query.Items['grau'],Req.Query.Items['situacao'],
          StrToInt64Def(Req.Query.Items['lista'],0),QueryFlag(Req.Query.Items['tem_email']),QueryFlag(Req.Query.Items['tem_whatsapp']),
          StrToIntDef(Req.Query.Items['page'],1),StrToIntDef(Req.Query.Items['page_size'],50));
        TAppResponse.Ok(Res,Dados,'Contatos carregados com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/contatos/:id',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TPlataformaContatoService.Buscar(StrToInt64Def(Req.Params.Items['id'],0));
        TAppResponse.Ok(Res,Dados,'Contato carregado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contatos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try
          Dados:=TPlataformaContatoService.Salvar(Claims.UserId,0,JsonString(Body,'cpf_cnpj'),JsonString(Body,'razao_social'),JsonString(Body,'nome_fantasia'),
            JsonString(Body,'responsavel'),JsonString(Body,'telefone'),JsonString(Body,'email'),JsonString(Body,'grau'),JsonString(Body,'cidade'),JsonString(Body,'uf'),
            JsonString(Body,'orgao'),JsonString(Body,'site'),JsonString(Body,'observacao'),JsonString(Body,'fonte'),JsonString(Body,'situacao'),JsonString(Body,'data_coleta'),
            TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        finally Body.Free; end;
        TAppResponse.Created(Res,Dados,'Contato criado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Put('/v1/certifica/plataforma/contatos/:id',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try
          Dados:=TPlataformaContatoService.Salvar(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),JsonString(Body,'cpf_cnpj'),JsonString(Body,'razao_social'),JsonString(Body,'nome_fantasia'),
            JsonString(Body,'responsavel'),JsonString(Body,'telefone'),JsonString(Body,'email'),JsonString(Body,'grau'),JsonString(Body,'cidade'),JsonString(Body,'uf'),
            JsonString(Body,'orgao'),JsonString(Body,'site'),JsonString(Body,'observacao'),JsonString(Body,'fonte'),JsonString(Body,'situacao'),JsonString(Body,'data_coleta'),
            TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Contato atualizado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Get('/v1/certifica/plataforma/contato-listas',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=TJSONObject.Create; Dados.AddPair('itens',TPlataformaContatoService.ListarListas);
        TAppResponse.Ok(Res,Dados,'Listas carregadas com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contato-listas',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try Dados:=TPlataformaContatoService.SalvarLista(Claims.UserId,0,JsonString(Body,'nome'),JsonString(Body,'descricao'),JsonString(Body,'cidade'),JsonString(Body,'uf'),JsonString(Body,'orgao'),JsonString(Body,'grau'),JsonString(Body,'fonte'),TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        finally Body.Free; end;
        TAppResponse.Created(Res,Dados,'Lista criada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Put('/v1/certifica/plataforma/contato-listas/:id',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req);
        try Dados:=TPlataformaContatoService.SalvarLista(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),JsonString(Body,'nome'),JsonString(Body,'descricao'),JsonString(Body,'cidade'),JsonString(Body,'uf'),JsonString(Body,'orgao'),JsonString(Body,'grau'),JsonString(Body,'fonte'),TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Lista atualizada com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contatos/importar/validar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Stream:TStream; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        if Req.ContentFields.Field('arquivo')=nil then TAppErrors.RaiseBadRequest('Arquivo CSV não informado.');
        Stream:=Req.ContentFields.Field('arquivo').AsStream;
        Dados:=TPlataformaContatoService.ValidarCSV(Stream,StrToInt64Def(Req.Query.Items['id_lista'],0));
        TAppResponse.Ok(Res,Dados,'CSV validado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/contatos/importar',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Stream:TStream; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        if Req.ContentFields.Field('arquivo')=nil then TAppErrors.RaiseBadRequest('Arquivo CSV não informado.');
        Stream:=Req.ContentFields.Field('arquivo').AsStream;
        Dados:=TPlataformaContatoService.ImportarCSV(Claims.UserId,Stream,StrToInt64Def(Req.Query.Items['id_lista'],0),TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        TAppResponse.Ok(Res,Dados,'CSV importado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

  THorse.Post('/v1/certifica/plataforma/campanhas/:id/adicionar-contatos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Body,Dados:TJSONObject; V:TJSONValue; Ids:TJSONArray; IdLista:Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Body:=ParseBody(Req); Ids:=nil;
        try
          IdLista:=JsonInt64(Body,'id_lista'); V:=Body.GetValue('ids_contatos'); if V is TJSONArray then Ids:=V as TJSONArray;
          Dados:=TPlataformaContatoService.AdicionarNaCampanha(Claims.UserId,StrToInt64Def(Req.Params.Items['id'],0),IdLista,Ids,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        finally Body.Free; end;
        TAppResponse.Ok(Res,Dados,'Contatos adicionados à campanha com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);
end;

end.
