unit Asmuv.Migration;

interface

uses
  Uni,
  App.Config;

type
  TAsmuvMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;

    class procedure CreateMigrationTable(const AConn: TUniConnection); static;

    class procedure Migration_001_CreateEmpresa(const AConn: TUniConnection); static;
    class procedure Migration_002_CreateUsuario(const AConn: TUniConnection); static;
    class procedure Migration_003_CreateAutorizacao(const AConn: TUniConnection); static;
    class procedure Migration_004_CreateCandidato(const AConn: TUniConnection); static;
    class procedure Migration_005_CreateEleicao(const AConn: TUniConnection); static;
    class procedure Migration_006_CreateChapa(const AConn: TUniConnection); static;
    class procedure Migration_007_CreateSocio(const AConn: TUniConnection); static;
    class procedure Migration_008_CreateVerificaCode(const AConn: TUniConnection); static;
    class procedure Migration_009_CreateConvenio(const AConn: TUniConnection); static;
    class procedure Migration_010_CreateMembro(const AConn: TUniConnection); static;
    class procedure Migration_011_CreateSindicatoDependente(const AConn: TUniConnection); static;
    class procedure Migration_012_CreateCampanha(const AConn: TUniConnection); static;
    class procedure Migration_013_CreateCampanhaHistorico(
      const AConn: TUniConnection); static;
    class procedure Migration_014_CreateCarteira(const AConn: TUniConnection); static;
    class procedure Migration_015_CreateNotificacao(
      const AConn: TUniConnection); static;
    class procedure Migration_016_CreateNotificacaoLida(
      const AConn: TUniConnection); static;
    class procedure Migration_017_CreateSecretaria(const AConn: TUniConnection); static;
    class procedure Migration_018_CreateSindicatoProfissao(
      const AConn: TUniConnection); static;
    class procedure Migration_019_CreateSindicatoRegistro(
      const AConn: TUniConnection); static;
    class procedure Migration_020_CreateVotos(const AConn: TUniConnection); static;


  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
  end;

implementation

uses
  System.SysUtils,
  Database.Connection;

{ TAsmuvMigration }

class procedure TAsmuvMigration.CreateMigrationTable(const AConn: TUniConnection);
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

