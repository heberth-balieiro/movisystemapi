unit PlataformaCampanha.Worker;

interface

type
  TPlataformaCampanhaWorker = class
  private
    class procedure RunMigration063; static;
  public
    class procedure Start; static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  Uni,
  App.Config,
  Database.Connection,
  PlataformaCampanha.Service;

class procedure TPlataformaCampanhaWorker.RunMigration063;
const
  VERSION = '063';
  DESCRIPTION = 'Execucoes e historico de reenvio das campanhas SaaS';
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
    Q.SQL.Text :=
      'SELECT 1 FROM schema_migrations WHERE version=:version LIMIT 1';
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

  function EnviosSemExecucao: Integer;
  begin
    Q.Close;
    Q.SQL.Text :=
      'SELECT COUNT(*) total FROM plataforma_campanha_envio ' +
      'WHERE id_execucao IS NULL';
    Q.Open;
    Result := Q.FieldByName('total').AsInteger;
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
      'CREATE TABLE IF NOT EXISTS plataforma_campanha_execucao (' +
      ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
      ' id_campanha BIGINT UNSIGNED NOT NULL,' +
      ' numero_execucao INT UNSIGNED NOT NULL,' +
      ' situacao VARCHAR(20) NOT NULL DEFAULT ''PROCESSANDO'',' +
      ' iniciado_por BIGINT UNSIGNED NOT NULL,' +
      ' iniciado_em DATETIME(3) NULL,' +
      ' concluido_em DATETIME(3) NULL,' +
      ' total_envios INT UNSIGNED NOT NULL DEFAULT 0,' +
      ' total_enviados INT UNSIGNED NOT NULL DEFAULT 0,' +
      ' total_falhas INT UNSIGNED NOT NULL DEFAULT 0,' +
      ' whatsapp_modo_remetente VARCHAR(10) NULL,' +
      ' id_whatsapp_usuario BIGINT UNSIGNED NULL,' +
      ' whatsapp_instancia VARCHAR(160) NULL,' +
      ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
      ' PRIMARY KEY (id),' +
      ' UNIQUE KEY uq_campanha_execucao_numero (id_campanha,numero_execucao),' +
      ' KEY ix_campanha_execucao_situacao (situacao,iniciado_em,id),' +
      ' CONSTRAINT fk_campanha_execucao_campanha FOREIGN KEY (id_campanha) ' +
      '   REFERENCES plataforma_campanha(id) ON UPDATE RESTRICT ON DELETE CASCADE,' +
      ' CONSTRAINT fk_campanha_execucao_usuario FOREIGN KEY (iniciado_por) ' +
      '   REFERENCES usuario(id) ON UPDATE RESTRICT ON DELETE RESTRICT,' +
      ' CONSTRAINT fk_campanha_execucao_whatsapp_usuario FOREIGN KEY (id_whatsapp_usuario) ' +
      '   REFERENCES usuario(id) ON UPDATE RESTRICT ON DELETE RESTRICT,' +
      ' CONSTRAINT ck_campanha_execucao_situacao CHECK (situacao IN ' +
      '   (''AGENDADA'',''PROCESSANDO'',''CONCLUIDA'',''CANCELADA'')),' +
      ' CONSTRAINT ck_campanha_execucao_whatsapp_modo CHECK (' +
      '   whatsapp_modo_remetente IS NULL OR whatsapp_modo_remetente IN (''EMPRESA'',''USUARIO''))' +
      ') ENGINE=InnoDB COMMENT=''Historico de execucoes e reenvios das campanhas SaaS.'';'
    );

    if not ColumnExists('plataforma_campanha_envio','id_execucao') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_envio ' +
        'ADD COLUMN id_execucao BIGINT UNSIGNED NULL AFTER id_campanha'
      );

    // Preserva os envios existentes como a primeira execucao historica.
    ExecSQL(
      'INSERT INTO plataforma_campanha_execucao (' +
      'id_campanha,numero_execucao,situacao,iniciado_por,iniciado_em,concluido_em,' +
      'total_envios,total_enviados,total_falhas,whatsapp_modo_remetente,' +
      'id_whatsapp_usuario,whatsapp_instancia,criado_em) ' +
      'SELECT c.id,1,' +
      'CASE ' +
      ' WHEN c.situacao=''AGENDADA'' THEN ''AGENDADA'' ' +
      ' WHEN c.situacao=''PROCESSANDO'' THEN ''PROCESSANDO'' ' +
      ' WHEN c.situacao=''CANCELADA'' THEN ''CANCELADA'' ' +
      ' ELSE ''CONCLUIDA'' END,' +
      'c.criado_por,c.iniciado_em,c.concluido_em,' +
      'c.total_envios,c.total_enviados,c.total_falhas,' +
      'c.whatsapp_modo_remetente,c.id_whatsapp_usuario,c.whatsapp_instancia,' +
      'COALESCE(c.iniciado_em,c.criado_em) ' +
      'FROM plataforma_campanha c ' +
      'WHERE EXISTS (SELECT 1 FROM plataforma_campanha_envio e WHERE e.id_campanha=c.id) ' +
      'AND NOT EXISTS (SELECT 1 FROM plataforma_campanha_execucao x WHERE x.id_campanha=c.id)'
    );

    ExecSQL(
      'UPDATE plataforma_campanha_envio e ' +
      'JOIN plataforma_campanha_execucao x ' +
      'ON x.id_campanha=e.id_campanha AND x.numero_execucao=1 ' +
      'SET e.id_execucao=x.id WHERE e.id_execucao IS NULL'
    );

    if EnviosSemExecucao > 0 then
      raise Exception.Create(
        'Migration 063 interrompida: existem envios de campanha sem execução vinculada.'
      );

    if IndexExists('plataforma_campanha_envio','uq_campanha_envio_dest_canal') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_envio ' +
        'DROP INDEX uq_campanha_envio_dest_canal'
      );

    if not IndexExists('plataforma_campanha_envio','uq_campanha_execucao_dest_canal') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_envio ' +
        'ADD UNIQUE KEY uq_campanha_execucao_dest_canal ' +
        '(id_execucao,id_destinatario,canal)'
      );

    if not IndexExists('plataforma_campanha_envio','ix_campanha_envio_execucao_situacao') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_envio ' +
        'ADD KEY ix_campanha_envio_execucao_situacao (id_execucao,situacao,id)'
      );

    if not ConstraintExists('plataforma_campanha_envio','fk_campanha_envio_execucao') then
      ExecSQL(
        'ALTER TABLE plataforma_campanha_envio ' +
        'ADD CONSTRAINT fk_campanha_envio_execucao ' +
        'FOREIGN KEY (id_execucao) REFERENCES plataforma_campanha_execucao(id) ' +
        'ON UPDATE RESTRICT ON DELETE CASCADE'
      );

    ExecSQL(
      'ALTER TABLE plataforma_campanha_envio ' +
      'MODIFY COLUMN id_execucao BIGINT UNSIGNED NOT NULL AFTER id_campanha'
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

class procedure TPlataformaCampanhaWorker.Start;
var
  Worker: TThread;
begin
  // Deve ocorrer antes da thread para impedir processamento com schema incompleto.
  RunMigration063;

  Worker :=
    TThread.CreateAnonymousThread(
      procedure
      begin
        while True do
        begin
          try
            TPlataformaCampanhaService.ProcessarProximo;
          except
            // O worker não pode derrubar a API.
            // Falhas individuais são persistidas na própria fila.
          end;

          TThread.Sleep(1500);
        end;
      end
    );

  Worker.FreeOnTerminate := True;
  Worker.Start;
end;

end.
