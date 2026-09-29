{

07/09 3 horas.

}

unit Cursos.Migration;

interface

uses
  Uni,
  App.Config;

type
  TCursosMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;
    class procedure CreateMigrationTable(const AConn: TUniConnection); static;

    class procedure Migration_001_CreateInstituicao(const AConn: TUniConnection); static;
    class procedure Migration_002_CreateInstituicaoConfiguracao(const AConn: TUniConnection); static;
    class procedure Migration_003_CreateUnidadeOrganizacional(const AConn: TUniConnection); static;
    class procedure Migration_004_CreateUsuario(const AConn: TUniConnection); static;
    class procedure Migration_005_CreateUsuarioInstituicao(const AConn: TUniConnection); static;
    class procedure Migration_006_CreatePermissao(const AConn: TUniConnection); static;
    class procedure Migration_007_CreatePerfil(const AConn: TUniConnection); static;
    class procedure Migration_008_CreatePerfilPermissao(const AConn: TUniConnection); static;
    class procedure Migration_009_CreateUsuarioInstituicaoPerfil(const AConn: TUniConnection); static;
    class procedure Migration_010_CreateUsuarioRecuperacaoSenha(const AConn: TUniConnection); static;
    class procedure Migration_011_CreateUsuarioSessao(const AConn: TUniConnection); static;
    class procedure Migration_012_CreateParticipante(const AConn: TUniConnection); static;
    class procedure Migration_013_CreateInstrutor(const AConn: TUniConnection); static;
    class procedure Migration_014_CreateCertificadoModelo(const AConn: TUniConnection); static;
    class procedure Migration_015_CreateCursoCategoria(const AConn: TUniConnection); static;
    class procedure Migration_016_CreateCurso(const AConn: TUniConnection); static;
    class procedure Migration_017_CreateCursoInstrutor(const AConn: TUniConnection); static;
    class procedure Migration_018_CreateCursoModulo(const AConn: TUniConnection); static;
    class procedure Migration_019_CreateCursoAula(const AConn: TUniConnection); static;
    class procedure Migration_020_CreateCursoMaterial(const AConn: TUniConnection); static;
    class procedure Migration_021_CreateTurma(const AConn: TUniConnection); static;
    class procedure Migration_022_CreateTurmaInstrutor(const AConn: TUniConnection); static;
    class procedure Migration_023_CreateTurmaEncontro(const AConn: TUniConnection); static;
    class procedure Migration_024_CreateTurmaCriterioConclusao(const AConn: TUniConnection); static;
    class procedure Migration_025_CreateInscricao(const AConn: TUniConnection); static;
    class procedure Migration_026_CreateInscricaoHistorico(const AConn: TUniConnection); static;
    class procedure Migration_027_CreatePresenca(const AConn: TUniConnection); static;
    class procedure Migration_028_CreateInscricaoAulaProgresso(const AConn: TUniConnection); static;
    class procedure Migration_029_CreateInscricaoCriterioResultado(const AConn: TUniConnection); static;
    class procedure Migration_030_CreateCertificadoConfiguracao(const AConn: TUniConnection); static;
    class procedure Migration_031_CreateCertificadoSequencia(const AConn: TUniConnection); static;
    class procedure Migration_032_CreateCertificado(const AConn: TUniConnection); static;
    class procedure Migration_033_CreateCertificadoHistorico(const AConn: TUniConnection); static;
    class procedure Migration_034_CreateCertificadoValidacaoAcesso(const AConn: TUniConnection); static;
    class procedure Migration_035_CreateTermo(const AConn: TUniConnection); static;
    class procedure Migration_036_CreateTermoAceite(const AConn: TUniConnection); static;
    class procedure Migration_037_CreateLgpdSolicitacao(const AConn: TUniConnection); static;
    class procedure Migration_038_CreateAuditoriaLog(const AConn: TUniConnection); static;
    class procedure Migration_039_AtualizaInstituicaoAdministracao(const AConn: TUniConnection); static;
    class procedure Migration_040_ConfigInstituicaoMidiasWhatsApp(const AConn: TUniConnection); static;
    class procedure Migration_041_PlataformaWhatsAppConfiguracao(const AConn: TUniConnection); static;
    class procedure Migration_042_InstituicaoWhatsAppInstancia(const AConn: TUniConnection); static;
    class procedure Migration_043_PlataformaAjuda(const AConn: TUniConnection); static;
    class procedure Migration_044_InstituicaoEmailConfiguracao(const AConn: TUniConnection); static;
    class procedure Migration_045_PlataformaEmailConfiguracao(const AConn: TUniConnection); static;
    class procedure Migration_046_RecuperacaoSenhaTenantTipo(const AConn: TUniConnection); static;
    class procedure Migration_047_CanaisEnvioAcesso(const AConn: TUniConnection); static;

    class procedure Migration_048_EncontroCheckin(const AConn: TUniConnection); static;
    class procedure Migration_049_PlataformaCampanhas(const AConn: TUniConnection); static;

  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
end;

implementation

uses
  System.SysUtils,
  Database.Connection;

{ TCursosMigration }

{$REGION 'Padrao'}

class procedure TCursosMigration.CreateMigrationTable(
  const AConn: TUniConnection);