class procedure TAsmuvMigration.ExecSQL(const AConn: TUniConnection;const ASQL: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := ASQL;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TAsmuvMigration.MigrationExists(const AConn: TUniConnection;
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

class procedure TAsmuvMigration.RegisterMigration(const AConn: TUniConnection;
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

class procedure TAsmuvMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);
  try
    Conn.StartTransaction;
      try

      CreateMigrationTable(Conn);

      Migration_001_CreateEmpresa(Conn);
      Migration_002_CreateUsuario(Conn);
      Migration_003_CreateAutorizacao(Conn);
      Migration_004_CreateCandidato(Conn);
      Migration_005_CreateEleicao(Conn);
      Migration_006_CreateChapa(Conn);
      Migration_007_CreateSocio(Conn);
      Migration_008_CreateVerificaCode(Conn);
      Migration_009_CreateConvenio(Conn);
      Migration_010_CreateMembro(Conn);
      Migration_011_CreateSindicatoDependente(Conn);
      Migration_012_CreateCampanha(Conn);
      Migration_013_CreateCampanhaHistorico(Conn);
      Migration_014_CreateCarteira(Conn);
      Migration_015_CreateNotificacao(Conn);
      Migration_016_CreateNotificacaoLida(Conn);
      Migration_017_CreateSecretaria(Conn);
      Migration_018_CreateSindicatoProfissao(Conn);
      Migration_019_CreateSindicatoRegistro(Conn);
      Migration_020_CreateVotos(Conn);

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;



class procedure TAsmuvMigration.Migration_001_CreateEmpresa(const AConn: TUniConnection);
const
  VERSION = '001';
  DESCRIPTION = 'Criar tabelas empresa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS empresa (          '+
  'id_empresa BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'razao_social VARCHAR(120) NOT NULL,                         '+
  'nome_fantasia VARCHAR(100) DEFAULT NULL,                    '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                         '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_empresa)                                   '+
') ENGINE=InnoDB                                              '+
  'DEFAULT CHARSET=utf8mb4                                    '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_002_CreateUsuario(const AConn: TUniConnection);
const
  VERSION = '002';
  DESCRIPTION = 'Criar tabela usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario (          '+
  'id_usuario BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'id_empresa BIGINT DEFAULT NULL,                             '+
  'nome VARCHAR(60) NOT NULL,                                  '+
  'login VARCHAR(45) NOT NULL,                                 '+
  'senha VARCHAR(250) NOT NULL,                                '+
  'email VARCHAR(180) DEFAULT NULL,                            '+
  'ativo CHAR(1) NOT NULL DEFAULT ''N'',                       '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,   '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_usuario),                                   '+
  'KEY fk_usuario_empresa_idx (id_empresa),                    '+
  'UNIQUE KEY uk_usuario_login (login),                        '+
  'CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa)      '+
  'REFERENCES empresa (id_empresa)                             '+
') ENGINE=InnoDB                                               '+
  'DEFAULT CHARSET=utf8mb4                                     '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_003_CreateAutorizacao(const AConn: TUniConnection);
const
  VERSION = '003';
  DESCRIPTION = 'Criar tabela autorizacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS autorizacao (       '+
  'id_autorizacao BIGINT NOT NULL AUTO_INCREMENT,               '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'data_autorizacao DATETIME DEFAULT NULL,                      '+
  'nome VARCHAR(190) DEFAULT NULL,                              '+
  'qtde_pessoa INT DEFAULT NULL,                                '+
  'observacao VARCHAR(500) DEFAULT NULL,                        '+
  'pessoa_autorizou VARCHAR(50) DEFAULT NULL,                   '+
  'status CHAR(1) NOT NULL DEFAULT ''A'',                       '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_autorizacao),                                '+
  'KEY fk_autorizacao_empresa_idx (id_empresa),                 '+
  'CONSTRAINT fk_autorizacao_empresa FOREIGN KEY (id_empresa)   '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_004_CreateCandidato(const AConn: TUniConnection);
const
  VERSION = '004';
  DESCRIPTION = 'Criar tabela candidato';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS candidato (         '+
  'id_candidato BIGINT NOT NULL AUTO_INCREMENT,                 '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'codigo INT DEFAULT NULL,                                     '+
  'nome VARCHAR(90) DEFAULT NULL,                               '+
  'cargo VARCHAR(60) DEFAULT NULL,                              '+
  'cpf VARCHAR(18) DEFAULT NULL,                                '+
  'descricao VARCHAR(250) DEFAULT NULL,                         '+
  'foto LONGBLOB DEFAULT NULL,                                  '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_candidato),                                  '+
  'KEY fk_candidato_empresa_idx (id_empresa),                   '+
  'KEY idx_candidato_codigo (codigo),                           '+
  'CONSTRAINT fk_candidato_empresa FOREIGN KEY (id_empresa)     '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_005_CreateEleicao(const AConn: TUniConnection);
const
  VERSION = '005';
  DESCRIPTION = 'Criar tabela eleicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS eleicao (           '+
  'id_eleicao BIGINT NOT NULL AUTO_INCREMENT,                   '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'codigo INT DEFAULT NULL,                                     '+
  'nome VARCHAR(90) NOT NULL,                                   '+
  'descricao VARCHAR(500) DEFAULT NULL,                         '+
  'ano INT DEFAULT NULL,                                        '+
  'data_cadastro DATE DEFAULT NULL,                             '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+
  'tipo CHAR(1) NOT NULL DEFAULT ''E'' COMMENT ''E=Eleicao, A=Assembleia'', '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_eleicao),                                    '+
  'KEY fk_eleicao_empresa_idx (id_empresa),                     '+
  'KEY idx_eleicao_codigo (codigo),                             '+
  'KEY idx_eleicao_tipo (tipo),                                 '+
  'CONSTRAINT fk_eleicao_empresa FOREIGN KEY (id_empresa)       '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_006_CreateChapa(const AConn: TUniConnection);
