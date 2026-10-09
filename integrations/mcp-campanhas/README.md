# MoviSystem — MCP de campanhas (fase 1)

Servidor MCP **stdio**, Node.js 20+, sem dependências externas. Reutiliza os endpoints atuais da API Delphi, sem alterar o worker, o banco ou o frontend.

## Configuração

Variáveis de ambiente do processo MCP:

- `MOVISYSTEM_API_URL`: origem da API, ex. `https://api-homologacao.exemplo.com` (sem `/v1`).
- `MOVISYSTEM_API_TOKEN`: JWT válido de uma conta `SUPER_ADMIN` da plataforma.
- `MOVISYSTEM_ALLOW_HTTP_LOCAL=true`: opcional, permite HTTP **somente** em localhost para testes locais.

Inicie com `node integrations/mcp-campanhas/server.mjs`. No cliente MCP, configure o comando `node`, o caminho absoluto do script e as variáveis de ambiente **fora do repositório**. Não versionar tokens.

## Ferramentas

- `criar_rascunho_campanha`: POST `/v1/certifica/plataforma/campanhas`, sempre `tipo_envio=IMEDIATO`, sem chamar `/iniciar`. Aceita `WHATSAPP`, `EMAIL` e `AMBOS`.
- `consultar_campanha`: GET `/v1/certifica/plataforma/campanhas/:id`.

## Segurança e limitações

A API existente valida JWT e role `SUPER_ADMIN`. Esta primeira versão **não** implementa OAuth para conexão remota ao ChatGPT; é um servidor MCP local/stdio. O token deve ser pessoal, restrito e protegido. Não expor este processo publicamente.

A criação de rascunhos ainda não tem chave de idempotência: em caso de timeout, consulte o painel antes de repetir a criação, para evitar duplicação. Não há ferramenta de iniciar, disparar, importar destinatários ou anexar imagens.

## Homologação

1. Execute `node --check integrations/mcp-campanhas/server.mjs`.
2. Configure URL HTTPS de homologação e JWT `SUPER_ADMIN`.
3. Teste `tools/list`, criação de rascunho e consulta.
4. Confirme no painel que a campanha permanece `RASCUNHO` e que **não houve envios**.
5. Teste token inválido/sem role; ambos devem ser rejeitados.