begin
  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS schema_migrations (' +
    ' id INT AUTO_INCREMENT PRIMARY KEY,' +
    ' version VARCHAR(50) NOT NULL UNIQUE,' +
    ' description VARCHAR(255) NOT NULL,' +
    ' executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );
end;

class procedure TCursosMigration.ExecSQL(const AConn: TUniConnection;
  const ASQL: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := ASQL;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TCursosMigration.MigrationExists(const AConn: TUniConnection;
  const AVersion: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM schema_migrations ' +
      'WHERE version = :version';

    Qry.ParamByName('version').AsString := AVersion;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TCursosMigration.RegisterMigration(const AConn: TUniConnection;
  const AVersion, ADescription: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO schema_migrations (version, description) ' +
      'VALUES (:version, :description)';

    Qry.ParamByName('version').AsString := AVersion;
    Qry.ParamByName('description').AsString := ADescription;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TCursosMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);

  try
    Conn.StartTransaction;
      try

      CreateMigrationTable(Conn);

      Migration_001_CreateInstituicao(Conn);
      Migration_002_CreateInstituicaoConfiguracao(Conn);
      Migration_003_CreateUnidadeOrganizacional(Conn);
      Migration_004_CreateUsuario(Conn);
      Migration_005_CreateUsuarioInstituicao(Conn);
      Migration_006_CreatePermissao(Conn);
      Migration_007_CreatePerfil(Conn);
      Migration_008_CreatePerfilPermissao(Conn);
      Migration_009_CreateUsuarioInstituicaoPerfil(Conn);
      Migration_010_CreateUsuarioRecuperacaoSenha(Conn);
      Migration_011_CreateUsuarioSessao(Conn);
      Migration_012_CreateParticipante(Conn);
      Migration_013_CreateInstrutor(Conn);
      Migration_014_CreateCertificadoModelo(Conn);
      Migration_015_CreateCursoCategoria(Conn);
      Migration_016_CreateCurso(Conn);
      Migration_017_CreateCursoInstrutor(Conn);
      Migration_018_CreateCursoModulo(Conn);
      Migration_019_CreateCursoAula(Conn);
      Migration_020_CreateCursoMaterial(Conn);
      Migration_021_CreateTurma(Conn);
      Migration_022_CreateTurmaInstrutor(Conn);
      Migration_023_CreateTurmaEncontro(Conn);
      Migration_024_CreateTurmaCriterioConclusao(Conn);
      Migration_025_CreateInscricao(Conn);
      Migration_026_CreateInscricaoHistorico(Conn);
      Migration_027_CreatePresenca(Conn);
      Migration_028_CreateInscricaoAulaProgresso(Conn);
      Migration_029_CreateInscricaoCriterioResultado(Conn);
      Migration_030_CreateCertificadoConfiguracao(Conn);
      Migration_031_CreateCertificadoSequencia(Conn);
      Migration_032_CreateCertificado(Conn);
      Migration_033_CreateCertificadoHistorico(Conn);
      Migration_034_CreateCertificadoValidacaoAcesso(Conn);
      Migration_035_CreateTermo(Conn);
      Migration_036_CreateTermoAceite(Conn);
      Migration_037_CreateLgpdSolicitacao(Conn);
      Migration_038_CreateAuditoriaLog(Conn);
      Migration_039_AtualizaInstituicaoAdministracao(Conn);
      Migration_040_ConfigInstituicaoMidiasWhatsApp(Conn);
      Migration_041_PlataformaWhatsAppConfiguracao(Conn);
      Migration_042_InstituicaoWhatsAppInstancia(Conn);
      Migration_043_PlataformaAjuda(Conn);
      Migration_044_InstituicaoEmailConfiguracao(Conn);
      Migration_045_PlataformaEmailConfiguracao(Conn);
      Migration_046_RecuperacaoSenhaTenantTipo(Conn);
      Migration_047_CanaisEnvioAcesso(Conn);
      Migration_048_EncontroCheckin(Conn);
      Migration_049_PlataformaCampanhas(Conn);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}


{$REGION 'Funcao Create'}

class procedure TCursosMigration.Migration_001_CreateInstituicao(const AConn: TUniConnection);
const
  VERSION = '001';
  DESCRIPTION = 'Criar tabela Instituicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS instituicao (                                                                                               '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                                                          '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT ''Código público gerado pela API, ex.: ULID.'',       '+
    'slug VARCHAR(120) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL COMMENT ''Identifica o ambiente público da instituição.'',   '+
    'razao_social VARCHAR(180) NOT NULL,                                                                                                  '+
    'nome_fantasia VARCHAR(180) NOT NULL,                                                                                                 '+
    'cnpj VARCHAR(14) NULL,                                                                                                               '+
    'email VARCHAR(254) NULL,                                                                                                             '+
    'telefone VARCHAR(30) NULL,                                                                                                           '+
    'site VARCHAR(500) NULL,                                                                                                              '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',                                                                                     '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                                                                         '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),                                      '+
    'inativado_em DATETIME(3) NULL,                                                                                                       '+
    'PRIMARY KEY (id),                                                                                                                    '+
    'UNIQUE KEY uq_instituicao_codigo_publico (codigo_publico),                                                                           '+
    'UNIQUE KEY uq_instituicao_slug (slug),                                                                                               '+
    'UNIQUE KEY uq_instituicao_cnpj (cnpj),                                                                                               '+
    'KEY ix_instituicao_situacao (situacao),                                                                                              '+
    'CONSTRAINT ck_instituicao_situacao CHECK (situacao IN (''ATIVA'',''INATIVA'',''BLOQUEADA''))                                         '+
    ') ENGINE=InnoDB COMMENT=''Tenant principal da plataforma.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_002_CreateInstituicaoConfiguracao(const AConn: TUniConnection);
const
  VERSION = '002';
  DESCRIPTION = 'Criar tabela InstituicaoConfiguracao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS instituicao_configuracao (          '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                   '+
    'nome_exibicao VARCHAR(180) NOT NULL,                                       '+
    'mensagem_boas_vindas TEXT NULL,                                            '+
    'logo_url VARCHAR(1000) NULL,                                               '+
    'favicon_url VARCHAR(1000) NULL,                                            '+
    'imagem_login_url VARCHAR(1000) NULL,                                       '+
    'cor_primaria CHAR(7) NOT NULL DEFAULT ''#2563EB'',                           '+
    'cor_secundaria CHAR(7) NOT NULL DEFAULT ''#1E40AF'',                         '+
    'cor_destaque CHAR(7) NOT NULL DEFAULT ''#F59E0B'',                           '+
    'cor_fundo CHAR(7) NOT NULL DEFAULT ''#F8FAFC'',                              '+
    'cor_texto CHAR(7) NOT NULL DEFAULT ''#0F172A'',                              '+
    'email_contato VARCHAR(254) NULL,                                           '+
    'telefone_contato VARCHAR(30) NULL,                                         '+
    'timezone VARCHAR(64) NOT NULL DEFAULT ''America/Sao_Paulo'',                 '+
    'permitir_inscricao_publica TINYINT(1) NOT NULL DEFAULT 0,                  '+
    'configuracao_publica JSON NULL COMMENT ''Configurações públicas futuras sem exigir nova coluna a cada evolução.'',   '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                                                       '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),                    '+
    'PRIMARY KEY (id_instituicao),                                                                                      '+
    'CONSTRAINT fk_instituicao_configuracao_instituicao                                                                 '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                                                        '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE                                                                           '+
    ') ENGINE=InnoDB COMMENT=''Tema e configurações públicas do tenant.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_003_CreateUnidadeOrganizacional(const AConn: TUniConnection);
const
  VERSION = '003';
  DESCRIPTION = 'Criar tabela UnidadeOrganizacional';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS unidade_organizacional (                                    '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                        '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                                           '+
    'id_unidade_pai BIGINT UNSIGNED NULL,                                                               '+
    'codigo VARCHAR(50) NULL,                                                                           '+
    'nome VARCHAR(180) NOT NULL,                                                                         '+
    'tipo VARCHAR(30) NOT NULL DEFAULT ''UNIDADE'',                                                       '+
    'descricao VARCHAR(500) NULL,                                                                       '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',                                                     '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                                       '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),    '+
    'PRIMARY KEY (id),                                                                                  '+
    'UNIQUE KEY uq_unidade_tenant_id (id_instituicao, id),                                              '+
    'UNIQUE KEY uq_unidade_codigo (id_instituicao, codigo),                                             '+
    'KEY ix_unidade_pai (id_instituicao, id_unidade_pai),                                               '+
    'KEY ix_unidade_nome (id_instituicao, nome),                                                        '+
    'CONSTRAINT fk_unidade_instituicao                                                                  '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                                        '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                         '+
    'CONSTRAINT fk_unidade_pai                                                                          '+
    '    FOREIGN KEY (id_instituicao, id_unidade_pai)                                                   '+
    '    REFERENCES unidade_organizacional(id_instituicao, id)                                          '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                         '+
    'CONSTRAINT ck_unidade_situacao CHECK (situacao IN (''ATIVA'',''INATIVA''))                             '+
    ') ENGINE=InnoDB COMMENT=''Secretarias, departamentos, unidades, setores ou equivalentes.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_004_CreateUsuario(const AConn: TUniConnection);
const
  VERSION = '004';
  DESCRIPTION = 'Criar tabela Usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario (                                                              '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                     '+
    'nome VARCHAR(180) NOT NULL,                                                                     '+
    'email VARCHAR(254) NOT NULL,                                                                    '+
    'email_normalizado VARCHAR(254) NOT NULL COMMENT ''E-mail em lowercase/trim para autenticação.'',  '+
    'senha_hash VARCHAR(255) NOT NULL COMMENT ''Hash Argon2id/bcrypt. Nunca armazenar senha pura.'',   '+
    'email_verificado_em DATETIME(3) NULL,                                                           '+
    'is_super_admin TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''Acesso da administração global do SaaS.'', '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                                  '+
    'ultimo_login_em DATETIME(3) NULL,                                                               '+
    'senha_alterada_em DATETIME(3) NULL,                                                             '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                                    '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                                               '+
    'UNIQUE KEY uq_usuario_email_normalizado (email_normalizado),                                    '+
    'KEY ix_usuario_situacao (situacao),                                                             '+
    'CONSTRAINT ck_usuario_situacao CHECK (situacao IN (''ATIVO'',''INATIVO'',''BLOQUEADO''))              '+
    ') ENGINE=InnoDB COMMENT=''Identidade global de autenticação.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_005_CreateUsuarioInstituicao(const AConn: TUniConnection);
const
  VERSION = '005';
  DESCRIPTION = 'Criar tabela UsuarioInstituicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario_instituicao (                                   '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                      '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                         '+
    'id_usuario BIGINT UNSIGNED NOT NULL,                                             '+
    'id_unidade_organizacional BIGINT UNSIGNED NULL,                                  '+
    'login VARCHAR(80) NULL COMMENT ''Login opcional específico dentro do tenant.'',    '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                   '+
    'principal TINYINT(1) NOT NULL DEFAULT 0,                                         '+
    'ultimo_acesso_em DATETIME(3) NULL,                                               '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                     '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),    '+
    'PRIMARY KEY (id),                                                                                  '+
    'UNIQUE KEY uq_usuario_instituicao_tenant_id (id_instituicao, id),                                  '+
    'UNIQUE KEY uq_usuario_instituicao_usuario (id_instituicao, id_usuario),                            '+
    'UNIQUE KEY uq_usuario_instituicao_login (id_instituicao, login),                                   '+
    'KEY ix_usuario_instituicao_usuario (id_usuario),                                                   '+
    'KEY ix_usuario_instituicao_situacao (id_instituicao, situacao),                                    '+
    'CONSTRAINT fk_usuario_instituicao_instituicao                                                      '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                                        '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                         '+
    'CONSTRAINT fk_usuario_instituicao_usuario                                                          '+
    '    FOREIGN KEY (id_usuario) REFERENCES usuario(id)                                                '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                         '+
    'CONSTRAINT fk_usuario_instituicao_unidade                                                          '+
    '    FOREIGN KEY (id_instituicao, id_unidade_organizacional)                                        '+
    '    REFERENCES unidade_organizacional(id_instituicao, id)                                          '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                         '+
    'CONSTRAINT ck_usuario_instituicao_situacao CHECK (situacao IN (''ATIVO'',''INATIVO'',''BLOQUEADO''))     '+
    ') ENGINE=InnoDB COMMENT=''Vínculo do usuário global com cada instituição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_006_CreatePermissao(const AConn: TUniConnection);
const
  VERSION = '006';
  DESCRIPTION = 'Criar tabela Permissao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS permissao (                                       '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                '+
    'codigo VARCHAR(100) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL, '+
    'modulo VARCHAR(50) NOT NULL,                                               '+
    'descricao VARCHAR(255) NOT NULL,                                           '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',                           '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),               '+
    'PRIMARY KEY (id),                                                          '+
    'UNIQUE KEY uq_permissao_codigo (codigo),                                   '+
    'KEY ix_permissao_modulo (modulo),                                          '+
    'CONSTRAINT ck_permissao_situacao CHECK (situacao IN (''ATIVA'',''INATIVA'')) '+
    ') ENGINE=InnoDB COMMENT=''Catálogo global de permissões da aplicação.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_007_CreatePerfil(const AConn: TUniConnection);
const
  VERSION = '007';
  DESCRIPTION = 'Criar tabela Perfil';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS perfil (                                         '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'nome VARCHAR(100) NOT NULL,                                               '+
    'descricao VARCHAR(255) NULL,                                              '+
    'sistema TINYINT(1) NOT NULL DEFAULT 0,                                    '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                            '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id),                                                       '+
    'UNIQUE KEY uq_perfil_tenant_id (id_instituicao, id),                    '+
    'UNIQUE KEY uq_perfil_nome (id_instituicao, nome),                       '+
    'CONSTRAINT fk_perfil_instituicao                                        '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)             '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                              '+
    'CONSTRAINT ck_perfil_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))   '+
    ') ENGINE=InnoDB COMMENT=''Perfis configuráveis por instituição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_008_CreatePerfilPermissao(const AConn: TUniConnection);
const
  VERSION = '008';
  DESCRIPTION = 'Criar tabela PerfilPermissao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS perfil_permissao (                         '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                            '+
    'id_perfil BIGINT UNSIGNED NOT NULL,                                 '+
    'id_permissao BIGINT UNSIGNED NOT NULL,                              '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),        '+
    'PRIMARY KEY (id_instituicao, id_perfil, id_permissao),              '+
    'KEY ix_perfil_permissao_permissao (id_permissao),                   '+
    'CONSTRAINT fk_perfil_permissao_perfil                               '+
    '    FOREIGN KEY (id_instituicao, id_perfil)                         '+
    '    REFERENCES perfil(id_instituicao, id)                           '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                           '+
    'CONSTRAINT fk_perfil_permissao_permissao                            '+
    '    FOREIGN KEY (id_permissao) REFERENCES permissao(id)             '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                           '+
    ') ENGINE=InnoDB COMMENT=''Permissões concedidas a cada perfil.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_009_CreateUsuarioInstituicaoPerfil(const AConn: TUniConnection);
const
  VERSION = '009';
  DESCRIPTION = 'Criar tabela UsuarioInstituicaoPerfil';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario_instituicao_perfil (                  '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                               '+
    'id_usuario_instituicao BIGINT UNSIGNED NOT NULL,                       '+
    'id_perfil BIGINT UNSIGNED NOT NULL,                                    '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),           '+
    'PRIMARY KEY (id_instituicao, id_usuario_instituicao, id_perfil),       '+
    'CONSTRAINT fk_usuario_perfil_usuario_instituicao                       '+
    '    FOREIGN KEY (id_instituicao, id_usuario_instituicao)               '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                 '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                              '+
    'CONSTRAINT fk_usuario_perfil_perfil                                    '+
    '    FOREIGN KEY (id_instituicao, id_perfil)                            '+
    '    REFERENCES perfil(id_instituicao, id)                              '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                              '+
    ') ENGINE=InnoDB COMMENT=''Perfis atribuídos ao usuário dentro do tenant.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_010_CreateUsuarioRecuperacaoSenha(const AConn: TUniConnection);
const
  VERSION = '010';
  DESCRIPTION = 'Criar tabela UsuarioRecuperacaoSenha';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario_recuperacao_senha (                 '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                          '+
    'id_usuario BIGINT UNSIGNED NOT NULL,                                 '+
    'token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL COMMENT ''SHA-256/HMAC do token enviado; nunca guardar token puro.'',  '+
    'expira_em DATETIME(3) NOT NULL,                                     '+
    'utilizado_em DATETIME(3) NULL,                                      '+
    'revogado_em DATETIME(3) NULL,                                       '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),        '+
    'PRIMARY KEY (id),                                                   '+
    'UNIQUE KEY uq_recuperacao_token_hash (token_hash),                  '+
    'KEY ix_recuperacao_usuario_data (id_usuario, criado_em),            '+
    'KEY ix_recuperacao_expiracao (expira_em),                           '+
    'CONSTRAINT fk_recuperacao_usuario                                   '+
    '    FOREIGN KEY (id_usuario) REFERENCES usuario(id)                 '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE                            '+
  ') ENGINE=InnoDB COMMENT=''Tokens de recuperação de senha armazenados somente em forma de hash.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_011_CreateUsuarioSessao(const AConn: TUniConnection);
const
  VERSION = '011';
  DESCRIPTION = 'Criar tabela UsuarioSessao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario_sessao (                                   '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                 '+
    'id_usuario BIGINT UNSIGNED NOT NULL,                                        '+
    'id_instituicao BIGINT UNSIGNED NULL,                                        '+
    'refresh_token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, '+
    'dispositivo VARCHAR(255) NULL,                                              '+
    'ip VARCHAR(45) NULL,                                                        '+
    'user_agent VARCHAR(1000) NULL,                                              '+
    'expira_em DATETIME(3) NOT NULL,                                             '+
    'revogado_em DATETIME(3) NULL,                                               '+
    'ultimo_uso_em DATETIME(3) NULL,                                             '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                '+
    'PRIMARY KEY (id),                                                           '+
    'UNIQUE KEY uq_usuario_sessao_refresh_hash (refresh_token_hash),             '+
    'KEY ix_usuario_sessao_usuario (id_usuario, criado_em),                      '+
    'KEY ix_usuario_sessao_expira (expira_em),                                   '+
    'CONSTRAINT fk_usuario_sessao_usuario                                        '+
    '    FOREIGN KEY (id_usuario) REFERENCES usuario(id)  '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,            '+
    'CONSTRAINT fk_usuario_sessao_instituicao             '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)  '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE                      '+
    ') ENGINE=InnoDB COMMENT=''Sessões/refresh tokens revogáveis. JWT de acesso pode continuar stateless.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_012_CreateParticipante(const AConn: TUniConnection);
