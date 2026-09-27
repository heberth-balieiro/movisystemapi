unit PublicoPrimeiroAcesso.DAO;

interface

uses
  Uni;

type
  TPrimeiroAcessoDados = record
    Valido: Boolean;
    IdToken: Int64;
    IdUsuario: Int64;
    Nome: string;
    Email: string;
    InstituicaoNome: string;
    InstituicaoSlug: string;
  end;

  TPublicoPrimeiroAcessoDAO = class
  public
    class function Buscar(
      const AConn: TUniConnection;
      const ASlug,
            AToken: string
    ): TPrimeiroAcessoDados; static;

    class procedure DefinirSenha(
      const AConn: TUniConnection;
      const AIdToken,
            AIdUsuario: Int64;
      const ASenhaHash: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  APP.Errors;

class function TPublicoPrimeiroAcessoDAO.Buscar(
  const AConn: TUniConnection;
  const ASlug,
        AToken: string
): TPrimeiroAcessoDados;
var
  Qry: TUniQuery;
begin
  Result :=
    Default(
      TPrimeiroAcessoDados
    );

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'r.id AS id_token, ' +
      'u.id AS id_usuario, ' +
      'u.nome, u.email, ' +
      'i.nome AS instituicao_nome, ' +
      'i.slug AS instituicao_slug ' +
      'FROM usuario_recuperacao_senha r ' +
      'JOIN usuario u ON u.id = r.id_usuario ' +
      'JOIN usuario_instituicao ui ON ui.id_usuario = u.id ' +
      'JOIN instituicao i ON i.id = ui.id_instituicao ' +
      'JOIN participante p ' +
      '  ON p.id_instituicao = ui.id_instituicao ' +
      ' AND p.id_usuario_instituicao = ui.id ' +
      'WHERE i.slug = :slug ' +
      '  AND r.token_hash = SHA2(:token, 256) ' +
      '  AND r.utilizado_em IS NULL ' +
      '  AND r.revogado_em IS NULL ' +
      '  AND r.expira_em > CURRENT_TIMESTAMP(3) ' +
      '  AND u.situacao = ''ATIVO'' ' +
      '  AND ui.situacao = ''ATIVO'' ' +
      '  AND p.situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString :=
      LowerCase(
        Trim(ASlug)
      );

    Qry.ParamByName('token').AsString :=
      Trim(AToken);

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Valido := True;
    Result.IdToken :=
      Qry.FieldByName('id_token').AsLargeInt;
    Result.IdUsuario :=
      Qry.FieldByName('id_usuario').AsLargeInt;
    Result.Nome :=
      Qry.FieldByName('nome').AsString;
    Result.Email :=
      Qry.FieldByName('email').AsString;
    Result.InstituicaoNome :=
      Qry.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug :=
      Qry.FieldByName('instituicao_slug').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TPublicoPrimeiroAcessoDAO.DefinirSenha(
  const AConn: TUniConnection;
  const AIdToken,
        AIdUsuario: Int64;
  const ASenhaHash: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE usuario_recuperacao_senha SET ' +
      'utilizado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id = :id_token ' +
      '  AND id_usuario = :id_usuario ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL ' +
      '  AND expira_em > CURRENT_TIMESTAMP(3)';

    Qry.ParamByName('id_token').AsLargeInt :=
      AIdToken;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ExecSQL;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'Este link de primeiro acesso não é mais válido.'
      );

    Qry.SQL.Text :=
      'UPDATE usuario SET ' +
      'senha_hash = :senha_hash, ' +
      'senha_alterada_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id = :id_usuario ' +
      '  AND situacao = ''ATIVO''';

    Qry.ParamByName('senha_hash').AsString :=
      ASenhaHash;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ExecSQL;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'Não foi possível definir a senha do usuário.'
      );

    Qry.SQL.Text :=
      'UPDATE usuario_recuperacao_senha SET ' +
      'revogado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_usuario = :id_usuario ' +
      '  AND id <> :id_token ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ParamByName('id_token').AsLargeInt :=
      AIdToken;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
