unit Eleicao.Migration;

interface

uses
  Uni,
  App.Config;

type
  TEleicaoMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;

    class procedure CreateMigrationTable(const AConn: TUniConnection); static;

    class procedure Migration_001_CreateEleicao(const AConn: TUniConnection); static;
    class procedure Migration_002_CreateEleicaoConfig(const AConn: TUniConnection); static;
    class procedure Migration_003_CreateEleicaoChapa(const AConn: TUniConnection); static;
    class procedure Migration_004_CreateEleicaoChapaMembros(const AConn: TUniConnection); static;
    class procedure Migration_005_CreateEleicaoConfirmacao(const AConn: TUniConnection);static;
    class procedure Migration_006_CreateEleicaoVotante(const AConn: TUniConnection);static;
    class procedure Migration_007_CreateEleicaoVoto(const AConn: TUniConnection);static;
    class procedure Migration_008_Createeleicao_auditoria(const AConn: TUniConnection);static;
    class procedure Migration_009_CreateEleicao_RateLimit(const AConn: TUniConnection);static;
    class procedure Migration_010_AlterEleicaoConfirmacao(const AConn: TUniConnection);static;
    class procedure Migration_011_AlterEleicaoConfirmacao(const AConn: TUniConnection);static;
    class procedure Migration_012_CreateEleicaoQuestao(const AConn: TUniConnection);static;
    class procedure Migration_013_CreateEleicaoQuestaoOpcao(const AConn: TUniConnection);static;
    class procedure Migration_014_CreateEleicaoComissao(const AConn: TUniConnection);static;
  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
end;

implementation

uses
  System.SysUtils,
  Database.Connection;

{ TEleicaoMigration }

{$REGION 'Padrao'}

class procedure TEleicaoMigration.CreateMigrationTable(const AConn: TUniConnection);
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

class procedure TEleicaoMigration.ExecSQL(const AConn: TUniConnection;const ASQL: string);
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

class function TEleicaoMigration.MigrationExists(const AConn: TUniConnection;const AVersion: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      ' FROM schema_migrations ' +
      ' WHERE version = :version';

    Qry.ParamByName('version').AsString := AVersion;
    Qry.Open;

    Result      := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoMigration.RegisterMigration(const AConn: TUniConnection;const AVersion, ADescription: string);
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

class procedure TEleicaoMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);

  try
    Conn.StartTransaction;
      try

      CreateMigrationTable(Conn);

      Migration_001_CreateEleicao(Conn);
      Migration_002_CreateEleicaoConfig(Conn);
      Migration_003_CreateEleicaoChapa(Conn);
      Migration_004_CreateEleicaoChapaMembros(Conn);
      Migration_005_CreateEleicaoConfirmacao(Conn);
      Migration_006_CreateEleicaoVotante(Conn);
      Migration_007_CreateEleicaoVoto(Conn);
      Migration_008_Createeleicao_auditoria(Conn);
      Migration_009_CreateEleicao_RateLimit(Conn);
      Migration_010_AlterEleicaoConfirmacao(Conn);
      Migration_011_AlterEleicaoConfirmacao(Conn);
      Migration_012_CreateEleicaoQuestao(Conn);
      Migration_013_CreateEleicaoQuestaoOpcao(Conn);
      Migration_014_CreateEleicaoComissao(Conn);
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

{$REGION 'Create'}