const
  VERSION = '012';
  DESCRIPTION = 'Criar tabela Participante';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS participante (                   '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                             '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                '+
    'id_unidade_organizacional BIGINT UNSIGNED NULL,                         '+
    'id_usuario_instituicao BIGINT UNSIGNED NULL COMMENT ''Preenchido quando o participante possui acesso ao portal.'',  '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,                                          '+
    'nome VARCHAR(180) NOT NULL,                                                                                      '+
    'cpf_criptografado VARBINARY(512) NULL COMMENT ''CPF criptografado pela API, preferencialmente AES-GCM.'',          '+
    'cpf_hash_busca CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL COMMENT ''HMAC-SHA256 do CPF normalizado para busca/uniqueness.'', '+
    'cpf_mascarado VARCHAR(20) NULL COMMENT ''Versão mascarada própria para grids e logs.'', '+
    'email VARCHAR(254) NULL,                                                              '+
    'matricula VARCHAR(80) NULL,                                                           '+
    'telefone VARCHAR(30) NULL,                                                            '+
    'orgao_empresa VARCHAR(180) NULL,                                                      '+
    'cargo VARCHAR(120) NULL,                                                              '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                        '+
    'anonimizado_em DATETIME(3) NULL,                                                      '+
    'motivo_anonimizacao VARCHAR(500) NULL,                                                '+
    'criado_por BIGINT UNSIGNED NULL,                                                      '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                          '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),  '+
    'PRIMARY KEY (id),                                                      '+
    'UNIQUE KEY uq_participante_tenant_id (id_instituicao, id),             '+
    'UNIQUE KEY uq_participante_codigo_publico (codigo_publico),            '+
    'UNIQUE KEY uq_participante_cpf (id_instituicao, cpf_hash_busca),       '+
    'UNIQUE KEY uq_participante_matricula (id_instituicao, matricula),      '+
    'UNIQUE KEY uq_participante_usuario (id_instituicao, id_usuario_instituicao),  '+
    'KEY ix_participante_nome (id_instituicao, nome),                             '+
    'KEY ix_participante_email (id_instituicao, email),                           '+
    'KEY ix_participante_situacao (id_instituicao, situacao),                     '+
    'CONSTRAINT fk_participante_instituicao                                       '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                  '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_participante_unidade                                           '+
    '    FOREIGN KEY (id_instituicao, id_unidade_organizacional)                  '+
    '    REFERENCES unidade_organizacional(id_instituicao, id)                    '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_participante_usuario_instituicao                               '+
    '    FOREIGN KEY (id_instituicao, id_usuario_instituicao)                     '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                       '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_participante_criado_por                                        '+
   '     FOREIGN KEY (id_instituicao, criado_por)                                 '+
   '     REFERENCES usuario_instituicao(id_instituicao, id)                       '+
   '     ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
   ' CONSTRAINT ck_participante_situacao CHECK (situacao IN (''ATIVO'',''INATIVO'',''ANONIMIZADO'')) '+
  ') ENGINE=InnoDB COMMENT=''Participantes/alunos vinculados ao tenant.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_013_CreateInstrutor(const AConn: TUniConnection);
const
  VERSION = '013';
  DESCRIPTION = 'Criar tabela Instrutor';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS instrutor (                               '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                      '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                         '+
    'id_participante BIGINT UNSIGNED NULL COMMENT ''Permite reutilizar participante interno como instrutor.'', '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,          '+
    'nome VARCHAR(180) NOT NULL,                                                      '+
    'email VARCHAR(254) NULL,                                                         '+
    'telefone VARCHAR(30) NULL,                                                       '+
    'documento_criptografado VARBINARY(512) NULL,                                     '+
    'documento_hash_busca CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,        '+
    'biografia TEXT NULL,                                                             '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                   '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                     '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                               '+
    'UNIQUE KEY uq_instrutor_tenant_id (id_instituicao, id),                         '+
    'UNIQUE KEY uq_instrutor_codigo_publico (codigo_publico),                        '+
    'UNIQUE KEY uq_instrutor_participante (id_instituicao, id_participante),         '+
    'KEY ix_instrutor_nome (id_instituicao, nome),                                   '+
    'CONSTRAINT fk_instrutor_instituicao                                             '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                     '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                      '+
    'CONSTRAINT fk_instrutor_participante                                            '+
    '    FOREIGN KEY (id_instituicao, id_participante)                                '+
    '    REFERENCES participante(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                      '+
    'CONSTRAINT ck_instrutor_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))        '+
    ') ENGINE=InnoDB COMMENT=''Instrutores internos ou externos.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_014_CreateCertificadoModelo(const AConn: TUniConnection);
const
  VERSION = '014';
  DESCRIPTION = 'Criar tabela CertificadoModelo';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS certificado_modelo (                                           '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                           '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                                              '+
    'nome VARCHAR(120) NOT NULL,                                                                           '+
    'descricao VARCHAR(500) NULL,                                                                          '+
    'template_html LONGTEXT NULL COMMENT ''Opcional: template HTML quando o gerador de PDF utilizar HTML.'', '+
    'template_configuracao JSON NULL COMMENT ''Posições, fontes, logos, assinaturas e demais parâmetros.'',  '+
    'imagem_fundo_url VARCHAR(1000) NULL,                                                                  '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                                        '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                                          '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),       '+
    'PRIMARY KEY (id),                                                                                     '+
    'UNIQUE KEY uq_certificado_modelo_tenant_id (id_instituicao, id),                                      '+
    'UNIQUE KEY uq_certificado_modelo_nome (id_instituicao, nome),                                         '+
    'CONSTRAINT fk_certificado_modelo_instituicao                                                          '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                                          '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                           '+
    'CONSTRAINT ck_certificado_modelo_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))                    '+
    ') ENGINE=InnoDB COMMENT=''Modelos de certificado configuráveis por instituição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_015_CreateCursoCategoria(const AConn: TUniConnection);
const
  VERSION = '015';
  DESCRIPTION = 'Criar tabela CursoCategoria';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso_categoria (                '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                             '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                '+
    'nome VARCHAR(120) NOT NULL,                                             '+
    'descricao VARCHAR(500) NULL,                                            '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',                        '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),            '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),  '+
    'PRIMARY KEY (id),                                                                                '+
    'UNIQUE KEY uq_curso_categoria_tenant_id (id_instituicao, id),                                    '+
    'UNIQUE KEY uq_curso_categoria_nome (id_instituicao, nome),                                       '+
    'CONSTRAINT fk_curso_categoria_instituicao                                                        '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                                      '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                                       '+
    'CONSTRAINT ck_curso_categoria_situacao CHECK (situacao IN (''ATIVA'',''INATIVA''))               '+
    ') ENGINE=InnoDB COMMENT=''Categorias configuráveis de cursos.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_016_CreateCurso(const AConn: TUniConnection);
const
  VERSION = '016';
  DESCRIPTION = 'Criar tabela Curso';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso (                            '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'id_categoria BIGINT UNSIGNED NULL,                                        '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,   '+
    'codigo_interno VARCHAR(50) NULL,                                          '+
    'slug VARCHAR(160) CHARACTER SET ascii COLLATE ascii_general_ci NULL,      '+
    'nome VARCHAR(200) NOT NULL,                                               '+
    'descricao TEXT NULL,                                                      '+
    'objetivo TEXT NULL,                                                       '+
    'conteudo_programatico LONGTEXT NULL,                                       '+
    'carga_horaria_minutos INT UNSIGNED NOT NULL COMMENT ''Armazenar em minutos evita inconsistência com casas decimais.'',  '+
    'modalidade VARCHAR(20) NOT NULL,                                         '+
    'imagem_url VARCHAR(1000) NULL,                                           '+
    'permitir_inscricao_publica TINYINT(1) NOT NULL DEFAULT 0,                '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''RASCUNHO'',                      '+
    'criado_por BIGINT UNSIGNED NULL,                                         '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),             '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'inativado_em DATETIME(3) NULL,                                          '+
    'PRIMARY KEY (id),                                                       '+
    'UNIQUE KEY uq_curso_tenant_id (id_instituicao, id),                     '+
    'UNIQUE KEY uq_curso_codigo_publico (codigo_publico),                    '+
    'UNIQUE KEY uq_curso_codigo_interno (id_instituicao, codigo_interno),    '+
    'UNIQUE KEY uq_curso_slug (id_instituicao, slug),                        '+
    'KEY ix_curso_nome (id_instituicao, nome),                               '+
    'KEY ix_curso_situacao (id_instituicao, situacao),                       '+
    'KEY ix_curso_categoria (id_instituicao, id_categoria),                  '+
    'CONSTRAINT fk_curso_instituicao                                         '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)             '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                             '+
    'CONSTRAINT fk_curso_categoria                                          '+
    '    FOREIGN KEY (id_instituicao, id_categoria)                         '+
    '    REFERENCES curso_categoria(id_instituicao, id)                     '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                             '+
    'CONSTRAINT fk_curso_criado_por                                         '+
    '    FOREIGN KEY (id_instituicao, criado_por)                           '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                 '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                             '+
   ' CONSTRAINT ck_curso_modalidade CHECK (modalidade IN (''PRESENCIAL'',''ONLINE'',''HIBRIDO'')), '+
   ' CONSTRAINT ck_curso_situacao CHECK (situacao IN (''RASCUNHO'',''ATIVO'',''INATIVO''))    '+
  ') ENGINE=InnoDB COMMENT=''Cadastro mestre de cursos/capacitações.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_017_CreateCursoInstrutor(const AConn: TUniConnection);
const
  VERSION = '017';
  DESCRIPTION = 'Criar tabela CursoInstrutor';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso_instrutor (             '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                             '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                   '+
    'id_instrutor BIGINT UNSIGNED NOT NULL,                               '+
    'principal TINYINT(1) NOT NULL DEFAULT 0,                             '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),         '+
    'PRIMARY KEY (id_instituicao, id_curso, id_instrutor),                '+
    'CONSTRAINT fk_curso_instrutor_curso                                  '+
    '    FOREIGN KEY (id_instituicao, id_curso)                           '+
    '    REFERENCES curso(id_instituicao, id)                             '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                            '+
    'CONSTRAINT fk_curso_instrutor_instrutor                              '+
    '    FOREIGN KEY (id_instituicao, id_instrutor)                       '+
    '    REFERENCES instrutor(id_instituicao, id)                         '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                            '+
    ') ENGINE=InnoDB COMMENT=''Instrutores padrão associados ao curso.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_018_CreateCursoModulo(const AConn: TUniConnection);
const
  VERSION = '018';
  DESCRIPTION = 'Criar tabela CursoModulo';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso_modulo (                     '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                        '+
    'nome VARCHAR(180) NOT NULL,                                               '+
    'descricao TEXT NULL,                                                      '+
    'ordem SMALLINT UNSIGNED NOT NULL DEFAULT 1,                               '+
    'obrigatorio TINYINT(1) NOT NULL DEFAULT 1,                                '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                          '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                         '+
    'UNIQUE KEY uq_curso_modulo_tenant_curso_id (id_instituicao, id_curso, id),'+
    'KEY ix_curso_modulo_ordem (id_instituicao, id_curso, ordem),              '+
    'CONSTRAINT fk_curso_modulo_curso                                          '+
    '    FOREIGN KEY (id_instituicao, id_curso)                                '+
    '    REFERENCES curso(id_instituicao, id)                                  '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                 '+
    'CONSTRAINT ck_curso_modulo_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))   '+
    ') ENGINE=InnoDB COMMENT=''Módulos opcionais para cursos online/híbridos.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_019_CreateCursoAula(const AConn: TUniConnection);
const
  VERSION = '019';
  DESCRIPTION = 'Criar tabela CursoAula';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso_aula (                      '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                              '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                 '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                       '+
    'id_modulo BIGINT UNSIGNED NOT NULL,                                      '+
    'titulo VARCHAR(200) NOT NULL,                                            '+
    'descricao TEXT NULL,                                                     '+
    'tipo VARCHAR(30) NOT NULL DEFAULT ''CONTEUDO'',                          '+
    'url_conteudo VARCHAR(1000) NULL,                                         '+
    'conteudo_html LONGTEXT NULL,                                             '+
    'duracao_minutos INT UNSIGNED NULL,                                       '+
    'ordem SMALLINT UNSIGNED NOT NULL DEFAULT 1,                              '+
    'obrigatoria TINYINT(1) NOT NULL DEFAULT 1,                               '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',                         '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),             '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id),                                                        '+
    'UNIQUE KEY uq_curso_aula_tenant_curso_id (id_instituicao, id_curso, id), '+
    'KEY ix_curso_aula_modulo_ordem (id_instituicao, id_modulo, ordem),       '+
    'CONSTRAINT fk_curso_aula_curso                                           '+
    '    FOREIGN KEY (id_instituicao, id_curso)                               '+
    '    REFERENCES curso(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT fk_curso_aula_modulo                                          '+
    '    FOREIGN KEY (id_instituicao, id_curso, id_modulo)                    '+
    '    REFERENCES curso_modulo(id_instituicao, id_curso, id)                '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT ck_curso_aula_tipo CHECK (tipo IN (''CONTEUDO'',''VIDEO'',''LINK'',''ARQUIVO'')), '+
    ' CONSTRAINT ck_curso_aula_situacao CHECK (situacao IN (''ATIVA'',''INATIVA'')) '+
    ') ENGINE=InnoDB COMMENT=''Aulas/conteúdos de módulos.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_020_CreateCursoMaterial(const AConn: TUniConnection);
const
  VERSION = '020';
  DESCRIPTION = 'Criar tabela CursoMaterial';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS curso_material (                   '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                        '+
    'id_aula BIGINT UNSIGNED NULL,                                             '+
    'nome VARCHAR(200) NOT NULL,                                               '+
    'tipo VARCHAR(30) NOT NULL DEFAULT ''ARQUIVO'',                            '+
    'url VARCHAR(1000) NOT NULL,                                               '+
    'descricao VARCHAR(500) NULL,                                              '+
    'ordem SMALLINT UNSIGNED NOT NULL DEFAULT 1,                               '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                          '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                        '+
    'UNIQUE KEY uq_curso_material_tenant_id (id_instituicao, id),             '+
    'KEY ix_curso_material_curso (id_instituicao, id_curso),                  '+
    'KEY ix_curso_material_aula (id_instituicao, id_aula),                    '+
    'CONSTRAINT fk_curso_material_curso                                       '+
    '    FOREIGN KEY (id_instituicao, id_curso)                               '+
    '    REFERENCES curso(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT fk_curso_material_aula                                        '+
    '    FOREIGN KEY (id_instituicao, id_curso, id_aula)                      '+
    '    REFERENCES curso_aula(id_instituicao, id_curso, id)                  '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT ck_curso_material_tipo CHECK (tipo IN (''ARQUIVO'',''LINK'',''VIDEO'',''OUTRO'')),'+
    'CONSTRAINT ck_curso_material_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))  '+
    ') ENGINE=InnoDB COMMENT=''Materiais complementares do curso/aula.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_021_CreateTurma(const AConn: TUniConnection);
const
  VERSION = '021';
  DESCRIPTION = 'Criar tabela Turma';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS turma (                            '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                        '+
    'id_modelo_certificado BIGINT UNSIGNED NULL,                               '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,   '+
    'codigo_interno VARCHAR(50) NULL,                                          '+
    'nome VARCHAR(180) NOT NULL,                                               '+
    'modalidade VARCHAR(20) NOT NULL,                                          '+
    'data_hora_inicio DATETIME(3) NOT NULL,                                    '+
    'data_hora_fim DATETIME(3) NOT NULL,                                       '+
    'inscricao_inicio DATETIME(3) NULL,                                        '+
    'inscricao_fim DATETIME(3) NULL,                                           '+
    'limite_participantes INT UNSIGNED NULL,                                   '+
    'local VARCHAR(255) NULL,                                                  '+
    'url_online VARCHAR(1000) NULL,                                            '+
    'carga_horaria_minutos INT UNSIGNED NULL COMMENT ''Quando nulo, utilizar a carga horária do curso.'', '+
    'permitir_inscricao_publica TINYINT(1) NOT NULL DEFAULT 0,                 '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''PLANEJADA'',                      '+
    'criado_por BIGINT UNSIGNED NULL,                                          '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                            '+
    'UNIQUE KEY uq_turma_tenant_id (id_instituicao, id),                          '+
    'UNIQUE KEY uq_turma_codigo_publico (codigo_publico),                         '+
    'UNIQUE KEY uq_turma_codigo_interno (id_instituicao, codigo_interno),         '+
    'KEY ix_turma_curso (id_instituicao, id_curso),                               '+
    'KEY ix_turma_situacao_periodo (id_instituicao, situacao, data_hora_inicio),  '+
    'CONSTRAINT fk_turma_instituicao                                              '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                  '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_turma_curso                                                    '+
    '    FOREIGN KEY (id_instituicao, id_curso)                                   '+
    '    REFERENCES curso(id_instituicao, id)                                     '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_turma_modelo_certificado                                       '+
    '    FOREIGN KEY (id_instituicao, id_modelo_certificado)                      '+
    '    REFERENCES certificado_modelo(id_instituicao, id)                        '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_turma_criado_por                                               '+
    '    FOREIGN KEY (id_instituicao, criado_por)                                 '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                       '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT ck_turma_modalidade CHECK (modalidade IN (''PRESENCIAL'',''ONLINE'',''HIBRIDO'')),  '+
    'CONSTRAINT ck_turma_situacao CHECK (situacao IN (''PLANEJADA'',''INSCRICOES_ABERTAS'',''EM_ANDAMENTO'',''ENCERRADA'',''CANCELADA'')), '+
    'CONSTRAINT ck_turma_periodo CHECK (data_hora_fim >= data_hora_inicio),                                                     '+
    'CONSTRAINT ck_turma_inscricao_periodo CHECK (inscricao_inicio IS NULL OR inscricao_fim IS NULL OR inscricao_fim >= inscricao_inicio)  '+
    ') ENGINE=InnoDB COMMENT=''Execução concreta de um curso.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_022_CreateTurmaInstrutor(const AConn: TUniConnection);
const
  VERSION = '022';
  DESCRIPTION = 'Criar tabela TurmaInstrutor';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS turma_instrutor (                 '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                 '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                       '+
    'id_instrutor BIGINT UNSIGNED NOT NULL,                                   '+
    'principal TINYINT(1) NOT NULL DEFAULT 0,                                 '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),             '+
    'PRIMARY KEY (id_instituicao, id_turma, id_instrutor),                    '+
    'CONSTRAINT fk_turma_instrutor_turma                                      '+
    '    FOREIGN KEY (id_instituicao, id_turma)                               '+
    '    REFERENCES turma(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT fk_turma_instrutor_instrutor                                  '+
    '    FOREIGN KEY (id_instituicao, id_instrutor)                           '+
    '    REFERENCES instrutor(id_instituicao, id)                             '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                                '+
    ') ENGINE=InnoDB COMMENT=''Instrutores efetivamente responsáveis pela turma.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_023_CreateTurmaEncontro(const AConn: TUniConnection);
const
  VERSION = '023';
  DESCRIPTION = 'Criar tabela TurmaEncontro';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS turma_encontro (                 '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                             '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                      '+
    'titulo VARCHAR(180) NOT NULL,                                           '+
    'descricao VARCHAR(500) NULL,                                            '+
    'data_hora_inicio DATETIME(3) NOT NULL,                                  '+
    'data_hora_fim DATETIME(3) NOT NULL,                                     '+
    'carga_horaria_minutos INT UNSIGNED NULL,                                '+
    'local VARCHAR(255) NULL,                                                '+
    'url_online VARCHAR(1000) NULL,                                          '+
    'obrigatorio TINYINT(1) NOT NULL DEFAULT 1,                              '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''AGENDADO'',                     '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),            '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),    '+
    'PRIMARY KEY (id),                                                           '+
    'UNIQUE KEY uq_turma_encontro_tenant_turma_id (id_instituicao, id_turma, id),'+
    'KEY ix_turma_encontro_data (id_instituicao, id_turma, data_hora_inicio),    '+
    'CONSTRAINT fk_turma_encontro_turma                                          '+
    '    FOREIGN KEY (id_instituicao, id_turma)                                  '+
    '    REFERENCES turma(id_instituicao, id)                                    '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                   '+
    'CONSTRAINT ck_turma_encontro_periodo CHECK (data_hora_fim >= data_hora_inicio), '+
    'CONSTRAINT ck_turma_encontro_situacao CHECK (situacao IN (''AGENDADO'',''REALIZADO'',''CANCELADO''))  '+
    ') ENGINE=InnoDB COMMENT=''Encontros/aulas presenciais ou síncronas para controle de presença.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_024_CreateTurmaCriterioConclusao(const AConn: TUniConnection);
const
  VERSION = '024';
  DESCRIPTION = 'Criar tabela TurmaCriterioConclusao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS turma_criterio_conclusao (                       '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                  '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                        '+
    'tipo VARCHAR(40) NOT NULL,                                                '+
    'nome VARCHAR(180) NOT NULL,                                               '+
    'obrigatorio TINYINT(1) NOT NULL DEFAULT 1,                                '+
    'configuracao JSON NULL COMMENT ''Ex.: {"percentual_minimo":75} para PRESENCA_MINIMA.'',     '+
    'ordem SMALLINT UNSIGNED NOT NULL DEFAULT 1,                                               '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',                                            '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),      '+
    'PRIMARY KEY (id),                                                                                   '+
    'UNIQUE KEY uq_turma_criterio_tenant_turma_id (id_instituicao, id_turma, id),                        '+
    'KEY ix_turma_criterio_tipo (id_instituicao, id_turma, tipo),                                        '+
    'CONSTRAINT fk_turma_criterio_turma                                                                  '+
    '    FOREIGN KEY (id_instituicao, id_turma)                                                         '+
    '    REFERENCES turma(id_instituicao, id)                                                           '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                                          '+
    'CONSTRAINT ck_turma_criterio_tipo CHECK (tipo IN (''PRESENCA_MINIMA'',''AULAS_CONCLUIDAS'',''AVALIACAO'',''ATIVIDADE'',''APROVACAO_MANUAL'',''OUTRO'')),'+
    'CONSTRAINT ck_turma_criterio_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))    '+
    ') ENGINE=InnoDB COMMENT=''Regras flexíveis que determinam a conclusão/certificação.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_025_CreateInscricao(const AConn: TUniConnection);
const
  VERSION = '025';
  DESCRIPTION = 'Criar tabela Inscricao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS inscricao (                        '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                              '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                 '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                       '+
    'id_participante BIGINT UNSIGNED NOT NULL,                                '+
    'codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,  '+
    'origem VARCHAR(20) NOT NULL DEFAULT ''ADMIN'',                             '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''INSCRITO'',          '+
    'inscrito_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),  '+
    'confirmado_em DATETIME(3) NULL,                                 '+
    'iniciado_em DATETIME(3) NULL,                                   '+
    'concluido_em DATETIME(3) NULL,                                  '+
    'cancelado_em DATETIME(3) NULL,                                  '+
    'motivo_cancelamento VARCHAR(500) NULL,                          '+
    'percentual_presenca DECIMAL(5,2) NULL,                          '+
    'percentual_progresso DECIMAL(5,2) NOT NULL DEFAULT 0.00,        '+
    'nota_final DECIMAL(8,2) NULL,                                  '+
    'elegivel_certificado TINYINT(1) NOT NULL DEFAULT 0,            '+
    'criado_por BIGINT UNSIGNED NULL,                               '+
    'atualizado_por BIGINT UNSIGNED NULL,                           '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),   '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),  '+
    'PRIMARY KEY (id),                                                                      '+
    'UNIQUE KEY uq_inscricao_tenant_turma_id (id_instituicao, id_turma, id),                '+
    'UNIQUE KEY uq_inscricao_codigo_publico (codigo_publico),                               '+
    'UNIQUE KEY uq_inscricao_participante_turma (id_instituicao, id_turma, id_participante),'+
    'KEY ix_inscricao_participante (id_instituicao, id_participante, situacao),             '+
    'KEY ix_inscricao_turma_situacao (id_instituicao, id_turma, situacao),                  '+
    'KEY ix_inscricao_data (id_instituicao, inscrito_em),                                   '+
    'CONSTRAINT fk_inscricao_turma                                                          '+
    '    FOREIGN KEY (id_instituicao, id_turma)                                             '+
    '    REFERENCES turma(id_instituicao, id)                                               '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                             '+
    'CONSTRAINT fk_inscricao_participante                                                   '+
    '    FOREIGN KEY (id_instituicao, id_participante)                                      '+
    '    REFERENCES participante(id_instituicao, id)                                        '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                             '+
    'CONSTRAINT fk_inscricao_criado_por                                                     '+
    '    FOREIGN KEY (id_instituicao, criado_por)                                           '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                             '+
    'CONSTRAINT fk_inscricao_atualizado_por                                                 '+
    '    FOREIGN KEY (id_instituicao, atualizado_por)                                       '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                                 '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                             '+
    'CONSTRAINT ck_inscricao_origem CHECK (origem IN (''PUBLICA'',''ADMIN'',''IMPORTACAO'',''API'')), '+
    'CONSTRAINT ck_inscricao_situacao CHECK (situacao IN (''INSCRITO'',''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'',''CANCELADO'',''REPROVADO'',''DESISTENTE'')), '+
    'CONSTRAINT ck_inscricao_presenca CHECK (percentual_presenca IS NULL OR (percentual_presenca >= 0 AND percentual_presenca <= 100)),   '+
    'CONSTRAINT ck_inscricao_progresso CHECK (percentual_progresso >= 0 AND percentual_progresso <= 100)    '+
    ') ENGINE=InnoDB COMMENT=''Vínculo entre participante e turma.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_026_CreateInscricaoHistorico(const AConn: TUniConnection);
const
  VERSION = '026';
  DESCRIPTION = 'Criar tabela InscricaoHistorico';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS inscricao_historico (                       '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                          '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                             '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                   '+
    'id_inscricao BIGINT UNSIGNED NOT NULL,                               '+
    'situacao_anterior VARCHAR(20) NULL,                                  '+
    'situacao_nova VARCHAR(20) NOT NULL,                                  '+
    'observacao VARCHAR(500) NULL,                                        '+
    'alterado_por BIGINT UNSIGNED NULL,                                   '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),         '+
    'PRIMARY KEY (id),                                                    '+
    'KEY ix_inscricao_historico_inscricao (id_instituicao, id_inscricao, criado_em),   '+
    'CONSTRAINT fk_inscricao_historico_inscricao                         '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_inscricao)            '+
    '    REFERENCES inscricao(id_instituicao, id_turma, id)              '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                           '+
    'CONSTRAINT fk_inscricao_historico_usuario                           '+
    '    FOREIGN KEY (id_instituicao, alterado_por)                      '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)              '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                           '+
    ') ENGINE=InnoDB COMMENT=''Histórico de mudanças de situação da inscrição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_027_CreatePresenca(const AConn: TUniConnection);