const
  VERSION = '006';
  DESCRIPTION = 'Criar tabela chapa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS chapa (             '+
  'id_chapa BIGINT NOT NULL AUTO_INCREMENT,                     '+
  'id_empresa BIGINT NOT NULL,                                  '+
  'id_eleicao BIGINT NOT NULL,                                  '+
  'id_candidato BIGINT DEFAULT NULL,                            '+
  'codigo INT DEFAULT NULL,                                     '+
  'nome VARCHAR(90) NOT NULL,                                   '+
  'descricao VARCHAR(250) DEFAULT NULL,                         '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+
  'exibir CHAR(1) NOT NULL DEFAULT ''S'',                       '+
  'data_cadastro DATE DEFAULT NULL,                             '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_chapa),                                      '+
  'KEY fk_chapa_empresa_idx (id_empresa),                       '+
  'KEY fk_chapa_eleicao_idx (id_eleicao),                       '+
  'KEY fk_chapa_candidato_idx (id_candidato),                   '+
  'KEY idx_chapa_codigo (codigo),                               '+
  'CONSTRAINT fk_chapa_empresa FOREIGN KEY (id_empresa)         '+
  'REFERENCES empresa (id_empresa),                             '+
  'CONSTRAINT fk_chapa_eleicao FOREIGN KEY (id_eleicao)         '+
  'REFERENCES eleicao (id_eleicao),                             '+
  'CONSTRAINT fk_chapa_candidato FOREIGN KEY (id_candidato)     '+
  'REFERENCES candidato (id_candidato)                          '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_007_CreateSocio(const AConn: TUniConnection);
const
  VERSION = '007';
  DESCRIPTION = 'Criar tabela socio';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS socio (             '+
  'id_socio BIGINT NOT NULL AUTO_INCREMENT,                     '+
  'id_empresa BIGINT NOT NULL,                                  '+

  'codigo INT DEFAULT NULL,                                     '+
  'matricula INT DEFAULT NULL,                                  '+
  'data_associacao DATE DEFAULT NULL,                           '+
  'situacao VARCHAR(45) DEFAULT NULL,                           '+
  'nome VARCHAR(150) NOT NULL,                                  '+
  'apelido VARCHAR(60) DEFAULT NULL,                            '+

  'cpf VARCHAR(18) DEFAULT NULL,                                '+
  'rg VARCHAR(20) DEFAULT NULL,                                 '+
  'orgao VARCHAR(15) DEFAULT NULL,                              '+
  'ctps VARCHAR(15) DEFAULT NULL,                               '+
  'serie VARCHAR(10) DEFAULT NULL,                              '+
  'pis VARCHAR(15) DEFAULT NULL,                                '+
  'sexo VARCHAR(20) DEFAULT NULL,                               '+
  'estado_civil VARCHAR(20) DEFAULT NULL,                       '+
  'data_nascimento DATE DEFAULT NULL,                           '+

  'email VARCHAR(180) DEFAULT NULL,                             '+
  'pai VARCHAR(90) DEFAULT NULL,                                '+
  'mae VARCHAR(90) DEFAULT NULL,                                '+
  'profissao VARCHAR(60) DEFAULT NULL,                          '+
  'data_admissao DATE DEFAULT NULL,                             '+

  'observacao VARCHAR(250) DEFAULT NULL,                        '+
  'foto LONGBLOB DEFAULT NULL,                                  '+
  'escritorio INT DEFAULT NULL,                                 '+
  'mostrar_app CHAR(1) NOT NULL DEFAULT ''S'',                  '+
  'bloqueado CHAR(1) NOT NULL DEFAULT ''N'',                    '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_socio),                                      '+
  'KEY fk_socio_empresa_idx (id_empresa),                       '+
  'KEY idx_socio_codigo (codigo),                               '+
  'KEY idx_socio_matricula (matricula),                         '+
  'KEY idx_socio_cpf (cpf),                                     '+
  'KEY idx_socio_nome (nome),                                   '+
  'CONSTRAINT fk_socio_empresa FOREIGN KEY (id_empresa)         '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_008_CreateVerificaCode(const AConn: TUniConnection);