class procedure TEleicaoMigration.Migration_001_CreateEleicao(const AConn: TUniConnection);
const
  VERSION = '001_E';
  DESCRIPTION = 'Criar tabela Eleicao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS eleicao (                          '+
                '`id` INT NOT NULL AUTO_INCREMENT,                            '+
                '`empresa_id` INT NOT NULL,                                   '+
                '`id_eleicao_int` INT NOT NULL,                               '+
                '`codigo` INT NULL,                                           '+
                '`nome` VARCHAR(150) NULL,                                    '+
                '`descricao` VARCHAR(150) NULL,                               '+
                '`ano` INT NULL,                                              '+
                '`ativo` CHAR(1) NULL DEFAULT ''N'',                          '+
                '`ano_fim` INT NULL,                                          '+
                '`tipo` VARCHAR(45) NULL,                                     '+
                '`situacao` VARCHAR(45) NULL,                                 '+
                '`operacao` VARCHAR(45) NULL,                                 '+
                'PRIMARY KEY (`id`),                                          '+
                'INDEX `fk_eleicao_empresa1_idx` (`empresa_id`),              '+
                'UNIQUE KEY `uk_eleicao_empresa_nome` (`empresa_id`,`nome`),  '+
                'UNIQUE KEY `uk_eleicao_empresa_idint` (`empresa_id`,`id_eleicao_int`), '+
                'CONSTRAINT `fk_eleicao_empresa1`                             '+
                'FOREIGN KEY (`empresa_id`)                                   '+
                'REFERENCES `empresa` (`id`)                                  '+
                'ON DELETE NO ACTION                                          '+
                'ON UPDATE NO ACTION                                          '+
                ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_002_CreateEleicaoConfig(const AConn: TUniConnection);
const
  VERSION = '002_E';
  DESCRIPTION = 'Criar tabela eleicao_configuracao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_configuracao` (           '+
                            '`id` INT NOT NULL AUTO_INCREMENT,                 '+
                            '`empresa_id` INT NOT NULL,                        '+
                            '`eleicao_id` INT NOT NULL,                        '+
                            '`id_config` INT NOT NULL,                         '+
                            '`slug` VARCHAR(60) NOT NULL,                      '+
                            '`nome_exibicao` VARCHAR(150) NOT NULL,            '+
                            '`logo` LONGBLOB NULL,                             '+
                            '`banner` LONGBLOB NULL,                           '+
                            '`mensagem_boas_vindas` VARCHAR(500) NULL,         '+
                            '`url_publica` VARCHAR(80) NOT NULL,               '+
                            '`email` VARCHAR(150) NULL,                        '+
                            '`telefone` VARCHAR(20) NULL,                      '+
                            '`cor_primaria` VARCHAR(25) NULL,                  '+
                            '`cor_secundaria` VARCHAR(25) NULL,                '+
                            '`url_instagram` VARCHAR(100) NULL,                '+
                            '`url_facebook` VARCHAR(100) NULL,                 '+
                            '`url_youtube` VARCHAR(100) NULL,                  '+
                            '`pagina_publicar` CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            '`data_hora_inicio` datetime DEFAULT NULL,          '+
                            '`data_hora_fim` datetime DEFAULT NULL,             '+
                            '`abertura_automatica` char(1) NOT NULL DEFAULT ''N'', '+
                            '`encerramento_automatico` char(1) NOT NULL DEFAULT ''N'', '+
                            'votacao_secreta  CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            'exibir_resultado_parcial CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            'publicacao_resultado CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            'controlar_quorum CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            'tipo_quorum varchar(20) NOT NULL DEFAULT ''PERCENTUAL'' '+
                            'quorum_minimo int NOT NULL DEFAULT 0'+
                            'quorum_percentual decimal(5,2) NOT NULL DEFAULT 0.00'+
                            'quorum_base  varchar(30) NOT NULL DEFAULT ''APTOS'',  '+
                            'controlar_presenca CHAR(1) NOT NULL DEFAULT ''N'',  '+
                            'exigir_presenca_votacao  CHAR(1) NOT NULL DEFAULT ''N'',  '+

                            'PRIMARY KEY (`id`),                               '+

                            'INDEX `idx_eleicao_configuracao_empresa` (`empresa_id`), '+
                            'INDEX `idx_eleicao_configuracao_eleicao` (`eleicao_id`), '+

                            'UNIQUE KEY `uk_eleicao_config_empresa_idconfig` '+
                            '  (`empresa_id`, `id_config`),                  '+

                            'CONSTRAINT `fk_eleicao_configuracao_empresa`   '+
                            '  FOREIGN KEY (`empresa_id`)                    '+
                            '  REFERENCES `empresa` (`id`)                   '+
                            '  ON DELETE NO ACTION                          '+
                            '  ON UPDATE NO ACTION,                         '+

                            'CONSTRAINT `fk_eleicao_configuracao_eleicao`   '+
                            '  FOREIGN KEY (`eleicao_id`)                   '+
                            '  REFERENCES `eleicao` (`id`)                  '+
                            '  ON DELETE NO ACTION                          '+
                            '  ON UPDATE NO ACTION                          '+

                            ') ENGINE=InnoDB                                '+
                            'DEFAULT CHARSET=utf8mb4                        '+
                            'COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_003_CreateEleicaoChapa(const AConn: TUniConnection);
