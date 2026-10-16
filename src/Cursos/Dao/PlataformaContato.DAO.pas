unit PlataformaContato.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaContatoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const ABusca, ACidade, AUF, AOrgao, AGrau, ASituacao: string;
      const AIdLista: Int64;
      const ATemEmail, ATemWhatsApp: Integer;
      const APagina, APorPagina: Integer
    ): TJSONObject; static;

    class function Buscar(const AConn: TUniConnection; const AId: Int64): TJSONObject; static;
    class function BuscarIdPorDocumento(const AConn: TUniConnection; const ADocumento: string): Int64; static;
    class function BuscarIdFallback(const AConn: TUniConnection; const AEmail, ATelefone: string): Int64; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ATipoDocumento, ADocumento, ADocumentoNormalizado,
            ARazaoSocial, ANomeFantasia, AResponsavel,
            ATelefone, ATelefoneNormalizado, AEmail, AEmailNormalizado,
            AGrau, ACidade, AUF, AOrgao, ASite, AObservacao, AFonte: string;
      const ADataColeta: TDateTime;
      const ATemDataColeta: Boolean
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AId: Int64;
      const ATipoDocumento, ADocumento, ADocumentoNormalizado,
            ARazaoSocial, ANomeFantasia, AResponsavel,
            ATelefone, ATelefoneNormalizado, AEmail, AEmailNormalizado,
            AGrau, ACidade, AUF, AOrgao, ASite, AObservacao, AFonte, ASituacao: string;
      const ADataColeta: TDateTime;
      const ATemDataColeta: Boolean
    ); static;

    class function ListarListas(const AConn: TUniConnection): TJSONArray; static;
    class function SalvarLista(
      const AConn: TUniConnection;
      const AIdUsuario, AId: Int64;
      const ANome, ADescricao, ACidade, AUF, AOrgao, AGrau, AFonte: string
    ): Int64; static;
    class procedure VincularLista(const AConn: TUniConnection; const AIdLista, AIdContato: Int64); static;
    class function ListaExiste(const AConn: TUniConnection; const AIdLista: Int64): Boolean; static;

    class function AdicionarContatosCampanhaPorIds(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const AIds: TJSONArray
    ): Integer; static;
    class function AdicionarContatosCampanhaPorLista(
      const AConn: TUniConnection;
      const AIdCampanha, AIdLista: Int64
    ): Integer; static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AAcao, AEntidade, ARegistro, AMensagem, AIP, AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

procedure AddNullableString(const AObj: TJSONObject; const AName: string; const AValue: string);
begin
  if Trim(AValue).IsEmpty then
    AObj.AddPair(AName, TJSONNull.Create)
  else
    AObj.AddPair(AName, AValue);
end;

class function TPlataformaContatoDAO.Listar(
  const AConn: TUniConnection;
  const ABusca, ACidade, AUF, AOrgao, AGrau, ASituacao: string;
  const AIdLista: Int64;
  const ATemEmail, ATemWhatsApp: Integer;
  const APagina, APorPagina: Integer
): TJSONObject;
var
  Q: TUniQuery;
  Arr: TJSONArray;
  J, Pag: TJSONObject;
  JoinSQL, WhereSQL: string;
  Pagina, PorPagina, Total, TotalPaginas: Integer;

  procedure Params;
  begin
    if not Trim(ABusca).IsEmpty then Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ACidade).IsEmpty then Q.ParamByName('cidade').AsString := Trim(ACidade);
    if not Trim(AUF).IsEmpty then Q.ParamByName('uf').AsString := UpperCase(Trim(AUF));
    if not Trim(AOrgao).IsEmpty then Q.ParamByName('orgao').AsString := Trim(AOrgao);
    if not Trim(AGrau).IsEmpty then Q.ParamByName('grau').AsString := Trim(AGrau);
    if not Trim(ASituacao).IsEmpty then Q.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    if AIdLista > 0 then Q.ParamByName('id_lista').AsLargeInt := AIdLista;
  end;
