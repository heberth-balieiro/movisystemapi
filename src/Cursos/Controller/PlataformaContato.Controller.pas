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
  System.StrUtils,
  Uni,
  App.Config,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  Database.Connection,
  PlataformaContato.DAO,
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

procedure AddNullable(const O:TJSONObject; const N,V:string);
begin
  if Trim(V).IsEmpty then O.AddPair(N,TJSONNull.Create) else O.AddPair(N,V);
end;

function RelatorioContatos(const AIdUsuario:Int64; const ATipo,AUF,AMunicipio,APartido,ASituacao:string;
  const AEmExercicio,ATemEmail:Integer; const AIP,AUserAgent:string):TJSONObject;
var
  Cfg:TAppApiConfig; Conn:TUniConnection; Q:TUniQuery; Arr:TJSONArray; J,F:TJSONObject;
  Tipo,UF,Municipio,Partido,Situacao,W:string;
  procedure Parametros;
  begin
    if not UF.IsEmpty then Q.ParamByName('uf').AsString:=UF;
    if not Municipio.IsEmpty then Q.ParamByName('cidade').AsString:=Municipio;
    if not Partido.IsEmpty then Q.ParamByName('partido').AsString:=Partido;
    if not Situacao.IsEmpty then Q.ParamByName('situacao').AsString:=Situacao;
    if MatchText(Tipo,['VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR']) then Q.ParamByName('cargo').AsString:=Tipo;
  end;
