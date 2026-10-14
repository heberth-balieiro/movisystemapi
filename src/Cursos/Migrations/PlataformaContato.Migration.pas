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
const
  VERSION = '064';
  DESCRIPTION = 'Base de contatos reutilizavel para campanhas da plataforma';
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

  function MigrationExists: Boolean;
  begin
    Q.Close;
    Q.SQL.Text := 'SELECT 1 FROM schema_migrations WHERE version=:version LIMIT 1';
    Q.ParamByName('version').AsString := VERSION;
    Q.Open;
    Result := not Q.IsEmpty;
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

begin
  C := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(C.Database);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := Conn;
    if MigrationExists then
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

    Q.Close;
    Q.SQL.Text :=
      'INSERT INTO schema_migrations (version,description) VALUES (:version,:descricao)';
    Q.ParamByName('version').AsString := VERSION;
    Q.ParamByName('descricao').AsString := DESCRIPTION;
    Q.Execute;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

end.