const
  VERSION = '008';
  DESCRIPTION = 'Criar tabela verifica_code';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS verifica_code (     '+
  'id_verifica_code BIGINT NOT NULL AUTO_INCREMENT,             '+
  'id_socio BIGINT DEFAULT NULL,                                '+
  'codigo VARCHAR(10) DEFAULT NULL,                             '+
  'data_expiracao DATETIME DEFAULT NULL,                        '+
  'utilizado CHAR(1) NOT NULL DEFAULT ''N'',                    '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_verifica_code),                              '+
  'KEY fk_verifica_code_socio_idx (id_socio),                   '+
  'KEY idx_verifica_code_codigo (codigo),                       '+
  'KEY idx_verifica_code_expiracao (data_expiracao),            '+
  'CONSTRAINT fk_verifica_code_socio FOREIGN KEY (id_socio)     '+
  'REFERENCES socio (id_socio)                                  '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_009_CreateConvenio(const AConn: TUniConnection);
const
  VERSION = '009';
  DESCRIPTION = 'Criar tabela convenio';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS convenio (          '+
  'id_convenio BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'codigo INT NOT NULL,                                         '+
  'nome VARCHAR(90) NOT NULL,                                   '+
  'tipo VARCHAR(45) NOT NULL,                                   '+
  'termos VARCHAR(250) DEFAULT NULL,                            '+
  'informacao_contrato VARCHAR(500) DEFAULT NULL,               '+
  'valor DECIMAL(15,2) DEFAULT NULL,                            '+
  'telefone VARCHAR(20) DEFAULT NULL,                           '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_convenio),                                   '+
  'KEY fk_convenio_empresa_idx (id_empresa),                    '+
  'KEY idx_convenio_codigo (codigo),                            '+
  'KEY idx_convenio_nome (nome),                                '+
  'KEY idx_convenio_tipo (tipo),                                '+
  'CONSTRAINT fk_convenio_empresa FOREIGN KEY (id_empresa)      '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_010_CreateMembro(const AConn: TUniConnection);
const
  VERSION = '010';
  DESCRIPTION = 'Criar tabela membro';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS membro (            '+
  'id_membro BIGINT NOT NULL AUTO_INCREMENT,                    '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'id_usuario BIGINT DEFAULT NULL,                              '+
  'id_eleicao BIGINT DEFAULT NULL,                              '+
  'codigo INT DEFAULT NULL,                                     '+
  'nome VARCHAR(90) DEFAULT NULL,                               '+
  'cpf VARCHAR(18) DEFAULT NULL,                                '+
  'whatsapp VARCHAR(20) DEFAULT NULL,                           '+
  'email VARCHAR(190) DEFAULT NULL,                             '+
  'chave_key VARCHAR(250) DEFAULT NULL,                         '+
  'foto LONGBLOB DEFAULT NULL,                                  '+
  'presidente CHAR(1) NOT NULL DEFAULT ''N'',                   '+
  'secretaria CHAR(1) NOT NULL DEFAULT ''N'',                   '+
  'mesario CHAR(1) NOT NULL DEFAULT ''N'',                      '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_membro),                                     '+
  'KEY fk_membro_empresa_idx (id_empresa),                      '+
  'KEY fk_membro_usuario_idx (id_usuario),                      '+
  'KEY fk_membro_eleicao_idx (id_eleicao),                      '+
  'KEY idx_membro_codigo (codigo),                              '+
  'KEY idx_membro_cpf (cpf),                                    '+
  'KEY idx_membro_nome (nome),                                  '+
  'CONSTRAINT fk_membro_empresa FOREIGN KEY (id_empresa)        '+
  'REFERENCES empresa (id_empresa),                             '+
  'CONSTRAINT fk_membro_usuario FOREIGN KEY (id_usuario)        '+
  'REFERENCES usuario (id_usuario),                             '+
  'CONSTRAINT fk_membro_eleicao FOREIGN KEY (id_eleicao)        '+
  'REFERENCES eleicao (id_eleicao)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_011_CreateSindicatoDependente(const AConn: TUniConnection);