const
  VERSION = '003_E';
  DESCRIPTION = 'Criar tabela eleicao_chapa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_chapa` (    '+
                '`id` INT NOT NULL AUTO_INCREMENT,                          '+
                '`empresa_id` INT NOT NULL,                                 '+
                '`eleicao_id` INT NOT NULL,                                 '+
                '`id_chapa_int` INT NOT NULL,                               '+
                '`codigo` INT NULL,                                         '+
                '`situacao` VARCHAR(45) NOT NULL,                           '+
                '`num_chapa` INT NOT NULL,                                  '+
                '`nome_chapa` VARCHAR(200) NOT NULL,                        '+
                '`slogan` VARCHAR(200) NULL,                                '+
                '`obs` VARCHAR(500) NULL,                                   '+
                '`ativo` CHAR(1) NOT NULL DEFAULT ''N'',                    '+
                'PRIMARY KEY (`id`),                                        '+
                'INDEX `idx_eleicao_chapa_empresa` (`empresa_id`),          '+
                'INDEX `idx_eleicao_chapa_eleicao` (`eleicao_id`),          '+
                'UNIQUE KEY `uk_eleicao_chapa_codigo`                       '+
                '  (`empresa_id`, `eleicao_id`, `codigo`),                  '+
                'UNIQUE KEY `uk_eleicao_chapa_numero`                       '+
                '(`empresa_id`, `eleicao_id`, `num_chapa`),                 '+
                'CONSTRAINT `fk_eleicao_chapa_empresa`                      '+
                'FOREIGN KEY (`empresa_id`)                                 '+
                'REFERENCES `empresa` (`id`)                     '+
                'ON DELETE NO ACTION                                        '+
                'ON UPDATE NO ACTION,                                       '+
                'CONSTRAINT `fk_eleicao_chapa_eleicao`                      '+
                'FOREIGN KEY (`eleicao_id`)                                 '+
                'REFERENCES `eleicao` (`id`)                     '+
                'ON DELETE NO ACTION                                        '+
                'ON UPDATE NO ACTION                                        '+
                ') ENGINE=InnoDB                                            '+
                'DEFAULT CHARSET=utf8mb4                                    '+
                'COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_004_CreateEleicaoChapaMembros(const AConn: TUniConnection);
