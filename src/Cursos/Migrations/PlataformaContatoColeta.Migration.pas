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
const
  VERSION = '065';
  DESCRIPTION = 'Coletas automatizadas para a base de contatos da plataforma';
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

begin
  C := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(C.Database);
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := Conn;
    if MigrationExists then
      Exit;

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

    Q.Close;
    Q.SQL.Text := 'INSERT INTO schema_migrations (version,description) VALUES (:version,:descricao)';
    Q.ParamByName('version').AsString := VERSION;
    Q.ParamByName('descricao').AsString := DESCRIPTION;
    Q.Execute;
  finally
    Q.Free;
    Conn.Free;
  end;
end;

end.
