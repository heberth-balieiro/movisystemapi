unit PlataformaParlamentar.DAO;

interface

uses
  Uni;

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
  end;

implementation

uses
  System.SysUtils;

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

end.