const
  VERSION = '011';
  DESCRIPTION = 'Criar tabela sindicato_dependente';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS sindicato_dependente ( '+
  'id_dependente BIGINT NOT NULL AUTO_INCREMENT,                   '+
  'id_empresa BIGINT DEFAULT NULL,                                 '+
  'id_socio BIGINT NOT NULL,                                       '+
  'codigo INT DEFAULT NULL,                                        '+
  'nome VARCHAR(190) NOT NULL,                                     '+
  'data_nascimento DATE DEFAULT NULL,                              '+
  'parentesco VARCHAR(40) NOT NULL,                                '+
  'cpf VARCHAR(20) DEFAULT NULL,                                   '+
  'rg VARCHAR(20) DEFAULT NULL,                                    '+
  'sexo VARCHAR(10) DEFAULT NULL,                                  '+
  'foto LONGBLOB DEFAULT NULL,                                     '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                           '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,       '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_dependente),                                    '+
  'KEY fk_dependente_empresa_idx (id_empresa),                     '+
  'KEY fk_dependente_socio_idx (id_socio),                         '+
  'KEY idx_dependente_codigo (codigo),                             '+
  'KEY idx_dependente_cpf (cpf),                                   '+
  'KEY idx_dependente_nome (nome),                                 '+
  'CONSTRAINT fk_dependente_empresa FOREIGN KEY (id_empresa)       '+
  'REFERENCES empresa (id_empresa),                                '+
  'CONSTRAINT fk_dependente_socio FOREIGN KEY (id_socio)           '+
  'REFERENCES socio (id_socio)                                     '+
') ENGINE=InnoDB                                                   '+
  'DEFAULT CHARSET=utf8mb4                                         '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_012_CreateCampanha(const AConn: TUniConnection);
const
  VERSION = '012';
  DESCRIPTION = 'Criar tabela campanha';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS campanha (          '+
  'id_campanha BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'id_empresa BIGINT NOT NULL,                                  '+
  'id_eleicao BIGINT NOT NULL,                                  '+
  'codigo INT NOT NULL,                                         '+

  'data_inicio DATE NOT NULL,                                   '+
  'hora_inicio TIME NOT NULL,                                   '+
  'data_final DATE NOT NULL,                                    '+
  'hora_final TIME NOT NULL,                                    '+

  'detalhes VARCHAR(500) DEFAULT NULL,                          '+
  'publicada CHAR(1) NOT NULL DEFAULT ''N'',                    '+
  'concluida CHAR(1) NOT NULL DEFAULT ''N'',                    '+
  'auditoria CHAR(1) NOT NULL DEFAULT ''N'',                    '+
  'fechamento_automatico CHAR(1) NOT NULL DEFAULT ''N'',        '+

  'token VARCHAR(250) DEFAULT NULL,                             '+
  'chave_key VARCHAR(250) DEFAULT NULL,                         '+
  'chave_key_alt VARCHAR(250) DEFAULT NULL,                     '+
  'chave_key_publicar VARCHAR(250) DEFAULT NULL,                '+
  'chave_key_despublicar VARCHAR(250) DEFAULT NULL,             '+
  'chave_key_encerramento VARCHAR(250) DEFAULT NULL,            '+

  'data_hora_publicacao DATETIME DEFAULT NULL,                  '+
  'data_hora_fechamento DATETIME DEFAULT NULL,                  '+
  'data_hora_despublicacao DATETIME DEFAULT NULL,               '+

  'anexo LONGBLOB DEFAULT NULL,                                 '+
  'anexo_formato VARCHAR(10) DEFAULT NULL,                      '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_campanha),                                   '+
  'KEY fk_campanha_empresa_idx (id_empresa),                    '+
  'KEY fk_campanha_eleicao_idx (id_eleicao),                    '+
  'KEY idx_campanha_codigo (codigo),                            '+
  'KEY idx_campanha_publicada (publicada),                      '+
  'KEY idx_campanha_concluida (concluida),                      '+
  'KEY idx_campanha_periodo (data_inicio, data_final),          '+
  'CONSTRAINT fk_campanha_empresa FOREIGN KEY (id_empresa)      '+
  'REFERENCES empresa (id_empresa),                             '+
  'CONSTRAINT fk_campanha_eleicao FOREIGN KEY (id_eleicao)      '+
  'REFERENCES eleicao (id_eleicao)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_013_CreateCampanhaHistorico(const AConn: TUniConnection);
