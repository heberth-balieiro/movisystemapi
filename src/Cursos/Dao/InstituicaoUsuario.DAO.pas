unit InstituicaoUsuario.DAO;

interface

uses
  Uni,
  InstituicaoUsuario.Model;

type
  TInstituicaoUsuarioGlobalDados = record
    Id: Int64;
    Nome: string;
    Email: string;
    Situacao: string;
  end;

  TInstituicaoUsuarioDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoUsuarioFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoUsuarioFiltro
    ); static;

    class function MapearUsuario(
      const AQry: TUniQuery
    ): TInstituicaoUsuarioItem; static;

    class procedure CarregarPerfis(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const AUsuario: TInstituicaoUsuarioItem
    ); static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoUsuarioFiltro
    ): TInstituicaoUsuarioLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoUsuarioItem; static;

    class function BuscarUsuarioGlobalPorEmail(
      const AConn: TUniConnection;
      const AEmail: string;
      out ADados: TInstituicaoUsuarioGlobalDados
    ): Boolean; static;

    class function UsuarioJaVinculado(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario: Int64
    ): Boolean; static;

    class function ExisteLogin(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ALogin: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function InserirUsuarioGlobal(
      const AConn: TUniConnection;
      const ANome,
            AEmail,
            ASenhaHash: string
    ): Int64; static;

    class function InserirVinculo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuario: Int64;
      const ALogin: string
    ): Int64; static;

    class procedure AtualizarLogin(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ALogin: string
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ASituacao: string
    ); static;

    class function PerfilAtivoPertenceInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdPerfil: Int64
    ): Boolean; static;

    class procedure SubstituirPerfis(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const APerfis: TArray<Int64>
    ); static;

    class procedure RegistrarAuditoria(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioAcao,
            AIdUsuarioInstituicaoAcao,
            AIdUsuarioInstituicaoAlterado: Int64;
      const AAcao,
            AMetodo,
            ARota,
            AMensagem,
            AIP,
            AUserAgent: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoUsuarioDAO.MontarWhere(
  const AFiltro: TInstituicaoUsuarioFiltro
): string;
begin
  Result :=
    ' WHERE ui.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result :=
      Result +
      ' AND (' +
      'u.nome LIKE :busca OR ' +
      'u.email LIKE :busca OR ' +
      'ui.login LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND ui.situacao = :situacao ';
end;

class procedure TInstituicaoUsuarioDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoUsuarioFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoUsuarioDAO.MapearUsuario(
  const AQry: TUniQuery
): TInstituicaoUsuarioItem;
begin
  Result := TInstituicaoUsuarioItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.IdUsuario :=
    AQry.FieldByName('id_usuario').AsLargeInt;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Email :=
    AQry.FieldByName('email').AsString;

  Result.Login :=
    AQry.FieldByName('login').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.Principal :=
    AQry.FieldByName('principal').AsBoolean;

  Result.TemUltimoAcesso :=
    not AQry.FieldByName('ultimo_acesso_em').IsNull;

  if Result.TemUltimoAcesso then
    Result.UltimoAcessoEm :=
      AQry.FieldByName('ultimo_acesso_em').AsDateTime;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class procedure TInstituicaoUsuarioDAO.CarregarPerfis(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const AUsuario: TInstituicaoUsuarioItem
);
var
  Qry: TUniQuery;
  Perfil: TInstituicaoUsuarioPerfilItem;
begin
  if AUsuario = nil then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT p.id, p.nome, p.sistema, p.situacao ' +
      'FROM usuario_instituicao_perfil uip ' +
      'JOIN perfil p ' +
      '  ON p.id_instituicao = uip.id_instituicao ' +
      ' AND p.id = uip.id_perfil ' +
      'WHERE uip.id_instituicao = :id_instituicao ' +
      '  AND uip.id_usuario_instituicao = :id_usuario_instituicao ' +
      'ORDER BY p.sistema DESC, p.nome';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Open;

    while not Qry.Eof do
    begin
      Perfil := TInstituicaoUsuarioPerfilItem.Create;

      Perfil.Id :=
        Qry.FieldByName('id').AsLargeInt;

      Perfil.Nome :=
        Qry.FieldByName('nome').AsString;

      Perfil.Sistema :=
        Qry.FieldByName('sistema').AsBoolean;

      Perfil.Situacao :=
        Qry.FieldByName('situacao').AsString;

      AUsuario.Perfis.Add(Perfil);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoUsuarioFiltro
): TInstituicaoUsuarioLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
  Usuario: TInstituicaoUsuarioItem;
