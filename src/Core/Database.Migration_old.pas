unit Database.Migration;

interface

uses
  Uni,
  App.Config;

type
  TDatabaseMigration = class
  private
    class procedure ExecSQL(const AConn: TUniConnection; const ASQL: string); static;
    class function MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean; static;
    class procedure RegisterMigration(const AConn: TUniConnection; const AVersion, ADescription: string); static;

    //Criacao
    class procedure CreateMigrationTable(const AConn: TUniConnection); static;
    class procedure Migration_001_CreateEmpresaUsuario(const AConn: TUniConnection); static;
    class procedure Migration_002_CreateCategoria(const AConn: TUniConnection); static;
    class procedure Migration_003_CreateProduto(const AConn: TUniConnection); static;
    class procedure Migration_004_CreateProdutoImagem(const AConn: TUniConnection); static;
    class procedure Migration_005_CreateCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_006_CreatePedido(const AConn: TUniConnection); static;
    class procedure Migration_007_CreateRegistroEvento(const AConn: TUniConnection); static;
    class procedure Migration_008_CreateNotificacaoFila(const AConn: TUniConnection); static;
    class procedure Migration_010_CreateAjuda(const AConn: TUniConnection); static;
    class procedure Migration_011_CreatePlano(const AConn: TUniConnection); static;
    class procedure Migration_017_CreateUnidade(const AConn: TUniConnection); static;
    class procedure Migration_022_CreateCliente(const AConn: TUniConnection); static;
    class procedure Migration_027_CreateMarca(const AConn: TUniConnection); static;
    class procedure Migration_032_CreateAssinatura(const AConn: TUniConnection); static;
    class procedure Migration_033_CreateAssinaturaCobranca(const AConn: TUniConnection); static;
    class procedure Migration_035_CreateCupom(const AConn: TUniConnection); static;

    //Alteracao
    class procedure Migration_009_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_012_AlterEmpresa(const AConn: TUniConnection); static;
    class procedure Migration_013_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_014_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_015_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_016_AlterProduto(const AConn: TUniConnection); static;
    class procedure Migration_019_AlterPlano(const AConn: TUniConnection); static;
    class procedure Migration_020_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_021_AlterCatalogoConfig(const AConn: TUniConnection); static;
    class procedure Migration_023_AlterUsuario(const AConn: TUniConnection); static;
    class procedure Migration_024_AlterPedidoCliente(const AConn: TUniConnection); static;
    class procedure Migration_025_AlterConfigCliente(const AConn: TUniConnection); static;
    class procedure Migration_026_AlterPlano(const AConn: TUniConnection); static;
    class procedure Migration_028_AlterProduto(const AConn: TUniConnection); static;
    class procedure Migration_029_AlterProduto(const AConn: TUniConnection); static;
    class procedure Migration_030_AlterProduto(const AConn: TUniConnection); static;
    class procedure Migration_031_AlterProduto(const AConn: TUniConnection); static;
    class procedure Migration_034_AlterCategoria(const AConn: TUniConnection); static;
    class procedure Migration_036_AlterCatalogoConfig(const AConn: TUniConnection); static;

  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
  end;

implementation

uses
  System.SysUtils,
  Database.Connection;

class procedure TDatabaseMigration.ExecSQL(const AConn: TUniConnection; const ASQL: string);
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

class function TDatabaseMigration.MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean;
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

class procedure TDatabaseMigration.RegisterMigration(const AConn: TUniConnection;const AVersion, ADescription: string);
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

class procedure TDatabaseMigration.CreateMigrationTable(const AConn: TUniConnection);
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

class procedure TDatabaseMigration.Run(const ACfg: TAppDatabaseConfig);
var
  Conn: TUniConnection;
