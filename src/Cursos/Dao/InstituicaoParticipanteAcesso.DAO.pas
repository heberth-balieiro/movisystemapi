unit InstituicaoParticipanteAcesso.DAO;

interface

uses
  Uni,
  InstituicaoParticipanteAcesso.Model;

type
  TParticipanteBaseAcesso = record
    Encontrado: Boolean;
    IdParticipante: Int64;
    IdUnidadeOrganizacional: Int64;
    TemUnidadeOrganizacional: Boolean;
    IdUsuarioInstituicao: Int64;
    TemUsuarioInstituicao: Boolean;
    Nome: string;
    Email: string;
    Telefone: string;
    InstituicaoNome: string;
    InstituicaoSlug: string;
    Situacao: string;
  end;

  TUsuarioGlobalAcesso = record
    Encontrado: Boolean;
    IdUsuario: Int64;
    Nome: string;
    Email: string;
    Situacao: string;
    TemSenhaDefinida: Boolean;
  end;

  TInstituicaoParticipanteAcessoDAO = class
  public
    class function BuscarParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TParticipanteBaseAcesso; static;

    class function BuscarUsuarioPorEmail(
      const AConn: TUniConnection;
      const AEmailNormalizado: string
    ): TUsuarioGlobalAcesso; static;

    class function BuscarUsuarioVinculado(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TUsuarioGlobalAcesso; static;

    class function CriarUsuario(
      const AConn: TUniConnection;
      const ANome,
            AEmail,
            AEmailNormalizado,
            ASenhaHash: string
    ): Int64; static;

    class procedure RevogarTokensSenha(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ); static;

    class procedure CriarTokenSenha(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const AToken: string;
      const AExpiraHoras: Integer
    ); static;

    class function BuscarUsuarioInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario: Int64
    ): Int64; static;

    class function UsuarioInstituicaoEhAdministrativo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): Boolean; static;

    class function UsuarioPossuiTokenSenhaPendente(
      const AConn: TUniConnection;
      const AIdUsuario: Int64
    ): Boolean; static;

    class function CriarUsuarioInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario,
            AIdUnidadeOrganizacional: Int64;
      const ATemUnidadeOrganizacional: Boolean
    ): Int64; static;

    class function UsuarioInstituicaoJaLigadoOutroParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdParticipanteIgnorar: Int64
    ): Boolean; static;

    class procedure VincularParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante,
            AIdUsuarioInstituicao: Int64
    ); static;

    class procedure RevogarVinculo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ); static;

    class function BuscarInfo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdParticipante: Int64
    ): TParticipanteAcessoInfo; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoParticipanteAcessoDAO.BuscarParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteBaseAcesso;
var
  Qry: TUniQuery;