const
  VERSION = '004_E';
  DESCRIPTION = 'Criar tabela eleicao_chapa_membros';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_chapa_membros` (                '+
              '`id` INT NOT NULL AUTO_INCREMENT,                                     '+
              '`empresa_id` INT NOT NULL,                                            '+
              '`eleicao_id` INT NOT NULL,                                            '+
              '`eleicao_chapa_id` INT NOT NULL,                                      '+
              '`id_membro_int` INT NOT NULL,                                                '+
              '`codigo` INT NOT NULL,                                                '+
              '`nome` VARCHAR(180) NULL,                                             '+
              '`cpf` VARCHAR(20) NULL,                                               '+
              '`telefone` VARCHAR(20) NULL,                                          '+
              '`email` VARCHAR(160) NULL,                                            '+
              '`ativo` CHAR(1) NOT NULL DEFAULT ''N'',                               '+
              '`cargo` VARCHAR(45) NULL,                                             '+
              '`tipo` VARCHAR(45) NULL,                                              '+
              '`observacao` VARCHAR(500) NULL,                                       '+
              '`arquivo_foto` LONGBLOB NULL,                                         '+
              '`extensao_foto` VARCHAR(10) NULL DEFAULT ''PNG'',                     '+
              'PRIMARY KEY (`id`),                                                   '+
              'INDEX `idx_eleicao_chapa_membros_empresa` (`empresa_id`),             '+
              'INDEX `idx_eleicao_chapa_membros_eleicao` (`eleicao_id`),             '+
              'INDEX `idx_eleicao_chapa_membros_chapa` (`eleicao_chapa_id`),         '+
              'UNIQUE KEY `uk_eleicao_chapa_membro_codigo`                           '+
              '  (`empresa_id`, `eleicao_id`, `eleicao_chapa_id`, `codigo`),         '+
              'CONSTRAINT `fk_eleicao_chapa_membros_empresa`                         '+
              'FOREIGN KEY (`empresa_id`)                                            '+
              'REFERENCES `empresa` (`id`)                                '+
              'ON DELETE NO ACTION                                                   '+
              'ON UPDATE NO ACTION,                                                  '+

              'CONSTRAINT `fk_eleicao_chapa_membros_eleicao`                         '+
              '  FOREIGN KEY (`eleicao_id`)                                          '+
              '  REFERENCES `eleicao` (`id`)                              '+
              '  ON DELETE NO ACTION                                                 '+
              '  ON UPDATE NO ACTION,                                                '+

              'CONSTRAINT `fk_eleicao_chapa_membros_chapa`                           '+
              '  FOREIGN KEY (`eleicao_chapa_id`)                                    '+
              '  REFERENCES `eleicao_chapa` (`id`)                        '+
              '  ON DELETE NO ACTION                                                 '+
              '  ON UPDATE NO ACTION                                                 '+

              ') ENGINE=InnoDB                                                       '+
              ' DEFAULT CHARSET=utf8mb4                                              '+
              ' COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_005_CreateEleicaoConfirmacao(const AConn: TUniConnection);
const
  VERSION = '005_E';
  DESCRIPTION = 'Criar tabela eleicao_confirmacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS eleicao_confirmacao (             '+
                ' `id` INT NOT NULL AUTO_INCREMENT,                           '+
                ' `usuario_id` INT NOT NULL,                                  '+
                ' `empresa_id` INT NOT NULL,                                  '+
                ' `eleicao_id` INT NOT NULL,                                  '+
                ' `codigo_hash` VARCHAR(255) NULL,                            '+
                ' `tentativas` INT NULL DEFAULT 0,                            '+
                ' `quantidade_envios` INT NULL DEFAULT 0,                     '+
                ' `enviado_em` DATETIME NULL,                                 '+
                ' `expira_em` DATETIME NULL,                                  '+
                ' `confirmado` CHAR(1) NULL DEFAULT ''N'',                      '+
                ' `confirmado_em` DATETIME NULL,                              '+
                ' `criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,        '+
                ' `atualizado_em` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,        '+
                ' PRIMARY KEY (`id`),                                                       '+
                ' INDEX `fk_eleicao_confirmacao_usuario1_idx` (`usuario_id` ASC) VISIBLE,   '+
                ' INDEX `fk_eleicao_confirmacao_empresa1_idx` (`empresa_id` ASC) VISIBLE,   '+
                ' INDEX `fk_eleicao_confirmacao_eleicao1_idx` (`eleicao_id` ASC) VISIBLE,   '+
                ' UNIQUE INDEX `eleicao_id_UNIQUE` (`eleicao_id` ASC) VISIBLE,              '+
                ' UNIQUE INDEX `usuario_id_UNIQUE` (`usuario_id` ASC) VISIBLE,              '+
                ' CONSTRAINT `fk_eleicao_confirmacao_usuario1`              '+
                '  FOREIGN KEY (`usuario_id`)                               '+
                '  REFERENCES `usuario` (`id`)                              '+
                '  ON DELETE NO ACTION                                      '+
                '  ON UPDATE NO ACTION,                                    '+
                ' CONSTRAINT `fk_eleicao_confirmacao_empresa1`             '+
                '  FOREIGN KEY (`empresa_id`)                              '+
                '  REFERENCES `empresa` (`id`)                             '+
                '  ON DELETE NO ACTION                                     '+
                '  ON UPDATE NO ACTION,                                    '+
                ' CONSTRAINT `fk_eleicao_confirmacao_eleicao1`             '+
                '  FOREIGN KEY (`eleicao_id`)                              '+
                '  REFERENCES `eleicao` (`id`)                             '+
                '  ON DELETE NO ACTION                                     '+
                '  ON UPDATE NO ACTION)                                    '+
                ' ENGINE = InnoDB                                                       '+
                ' DEFAULT CHARSET=utf8mb4                                              '+
                ' COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);

