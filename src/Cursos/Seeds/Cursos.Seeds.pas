unit Cursos.Seeds;

interface

uses
  Uni;

type
  TCursosSeeds = class
  private
    class procedure GarantirPermissao(
      const AConn: TUniConnection;
      const ACodigo,
            AModulo,
            ADescricao: string
    ); static;
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  App.Config,
  Database.Connection,
  InstituicaoPermissao.DAO;

class procedure TCursosSeeds.GarantirPermissao(
  const AConn: TUniConnection;
  const ACodigo,
        AModulo,
        ADescricao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO permissao ' +
      '(codigo, modulo, descricao, situacao) ' +
      'VALUES (:codigo, :modulo, :descricao, ''ATIVA'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'modulo = VALUES(modulo), ' +
      'descricao = VALUES(descricao), ' +
      'situacao = ''ATIVA''';

    Qry.ParamByName('codigo').AsString :=
      LowerCase(Trim(ACodigo));

    Qry.ParamByName('modulo').AsString :=
      UpperCase(Trim(AModulo));

    Qry.ParamByName('descricao').AsString :=
      Trim(ADescricao);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TCursosSeeds.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Conn.StartTransaction;
    try
      GarantirPermissao(Conn, 'dashboard.visualizar', 'DASHBOARD', 'Visualizar dashboard.');

      GarantirPermissao(Conn, 'curso.visualizar', 'CURSO', 'Visualizar cursos, categorias e instrutores.');
      GarantirPermissao(Conn, 'curso.cadastrar', 'CURSO', 'Cadastrar cursos, categorias e instrutores.');
      GarantirPermissao(Conn, 'curso.editar', 'CURSO', 'Editar cursos, categorias e instrutores.');
      GarantirPermissao(Conn, 'curso.inativar', 'CURSO', 'Inativar cursos, categorias e instrutores.');

      GarantirPermissao(Conn, 'turma.visualizar', 'TURMA', 'Visualizar turmas.');
      GarantirPermissao(Conn, 'turma.cadastrar', 'TURMA', 'Cadastrar turmas.');
      GarantirPermissao(Conn, 'turma.editar', 'TURMA', 'Editar turmas.');
      GarantirPermissao(Conn, 'turma.inativar', 'TURMA', 'Inativar turmas.');

      GarantirPermissao(Conn, 'participante.visualizar', 'PARTICIPANTE', 'Visualizar participantes.');
      GarantirPermissao(Conn, 'participante.cadastrar', 'PARTICIPANTE', 'Cadastrar participantes.');
      GarantirPermissao(Conn, 'participante.editar', 'PARTICIPANTE', 'Editar participantes.');
      GarantirPermissao(Conn, 'participante.inativar', 'PARTICIPANTE', 'Inativar participantes.');

      GarantirPermissao(Conn, 'inscricao.visualizar', 'INSCRICAO', 'Visualizar inscrições.');
      GarantirPermissao(Conn, 'inscricao.cadastrar', 'INSCRICAO', 'Cadastrar inscrições.');
      GarantirPermissao(Conn, 'inscricao.editar', 'INSCRICAO', 'Editar inscrições.');
      GarantirPermissao(Conn, 'inscricao.aprovar', 'INSCRICAO', 'Aprovar ou rejeitar inscrições.');

      GarantirPermissao(Conn, 'presenca.visualizar', 'PRESENCA', 'Visualizar presenças.');
      GarantirPermissao(Conn, 'presenca.editar', 'PRESENCA', 'Registrar e editar presenças.');

      GarantirPermissao(Conn, 'certificado.visualizar', 'CERTIFICADO', 'Visualizar certificados.');
      GarantirPermissao(Conn, 'certificado.emitir', 'CERTIFICADO', 'Emitir e reemitir certificados.');
      GarantirPermissao(Conn, 'certificado.cancelar', 'CERTIFICADO', 'Cancelar certificados.');
      GarantirPermissao(Conn, 'certificado.configurar', 'CERTIFICADO', 'Configurar modelos e regras de certificados.');

      GarantirPermissao(Conn, 'usuario.visualizar', 'USUARIO', 'Visualizar usuários da instituição.');
      GarantirPermissao(Conn, 'usuario.cadastrar', 'USUARIO', 'Cadastrar usuários da instituição.');
      GarantirPermissao(Conn, 'usuario.editar', 'USUARIO', 'Editar usuários da instituição.');
      GarantirPermissao(Conn, 'usuario.inativar', 'USUARIO', 'Inativar usuários da instituição.');

      GarantirPermissao(Conn, 'perfil.visualizar', 'PERFIL', 'Visualizar perfis e permissões.');
      GarantirPermissao(Conn, 'perfil.cadastrar', 'PERFIL', 'Cadastrar perfis.');
      GarantirPermissao(Conn, 'perfil.editar', 'PERFIL', 'Editar perfis e suas permissões.');
      GarantirPermissao(Conn, 'perfil.inativar', 'PERFIL', 'Inativar perfis.');

      GarantirPermissao(Conn, 'relatorio.visualizar', 'RELATORIO', 'Visualizar relatórios.');

      GarantirPermissao(Conn, 'configuracao.visualizar', 'CONFIGURACAO', 'Visualizar configurações da instituição.');
      GarantirPermissao(Conn, 'configuracao.editar', 'CONFIGURACAO', 'Editar configurações da instituição.');

      TInstituicaoPermissaoDAO.GarantirPerfisAdministradores(
        Conn
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