begin
  Conn := TDatabaseConnection.NewConnection(ACfg);
  try
    Conn.StartTransaction;
    try




      CreateMigrationTable(Conn);

      //Novas Migration
      Migration_001_CreateEmpresaUsuario(Conn);
      Migration_002_CreateCategoria(Conn);
      Migration_003_CreateProduto(Conn);
      Migration_004_CreateProdutoImagem(Conn);
      Migration_005_CreateCatalogoConfig(Conn);
      Migration_006_CreatePedido(Conn);
      Migration_007_CreateRegistroEvento(Conn);
      Migration_008_CreateNotificacaoFila(Conn);
      Migration_009_AlterCatalogoConfig(Conn);
      Migration_010_CreateAjuda(Conn);
      Migration_011_CreatePlano(Conn);
      Migration_012_AlterEmpresa(Conn);
      Migration_013_AlterCatalogoConfig(Conn);
      Migration_014_AlterCatalogoConfig(Conn);
      Migration_015_AlterCatalogoConfig(Conn);
      Migration_016_AlterProduto(Conn);
      Migration_017_CreateUnidade(Conn);
      Migration_019_AlterPlano(Conn);
      Migration_020_AlterCatalogoConfig(Conn);
      Migration_021_AlterCatalogoConfig(Conn);
      Migration_022_CreateCliente(Conn);
      Migration_023_AlterUsuario(Conn);
      Migration_024_AlterPedidoCliente(Conn);
      Migration_025_AlterConfigCliente(Conn);
      Migration_026_AlterPlano(Conn);
      Migration_027_CreateMarca(Conn);
      Migration_028_AlterProduto(Conn);
      Migration_029_AlterProduto(Conn);
      Migration_030_AlterProduto(Conn);
      Migration_031_AlterProduto(Conn);
      Migration_032_CreateAssinatura(Conn);
      Migration_033_CreateAssinaturaCobranca(Conn);
      Migration_034_AlterCategoria(Conn);
      Migration_035_CreateCupom(Conn);
      Migration_036_AlterCatalogoConfig(Conn);


      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

{$REGION 'Criação'}

class procedure TDatabaseMigration.Migration_001_CreateEmpresaUsuario(const AConn: TUniConnection);
const
  VERSION = '001';
  DESCRIPTION = 'Criar tabelas empresa e usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS empresa (' +
    ' id_empresa BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' nome VARCHAR(150) NOT NULL,' +
    ' cnpj VARCHAR(20) NOT NULL,' +
    ' cep VARCHAR(10) NULL,' +
    ' endereco VARCHAR(150) NULL,' +
    ' numero VARCHAR(20) NULL,' +
    ' complemento VARCHAR(100) NULL,' +
    ' bairro VARCHAR(100) NULL,' +
    ' cidade VARCHAR(100) NULL,' +
    ' uf VARCHAR(2) NULL,' +
    ' whatsapp VARCHAR(20) NULL,' +
    ' email VARCHAR(150) NOT NULL,' +
    ' nome_responsavel VARCHAR(120) NOT NULL,' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_validade DATE NOT NULL,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' notificar_pedido_whatsapp CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' notificar_pedido_email CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' resumo_diario CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' mensagem_modelo TEXT NULL,' +
    ' id_plano BIGINT NOT NULL, '+
    ' UNIQUE KEY uk_empresa_cnpj (cnpj),' +
    ' UNIQUE KEY uk_empresa_email (email)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS usuario (' +
    ' id_usuario BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' nome VARCHAR(120) NOT NULL,' +
    ' email VARCHAR(150) NOT NULL,' +
    ' senha_hash VARCHAR(255) NOT NULL,' +
    ' perfil VARCHAR(30) NOT NULL DEFAULT ''ADMIN'',' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' id_cliente BIGINT NULL'+
    ' UNIQUE KEY uk_usuario_email (email),' +
    ' CONSTRAINT fk_usuario_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_002_CreateCategoria(const AConn: TUniConnection);