begin
  Pagina := APagina; if Pagina <= 0 then Pagina := 1;
  PorPagina := APorPagina; if PorPagina <= 0 then PorPagina := 50; if PorPagina > 200 then PorPagina := 200;

  JoinSQL := '';
  if AIdLista > 0 then
    JoinSQL := ' JOIN plataforma_contato_lista_item li ON li.id_contato=c.id AND li.id_lista=:id_lista ';

  WhereSQL := ' WHERE 1=1 ';
  if not Trim(ABusca).IsEmpty then
    WhereSQL := WhereSQL + 'AND (c.razao_social LIKE :busca OR c.nome_fantasia LIKE :busca OR c.responsavel LIKE :busca OR c.documento_normalizado LIKE :busca OR c.email_normalizado LIKE :busca) ';
  if not Trim(ACidade).IsEmpty then WhereSQL := WhereSQL + 'AND c.cidade=:cidade ';
  if not Trim(AUF).IsEmpty then WhereSQL := WhereSQL + 'AND c.uf=:uf ';
  if not Trim(AOrgao).IsEmpty then WhereSQL := WhereSQL + 'AND c.orgao=:orgao ';
  if not Trim(AGrau).IsEmpty then WhereSQL := WhereSQL + 'AND c.grau=:grau ';
  if not Trim(ASituacao).IsEmpty then WhereSQL := WhereSQL + 'AND c.situacao=:situacao ';
  if ATemEmail = 1 then WhereSQL := WhereSQL + 'AND COALESCE(c.email_normalizado,'''')<>'''' ';
  if ATemEmail = 0 then WhereSQL := WhereSQL + 'AND COALESCE(c.email_normalizado,'''')='''' ';
  if ATemWhatsApp = 1 then WhereSQL := WhereSQL + 'AND COALESCE(c.telefone_normalizado,'''')<>'''' ';
  if ATemWhatsApp = 0 then WhereSQL := WhereSQL + 'AND COALESCE(c.telefone_normalizado,'''')='''' ';

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT COUNT(DISTINCT c.id) total FROM plataforma_contato c ' + JoinSQL + WhereSQL;
    Params;
    Q.Open;
    Total := Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text :=
      'SELECT DISTINCT c.id,c.tipo_documento,c.documento,c.documento_normalizado,c.razao_social,c.nome_fantasia,' +
      'c.responsavel,c.telefone,c.telefone_normalizado,c.email,c.email_normalizado,c.grau,c.cidade,c.uf,c.orgao,' +
      'c.site,c.fonte,c.data_coleta,c.situacao,c.criado_em,c.atualizado_em ' +
      'FROM plataforma_contato c ' + JoinSQL + WhereSQL +
      'ORDER BY COALESCE(NULLIF(c.nome_fantasia,''''),c.razao_social),c.id LIMIT :limite OFFSET :offset';
    Params;
    Q.ParamByName('limite').AsInteger := PorPagina;
    Q.ParamByName('offset').AsInteger := (Pagina - 1) * PorPagina;
    Q.Open;

    Arr := TJSONArray.Create;
    while not Q.Eof do
    begin
      J := TJSONObject.Create;
      J.AddPair('id', TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      AddNullableString(J,'tipo_documento',Q.FieldByName('tipo_documento').AsString);
      AddNullableString(J,'documento',Q.FieldByName('documento').AsString);
      AddNullableString(J,'razao_social',Q.FieldByName('razao_social').AsString);
      AddNullableString(J,'nome_fantasia',Q.FieldByName('nome_fantasia').AsString);
      AddNullableString(J,'responsavel',Q.FieldByName('responsavel').AsString);
      AddNullableString(J,'telefone',Q.FieldByName('telefone').AsString);
      AddNullableString(J,'email',Q.FieldByName('email').AsString);
      AddNullableString(J,'grau',Q.FieldByName('grau').AsString);
      AddNullableString(J,'cidade',Q.FieldByName('cidade').AsString);
      AddNullableString(J,'uf',Q.FieldByName('uf').AsString);
      AddNullableString(J,'orgao',Q.FieldByName('orgao').AsString);
      AddNullableString(J,'site',Q.FieldByName('site').AsString);
      AddNullableString(J,'fonte',Q.FieldByName('fonte').AsString);
      if Q.FieldByName('data_coleta').IsNull then J.AddPair('data_coleta',TJSONNull.Create)
      else J.AddPair('data_coleta',FormatDateTime('yyyy-mm-dd',Q.FieldByName('data_coleta').AsDateTime));
      J.AddPair('situacao',Q.FieldByName('situacao').AsString);
      J.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('criado_em').AsDateTime));
      J.AddPair('atualizado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('atualizado_em').AsDateTime));
      Arr.AddElement(J);
      Q.Next;
    end;

    TotalPaginas := 0;
    if Total > 0 then TotalPaginas := (Total + PorPagina - 1) div PorPagina;
    Pag := TJSONObject.Create;
    Pag.AddPair('pagina',TJSONNumber.Create(Pagina));
    Pag.AddPair('por_pagina',TJSONNumber.Create(PorPagina));
    Pag.AddPair('total',TJSONNumber.Create(Total));
    Pag.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));
    Result := TJSONObject.Create;
    Result.AddPair('itens',Arr);
    Result.AddPair('paginacao',Pag);
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoDAO.Buscar(const AConn:TUniConnection; const AId:Int64):TJSONObject;
var Q:TUniQuery;
begin
  Result:=nil;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT c.* FROM plataforma_contato c WHERE c.id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Open;
    if Q.IsEmpty then Exit;
    Result:=TJSONObject.Create;
    Result.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
    AddNullableString(Result,'tipo_documento',Q.FieldByName('tipo_documento').AsString);
    AddNullableString(Result,'documento',Q.FieldByName('documento').AsString);
    AddNullableString(Result,'razao_social',Q.FieldByName('razao_social').AsString);
    AddNullableString(Result,'nome_fantasia',Q.FieldByName('nome_fantasia').AsString);
    AddNullableString(Result,'responsavel',Q.FieldByName('responsavel').AsString);
    AddNullableString(Result,'telefone',Q.FieldByName('telefone').AsString);
    AddNullableString(Result,'email',Q.FieldByName('email').AsString);
    AddNullableString(Result,'grau',Q.FieldByName('grau').AsString);
    AddNullableString(Result,'cidade',Q.FieldByName('cidade').AsString);
    AddNullableString(Result,'uf',Q.FieldByName('uf').AsString);
    AddNullableString(Result,'orgao',Q.FieldByName('orgao').AsString);
    AddNullableString(Result,'site',Q.FieldByName('site').AsString);
    AddNullableString(Result,'observacao',Q.FieldByName('observacao').AsString);
    AddNullableString(Result,'fonte',Q.FieldByName('fonte').AsString);
    if Q.FieldByName('data_coleta').IsNull then Result.AddPair('data_coleta',TJSONNull.Create)
    else Result.AddPair('data_coleta',FormatDateTime('yyyy-mm-dd',Q.FieldByName('data_coleta').AsDateTime));
    Result.AddPair('situacao',Q.FieldByName('situacao').AsString);
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.BuscarIdPorDocumento(const AConn:TUniConnection; const ADocumento:string):Int64;
var Q:TUniQuery;
begin
  Result:=0; if Trim(ADocumento).IsEmpty then Exit;
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='SELECT id FROM plataforma_contato WHERE documento_normalizado=:v LIMIT 1';
    Q.ParamByName('v').AsString:=ADocumento; Q.Open;
    if not Q.IsEmpty then Result:=Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.BuscarIdFallback(const AConn:TUniConnection; const AEmail,ATelefone:string):Int64;
var Q:TUniQuery;
begin
  Result:=0; if Trim(AEmail).IsEmpty and Trim(ATelefone).IsEmpty then Exit;
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='SELECT id FROM plataforma_contato WHERE documento_normalizado IS NULL AND ('+
      '(:email<>'''' AND email_normalizado=:email) OR (:telefone<>'''' AND telefone_normalizado=:telefone)) ORDER BY id LIMIT 1';
    Q.ParamByName('email').AsString:=AEmail; Q.ParamByName('telefone').AsString:=ATelefone; Q.Open;
    if not Q.IsEmpty then Result:=Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.Inserir(
  const AConn:TUniConnection; const AIdUsuario:Int64;
  const ATipoDocumento,ADocumento,ADocumentoNormalizado,ARazaoSocial,ANomeFantasia,AResponsavel,
        ATelefone,ATelefoneNormalizado,AEmail,AEmailNormalizado,AGrau,ACidade,AUF,AOrgao,ASite,AObservacao,AFonte:string;
  const ADataColeta:TDateTime; const ATemDataColeta:Boolean):Int64;
var Q:TUniQuery;
  procedure S(const N,V:string); begin if Trim(V).IsEmpty then Q.ParamByName(N).Clear else Q.ParamByName(N).AsString:=V; end;
begin
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='INSERT INTO plataforma_contato (tipo_documento,documento,documento_normalizado,razao_social,nome_fantasia,responsavel,'+
      'telefone,telefone_normalizado,email,email_normalizado,grau,cidade,uf,orgao,site,observacao,fonte,data_coleta,situacao,criado_por) VALUES ('+
      ':tipo,:documento,:documento_n,:razao,:fantasia,:responsavel,:telefone,:telefone_n,:email,:email_n,:grau,:cidade,:uf,:orgao,:site,:obs,:fonte,:data_coleta,''ATIVO'',:usuario)';
    S('tipo',ATipoDocumento); S('documento',ADocumento); S('documento_n',ADocumentoNormalizado); S('razao',ARazaoSocial); S('fantasia',ANomeFantasia);
    S('responsavel',AResponsavel); S('telefone',ATelefone); S('telefone_n',ATelefoneNormalizado); S('email',AEmail); S('email_n',AEmailNormalizado);
    S('grau',AGrau); S('cidade',ACidade); S('uf',AUF); S('orgao',AOrgao); S('site',ASite); S('obs',AObservacao); S('fonte',AFonte);
    if ATemDataColeta then Q.ParamByName('data_coleta').AsDateTime:=ADataColeta else Q.ParamByName('data_coleta').Clear;
    Q.ParamByName('usuario').AsLargeInt:=AIdUsuario; Q.Execute;
    Q.SQL.Text:='SELECT LAST_INSERT_ID() id'; Q.Open; Result:=Q.FieldByName('id').AsLargeInt;
  finally Q.Free; end;
end;

class procedure TPlataformaContatoDAO.Atualizar(
  const AConn:TUniConnection; const AId:Int64;
  const ATipoDocumento,ADocumento,ADocumentoNormalizado,ARazaoSocial,ANomeFantasia,AResponsavel,
        ATelefone,ATelefoneNormalizado,AEmail,AEmailNormalizado,AGrau,ACidade,AUF,AOrgao,ASite,AObservacao,AFonte,ASituacao:string;
  const ADataColeta:TDateTime; const ATemDataColeta:Boolean);
var Q:TUniQuery;
  procedure S(const N,V:string); begin if Trim(V).IsEmpty then Q.ParamByName(N).Clear else Q.ParamByName(N).AsString:=V; end;
begin
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='UPDATE plataforma_contato SET tipo_documento=:tipo,documento=:documento,documento_normalizado=:documento_n,razao_social=:razao,'+
      'nome_fantasia=:fantasia,responsavel=:responsavel,telefone=:telefone,telefone_normalizado=:telefone_n,email=:email,email_normalizado=:email_n,'+
      'grau=:grau,cidade=:cidade,uf=:uf,orgao=:orgao,site=:site,observacao=:obs,fonte=:fonte,data_coleta=:data_coleta,situacao=:situacao WHERE id=:id';
    S('tipo',ATipoDocumento); S('documento',ADocumento); S('documento_n',ADocumentoNormalizado); S('razao',ARazaoSocial); S('fantasia',ANomeFantasia);
    S('responsavel',AResponsavel); S('telefone',ATelefone); S('telefone_n',ATelefoneNormalizado); S('email',AEmail); S('email_n',AEmailNormalizado);
    S('grau',AGrau); S('cidade',ACidade); S('uf',AUF); S('orgao',AOrgao); S('site',ASite); S('obs',AObservacao); S('fonte',AFonte);
    if ATemDataColeta then Q.ParamByName('data_coleta').AsDateTime:=ADataColeta else Q.ParamByName('data_coleta').Clear;
    Q.ParamByName('situacao').AsString:=ASituacao; Q.ParamByName('id').AsLargeInt:=AId; Q.Execute;
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.ListarListas(const AConn:TUniConnection):TJSONArray;
var Q:TUniQuery; J:TJSONObject;
begin
  Result:=TJSONArray.Create; Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='SELECT l.id,l.nome,l.descricao,l.cidade,l.uf,l.orgao,l.grau,l.fonte,l.criado_em,COUNT(li.id_contato) total_contatos '+
      'FROM plataforma_contato_lista l LEFT JOIN plataforma_contato_lista_item li ON li.id_lista=l.id GROUP BY l.id ORDER BY l.nome'; Q.Open;
    while not Q.Eof do begin J:=TJSONObject.Create; J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt)); J.AddPair('nome',Q.FieldByName('nome').AsString);
      AddNullableString(J,'descricao',Q.FieldByName('descricao').AsString); AddNullableString(J,'cidade',Q.FieldByName('cidade').AsString); AddNullableString(J,'uf',Q.FieldByName('uf').AsString);
      AddNullableString(J,'orgao',Q.FieldByName('orgao').AsString); AddNullableString(J,'grau',Q.FieldByName('grau').AsString); AddNullableString(J,'fonte',Q.FieldByName('fonte').AsString);
      J.AddPair('total_contatos',TJSONNumber.Create(Q.FieldByName('total_contatos').AsInteger)); J.AddPair('criado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('criado_em').AsDateTime));
      Result.AddElement(J); Q.Next; end;
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.SalvarLista(const AConn:TUniConnection; const AIdUsuario,AId:Int64;
  const ANome,ADescricao,ACidade,AUF,AOrgao,AGrau,AFonte:string):Int64;
var Q:TUniQuery;
  procedure S(const N,V:string); begin if Trim(V).IsEmpty then Q.ParamByName(N).Clear else Q.ParamByName(N).AsString:=V; end;
begin
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    if AId<=0 then begin
      Q.SQL.Text:='INSERT INTO plataforma_contato_lista (nome,descricao,cidade,uf,orgao,grau,fonte,criado_por) VALUES (:nome,:descricao,:cidade,:uf,:orgao,:grau,:fonte,:usuario)';
      Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
    end else Q.SQL.Text:='UPDATE plataforma_contato_lista SET nome=:nome,descricao=:descricao,cidade=:cidade,uf=:uf,orgao=:orgao,grau=:grau,fonte=:fonte WHERE id=:id';
    Q.ParamByName('nome').AsString:=ANome; S('descricao',ADescricao); S('cidade',ACidade); S('uf',AUF); S('orgao',AOrgao); S('grau',AGrau); S('fonte',AFonte);
    if AId>0 then Q.ParamByName('id').AsLargeInt:=AId; Q.Execute;
    if AId<=0 then begin Q.SQL.Text:='SELECT LAST_INSERT_ID() id'; Q.Open; Result:=Q.FieldByName('id').AsLargeInt; end else Result:=AId;
  finally Q.Free; end;
end;

class procedure TPlataformaContatoDAO.VincularLista(const AConn:TUniConnection; const AIdLista,AIdContato:Int64);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
  Q.SQL.Text:='INSERT IGNORE INTO plataforma_contato_lista_item (id_lista,id_contato) VALUES (:lista,:contato)';
  Q.ParamByName('lista').AsLargeInt:=AIdLista; Q.ParamByName('contato').AsLargeInt:=AIdContato; Q.Execute;
finally Q.Free; end; end;

class function TPlataformaContatoDAO.ListaExiste(const AConn:TUniConnection; const AIdLista:Int64):Boolean;
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn; Q.SQL.Text:='SELECT 1 FROM plataforma_contato_lista WHERE id=:id LIMIT 1'; Q.ParamByName('id').AsLargeInt:=AIdLista; Q.Open; Result:=not Q.IsEmpty; finally Q.Free; end; end;

class function TPlataformaContatoDAO.AdicionarContatosCampanhaPorIds(const AConn:TUniConnection; const AIdCampanha:Int64; const AIds:TJSONArray):Integer;
var Q:TUniQuery; I:Integer; V:TJSONValue; Id:Int64;
begin
  Result:=0; Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='INSERT INTO plataforma_campanha_destinatario (id_campanha,id_contato_origem,nome,email,whatsapp,empresa,origem) '+
      'SELECT :campanha,c.id,COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),c.email_normalizado,c.telefone_normalizado,'+
      'COALESCE(NULLIF(c.nome_fantasia,''''),c.razao_social),''MANUAL'' FROM plataforma_contato c WHERE c.id=:contato AND c.situacao=''ATIVO'' '+
      'AND (COALESCE(c.email_normalizado,'''')<>'''' OR COALESCE(c.telefone_normalizado,'''')<>'''') '+
      'AND NOT EXISTS (SELECT 1 FROM plataforma_campanha_destinatario d WHERE d.id_campanha=:campanha AND '+
      '((c.email_normalizado IS NOT NULL AND c.email_normalizado<>'''' AND d.email=c.email_normalizado) OR '+
      '(c.telefone_normalizado IS NOT NULL AND c.telefone_normalizado<>'''' AND d.whatsapp=c.telefone_normalizado)))';
    for I:=0 to AIds.Count-1 do begin V:=AIds.Items[I]; Id:=StrToInt64Def(V.Value,0); if Id<=0 then Continue;
      Q.Close; Q.ParamByName('campanha').AsLargeInt:=AIdCampanha; Q.ParamByName('contato').AsLargeInt:=Id; Q.Execute; Inc(Result,Q.RowsAffected); end;
  finally Q.Free; end;