const
  VERSION = '027';
  DESCRIPTION = 'Criar tabela Presenca';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS presenca (                       '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                             '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                      '+
    'id_encontro BIGINT UNSIGNED NOT NULL,                                   '+
    'id_inscricao BIGINT UNSIGNED NOT NULL,                                  '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''PRESENTE'',                       '+
    'checkin_em DATETIME(3) NULL,              '+
    'checkout_em DATETIME(3) NULL,             '+
    'minutos_presentes INT UNSIGNED NULL,      '+
    'justificativa VARCHAR(500) NULL,          '+
    'registrado_por BIGINT UNSIGNED NULL,      '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),     '+
    'PRIMARY KEY (id),                                              '+
    'UNIQUE KEY uq_presenca_encontro_inscricao (id_instituicao, id_encontro, id_inscricao), '+
    'KEY ix_presenca_inscricao (id_instituicao, id_inscricao),          '+
    'CONSTRAINT fk_presenca_encontro                                    '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_encontro)            '+
    '    REFERENCES turma_encontro(id_instituicao, id_turma, id)        '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                          '+
    'CONSTRAINT fk_presenca_inscricao                                   '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_inscricao)           '+
    '    REFERENCES inscricao(id_instituicao, id_turma, id)             '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                          '+
    'CONSTRAINT fk_presenca_registrado_por                              '+
    '    FOREIGN KEY (id_instituicao, registrado_por)                   '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)             '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                         '+
    'CONSTRAINT ck_presenca_situacao CHECK (situacao IN (''PRESENTE'',''AUSENTE'',''JUSTIFICADA'',''PARCIAL'')) '+
    ') ENGINE=InnoDB COMMENT=''Presença do inscrito em cada encontro da turma.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_028_CreateInscricaoAulaProgresso(const AConn: TUniConnection);
