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
  end;

implementation

uses
  System.SysUtils;

procedure AddNullable(const O:TJSONObject; const N,V:string);
begin
  if O.GetValue(N)<>nil then
    Exit;
  if Trim(V).IsEmpty then
    O.AddPair(N,TJSONNull.Create)
  else
    O.AddPair(N,V);
end;

class procedure TPlataformaContatoColetaEntidadeDAO.AtualizarParametros(
  const AConn:TUniConnection;
  const AId:Int64;
  const ATermoBusca,ASegmento:string
);
var
  Q:TUniQuery;
begin
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'UPDATE plataforma_contato_coleta SET ' +
      'termo_busca=:termo,segmento=:segmento WHERE id=:id';

    if Trim(ATermoBusca).IsEmpty then
      Q.ParamByName('termo').Clear
    else
      Q.ParamByName('termo').AsString:=Trim(ATermoBusca);

    if Trim(ASegmento).IsEmpty then
      Q.ParamByName('segmento').Clear
    else
      Q.ParamByName('segmento').AsString:=UpperCase(Trim(ASegmento));

    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.EnriquecerColeta(
  const AConn:TUniConnection;
  const AId:Int64;
  const AJSON:TJSONObject
);
var
  Q:TUniQuery;
begin
  if (AJSON=nil) or (AId<=0) then
    Exit;

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT termo_busca,segmento FROM plataforma_contato_coleta ' +
      'WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AId;
    Q.Open;
    if Q.IsEmpty then
      Exit;

    AddNullable(AJSON,'termo_busca',Q.FieldByName('termo_busca').AsString);
    AddNullable(AJSON,'segmento',Q.FieldByName('segmento').AsString);
  finally
    Q.Free;
  end;
end;

class procedure TPlataformaContatoColetaEntidadeDAO.EnriquecerLista(
  const AConn:TUniConnection;
  const AJSON:TJSONObject
);
var
  V:TJSONValue;
  A:TJSONArray;
  I:Integer;
  O:TJSONObject;
  Id:Int64;
begin
  if AJSON=nil then
    Exit;

  V:=AJSON.GetValue('itens');
  if not (V is TJSONArray) then
    Exit;

  A:=V as TJSONArray;
  for I:=0 to A.Count-1 do
  begin
    if not (A.Items[I] is TJSONObject) then
      Continue;
    O:=A.Items[I] as TJSONObject;
    Id:=StrToInt64Def(O.GetValue<string>('id','0'),0);
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
  Novos:=0;
  Existentes:=0;
  Vinculados:=0;

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;

    Q.SQL.Text:=
      'SELECT tipo,segmento FROM plataforma_contato_coleta ' +
      'WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AIdColeta;
    Q.Open;
    if Q.IsEmpty then
      raise Exception.Create('Coleta não encontrada.');

    Tipo:=UpperCase(Q.FieldByName('tipo').AsString);
    Segmento:=UpperCase(Trim(Q.FieldByName('segmento').AsString));

    if Tipo='SINDICATO' then
      Orgao:='Sindicato'
    else if Tipo='ASSOCIACAO' then
      Orgao:='Associação'
    else
      raise Exception.Create('Tipo de entidade não suportado para importação.');

    if Segmento.IsEmpty then
      Grau:=Orgao
    else
      Grau:=Segmento;

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
      'i.coletado_em,''ATIVO'',:usuario ' +
      'FROM plataforma_contato_coleta_item i ' +
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
        'INSERT IGNORE INTO plataforma_contato_lista_item ' +
        '(id_lista,id_contato) ' +
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
  finally
    Q.Free;
  end;
end;

end.
