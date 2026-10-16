unit PlataformaCampanhaPublico.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaCampanhaPublicoDAO = class
  private
    class function MontarWhere(
      const ATipo, ABusca, AUF, AMunicipio, APartido, ACanal: string;
      const AEmExercicio, AUnaleAssociado, ATemEmail, ATemWhatsApp: Integer
    ): string; static;
    class procedure AplicarParametros(
      const Q: TUniQuery;
      const ATipo, ABusca, AUF, AMunicipio, APartido: string
    ); static;
  public
    class function ObterCampanhaContexto(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      out ASituacao, ACanal: string
    ): Boolean; static;

    class function Listar(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const ACanal, ATipo, ABusca, AUF, AMunicipio, APartido: string;
      const AEmExercicio, AUnaleAssociado, ATemEmail, ATemWhatsApp: Integer;
      const APagina, APorPagina: Integer
    ): TJSONObject; static;

    class function AdicionarPorFiltro(
      const AConn: TUniConnection;
      const AIdCampanha: Int64;
      const ACanal, ATipo, ABusca, AUF, AMunicipio, APartido: string;
      const AEmExercicio, AUnaleAssociado, ATemEmail, ATemWhatsApp: Integer
    ): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

procedure AddNullable(const O:TJSONObject; const N,V:string);
begin
  if Trim(V).IsEmpty then
    O.AddPair(N,TJSONNull.Create)
  else
    O.AddPair(N,V);
end;

class function TPlataformaCampanhaPublicoDAO.MontarWhere(
  const ATipo, ABusca, AUF, AMunicipio, APartido, ACanal: string;
  const AEmExercicio, AUnaleAssociado, ATemEmail, ATemWhatsApp: Integer
): string;
var
  Tipo, Canal:string;
begin
  Tipo:=UpperCase(Trim(ATipo));
  Canal:=UpperCase(Trim(ACanal));
  Result:=' WHERE c.situacao=''ATIVO'' ';

  if Tipo='CAMARA' then
    Result:=Result+
      'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' '+
      'AND (c.orgao=''Câmara Municipal'' OR c.grau=''Câmara Municipal'') '
  else if Tipo='PREFEITURA' then
    Result:=Result+
      'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' '+
      'AND (c.orgao=''Prefeitura Municipal'' OR c.grau=''Prefeitura Municipal'') '
  else if Tipo='SINDICATO' then
    Result:=Result+
      'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' '+
      'AND (c.orgao=''Sindicato'' OR c.grau=''Sindicato'') '
  else if Tipo='ASSOCIACAO' then
    Result:=Result+
      'AND COALESCE(c.tipo_contato,''ENTIDADE'')<>''PARLAMENTAR'' '+
      'AND (c.orgao=''Associação'' OR c.grau=''Associação'') '
  else if Tipo='UNALE_ASSOCIADO' then
    Result:=Result+'AND c.tipo_contato=''PARLAMENTAR'' AND c.unale_associado=1 '
  else if MatchText(Tipo,['VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR']) then
    Result:=Result+'AND c.tipo_contato=''PARLAMENTAR'' AND c.cargo=:cargo ';

  if not Trim(ABusca).IsEmpty then
    Result:=Result+
      'AND (c.responsavel LIKE :busca OR c.nome_fantasia LIKE :busca '+
      'OR c.razao_social LIKE :busca OR c.email_normalizado LIKE :busca '+
      'OR c.documento_normalizado LIKE :busca) ';

  if not Trim(AUF).IsEmpty then
    Result:=Result+'AND c.uf=:uf ';
  if not Trim(AMunicipio).IsEmpty then
    Result:=Result+'AND c.cidade=:municipio ';
  if not Trim(APartido).IsEmpty then
    Result:=Result+'AND c.partido=:partido ';

  if AEmExercicio=1 then
    Result:=Result+'AND c.em_exercicio=1 '
  else if AEmExercicio=0 then
    Result:=Result+'AND c.em_exercicio=0 ';

  if AUnaleAssociado=1 then
    Result:=Result+'AND c.unale_associado=1 '
  else if AUnaleAssociado=0 then
    Result:=Result+'AND c.unale_associado=0 ';

  if ATemEmail=1 then
    Result:=Result+'AND COALESCE(c.email_normalizado,'''')<>'''' '
  else if ATemEmail=0 then
    Result:=Result+'AND COALESCE(c.email_normalizado,'''')='''' ';

  if ATemWhatsApp=1 then
    Result:=Result+'AND COALESCE(c.telefone_normalizado,'''')<>'''' '
  else if ATemWhatsApp=0 then
    Result:=Result+'AND COALESCE(c.telefone_normalizado,'''')='''' ';

  if Canal='EMAIL' then
    Result:=Result+'AND COALESCE(c.email_normalizado,'''')<>'''' '
  else if Canal='WHATSAPP' then
    Result:=Result+'AND COALESCE(c.telefone_normalizado,'''')<>'''' '
  else
    Result:=Result+
      'AND (COALESCE(c.email_normalizado,'''')<>'''' '+
      'OR COALESCE(c.telefone_normalizado,'''')<>'''') ';
