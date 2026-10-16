unit PlataformaContatoColetaEntidade.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaContatoColetaEntidadeDAO = class
  public
    class procedure AtualizarParametros(
      const AConn:TUniConnection;
      const AId:Int64;
      const ATermoBusca,ASegmento:string
    ); static;

    class procedure EnriquecerColeta(
      const AConn:TUniConnection;
      const AId:Int64;
      const AJSON:TJSONObject
    ); static;

    class procedure EnriquecerLista(
      const AConn:TUniConnection;
      const AJSON:TJSONObject
    ); static;

    class function ImportarAprovados(
      const AConn:TUniConnection;
      const AIdColeta,AIdLista,AIdUsuario:Int64
    ):TJSONObject; static;

    class procedure AtualizarMetadadosParlamentar(
      const AConn:TUniConnection;
      const AIdColeta:Int64;
      const ANome,ACidade,AUF,AEmail,ATipoContato,ACargo,APartido,
            AIdExterno,AFonteDados,AUrlPerfil,AFotoUrl:string;
      const AUnaleAssociado:Boolean
    ); static;

    class procedure EnriquecerItensParlamentares(
      const AConn:TUniConnection;
      const AResultado:TJSONObject
    ); static;

    class function ImportarAprovadosParlamentares(
      const AConn:TUniConnection;
      const AIdColeta,AIdLista,AIdUsuario:Int64
    ):TJSONObject; static;
  end;

implementation

uses
  System.SysUtils;

procedure AddNullable(const O:TJSONObject; const N,V:string);
begin
  if O.GetValue(N)<>nil then Exit;
  if Trim(V).IsEmpty then O.AddPair(N,TJSONNull.Create)
  else O.AddPair(N,V);
end;

class procedure TPlataformaContatoColetaEntidadeDAO.AtualizarParametros(
  const AConn:TUniConnection;
  const AId:Int64;
  const ATermoBusca,ASegmento:string
);
var Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'termo_busca=:termo,segmento=:segmento WHERE id=:id';
    if Trim(ATermoBusca).IsEmpty then Q.ParamByName('termo').Clear
    else Q.ParamByName('termo').AsString:=Trim(ATermoBusca);
    if Trim(ASegmento).IsEmpty then Q.ParamByName('segmento').Clear
    else Q.ParamByName('segmento').AsString:=UpperCase(Trim(ASegmento));
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally Q.Free; end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(
  const AConn:TUniConnection;
  const AId:Int64;
  const AJSON:TJSONObject
);
var Q:TUniQuery;
begin
  if (AJSON=nil) or (AId<=0) then Exit;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT termo_busca,segmento FROM plataforma_contato_coleta ' +
      'WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Open;
    if Q.IsEmpty then Exit;
    AddNullable(AJSON,'termo_busca',Q.FieldByName('termo_busca').AsString);
    AddNullable(AJSON,'segmento',Q.FieldByName('segmento').AsString);
  finally Q.Free; end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.EnriquecerLista(
  const AConn:TUniConnection;
  const AJSON:TJSONObject
);
var
  VId,V:TJSONValue;
  A:TJSONArray;
  I:Integer;
  O:TJSONObject;
  Id:Int64;
begin
  if AJSON=nil then Exit;
  V:=AJSON.GetValue('itens');
  if not (V is TJSONArray) then Exit;
  A:=V as TJSONArray;
  for I:=0 to A.Count-1 do
  begin
    if not (A.Items[I] is TJSONObject) then Continue;
    O:=A.Items[I] as TJSONObject;
    VId:=O.GetValue('id');
    if VId=nil then Continue;
    Id:=StrToInt64Def(VId.Value,0);
    EnriquecerColeta(AConn,Id,O);
  end;
end;