const
  VERSION = '028';
  DESCRIPTION = 'Criar tabela InscricaoAulaProgresso';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS inscricao_aula_progresso (                               '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                     '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                                        '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                                              '+
    'id_inscricao BIGINT UNSIGNED NOT NULL,                                                          '+
    'id_curso BIGINT UNSIGNED NOT NULL,                                                              '+
    'id_aula BIGINT UNSIGNED NOT NULL,                                                               '+
    'percentual DECIMAL(5,2) NOT NULL DEFAULT 0.00,                                                  '+
    'duracao_assistida_segundos INT UNSIGNED NOT NULL DEFAULT 0,                                     '+
    'iniciado_em DATETIME(3) NULL,                                                                   '+
    'concluido_em DATETIME(3) NULL,                                                                  '+
    'ultimo_acesso_em DATETIME(3) NULL,                                                              '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                                               '+
    'UNIQUE KEY uq_inscricao_aula_progresso (id_instituicao, id_inscricao, id_aula),                 '+
    'KEY ix_inscricao_aula_turma (id_instituicao, id_turma, id_inscricao),                           '+
    'CONSTRAINT fk_inscricao_aula_inscricao                                                          '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_inscricao)                                        '+
    '    REFERENCES inscricao(id_instituicao, id_turma, id)                                          '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                                       '+
    'CONSTRAINT fk_inscricao_aula_aula                                                               '+
    '    FOREIGN KEY (id_instituicao, id_curso, id_aula)                                             '+
    '    REFERENCES curso_aula(id_instituicao, id_curso, id)                                         '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                                       '+
    'CONSTRAINT ck_inscricao_aula_percentual CHECK (percentual >= 0 AND percentual <= 100)           '+
    ') ENGINE=InnoDB COMMENT=''Progresso em aulas online/híbridas.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_029_CreateInscricaoCriterioResultado(const AConn: TUniConnection);
const
  VERSION = '029';
  DESCRIPTION = 'Criar tabela InscricaoCriterioResultado';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS inscricao_criterio_resultado (         '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                   '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                      '+
    'id_turma BIGINT UNSIGNED NOT NULL,                                            '+
    'id_inscricao BIGINT UNSIGNED NOT NULL,                                        '+
    'id_criterio BIGINT UNSIGNED NOT NULL,                                         '+
    'atendido TINYINT(1) NULL COMMENT ''NULL = ainda não avaliado.'',                '+
    'resultado JSON NULL COMMENT ''Ex.: percentual obtido, nota, observações.'',     '+
    'avaliado_por BIGINT UNSIGNED NULL,                                              '+
    'avaliado_em DATETIME(3) NULL,                                                   '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id),                                                              '+
    'UNIQUE KEY uq_inscricao_criterio (id_instituicao, id_inscricao, id_criterio),  '+
    'CONSTRAINT fk_inscricao_criterio_inscricao                                     '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_inscricao)                       '+
    '    REFERENCES inscricao(id_instituicao, id_turma, id)                         '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                      '+
    'CONSTRAINT fk_inscricao_criterio_criterio                                      '+
    '    FOREIGN KEY (id_instituicao, id_turma, id_criterio)                        '+
    '    REFERENCES turma_criterio_conclusao(id_instituicao, id_turma, id)          '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                      '+
    'CONSTRAINT fk_inscricao_criterio_avaliado_por                                  '+
    '    FOREIGN KEY (id_instituicao, avaliado_por)                                 '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                         '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                                      '+
    ') ENGINE=InnoDB COMMENT=''Resultado de cada critério de conclusão para cada inscrição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_030_CreateCertificadoConfiguracao(const AConn: TUniConnection);
const
  VERSION = '030';
  DESCRIPTION = 'Criar tabela CertificadoConfiguracao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS certificado_configuracao (    '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,    '+
    'id_modelo_padrao BIGINT UNSIGNED NULL,    '+
    'prefixo VARCHAR(30) NULL COMMENT ''Ex.: CERT. A API monta o número público.'', '+
    'usar_ano TINYINT(1) NOT NULL DEFAULT 1,                '+
    'digitos_sequencia TINYINT UNSIGNED NOT NULL DEFAULT 6,  '+
    'texto_validacao VARCHAR(255) NOT NULL DEFAULT ''Valide este certificado'',    '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                             '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id_instituicao),                                            '+
    'CONSTRAINT fk_certificado_config_instituicao                             '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)              '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                                '+
    'CONSTRAINT fk_certificado_config_modelo                                  '+
    '    FOREIGN KEY (id_instituicao, id_modelo_padrao)                       '+
    '    REFERENCES certificado_modelo(id_instituicao, id)                    '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                               '+
    'CONSTRAINT ck_certificado_digitos CHECK (digitos_sequencia BETWEEN 4 AND 12)   '+
    ') ENGINE=InnoDB COMMENT=''Configuração de emissão/numeração por instituição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_031_CreateCertificadoSequencia(const AConn: TUniConnection);
const
  VERSION = '031';
  DESCRIPTION = 'Criar tabela CertificadoSequencia';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS certificado_sequencia (                               '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                       '+
    'ano SMALLINT UNSIGNED NOT NULL COMMENT ''Use 0 se a instituição não reiniciar a numeração por ano.'',  '+
    'ultimo_numero BIGINT UNSIGNED NOT NULL DEFAULT 0,                                          '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id_instituicao, ano),                                '+
    'CONSTRAINT fk_certificado_sequencia_instituicao                   '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)       '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE                          '+
    ') ENGINE=InnoDB COMMENT=''Controle transacional da sequência pública do certificado.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_032_CreateCertificado(
  const AConn: TUniConnection);