end;

class procedure TPlataformaCampanhaPublicoDAO.AplicarParametros(
  const Q:TUniQuery;
  const ATipo,ABusca,AUF,AMunicipio,APartido:string
);
begin
  if MatchText(UpperCase(Trim(ATipo)),['VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR']) then
    Q.ParamByName('cargo').AsString:=UpperCase(Trim(ATipo));
  if not Trim(ABusca).IsEmpty then
    Q.ParamByName('busca').AsString:='%'+Trim(ABusca)+'%';
  if not Trim(AUF).IsEmpty then
    Q.ParamByName('uf').AsString:=UpperCase(Trim(AUF));
  if not Trim(AMunicipio).IsEmpty then
    Q.ParamByName('municipio').AsString:=Trim(AMunicipio);
  if not Trim(APartido).IsEmpty then
    Q.ParamByName('partido').AsString:=UpperCase(Trim(APartido));
end;

class function TPlataformaCampanhaPublicoDAO.ObterCampanhaContexto(
  const AConn:TUniConnection;
  const AIdCampanha:Int64;
  out ASituacao,ACanal:string
):Boolean;
var
  Q:TUniQuery;
begin
  ASituacao:='';
  ACanal:='';
  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT situacao,canal FROM plataforma_campanha WHERE id=:id LIMIT 1';
    Q.ParamByName('id').AsLargeInt:=AIdCampanha;
    Q.Open;
    Result:=not Q.IsEmpty;
    if Result then
    begin
      ASituacao:=Q.FieldByName('situacao').AsString;
      ACanal:=Q.FieldByName('canal').AsString;
    end;
  finally
    Q.Free;
  end;
end;

class function TPlataformaCampanhaPublicoDAO.Listar(
  const AConn:TUniConnection;
  const AIdCampanha:Int64;
  const ACanal,ATipo,ABusca,AUF,AMunicipio,APartido:string;
  const AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp,APagina,APorPagina:Integer
):TJSONObject;
var
  Q:TUniQuery;
  Arr:TJSONArray;
  J,Pag,Resumo:TJSONObject;
  W:string;
  Pagina,PorPagina,Total,TotalPaginas,JaAdicionados:Integer;
