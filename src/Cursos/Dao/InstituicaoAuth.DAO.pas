unit InstituicaoAuth.DAO;

interface

uses
  Uni;

type
  TInstituicaoLoginDados = record
    IdUsuario: Int64;
    IdUsuarioInstituicao: Int64;
    IdInstituicao: Int64;

    Nome: string;
    Email: string;
    SenhaHash: string;

    UsuarioSituacao: string;
    VinculoSituacao: string;

    InstituicaoSlug: string;
    InstituicaoNome: string;
    InstituicaoSituacao: string;

    Principal: Boolean;

    CorPrimaria: string;
    CorSecundaria: string;
    CorDestaque: string;
    CorFundo: string;
    CorTexto: string;
    LogoUrl: string;
  end;

  TInstituicaoAuthDAO = class
  public
    class function BuscarLogin(
      const AConn: TUniConnection;
      const ASlug, ALogin: string;
      out ADados: TInstituicaoLoginDados
    ): Boolean; static;

    class procedure RegistrarLogin(
      const AConn: TUniConnection;
      const AIdUsuario, AIdUsuarioInstituicao: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoAuthDAO.BuscarLogin(
  const AConn: TUniConnection;
  const ASlug, ALogin: string;
  out ADados: TInstituicaoLoginDados
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  ADados := Default(TInstituicaoLoginDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      '  u.id AS id_usuario, ' +
      '  ui.id AS id_usuario_instituicao, ' +
      '  i.id AS id_instituicao, ' +
      '  u.nome, ' +
      '  u.email, ' +
      '  u.senha_hash, ' +
      '  u.situacao AS usuario_situacao, ' +
      '  ui.situacao AS vinculo_situacao, ' +
      '  ui.principal, ' +
      '  i.slug, ' +
      '  i.nome_fantasia, ' +
      '  i.situacao AS instituicao_situacao, ' +
      '  COALESCE(ic.logo_url, '''') AS logo_url, ' +
      '  COALESCE(ic.cor_primaria, ''#2563EB'') AS cor_primaria, ' +
      '  COALESCE(ic.cor_secundaria, ''#1E40AF'') AS cor_secundaria, ' +
      '  COALESCE(ic.cor_destaque, ''#F59E0B'') AS cor_destaque, ' +
      '  COALESCE(ic.cor_fundo, ''#F8FAFC'') AS cor_fundo, ' +
      '  COALESCE(ic.cor_texto, ''#0F172A'') AS cor_texto ' +

      'FROM instituicao i ' +

      'INNER JOIN usuario_instituicao ui ' +
      '        ON ui.id_instituicao = i.id ' +

      'INNER JOIN usuario u ' +
      '        ON u.id = ui.id_usuario ' +

      'LEFT JOIN instituicao_configuracao ic ' +
      '       ON ic.id_instituicao = i.id ' +

      'WHERE i.slug = :slug ' +
      '  AND (' +
      '       LOWER(ui.login) = :login ' +
      '       OR u.email_normalizado = :login' +
      '      ) ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString :=
      LowerCase(Trim(ASlug));

    Qry.ParamByName('login').AsString :=
      LowerCase(Trim(ALogin));

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    ADados.IdUsuario :=
      Qry.FieldByName('id_usuario').AsLargeInt;

    ADados.IdUsuarioInstituicao :=
      Qry.FieldByName('id_usuario_instituicao').AsLargeInt;

    ADados.IdInstituicao :=
      Qry.FieldByName('id_instituicao').AsLargeInt;

    ADados.Nome :=
      Qry.FieldByName('nome').AsString;

    ADados.Email :=
      Qry.FieldByName('email').AsString;

    ADados.SenhaHash :=
      Qry.FieldByName('senha_hash').AsString;

    ADados.UsuarioSituacao :=
      Qry.FieldByName('usuario_situacao').AsString;

    ADados.VinculoSituacao :=
      Qry.FieldByName('vinculo_situacao').AsString;

    ADados.InstituicaoSlug :=
      Qry.FieldByName('slug').AsString;

    ADados.InstituicaoNome :=
      Qry.FieldByName('nome_fantasia').AsString;

    ADados.InstituicaoSituacao :=
      Qry.FieldByName('instituicao_situacao').AsString;

    ADados.Principal :=
      Qry.FieldByName('principal').AsBoolean;

    ADados.LogoUrl :=
      Qry.FieldByName('logo_url').AsString;

    ADados.CorPrimaria :=
      Qry.FieldByName('cor_primaria').AsString;

    ADados.CorSecundaria :=
      Qry.FieldByName('cor_secundaria').AsString;

    ADados.CorDestaque :=
      Qry.FieldByName('cor_destaque').AsString;

    ADados.CorFundo :=
      Qry.FieldByName('cor_fundo').AsString;

    ADados.CorTexto :=
      Qry.FieldByName('cor_texto').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoAuthDAO.RegistrarLogin(
  const AConn: TUniConnection;
  const AIdUsuario, AIdUsuarioInstituicao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE usuario ' +
      'SET ultimo_login_em = CURRENT_TIMESTAMP ' +
      'WHERE id = :id_usuario';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.Execute;

    Qry.SQL.Text :=
      'UPDATE usuario_instituicao ' +
      'SET ultimo_acesso_em = CURRENT_TIMESTAMP ' +
      'WHERE id = :id_usuario_instituicao';

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
