unit PlataformaUsuario.DAO;

interface

uses
  Uni,
  System.Generics.Collections,
  PlataformaUsuario.Model;

type
  TPlataformaUsuarioDAO = class
  public
    class function ExisteEmail(const AConn: TUniConnection; const AEmail: string): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const ANome, AEmail, ASenhaHash: string
    ): Int64; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AId: Int64
    ): TPlataformaUsuarioModel; static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdUsuarioCriado, AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string
    ); static;

    class function Listar(const AConn: TUniConnection): TObjectList<TPlataformaUsuarioModel>; static;

    class function ExisteEmailOutroUsuario(const AConn: TUniConnection;const AEmail: string;const AIdUsuario: Int64): Boolean; static;
    class procedure Atualizar(const AConn: TUniConnection;const AIdUsuario: Int64;const ANome, AEmail: string); static;
    class procedure RegistrarAuditoriaAlteracao(const AConn: TUniConnection;const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;const AIP, AUserAgent: string); static;


    class function QuantidadeSuperAdminsAtivos(
      const AConn: TUniConnection
    ): Integer; static;

    class procedure AtualizarSituacao(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ASituacao: string
    ); static;

    class procedure RegistrarAuditoriaSituacao(
      const AConn: TUniConnection;
      const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;
      const ASituacao, AIP, AUserAgent: string
    ); static;


    class procedure AtualizarSenha(
      const AConn: TUniConnection;
      const AIdUsuario: Int64;
      const ASenhaHash: string
    ); static;

    class procedure RegistrarAuditoriaRenovacaoSenha(
      const AConn: TUniConnection;
      const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string
    ); static;

  end;

implementation

uses
  System.SysUtils;