const
  VERSION = '013';
  DESCRIPTION = 'Criar tabela campanha_historico';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS campanha_historico ( '+
  'id_historico BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'id_campanha BIGINT DEFAULT NULL,                              '+
  'id_membro BIGINT NOT NULL,                                    '+
  'cpf_confirmacao VARCHAR(20) NOT NULL,                         '+
  'data_confirmacao DATE DEFAULT NULL,                           '+
  'hora_confirmacao TIME DEFAULT NULL,                           '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,     '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_historico),                                   '+
  'KEY fk_campanha_historico_campanha_idx (id_campanha),         '+
  'KEY fk_campanha_historico_membro_idx (id_membro),             '+
  'KEY idx_campanha_historico_cpf (cpf_confirmacao),             '+
  'KEY idx_campanha_historico_data (data_confirmacao),           '+
  'CONSTRAINT fk_campanha_historico_campanha FOREIGN KEY (id_campanha) '+
  'REFERENCES campanha (id_campanha),                            '+
  'CONSTRAINT fk_campanha_historico_membro FOREIGN KEY (id_membro) '+
  'REFERENCES membro (id_membro)                                 '+
') ENGINE=InnoDB                                                 '+
  'DEFAULT CHARSET=utf8mb4                                       '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_014_CreateCarteira(const AConn: TUniConnection);
const
  VERSION = '014';
  DESCRIPTION = 'Criar tabela carteira';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS carteira (          '+
  'id_carteira BIGINT NOT NULL AUTO_INCREMENT,                  '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'id_socio BIGINT NOT NULL,                                    '+
  'id_dependente BIGINT DEFAULT NULL,                           '+

  'data_validade DATE DEFAULT NULL,                             '+
  'data_emissao DATE DEFAULT NULL,                              '+

  'ativo CHAR(1) NOT NULL DEFAULT ''N'',                        '+
  'impresso_dependente CHAR(1) NOT NULL DEFAULT ''N'',          '+
  'digital CHAR(1) NOT NULL DEFAULT ''N'',                      '+
  'api CHAR(1) NOT NULL DEFAULT ''N'',                          '+

  'login VARCHAR(20) DEFAULT NULL,                              '+
  'nome_usuario VARCHAR(90) DEFAULT NULL,                       '+
  'senha VARCHAR(250) DEFAULT NULL,                             '+
  'token VARCHAR(500) DEFAULT NULL,                             '+
  'token_device VARCHAR(500) DEFAULT NULL,                      '+
  'qrcode LONGBLOB DEFAULT NULL,                                '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_carteira),                                   '+
  'KEY fk_carteira_empresa_idx (id_empresa),                    '+
  'KEY fk_carteira_socio_idx (id_socio),                        '+
  'KEY fk_carteira_dependente_idx (id_dependente),              '+
  'KEY idx_carteira_login (login),                              '+
  'KEY idx_carteira_validade (data_validade),                   '+
  'CONSTRAINT fk_carteira_empresa FOREIGN KEY (id_empresa)      '+
  'REFERENCES empresa (id_empresa),                             '+
  'CONSTRAINT fk_carteira_socio FOREIGN KEY (id_socio)          '+
  'REFERENCES socio (id_socio),                                 '+
  'CONSTRAINT fk_carteira_dependente FOREIGN KEY (id_dependente) '+
  'REFERENCES sindicato_dependente (id_dependente)              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_015_CreateNotificacao(const AConn: TUniConnection);
const
  VERSION = '015';
  DESCRIPTION = 'Criar tabela notificacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS notificacao (       '+
  'id_notificacao BIGINT NOT NULL AUTO_INCREMENT,               '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'id_socio BIGINT DEFAULT NULL,                                '+

  'tipo INT NOT NULL,                                           '+
  'titulo VARCHAR(90) NOT NULL,                                 '+
  'mensagem VARCHAR(1500) NOT NULL,                             '+

  'data_criacao_notificacao DATE DEFAULT NULL,                  '+
  'hora_criacao_notificacao TIME DEFAULT NULL,                  '+
  'data_envio DATE DEFAULT NULL,                                '+
  'hora_envio TIME DEFAULT NULL,                                '+
  'retorno_envio VARCHAR(250) DEFAULT NULL,                     '+

  'publico CHAR(1) NOT NULL DEFAULT ''N'',                      '+
  'foto LONGBLOB DEFAULT NULL,                                  '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_notificacao),                                '+
  'KEY fk_notificacao_empresa_idx (id_empresa),                 '+
  'KEY fk_notificacao_socio_idx (id_socio),                     '+
  'KEY idx_notificacao_tipo (tipo),                             '+
  'KEY idx_notificacao_publico (publico),                       '+
  'KEY idx_notificacao_envio (data_envio, hora_envio),          '+
  'CONSTRAINT fk_notificacao_empresa FOREIGN KEY (id_empresa)   '+
  'REFERENCES empresa (id_empresa),                             '+
  'CONSTRAINT fk_notificacao_socio FOREIGN KEY (id_socio)       '+
  'REFERENCES socio (id_socio)                                  '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_016_CreateNotificacaoLida(const AConn: TUniConnection);
