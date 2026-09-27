unit Catalogo.Migration;

interface

uses
  Uni,
  App.Config;

type
  TCatalogoMigration = class
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
    class procedure Migration_012_CreateUnidade(const AConn: TUniConnection); static;
    class procedure Migration_013_CreateCliente(const AConn: TUniConnection); static;
    class procedure Migration_014_CreateMarca(const AConn: TUniConnection); static;
    class procedure Migration_015_CreateAssinatura(const AConn: TUniConnection); static;
    class procedure Migration_016_CreateAssinaturaCobranca(const AConn: TUniConnection); static;
    class procedure Migration_017_CreateCupom(const AConn: TUniConnection); static;
    class procedure Migration_018_CreateSegmento(const Aconn: TuniConnection); static;

  public
    class procedure Run(const ACfg: TAppDatabaseConfig); static;
  end;

implementation

uses
  System.SysUtils,
  Database.Connection;

class procedure TCatalogoMigration.ExecSQL(const AConn: TUniConnection; const ASQL: string);
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

class function TCatalogoMigration.MigrationExists(const AConn: TUniConnection; const AVersion: string): Boolean;
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

class procedure TCatalogoMigration.RegisterMigration(const AConn: TUniConnection;const AVersion, ADescription: string);
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

class procedure TCatalogoMigration.CreateMigrationTable(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Run(const ACfg: TAppDatabaseConfig);
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
      Migration_010_CreateAjuda(Conn);
      Migration_011_CreatePlano(Conn);
      Migration_012_CreateUnidade(Conn);
      Migration_013_CreateCliente(Conn);
      Migration_014_CreateMarca(Conn);
      Migration_015_CreateAssinatura(Conn);
      Migration_016_CreateAssinaturaCobranca(Conn);
      Migration_017_CreateCupom(Conn);
      Migration_018_CreateSegmento(Conn);

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

class procedure TCatalogoMigration.Migration_001_CreateEmpresaUsuario(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_002_CreateCategoria(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_003_CreateProduto(const AConn: TUniConnection);
const
  VERSION = '003';
  DESCRIPTION = 'Criar tabela produto';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS produto (' +
    '`id_produto` bigint NOT NULL AUTO_INCREMENT,                       '+
    '`id_empresa` bigint NOT NULL,                                      '+
    '`id_categoria` bigint NOT NULL,                                    '+
    '`nome` varchar(150) NOT NULL,                                      '+
    '`descricao` text,                                                  '+
    '`preco` decimal(15,2) NOT NULL DEFAULT ''0.00'',                     '+
    '`ativo` char(1) NOT NULL DEFAULT ''S'',                              '+
    '`destaque` char(1) NOT NULL DEFAULT ''N'',                           '+
    '`ordem` int NOT NULL DEFAULT ''0'',                                  '+
    '`data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,        '+
    '`data_alteracao` datetime DEFAULT NULL,                            '+
    '`codigo` varchar(25) DEFAULT NULL,                                 '+
    '`id_unidade` int DEFAULT NULL,                                     '+
    '`id_marca` bigint DEFAULT NULL,                                    '+
    '`promocao` decimal(15,2) DEFAULT ''0.00'',                           '+
    '`referencia` varchar(60) DEFAULT NULL,                             '+
    '`tags` varchar(80) DEFAULT NULL,                                   '+
    'PRIMARY KEY (`id_produto`),                                        '+
    'KEY `idx_produto_empresa` (`id_empresa`),                          '+
    'KEY `idx_produto_categoria` (`id_categoria`),                      '+
    'KEY `idx_produto_marca` (`id_marca`),                              '+
    'CONSTRAINT `fk_produto_categoria` FOREIGN KEY (`id_categoria`) '+
    'REFERENCES `categoria` (`id_categoria`) ON DELETE RESTRICT ON UPDATE CASCADE, '+
    'CONSTRAINT `fk_produto_empresa` FOREIGN KEY (`id_empresa`) '+
    'REFERENCES `empresa` (`id_empresa`) ON DELETE RESTRICT ON UPDATE CASCADE, '+
    'CONSTRAINT `fk_produto_marca` FOREIGN KEY (`id_marca`) REFERENCES `marca` (`id_marca`) '+
  ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCatalogoMigration.Migration_004_CreateProdutoImagem(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_005_CreateCatalogoConfig(const AConn: TUniConnection);
const
  VERSION = '005';
  DESCRIPTION = 'Criar tabela catalogo_config';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;

  ExecSQL(AConn,
    'CREATE TABLE IF NOT EXISTS catalogo_config (' +
    '`id_config` bigint NOT NULL AUTO_INCREMENT,                  '+
    '`id_empresa` bigint NOT NULL,                                '+
    '`slug` varchar(120) NOT NULL,                                '+
    '`titulo_catalogo` varchar(150) NOT NULL,                     '+
    '`descricao` text,                                            '+
    '`cor_primaria` varchar(20) DEFAULT NULL,                     '+
    '`cor_secundaria` varchar(20) DEFAULT NULL,                   '+
    '`logo_url` varchar(500) DEFAULT NULL,                        '+
    '`banner_url` varchar(500) DEFAULT NULL,                      '+
    '`mostrar_preco` char(1) NOT NULL DEFAULT ''S'',                '+
    '`permitir_observacao` char(1) NOT NULL DEFAULT ''S'',          '+
    '`permitir_retirada` char(1) NOT NULL DEFAULT ''S'',            '+
    '`permitir_entrega` char(1) NOT NULL DEFAULT ''N'',             '+
    '`valor_minimo_pedido` decimal(15,2) NOT NULL DEFAULT ''0.00'', '+
    '`ativo` char(1) NOT NULL DEFAULT ''S'',                        '+
    '`data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,  '+
    '`data_alteracao` datetime DEFAULT NULL,                      '+
    '`url_whatsapp` varchar(500) DEFAULT NULL,                    '+
    '`instancia_whatsapp` varchar(250) DEFAULT NULL,              '+
    '`token_whatsapp` varchar(500) DEFAULT NULL,                  '+
    '`apikey_whatsapp` varchar(250) DEFAULT NULL,                 '+
    '`facebook_url` varchar(200) DEFAULT NULL,                    '+
    '`instagram_url` varchar(200) DEFAULT NULL,                   '+
    '`tiktok_url` varchar(200) DEFAULT NULL,                      '+
    '`youtube_url` varchar(200) DEFAULT NULL,                     '+
    '`imagens_destaque` varchar(500) DEFAULT NULL,                '+
    '`permitir_ficha` char(1) NOT NULL DEFAULT ''N'',               '+
    '`ecommerce` char(1) NOT NULL DEFAULT ''N'',                    '+
    '`pagseguro` char(1) NOT NULL DEFAULT ''N'',                    '+
    '`pagseguro_token` varchar(500) DEFAULT NULL,                 '+
    '`pagseguro_ambiente` varchar(20) NOT NULL DEFAULT ''PRODUCAO'','+
    '`compra_sem_cadastro` char(1) NOT NULL DEFAULT ''S'',          '+
    '`exigir_cliente_cadastrado` char(1) NOT NULL DEFAULT ''N'',    '+
    '`permitir_consignado` char(1) NOT NULL DEFAULT ''N'',          '+
    '`links_sobrenos` varchar(500) DEFAULT NULL,                  '+
    '`links_privacidade` varchar(500) DEFAULT NULL,               '+
    '`links_termos` varchar(500) DEFAULT NULL,                    '+
    '`tipo_catalogo` varchar(30) NOT NULL DEFAULT ''PEDIDO_ORCAMENTO'','+
    '`id_segmento` bigint DEFAULT NULL,                           '+
    'PRIMARY KEY (`id_config`),                                   '+
    'UNIQUE KEY `uk_catalogo_config_empresa` (`id_empresa`),      '+
    'UNIQUE KEY `uk_catalogo_config_slug` (`slug`),               '+
    'KEY `idx_catalogo_config_slug` (`slug`),                     '+
    'CONSTRAINT `fk_catalogo_config_empresa` FOREIGN KEY (`id_empresa`)  '+
    ' REFERENCES `empresa` (`id_empresa`) ON DELETE RESTRICT ON UPDATE CASCADE '+
  ')  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCatalogoMigration.Migration_006_CreatePedido(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_007_CreateRegistroEvento(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_008_CreateNotificacaoFila(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_010_CreateAjuda(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_011_CreatePlano(const AConn: TUniConnection);
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
    ' permite_config_cupom CHAR(1) NOT NULL DEFAULT ''N'', '+
    ' tipo_catalogo_padrao VARCHAR(30) NOT NULL DEFAULT ''VITRINE'', '+

    ' PRIMARY KEY (id_plano),' +
    ' INDEX idx_plano_descricao (descricao),' +
    ' INDEX idx_plano_catalogo (catalogo),' +
    ' INDEX idx_plano_ativo (ativo)' +
    ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;'
  );

  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;

class procedure TCatalogoMigration.Migration_012_CreateUnidade(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_013_CreateCliente(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_014_CreateMarca(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_015_CreateAssinatura(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_016_CreateAssinaturaCobranca(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_017_CreateCupom(const AConn: TUniConnection);
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

class procedure TCatalogoMigration.Migration_018_CreateSegmento(const Aconn: TuniConnection);
const
  VERSION = '038';
  DESCRIPTION = 'Criar tabela segmento';
begin
  if MigrationExists(AConn, VERSION) then
    Exit;
  ExecSQL(AConn,
       'CREATE TABLE IF NOT EXISTS segmento (                 '+
       'id_segmento BIGINT NOT NULL AUTO_INCREMENT,           '+
       'nome VARCHAR(100) NOT NULL,                           '+
       'descricao VARCHAR(255) NULL,                          '+
       'ativo CHAR(1) NOT NULL DEFAULT ''S'',                  '+
       'ordem INT NOT NULL DEFAULT 0,                          '+
       'data_criacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,  '+
       'data_alteracao DATETIME NULL,                              '+
       'PRIMARY KEY (id_segmento),                                 '+
       'UNIQUE KEY uk_segmento_nome (nome)                          '+
       ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'
       );
  RegisterMigration(AConn, VERSION, DESCRIPTION);
end;


{$ENDREGION}




end.
