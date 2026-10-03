unit Contratos.Migration;

interface

uses
  Uni,
  App.Config;

type
  TContratosMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class function ColumnExists(const AConn: TUniConnection; const ATable, AColumn: string): Boolean; static;
    class procedure AddColumnIfMissing(const AConn: TUniConnection; const ATable, AColumn, ADefinition: string); static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;
    class procedure Migration_001_Core(const AConn: TUniConnection); static;
    class procedure Migration_002_DocumentosHistoricoSituacao(const AConn: TUniConnection); static;
  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
  end;

implementation

uses
  Database.Connection;

class procedure TContratosMigration.ExecSQL(const AConn: TUniConnection; const ASQL: string);
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

class function TContratosMigration.MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'SELECT 1 FROM schema_migrations WHERE version=:version LIMIT 1';
    Qry.ParamByName('version').AsString := AVersion;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;


class function TContratosMigration.ColumnExists(
  const AConn: TUniConnection;
  const ATable, AColumn: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM information_schema.columns ' +
      'WHERE table_schema=DATABASE() AND table_name=:tabela AND column_name=:coluna LIMIT 1';
    Qry.ParamByName('tabela').AsString := ATable;
    Qry.ParamByName('coluna').AsString := AColumn;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TContratosMigration.AddColumnIfMissing(
  const AConn: TUniConnection;
  const ATable, AColumn, ADefinition: string
);
begin
  if not ColumnExists(AConn, ATable, AColumn) then
    ExecSQL(
      AConn,
      'ALTER TABLE ' + ATable +
      ' ADD COLUMN ' + AColumn + ' ' + ADefinition
    );
end;

class procedure TContratosMigration.RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'INSERT INTO schema_migrations(version,description) VALUES(:version,:description)';
    Qry.ParamByName('version').AsString := AVersion;
    Qry.ParamByName('description').AsString := ADescription;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TContratosMigration.Migration_001_Core(const AConn: TUniConnection);
const
  VERSION = 'CONTRATOS_001';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_entidade (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' tipo_pessoa VARCHAR(10) NOT NULL DEFAULT ''JURIDICA'',' +
    ' documento VARCHAR(20) NULL,' +
    ' nome VARCHAR(180) NOT NULL,' +
    ' nome_fantasia VARCHAR(180) NULL,' +
    ' email VARCHAR(254) NULL,' +
    ' telefone VARCHAR(30) NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''ATIVA'',' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' UNIQUE KEY uq_contrato_entidade_tenant_id(id_instituicao,id),' +
    ' UNIQUE KEY uq_contrato_entidade_documento(id_instituicao,documento),' +
    ' KEY ix_contrato_entidade_nome(id_instituicao,nome),' +
    ' CONSTRAINT fk_contrato_entidade_instituicao FOREIGN KEY(id_instituicao) REFERENCES instituicao(id) ON DELETE CASCADE,' +
    ' CONSTRAINT ck_contrato_entidade_tipo CHECK(tipo_pessoa IN(''FISICA'',''JURIDICA'')),' +
    ' CONSTRAINT ck_contrato_entidade_situacao CHECK(situacao IN(''ATIVA'',''INATIVA''))' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_entidade BIGINT UNSIGNED NOT NULL,' +
    ' codigo_publico CHAR(26) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,' +
    ' numero VARCHAR(80) NOT NULL,' +
    ' numero_externo VARCHAR(80) NULL,' +
    ' tipo_gestao VARCHAR(20) NOT NULL DEFAULT ''PUBLICA'',' +
    ' tipo VARCHAR(40) NOT NULL DEFAULT ''SERVICO'',' +
    ' titulo VARCHAR(180) NOT NULL,' +
    ' objeto TEXT NOT NULL,' +
    ' numero_processo VARCHAR(80) NULL,' +
    ' ano_processo SMALLINT UNSIGNED NULL,' +
    ' origem_contratacao VARCHAR(40) NULL,' +
    ' modalidade VARCHAR(80) NULL,' +
    ' numero_licitacao VARCHAR(80) NULL,' +
    ' identificador_pncp VARCHAR(120) NULL,' +
    ' url_pncp VARCHAR(1000) NULL,' +
    ' data_assinatura DATE NULL,' +
    ' data_inicio DATE NOT NULL,' +
    ' data_fim DATE NOT NULL,' +
    ' valor_inicial DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' valor_atual DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' periodicidade VARCHAR(20) NULL,' +
    ' unidade_responsavel VARCHAR(180) NULL,' +
    ' observacao TEXT NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''RASCUNHO'',' +
    ' criado_por BIGINT UNSIGNED NOT NULL,' +
    ' atualizado_por BIGINT UNSIGNED NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' encerrado_em DATETIME(3) NULL,' +
    ' PRIMARY KEY(id),' +
    ' UNIQUE KEY uq_contrato_tenant_id(id_instituicao,id),' +
    ' UNIQUE KEY uq_contrato_codigo_publico(codigo_publico),' +
    ' UNIQUE KEY uq_contrato_numero(id_instituicao,numero),' +
    ' KEY ix_contrato_vigencia(id_instituicao,data_fim,situacao),' +
    ' KEY ix_contrato_entidade(id_instituicao,id_entidade),' +
    ' CONSTRAINT fk_contrato_instituicao FOREIGN KEY(id_instituicao) REFERENCES instituicao(id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_entidade FOREIGN KEY(id_instituicao,id_entidade) REFERENCES contrato_entidade(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT fk_contrato_criado_por FOREIGN KEY(id_instituicao,criado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT fk_contrato_atualizado_por FOREIGN KEY(id_instituicao,atualizado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contrato_tipo_gestao CHECK(tipo_gestao IN(''PUBLICA'',''PRIVADA'')),' +
    ' CONSTRAINT ck_contrato_situacao CHECK(situacao IN(''RASCUNHO'',''ATIVO'',''ENCERRADO'',''CANCELADO'')),' +
    ' CONSTRAINT ck_contrato_datas CHECK(data_fim>=data_inicio)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_responsavel (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' id_usuario_instituicao BIGINT UNSIGNED NULL,' +
    ' nome VARCHAR(180) NOT NULL,' +
    ' funcao VARCHAR(30) NOT NULL,' +
    ' numero_designacao VARCHAR(100) NULL,' +
    ' data_inicio DATE NULL,' +
    ' data_fim DATE NULL,' +
    ' ativo TINYINT(1) NOT NULL DEFAULT 1,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' KEY ix_contrato_responsavel(id_instituicao,id_contrato,funcao,ativo),' +
    ' CONSTRAINT fk_contrato_responsavel_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_responsavel_usuario FOREIGN KEY(id_instituicao,id_usuario_instituicao) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contrato_responsavel_funcao CHECK(funcao IN(''GESTOR'',''FISCAL'',''SUPLENTE''))' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_documento (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' tipo VARCHAR(40) NOT NULL,' +
    ' nome VARCHAR(255) NOT NULL,' +
    ' arquivo_url VARCHAR(1000) NOT NULL,' +
    ' observacao VARCHAR(500) NULL,' +
    ' enviado_por BIGINT UNSIGNED NOT NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' KEY ix_contrato_documento(id_instituicao,id_contrato,tipo),' +
    ' CONSTRAINT fk_contrato_documento_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_documento_usuario FOREIGN KEY(id_instituicao,enviado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_aditivo (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' numero VARCHAR(80) NOT NULL,' +
    ' tipo VARCHAR(30) NOT NULL,' +
    ' data_assinatura DATE NULL,' +
    ' nova_data_fim DATE NULL,' +
    ' valor_acrescimo DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' valor_supressao DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' justificativa TEXT NULL,' +
    ' criado_por BIGINT UNSIGNED NOT NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' UNIQUE KEY uq_contrato_aditivo_numero(id_instituicao,id_contrato,numero),' +
    ' CONSTRAINT fk_contrato_aditivo_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_aditivo_usuario FOREIGN KEY(id_instituicao,criado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contrato_aditivo_tipo CHECK(tipo IN(''PRAZO'',''VALOR'',''PRAZO_VALOR'',''OUTRO''))' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_fiscalizacao (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' data_ocorrencia DATE NOT NULL,' +
    ' tipo VARCHAR(40) NOT NULL,' +
    ' descricao TEXT NOT NULL,' +
    ' providencia TEXT NULL,' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''ABERTA'',' +
    ' registrado_por BIGINT UNSIGNED NOT NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' KEY ix_contrato_fiscalizacao(id_instituicao,id_contrato,situacao,data_ocorrencia),' +
    ' CONSTRAINT fk_contrato_fiscalizacao_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_fiscalizacao_usuario FOREIGN KEY(id_instituicao,registrado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contrato_fiscalizacao_situacao CHECK(situacao IN(''ABERTA'',''EM_TRATAMENTO'',''RESOLVIDA'',''CANCELADA''))' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_alerta (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' tipo VARCHAR(30) NOT NULL DEFAULT ''VENCIMENTO'',' +
    ' dias_antecedencia INT NOT NULL,' +
    ' ativo TINYINT(1) NOT NULL DEFAULT 1,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' UNIQUE KEY uq_contrato_alerta(id_instituicao,id_contrato,tipo,dias_antecedencia),' +
    ' CONSTRAINT fk_contrato_alerta_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_projecao (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' competencia DATE NOT NULL,' +
    ' valor_previsto DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' valor_realizado DECIMAL(18,2) NOT NULL DEFAULT 0,' +
    ' origem VARCHAR(20) NOT NULL DEFAULT ''AUTOMATICA'',' +
    ' observacao VARCHAR(500) NULL,' +
    ' atualizado_por BIGINT UNSIGNED NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' atualizado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' UNIQUE KEY uq_contrato_projecao(id_instituicao,id_contrato,competencia),' +
    ' KEY ix_contrato_projecao_competencia(id_instituicao,competencia),' +
    ' CONSTRAINT fk_contrato_projecao_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_projecao_usuario FOREIGN KEY(id_instituicao,atualizado_por) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT,' +
    ' CONSTRAINT ck_contrato_projecao_origem CHECK(origem IN(''AUTOMATICA'',''MANUAL'',''ADITIVO''))' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_projecao_historico (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' id_projecao BIGINT UNSIGNED NULL,' +
    ' competencia DATE NOT NULL,' +
    ' valor_previsto DECIMAL(18,2) NOT NULL,' +
    ' valor_realizado DECIMAL(18,2) NOT NULL,' +
    ' evento VARCHAR(30) NOT NULL,' +
    ' usuario BIGINT UNSIGNED NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' KEY ix_contrato_projecao_hist(id_instituicao,id_contrato,criado_em),' +
    ' CONSTRAINT fk_contrato_projecao_hist_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_projecao_hist_usuario FOREIGN KEY(id_instituicao,usuario) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS contrato_historico (' +
    ' id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,' +
    ' id_instituicao BIGINT UNSIGNED NOT NULL,' +
    ' id_contrato BIGINT UNSIGNED NOT NULL,' +
    ' evento VARCHAR(40) NOT NULL,' +
    ' descricao VARCHAR(1000) NOT NULL,' +
    ' usuario BIGINT UNSIGNED NULL,' +
    ' criado_em DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),' +
    ' PRIMARY KEY(id),' +
    ' KEY ix_contrato_historico(id_instituicao,id_contrato,criado_em),' +
    ' CONSTRAINT fk_contrato_historico_contrato FOREIGN KEY(id_instituicao,id_contrato) REFERENCES contrato(id_instituicao,id) ON DELETE CASCADE,' +
    ' CONSTRAINT fk_contrato_historico_usuario FOREIGN KEY(id_instituicao,usuario) REFERENCES usuario_instituicao(id_instituicao,id) ON DELETE RESTRICT' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

  RegisterMigration(AConn, VERSION, 'Nucleo inicial do MoviSystem Contratos');
end;


class procedure TContratosMigration.Migration_002_DocumentosHistoricoSituacao(
  const AConn: TUniConnection
);
const
  VERSION = 'CONTRATOS_002';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  AddColumnIfMissing(AConn,'contrato_documento','storage_key','VARCHAR(1000) NULL AFTER arquivo_url');
  AddColumnIfMissing(AConn,'contrato_documento','mime_type','VARCHAR(120) NULL AFTER storage_key');
  AddColumnIfMissing(AConn,'contrato_documento','tamanho_bytes','BIGINT UNSIGNED NULL AFTER mime_type');
  AddColumnIfMissing(AConn,'contrato_documento','sha256','CHAR(64) NULL AFTER tamanho_bytes');
  AddColumnIfMissing(AConn,'contrato_documento','ativo','TINYINT(1) NOT NULL DEFAULT 1 AFTER sha256');
  AddColumnIfMissing(AConn,'contrato_documento','excluido_em','DATETIME(3) NULL AFTER ativo');
  AddColumnIfMissing(AConn,'contrato_documento','excluido_por','BIGINT UNSIGNED NULL AFTER excluido_em');

  AddColumnIfMissing(AConn,'contrato_historico','referencia_tipo','VARCHAR(40) NULL AFTER descricao');
  AddColumnIfMissing(AConn,'contrato_historico','referencia_id','BIGINT UNSIGNED NULL AFTER referencia_tipo');
  AddColumnIfMissing(AConn,'contrato_historico','detalhes_json','LONGTEXT NULL AFTER referencia_id');

  AddColumnIfMissing(AConn,'contrato','motivo_encerramento','VARCHAR(1000) NULL AFTER encerrado_em');
  AddColumnIfMissing(AConn,'contrato','cancelado_em','DATETIME(3) NULL AFTER motivo_encerramento');
  AddColumnIfMissing(AConn,'contrato','motivo_cancelamento','VARCHAR(1000) NULL AFTER cancelado_em');

  RegisterMigration(
    AConn,
    VERSION,
    'Documentos privados, historico detalhado e encerramento/cancelamento de contratos'
  );
end;

class procedure TContratosMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);
  try
    Conn.StartTransaction;
    try
      Migration_001_Core(Conn);
      Migration_002_DocumentosHistoricoSituacao(Conn);
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
