unit PlataformaContato.Migration;

interface

type
  TPlataformaContatoMigration = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

class procedure TPlataformaContatoMigration.Run;
var
  C: TAppApiConfig;
  Conn: TUniConnection;
  Q: TUniQuery;

  procedure ExecSQL(const ASQL: string);
  var
    Cmd: TUniQuery;
  begin
    Cmd := TUniQuery.Create(nil);
    try
      Cmd.Connection := Conn;
      Cmd.SQL.Text := ASQL;
      Cmd.Execute;
    finally
      Cmd.Free;
    end;
  end;

  function MigrationExists(const AVersion: string): Boolean;
  begin
    Q.Close;
    Q.SQL.Text :=
      'SELECT 1 FROM schema_migrations ' +
      'WHERE version=:version LIMIT 1';
    Q.ParamByName('version').AsString := AVersion;
    Q.Open;
    Result := not Q.IsEmpty;
  end;

  procedure RegisterMigration(const AVersion, ADescription: string);
  begin
    Q.Close;
    Q.SQL.Text :=
      'INSERT INTO schema_migrations (version,description) ' +
      'VALUES (:version,:descricao)';
    Q.ParamByName('version').AsString := AVersion;
    Q.ParamByName('descricao').AsString := ADescription;
    Q.Execute;
  end;

  function ColumnExists(const ATable, AColumn: string): Boolean;
  begin
    Q.Close;
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.columns ' +
      'WHERE table_schema=DATABASE() AND table_name=:tabela ' +
      'AND column_name=:coluna LIMIT 1';
    Q.ParamByName('tabela').AsString := ATable;
    Q.ParamByName('coluna').AsString := AColumn;
    Q.Open;
    Result := not Q.IsEmpty;
  end;

  function IndexExists(const ATable, AIndex: string): Boolean;
  begin
    Q.Close;
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.statistics ' +
      'WHERE table_schema=DATABASE() AND table_name=:tabela ' +
      'AND index_name=:indice LIMIT 1';
    Q.ParamByName('tabela').AsString := ATable;
    Q.ParamByName('indice').AsString := AIndex;
    Q.Open;
    Result := not Q.IsEmpty;
  end;

  function ConstraintExists(const ATable, AConstraint: string): Boolean;
  begin
    Q.Close;
    Q.SQL.Text :=
      'SELECT 1 FROM information_schema.table_constraints ' +
      'WHERE constraint_schema=DATABASE() AND table_name=:tabela ' +
      'AND constraint_name=:constraint_name LIMIT 1';
    Q.ParamByName('tabela').AsString := ATable;
    Q.ParamByName('constraint_name').AsString := AConstraint;
    Q.Open;
    Result := not Q.IsEmpty;
  end;

  procedure Run064;
  begin
    if MigrationExists('064') then
      Exit;

    ExecSQL(
      'CREATE TABLE IF NOT EXISTS plataforma_contato (' +
      ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
      ' tipo_documento VARCHAR(4) NULL,' +
      ' documento VARCHAR(25) NULL,' +
      ' documento_normalizado VARCHAR(20) NULL,' +
      ' razao_social VARCHAR(200) NULL,' +
      ' nome_fantasia VARCHAR(200) NULL,' +
      ' responsavel VARCHAR(180) NULL,' +
      ' telefone VARCHAR(30) NULL,' +
      ' telefone_normalizado VARCHAR(20) NULL,' +
      ' email VARCHAR(254) NULL,' +
      ' email_normalizado VARCHAR(254) NULL,' +
      ' grau VARCHAR(100) NULL,' +
      ' cidade VARCHAR(120) NULL,' +
      ' uf CHAR(2) NULL,' +
      ' orgao VARCHAR(160) NULL,' +
      ' site VARCHAR(500) NULL,' +
      ' observacao TEXT NULL,' +
      ' fonte VARCHAR(255) NULL,' +
      ' data_coleta DATE NULL,' +
      ' situacao VARCHAR(10) NOT NULL DEFAULT ''ATIVO'',' +
      ' criado_por BIGINT UNSIGNED NOT NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id),' +
      ' UNIQUE KEY uq_plataforma_contato_documento (documento_normalizado),' +
      ' KEY ix_plataforma_contato_email (email_normalizado),' +
      ' KEY ix_plataforma_contato_telefone (telefone_normalizado),' +
      ' KEY ix_plataforma_contato_local (uf,cidade),' +
      ' KEY ix_plataforma_contato_segmentacao (grau,orgao,situacao),' +
      ' CONSTRAINT fk_plataforma_contato_usuario FOREIGN KEY (criado_por) ' +
      '   REFERENCES usuario(id) ON UPDATE RESTRICT ON DELETE RESTRICT,' +
      ' CONSTRAINT ck_plataforma_contato_tipo_documento CHECK (' +
      '   tipo_documento IS NULL OR tipo_documento IN (''CPF'',''CNPJ'')),' +
      ' CONSTRAINT ck_plataforma_contato_situacao CHECK (situacao IN (''ATIVO'',''INATIVO''))' +
      ') ENGINE=InnoDB COMMENT=''Base global de contatos para campanhas da plataforma.'';'
    );

    ExecSQL(
      'CREATE TABLE IF NOT EXISTS plataforma_contato_lista (' +
      ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
      ' nome VARCHAR(180) NOT NULL,' +
      ' descricao VARCHAR(500) NULL,' +
      ' cidade VARCHAR(120) NULL,' +
      ' uf CHAR(2) NULL,' +
      ' orgao VARCHAR(160) NULL,' +
      ' grau VARCHAR(100) NULL,' +
      ' fonte VARCHAR(255) NULL,' +
      ' criado_por BIGINT UNSIGNED NOT NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id),' +
      ' KEY ix_plataforma_contato_lista_nome (nome),' +
      ' CONSTRAINT fk_plataforma_contato_lista_usuario FOREIGN KEY (criado_por) ' +
      '   REFERENCES usuario(id) ON UPDATE RESTRICT ON DELETE RESTRICT' +
      ') ENGINE=InnoDB COMMENT=''Listas reutilizaveis de contatos da plataforma.'';'
    );

    ExecSQL(
      'CREATE TABLE IF NOT EXISTS plataforma_contato_lista_item (' +
      ' id_lista BIGINT UNSIGNED NOT NULL,' +
      ' id_contato BIGINT UNSIGNED NOT NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id_lista,id_contato),' +
      ' KEY ix_plataforma_contato_lista_item_contato (id_contato),' +
      ' CONSTRAINT fk_plataforma_contato_lista_item_lista FOREIGN KEY (id_lista) ' +
      '   REFERENCES plataforma_contato_lista(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
      ' CONSTRAINT fk_plataforma_contato_lista_item_contato FOREIGN KEY (id_contato) ' +
      '   REFERENCES plataforma_contato(id) ON UPDATE RESTRICT ON DELETE CASCADE' +
      ') ENGINE=InnoDB COMMENT=''Relacionamento entre contatos e listas.'';'
    );

    if not ColumnExists('plataforma_campanha_destinatario','id_contato_origem') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_destinatario ' +
        'ADD COLUMN id_contato_origem BIGINT UNSIGNED NULL AFTER id_campanha'
      );

    if not IndexExists('plataforma_campanha_destinatario','ix_campanha_dest_contato_origem') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_destinatario ' +
        'ADD KEY ix_campanha_dest_contato_origem (id_contato_origem)'
      );

    if not ConstraintExists('plataforma_campanha_destinatario','fk_campanha_dest_contato_origem') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_destinatario ' +
        'ADD CONSTRAINT fk_campanha_dest_contato_origem ' +
        'FOREIGN KEY (id_contato_origem) REFERENCES plataforma_contato(id) ' +
        'ON UPDATE RESTRICT ON DELETE SET NULL'
      );

    RegisterMigration(
      '064',
      'Base de contatos reutilizavel para campanhas da plataforma'
    );
  end;

  procedure Run068;
  begin
    if MigrationExists('068') then
      Exit;

    if not ColumnExists('plataforma_contato','tipo_contato') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN tipo_contato VARCHAR(20) NOT NULL DEFAULT ''ENTIDADE'' AFTER id'
      );

    if not ColumnExists('plataforma_contato','cargo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN cargo VARCHAR(40) NULL AFTER grau'
      );

    if not ColumnExists('plataforma_contato','partido') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN partido VARCHAR(30) NULL AFTER cargo'
      );

    if not ColumnExists('plataforma_contato','id_externo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN id_externo VARCHAR(80) NULL AFTER partido'
      );

    if not ColumnExists('plataforma_contato','fonte_dados') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN fonte_dados VARCHAR(50) NULL AFTER id_externo'
      );

    if not ColumnExists('plataforma_contato','url_perfil') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN url_perfil VARCHAR(500) NULL AFTER fonte_dados'
      );

    if not ColumnExists('plataforma_contato','foto_url') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN foto_url VARCHAR(500) NULL AFTER url_perfil'
      );

    if not ColumnExists('plataforma_contato','unale_associado') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN unale_associado TINYINT(1) NOT NULL DEFAULT 0 AFTER foto_url'
      );

    if not ColumnExists('plataforma_contato','em_exercicio') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD COLUMN em_exercicio TINYINT(1) NOT NULL DEFAULT 1 AFTER unale_associado'
      );

    if not IndexExists('plataforma_contato','uq_plataforma_contato_fonte_externo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD UNIQUE KEY uq_plataforma_contato_fonte_externo (fonte_dados,id_externo)'
      );

    if not IndexExists('plataforma_contato','ix_plataforma_contato_parlamentar') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD KEY ix_plataforma_contato_parlamentar ' +
        '(tipo_contato,cargo,uf,partido,situacao)'
      );

    if not IndexExists('plataforma_contato','ix_plataforma_contato_unale') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD KEY ix_plataforma_contato_unale ' +
        '(unale_associado,uf,situacao)'
      );

    if not ConstraintExists('plataforma_contato','ck_plataforma_contato_tipo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD CONSTRAINT ck_plataforma_contato_tipo CHECK (' +
        'tipo_contato IN (''ENTIDADE'',''PARLAMENTAR'',''PESSOA''))'
      );

    if not ConstraintExists('plataforma_contato','ck_plataforma_contato_cargo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato ' +
        'ADD CONSTRAINT ck_plataforma_contato_cargo CHECK (' +
        'cargo IS NULL OR cargo IN (' +
        '''VEREADOR'',''DEPUTADO_ESTADUAL'',''DEPUTADO_FEDERAL'',''SENADOR''))'
      );

    RegisterMigration(
      '068',
      'Base de contatos preparada para parlamentares e associados UNALE'
    );
  end;

begin
  C := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(C.Database);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := Conn;
    Run064;
    Run068;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

end.
