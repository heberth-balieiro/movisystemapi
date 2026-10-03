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
      GarantirPermissao(Conn, 'turma.importar_participantes', 'TURMA', 'Importar participantes por CSV em turmas de certifica' + #$00E7 + #$00E3 + 'o.');

      GarantirPermissao(Conn, 'participante.visualizar', 'PARTICIPANTE', 'Visualizar participantes.');
      GarantirPermissao(Conn, 'participante.cadastrar', 'PARTICIPANTE', 'Cadastrar participantes.');
      GarantirPermissao(Conn, 'participante.editar', 'PARTICIPANTE', 'Editar participantes.');
      GarantirPermissao(Conn, 'participante.inativar', 'PARTICIPANTE', 'Inativar participantes.');

      GarantirPermissao(Conn, 'inscricao.visualizar', 'INSCRICAO', 'Visualizar inscri' + #$00E7 + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'inscricao.cadastrar', 'INSCRICAO', 'Cadastrar inscri' + #$00E7 + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'inscricao.editar', 'INSCRICAO', 'Editar inscri' + #$00E7 + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'inscricao.aprovar', 'INSCRICAO', 'Aprovar ou rejeitar inscri' + #$00E7 + #$00F5 + 'es.');

      GarantirPermissao(Conn, 'presenca.visualizar', 'PRESENCA', 'Visualizar presen' + #$00E7 + 'as.');
      GarantirPermissao(Conn, 'presenca.editar', 'PRESENCA', 'Registrar e editar presen' + #$00E7 + 'as.');

      GarantirPermissao(Conn, 'certificado.visualizar', 'CERTIFICADO', 'Visualizar certificados.');
      GarantirPermissao(Conn, 'certificado.emitir', 'CERTIFICADO', 'Emitir e reemitir certificados.');
      GarantirPermissao(Conn, 'certificado.cancelar', 'CERTIFICADO', 'Cancelar certificados.');
      GarantirPermissao(Conn, 'certificado.reprocessar', 'CERTIFICADO', 'Reprocessar certificados com erro.');
      GarantirPermissao(Conn, 'certificado.configurar', 'CERTIFICADO', 'Configurar modelos e regras de certificados.');

      GarantirPermissao(Conn, 'usuario.visualizar', 'USUARIO', 'Visualizar usu' + #$00E1 + 'rios da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'usuario.cadastrar', 'USUARIO', 'Cadastrar usu' + #$00E1 + 'rios da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'usuario.editar', 'USUARIO', 'Editar usu' + #$00E1 + 'rios da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'usuario.inativar', 'USUARIO', 'Inativar usu' + #$00E1 + 'rios da institui' + #$00E7 + #$00E3 + 'o.');

      GarantirPermissao(Conn, 'perfil.visualizar', 'PERFIL', 'Visualizar perfis e permiss' + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'perfil.cadastrar', 'PERFIL', 'Cadastrar perfis.');
      GarantirPermissao(Conn, 'perfil.editar', 'PERFIL', 'Editar perfis e suas permiss' + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'perfil.inativar', 'PERFIL', 'Inativar perfis.');

      GarantirPermissao(Conn, 'relatorio.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rios.');
      GarantirPermissao(Conn, 'relatorio.certificados.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rio de certificados.');
      GarantirPermissao(Conn, 'relatorio.certificados.exportar', 'RELATORIO', 'Exportar relat' + #$00F3 + 'rio de certificados.');
      GarantirPermissao(Conn, 'relatorio.turmas.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rio de turmas.');
      GarantirPermissao(Conn, 'relatorio.turmas.exportar', 'RELATORIO', 'Exportar relat' + #$00F3 + 'rio de turmas.');
      GarantirPermissao(Conn, 'relatorio.participantes.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rio de participantes.');
      GarantirPermissao(Conn, 'relatorio.participantes.exportar', 'RELATORIO', 'Exportar relat' + #$00F3 + 'rio de participantes.');
      GarantirPermissao(Conn, 'relatorio.inscricoes.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rio de inscri' + #$00E7 + #$00F5 + 'es e conclus' + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'relatorio.inscricoes.exportar', 'RELATORIO', 'Exportar relat' + #$00F3 + 'rio de inscri' + #$00E7 + #$00F5 + 'es e conclus' + #$00F5 + 'es.');
      GarantirPermissao(Conn, 'relatorio.presencas.visualizar', 'RELATORIO', 'Visualizar relat' + #$00F3 + 'rio de presen' + #$00E7 + 'as.');
      GarantirPermissao(Conn, 'relatorio.presencas.exportar', 'RELATORIO', 'Exportar relat' + #$00F3 + 'rio de presen' + #$00E7 + 'as.');
      GarantirPermissao(Conn, 'auditoria.visualizar', 'AUDITORIA', 'Visualizar auditoria da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'lgpd.visualizar', 'LGPD', 'Visualizar solicita' + #$00E7 + #$00F5 + 'es LGPD da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'lgpd.gerenciar', 'LGPD', 'Analisar e responder solicita' + #$00E7 + #$00F5 + 'es LGPD.');

      GarantirPermissao(Conn, 'configuracao.visualizar', 'CONFIGURACAO', 'Visualizar configura' + #$00E7 + #$00F5 + 'es da institui' + #$00E7 + #$00E3 + 'o.');
      GarantirPermissao(Conn, 'configuracao.editar', 'CONFIGURACAO', 'Editar configura' + #$00E7 + #$00F5 + 'es da institui' + #$00E7 + #$00E3 + 'o.');

      GarantirPermissao(Conn, 'whatsapp.visualizar', 'WHATSAPP', 'Visualizar conex' + #$00E3 + 'o WhatsApp.');
      GarantirPermissao(Conn, 'whatsapp.gerenciar', 'WHATSAPP', 'Criar inst' + #$00E2 + 'ncia e conectar WhatsApp.');

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