end;

class procedure TEleicaoMigration.Migration_006_CreateEleicaoVotante(const AConn: TUniConnection);
const
  VERSION = '006_E';
  DESCRIPTION = 'Criar tabela EleicaoVotante';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_votante` (               '+
                '`id` int NOT NULL AUTO_INCREMENT,                            '+
                '`empresa_id` int NOT NULL,                                   '+
                '`eleicao_id` int NOT NULL,                                   '+
                '`usuario_id` int NOT NULL,                                   '+
                '`votou` char(1) COLLATE utf8mb4_unicode_ci DEFAULT ''S'',    '+
                '`votado_em` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,     '+
                'PRIMARY KEY (`id`),                                          '+
                'UNIQUE KEY `eleicao_id_UNIQUE` (`eleicao_id`,`usuario_id`) /*!80000 INVISIBLE */,  '+
                'KEY `fk_eleicao_votante_empresa1_idx` (`empresa_id`),                              '+
                'KEY `fk_eleicao_votante_eleicao1_idx` (`eleicao_id`),                              '+
                'KEY `fk_eleicao_votante_usuario1_idx` (`usuario_id`),                              '+
                'CONSTRAINT `fk_eleicao_votante_eleicao1` FOREIGN KEY (`eleicao_id`) REFERENCES `eleicao` (`id`),  '+
                'CONSTRAINT `fk_eleicao_votante_empresa1` FOREIGN KEY (`empresa_id`) REFERENCES `empresa` (`id`),   '+
                'CONSTRAINT `fk_eleicao_votante_usuario1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`)    '+
                ') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);

end;

class procedure TEleicaoMigration.Migration_007_CreateEleicaoVoto(const AConn: TUniConnection);
const
  VERSION = '007_E';
  DESCRIPTION = 'Criar tabela eleicao_voto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_voto` (                  '+
                '`id` INT NOT NULL AUTO_INCREMENT,                            '+
                '`empresa_id` INT NOT NULL,                                   '+
                '`eleicao_id` INT NOT NULL,                                   '+
                '`eleicao_chapa_id` INT NULL,                             '+
                '`tipo_voto` VARCHAR(10) NOT NULL,                                '+
                '`comprovante_hash` VARCHAR(254) NULL,                        '+
                '`criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,    '+
                'PRIMARY KEY (`id`),                                          '+
                'INDEX `fk_eleicao_voto_empresa1_idx` (`empresa_id` ASC) VISIBLE,                '+
                'INDEX `fk_eleicao_voto_eleicao1_idx` (`eleicao_id` ASC) VISIBLE,                '+
                'INDEX `fk_eleicao_voto_eleicao_chapa1_idx` (`eleicao_chapa_id` ASC) VISIBLE,    '+
                'CONSTRAINT `fk_eleicao_voto_empresa1`                        '+
                '  FOREIGN KEY (`empresa_id`)                                 '+
                '  REFERENCES `empresa` (`id`)                     '+
                '  ON DELETE NO ACTION                                        '+
                '  ON UPDATE NO ACTION,                                       '+
                'CONSTRAINT `fk_eleicao_voto_eleicao1`                        '+
                '  FOREIGN KEY (`eleicao_id`)                                 '+
                '  REFERENCES `eleicao` (`id`)                                '+
                '  ON DELETE NO ACTION                                        '+
                '  ON UPDATE NO ACTION,                                       '+
                'CONSTRAINT `fk_eleicao_voto_eleicao_chapa1`                  '+
                '  FOREIGN KEY (`eleicao_chapa_id`)                           '+
                '  REFERENCES `eleicao_chapa` (`id`)                          '+
                '  ON DELETE NO ACTION                                        '+
                '  ON UPDATE NO ACTION)                                       '+
                ' ENGINE = InnoDB                                              '+
                ' COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_008_Createeleicao_auditoria(const AConn: TUniConnection);
const
  VERSION = '008_E';
  DESCRIPTION = 'Criar tabela eleicao_auditoria';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS `eleicao_auditoria` (           '+
                '`id` INT NOT NULL AUTO_INCREMENT,                          '+
                '`empresa_id` INT NOT NULL,                                 '+
                '`eleicao_id` INT NOT NULL,                                 '+
                '`usuario_id` INT NULL,                                     '+

                '`tipo_evento` VARCHAR(50) NOT NULL,                        '+
                '`origem` VARCHAR(20) NOT NULL,                             '+
                '`sucesso` CHAR(1) NOT NULL DEFAULT ''S'',                  '+
                '`descricao` VARCHAR(255) NULL,                             '+

                '`ip` VARCHAR(45) NULL,                                     '+
                '`user_agent` VARCHAR(500) NULL,                            '+

                '`criado_em` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,  '+

                'PRIMARY KEY (`id`),                                       '+

                'INDEX `fk_eleicao_auditoria_empresa1_idx` (`empresa_id` ASC), '+
                'INDEX `fk_eleicao_auditoria_eleicao1_idx` (`eleicao_id` ASC),'+
                'INDEX `fk_eleicao_auditoria_usuario1_idx` (`usuario_id` ASC),'+

                'INDEX `idx_eleicao_auditoria_evento` (`tipo_evento` ASC),   '+
                'INDEX `idx_eleicao_auditoria_data` (`criado_em` ASC),      '+

                'CONSTRAINT `fk_eleicao_auditoria_empresa1`               '+
                '  FOREIGN KEY (`empresa_id`)                              '+
                '  REFERENCES `empresa` (`id`)                         '+
                '  ON DELETE NO ACTION                                 '+
                '  ON UPDATE NO ACTION,                                '+

                'CONSTRAINT `fk_eleicao_auditoria_eleicao1`           '+
                '  FOREIGN KEY (`eleicao_id`)                        '+
                '  REFERENCES `eleicao` (`id`)                       '+
                '  ON DELETE NO ACTION                              '+
                '  ON UPDATE NO ACTION,                             '+

                'CONSTRAINT `fk_eleicao_auditoria_usuario1`        '+
                '  FOREIGN KEY (`usuario_id`)                      '+
                '  REFERENCES `usuario` (`id`)                     '+
                '  ON DELETE NO ACTION                            '+
                '  ON UPDATE NO ACTION                            '+
                 ' )                                              '+
                '  ENGINE = InnoDB                               '+
                ' COLLATE=utf8mb4_0900_ai_ci DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_009_CreateEleicao_RateLimit(const AConn: TUniConnection);
const
  VERSION = '009_E';
  DESCRIPTION = 'Criar tabela eleicao_rate_limit ';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS eleicao_rate_limit (                     '+
                  'id integer NOT NULL AUTO_INCREMENT,                 '+
                  'empresa_id INT NOT NULL,                            '+
                  'eleicao_id INT NOT NULL,                            '+
                  'tipo VARCHAR(40) NOT NULL,                          '+
                  'chave VARCHAR(64) NOT NULL,                         '+
                  'tentativas INT NOT NULL DEFAULT 0,                  '+
                  'janela_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, '+
                  'bloqueado_ate DATETIME NULL,                              '+
                  'atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,   '+

                  'PRIMARY KEY (id),                                         '+

                  'UNIQUE KEY uk_eleicao_rate_limit (                        '+
                  '  empresa_id,                                              '+
                  '  eleicao_id,                                               '+
                  '  tipo,                                                    '+
                  '  chave                                                    '+
                  '),                                                        '+

                  'KEY idx_eleicao_rate_limit_eleicao (eleicao_id),          '+
                  'KEY idx_eleicao_rate_limit_tipo (tipo),                   '+
                  'KEY idx_eleicao_rate_limit_bloqueado (bloqueado_ate),     '+

                  'CONSTRAINT fk_eleicao_rate_limit_empresa                 '+
                  '  FOREIGN KEY (empresa_id) REFERENCES empresa(id),        '+

                  'CONSTRAINT fk_eleicao_rate_limit_eleicao                 '+
                  '  FOREIGN KEY (eleicao_id) REFERENCES eleicao(id)        '+
                  ');');
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_010_AlterEleicaoConfirmacao(const AConn: TUniConnection);
const
  VERSION = '010_E';
  DESCRIPTION = 'Criar tabela eleicao_confirmacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'ALTER TABLE eleicao_confirmacao    '+
                'DROP INDEX eleicao_id_UNIQUE,      '+
                'DROP INDEX usuario_id_UNIQUE;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_011_AlterEleicaoConfirmacao(const AConn: TUniConnection);
const
  VERSION = '011_E';
  DESCRIPTION = 'Criar tabela eleicao_confirmacao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'ALTER TABLE eleicao_confirmacao    '+
                'ADD UNIQUE KEY uk_confirmacao_empresa_eleicao_usuario  '+
                '(                                                      '+
                '  empresa_id,                                          '+
                '  eleicao_id,                                          '+
                '  usuario_id                                           '+
                ');');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_012_CreateEleicaoQuestao(const AConn: TUniConnection);
const
  VERSION = '015_E';
  DESCRIPTION = 'Criar tabela eleicao_questao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS `eleicao_questao` ('+
    ' `id` INT NOT NULL AUTO_INCREMENT,'+
    ' `id_questao_int` INT NOT NULL,'+
    ' `eleicao_id` INT NOT NULL,'+
    ' `id_eleicao_int` INT NOT NULL,'+
    ' `empresa_id` INT NOT NULL,'+
    ' `titulo` VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL,'+
    ' `descricao` TEXT COLLATE utf8mb4_unicode_ci NULL,'+
    ' `ordem` INT NOT NULL DEFAULT 1,'+
    ' `tipo_resposta` VARCHAR(30) COLLATE utf8mb4_unicode_ci NOT NULL,'+
    ' `obrigatoria` CHAR(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT ''S'','+
    ' `ativo` CHAR(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT ''S'','+
    ' `data_criacao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,'+
    ' `data_alteracao` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,'+
    ' PRIMARY KEY (`id`),'+
    ' UNIQUE KEY `uk_eleicao_questao_int` (`empresa_id`,`id_eleicao_int`,`id_questao_int`),'+
    ' KEY `idx_eleicao_questao_eleicao` (`eleicao_id`),'+
    ' KEY `idx_eleicao_questao_ordem` (`eleicao_id`,`ordem`),'+
    ' KEY `idx_eleicao_questao_ativo` (`eleicao_id`,`ativo`),'+
    ' CONSTRAINT `fk_eleicao_questao_eleicao` FOREIGN KEY (`eleicao_id`) REFERENCES `eleicao` (`id`) ON DELETE CASCADE'+
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEleicaoMigration.Migration_013_CreateEleicaoQuestaoOpcao(const AConn: TUniConnection);
const
  VERSION = '016_E';
  DESCRIPTION = 'Criar tabela eleicao_questao_opcao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS `eleicao_questao_opcao` ('+
    ' `id` INT NOT NULL AUTO_INCREMENT,'+
    ' `id_opcao_int` INT NOT NULL,'+
    ' `questao_id` INT NOT NULL,'+
    ' `id_questao_int` INT NOT NULL,'+
    ' `eleicao_id` INT NOT NULL,'+
    ' `id_eleicao_int` INT NOT NULL,'+
    ' `empresa_id` INT NOT NULL,'+
    ' `ordem` INT NOT NULL DEFAULT 1,'+
    ' `descricao` VARCHAR(200) COLLATE utf8mb4_unicode_ci NOT NULL,'+
    ' `ativo` CHAR(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT ''S'','+
    ' `data_criacao` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,'+
    ' `data_alteracao` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,'+
    ' PRIMARY KEY (`id`),'+
    ' UNIQUE KEY `uk_eleicao_questao_opcao_int` (`empresa_id`,`id_eleicao_int`,`id_questao_int`,`id_opcao_int`),'+
    ' KEY `idx_eleicao_questao_opcao_questao` (`questao_id`),'+
    ' KEY `idx_eleicao_questao_opcao_eleicao` (`eleicao_id`),'+
    ' KEY `idx_eleicao_questao_opcao_ordem` (`questao_id`,`ordem`),'+
    ' KEY `idx_eleicao_questao_opcao_ativo` (`questao_id`,`ativo`),'+
    ' CONSTRAINT `fk_eleicao_questao_opcao_questao` FOREIGN KEY (`questao_id`) REFERENCES `eleicao_questao` (`id`) ON DELETE CASCADE,'+
    ' CONSTRAINT `fk_eleicao_questao_opcao_eleicao` FOREIGN KEY (`eleicao_id`) REFERENCES `eleicao` (`id`) ON DELETE CASCADE'+
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;


class procedure TEleicaoMigration.Migration_014_CreateEleicaoComissao(const AConn: TUniConnection);
const
  VERSION = '017_E';
  DESCRIPTION = 'Criar tabela eleicao_comissao';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS eleicao_comissao ('+
    ' id INT NOT NULL AUTO_INCREMENT,'+
    ' empresa_id INT NOT NULL,'+
    ' eleicao_id INT NOT NULL,'+
    ' id_eleicao_int INT NOT NULL,'+
    ' id_comissao_int INT NOT NULL,'+
    ' usuario_id INT NOT NULL,'+
    ' nome VARCHAR(180) NOT NULL,'+
    ' cpf VARCHAR(20) NOT NULL,'+
    ' telefone VARCHAR(20) NULL,'+
    ' email VARCHAR(180) NULL,'+
    ' cargo VARCHAR(100) NULL,'+
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'','+
    ' criadoem DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,'+
    ' atualizadoem DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,'+
    ' PRIMARY KEY (id),'+
    ' UNIQUE KEY uk_eleicao_comissao_int (empresa_id,id_eleicao_int,id_comissao_int),'+
    ' KEY idx_eleicao_comissao_eleicao (eleicao_id),'+
    ' KEY idx_eleicao_comissao_usuario (usuario_id),'+
    ' KEY idx_eleicao_comissao_ativo (eleicao_id,ativo),'+
    ' CONSTRAINT fk_eleicao_comissao_empresa FOREIGN KEY (empresa_id) REFERENCES empresa(id),'+
    ' CONSTRAINT fk_eleicao_comissao_eleicao FOREIGN KEY (eleicao_id) REFERENCES eleicao(id) ON DELETE CASCADE,'+
    ' CONSTRAINT fk_eleicao_comissao_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id)'+
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

{$ENDREGION}


end.