const
  VERSION = '032';
  DESCRIPTION = 'Criar tabela Certificado';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS certificado ( ' +

    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, ' +
    'id_instituicao BIGINT UNSIGNED NOT NULL, ' +
    'id_inscricao BIGINT UNSIGNED NOT NULL, ' +
    'id_turma BIGINT UNSIGNED NOT NULL, ' +
    'id_participante BIGINT UNSIGNED NOT NULL, ' +
    'id_curso BIGINT UNSIGNED NOT NULL, ' +
    'id_modelo BIGINT UNSIGNED NULL, ' +

    'id_certificado_origem BIGINT UNSIGNED NULL ' +
    'COMMENT ''Preenchido quando for reemissão de outro certificado.'', ' +

    'numero_publico VARCHAR(80) ' +
    'CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL, ' +

    'codigo_validacao VARCHAR(80) ' +
    'CHARACTER SET ascii COLLATE ascii_bin NOT NULL ' +
    'COMMENT ''Token público aleatório; mínimo recomendado: 128 bits.'', ' +

    'versao SMALLINT UNSIGNED NOT NULL DEFAULT 1, ' +

    'situacao VARCHAR(20) NOT NULL DEFAULT ''PENDENTE'', ' +

    // Só deve ser preenchido quando o certificado tornar-se válido.
    'emitido_em DATETIME(3) NULL, ' +

    'cancelado_em DATETIME(3) NULL, ' +
    'motivo_cancelamento VARCHAR(500) NULL, ' +
    'motivo_reemissao VARCHAR(500) NULL, ' +

    // Snapshot histórico do conteúdo certificado.
    'participante_nome VARCHAR(180) NOT NULL, ' +
    'curso_nome VARCHAR(200) NOT NULL, ' +
    'instituicao_nome VARCHAR(180) NOT NULL, ' +
    'carga_horaria_minutos INT UNSIGNED NOT NULL, ' +
    'data_conclusao DATETIME(3) NOT NULL, ' +

    // Dados físicos/integridade do PDF.
    'pdf_storage_key VARCHAR(500) NULL, ' +
    'pdf_sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL, ' +
    'pdf_tamanho_bytes BIGINT UNSIGNED NULL, ' +
    'pdf_gerado_em DATETIME(3) NULL, ' +

    'emitido_por BIGINT UNSIGNED NULL, ' +

    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), ' +

    'atualizado_em DATETIME(3) NOT NULL ' +
    'DEFAULT CURRENT_TIMESTAMP(3) ' +
    'ON UPDATE CURRENT_TIMESTAMP(3), ' +

    'PRIMARY KEY (id), ' +

    'UNIQUE KEY uq_certificado_tenant_id ' +
    '(id_instituicao, id), ' +

    'UNIQUE KEY uq_certificado_numero_publico ' +
    '(id_instituicao, numero_publico), ' +

    'UNIQUE KEY uq_certificado_codigo_validacao ' +
    '(codigo_validacao), ' +

    'KEY ix_certificado_inscricao ' +
    '(id_instituicao, id_inscricao), ' +

    'KEY ix_certificado_participante ' +
    '(id_instituicao, id_participante, emitido_em), ' +

    'KEY ix_certificado_curso ' +
    '(id_instituicao, id_curso, emitido_em), ' +

    'KEY ix_certificado_situacao ' +
    '(id_instituicao, situacao, emitido_em), ' +

    'KEY ix_certificado_origem ' +
    '(id_instituicao, id_certificado_origem), ' +

    'KEY ix_certificado_modelo ' +
    '(id_instituicao, id_modelo), ' +

    'KEY ix_certificado_emitido_por ' +
    '(id_instituicao, emitido_por), ' +

    'CONSTRAINT fk_certificado_inscricao ' +
    'FOREIGN KEY (id_instituicao, id_turma, id_inscricao) ' +
    'REFERENCES inscricao(id_instituicao, id_turma, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_participante ' +
    'FOREIGN KEY (id_instituicao, id_participante) ' +
    'REFERENCES participante(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_curso ' +
    'FOREIGN KEY (id_instituicao, id_curso) ' +
    'REFERENCES curso(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_turma ' +
    'FOREIGN KEY (id_instituicao, id_turma) ' +
    'REFERENCES turma(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_modelo ' +
    'FOREIGN KEY (id_instituicao, id_modelo) ' +
    'REFERENCES certificado_modelo(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_origem ' +
    'FOREIGN KEY (id_instituicao, id_certificado_origem) ' +
    'REFERENCES certificado(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT fk_certificado_emitido_por ' +
    'FOREIGN KEY (id_instituicao, emitido_por) ' +
    'REFERENCES usuario_instituicao(id_instituicao, id) ' +
    'ON UPDATE RESTRICT ON DELETE RESTRICT, ' +

    'CONSTRAINT ck_certificado_situacao ' +
    'CHECK (situacao IN (' +
      '''PENDENTE'',' +
      '''VALIDO'',' +
      '''CANCELADO'',' +
      '''ERRO''' +
    ')) ' +

    ') ENGINE=InnoDB ' +
    'COMMENT=''Certificados emitidos com snapshot histórico e validação pública.'';'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_033_CreateCertificadoHistorico(const AConn: TUniConnection);
const
  VERSION = '033';
  DESCRIPTION = 'Criar tabela CertificadoHistorico';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS certificado_historico (                    '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                         '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                            '+
    'id_certificado BIGINT UNSIGNED NOT NULL,                            '+
    'evento VARCHAR(30) NOT NULL,                                        '+
    'descricao VARCHAR(500) NULL,                                        '+
    'dados JSON NULL,                                                    '+
    'id_usuario_instituicao BIGINT UNSIGNED NULL,                        '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),        '+
    'PRIMARY KEY (id),                                                   '+
    'KEY ix_certificado_historico_certificado (id_instituicao, id_certificado, criado_em), '+
    'CONSTRAINT fk_certificado_historico_certificado               '+
    '    FOREIGN KEY (id_instituicao, id_certificado)              '+
    '    REFERENCES certificado(id_instituicao, id)                '+
    '    ON UPDATE RESTRICT ON DELETE CASCADE,                     '+
    'CONSTRAINT fk_certificado_historico_usuario                   '+
    '    FOREIGN KEY (id_instituicao, id_usuario_instituicao)      '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)        '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                    '+
    'CONSTRAINT ck_certificado_historico_evento CHECK (evento IN (''EMITIDO'',''PDF_GERADO'',''CANCELADO'',''REEMITIDO'',''ERRO'')) '+
    ') ENGINE=InnoDB COMMENT=''Rastreabilidade de emissão, cancelamento e reemissão.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_034_CreateCertificadoValidacaoAcesso(const AConn: TUniConnection);
const
  VERSION = '034';
  DESCRIPTION = 'Criar tabela CertificadoValidacaoAcesso';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS certificado_validacao_acesso (    '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                '+
    'id_instituicao BIGINT UNSIGNED NULL COMMENT ''Pode ser NULL quando um código inexistente não permite identificar o tenant.'', '+
    'id_certificado BIGINT UNSIGNED NULL COMMENT ''Pode ser NULL quando um código inexistente for consultado.'','+
    'codigo_consultado_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL COMMENT ''Evita logar o token público em claro.'', '+
    'resultado VARCHAR(30) NOT NULL,                                       '+
    'ip VARCHAR(45) NULL,                                                  '+
    'user_agent VARCHAR(1000) NULL,                                        '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),           '+
    'PRIMARY KEY (id),                                                        '+
    'KEY ix_validacao_certificado_data (id_instituicao, id_certificado, criado_em),'+
    'KEY ix_validacao_resultado_data (resultado, criado_em),            '+
    'CONSTRAINT fk_validacao_instituicao                                 '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)          '+
    '    ON UPDATE RESTRICT ON DELETE SET NULL,                            '+
    'CONSTRAINT fk_validacao_certificado                                    '+
    '    FOREIGN KEY (id_instituicao, id_certificado)                         '+
    '    REFERENCES certificado(id_instituicao, id)                            '+
    '    ON UPDATE RESTRICT ON DELETE SET NULL,                                 '+
    'CONSTRAINT ck_validacao_resultado CHECK (resultado IN (''VALIDO'',''CANCELADO'',''NAO_ENCONTRADO'',''ERRO''))  '+
    ') ENGINE=InnoDB COMMENT=''Log opcional das validações públicas. Aplicar política de retenção LGPD.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_035_CreateTermo(const AConn: TUniConnection);
const
  VERSION = '035';
  DESCRIPTION = 'Criar tabela Termo';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS termo (              '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT, '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,  '+
    'tipo VARCHAR(30) NOT NULL,              '+
    'titulo VARCHAR(180) NOT NULL,         '+
    'versao VARCHAR(30) NOT NULL,        '+
    'conteudo LONGTEXT NOT NULL,                                                         '+
    'publicado_em DATETIME(3) NOT NULL,                                                    '+
    'vigente TINYINT(1) NOT NULL DEFAULT 1,                                                 '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                            '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3), '+
    'PRIMARY KEY (id),                                                                      '+
    'UNIQUE KEY uq_termo_tenant_id (id_instituicao, id),                                   '+
    'UNIQUE KEY uq_termo_versao (id_instituicao, tipo, versao),                           '+
    'KEY ix_termo_vigente (id_instituicao, tipo, vigente),                               '+
    'CONSTRAINT fk_termo_instituicao                                                    '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                       '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                       '+
    'CONSTRAINT ck_termo_tipo CHECK (tipo IN (''PRIVACIDADE'',''USO'',''CONSENTIMENTO'',''OUTRO'')) '+
    ') ENGINE=InnoDB COMMENT=''Versões de termos e política de privacidade por instituição.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_036_CreateTermoAceite(const AConn: TUniConnection);
const
  VERSION = '036';
  DESCRIPTION = 'Criar tabela TermoAceite';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS termo_aceite (                                             '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                         '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                            '+
    'id_termo BIGINT UNSIGNED NOT NULL,                                                  '+
    'id_participante BIGINT UNSIGNED NULL,                                               '+
    'id_usuario_instituicao BIGINT UNSIGNED NULL,                                        '+
    'ip VARCHAR(45) NULL,                                                                '+
    'user_agent VARCHAR(1000) NULL,                                                      '+
    'aceito_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                        '+
    'PRIMARY KEY (id),                                                                   '+
    'KEY ix_termo_aceite_participante (id_instituicao, id_participante, aceito_em),      '+
    'KEY ix_termo_aceite_usuario (id_instituicao, id_usuario_instituicao, aceito_em),    '+
    'CONSTRAINT fk_termo_aceite_termo                                                    '+
    '    FOREIGN KEY (id_instituicao, id_termo)                                          '+
    '    REFERENCES termo(id_instituicao, id)                                            '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                          '+
    'CONSTRAINT fk_termo_aceite_participante                                             '+
    '    FOREIGN KEY (id_instituicao, id_participante)                                   '+
    '    REFERENCES participante(id_instituicao, id)                                     '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                          '+
    'CONSTRAINT fk_termo_aceite_usuario                                                  '+
    '    FOREIGN KEY (id_instituicao, id_usuario_instituicao)                            '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                              '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                          '+
    'CONSTRAINT ck_termo_aceite_pessoa CHECK (                                           '+
    '    (id_participante IS NOT NULL AND id_usuario_instituicao IS NULL)                '+
    '    OR                                                                              '+
    '    (id_participante IS NULL AND id_usuario_instituicao IS NOT NULL)                '+
    '  )                                                                                 '+
    '    ) ENGINE=InnoDB COMMENT=''Prova de aceite de termos pelo participante ou usuário administrativo.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_037_CreateLgpdSolicitacao(const AConn: TUniConnection);
const
  VERSION = '037';
  DESCRIPTION = 'Criar tabela LgpdSolicitacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS lgpd_solicitacao (                      '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                    '+
    'id_instituicao BIGINT UNSIGNED NOT NULL,                                       '+
    'id_participante BIGINT UNSIGNED NULL,                                          '+
    'protocolo VARCHAR(50) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,   '+
    'tipo VARCHAR(30) NOT NULL,                                                     '+
    'situacao VARCHAR(20) NOT NULL DEFAULT ''ABERTA'',                              '+
    'descricao TEXT NULL,                                                           '+
    'resposta TEXT NULL,                                                            '+
    'solicitado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),               '+
    'concluido_em DATETIME(3) NULL,                                                 '+
    'responsavel BIGINT UNSIGNED NULL,                                              '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),                   '+
    'atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id),                                                            '+
    'UNIQUE KEY uq_lgpd_protocolo (id_instituicao, protocolo),                    '+
    'KEY ix_lgpd_situacao_data (id_instituicao, situacao, solicitado_em),         '+
    'CONSTRAINT fk_lgpd_instituicao                                               '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)                  '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_lgpd_participante                                              '+
    '    FOREIGN KEY (id_instituicao, id_participante)                            '+
    '    REFERENCES participante(id_instituicao, id)                              '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT fk_lgpd_responsavel                                               '+
    '    FOREIGN KEY (id_instituicao, responsavel)                                '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)                       '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                                   '+
    'CONSTRAINT ck_lgpd_tipo CHECK (tipo IN (''ACESSO'',''CORRECAO'',''ANONIMIZACAO'',''EXCLUSAO'',''PORTABILIDADE'',''REVOGACAO'',''OUTRO'')),       '+
    'CONSTRAINT ck_lgpd_situacao CHECK (situacao IN (''ABERTA'',''EM_ANALISE'',''ATENDIDA'',''NEGADA'',''CANCELADA''))     '+
    ') ENGINE=InnoDB COMMENT=''Registro de solicitações relacionadas aos direitos do titular.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_038_CreateAuditoriaLog(const AConn: TUniConnection);
const
  VERSION = '038';
  DESCRIPTION = 'Criar tabela AuditoriaLog';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS auditoria_log (                                        '+
    'id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,                                                   '+
    'id_instituicao BIGINT UNSIGNED NULL COMMENT ''NULL para ações estritamente globais do SaaS.'',  '+
    'id_usuario BIGINT UNSIGNED NULL,                                                             '+
    'id_usuario_instituicao BIGINT UNSIGNED NULL,                                                 '+
    'acao VARCHAR(80) NOT NULL,                                                                   '+
    'entidade VARCHAR(80) NULL,                                                                   '+
    'registro_id VARCHAR(100) NULL,                         '+
    'metodo_http VARCHAR(10) NULL,                          '+
    'rota VARCHAR(500) NULL,                                '+
    'ip VARCHAR(45) NULL,                                   '+
    'user_agent VARCHAR(1000) NULL,                         '+
    'sucesso TINYINT(1) NOT NULL DEFAULT 1,                 '+
    'mensagem VARCHAR(1000) NULL,                           '+
    'dados_anteriores JSON NULL COMMENT ''Nunca registrar senha, token ou dados pessoais desnecessários.'', '+
    'dados_novos JSON NULL COMMENT ''Aplicar redaction antes de persistir.'', '+
    'criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),'+
    'PRIMARY KEY (id),                                           '+
    'KEY ix_auditoria_tenant_data (id_instituicao, criado_em),   '+
    'KEY ix_auditoria_usuario_data (id_usuario, criado_em),      '+
    'KEY ix_auditoria_entidade_registro (id_instituicao, entidade, registro_id),    '+
    'KEY ix_auditoria_acao_data (acao, criado_em),                '+
    'CONSTRAINT fk_auditoria_instituicao                           '+
    '    FOREIGN KEY (id_instituicao) REFERENCES instituicao(id)     '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                        '+
    'CONSTRAINT fk_auditoria_usuario                                     '+
    '    FOREIGN KEY (id_usuario) REFERENCES usuario(id)                   '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT,                              '+
    'CONSTRAINT fk_auditoria_usuario_instituicao                               '+
    '    FOREIGN KEY (id_instituicao, id_usuario_instituicao)  '+
    '    REFERENCES usuario_instituicao(id_instituicao, id)      '+
    '    ON UPDATE RESTRICT ON DELETE RESTRICT                     '+
    ') ENGINE=InnoDB COMMENT=''Auditoria central de operações relevantes.'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_039_AtualizaInstituicaoAdministracao(const AConn: TUniConnection);
const
  VERSION = '039';
  DESCRIPTION = 'Adicionar tipo e situacao implantacao em instituicao';
begin
  if MigrationExists(AConn, VERSION) then Exit;
  // Define se o tenant é uma empresa privada ou instituição pública.
  ExecSQL(AConn,
    'ALTER TABLE instituicao ' +
    'ADD COLUMN tipo VARCHAR(20) NOT NULL DEFAULT ''PRIVADA'' AFTER cnpj'
  );
  // Inclui a etapa de implantação utilizada no onboarding do cliente.
  ExecSQL(AConn, 'ALTER TABLE instituicao DROP CHECK ck_instituicao_situacao');
  ExecSQL(AConn,
    'ALTER TABLE instituicao ' +
    'ADD CONSTRAINT ck_instituicao_situacao ' +
    'CHECK (situacao IN (''ATIVA'',''IMPLANTACAO'',''INATIVA'',''BLOQUEADA''))'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCursosMigration.Migration_040_ConfigInstituicaoMidiasWhatsApp(
  const AConn: TUniConnection);
const
  VERSION = '040';
  DESCRIPTION = 'Configuracoes instituicao, midias e WhatsApp';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  // Dados institucionais exibidos na area publica.
  ExecSQL(
    AConn,
    'ALTER TABLE instituicao ' +
    'ADD COLUMN descricao TEXT NULL AFTER nome_fantasia'
  );

  // Banner utilizado na home publica da instituicao.
  ExecSQL(
    AConn,
    'ALTER TABLE instituicao_configuracao ' +
    'ADD COLUMN banner_url VARCHAR(1000) NULL AFTER imagem_login_url'
  );

  // Configuracao da Evolution API por tenant.
  // O token nunca e salvo em texto puro.
  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS instituicao_whatsapp_configuracao (' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' ativo TINYINT(1) NOT NULL DEFAULT 0,' +
    ' url VARCHAR(1000) NOT NULL DEFAULT '''',' +
    ' token_criptografado VARBINARY(2048) NULL,' +
    ' token_hint VARCHAR(16) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id_instituicao),' +
    ' CONSTRAINT fk_instituicao_whatsapp_instituicao ' +
    '   FOREIGN KEY (id_instituicao) REFERENCES instituicao(id) ' +
    '   ON UPDATE RESTRICT ON DELETE CASCADE' +
    ') ENGINE=InnoDB COMMENT=''Configuracao Evolution API por instituicao.'';'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;