begin
  Result := Default(TParticipanteBaseAcesso);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT p.id, p.id_unidade_organizacional, p.id_usuario_instituicao, ' +
      '       p.nome, p.email, p.telefone, p.situacao, ' +
      '       COALESCE(NULLIF(ic.nome_exibicao, ''''), i.nome_fantasia) AS instituicao_nome, ' +
      '       i.slug AS instituicao_slug ' +
      'FROM participante p ' +
      'JOIN instituicao i ON i.id = p.id_instituicao ' +
      'LEFT JOIN instituicao_configuracao ic ON ic.id_instituicao = i.id ' +
      'WHERE p.id_instituicao = :id_instituicao AND p.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdParticipante;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado := True;
    Result.IdParticipante               := Qry.FieldByName('id').AsLargeInt;
    Result.TemUnidadeOrganizacional     := not Qry.FieldByName('id_unidade_organizacional').IsNull;
    if Result.TemUnidadeOrganizacional then
      Result.IdUnidadeOrganizacional    := Qry.FieldByName('id_unidade_organizacional').AsLargeInt;

    Result.TemUsuarioInstituicao := not Qry.FieldByName('id_usuario_instituicao').IsNull;
    if Result.TemUsuarioInstituicao then
      Result.IdUsuarioInstituicao := Qry.FieldByName('id_usuario_instituicao').AsLargeInt;

    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.Telefone := Qry.FieldByName('telefone').AsString;
    Result.InstituicaoNome := Qry.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug := Qry.FieldByName('instituicao_slug').AsString;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.BuscarUsuarioPorEmail(
  const AConn: TUniConnection;
  const AEmailNormalizado: string
): TUsuarioGlobalAcesso;
var
  Qry: TUniQuery;
begin
  Result := Default(TUsuarioGlobalAcesso);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, nome, email, situacao, senha_alterada_em ' +
      'FROM usuario WHERE email_normalizado = :email LIMIT 1';

    Qry.ParamByName('email').AsString := AEmailNormalizado;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado     := True;
    Result.IdUsuario      := Qry.FieldByName('id').AsLargeInt;
    Result.Nome           := Qry.FieldByName('nome').AsString;
    Result.Email          := Qry.FieldByName('email').AsString;
    Result.Situacao       := Qry.FieldByName('situacao').AsString;
    Result.TemSenhaDefinida :=
      not Qry.FieldByName('senha_alterada_em').IsNull;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.BuscarUsuarioVinculado(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): TUsuarioGlobalAcesso;
var
  Qry: TUniQuery;
begin
  Result :=
    Default(
      TUsuarioGlobalAcesso
    );

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT u.id, u.nome, u.email, u.situacao, u.senha_alterada_em ' +
      'FROM participante p ' +
      'JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = p.id_instituicao ' +
      ' AND ui.id = p.id_usuario_instituicao ' +
      'JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE p.id_instituicao = :id_instituicao ' +
      '  AND p.id = :id_participante ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_participante').AsLargeInt :=
      AIdParticipante;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado := True;
    Result.IdUsuario :=
      Qry.FieldByName('id').AsLargeInt;
    Result.Nome :=
      Qry.FieldByName('nome').AsString;
    Result.Email :=
      Qry.FieldByName('email').AsString;
    Result.Situacao :=
      Qry.FieldByName('situacao').AsString;
    Result.TemSenhaDefinida :=
      not Qry.FieldByName('senha_alterada_em').IsNull;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.CriarUsuario(
  const AConn: TUniConnection;
  const ANome,
        AEmail,
        AEmailNormalizado,
        ASenhaHash: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario ' +
      '(nome, email, email_normalizado, senha_hash, is_super_admin, situacao, senha_alterada_em) ' +
      'VALUES (:nome, :email, :email_normalizado, :senha_hash, 0, ''ATIVO'', NULL)';

    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('email').AsString := AEmail;
    Qry.ParamByName('email_normalizado').AsString := AEmailNormalizado;
    Qry.ParamByName('senha_hash').AsString := ASenhaHash;
    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteAcessoDAO.RevogarTokensSenha(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
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
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteAcessoDAO.CriarTokenSenha(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const AToken: string;
  const AExpiraHoras: Integer
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario_recuperacao_senha ' +
      '(id_usuario, token_hash, expira_em) ' +
      'VALUES (:id_usuario, SHA2(:token, 256), ' +
      'DATE_ADD(CURRENT_TIMESTAMP(3), INTERVAL :horas HOUR))';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.ParamByName('token').AsString :=
      AToken;

    Qry.ParamByName('horas').AsInteger :=
      AExpiraHoras;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.BuscarUsuarioInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario: Int64
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id FROM usuario_instituicao ' +
      'WHERE id_instituicao = :id_instituicao AND id_usuario = :id_usuario LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt  := AIdInstituicao;
    Qry.ParamByName('id_usuario').AsLargeInt      := AIdUsuario;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.UsuarioInstituicaoEhAdministrativo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario_instituicao ui ' +
      'WHERE ui.id_instituicao = :id_instituicao ' +
      '  AND ui.id = :id_usuario_instituicao ' +
      '  AND (' +
      '       ui.principal = 1 ' +
      '       OR EXISTS (' +
      '          SELECT 1 ' +
      '          FROM usuario_instituicao_perfil uip ' +
      '          JOIN perfil p ' +
      '            ON p.id_instituicao = uip.id_instituicao ' +
      '           AND p.id = uip.id_perfil ' +
      '           AND p.situacao = ''ATIVO'' ' +
      '          WHERE uip.id_instituicao = ui.id_instituicao ' +
      '            AND uip.id_usuario_instituicao = ui.id' +
      '       )' +
      '      ) ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.UsuarioPossuiTokenSenhaPendente(
  const AConn: TUniConnection;
  const AIdUsuario: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario_recuperacao_senha ' +
      'WHERE id_usuario = :id_usuario ' +
      '  AND utilizado_em IS NULL ' +
      '  AND revogado_em IS NULL ' +
      '  AND expira_em > CURRENT_TIMESTAMP(3) ' +
      'LIMIT 1';

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.CriarUsuarioInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario,
        AIdUnidadeOrganizacional: Int64;
  const ATemUnidadeOrganizacional: Boolean
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO usuario_instituicao ' +
      '(id_instituicao, id_usuario, id_unidade_organizacional, login, situacao, principal) ' +
      'VALUES (:id_instituicao, :id_usuario, :id_unidade, NULL, ''ATIVO'', 0)';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuario;

    if ATemUnidadeOrganizacional then
      Qry.ParamByName('id_unidade').AsLargeInt := AIdUnidadeOrganizacional
    else
      Qry.ParamByName('id_unidade').Clear;

    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.UsuarioInstituicaoJaLigadoOutroParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdParticipanteIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_usuario_instituicao = :id_usuario_instituicao ' +
      'AND id <> :id_participante LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipanteIgnorar;
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteAcessoDAO.VincularParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante,
        AIdUsuarioInstituicao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE participante SET id_usuario_instituicao = :id_usuario_instituicao ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id';

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt := AIdUsuarioInstituicao;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdParticipante;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoParticipanteAcessoDAO.RevogarVinculo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE participante SET id_usuario_instituicao = NULL ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdParticipante;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoParticipanteAcessoDAO.BuscarInfo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdParticipante: Int64
): TParticipanteAcessoInfo;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT p.id AS id_participante, p.nome, p.email, ' +
      'ui.id AS id_usuario_instituicao, ui.situacao AS situacao_vinculo, ' +
      'u.id AS id_usuario, u.situacao AS situacao_usuario ' +
      'FROM participante p ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = p.id_instituicao AND ui.id = p.id_usuario_instituicao ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE p.id_instituicao = :id_instituicao AND p.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdParticipante;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TParticipanteAcessoInfo.Create;
    Result.IdParticipante := Qry.FieldByName('id_participante').AsLargeInt;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.AcessoLiberado := not Qry.FieldByName('id_usuario_instituicao').IsNull;

    if Result.AcessoLiberado then
    begin
      Result.IdUsuarioInstituicao := Qry.FieldByName('id_usuario_instituicao').AsLargeInt;
      Result.IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;
      Result.SituacaoVinculo := Qry.FieldByName('situacao_vinculo').AsString;
      Result.SituacaoUsuario := Qry.FieldByName('situacao_usuario').AsString;
    end;
  finally
    Qry.Free;
  end;
end;

end.
