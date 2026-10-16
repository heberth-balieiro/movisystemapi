unit PlataformaContatoColeta.Migration;

interface

type
  TPlataformaContatoColetaMigration = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

class procedure TPlataformaContatoColetaMigration.Run;
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

  procedure Run065;
  begin
    if MigrationExists('065') then Exit;

    ExecSQL(
      'CREATE TABLE IF NOT EXISTS plataforma_contato_coleta (' +
      ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
      ' nome VARCHAR(180) NOT NULL,' +
      ' tipo VARCHAR(30) NOT NULL,' +
      ' uf CHAR(2) NOT NULL,' +
      ' limite INT NOT NULL DEFAULT 0,' +
      ' workers INT NOT NULL DEFAULT 6,' +
      ' situacao VARCHAR(15) NOT NULL DEFAULT ''PENDENTE'',' +
      ' total_alvos INT NOT NULL DEFAULT 0,' +
      ' total_processados INT NOT NULL DEFAULT 0,' +
      ' total_emails INT NOT NULL DEFAULT 0,' +
      ' total_institucionais INT NOT NULL DEFAULT 0,' +
      ' total_revisar INT NOT NULL DEFAULT 0,' +
      ' total_sem_email INT NOT NULL DEFAULT 0,' +
      ' mensagem_erro TEXT NULL,' +
      ' criado_por BIGINT UNSIGNED NOT NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' iniciado_em DATETIME(3) NULL,' +
      ' finalizado_em DATETIME(3) NULL,' +
      ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id),' +
      ' KEY ix_contato_coleta_fila (situacao,id),' +
      ' KEY ix_contato_coleta_tipo_uf (tipo,uf,situacao),' +
      ' CONSTRAINT fk_contato_coleta_usuario FOREIGN KEY (criado_por) REFERENCES usuario(id) ON UPDATE RESTRICT ON DELETE RESTRICT,' +
      ' CONSTRAINT ck_contato_coleta_situacao CHECK (situacao IN (''PENDENTE'',''PROCESSANDO'',''CONCLUIDA'',''ERRO'',''CANCELADA''))' +
      ') ENGINE=InnoDB COMMENT=''Execucoes de coleta automatizada de contatos publicos.'';'
    );

    ExecSQL(
      'CREATE TABLE IF NOT EXISTS plataforma_contato_coleta_item (' +
      ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
      ' id_coleta BIGINT UNSIGNED NOT NULL,' +
      ' nome_orgao VARCHAR(200) NOT NULL,' +
      ' cidade VARCHAR(120) NOT NULL,' +
      ' uf CHAR(2) NOT NULL,' +
      ' email VARCHAR(254) NULL,' +
      ' site VARCHAR(500) NULL,' +
      ' pagina_origem VARCHAR(1000) NULL,' +
      ' classificacao VARCHAR(40) NOT NULL,' +
      ' observacao VARCHAR(500) NULL,' +
      ' situacao_revisao VARCHAR(15) NOT NULL DEFAULT ''PENDENTE'',' +
      ' id_contato BIGINT UNSIGNED NULL,' +
      ' coletado_em DATE NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id),' +
      ' UNIQUE KEY uq_contato_coleta_item_email (id_coleta,email,cidade),' +
      ' KEY ix_contato_coleta_item_coleta (id_coleta,classificacao,situacao_revisao),' +
      ' KEY ix_contato_coleta_item_local (uf,cidade),' +
      ' KEY ix_contato_coleta_item_contato (id_contato),' +
      ' CONSTRAINT fk_contato_coleta_item_coleta FOREIGN KEY (id_coleta) REFERENCES plataforma_contato_coleta(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
      ' CONSTRAINT fk_contato_coleta_item_contato FOREIGN KEY (id_contato) REFERENCES plataforma_contato(id) ON UPDATE RESTRICT ON DELETE SET NULL,' +
      ' CONSTRAINT ck_contato_coleta_item_revisao CHECK (situacao_revisao IN (''PENDENTE'',''APROVADO'',''DESCARTADO'',''IMPORTADO''))' +
      ') ENGINE=InnoDB COMMENT=''Resultados encontrados pelo coletor de contatos.'';'
    );

    RegisterMigration('065','Coletas automatizadas para a base de contatos da plataforma');
  end;

  procedure Run066;
  begin
    if MigrationExists('066') then Exit;

    ExecSQL(
      'ALTER TABLE plataforma_contato_coleta ' +
      'ADD COLUMN modo_alvo VARCHAR(20) NOT NULL DEFAULT ''TODOS'' AFTER uf,' +
      'ADD COLUMN municipio VARCHAR(120) NULL AFTER modo_alvo,' +
      'ADD KEY ix_contato_coleta_alvo (tipo,uf,modo_alvo,municipio);'
    );

    RegisterMigration('066','Filtros de alvo da coleta e preparacao para novos tipos de coletor');
  end;

  procedure Run067;
  begin
    if MigrationExists('067') then Exit;

    ExecSQL(
      'ALTER TABLE plataforma_contato_coleta ' +
      'ADD COLUMN termo_busca VARCHAR(255) NULL AFTER municipio,' +
      'ADD COLUMN segmento VARCHAR(80) NULL AFTER termo_busca,' +
      'ADD KEY ix_contato_coleta_segmento (tipo,uf,segmento);'
    );

    RegisterMigration('067','Parametros de busca para sindicatos e associacoes');
  end;

  procedure Run069;
  begin
    if MigrationExists('069') then Exit;

    if not ColumnExists('plataforma_contato_coleta_item','tipo_contato') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN tipo_contato VARCHAR(20) NULL AFTER nome_orgao'
      );

    if not ColumnExists('plataforma_contato_coleta_item','cargo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN cargo VARCHAR(40) NULL AFTER tipo_contato'
      );

    if not ColumnExists('plataforma_contato_coleta_item','partido') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN partido VARCHAR(30) NULL AFTER cargo'
      );

    if not ColumnExists('plataforma_contato_coleta_item','id_externo') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN id_externo VARCHAR(80) NULL AFTER partido'
      );

    if not ColumnExists('plataforma_contato_coleta_item','fonte_dados') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN fonte_dados VARCHAR(50) NULL AFTER id_externo'
      );

    if not ColumnExists('plataforma_contato_coleta_item','url_perfil') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN url_perfil VARCHAR(500) NULL AFTER fonte_dados'
      );

    if not ColumnExists('plataforma_contato_coleta_item','foto_url') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN foto_url VARCHAR(500) NULL AFTER url_perfil'
      );

    if not ColumnExists('plataforma_contato_coleta_item','unale_associado') then
      ExecSQL(
        'ALTER TABLE plataforma_contato_coleta_item ' +
        'ADD COLUMN unale_associado TINYINT(1) NOT NULL DEFAULT 0 AFTER foto_url'
      );

    RegisterMigration('069','Metadados parlamentares nos itens de coleta de contatos');
  end;

begin
  C := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(C.Database);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := Conn;
    Run065;
    Run066;
    Run067;
    Run069;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

end.
