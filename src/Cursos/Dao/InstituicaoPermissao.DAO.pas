unit InstituicaoPermissao.DAO;

interface

uses
  Uni,
  System.SysUtils;

type
  TInstituicaoPermissaoDAO = class
  public
    class function UsuarioTemPermissao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const APermissao: string
    ): Boolean; static;

    class function ListarPermissoesUsuario(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TArray<string>; static;

    class procedure GarantirPerfilAdministrador(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ); static;

    class procedure GarantirPerfisAdministradores(
      const AConn: TUniConnection
    ); static;
  end;

implementation

uses
  System.Generics.Collections;

class function TInstituicaoPermissaoDAO.UsuarioTemPermissao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const APermissao: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) or
     Trim(APermissao).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM usuario_instituicao ui ' +
      'JOIN usuario_instituicao_perfil uip ' +
      '  ON uip.id_instituicao = ui.id_instituicao ' +
      ' AND uip.id_usuario_instituicao = ui.id ' +
      'JOIN perfil p ' +
      '  ON p.id_instituicao = uip.id_instituicao ' +
      ' AND p.id = uip.id_perfil ' +
      ' AND p.situacao = ''ATIVO'' ' +
      'JOIN perfil_permissao pp ' +
      '  ON pp.id_instituicao = p.id_instituicao ' +
      ' AND pp.id_perfil = p.id ' +
      'JOIN permissao pe ' +
      '  ON pe.id = pp.id_permissao ' +
      ' AND pe.situacao = ''ATIVA'' ' +
      'WHERE ui.id_instituicao = :id_instituicao ' +
      '  AND ui.id = :id_usuario_instituicao ' +
      '  AND ui.situacao = ''ATIVO'' ' +
      '  AND pe.codigo = :permissao ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
      AIdUsuarioInstituicao;

    Qry.ParamByName('permissao').AsString :=
      LowerCase(Trim(APermissao));

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPermissaoDAO.ListarPermissoesUsuario(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TArray<string>;
var
  Qry: TUniQuery;
  Lista: TList<string>;
begin
  SetLength(Result, 0);

  if (AIdInstituicao <= 0) or
     (AIdUsuarioInstituicao <= 0) then
    Exit;

  Lista := TList<string>.Create;
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT DISTINCT pe.codigo ' +
        'FROM usuario_instituicao ui ' +
        'JOIN usuario_instituicao_perfil uip ' +
        '  ON uip.id_instituicao = ui.id_instituicao ' +
        ' AND uip.id_usuario_instituicao = ui.id ' +
        'JOIN perfil p ' +
        '  ON p.id_instituicao = uip.id_instituicao ' +
        ' AND p.id = uip.id_perfil ' +
        ' AND p.situacao = ''ATIVO'' ' +
        'JOIN perfil_permissao pp ' +
        '  ON pp.id_instituicao = p.id_instituicao ' +
        ' AND pp.id_perfil = p.id ' +
        'JOIN permissao pe ' +
        '  ON pe.id = pp.id_permissao ' +
        ' AND pe.situacao = ''ATIVA'' ' +
        'WHERE ui.id_instituicao = :id_instituicao ' +
        '  AND ui.id = :id_usuario_instituicao ' +
        '  AND ui.situacao = ''ATIVO'' ' +
        'ORDER BY pe.codigo';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_usuario_instituicao').AsLargeInt :=
        AIdUsuarioInstituicao;

      Qry.Open;

      while not Qry.Eof do
      begin
        Lista.Add(
          Qry.FieldByName('codigo').AsString
        );

        Qry.Next;
      end;
    finally
      Qry.Free;
    end;

    Result := Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

class procedure TInstituicaoPermissaoDAO.GarantirPerfilAdministrador(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
);
var
  Qry: TUniQuery;
  IdPerfil: Int64;
begin
  if AIdInstituicao <= 0 then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO perfil ' +
      '(id_instituicao, nome, descricao, sistema, situacao) ' +
      'VALUES ' +
      '(:id_instituicao, ''Administrador'', ' +
      '''Perfil administrador padrão da instituição.'', 1, ''ATIVO'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'descricao = VALUES(descricao), ' +
      'sistema = 1, ' +
      'situacao = ''ATIVO''';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.Execute;

    Qry.SQL.Text :=
      'SELECT id ' +
      'FROM perfil ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND nome = ''Administrador'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.Open;

    if Qry.IsEmpty then
      raise Exception.Create(
        'Não foi possível localizar o perfil Administrador.'
      );

    IdPerfil :=
      Qry.FieldByName('id').AsLargeInt;

    Qry.Close;

    // O perfil de sistema Administrador recebe todas as permissões ativas.
    Qry.SQL.Text :=
      'INSERT IGNORE INTO perfil_permissao ' +
      '(id_instituicao, id_perfil, id_permissao) ' +
      'SELECT :id_instituicao, :id_perfil, pe.id ' +
      'FROM permissao pe ' +
      'WHERE pe.situacao = ''ATIVA''';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_perfil').AsLargeInt :=
      IdPerfil;

    Qry.Execute;

    // O usuário principal do tenant sempre pertence ao perfil Administrador.
    Qry.SQL.Text :=
      'INSERT IGNORE INTO usuario_instituicao_perfil ' +
      '(id_instituicao, id_usuario_instituicao, id_perfil) ' +
      'SELECT ui.id_instituicao, ui.id, :id_perfil ' +
      'FROM usuario_instituicao ui ' +
      'WHERE ui.id_instituicao = :id_instituicao ' +
      '  AND ui.principal = 1 ' +
      '  AND ui.situacao = ''ATIVO''';

    Qry.ParamByName('id_perfil').AsLargeInt :=
      IdPerfil;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPermissaoDAO.GarantirPerfisAdministradores(
  const AConn: TUniConnection
);
var
  Qry: TUniQuery;
  Instituicoes: TList<Int64>;
  IdInstituicao: Int64;
begin
  Instituicoes := TList<Int64>.Create;
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT id ' +
        'FROM instituicao ' +
        'ORDER BY id';

      Qry.Open;

      while not Qry.Eof do
      begin
        Instituicoes.Add(
          Qry.FieldByName('id').AsLargeInt
        );

        Qry.Next;
      end;
    finally
      Qry.Free;
    end;

    for IdInstituicao in Instituicoes do
      GarantirPerfilAdministrador(
        AConn,
        IdInstituicao
      );
  finally
    Instituicoes.Free;
  end;
end;

end.
