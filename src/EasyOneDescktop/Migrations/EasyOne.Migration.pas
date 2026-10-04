unit EasyOne.Migration;

interface

uses
  Uni,
  App.Config;

type
  TEasyOneMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;
    class procedure CreateMigrationTable(const AConn: TUniConnection); static;


    class procedure Migration_001_CreateEmpresa(const AConn: TUniConnection); static;
    class procedure Migration_002_CreateAssociado(const AConn: TUniConnection); static;
    class procedure Migration_003_CreateUsuario(const AConn: TUniConnection); static;
    class procedure Migration_004_AlterEmpresa(const AConn: TUniConnection); static;
    class procedure Migration_005_AlterUsuario(const AConn: TUniConnection); static;
    class procedure Migration_006_AlterUsuarioIdExterno(const AConn: TUniConnection); static;
    class procedure Migration_007_AlterUsuarioPessoaOpcional(const AConn: TUniConnection); static;

  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
end;

implementation

uses
  System.SysUtils,
  Database.Connection;

{ TEasyOneMigration }

{$REGION 'Padrao'}

class procedure TEasyOneMigration.CreateMigrationTable(const AConn: TUniConnection);
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

class procedure TEasyOneMigration.ExecSQL(const AConn: TUniConnection;const ASQL: string);
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

class function TEasyOneMigration.MigrationExists(const AConn: TUniConnection;const AVersion: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS total ' +
      ' FROM schema_migrations ' +
      ' WHERE version = :version';

    Qry.ParamByName('version').AsString := AVersion;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TEasyOneMigration.RegisterMigration(const AConn: TUniConnection;const AVersion, ADescription: string);
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

class procedure TEasyOneMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);

  try
    Conn.StartTransaction;
      try

      CreateMigrationTable(Conn);

      Migration_001_CreateEmpresa(Conn);
      Migration_002_CreateAssociado(Conn);
      Migration_003_CreateUsuario(Conn);
      Migration_004_AlterEmpresa(Conn);
      Migration_005_AlterUsuario(Conn);
      Migration_006_AlterUsuarioIdExterno(Conn);
      Migration_007_AlterUsuarioPessoaOpcional(Conn);

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

class procedure TEasyOneMigration.Migration_001_CreateEmpresa(const AConn: TUniConnection);
const
  VERSION = '001';
  DESCRIPTION = 'Criar tabelas empresa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS empresa (                         '+
          '`id` INT NOT NULL AUTO_INCREMENT,                                  '+
          '`id_empresa` INT NOT NULL,                                         '+
          '`uuid` CHAR(36) NULL,                                              '+
          '`razao` VARCHAR(180) NOT NULL,                                     '+
          '`fantasia` VARCHAR(100) NULL,                                      '+
          '`telefone` VARCHAR(15) NULL,                                       '+
          '`ativo` CHAR(1) NOT NULL DEFAULT ''S'',                              '+
          '`cpfcnpj` VARCHAR(20) NOT NULL,                                    '+
          '`criadoem` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,            '+
          '`atualizadoem` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,'+
          '`whatsapp_url` varchar(200) DEFAULT NULL,                          '+
          '`whatsapp_instancia` varchar(500) DEFAULT NULL,                    '+
          '`whatsapp_token` varchar(500) DEFAULT NULL,                        '+
          'PRIMARY KEY (`id`),                                                '+
          'UNIQUE INDEX `id_empresa_UNIQUE` (`id_empresa` ASC) VISIBLE,       '+
          'UNIQUE INDEX `uuid_UNIQUE` (`uuid` ASC) VISIBLE,                   '+
          'UNIQUE INDEX `cpfcnpj_UNIQUE` (`cpfcnpj` ASC) VISIBLE,             '+
          'INDEX `idx_empresa_razao` (`razao` ASC) INVISIBLE,                 '+
          'INDEX `idx_empresa_fantasia` USING BTREE (`fantasia`) VISIBLE)     '+
          'ENGINE = InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;');


  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_002_CreateAssociado(const AConn: TUniConnection);
