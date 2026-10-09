# MCP de campanhas SaaS — fase 1 (somente rascunhos)

Esta integração **não altera** o worker, a fila, a Evolution API ou os controllers existentes.

## Contrato confirmado na branch develop

- `POST /v1/certifica/plataforma/campanhas`: cria campanha como `RASCUNHO`.
- `GET /v1/certifica/plataforma/campanhas/:id`: consulta campanha e situação.
- O controller exige JWT válido com role `SUPER_ADMIN`.
- O service `TPlataformaCampanhaService.Salvar` registra auditoria e cria a campanha.
- **Não** chamar `/iniciar` nesta fase.

## Ponte MCP privada

O servidor MCP (fora do processo Delphi) usará HTTPS para chamar a API existente, com token de uma conta administrativa autorizada, mantido somente no servidor e nunca exposto ao modelo.

Ferramentas da primeira fase:

1. `criar_rascunho_campanha` — recebe nome, mensagem WhatsApp e, opcionalmente, e-mail; fixa `tipo_envio=IMEDIATO` e `agendado_para=null`; cria apenas rascunho.
2. `consultar_campanha` — consulta ID existente, sem modificar nada.

A integração deve exigir confirmação humana antes de qualquer ferramenta futura de disparo, usar idempotência persistente para evitar duplicações e registrar quem solicitou a ação.

## Testes de homologação

1. Token inválido e token sem SUPER_ADMIN devem ser rejeitados.
2. Criar rascunho WHATSAPP e verificar no painel SaaS.
3. Conferir que nenhuma linha de envio foi criada na fila antes de iniciar.
4. Consultar o rascunho pelo ID.
5. Verificar auditoria e não ocorrência de disparo.
6. Somente depois de homologar, implementar anexos e destinatários.

## Observações

A primeira fase não recebe arquivos nem envia mensagens. Não armazenar tokens em repositório, logs ou prompts. Usar credenciais distintas de homologação e produção.