begin
  Tipo:=UpperCase(Trim(ATipo));
  if not MatchText(Tipo,['CAMARA','PREFEITURA','SINDICATO','ASSOCIACAO','VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR','UNALE_ASSOCIADO']) then
    TAppErrors.RaiseBadRequest('Tipo de relatório inválido.');
  UF:=UpperCase(Trim(AUF)); if (not UF.IsEmpty) and (Length(UF)<>2) then TAppErrors.RaiseBadRequest('UF inválida.');
  Municipio:=Trim(AMunicipio); Partido:=UpperCase(Trim(APartido)); Situacao:=UpperCase(Trim(ASituacao));
  if (not Situacao.IsEmpty) and not MatchText(Situacao,['ATIVO','INATIVO']) then TAppErrors.RaiseBadRequest('Situação inválida.');

  W:=' WHERE 1=1 ';
  if Tipo='CAMARA' then W:=W+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Câmara Municipal'' OR c.grau=''Câmara Municipal'') '
  else if Tipo='PREFEITURA' then W:=W+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Prefeitura Municipal'' OR c.grau=''Prefeitura Municipal'') '
  else if Tipo='SINDICATO' then W:=W+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Sindicato'' OR c.grau=''Sindicato'') '
  else if Tipo='ASSOCIACAO' then W:=W+'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' AND (c.orgao=''Associação'' OR c.grau=''Associação'') '
  else if Tipo='UNALE_ASSOCIADO' then W:=W+'AND c.tipo_contato=''PARLAMENTAR'' AND c.unale_associado=1 '
  else W:=W+'AND c.tipo_contato=''PARLAMENTAR'' AND c.cargo=:cargo ';
  if not UF.IsEmpty then W:=W+'AND c.uf=:uf ';
  if not Municipio.IsEmpty then W:=W+'AND c.cidade=:cidade ';
  if not Partido.IsEmpty then W:=W+'AND c.partido=:partido ';
  if not Situacao.IsEmpty then W:=W+'AND c.situacao=:situacao ';
  if AEmExercicio=1 then W:=W+'AND c.em_exercicio=1 ' else if AEmExercicio=0 then W:=W+'AND c.em_exercicio=0 ';
  if ATemEmail=1 then W:=W+'AND COALESCE(c.email_normalizado,'''')<>'''' ' else if ATemEmail=0 then W:=W+'AND COALESCE(c.email_normalizado,'''')='''' ';

  Cfg:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini'); Conn:=TDatabaseConnection.NewConnection(Cfg.Database); Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=Conn;
    Q.SQL.Text:='SELECT c.id,c.tipo_documento,c.documento,c.razao_social,c.nome_fantasia,c.responsavel,c.telefone,c.email,c.grau,c.cidade,c.uf,c.orgao,c.site,c.fonte,c.data_coleta,c.situacao,c.cargo,c.partido,c.id_externo,c.fonte_dados,c.url_perfil,c.unale_associado,c.em_exercicio FROM plataforma_contato c '+W+'ORDER BY c.uf,c.cidade,COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),c.id LIMIT 5000';
    Parametros; Q.Open; Arr:=TJSONArray.Create;
    while not Q.Eof do begin
      J:=TJSONObject.Create; J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      if SameText(Q.FieldByName('tipo_documento').AsString,'CNPJ') then AddNullable(J,'documento',Q.FieldByName('documento').AsString) else J.AddPair('documento',TJSONNull.Create);
      AddNullable(J,'razao_social',Q.FieldByName('razao_social').AsString); AddNullable(J,'nome_fantasia',Q.FieldByName('nome_fantasia').AsString); AddNullable(J,'responsavel',Q.FieldByName('responsavel').AsString);
      AddNullable(J,'telefone',Q.FieldByName('telefone').AsString); AddNullable(J,'email',Q.FieldByName('email').AsString); AddNullable(J,'grau',Q.FieldByName('grau').AsString); AddNullable(J,'cidade',Q.FieldByName('cidade').AsString); AddNullable(J,'uf',Q.FieldByName('uf').AsString); AddNullable(J,'orgao',Q.FieldByName('orgao').AsString);
      AddNullable(J,'site',Q.FieldByName('site').AsString); AddNullable(J,'fonte',Q.FieldByName('fonte').AsString); AddNullable(J,'cargo',Q.FieldByName('cargo').AsString); AddNullable(J,'partido',Q.FieldByName('partido').AsString); AddNullable(J,'id_externo',Q.FieldByName('id_externo').AsString); AddNullable(J,'fonte_dados',Q.FieldByName('fonte_dados').AsString); AddNullable(J,'url_perfil',Q.FieldByName('url_perfil').AsString);
      J.AddPair('unale_associado',TJSONBool.Create(Q.FieldByName('unale_associado').AsBoolean)); J.AddPair('em_exercicio',TJSONBool.Create(Q.FieldByName('em_exercicio').AsBoolean)); J.AddPair('situacao',Q.FieldByName('situacao').AsString);
      if Q.FieldByName('data_coleta').IsNull then J.AddPair('data_coleta',TJSONNull.Create) else J.AddPair('data_coleta',FormatDateTime('yyyy-mm-dd',Q.FieldByName('data_coleta').AsDateTime));
      Arr.AddElement(J); Q.Next;
    end;
    F:=TJSONObject.Create; F.AddPair('tipo',Tipo); AddNullable(F,'uf',UF); AddNullable(F,'municipio',Municipio); AddNullable(F,'partido',Partido); AddNullable(F,'situacao',Situacao);
    Result:=TJSONObject.Create; Result.AddPair('tipo',Tipo); Result.AddPair('total',TJSONNumber.Create(Arr.Count)); Result.AddPair('limite',TJSONNumber.Create(5000)); Result.AddPair('filtros',F); Result.AddPair('itens',Arr);
    TPlataformaContatoDAO.RegistrarAuditoria(Conn,AIdUsuario,'RELATORIO_CONTATOS_GERADO','plataforma_contato','','Relatório analítico gerado: '+Tipo,AIP,AUserAgent);
  finally Q.Free; Conn.Free; end;
end;

class procedure TPlataformaContatoController.Registry;
begin
  THorse.Get('/v1/certifica/plataforma/relatorios/contatos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var Claims:TJWTClaims; Dados:TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req,Res,Claims) then Exit;
        Dados:=RelatorioContatos(Claims.UserId,Req.Query.Items['tipo'],Req.Query.Items['uf'],Req.Query.Items['municipio'],Req.Query.Items['partido'],Req.Query.Items['situacao'],QueryFlag(Req.Query.Items['em_exercicio']),QueryFlag(Req.Query.Items['tem_email']),TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));
        TAppResponse.Ok(Res,Dados,'Relatório de contatos carregado com sucesso.');
      except on E:Exception do TAppErrors.HandleException(Res,E); end;
    end);

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