begin
  Pagina:=APagina;
  if Pagina<=0 then Pagina:=1;
  PorPagina:=APorPagina;
  if PorPagina<=0 then PorPagina:=50;
  if PorPagina>200 then PorPagina:=200;

  W:=MontarWhere(
    ATipo,ABusca,AUF,AMunicipio,APartido,ACanal,
    AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp
  );

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'SELECT COUNT(*) total, '+
      'SUM(CASE WHEN EXISTS ('+
      'SELECT 1 FROM plataforma_campanha_destinatario d '+
      'WHERE d.id_campanha=:campanha AND d.id_contato_origem=c.id'+
      ') THEN 1 ELSE 0 END) adicionados '+
      'FROM plataforma_contato c '+W;
    Q.ParamByName('campanha').AsLargeInt:=AIdCampanha;
    AplicarParametros(Q,ATipo,ABusca,AUF,AMunicipio,APartido);
    Q.Open;
    Total:=Q.FieldByName('total').AsInteger;
    JaAdicionados:=0;
    if not Q.FieldByName('adicionados').IsNull then
      JaAdicionados:=Q.FieldByName('adicionados').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'SELECT c.id,c.tipo_contato,c.razao_social,c.nome_fantasia,'+
      'c.responsavel,c.telefone,c.email,c.grau,c.cidade,c.uf,c.orgao,'+
      'c.cargo,c.partido,c.unale_associado,c.em_exercicio,'+
      'EXISTS ('+
      'SELECT 1 FROM plataforma_campanha_destinatario d '+
      'WHERE d.id_campanha=:campanha AND d.id_contato_origem=c.id'+
      ') ja_adicionado '+
      'FROM plataforma_contato c '+W+
      'ORDER BY c.uf,c.cidade,'+
      'COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),c.id '+
      'LIMIT :limite OFFSET :offset';
    Q.ParamByName('campanha').AsLargeInt:=AIdCampanha;
    AplicarParametros(Q,ATipo,ABusca,AUF,AMunicipio,APartido);
    Q.ParamByName('limite').AsInteger:=PorPagina;
    Q.ParamByName('offset').AsInteger:=(Pagina-1)*PorPagina;
    Q.Open;

    Arr:=TJSONArray.Create;
    while not Q.Eof do
    begin
      J:=TJSONObject.Create;
      J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      AddNullable(J,'tipo_contato',Q.FieldByName('tipo_contato').AsString);
      AddNullable(J,'razao_social',Q.FieldByName('razao_social').AsString);
      AddNullable(J,'nome_fantasia',Q.FieldByName('nome_fantasia').AsString);
      AddNullable(J,'responsavel',Q.FieldByName('responsavel').AsString);
      AddNullable(J,'telefone',Q.FieldByName('telefone').AsString);
      AddNullable(J,'email',Q.FieldByName('email').AsString);
      AddNullable(J,'grau',Q.FieldByName('grau').AsString);
      AddNullable(J,'cidade',Q.FieldByName('cidade').AsString);
      AddNullable(J,'uf',Q.FieldByName('uf').AsString);
      AddNullable(J,'orgao',Q.FieldByName('orgao').AsString);
      AddNullable(J,'cargo',Q.FieldByName('cargo').AsString);
      AddNullable(J,'partido',Q.FieldByName('partido').AsString);
      J.AddPair('unale_associado',TJSONBool.Create(Q.FieldByName('unale_associado').AsBoolean));
      J.AddPair('em_exercicio',TJSONBool.Create(Q.FieldByName('em_exercicio').AsBoolean));
      J.AddPair('ja_adicionado',TJSONBool.Create(Q.FieldByName('ja_adicionado').AsInteger=1));
      Arr.AddElement(J);
      Q.Next;
    end;

    TotalPaginas:=0;
    if Total>0 then
      TotalPaginas:=(Total+PorPagina-1) div PorPagina;

    Pag:=TJSONObject.Create;
    Pag.AddPair('pagina',TJSONNumber.Create(Pagina));
    Pag.AddPair('por_pagina',TJSONNumber.Create(PorPagina));
    Pag.AddPair('total',TJSONNumber.Create(Total));
    Pag.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));

    Resumo:=TJSONObject.Create;
    Resumo.AddPair('encontrados',TJSONNumber.Create(Total));
    Resumo.AddPair('ja_adicionados',TJSONNumber.Create(JaAdicionados));
    Resumo.AddPair('disponiveis',TJSONNumber.Create(Total-JaAdicionados));
    Resumo.AddPair('canal',UpperCase(Trim(ACanal)));

    Result:=TJSONObject.Create;
    Result.AddPair('itens',Arr);
    Result.AddPair('paginacao',Pag);
    Result.AddPair('resumo',Resumo);
  finally
    Q.Free;
  end;
end;

class function TPlataformaCampanhaPublicoDAO.AdicionarPorFiltro(
  const AConn:TUniConnection;
  const AIdCampanha:Int64;
  const ACanal,ATipo,ABusca,AUF,AMunicipio,APartido:string;
  const AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp:Integer
):Integer;
var
  Q:TUniQuery;
  W:string;
begin
  W:=MontarWhere(
    ATipo,ABusca,AUF,AMunicipio,APartido,ACanal,
    AEmExercicio,AUnaleAssociado,ATemEmail,ATemWhatsApp
  );

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:=
      'INSERT INTO plataforma_campanha_destinatario '+
      '(id_campanha,id_contato_origem,nome,email,whatsapp,empresa,origem) '+
      'SELECT :campanha,c.id,'+
      'COALESCE(NULLIF(c.responsavel,''''),NULLIF(c.nome_fantasia,''''),c.razao_social),'+
      'c.email_normalizado,c.telefone_normalizado,'+
      'COALESCE(NULLIF(c.nome_fantasia,''''),c.razao_social),''BASE_CONTATOS'' '+
      'FROM plataforma_contato c '+W+
      'AND NOT EXISTS ('+
      'SELECT 1 FROM plataforma_campanha_destinatario d '+
      'WHERE d.id_campanha=:campanha '+
      'AND (d.id_contato_origem=c.id '+
      'OR (COALESCE(c.email_normalizado,'''')<>'''' AND d.email=c.email_normalizado) '+
      'OR (COALESCE(c.telefone_normalizado,'''')<>'''' AND d.whatsapp=c.telefone_normalizado))'+
      ')';
    Q.ParamByName('campanha').AsLargeInt:=AIdCampanha;
    AplicarParametros(Q,ATipo,ABusca,AUF,AMunicipio,APartido);
    Q.Execute;
    Result:=Q.RowsAffected;
  finally
    Q.Free;
  end;
end;

end.