const
  VERSION = '002';
  DESCRIPTION = 'Criar tabela categoria';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS categoria (' +
    ' id_categoria BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' nome VARCHAR(120) NOT NULL,' +
    ' descricao VARCHAR(255) NULL,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' ordem INT NOT NULL DEFAULT 0,' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' imagem_url VARCHAR(500) NULL, '+
    ' CONSTRAINT fk_categoria_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +
    ' INDEX idx_categoria_empresa (id_empresa)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_003_CreateProduto(const AConn: TUniConnection);
const
  VERSION = '003';
  DESCRIPTION = 'Criar tabela produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS produto (' +
    ' id_produto BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' id_categoria BIGINT NOT NULL,' +

    ' nome VARCHAR(150) NOT NULL,' +
    ' descricao TEXT NULL,' +
    ' preco DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' destaque CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' ordem INT NOT NULL DEFAULT 0,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' codigo VARCHAR(25) NULL, '+
    ' id_unidade BIGINT NOT NULL, '+
    ' id_marca BIGINT NOT NULL, '+
    ' promocao DECIMAL(15,2) DEFAULT 0, '+
    ' referencia VARCHA(60) NULL, '+
    ' tags (VARCHAR(80) NULL, '+

    ' CONSTRAINT fk_produto_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria)' +
    ' REFERENCES categoria(id_categoria)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' INDEX idx_produto_empresa (id_empresa),' +
    ' INDEX idx_produto_categoria (id_categoria)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_004_CreateProdutoImagem(const AConn: TUniConnection);
const
  VERSION = '004';
  DESCRIPTION = 'Criar tabela produto_imagem';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS produto_imagem (' +
    ' id_imagem BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' id_produto BIGINT NOT NULL,' +

    ' url_imagem VARCHAR(500) NOT NULL,' +
    ' principal CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' ordem INT NOT NULL DEFAULT 0,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' CONSTRAINT fk_produto_imagem_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_produto_imagem_produto FOREIGN KEY (id_produto)' +
    ' REFERENCES produto(id_produto)' +
    ' ON DELETE CASCADE ON UPDATE CASCADE,' +

    ' INDEX idx_produto_imagem_empresa (id_empresa),' +
    ' INDEX idx_produto_imagem_produto (id_produto)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_005_CreateCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '005';
  DESCRIPTION = 'Criar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS catalogo_config (' +
    ' id_config BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +

    ' slug VARCHAR(120) NOT NULL,' +
    ' titulo_catalogo VARCHAR(150) NOT NULL,' +
    ' descricao TEXT NULL,' +

    ' cor_primaria VARCHAR(20) NULL,' +
    ' cor_secundaria VARCHAR(20) NULL,' +
    ' logo_url VARCHAR(500) NULL,' +
    ' banner_url VARCHAR(500) NULL,' +

    ' mostrar_preco CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' permitir_observacao CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' permitir_retirada CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' permitir_entrega CHAR(1) NOT NULL DEFAULT ''N'',' +

    ' valor_minimo_pedido DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' url_whatsapp VARCHAR(500) NULL,'+
    ' instancia_whatsapp VARCHAR(250) NULL,'+
    ' token_whatsapp VARCHAR(500) NULL,'+
    ' apikey_whatsapp VARCHAR(250) NULL,'+
    ' facebook_url VARCHAR(200) NULL,'+
    ' instagram_url VARCHAR(200) NULL,'+
    ' tiktok_url VARCHAR(200) NULL,'+
    ' youtube_url VARCHAR(200) NULL,'+
    ' imagens_destaque VARCHAR(500) NULL,'+
    ' permitir_ficha CHAR(1) NOT NULL DEFAULT ''N'','+
    ' ecommerce CHAR(1) NOT NULL DEFAULT ''N'','+
    ' pagseguro CHAR(1) NOT NULL DEFAULT ''N'','+
    ' pagseguro_token VARCHAR(500) NULL,'+
    ' pagseguro_ambiente VARCHAR(20) NOT NULL DEFAULT ''PRODUCAO'','+
    ' compra_sem_cadastro CHAR(1) NOT NULL DEFAULT ''S'','+
    ' exigir_cliente_cadastrado CHAR(1) NOT NULL DEFAULT ''N'','+
    ' permitir_consignado CHAR(1) NOT NULL DEFAULT ''N'','+
    ' links_sobrenos VARCHAR(500) null,     '+
    ' links_privacidade VARCHAR(500) null,  '+
    ' links_termos VARCHAR(500) null,       '+

    ' CONSTRAINT fk_catalogo_config_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' UNIQUE KEY uk_catalogo_config_empresa (id_empresa),' +
    ' UNIQUE KEY uk_catalogo_config_slug (slug),' +
    ' INDEX idx_catalogo_config_slug (slug)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_006_CreatePedido(const AConn: TUniConnection);
const
  VERSION = '006';
  DESCRIPTION = 'Criar tabelas pedido e pedido_item';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS pedido (' +
    ' id_pedido BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +

    ' nome_cliente VARCHAR(120) NOT NULL,' +
    ' whatsapp_cliente VARCHAR(20) NOT NULL,' +
    ' email_cliente VARCHAR(150) NULL,' +

    ' observacao TEXT NULL,' +
    ' tipo_entrega VARCHAR(20) NOT NULL DEFAULT ''RETIRADA'',' +
    ' endereco_entrega VARCHAR(255) NULL,' +

    ' status VARCHAR(30) NOT NULL DEFAULT ''NOVO'',' +
    ' valor_total DECIMAL(15,2) NOT NULL DEFAULT 0,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' id_cliente BIGINT NULL,'+
    ' tipo_pedido VARCHAR(20) NOT NULL DEFAULT ''ORCAMENTO'', '+

    ' CONSTRAINT fk_pedido_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' INDEX idx_pedido_empresa (id_empresa),' +
    ' INDEX idx_pedido_status (status),' +
    ' INDEX idx_pedido_data_criacao (data_criacao)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS pedido_item (' +
    ' id_item BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_pedido BIGINT NOT NULL,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' id_produto BIGINT NOT NULL,' +

    ' nome_produto VARCHAR(150) NOT NULL,' +
    ' quantidade DECIMAL(15,3) NOT NULL DEFAULT 1,' +
    ' valor_unitario DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' valor_total DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' observacao TEXT NULL,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +

    ' CONSTRAINT fk_pedido_item_pedido FOREIGN KEY (id_pedido)' +
    ' REFERENCES pedido(id_pedido)' +
    ' ON DELETE CASCADE ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_pedido_item_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_pedido_item_produto FOREIGN KEY (id_produto)' +
    ' REFERENCES produto(id_produto)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' INDEX idx_pedido_item_pedido (id_pedido),' +
    ' INDEX idx_pedido_item_empresa (id_empresa),' +
    ' INDEX idx_pedido_item_produto (id_produto)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_007_CreateRegistroEvento(const AConn: TUniConnection);
const
  VERSION = '007';
  DESCRIPTION = 'Criar tabela registro_evento';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS registro_evento (' +
    ' id_registro BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NULL,' +
    ' id_usuario BIGINT NULL,' +

    ' origem VARCHAR(50) NOT NULL,' +
    ' tipo VARCHAR(50) NOT NULL,' +
    ' entidade VARCHAR(50) NULL,' +
    ' id_entidade BIGINT NULL,' +

    ' titulo VARCHAR(150) NOT NULL,' +
    ' mensagem TEXT NULL,' +
    ' dados_json JSON NULL,' +

    ' nivel VARCHAR(20) NOT NULL DEFAULT ''INFO'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +

    ' CONSTRAINT fk_registro_evento_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE SET NULL ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_registro_evento_usuario FOREIGN KEY (id_usuario)' +
    ' REFERENCES usuario(id_usuario)' +
    ' ON DELETE SET NULL ON UPDATE CASCADE,' +

    ' INDEX idx_registro_empresa (id_empresa),' +
    ' INDEX idx_registro_usuario (id_usuario),' +
    ' INDEX idx_registro_origem (origem),' +
    ' INDEX idx_registro_tipo (tipo),' +
    ' INDEX idx_registro_entidade (entidade, id_entidade),' +
    ' INDEX idx_registro_data (data_criacao)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_008_CreateNotificacaoFila(const AConn: TUniConnection);
const
  VERSION = '008';
  DESCRIPTION = 'Criar tabela notificacao_fila';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS notificacao_fila (' +
    ' id_notificacao BIGINT AUTO_INCREMENT PRIMARY KEY,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' id_pedido BIGINT NULL,' +

    ' canal VARCHAR(20) NOT NULL,' +
    ' destinatario VARCHAR(150) NOT NULL,' +
    ' titulo VARCHAR(150) NOT NULL,' +
    ' mensagem TEXT NOT NULL,' +

    ' status VARCHAR(30) NOT NULL DEFAULT ''PENDENTE'',' +
    ' tentativas INT NOT NULL DEFAULT 0,' +
    ' ultimo_erro TEXT NULL,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_envio DATETIME NULL,' +
    ' data_alteracao DATETIME NULL,' +

    ' CONSTRAINT fk_notificacao_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE,' +

    ' CONSTRAINT fk_notificacao_pedido FOREIGN KEY (id_pedido)' +
    ' REFERENCES pedido(id_pedido)' +
    ' ON DELETE SET NULL ON UPDATE CASCADE,' +

    ' INDEX idx_notificacao_empresa (id_empresa),' +
    ' INDEX idx_notificacao_pedido (id_pedido),' +
    ' INDEX idx_notificacao_status (status),' +
    ' INDEX idx_notificacao_canal (canal),' +
    ' INDEX idx_notificacao_data_criacao (data_criacao)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_010_CreateAjuda(const AConn: TUniConnection);
const
  VERSION = '010';
  DESCRIPTION = 'Criar tabela ajuda';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS ajuda (' +
    ' id_ajuda BIGINT NOT NULL AUTO_INCREMENT,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' ordem INT NOT NULL DEFAULT 0,' +
    ' titulo VARCHAR(150) NOT NULL,' +
    ' url VARCHAR(500) NOT NULL,' +
    ' descricao TEXT NULL,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' PRIMARY KEY (id_ajuda),' +
    ' INDEX idx_ajuda_empresa (id_empresa),' +
    ' INDEX idx_ajuda_ordem (ordem),' +
    ' CONSTRAINT fk_ajuda_empresa FOREIGN KEY (id_empresa)' +
    ' REFERENCES empresa(id_empresa)' +
    ' ON DELETE RESTRICT ON UPDATE CASCADE' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_011_CreatePlano(const AConn: TUniConnection);
const
  VERSION = '011';
  DESCRIPTION = 'Criar tabela plano';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS plano (' +
    ' id_plano BIGINT NOT NULL AUTO_INCREMENT,' +
    ' descricao VARCHAR(150) NOT NULL,' +
    ' valor DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' catalogo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' catalogo_qtde INT NOT NULL DEFAULT 0,' +
    ' interno CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' valor_anual decimal(15,2) DEFAULT ''0.00'','+
    ' produto_qtde int DEFAULT ''0'','+
    ' recursos varchar(500) DEFAULT NULL,'+
    ' permite_produto_ilimitado char(1) NOT NULL DEFAULT ''N'','+
    ' permite_whatsapp char(1) NOT NULL DEFAULT ''S'','+
    ' permite_email char(1) NOT NULL DEFAULT ''S'', '+
    ' permite_pedido char(1) NOT NULL DEFAULT ''S'','+
    ' permite_ecommerce char(1) NOT NULL DEFAULT ''N'','+
    ' permite_pagseguro char(1) NOT NULL DEFAULT ''N'','+
    ' permite_pedido_ficha char(1) NOT NULL DEFAULT ''N'', '+
    ' permite_config_visual char(1) NOT NULL DEFAULT ''S'', '+

    ' PRIMARY KEY (id_plano),' +
    ' INDEX idx_plano_descricao (descricao),' +
    ' INDEX idx_plano_catalogo (catalogo),' +
    ' INDEX idx_plano_ativo (ativo)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_017_CreateUnidade(const AConn: TUniConnection);
const
  VERSION = '017';
  DESCRIPTION = 'Criar tabela unidade';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS unidade (' +
    ' id_unidade BIGINT NOT NULL AUTO_INCREMENT,' +
    ' sigla CHAR(3) NOT NULL,' +
    ' descricao VARCHAR(45),' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' PRIMARY KEY (id_unidade),' +
    ' UNIQUE INDEX uk_unidade_sigla (sigla),' +
    ' INDEX idx_unidade_descricao (descricao),' +
    ' INDEX idx_unidade_ativo (ativo)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_022_CreateCliente(const AConn: TUniConnection);
const
  VERSION = '022';
  DESCRIPTION = 'Criar tabela cliente';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS cliente (' +
    ' id_cliente BIGINT NOT NULL AUTO_INCREMENT,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' tipo_pessoa VARCHAR(10) NOT NULL DEFAULT ''JURIDICA'',' +
    ' nome_razao VARCHAR(150) NOT NULL,' +
    ' nome_fantasia VARCHAR(150) NULL,' +
    ' cpf_cnpj VARCHAR(20) NULL,' +
    ' rg_ie VARCHAR(30) NULL,' +
    ' telefone VARCHAR(30) NULL,' +
    ' whatsapp VARCHAR(30) NULL,' +
    ' email VARCHAR(150) NULL,' +
    ' cep VARCHAR(15) NULL,' +
    ' endereco VARCHAR(150) NULL,' +
    ' numero VARCHAR(20) NULL,' +
    ' complemento VARCHAR(100) NULL,' +
    ' bairro VARCHAR(100) NULL,' +
    ' cidade VARCHAR(100) NULL,' +
    ' uf CHAR(2) NULL,' +
    ' responsavel_nome VARCHAR(150) NULL,' +
    ' responsavel_cpf VARCHAR(20) NULL,' +
    ' responsavel_telefone VARCHAR(30) NULL,' +
    ' acesso_portal CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' ecommerce CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' consignado CHAR(1) NOT NULL DEFAULT ''N'',' +
    ' limite_consignado DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' dia_fechamento INT NULL,' +
    ' prazo_pagamento_dias INT NULL,' +
    ' status VARCHAR(20) NOT NULL DEFAULT ''ATIVO'',' +
    ' observacao TEXT NULL,' +
    ' data_cadastro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' PRIMARY KEY (id_cliente),' +
    ' INDEX idx_cliente_empresa (id_empresa),' +
    ' INDEX idx_cliente_nome (nome_razao),' +
    ' INDEX idx_cliente_cpf_cnpj (cpf_cnpj),' +
    ' INDEX idx_cliente_email (email),' +
    ' INDEX idx_cliente_status (status),' +
    ' CONSTRAINT fk_cliente_empresa ' +
    ' FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_027_CreateMarca(const AConn: TUniConnection);
const
  VERSION = '027';
  DESCRIPTION = 'Criar tabela marca';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS marca (         '+
    ' id_marca BIGINT NOT NULL AUTO_INCREMENT,      '+
    ' id_empresa BIGINT NOT NULL,                   '+
    ' nome VARCHAR(100) NOT NULL,                '+
    ' descricao VARCHAR(255),                    '+
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',      '+
    ' ordem INT NOT NULL DEFAULT 0,              '+
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,   '+
    ' data_alteracao DATETIME NULL,              '+
    ' PRIMARY KEY (id_marca),                     '+
    ' INDEX idx_marca_empresa (id_empresa),       '+
    ' INDEX idx_marca_nome (nome),                '+
    ' INDEX idx_marca_ativo (ativo),              '+
    ' CONSTRAINT fk_marca_empresa                 '+
    ' FOREIGN KEY (id_empresa)                '+
    ' REFERENCES empresa(id_empresa));  ');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_032_CreateAssinatura(const AConn: TUniConnection);
const
  VERSION = '032';
  DESCRIPTION = 'Criar tabela assinatura';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS assinatura (' +

    ' id_assinatura BIGINT NOT NULL AUTO_INCREMENT,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' id_plano BIGINT NOT NULL,' +

    ' recorrencia VARCHAR(20) NOT NULL DEFAULT ''MENSAL'',' +
    ' situacao VARCHAR(20) NOT NULL DEFAULT ''TRIAL'',' +

    ' iniciado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' trial_termina_em DATETIME NULL,' +
    ' proximo_vencimento DATETIME NULL,' +
    ' cancelado_em DATETIME NULL,' +
    ' termina_em DATETIME NULL,' +

    ' valor DECIMAL(15,2) NOT NULL DEFAULT 0,' +

    ' observacao TEXT NULL,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' PRIMARY KEY (id_assinatura),' +

    ' INDEX idx_assinatura_empresa (id_empresa),' +
    ' INDEX idx_assinatura_plano (id_plano),' +
    ' INDEX idx_assinatura_situacao (situacao),' +
    ' INDEX idx_assinatura_recorrencia (recorrencia),' +
    ' INDEX idx_assinatura_proximo_vencimento (proximo_vencimento),' +

    ' CONSTRAINT fk_assinatura_empresa ' +
    ' FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa),' +

    ' CONSTRAINT fk_assinatura_plano ' +
    ' FOREIGN KEY (id_plano) REFERENCES plano(id_plano)' +

    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_033_CreateAssinaturaCobranca(const AConn: TUniConnection);
const
  VERSION = '033';
  DESCRIPTION = 'Criar tabela assinatura_cobranca';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS assinatura_cobranca (' +

    ' id_cobranca BIGINT NOT NULL AUTO_INCREMENT,' +
    ' id_assinatura BIGINT NOT NULL,' +
    ' id_empresa BIGINT NOT NULL,' +

    ' vencimento DATETIME NOT NULL,' +
    ' pago_em DATETIME NULL,' +

    ' situacao VARCHAR(20) NOT NULL DEFAULT ''ABERTA'',' +
    ' valor DECIMAL(15,2) NOT NULL DEFAULT 0,' +

    ' descricao VARCHAR(255) NULL,' +
    ' referencia VARCHAR(20) NULL,' +

    ' forma_pagamento VARCHAR(30) NULL,' +
    ' id_transacao VARCHAR(150) NULL,' +
    ' link_pagamento VARCHAR(500) NULL,' +

    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +

    ' PRIMARY KEY (id_cobranca),' +

    ' INDEX idx_ass_cob_assinatura (id_assinatura),' +
    ' INDEX idx_ass_cob_empresa (id_empresa),' +
    ' INDEX idx_ass_cob_situacao (situacao),' +
    ' INDEX idx_ass_cob_vencimento (vencimento),' +
    ' INDEX idx_ass_cob_referencia (referencia),' +

    ' CONSTRAINT fk_ass_cob_assinatura ' +
    ' FOREIGN KEY (id_assinatura) REFERENCES assinatura(id_assinatura),' +

    ' CONSTRAINT fk_ass_cob_empresa ' +
    ' FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)' +

    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_035_CreateCupom(const AConn: TUniConnection);
const
  VERSION = '035';
  DESCRIPTION = 'Criar tabela cupom';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS cupom (' +
    ' id_cupom BIGINT NOT NULL AUTO_INCREMENT,' +
    ' id_empresa BIGINT NOT NULL,' +
    ' codigo VARCHAR(50) NOT NULL,' +
    ' descricao VARCHAR(255) NULL,' +
    ' tipo_desconto VARCHAR(20) NOT NULL DEFAULT ''PERCENTUAL'',' +
    ' valor_desconto DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' valor_minimo_pedido DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' valor_maximo_desconto DECIMAL(15,2) NOT NULL DEFAULT 0,' +
    ' limite_total INT NOT NULL DEFAULT 0,' +
    ' quantidade_utilizada INT NOT NULL DEFAULT 0,' +
    ' limite_por_cliente INT NOT NULL DEFAULT 1,' +
    ' data_inicio DATETIME NULL,' +
    ' data_fim DATETIME NULL,' +
    ' ativo CHAR(1) NOT NULL DEFAULT ''S'',' +
    ' data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    ' data_alteracao DATETIME NULL,' +
    ' PRIMARY KEY (id_cupom),' +
    ' UNIQUE KEY uk_cupom_empresa_codigo (id_empresa, codigo),' +
    ' INDEX idx_cupom_empresa (id_empresa),' +
    ' INDEX idx_cupom_codigo (codigo),' +
    ' INDEX idx_cupom_ativo (ativo),' +
    ' INDEX idx_cupom_data_fim (data_fim),' +
    ' CONSTRAINT fk_cupom_empresa ' +
    ' FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

{$ENDREGION}

{$REGION 'Alteração'}

class procedure TDatabaseMigration.Migration_009_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '009';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN url_whatsapp VARCHAR(500) NULL, ' +
    ' ADD COLUMN instancia_whatsapp VARCHAR(250) NULL, ' +
    ' ADD COLUMN token_whatsapp VARCHAR(500) NULL '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_012_AlterEmpresa(const AConn: TUniConnection);
const
  VERSION = '012';
  DESCRIPTION = 'Alterar tabela empresa';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE empresa ' +
    ' ADD COLUMN id_plano INT NULL '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_013_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '013';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN apikey_whatsapp varchar(250)'
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_014_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '014';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN facebook_url   varchar(200),  '+
    ' ADD COLUMN instagram_url  varchar(200),  '+
    ' ADD COLUMN tiktok_url     varchar(200),  '+
    ' ADD COLUMN youtube_url    varchar(200)  '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_015_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '015';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN imagens_destaque varchar(500)  '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_016_AlterProduto(const AConn: TUniConnection);
const
  VERSION = '016';
  DESCRIPTION = 'Alterar tabela produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE produto ' +
    ' ADD COLUMN codigo varchar(25),  '+
    ' ADD COLUMN id_unidade int  '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_019_AlterPlano(const AConn: TUniConnection);
const
  VERSION = '019';
  DESCRIPTION = 'Alteração tabela plano';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE plano ' +
    ' ADD COLUMN valor_anual DECIMAL(15,2) DEFAULT 0,  '+
    ' ADD COLUMN produto_qtde int DEFAULT 0,  '  +
    ' ADD COLUMN recursos varchar(500)  '
    );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_020_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '020';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN permitir_ficha CHAR(1) NOT NULL DEFAULT ''N'' ');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_021_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '021';
  DESCRIPTION = 'Alterar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

   ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN ecommerce CHAR(1) NOT NULL DEFAULT ''N'', ' +
    ' ADD COLUMN pagseguro CHAR(1) NOT NULL DEFAULT ''N'', ' +
    ' ADD COLUMN pagseguro_token VARCHAR(500) NULL, ' +
    ' ADD COLUMN pagseguro_ambiente VARCHAR(20) NOT NULL DEFAULT ''PRODUCAO'' ');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_023_AlterUsuario(const AConn: TUniConnection);
const
  VERSION = '023';
  DESCRIPTION = 'Adicionar id_cliente na tabela usuario';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE usuario ' +
    ' ADD COLUMN id_cliente BIGINT NULL, ' +
    ' ADD INDEX idx_usuario_cliente (id_cliente)'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_024_AlterPedidoCliente(const AConn: TUniConnection);
const
  VERSION = '024';
  DESCRIPTION = 'Adicionar cliente e tipo de pedido na tabela pedido';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE pedido ' +
    ' ADD COLUMN id_cliente BIGINT NULL, ' +
    ' ADD COLUMN tipo_pedido VARCHAR(20) NOT NULL DEFAULT ''ORCAMENTO'', ' +
    ' ADD INDEX idx_pedido_cliente (id_cliente), ' +
    ' ADD INDEX idx_pedido_tipo (tipo_pedido)'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);

//  ORCAMENTO
//ECOMMERCE
//CONSIGNADO

end;

class procedure TDatabaseMigration.Migration_025_AlterConfigCliente(const AConn: TUniConnection);
const
  VERSION = '025';
  DESCRIPTION = 'Adicionar regras de cliente e consignado no catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN compra_sem_cadastro CHAR(1) NOT NULL DEFAULT ''S'', ' +
    ' ADD COLUMN exigir_cliente_cadastrado CHAR(1) NOT NULL DEFAULT ''N'', ' +
    ' ADD COLUMN permitir_consignado CHAR(1) NOT NULL DEFAULT ''N'' '
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_026_AlterPlano(const AConn: TUniConnection);
const
  VERSION = '026';
  DESCRIPTION = 'Criação de novos campos tabela de plano';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE plano                               '+
    ' ADD COLUMN permite_produto_ilimitado CHAR(1) NOT NULL DEFAULT ''N'',  '+
    ' ADD COLUMN permite_whatsapp CHAR(1) NOT NULL DEFAULT ''S'',  '+
    ' ADD COLUMN permite_email CHAR(1) NOT NULL DEFAULT ''S'' ,             '+
    ' ADD COLUMN permite_pedido CHAR(1) NOT NULL DEFAULT ''S'' ,               '+
    ' ADD COLUMN permite_ecommerce CHAR(1) NOT NULL DEFAULT ''N'' ,           '+
    ' ADD COLUMN permite_pagseguro CHAR(1) NOT NULL DEFAULT ''N'' ,        '+
    ' ADD COLUMN permite_pedido_ficha CHAR(1) NOT NULL DEFAULT ''N'' ,     '+
    ' ADD COLUMN permite_config_visual CHAR(1) NOT NULL DEFAULT ''S'';');
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_028_AlterProduto(const AConn: TUniConnection);
const
  VERSION = '028';
  DESCRIPTION = 'Criação de novos campos tabela de produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE produto             '+
    ' ADD COLUMN id_marca BIGINT NULL;   ');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_029_AlterProduto(const AConn: TUniConnection);
const
  VERSION = '029';
  DESCRIPTION = 'Criação de novos campos tabela de produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE produto               '+
    ' ADD CONSTRAINT fk_produto_marca  '+
    ' FOREIGN KEY (id_marca)           '+
    ' REFERENCES marca(id_marca);');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_030_AlterProduto(const AConn: TUniConnection);
const
  VERSION = '030';
  DESCRIPTION = 'Criação de novos campos tabela de produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'CREATE INDEX idx_produto_marca   '+
    ' ON produto(id_marca);');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_031_AlterProduto(const AConn: TUniConnection);
const
  VERSION = '031';
  DESCRIPTION = 'Criação de novos campos tabela de produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE produto             '+
    ' ADD COLUMN promocao decimal(15,2) NULL DEFAULT 0, '+
    ' ADD COLUMN referencia varchar(60) NULL, '+
    ' ADD COLUMN tags varchar(80) NULL ');

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_034_AlterCategoria(const AConn: TUniConnection);
const
  VERSION = '034';
  DESCRIPTION = 'Adicionar imagem na tabela categoria';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE categoria ' +
    ' ADD COLUMN imagem_url VARCHAR(500) NULL;'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TDatabaseMigration.Migration_036_AlterCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '036';
  DESCRIPTION = 'Alteração na tabela config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
    'ALTER TABLE catalogo_config ' +
    ' ADD COLUMN links_sobrenos VARCHAR(500) NULL, '+
    ' ADD COLUMN links_privacidade VARCHAR(500) NULL, '+
    ' ADD COLUMN links_termos VARCHAR(500) NULL;'
  );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;






{$ENDREGION}




end.