const
  VERSION = '016';
  DESCRIPTION = 'Criar tabela notificacao_lida';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS notificacao_lida (  '+
  'id_notificacao_lida BIGINT NOT NULL AUTO_INCREMENT,          '+
  'id_notificacao BIGINT DEFAULT NULL,                          '+
  'id_carteira BIGINT DEFAULT NULL,                             '+
  'data_leitura DATE DEFAULT NULL,                              '+
  'hora_leitura TIME DEFAULT NULL,                              '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_notificacao_lida),                           '+
  'KEY fk_notificacao_lida_notificacao_idx (id_notificacao),    '+
  'KEY fk_notificacao_lida_carteira_idx (id_carteira),          '+
  'KEY idx_notificacao_lida_data (data_leitura),                '+
  'CONSTRAINT fk_notificacao_lida_notificacao FOREIGN KEY (id_notificacao) '+
  'REFERENCES notificacao (id_notificacao),                     '+
  'CONSTRAINT fk_notificacao_lida_carteira FOREIGN KEY (id_carteira) '+
  'REFERENCES carteira (id_carteira)                            '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_017_CreateSecretaria(const AConn: TUniConnection);
const
  VERSION = '017';
  DESCRIPTION = 'Criar tabela secretaria';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS secretaria (        '+
  'id_secretaria BIGINT NOT NULL AUTO_INCREMENT,                '+
  'id_empresa BIGINT DEFAULT NULL,                              '+
  'codigo INT DEFAULT NULL,                                     '+
  'razao_social VARCHAR(120) NOT NULL,                          '+
  'nome_fantasia VARCHAR(120) DEFAULT NULL,                     '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                        '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_secretaria),                                 '+
  'KEY fk_secretaria_empresa_idx (id_empresa),                  '+
  'KEY idx_secretaria_codigo (codigo),                          '+
  'KEY idx_secretaria_razao_social (razao_social),              '+
  'CONSTRAINT fk_secretaria_empresa FOREIGN KEY (id_empresa)    '+
  'REFERENCES empresa (id_empresa)                              '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_018_CreateSindicatoProfissao(const AConn: TUniConnection);
const
  VERSION = '018';
  DESCRIPTION = 'Criar tabela sindicato_profissao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS sindicato_profissao ( '+
  'id_profissao BIGINT NOT NULL AUTO_INCREMENT,                   '+
  'id_empresa BIGINT DEFAULT NULL,                                '+
  'codigo INT DEFAULT NULL,                                       '+
  'descricao VARCHAR(190) NOT NULL,                               '+
  'ativo CHAR(1) NOT NULL DEFAULT ''S'',                          '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,      '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_profissao),                                    '+
  'KEY fk_profissao_empresa_idx (id_empresa),                     '+
  'KEY idx_profissao_codigo (codigo),                             '+
  'KEY idx_profissao_descricao (descricao),                       '+
  'CONSTRAINT fk_profissao_empresa FOREIGN KEY (id_empresa)       '+
  'REFERENCES empresa (id_empresa)                                '+
') ENGINE=InnoDB                                                  '+
  'DEFAULT CHARSET=utf8mb4                                        '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_019_CreateSindicatoRegistro(const AConn: TUniConnection);
const
  VERSION = '019';
  DESCRIPTION = 'Criar tabela sindicato_registro';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS sindicato_registro ( '+
  'id_registro BIGINT NOT NULL AUTO_INCREMENT,                   '+
  'id_carteira BIGINT NOT NULL,                                  '+
  'data_registro DATE DEFAULT NULL,                              '+
  'hora_registro TIME DEFAULT NULL,                              '+
  'observacao VARCHAR(250) DEFAULT NULL,                         '+
  'sincronizado CHAR(1) NOT NULL DEFAULT ''N'',                  '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,     '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_registro),                                    '+
  'KEY fk_registro_carteira_idx (id_carteira),                   '+
  'KEY idx_registro_data (data_registro),                        '+
  'KEY idx_registro_sincronizado (sincronizado),                 '+
  'CONSTRAINT fk_registro_carteira FOREIGN KEY (id_carteira)     '+
  'REFERENCES carteira (id_carteira)                             '+
') ENGINE=InnoDB                                                 '+
  'DEFAULT CHARSET=utf8mb4                                       '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TAsmuvMigration.Migration_020_CreateVotos(const AConn: TUniConnection);
const
  VERSION = '020';
  DESCRIPTION = 'Criar tabela votos';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS votos (             '+
  'id_voto BIGINT NOT NULL AUTO_INCREMENT,                      '+
  'id_socio BIGINT NOT NULL,                                    '+
  'id_eleicao BIGINT DEFAULT NULL,                              '+
  'id_campanha BIGINT DEFAULT NULL,                             '+
  'token VARCHAR(250) NOT NULL,                                 '+
  'voto INT NOT NULL,                                           '+
  'chave VARCHAR(250) DEFAULT NULL,                             '+
  'data_voto DATE DEFAULT NULL,                                 '+
  'hora_voto TIME DEFAULT NULL,                                 '+
  'ip VARCHAR(45) DEFAULT NULL,                                 '+
  'ordem INT DEFAULT NULL,                                      '+

  'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
  'data_alteracao DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+

  'PRIMARY KEY (id_voto),                                       '+
  'KEY fk_votos_socio_idx (id_socio),                           '+
  'KEY fk_votos_eleicao_idx (id_eleicao),                       '+
  'KEY fk_votos_campanha_idx (id_campanha),                     '+
  'KEY idx_votos_token (token),                                 '+
  'KEY idx_votos_data (data_voto),                              '+
  'KEY idx_votos_ordem (ordem),                                 '+
  'CONSTRAINT fk_votos_socio FOREIGN KEY (id_socio)             '+
  'REFERENCES socio (id_socio),                                 '+
  'CONSTRAINT fk_votos_eleicao FOREIGN KEY (id_eleicao)         '+
  'REFERENCES eleicao (id_eleicao),                             '+
  'CONSTRAINT fk_votos_campanha FOREIGN KEY (id_campanha)       '+
  'REFERENCES campanha (id_campanha)                            '+
') ENGINE=InnoDB                                                '+
  'DEFAULT CHARSET=utf8mb4                                      '+
  'COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

end.