end;

class function TPlataformaContatoDAO.AdicionarContatosCampanhaPorLista(const AConn:TUniConnection; const AIdCampanha,AIdLista:Int64):Integer;
var Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
    Q.SQL.Text:='INSERT INTO plataforma_campanha_destinatario (id_campanha,id_contato_origem,nome,email,whatsapp,empresa,origem) '+
      'SELECT :campanha,c.id,COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),c.email_normalizado,c.telefone_normalizado,'+
      'COALESCE(NULLIF(c.nome_fantasia,''''),c.razao_social),''MANUAL'' FROM plataforma_contato_lista_item li JOIN plataforma_contato c ON c.id=li.id_contato '+
      'WHERE li.id_lista=:lista AND c.situacao=''ATIVO'' AND (COALESCE(c.email_normalizado,'''')<>'''' OR COALESCE(c.telefone_normalizado,'''')<>'''') '+
      'AND NOT EXISTS (SELECT 1 FROM plataforma_campanha_destinatario d WHERE d.id_campanha=:campanha AND '+
      '((c.email_normalizado IS NOT NULL AND c.email_normalizado<>'''' AND d.email=c.email_normalizado) OR '+
      '(c.telefone_normalizado IS NOT NULL AND c.telefone_normalizado<>'''' AND d.whatsapp=c.telefone_normalizado)))';
    Q.ParamByName('campanha').AsLargeInt:=AIdCampanha; Q.ParamByName('lista').AsLargeInt:=AIdLista; Q.Execute; Result:=Q.RowsAffected;
  finally Q.Free; end;
end;

class procedure TPlataformaContatoDAO.RegistrarAuditoria(const AConn:TUniConnection; const AIdUsuario:Int64;
  const AAcao,AEntidade,ARegistro,AMensagem,AIP,AUserAgent:string);
var Q:TUniQuery;
begin Q:=TUniQuery.Create(nil); try Q.Connection:=AConn;
  Q.SQL.Text:='INSERT INTO auditoria_log (id_instituicao,id_usuario,id_usuario_instituicao,acao,entidade,registro_id,metodo_http,rota,ip,user_agent,sucesso,mensagem) '+
    'VALUES (NULL,:usuario,NULL,:acao,:entidade,:registro,''POST'',''/v1/certifica/plataforma/contatos'',:ip,:ua,1,:msg)';
  Q.ParamByName('usuario').AsLargeInt:=AIdUsuario; Q.ParamByName('acao').AsString:=AAcao; Q.ParamByName('entidade').AsString:=AEntidade;
  Q.ParamByName('registro').AsString:=ARegistro; Q.ParamByName('ip').AsString:=Copy(Trim(AIP),1,45); Q.ParamByName('ua').AsString:=Copy(Trim(AUserAgent),1,1000);
  Q.ParamByName('msg').AsString:=Copy(Trim(AMensagem),1,1000); Q.Execute;
finally Q.Free; end; end;

end.