class function TPlataformaContatoColetaEntidadeDAO.ImportarAprovados(
  const AConn:TUniConnection;
  const AIdColeta,AIdLista,AIdUsuario:Int64
):TJSONObject;
var
  Q:TUniQuery;
  Novos,Existentes,Vinculados:Integer;
  Tipo,Orgao,Grau,Segmento:string;
begin
  Novos:=0; Existentes:=0; Vinculados:=0;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT tipo,segmento FROM plataforma_contato_coleta ' +
      'WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AIdColeta;
    Q.Open;
    if Q.IsEmpty then raise Exception.Create('Coleta não encontrada.');

    Tipo:=UpperCase(Q.FieldByName('tipo').AsString);
    Segmento:=UpperCase(Trim(Q.FieldByName('segmento').AsString));
    if Tipo='SINDICATO' then Orgao:='Sindicato'
    else if Tipo='ASSOCIACAO' then Orgao:='Associação'
    else raise Exception.Create('Tipo de entidade não suportado para importação.');

    if Segmento.IsEmpty then Grau:=Orgao else Grau:=Segmento;

    Q.Close;
    Q.SQL.Text:=
      'SELECT COUNT(*) total FROM plataforma_contato_coleta_item ' +
      'WHERE id_coleta=:coleta AND situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(email,'''')<>''''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Open;
    Existentes:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'INSERT INTO plataforma_contato ' +
      '(razao_social,nome_fantasia,email,email_normalizado,grau,cidade,uf,' +
      'orgao,site,observacao,fonte,data_coleta,situacao,criado_por) ' +
      'SELECT i.nome_orgao,i.nome_orgao,i.email,LOWER(i.email),:grau,' +
      'i.cidade,i.uf,:orgao,i.site,i.observacao,i.pagina_origem,' +
      'i.coletado_em,''ATIVO'',:usuario FROM plataforma_contato_coleta_item i ' +
      'WHERE i.id_coleta=:coleta AND i.situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(i.email,'''')<>'''' AND NOT EXISTS (' +
      'SELECT 1 FROM plataforma_contato c ' +
      'WHERE c.email_normalizado=LOWER(i.email))';
    Q.ParamByName('grau').AsString:=Grau;
    Q.ParamByName('orgao').AsString:=Orgao;
    Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;
    Novos:=Q.RowsAffected;
    Existentes:=Existentes-Novos;

    Q.Close;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta_item i ' +
      'JOIN plataforma_contato c ON c.email_normalizado=LOWER(i.email) ' +
      'SET i.id_contato=c.id,i.situacao_revisao=''IMPORTADO'' ' +
      'WHERE i.id_coleta=:coleta AND i.situacao_revisao=''APROVADO''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;

    if AIdLista>0 then
    begin
      Q.Close;
      Q.SQL.Text:=
        'INSERT IGNORE INTO plataforma_contato_lista_item (id_lista,id_contato) ' +
        'SELECT :lista,id_contato FROM plataforma_contato_coleta_item ' +
        'WHERE id_coleta=:coleta AND situacao_revisao=''IMPORTADO'' ' +
        'AND id_contato IS NOT NULL';
      Q.ParamByName('lista').AsLargeInt:=AIdLista;
      Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
      Q.Execute;
      Vinculados:=Q.RowsAffected;
    end;

    Result:=TJSONObject.Create;
    Result.AddPair('novos',TJSONNumber.Create(Novos));
    Result.AddPair('existentes',TJSONNumber.Create(Existentes));
    Result.AddPair('vinculados_lista',TJSONNumber.Create(Vinculados));
  finally Q.Free; end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.AtualizarMetadadosParlamentar(
  const AConn:TUniConnection;
  const AIdColeta:Int64;
  const ANome,ACidade,AUF,AEmail,ATipoContato,ACargo,APartido,
        AIdExterno,AFonteDados,AUrlPerfil,AFotoUrl:string;
  const AUnaleAssociado:Boolean
);
var
  Q:TUniQuery;
  procedure S(const N,V:string);
  begin
    if Trim(V).IsEmpty then Q.ParamByName(N).Clear
    else Q.ParamByName(N).AsString:=Trim(V);
  end;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta_item SET ' +
      'tipo_contato=:tipo_contato,cargo=:cargo,partido=:partido,' +
      'id_externo=:id_externo,fonte_dados=:fonte_dados,' +
      'url_perfil=:url_perfil,foto_url=:foto_url,unale_associado=:unale ' +
      'WHERE id_coleta=:coleta AND nome_orgao=:nome AND cidade=:cidade ' +
      'AND uf=:uf AND ((:email='''' AND COALESCE(email,'''')='''') OR email=:email) ' +
      'ORDER BY id DESC LIMIT 1';
    S('tipo_contato',UpperCase(ATipoContato));
    S('cargo',UpperCase(ACargo));
    S('partido',UpperCase(APartido));
    S('id_externo',AIdExterno);
    S('fonte_dados',UpperCase(AFonteDados));
    S('url_perfil',AUrlPerfil);
    S('foto_url',AFotoUrl);
    Q.ParamByName('unale').AsInteger:=Ord(AUnaleAssociado);
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.ParamByName('nome').AsString:=Trim(ANome);
    Q.ParamByName('cidade').AsString:=Trim(ACidade);
    Q.ParamByName('uf').AsString:=UpperCase(Trim(AUF));
    Q.ParamByName('email').AsString:=LowerCase(Trim(AEmail));
    Q.Execute;
  finally Q.Free; end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.EnriquecerItensParlamentares(
  const AConn:TUniConnection;
  const AResultado:TJSONObject
);
var
  V:TJSONValue;
  A:TJSONArray;
  O:TJSONObject;
  Q:TUniQuery;
  Id:Int64;
  K:Integer;
begin
  if AResultado=nil then Exit;
  V:=AResultado.GetValue('itens');
  if not (V is TJSONArray) then Exit;
  A:=V as TJSONArray;

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    for K:=0 to A.Count-1 do
    begin
      if not (A.Items[K] is TJSONObject) then Continue;
      O:=A.Items[K] as TJSONObject;
      V:=O.GetValue('id');
      if V=nil then Continue;
      Id:=StrToInt64Def(V.Value,0);
      if Id<=0 then Continue;

      Q.Close;
      Q.SQL.Text:=
        'SELECT tipo_contato,cargo,partido,id_externo,fonte_dados,' +
        'url_perfil,foto_url,unale_associado ' +
        'FROM plataforma_contato_coleta_item WHERE id=:id';
      Q.ParamByName('id').AsLargeInt:=Id;
      Q.Open;
      if Q.IsEmpty then Continue;

      AddNullable(O,'tipo_contato',Q.FieldByName('tipo_contato').AsString);
      AddNullable(O,'cargo',Q.FieldByName('cargo').AsString);
      AddNullable(O,'partido',Q.FieldByName('partido').AsString);
      AddNullable(O,'id_externo',Q.FieldByName('id_externo').AsString);
      AddNullable(O,'fonte_dados',Q.FieldByName('fonte_dados').AsString);
      AddNullable(O,'url_perfil',Q.FieldByName('url_perfil').AsString);
      AddNullable(O,'foto_url',Q.FieldByName('foto_url').AsString);
      if O.GetValue('unale_associado')=nil then
        O.AddPair('unale_associado',TJSONBool.Create(Q.FieldByName('unale_associado').AsInteger=1));
    end;
  finally
    Q.Free;
  end;
end;

class function TPlataformaContatoColetaEntidadeDAO.ImportarAprovadosParlamentares(
  const AConn:TUniConnection;
  const AIdColeta,AIdLista,AIdUsuario:Int64
):TJSONObject;
var
  Q:TUniQuery;
  Novos,Existentes,Vinculados:Integer;
begin
  Novos:=0; Existentes:=0; Vinculados:=0;
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT COUNT(*) total FROM plataforma_contato_coleta_item ' +
      'WHERE id_coleta=:coleta AND situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(email,'''')<>''''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Open;
    Existentes:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'INSERT INTO plataforma_contato (' +
      'tipo_contato,responsavel,email,email_normalizado,grau,cargo,partido,' +
      'cidade,uf,orgao,id_externo,fonte_dados,url_perfil,foto_url,' +
      'unale_associado,em_exercicio,site,observacao,fonte,data_coleta,' +
      'situacao,criado_por) ' +
      'SELECT ''PARLAMENTAR'',i.nome_orgao,i.email,LOWER(i.email),' +
      'CASE i.cargo WHEN ''VEREADOR'' THEN ''Vereador'' ' +
      'WHEN ''DEPUTADO_ESTADUAL'' THEN ''Deputado Estadual'' ELSE ''Parlamentar'' END,' +
      'i.cargo,i.partido,i.cidade,i.uf,' +
      'CASE i.cargo WHEN ''VEREADOR'' THEN ''Câmara Municipal'' ' +
      'WHEN ''DEPUTADO_ESTADUAL'' THEN ''Assembleia Legislativa'' ELSE ''UNALE'' END,' +
      'i.id_externo,i.fonte_dados,i.url_perfil,i.foto_url,' +
      'i.unale_associado,1,i.site,i.observacao,i.pagina_origem,' +
      'i.coletado_em,''ATIVO'',:usuario ' +
      'FROM plataforma_contato_coleta_item i ' +
      'WHERE i.id_coleta=:coleta AND i.situacao_revisao=''APROVADO'' ' +
      'AND COALESCE(i.email,'''')<>'''' AND NOT EXISTS (' +
      'SELECT 1 FROM plataforma_contato c WHERE ' +
      '(COALESCE(i.fonte_dados,'''')<>'''' AND COALESCE(i.id_externo,'''')<>'''' ' +
      'AND c.fonte_dados=i.fonte_dados AND c.id_externo=i.id_externo) OR ' +
      'c.email_normalizado=LOWER(i.email))';
    Q.ParamByName('usuario').AsLargeInt:=AIdUsuario;
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;
    Novos:=Q.RowsAffected;
    Existentes:=Existentes-Novos;

    Q.Close;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta_item i ' +
      'JOIN plataforma_contato c ON (' +
      '(COALESCE(i.fonte_dados,'''')<>'''' AND COALESCE(i.id_externo,'''')<>'''' ' +
      'AND c.fonte_dados=i.fonte_dados AND c.id_externo=i.id_externo) OR ' +
      'c.email_normalizado=LOWER(i.email)) ' +
      'SET i.id_contato=c.id,i.situacao_revisao=''IMPORTADO'' ' +
      'WHERE i.id_coleta=:coleta AND i.situacao_revisao=''APROVADO''';
    Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
    Q.Execute;

    if AIdLista>0 then
    begin
      Q.Close;
      Q.SQL.Text:=
        'INSERT IGNORE INTO plataforma_contato_lista_item (id_lista,id_contato) ' +
        'SELECT :lista,id_contato FROM plataforma_contato_coleta_item ' +
        'WHERE id_coleta=:coleta AND situacao_revisao=''IMPORTADO'' ' +
        'AND id_contato IS NOT NULL';
      Q.ParamByName('lista').AsLargeInt:=AIdLista;
      Q.ParamByName('coleta').AsLargeInt:=AIdColeta;
      Q.Execute;
      Vinculados:=Q.RowsAffected;
    end;

    Result:=TJSONObject.Create;
    Result.AddPair('novos',TJSONNumber.Create(Novos));
    Result.AddPair('existentes',TJSONNumber.Create(Existentes));
    Result.AddPair('vinculados_lista',TJSONNumber.Create(Vinculados));
  finally Q.Free; end;
end;

end.
