unit PublicoRecuperacaoSenha.DAO;

interface

uses
  Uni;

type
  TRecuperacaoSenhaDados = record
    Valido: Boolean;
    IdToken: Int64;
    IdUsuario: Int64;
    IdInstituicao: Int64;
    Nome: string;
    Email: string;
    InstituicaoNome: string;
    InstituicaoSlug: string;
  end;

  TPublicoRecuperacaoSenhaDAO = class
  public
    class function BuscarUsuario(
      const AConn: TUniConnection;
      const ASlug,
            AEmail: string
    ): TRecuperacaoSenhaDados; static;

    class procedure RevogarTokens(
      const AConn: TUniConnection;
      const AIdUsuario,
            AIdInstituicao: Int64
    ); static;

    class procedure CriarToken(
      const AConn: TUniConnection;
      const AIdUsuario,
            AIdInstituicao: Int64;
      const AToken: string
    ); static;

    class function BuscarToken(
      const AConn: TUniConnection;
      const ASlug,
            AToken: string
    ): TRecuperacaoSenhaDados; static;

    class procedure RedefinirSenha(
      const AConn: TUniConnection;
      const AIdToken,
            AIdUsuario,
            AIdInstituicao: Int64;
      const ASenhaHash: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  APP.Errors;

class function TPublicoRecuperacaoSenhaDAO.BuscarUsuario(
  const AConn: TUniConnection;
  const ASlug,
        AEmail: string
): TRecuperacaoSenhaDados;
var
  Qry: TUniQuery;
begin
  Result := Default(TRecuperacaoSenhaDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT u.id AS id_usuario, i.id AS id_instituicao, ' +
      '       u.nome, u.email, i.slug, ' +
      '       COALESCE(NULLIF(ic.nome_exibicao, ''''), i.nome_fantasia) AS instituicao_nome ' +
      'FROM instituicao i ' +
      'JOIN usuario_instituicao ui ON ui.id_instituicao = i.id ' +
      'JOIN usuario u ON u.id = ui.id_usuario ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'WHERE i.slug = :slug ' +
      '  AND u.email_normalizado = :email ' +
      '  AND u.situacao = ''ATIVO'' ' +
      '  AND ui.situacao = ''ATIVO'' ' +
      '  AND i.situacao IN (''ATIVA'',''IMPLANTACAO'') ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := LowerCase(Trim(ASlug));
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Valido := True;
    Result.IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;
    Result.IdInstituicao := Qry.FieldByName('id_instituicao').AsLargeInt;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug := Qry.FieldByName('slug').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TPublicoRecuperacaoSenhaDAO.RevogarTokens(
  const AConn: TUniConnection;
  const AIdUsuario,
        AIdInstituicao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE usuario_recuperacao_senha ' +
      'SET revogado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_usuario = :id_usuario ' +
      '  AND id_instituicao = :id_instituicao ' +
      '  AND tipo = ''RECUPERACAO_SENHA'' ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TPublicoRecuperacaoSenhaDAO.CriarToken(
  const AConn: TUniConnection;
  const AIdUsuario,
        AIdInstituicao: Int64;
  const AToken: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario_recuperacao_senha ' +
      '(id_usuario, id_instituicao, tipo, token_hash, expira_em) ' +
      'VALUES (:id_usuario, :id_instituicao, ''RECUPERACAO_SENHA'', ' +
      'SHA2(:token, 256), DATE_ADD(CURRENT_TIMESTAMP(3), INTERVAL 30 MINUTE))';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('token').AsString := AToken;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TPublicoRecuperacaoSenhaDAO.BuscarToken(
  const AConn: TUniConnection;
  const ASlug,
        AToken: string
): TRecuperacaoSenhaDados;
var
  Qry: TUniQuery;
begin
  Result := Default(TRecuperacaoSenhaDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT r.id AS id_token, u.id AS id_usuario, i.id AS id_instituicao, ' +
      '       u.nome, u.email, i.slug, ' +
      '       COALESCE(NULLIF(ic.nome_exibicao, ''''), i.nome_fantasia) AS instituicao_nome ' +
      'FROM usuario_recuperacao_senha r ' +
      'JOIN usuario u ON u.id = r.id_usuario ' +
      'JOIN instituicao i ON i.id = r.id_instituicao ' +
      'JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = i.id AND ui.id_usuario = u.id ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'WHERE i.slug = :slug ' +
      '  AND r.tipo = ''RECUPERACAO_SENHA'' ' +
      '  AND r.token_hash = SHA2(:token, 256) ' +
      '  AND r.utilizado_em IS NULL ' +
      '  AND r.revogado_em IS NULL ' +
      '  AND r.expira_em > CURRENT_TIMESTAMP(3) ' +
      '  AND u.situacao = ''ATIVO'' ' +
      '  AND ui.situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := LowerCase(Trim(ASlug));
    Qry.ParamByName('token').AsString := Trim(AToken);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Valido := True;
    Result.IdToken := Qry.FieldByName('id_token').AsLargeInt;
    Result.IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;
    Result.IdInstituicao := Qry.FieldByName('id_instituicao').AsLargeInt;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug := Qry.FieldByName('slug').AsString;
  finally
    Qry.Free;
  end;
end;

class procedure TPublicoRecuperacaoSenhaDAO.RedefinirSenha(
  const AConn: TUniConnection;
  const AIdToken,
        AIdUsuario,
        AIdInstituicao: Int64;
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
      '  AND id_instituicao = :id_instituicao ' +
      '  AND tipo = ''RECUPERACAO_SENHA'' ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL ' +
      '  AND expira_em > CURRENT_TIMESTAMP(3)';

    Qry.ParamByName('id_token').AsLargeInt := AIdToken;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ExecSQL;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'Este link de recuperação não é mais válido.'
      );

    Qry.SQL.Text :=
      'UPDATE usuario SET ' +
      'senha_hash = :senha_hash, ' +
      'senha_alterada_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id = :id_usuario ' +
      '  AND situacao = ''ATIVO''';

    Qry.ParamByName('senha_hash').AsString := ASenhaHash;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;

    if Qry.RowsAffected <> 1 then
      TAppErrors.RaiseBadRequest(
        'Não foi possível atualizar a senha.'
      );

    Qry.SQL.Text :=
      'UPDATE usuario_recuperacao_senha SET ' +
      'revogado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_usuario = :id_usuario ' +
      '  AND id <> :id_token ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_token').AsLargeInt := AIdToken;
    Qry.ExecSQL;

    Qry.SQL.Text :=
      'UPDATE usuario_sessao SET ' +
      'revogado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_usuario = :id_usuario ' +
      '  AND revogado_em IS NULL';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
