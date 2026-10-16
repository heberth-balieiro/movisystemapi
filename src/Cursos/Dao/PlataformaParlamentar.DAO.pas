unit PlataformaParlamentar.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TPlataformaParlamentarDAO = class
  public
    class procedure MarcarForaExercicio(
      const AConn: TUniConnection;
      const AFonteDados, ACargo, AUF: string
    ); static;

    class function Upsert(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AIdExterno, ANome, AEmail, APartido, AUF,
            AUrlPerfil, AFotoUrl: string
    ): Boolean; static;

    class function UpsertSenador(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AIdExterno, ANome, AEmail, APartido, AUF,
            AUrlPerfil, AFotoUrl: string
    ): Boolean; static;

    class function Listar(
      const AConn: TUniConnection;
      const ABusca, ACargo, AUF, APartido: string;
      const AUnaleAssociado, AEmExercicio, APagina, APorPagina: Integer
    ): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils;

procedure AddNullableString(const AObj:TJSONObject; const AName,AValue:string);
begin
  if Trim(AValue).IsEmpty then
    AObj.AddPair(AName,TJSONNull.Create)
  else
    AObj.AddPair(AName,AValue);
end;

class procedure TPlataformaParlamentarDAO.MarcarForaExercicio(
  const AConn: TUniConnection;
  const AFonteDados, ACargo, AUF: string
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE plataforma_contato SET em_exercicio=0 ' +
      'WHERE tipo_contato=''PARLAMENTAR'' ' +
      'AND fonte_dados=:fonte AND cargo=:cargo ';
    if not Trim(AUF).IsEmpty then
      Q.SQL.Add('AND uf=:uf');

    Q.ParamByName('fonte').AsString := AFonteDados;
    Q.ParamByName('cargo').AsString := ACargo;
    if not Trim(AUF).IsEmpty then
      Q.ParamByName('uf').AsString := UpperCase(Trim(AUF));
    Q.Execute;
  finally
    Q.Free;
  end;
end;

class function TPlataformaParlamentarDAO.Upsert(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AIdExterno, ANome, AEmail, APartido, AUF,
        AUrlPerfil, AFotoUrl: string
): Boolean;
var
  Q: TUniQuery;
  EmailN: string;

  procedure SetNullable(const AName, AValue: string);
  begin
    if Trim(AValue).IsEmpty then
      Q.ParamByName(AName).Clear
    else
      Q.ParamByName(AName).AsString := Trim(AValue);
  end;

begin
  Result := False;
  if Trim(AIdExterno).IsEmpty or Trim(ANome).IsEmpty then
    Exit;

  EmailN := LowerCase(Trim(AEmail));

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_contato (' +
      'tipo_contato,responsavel,email,email_normalizado,grau,cargo,partido,' +
      'uf,orgao,id_externo,fonte_dados,url_perfil,foto_url,' +
      'unale_associado,em_exercicio,fonte,situacao,criado_por) VALUES (' +
      '''PARLAMENTAR'',:nome,:email,:email_n,''Deputado Federal'',' +
      '''DEPUTADO_FEDERAL'',:partido,:uf,''Câmara dos Deputados'',:id_externo,' +
      '''CAMARA_DADOS_ABERTOS'',:url_perfil,:foto_url,0,1,' +
      '''Câmara dos Deputados - Dados Abertos'',''ATIVO'',:usuario) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'responsavel=VALUES(responsavel),' +
      'email=VALUES(email),' +
      'email_normalizado=VALUES(email_normalizado),' +
      'grau=VALUES(grau),' +
      'cargo=VALUES(cargo),' +
      'partido=VALUES(partido),' +
      'uf=VALUES(uf),' +
      'orgao=VALUES(orgao),' +
      'url_perfil=VALUES(url_perfil),' +
      'foto_url=VALUES(foto_url),' +
      'em_exercicio=1,' +
      'fonte=VALUES(fonte),' +
      'situacao=''ATIVO''';

    Q.ParamByName('nome').AsString := Trim(ANome);
    SetNullable('email', AEmail);
    SetNullable('email_n', EmailN);
    SetNullable('partido', UpperCase(Trim(APartido)));
    SetNullable('uf', UpperCase(Trim(AUF)));
    Q.ParamByName('id_externo').AsString := Trim(AIdExterno);
    SetNullable('url_perfil', AUrlPerfil);
    SetNullable('foto_url', AFotoUrl);
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.Execute;
    Result := True;
  finally
    Q.Free;
  end;
end;

class function TPlataformaParlamentarDAO.UpsertSenador(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AIdExterno, ANome, AEmail, APartido, AUF,
        AUrlPerfil, AFotoUrl: string
): Boolean;
var
  Q: TUniQuery;
  EmailN: string;

  procedure SetNullable(const AName, AValue: string);
  begin
    if Trim(AValue).IsEmpty then
      Q.ParamByName(AName).Clear
    else
      Q.ParamByName(AName).AsString := Trim(AValue);
  end;

begin
  Result := False;
  if Trim(AIdExterno).IsEmpty or Trim(ANome).IsEmpty then
    Exit;

  EmailN := LowerCase(Trim(AEmail));

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO plataforma_contato (' +
      'tipo_contato,responsavel,email,email_normalizado,grau,cargo,partido,' +
      'uf,orgao,id_externo,fonte_dados,url_perfil,foto_url,' +
      'unale_associado,em_exercicio,fonte,situacao,criado_por) VALUES (' +
      '''PARLAMENTAR'',:nome,:email,:email_n,''Senador'',' +
      '''SENADOR'',:partido,:uf,''Senado Federal'',:id_externo,' +
      '''SENADO_DADOS_ABERTOS'',:url_perfil,:foto_url,0,1,' +
      '''Senado Federal - Dados Abertos'',''ATIVO'',:usuario) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'responsavel=VALUES(responsavel),' +
      'email=VALUES(email),' +
      'email_normalizado=VALUES(email_normalizado),' +
      'grau=VALUES(grau),' +
      'cargo=VALUES(cargo),' +
      'partido=VALUES(partido),' +
      'uf=VALUES(uf),' +
      'orgao=VALUES(orgao),' +
      'url_perfil=VALUES(url_perfil),' +
      'foto_url=VALUES(foto_url),' +
      'em_exercicio=1,' +
      'fonte=VALUES(fonte),' +
      'situacao=''ATIVO''';

    Q.ParamByName('nome').AsString := Trim(ANome);
    SetNullable('email', AEmail);
    SetNullable('email_n', EmailN);
    SetNullable('partido', UpperCase(Trim(APartido)));
    SetNullable('uf', UpperCase(Trim(AUF)));
    Q.ParamByName('id_externo').AsString := Trim(AIdExterno);
    SetNullable('url_perfil', AUrlPerfil);
    SetNullable('foto_url', AFotoUrl);
    Q.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Q.Execute;
    Result := True;
  finally
    Q.Free;
  end;
end;

class function TPlataformaParlamentarDAO.Listar(
  const AConn: TUniConnection;
  const ABusca, ACargo, AUF, APartido: string;
  const AUnaleAssociado, AEmExercicio, APagina, APorPagina: Integer
): TJSONObject;
var
  Q:TUniQuery;
  Arr:TJSONArray;
  J,Pag:TJSONObject;
  W:string;
  Pagina,PorPagina,Total,TotalPaginas:Integer;

  procedure Params;
  begin
    if not Trim(ABusca).IsEmpty then
      Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ACargo).IsEmpty then
      Q.ParamByName('cargo').AsString := UpperCase(Trim(ACargo));
    if not Trim(AUF).IsEmpty then
      Q.ParamByName('uf').AsString := UpperCase(Trim(AUF));
    if not Trim(APartido).IsEmpty then
      Q.ParamByName('partido').AsString := UpperCase(Trim(APartido));
    if AUnaleAssociado in [0,1] then
      Q.ParamByName('unale').AsInteger := AUnaleAssociado;
    if AEmExercicio in [0,1] then
      Q.ParamByName('exercicio').AsInteger := AEmExercicio;
  end;