class procedure TPlataformaUsuarioDAO.AtualizarSenha(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const ASenhaHash: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // A senha em texto puro nunca é persistida.
    Qry.SQL.Text :=
      'UPDATE usuario SET ' +
      'senha_hash = :senha_hash, ' +
      'senha_alterada_em = CURRENT_TIMESTAMP, ' +
      'atualizado_em = CURRENT_TIMESTAMP ' +
      'WHERE id = :id ' +
      '  AND is_super_admin = 1';

    Qry.ParamByName('senha_hash').AsString := ASenhaHash;
    Qry.ParamByName('id').AsLargeInt := AIdUsuario;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioDAO.RegistrarAuditoriaRenovacaoSenha(
  const AConn: TUniConnection;
  const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      'metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ''PLATAFORMA_USUARIO_SENHA_RENOVADA'', ''usuario'', :registro_id, ' +
      '''POST'', :rota, :ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioAcao;
    Qry.ParamByName('registro_id').AsString := AIdUsuarioAlterado.ToString;

    Qry.ParamByName('rota').AsString :=
      '/v1/certifica/plataforma/usuarios/' +
      AIdUsuarioAlterado.ToString +
      '/renovar-senha';

    Qry.ParamByName('ip').AsString :=
      Copy(Trim(AIP), 1, 45);

    Qry.ParamByName('user_agent').AsString :=
      Copy(Trim(AUserAgent), 1, 1000);

    // Nunca registrar a senha temporária no log.
    Qry.ParamByName('mensagem').AsString :=
      'Senha do usuário administrador da plataforma renovada.';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioDAO.ExisteEmail(
  const AConn: TUniConnection;
  const AEmail: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario ' +
      'WHERE email_normalizado = :email ' +
      'LIMIT 1';

    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;



class function TPlataformaUsuarioDAO.Inserir(
  const AConn: TUniConnection;
  const ANome, AEmail, ASenhaHash: string
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // Usuários cadastrados por esta rota são sempre administradores globais da MoviSystem.
    Qry.SQL.Text :=
      'INSERT INTO usuario ' +
      '(nome, email, email_normalizado, senha_hash, is_super_admin, situacao) ' +
      'VALUES ' +
      '(:nome, :email, :email_normalizado, :senha_hash, 1, ''ATIVO'')';

    Qry.ParamByName('nome').AsString := Trim(ANome);
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('email_normalizado').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('senha_hash').AsString := ASenhaHash;

    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;

    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioDAO.Listar(const AConn: TUniConnection): TObjectList<TPlataformaUsuarioModel>;
var
  Qry: TUniQuery;
  Usuario: TPlataformaUsuarioModel;
begin
  Result := TObjectList<TPlataformaUsuarioModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // A administração MoviSystem lista somente usuários globais da plataforma.
    Qry.SQL.Text :=
      'SELECT id, nome, email, situacao, ultimo_login_em, criado_em ' +
      'FROM usuario ' +
      'WHERE is_super_admin = 1 ' +
      'ORDER BY nome';

    Qry.Open;

    while not Qry.Eof do
    begin
      Usuario := TPlataformaUsuarioModel.Create;

      Usuario.Id := Qry.FieldByName('id').AsLargeInt;
      Usuario.Nome := Qry.FieldByName('nome').AsString;
      Usuario.Email := Qry.FieldByName('email').AsString;
      Usuario.Situacao := Qry.FieldByName('situacao').AsString;
      Usuario.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;

      Usuario.TemUltimoLogin := not Qry.FieldByName('ultimo_login_em').IsNull;

      if Usuario.TemUltimoLogin then
        Usuario.UltimoLoginEm := Qry.FieldByName('ultimo_login_em').AsDateTime;

      Result.Add(Usuario);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;


class function TPlataformaUsuarioDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AId: Int64
): TPlataformaUsuarioModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id, nome, email, situacao, ultimo_login_em, criado_em ' +
      'FROM usuario ' +
      'WHERE id = :id ' +
      '  AND is_super_admin = 1 ' +
      'LIMIT 1';

    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TPlataformaUsuarioModel.Create;

    Result.Id := Qry.FieldByName('id').AsLargeInt;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.Email := Qry.FieldByName('email').AsString;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
    Result.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;

    Result.TemUltimoLogin := not Qry.FieldByName('ultimo_login_em').IsNull;

    if Result.TemUltimoLogin then
      Result.UltimoLoginEm := Qry.FieldByName('ultimo_login_em').AsDateTime;

  finally
    Qry.Free;
  end;
end;



class procedure TPlataformaUsuarioDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdUsuarioCriado, AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      'metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ''PLATAFORMA_USUARIO_CRIADO'', ''usuario'', :registro_id, ' +
      '''POST'', ''/v1/certifica/plataforma/usuarios'', :ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioAcao;
    Qry.ParamByName('registro_id').AsString := AIdUsuarioCriado.ToString;
    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);
    Qry.ParamByName('mensagem').AsString := 'Usuário administrador da plataforma cadastrado.';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaUsuarioDAO.ExisteEmailOutroUsuario(
  const AConn: TUniConnection;
  const AEmail: string;
  const AIdUsuario: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario ' +
      'WHERE email_normalizado = :email ' +
      '  AND id <> :id ' +
      'LIMIT 1';

    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('id').AsLargeInt := AIdUsuario;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const ANome, AEmail: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // Esta operação altera somente os dados cadastrais do administrador.
    // Situação, senha e privilégios permanecem sob controle de rotas específicas.
    Qry.SQL.Text :=
      'UPDATE usuario SET ' +
      'nome = :nome, ' +
      'email = :email, ' +
      'email_normalizado = :email_normalizado, ' +
      'atualizado_em = CURRENT_TIMESTAMP ' +
      'WHERE id = :id ' +
      '  AND is_super_admin = 1';

    Qry.ParamByName('nome').AsString := Trim(ANome);
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('email_normalizado').AsString := LowerCase(Trim(AEmail));
    Qry.ParamByName('id').AsLargeInt := AIdUsuario;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioDAO.RegistrarAuditoriaAlteracao(
  const AConn: TUniConnection;
  const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      'metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, ''PLATAFORMA_USUARIO_ALTERADO'', ''usuario'', :registro_id, ' +
      '''PUT'', :rota, :ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioAcao;
    Qry.ParamByName('registro_id').AsString := AIdUsuarioAlterado.ToString;
    Qry.ParamByName('rota').AsString :=
      '/v1/certifica/plataforma/usuarios/' + AIdUsuarioAlterado.ToString;

    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);
    Qry.ParamByName('mensagem').AsString :=
      'Dados do usuário administrador da plataforma alterados.';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;


class function TPlataformaUsuarioDAO.QuantidadeSuperAdminsAtivos(
  const AConn: TUniConnection
): Integer;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM usuario ' +
      'WHERE is_super_admin = 1 ' +
      '  AND situacao = ''ATIVO''';

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioDAO.AtualizarSituacao(
  const AConn: TUniConnection;
  const AIdUsuario: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE usuario SET ' +
      'situacao = :situacao, ' +
      'atualizado_em = CURRENT_TIMESTAMP ' +
      'WHERE id = :id ' +
      '  AND is_super_admin = 1';

    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id').AsLargeInt := AIdUsuario;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaUsuarioDAO.RegistrarAuditoriaSituacao(
  const AConn: TUniConnection;
  const AIdUsuarioAlterado, AIdUsuarioAcao: Int64;
  const ASituacao, AIP, AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, acao, entidade, registro_id, ' +
      'metodo_http, rota, ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(NULL, :id_usuario, NULL, :acao, ''usuario'', :registro_id, ' +
      '''PATCH'', :rota, :ip, :user_agent, 1, :mensagem)';

    if ASituacao = 'ATIVO' then
      Qry.ParamByName('acao').AsString := 'PLATAFORMA_USUARIO_REATIVADO'
    else
      Qry.ParamByName('acao').AsString := 'PLATAFORMA_USUARIO_INATIVADO';

    Qry.ParamByName('id_usuario').AsLargeInt := AIdUsuarioAcao;
    Qry.ParamByName('registro_id').AsString := AIdUsuarioAlterado.ToString;

    Qry.ParamByName('rota').AsString :=
      '/v1/certifica/plataforma/usuarios/' +
      AIdUsuarioAlterado.ToString +
      '/situacao';

    Qry.ParamByName('ip').AsString := Copy(Trim(AIP), 1, 45);
    Qry.ParamByName('user_agent').AsString := Copy(Trim(AUserAgent), 1, 1000);

    Qry.ParamByName('mensagem').AsString :=
      'Situação do usuário administrador alterada para ' + ASituacao + '.';

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