begin
  Result := TInstituicaoUsuarioLista.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(AFiltro);

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM usuario_instituicao ui ' +
        'JOIN usuario u ON u.id = ui.id_usuario ' +
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'ui.id, ui.id_usuario, u.nome, u.email, ' +
        'ui.login, ui.situacao, ui.principal, ui.ultimo_acesso_em, ' +
        'ui.criado_em, ui.atualizado_em ' +
        'FROM usuario_instituicao ui ' +
        'JOIN usuario u ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY ui.principal DESC, u.nome, ui.id ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.ParamByName('limite').AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName('offset').AsInteger :=
        Offset;

      Qry.Open;

      while not Qry.Eof do
      begin
        Usuario :=
          MapearUsuario(Qry);

        CarregarPerfis(
          AConn,
          AIdInstituicao,
          Usuario.Id,
          Usuario
        );

        Result.Itens.Add(Usuario);

        Qry.Next;
      end;

    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoUsuarioItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'ui.id, ui.id_usuario, u.nome, u.email, ' +
      'ui.login, ui.situacao, ui.principal, ui.ultimo_acesso_em, ' +
      'ui.criado_em, ui.atualizado_em ' +
      'FROM usuario_instituicao ui ' +
      'JOIN usuario u ON u.id = ui.id_usuario ' +
      'WHERE ui.id_instituicao = :id_instituicao ' +
      '  AND ui.id = :id_usuario_instituicao ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Open;

    if not Qry.IsEmpty then
    begin
      Result :=
        MapearUsuario(Qry);

      CarregarPerfis(
        AConn,
        AIdInstituicao,
        AIdUsuarioInstituicao,
        Result
      );
    end;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.BuscarUsuarioGlobalPorEmail(
  const AConn: TUniConnection;
  const AEmail: string;
  out ADados: TInstituicaoUsuarioGlobalDados
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  ADados := Default(TInstituicaoUsuarioGlobalDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id, nome, email, situacao ' +
      'FROM usuario ' +
      'WHERE email_normalizado = :email ' +
      'LIMIT 1';

    Qry.ParamByName('email').AsString :=
      LowerCase(Trim(AEmail));

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    ADados.Id :=
      Qry.FieldByName('id').AsLargeInt;

    ADados.Nome :=
      Qry.FieldByName('nome').AsString;

    ADados.Email :=
      Qry.FieldByName('email').AsString;

    ADados.Situacao :=
      Qry.FieldByName('situacao').AsString;

    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.UsuarioJaVinculado(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario: Int64
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
      'FROM usuario_instituicao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_usuario = :id_usuario ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.ExisteLogin(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ALogin: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ALogin).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario_instituicao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND login = :login ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('login').AsString :=
      Trim(ALogin);

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.InserirUsuarioGlobal(
  const AConn: TUniConnection;
  const ANome,
        AEmail,
        ASenhaHash: string
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO usuario ' +
      '(nome, email, email_normalizado, senha_hash, is_super_admin, situacao) ' +
      'VALUES ' +
      '(:nome, :email, :email_normalizado, :senha_hash, 0, ''ATIVO'')';

    Qry.ParamByName('nome').AsString :=
      Trim(ANome);

    Qry.ParamByName('email').AsString :=
      LowerCase(Trim(AEmail));

    Qry.ParamByName('email_normalizado').AsString :=
      LowerCase(Trim(AEmail));

    Qry.ParamByName('senha_hash').AsString :=
      ASenhaHash;

    Qry.Execute;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.InserirVinculo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuario: Int64;
  const ALogin: string
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO usuario_instituicao ' +
      '(id_instituicao, id_usuario, login, situacao, principal) ' +
      'VALUES ' +
      '(:id_instituicao, :id_usuario, :login, ''ATIVO'', 0)';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuario;

    if Trim(ALogin).IsEmpty then
      Qry.ParamByName('login').Clear
    else
      Qry.ParamByName('login').AsString :=
        Trim(ALogin);

    Qry.Execute;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoUsuarioDAO.AtualizarLogin(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ALogin: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE usuario_instituicao SET ' +
      'login = :login ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id = :id_usuario_instituicao ' +
      '  AND principal = 0';

    if Trim(ALogin).IsEmpty then
      Qry.ParamByName('login').Clear
    else
      Qry.ParamByName('login').AsString :=
        Trim(ALogin);

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoUsuarioDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE usuario_instituicao SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id = :id_usuario_instituicao ' +
      '  AND principal = 0';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoUsuarioDAO.PerfilAtivoPertenceInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdPerfil: Int64
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
      'FROM perfil ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id = :id_perfil ' +
      '  AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      AIdPerfil;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoUsuarioDAO.SubstituirPerfis(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const APerfis: TArray<Int64>
);
var
  Qry: TUniQuery;
  IdPerfil: Int64;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM usuario_instituicao_perfil ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND id_usuario_instituicao = :id_usuario_instituicao';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.Execute;

    for IdPerfil in APerfis do
    begin
      Qry.SQL.Text :=
        'INSERT INTO usuario_instituicao_perfil ' +
        '(id_instituicao, id_usuario_instituicao, id_perfil) ' +
        'VALUES ' +
        '(:id_instituicao, :id_usuario_instituicao, :id_perfil)';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
        AIdUsuarioInstituicao;

      Qry.ParamByName('id_perfil').AsLargeInt :=
        IdPerfil;

      Qry.Execute;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoUsuarioDAO.RegistrarAuditoria(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao,
        AIdUsuarioInstituicaoAlterado: Int64;
  const AAcao,
        AMetodo,
        ARota,
        AMensagem,
        AIP,
        AUserAgent: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO auditoria_log ' +
      '(id_instituicao, id_usuario, id_usuario_instituicao, ' +
      'acao, entidade, registro_id, metodo_http, rota, ' +
      'ip, user_agent, sucesso, mensagem) ' +
      'VALUES ' +
      '(:id_instituicao, :id_usuario, :id_usuario_instituicao, ' +
      ':acao, ''usuario_instituicao'', :registro_id, :metodo, :rota, ' +
      ':ip, :user_agent, 1, :mensagem)';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario').AsLargeInt :=
      AIdUsuarioAcao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicaoAcao;

    Qry.ParamByName('acao').AsString :=
      Copy(UpperCase(Trim(AAcao)), 1, 80);

    Qry.ParamByName('registro_id').AsString :=
      AIdUsuarioInstituicaoAlterado.ToString;

    Qry.ParamByName('metodo').AsString :=
      Copy(UpperCase(Trim(AMetodo)), 1, 10);

    Qry.ParamByName('rota').AsString :=
      Copy(Trim(ARota), 1, 500);

    Qry.ParamByName('ip').AsString :=
      Copy(Trim(AIP), 1, 45);

    Qry.ParamByName('user_agent').AsString :=
      Copy(Trim(AUserAgent), 1, 1000);

    Qry.ParamByName('mensagem').AsString :=
      Copy(Trim(AMensagem), 1, 1000);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