begin
  Pagina:=APagina;
  if Pagina<=0 then Pagina:=1;
  PorPagina:=APorPagina;
  if PorPagina<=0 then PorPagina:=50;
  if PorPagina>200 then PorPagina:=200;

  W:=' WHERE tipo_contato=''PARLAMENTAR'' ';
  if not Trim(ABusca).IsEmpty then
    W:=W+'AND (responsavel LIKE :busca OR email LIKE :busca OR id_externo LIKE :busca) ';
  if not Trim(ACargo).IsEmpty then W:=W+'AND cargo=:cargo ';
  if not Trim(AUF).IsEmpty then W:=W+'AND uf=:uf ';
  if not Trim(APartido).IsEmpty then W:=W+'AND partido=:partido ';
  if AUnaleAssociado in [0,1] then W:=W+'AND unale_associado=:unale ';
  if AEmExercicio in [0,1] then W:=W+'AND em_exercicio=:exercicio ';

  Q:=TUniQuery.Create(nil);
  try
    Q.Connection:=AConn;
    Q.SQL.Text:='SELECT COUNT(*) total FROM plataforma_contato '+W;
    Params;
    Q.Open;
    Total:=Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text:=
      'SELECT id,responsavel,email,telefone,cargo,partido,uf,cidade,orgao,' +
      'id_externo,fonte_dados,url_perfil,foto_url,unale_associado,' +
      'em_exercicio,situacao,atualizado_em ' +
      'FROM plataforma_contato '+W+
      'ORDER BY cargo,uf,responsavel LIMIT :limite OFFSET :offset';
    Params;
    Q.ParamByName('limite').AsInteger:=PorPagina;
    Q.ParamByName('offset').AsInteger:=(Pagina-1)*PorPagina;
    Q.Open;

    Arr:=TJSONArray.Create;
    while not Q.Eof do
    begin
      J:=TJSONObject.Create;
      J.AddPair('id',TJSONNumber.Create(Q.FieldByName('id').AsLargeInt));
      AddNullableString(J,'nome',Q.FieldByName('responsavel').AsString);
      AddNullableString(J,'email',Q.FieldByName('email').AsString);
      AddNullableString(J,'telefone',Q.FieldByName('telefone').AsString);
      AddNullableString(J,'cargo',Q.FieldByName('cargo').AsString);
      AddNullableString(J,'partido',Q.FieldByName('partido').AsString);
      AddNullableString(J,'uf',Q.FieldByName('uf').AsString);
      AddNullableString(J,'cidade',Q.FieldByName('cidade').AsString);
      AddNullableString(J,'orgao',Q.FieldByName('orgao').AsString);
      AddNullableString(J,'id_externo',Q.FieldByName('id_externo').AsString);
      AddNullableString(J,'fonte_dados',Q.FieldByName('fonte_dados').AsString);
      AddNullableString(J,'url_perfil',Q.FieldByName('url_perfil').AsString);
      AddNullableString(J,'foto_url',Q.FieldByName('foto_url').AsString);
      J.AddPair('unale_associado',TJSONBool.Create(Q.FieldByName('unale_associado').AsBoolean));
      J.AddPair('em_exercicio',TJSONBool.Create(Q.FieldByName('em_exercicio').AsBoolean));
      J.AddPair('situacao',Q.FieldByName('situacao').AsString);
      J.AddPair('atualizado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Q.FieldByName('atualizado_em').AsDateTime));
      Arr.AddElement(J);
      Q.Next;
    end;

    TotalPaginas:=0;
    if Total>0 then TotalPaginas:=(Total+PorPagina-1) div PorPagina;
    Pag:=TJSONObject.Create;
    Pag.AddPair('pagina',TJSONNumber.Create(Pagina));
    Pag.AddPair('por_pagina',TJSONNumber.Create(PorPagina));
    Pag.AddPair('total',TJSONNumber.Create(Total));
    Pag.AddPair('total_paginas',TJSONNumber.Create(TotalPaginas));
    Result:=TJSONObject.Create;
    Result.AddPair('itens',Arr);
    Result.AddPair('paginacao',Pag);
  finally
    Q.Free;
  end;
end;

end.