class procedure TCursosMigration.Migration_041_PlataformaWhatsAppConfiguracao(
  const AConn: TUniConnection);
const
  VERSION = '041';
  DESCRIPTION = 'Configuracao global da API WhatsApp';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_whatsapp_configuracao (' +
    ' id TINYINT UNSIGNED NOT NULL,' +
    ' habilitado TINYINT(1) NOT NULL DEFAULT 0,' +
    ' api_url VARCHAR(1000) NOT NULL DEFAULT '''',' +
    ' api_key_criptografada VARBINARY(2048) NULL,' +
    ' api_key_hint VARCHAR(16) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' CONSTRAINT ck_plataforma_whatsapp_unico CHECK (id = 1)' +
    ') ENGINE=InnoDB COMMENT=''Configuracao global da Evolution API para o SaaS.'';'
  );

  ExecSQL(
    AConn,
    'INSERT IGNORE INTO plataforma_whatsapp_configuracao ' +
    '(id, habilitado, api_url) VALUES (1, 0, '''')'
  );

  RegisterMigration(
    AConn,
    VERSION,
    DESCRIPTION
  );
end;


class procedure TCursosMigration.Migration_042_InstituicaoWhatsAppInstancia(
  const AConn: TUniConnection);
const
  VERSION = '042';
  DESCRIPTION = 'Instancia WhatsApp por instituicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS instituicao_whatsapp_instancia (' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' nome_instancia VARCHAR(160) CHARACTER SET ascii COLLATE ascii_general_ci NOT NULL,' +
    ' estado VARCHAR(30) NOT NULL DEFAULT ''CREATED'',' +
    ' numero_conectado VARCHAR(80) NULL,' +
    ' ultimo_status_em DATETIME(3) NULL,' +
    ' ultimo_erro VARCHAR(1000) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id_instituicao),' +
    ' UNIQUE KEY uq_instituicao_whatsapp_nome (nome_instancia),' +
    ' CONSTRAINT fk_instituicao_whatsapp_instancia_instituicao ' +
    '   FOREIGN KEY (id_instituicao) REFERENCES instituicao(id) ' +
    '   ON UPDATE RESTRICT ON DELETE CASCADE' +
    ') ENGINE=InnoDB COMMENT=''Instancia Evolution API exclusiva por instituicao.'';'
  );

  RegisterMigration(
    AConn,
    VERSION,
    DESCRIPTION
  );
end;


class procedure TCursosMigration.Migration_043_PlataformaAjuda(
  const AConn: TUniConnection);