const
  VERSION = '002';
  DESCRIPTION = 'Criar tabelas pessoa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS pessoa (                         '+
        '`id` INT NOT NULL AUTO_INCREMENT,                                   '+
        '`id_socio` INT NOT NULL,                                            '+
        '`codigo` INT NOT NULL,                                              '+
        '`matricula` INT NOT NULL,                                           '+
        '`ativo` CHAR(1) NOT NULL DEFAULT ''S'',                             '+
        '`nome` VARCHAR(180) NULL,                                           '+
        '`apelido` VARCHAR(100) NULL,                                        '+
        '`telefone` VARCHAR(15) NULL,                                        '+
        '`celular` VARCHAR(15) NULL,                                         '+
        '`whatsapp` VARCHAR(15) NULL,                                        '+
        '`cpf` VARCHAR(20) NULL,                                             '+
        '`nascimento` DATE NULL,                                             '+
        '`email` VARCHAR(180) NULL,                                          '+
        '`cidade` VARCHAR(60) NULL,                                          '+
        '`secretaria` VARCHAR(60) NULL,                                      '+
        '`profissao` VARCHAR(60) NULL,                                       '+
        '`lotacao` VARCHAR(60) NULL,                                         '+
        '`localtrabalho` VARCHAR(60) NULL,                                   '+
        '`funcao` VARCHAR(60) NULL,                                          '+
        '`naturalde` VARCHAR(60) NULL,                                       '+
        '`rg` VARCHAR(20) NULL,                                              '+
        '`data_filiacao` DATE NULL,                                          '+
        '`pai` VARCHAR(100) NULL,                                            '+
        '`mae` VARCHAR(100) NULL,                                            '+
        '`foto` LONGBLOB NULL,                                               '+
        '`bloqueado` CHAR(1) NULL DEFAULT ''N'',                             '+
        '`excluido` INT NULL DEFAULT 0,                                      '+
        '`criadoem` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,             '+
        '`atualizadoem` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+
        '`empresa_id` INT NOT NULL,                                          '+
        'PRIMARY KEY (`id`),                                                 '+
        'INDEX `fk_pessoa_empresa_idx` (`empresa_id` ASC) VISIBLE,           '+
        'UNIQUE INDEX `uk_pessoa_empresa_socio` (`empresa_id` ASC, `id_socio` ASC) INVISIBLE, '+
        'UNIQUE INDEX `uk_pessoa_empresa_codigo` (`empresa_id` ASC, `codigo` ASC) INVISIBLE,  '+
        'INDEX `idx_pessoa_empresa_matricula` USING BTREE (`empresa_id`, `matricula`) INVISIBLE,'+
        'INDEX `idx_pessoa_empresa_nome` USING BTREE (`empresa_id`, `nome`) INVISIBLE, '+
        'INDEX `idx_pessoa_empresa_cpf` USING BTREE (`empresa_id`, `cpf`) VISIBLE, '+
        'CONSTRAINT `fk_pessoa_empresa`                                      '+
        '  FOREIGN KEY (`empresa_id`)                                        '+
        '  REFERENCES `empresa` (`id`)                            '+
        '  ON DELETE NO ACTION                                               '+
        '  ON UPDATE NO ACTION)                                              '+
        ' ENGINE = InnoDB                                                    ' +
        ' DEFAULT CHARSET=utf8mb4                                            ' +
        ' COLLATE=utf8mb4_0900_ai_ci;'                                       );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_003_CreateUsuario(const AConn: TUniConnection);
const
  VERSION = '003';
  DESCRIPTION = 'Criar tabelas Usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'CREATE TABLE IF NOT EXISTS usuario (                           '+
            '`id` INT NOT NULL AUTO_INCREMENT,                                  '+
            '`empresa_id` INT NOT NULL,                                         '+
            '`pessoa_id` INT NOT NULL,                                          '+
            '`nome` VARCHAR(180) NULL,                                          '+
            '`login` VARCHAR(40) NULL,                                          '+
            '`senha_hash` VARCHAR(250) NULL,                                    '+
            '`ativo` CHAR(1) NULL DEFAULT ''S'',                                '+
            '`email` VARCHAR(180) NULL,                                         '+
            '`perfil` VARCHAR(25) NULL DEFAULT ''ADMIN'',                       '+
            '`criadoem` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,            '+
            '`atualizadoem` DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP, '+
            'PRIMARY KEY (`id`),                                                '+
            'INDEX `fk_usuario_empresa1_idx` (`empresa_id` ASC) VISIBLE,        '+
            'INDEX `fk_usuario_pessoa1_idx` (`pessoa_id` ASC) VISIBLE,          '+
            'UNIQUE INDEX `uk_usuario_empresa_login` (`empresa_id` ASC, `login` ASC) INVISIBLE,  '+
            'UNIQUE INDEX `uk_usuario_empresa_pessoa` (`empresa_id` ASC, `pessoa_id` ASC) INVISIBLE, '+
            'INDEX `idx_usuario_pessoa` USING BTREE (`pessoa_id`) VISIBLE,       '+
            'CONSTRAINT `fk_usuario_empresa1`                                   '+
            '  FOREIGN KEY (`empresa_id`)                                       '+
            '  REFERENCES `empresa` (`id`)                           '+
            '  ON DELETE NO ACTION                                              '+
            '  ON UPDATE NO ACTION,                                             '+
            'CONSTRAINT `fk_usuario_pessoa1`                                    '+
            '  FOREIGN KEY (`pessoa_id`)                                        '+
            '  REFERENCES `pessoa` (`id`)                            '+
            '  ON DELETE NO ACTION                                              '+
            '  ON UPDATE NO ACTION)                                             '+
            'ENGINE = InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_004_AlterEmpresa(const AConn: TUniConnection);
const
  VERSION = '004';
  DESCRIPTION = 'Alterar tabelas empresa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'ALTER TABLE empresa    '+
                'ADD COLUMN easyone_api_key_hash VARCHAR(64) NULL,         '+
                'ADD COLUMN easyone_integracao_ativo CHAR(1) NOT NULL DEFAULT ''N'';');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_005_AlterUsuario(const AConn: TUniConnection);
const
  VERSION = '005';
  DESCRIPTION = 'Alterar tabelas usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,'ALTER TABLE usuario    '+
                'ADD COLUMN id_eleitor_int INT NULL');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_006_AlterUsuarioIdExterno(const AConn: TUniConnection);
const
  VERSION = '006';
  DESCRIPTION = 'Adicionar identificador externo do usuario EasyOne';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'ALTER TABLE usuario '+
    'ADD COLUMN id_usuario_int INT NULL, '+
    'ADD UNIQUE KEY uk_usuario_empresa_usuario_int (empresa_id, id_usuario_int)');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TEasyOneMigration.Migration_007_AlterUsuarioPessoaOpcional(const AConn: TUniConnection);
const
  VERSION = '007';
  DESCRIPTION = 'Permitir usuario administrativo sem pessoa associada';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'ALTER TABLE usuario '+
    'MODIFY COLUMN pessoa_id INT NULL');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

{$ENDREGION}


end.


