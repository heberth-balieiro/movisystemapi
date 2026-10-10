-- ETAPA 2 - Configuracao SMTP por empresa
-- Aplicacao idempotente: a API tambem garante a existencia da tabela antes do uso.

CREATE TABLE IF NOT EXISTS empresa_email_configuracao (
  empresa_id INT NOT NULL,
  ativo TINYINT(1) NOT NULL DEFAULT 0,
  smtp_host VARCHAR(255) NOT NULL DEFAULT '',
  smtp_porta SMALLINT UNSIGNED NOT NULL DEFAULT 587,
  seguranca VARCHAR(20) NOT NULL DEFAULT 'STARTTLS',
  usuario VARCHAR(254) NOT NULL DEFAULT '',
  senha_criptografada VARBINARY(4096) NULL,
  senha_hint VARCHAR(16) NULL,
  remetente_nome VARCHAR(180) NOT NULL DEFAULT '',
  remetente_email VARCHAR(254) NOT NULL DEFAULT '',
  responder_para VARCHAR(254) NULL,
  criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (empresa_id),
  CONSTRAINT fk_empresa_email_configuracao_empresa
    FOREIGN KEY (empresa_id) REFERENCES empresa(id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