const
  VERSION = '043';
  DESCRIPTION = 'Conteudo global de ajuda da plataforma';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_ajuda (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' url_youtube VARCHAR(1000) NOT NULL,' +
    ' assunto VARCHAR(180) NOT NULL,' +
    ' descricao TEXT NOT NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',' +
    ' ordem INT NOT NULL DEFAULT 0,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' KEY ix_plataforma_ajuda_situacao_ordem (situacao, ordem, id),' +
    ' CONSTRAINT ck_plataforma_ajuda_situacao ' +
    '   CHECK (situacao IN (''ATIVO'',''INATIVO''))' +
    ') ENGINE=InnoDB COMMENT=''Videos e orientacoes globais publicados pelo administrador SaaS.'';'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;


class procedure TCursosMigration.Migration_044_InstituicaoEmailConfiguracao(
  const AConn: TUniConnection);
const
  VERSION = '044';
  DESCRIPTION = 'Configuracao SMTP por instituicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS instituicao_email_configuracao (' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' ativo TINYINT(1) NOT NULL DEFAULT 0,' +
    ' smtp_host VARCHAR(255) NOT NULL DEFAULT '''',' +
    ' smtp_porta SMALLINT UNSIGNED NOT NULL DEFAULT 587,' +
    ' seguranca VARCHAR(20) NOT NULL DEFAULT ''STARTTLS'',' +
    ' usuario VARCHAR(254) NOT NULL DEFAULT '''',' +
    ' senha_criptografada VARBINARY(4096) NULL,' +
    ' senha_hint VARCHAR(16) NULL,' +
    ' remetente_nome VARCHAR(180) NOT NULL DEFAULT '''',' +
    ' remetente_email VARCHAR(254) NOT NULL DEFAULT '''',' +
    ' responder_para VARCHAR(254) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id_instituicao),' +
    ' CONSTRAINT fk_instituicao_email_config_instituicao ' +
    '   FOREIGN KEY (id_instituicao) REFERENCES instituicao(id) ' +
    '   ON UPDATE RESTRICT ON DELETE CASCADE,' +
    ' CONSTRAINT ck_instituicao_email_seguranca ' +
    '   CHECK (seguranca IN (''STARTTLS'',''SSL_TLS'',''NONE''))' +
    ') ENGINE=InnoDB COMMENT=''Configuracao SMTP isolada por instituicao.'';'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;



class procedure TCursosMigration.Migration_045_PlataformaEmailConfiguracao(
  const AConn: TUniConnection);
const
  VERSION = '045';
  DESCRIPTION = 'Configuracao SMTP global da plataforma';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_email_configuracao (' +
    ' id TINYINT UNSIGNED NOT NULL,' +
    ' ativo TINYINT(1) NOT NULL DEFAULT 0,' +
    ' smtp_host VARCHAR(255) NOT NULL DEFAULT '''',' +
    ' smtp_porta SMALLINT UNSIGNED NOT NULL DEFAULT 587,' +
    ' seguranca VARCHAR(20) NOT NULL DEFAULT ''STARTTLS'',' +
    ' usuario VARCHAR(254) NOT NULL DEFAULT '''',' +
    ' senha_criptografada VARBINARY(4096) NULL,' +
    ' senha_hint VARCHAR(16) NULL,' +
    ' remetente_nome VARCHAR(180) NOT NULL DEFAULT '''',' +
    ' remetente_email VARCHAR(254) NOT NULL DEFAULT '''',' +
    ' responder_para VARCHAR(254) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ' +
    '   ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' CONSTRAINT ck_plataforma_email_id CHECK (id = 1),' +
    ' CONSTRAINT ck_plataforma_email_seguranca ' +
    '   CHECK (seguranca IN (''STARTTLS'',''SSL_TLS'',''NONE''))' +
    ') ENGINE=InnoDB COMMENT=''Configuracao SMTP global da plataforma SaaS.'';'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;



class procedure TCursosMigration.Migration_046_RecuperacaoSenhaTenantTipo(
  const AConn: TUniConnection);
const
  VERSION = '046';
  DESCRIPTION = 'Vincular token de senha ao tenant e finalidade';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'ALTER TABLE usuario_recuperacao_senha ' +
    'ADD COLUMN id_instituicao BIGINT UNSIGNED NULL AFTER id_usuario'
  );

  ExecSQL(
    AConn,
    'ALTER TABLE usuario_recuperacao_senha ' +
    'ADD COLUMN tipo VARCHAR(30) NOT NULL DEFAULT ''PRIMEIRO_ACESSO'' AFTER id_instituicao'
  );

  ExecSQL(
    AConn,
    'ALTER TABLE usuario_recuperacao_senha ' +
    'ADD KEY ix_recuperacao_tenant_tipo (id_instituicao, tipo, criado_em)'
  );

  ExecSQL(
    AConn,
    'ALTER TABLE usuario_recuperacao_senha ' +
    'ADD CONSTRAINT fk_recuperacao_instituicao ' +
    'FOREIGN KEY (id_instituicao) REFERENCES instituicao(id) ' +
    'ON UPDATE RESTRICT ON DELETE CASCADE'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;



class procedure TCursosMigration.Migration_047_CanaisEnvioAcesso(
  const AConn: TUniConnection);
const
  VERSION = '047';
  DESCRIPTION = 'Canais de envio do acesso ao participante';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(
    AConn,
    'ALTER TABLE instituicao_configuracao ' +
    'ADD COLUMN acesso_envio_email TINYINT(1) NOT NULL DEFAULT 0 AFTER cor_texto'
  );

  ExecSQL(
    AConn,
    'ALTER TABLE instituicao_configuracao ' +
    'ADD COLUMN acesso_envio_whatsapp TINYINT(1) NOT NULL DEFAULT 1 AFTER acesso_envio_email'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;


class procedure TCursosMigration.Migration_048_EncontroCheckin(const AConn: TUniConnection);
var Q: TUniQuery;
begin
  if MigrationExists(AConn, '048') then Exit;
  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS encontro_checkin (' +
    'id_instituicao BIGINT UNSIGNED NOT NULL, id_turma BIGINT UNSIGNED NOT NULL, ' +
    'id_encontro BIGINT UNSIGNED NOT NULL, ' +
    'token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL, ' +
    'aberto_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3), ' +
    'expira_em DATETIME(3) NOT NULL, encerrado_em DATETIME(3) NULL, ' +
    'aberto_por BIGINT UNSIGNED NOT NULL, ' +
    'PRIMARY KEY(id_instituicao,id_encontro), UNIQUE KEY uq_checkin_token(token_hash), ' +
    'CONSTRAINT fk_checkin_encontro FOREIGN KEY(id_instituicao,id_turma,id_encontro) ' +
    'REFERENCES turma_encontro(id_instituicao,id_turma,id) ON DELETE CASCADE, ' +
    'CONSTRAINT fk_checkin_usuario FOREIGN KEY(id_instituicao,aberto_por) ' +
    'REFERENCES usuario_instituicao(id_instituicao,id)) ENGINE=InnoDB');
  // DDL auto-commits in MySQL: allow retry after partial execution.
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text := 'SELECT 1 FROM information_schema.columns WHERE table_schema=DATABASE() ' +
      'AND table_name=''presenca'' AND column_name=''origem''';
    Q.Open;
    if Q.IsEmpty then
      ExecSQL(AConn, 'ALTER TABLE presenca ADD COLUMN origem VARCHAR(20) NOT NULL DEFAULT ''LEGADO''');
  finally Q.Free; end;
  RegisterMigration(AConn, '048', 'QR de encontro e auto check-in autenticado');
end;


class procedure TCursosMigration.Migration_049_PlataformaCampanhas(
  const AConn: TUniConnection);
var
  Q: TUniQuery;
begin
  if MigrationExists(AConn, '049') then
    Exit;

  // A configuracao global passa a informar a instancia Evolution usada
  // exclusivamente pelas campanhas do SaaS.
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.columns ' +
      'WHERE table_schema = DATABASE() ' +
      'AND table_name = ''plataforma_whatsapp_configuracao'' ' +
      'AND column_name = ''nome_instancia''';
    Q.Open;
    if Q.IsEmpty then
      ExecSQL(AConn,
        'ALTER TABLE plataforma_whatsapp_configuracao ' +
        'ADD COLUMN nome_instancia VARCHAR(160) NOT NULL DEFAULT '''' AFTER api_url');
  finally
    Q.Free;
  end;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_campanha (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' nome VARCHAR(180) NOT NULL,' +
    ' canal VARCHAR(20) NOT NULL,' +
    ' assunto_email VARCHAR(255) NULL,' +
    ' corpo_email LONGTEXT NULL,' +
    ' mensagem_whatsapp LONGTEXT NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''RASCUNHO'',' +
    ' total_destinatarios INT UNSIGNED NOT NULL DEFAULT 0,' +
    ' total_envios INT UNSIGNED NOT NULL DEFAULT 0,' +
    ' total_enviados INT UNSIGNED NOT NULL DEFAULT 0,' +
    ' total_falhas INT UNSIGNED NOT NULL DEFAULT 0,' +
    ' criado_por BIGINT UNSIGNED NOT NULL,' +
    ' iniciado_em DATETIME(3) NULL,' +
    ' concluido_em DATETIME(3) NULL,' +
    ' cancelado_em DATETIME(3) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' KEY ix_plataforma_campanha_situacao_data (situacao, criado_em),' +
    ' CONSTRAINT fk_plataforma_campanha_usuario FOREIGN KEY (criado_por) REFERENCES usuario(id) ' +
    '   ON UPDATE RESTRICT ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_plataforma_campanha_canal CHECK (canal IN (''EMAIL'',''WHATSAPP'',''AMBOS'')),' +
    ' CONSTRAINT ck_plataforma_campanha_situacao CHECK (situacao IN ' +
    '   (''RASCUNHO'',''PROCESSANDO'',''CONCLUIDA'',''CANCELADA''))' +
    ') ENGINE=InnoDB COMMENT=''Campanhas de comunicacao do administrador SaaS.'';');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_campanha_destinatario (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_campanha BIGINT UNSIGNED NOT NULL,' +
    ' nome VARCHAR(180) NOT NULL,' +
    ' email VARCHAR(254) NULL,' +
    ' whatsapp VARCHAR(30) NULL,' +
    ' empresa VARCHAR(180) NULL,' +
    ' origem VARCHAR(10) NOT NULL DEFAULT ''MANUAL'',' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' KEY ix_campanha_dest_campanha (id_campanha, id),' +
    ' KEY ix_campanha_dest_email (id_campanha, email),' +
    ' KEY ix_campanha_dest_whatsapp (id_campanha, whatsapp),' +
    ' CONSTRAINT fk_campanha_dest_campanha FOREIGN KEY (id_campanha) ' +
    '   REFERENCES plataforma_campanha(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
    ' CONSTRAINT ck_campanha_dest_origem CHECK (origem IN (''MANUAL'',''CSV''))' +
    ') ENGINE=InnoDB COMMENT=''Destinatarios importados ou adicionados manualmente.'';');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_campanha_anexo (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_campanha BIGINT UNSIGNED NOT NULL,' +
    ' nome_original VARCHAR(255) NOT NULL,' +
    ' nome_storage VARCHAR(100) NOT NULL,' +
    ' caminho_storage VARCHAR(1000) NOT NULL,' +
    ' mime_type VARCHAR(120) NOT NULL,' +
    ' tamanho_bytes BIGINT UNSIGNED NOT NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' KEY ix_campanha_anexo_campanha (id_campanha, id),' +
    ' CONSTRAINT fk_campanha_anexo_campanha FOREIGN KEY (id_campanha) ' +
    '   REFERENCES plataforma_campanha(id) ON UPDATE RESTRICT ON DELETE CASCADE' +
    ') ENGINE=InnoDB COMMENT=''Anexos das campanhas SaaS.'';');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_campanha_envio (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_campanha BIGINT UNSIGNED NOT NULL,' +
    ' id_destinatario BIGINT UNSIGNED NOT NULL,' +
    ' canal VARCHAR(20) NOT NULL,' +
    ' destinatario VARCHAR(254) NOT NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''PENDENTE'',' +
    ' tentativas INT UNSIGNED NOT NULL DEFAULT 0,' +
    ' proxima_tentativa_em DATETIME(3) NULL,' +
    ' processando_em DATETIME(3) NULL,' +
    ' enviado_em DATETIME(3) NULL,' +
    ' ultimo_erro VARCHAR(1000) NULL,' +
    ' provider_id VARCHAR(255) NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' UNIQUE KEY uq_campanha_envio_dest_canal (id_campanha, id_destinatario, canal),' +
    ' KEY ix_campanha_envio_fila (situacao, proxima_tentativa_em, id),' +
    ' KEY ix_campanha_envio_campanha (id_campanha, situacao),' +
    ' CONSTRAINT fk_campanha_envio_campanha FOREIGN KEY (id_campanha) ' +
    '   REFERENCES plataforma_campanha(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
    ' CONSTRAINT fk_campanha_envio_dest FOREIGN KEY (id_destinatario) ' +
    '   REFERENCES plataforma_campanha_destinatario(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
    ' CONSTRAINT ck_campanha_envio_canal CHECK (canal IN (''EMAIL'',''WHATSAPP'')),' +
    ' CONSTRAINT ck_campanha_envio_situacao CHECK (situacao IN ' +
    '   (''PENDENTE'',''PROCESSANDO'',''ENVIADO'',''FALHA'',''CANCELADO''))' +
    ') ENGINE=InnoDB COMMENT=''Fila persistente de envios das campanhas SaaS.'';');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plataforma_contato_bloqueio (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' canal VARCHAR(20) NOT NULL,' +
    ' valor VARCHAR(254) NOT NULL,' +
    ' valor_normalizado VARCHAR(254) NOT NULL,' +
    ' motivo VARCHAR(500) NULL,' +
    ' criado_por BIGINT UNSIGNED NOT NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY (id),' +
    ' UNIQUE KEY uq_contato_bloqueio (canal, valor_normalizado),' +
    ' CONSTRAINT fk_contato_bloqueio_usuario FOREIGN KEY (criado_por) REFERENCES usuario(id) ' +
    '   ON UPDATE RESTRICT ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contato_bloqueio_canal CHECK (canal IN (''EMAIL'',''WHATSAPP''))' +
    ') ENGINE=InnoDB COMMENT=''Lista global de supressao de comunicacoes da plataforma.'';');

  RegisterMigration(AConn, '049', 'Campanhas de email e WhatsApp da plataforma SaaS');
end;

{$ENDREGION}

end.
