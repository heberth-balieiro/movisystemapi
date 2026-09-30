# Revisão final de configurações e segurança

## Status atual

A revisão técnica de produção verificou:

- carregamento do Config.ini;
- JWT;
- isolamento multi-tenant;
- rate limit;
- CORS;
- headers de segurança;
- segredos SMTP/WhatsApp;
- geração de certificados;
- logs/auditoria;
- configuração do frontend.

## Ajustes aplicados

### Ambiente

O Config.ini passa a aceitar:

```ini
[APP]
Ambiente=DESENVOLVIMENTO
RunDemoSeeds=0
```

Valores permitidos para Ambiente:

- DESENVOLVIMENTO
- PRODUCAO

Quando não informado, permanece DESENVOLVIMENTO para preservar o ambiente local.

### Produção

Em PRODUCAO a API exige:

- senha do banco configurada;
- JWT.Secret com pelo menos 32 caracteres;
- WEB.PublicURL usando HTTPS;
- SECURITY.CorsAllowedOrigin informado e usando HTTPS;
- RateLimitEnabled habilitado;
- RunDemoSeeds desabilitado;
- PublicValidationBaseUrl de certificados usando HTTPS;
- configuração válida de StoragePath, qrencode e Chromium.

### Demo seeds

Os seeds de demonstração não rodam mais automaticamente.

Só executam quando:

```ini
[APP]
RunDemoSeeds=1
```

Em PRODUCAO esse valor é rejeitado.

### CORS

O middleware permissivo padrão do Horse foi removido.

Nova configuração:

```ini
[SECURITY]
CorsAllowedOrigin=https://SEU_FRONTEND
```

Em desenvolvimento pode ser usado `*`.

Em produção, `*` é rejeitado.

Métodos permitidos:

- GET
- POST
- PUT
- PATCH
- DELETE
- OPTIONS

Headers aceitos:

- Authorization
- Content-Type
- Accept

### Rate limit

Em PRODUCAO:

```ini
[SECURITY]
RateLimitEnabled=1
```

é obrigatório.

O rate limit atual é em memória e atende o MVP com uma instância da API.

Se futuramente houver múltiplas instâncias da API, migrar o contador para Redis ou serviço compartilhado.

### Headers da API

A API envia:

- X-Content-Type-Options: nosniff
- X-Frame-Options: DENY
- Referrer-Policy: no-referrer
- Permissions-Policy
- Content-Security-Policy restritiva para respostas da API
- Strict-Transport-Security em PRODUCAO

### Segredos

Config.ini permanece ignorado pelo Git.

Também são ignorados:

- .env
- chaves privadas;
- certificados;
- arquivos .pfx/.p12;
- dumps e backups.

Os segredos de SMTP e WhatsApp exigem no mínimo 32 caracteres.

Nunca incluir credenciais reais em commits.

## Configuração mínima recomendada no servidor

```ini
[APP]
Produto=MOVISYSTEM
Ambiente=PRODUCAO
RunDemoSeeds=0

[SECURITY]
RateLimitEnabled=1
TrustProxyHeaders=0
CorsAllowedOrigin=https://SEU_FRONTEND
WhatsAppTokenSecret=<SEGREDO_FORTE>
EmailSmtpSecret=<SEGREDO_FORTE>

[WEB]
PublicURL=https://SEU_FRONTEND

[JWT]
Secret=<SEGREDO_ALEATORIO_COM_32_OU_MAIS_CARACTERES>
Issuer=MOVISYSTEM
TTL_Minutos=120
TTL_Admin_Minutos=120

[CERTIFICADO_DOCUMENTO]
StoragePath=/CAMINHO/FORA/DA/PASTA_PUBLICA
PublicValidationBaseUrl=https://SEU_FRONTEND
QrEncodeExecutable=/usr/bin/qrencode
ChromiumExecutable=/usr/bin/chromium
ChromiumArgs=--headless --disable-gpu --no-pdf-header-footer
```

As credenciais MySQL devem ficar somente no Config.ini real do servidor.

## Frontend

Em produção passam a ser obrigatórias:

```
NEXT_PUBLIC_API_URL
NEXT_PUBLIC_APP_URL
```

Ambas precisam utilizar HTTPS.

O frontend não usa mais silenciosamente o IP local caso a variável de produção esteja ausente.

Também foram adicionados headers:

- X-Content-Type-Options
- X-Frame-Options
- Referrer-Policy
- Permissions-Policy
- HSTS em produção

O header `X-Powered-By` do Next.js foi desabilitado.

## Ponto de evolução

Atualmente o JWT do frontend é persistido em localStorage.

Para o MVP isso permanece inalterado para não trocar a arquitetura de autenticação no fechamento do projeto.

Evolução recomendada:

- cookie HttpOnly;
- Secure;
- SameSite;
- revisão de CSRF;
- ajuste do fluxo de login/logout.

Essa mudança deve ser tratada em demanda própria.

## Senhas

As senhas usam:

- PBKDF2-HMAC-SHA256;
- salt aleatório;
- comparação em tempo constante;
- fonte criptograficamente segura de aleatoriedade em Windows e Linux.

A quantidade de iterações está registrada no próprio hash, permitindo evolução futura sem invalidar hashes existentes.

## Checklist antes do go-live

- Config.ini real fora do Git.
- APP.Ambiente=PRODUCAO.
- APP.RunDemoSeeds=0.
- JWT.Secret forte e exclusivo.
- Banco com usuário exclusivo da aplicação.
- RateLimitEnabled=1.
- CorsAllowedOrigin com domínio real do frontend.
- WEB.PublicURL HTTPS.
- NEXT_PUBLIC_API_URL HTTPS.
- NEXT_PUBLIC_APP_URL HTTPS.
- SPF/DKIM/DMARC revisados.
- WhatsApp Evolution validado.
- Chromium e qrencode instalados.
- StoragePath existente e gravável somente pelo serviço da API.
- HTTPS/Cloudflare/Nginx validados.
- Homologação multi-tenant manual concluída.
- Homologação mobile concluída.
- Backup/restauração ainda pendentes conforme planejamento do projeto.
