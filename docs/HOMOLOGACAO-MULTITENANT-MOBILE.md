# Homologação Multi-tenant e Mobile

## Objetivo

Validar o MoviSystem Certifica antes do go-live, com foco em:

- isolamento entre instituições;
- permissões;
- segurança de certificados;
- LGPD/auditoria;
- responsividade em dispositivos móveis.

## Status

Legenda:

- `OK ESTÁTICO`: revisão de código concluída sem evidência de falha.
- `PENDENTE MANUAL`: precisa ser validado em execução.
- `CRÍTICO`: qualquer falha deve bloquear o go-live.

---

## 1. Multi-tenant

### Participantes

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- listagem filtrada por `id_instituicao`;
- busca por ID filtrada por `id_instituicao`;
- atualização e situação filtradas por tenant;
- CPF/matrícula verificados dentro da instituição;
- vínculos com unidade e usuário validados pelo mesmo tenant.

Teste manual:
1. Criar participante na Instituição A.
2. Entrar na Instituição B.
3. Confirmar que não aparece na listagem.
4. Tentar acessar diretamente o ID da A.
5. Esperado: não encontrado/bloqueado.

Severidade se falhar: **CRÍTICO**.

### Usuários

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- vínculo administrativo parte de `usuario_instituicao`;
- consultas usam `id_instituicao`;
- join com `usuario` ocorre após vínculo já restrito ao tenant.

Teste manual:
1. Criar usuário administrativo na A.
2. Confirmar que não aparece na B.
3. Testar acesso direto por ID.

Severidade se falhar: **CRÍTICO**.

### Cursos

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- CRUD e filtros vinculados ao tenant;
- referências usadas na turma são validadas pela instituição.

Teste manual:
- tentar consultar/editar curso da A usando sessão da B.

Severidade se falhar: **CRÍTICO**.

### Turmas

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- listagem/busca/update usam `id_instituicao`;
- curso pertence à mesma instituição;
- modelo de certificado validado pelo tenant;
- código interno é validado dentro da instituição.

Teste manual:
- tentar acessar turma de outra instituição por ID.

Severidade se falhar: **CRÍTICO**.

### Inscrições

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- consultas críticas usam `id_instituicao`;
- relações participante/turma permanecem vinculadas ao tenant.

Teste manual:
- tentar acessar/aprovar inscrição de outra instituição.

Severidade se falhar: **CRÍTICO**.

### Presenças e check-in

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- QR/check-in mantém contexto de instituição;
- inscrição, turma e presença são vinculadas ao tenant.

Teste manual:
1. Gerar QR na Instituição A.
2. Tentar registrar participante/inscrição da B.
3. Esperado: rejeitado.

Severidade se falhar: **CRÍTICO**.

### Certificados

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- busca por ID usa `id_instituicao`;
- emissão/reemissão/cancelamento respeitam tenant;
- download administrativo e do aluno validam instituição;
- participante só acessa certificado próprio;
- validação pública da home usa `slug + codigo_validacao`;
- certificado de outra instituição não deve validar na home atual.

Teste manual:
1. Certificado A na Instituição A: deve validar.
2. Mesmo código na home da B: deve retornar não encontrado.
3. Usuário B tentando PDF da A: bloqueado.
4. Participante B tentando certificado do participante A: bloqueado.

Severidade se falhar: **CRÍTICO**.

### Auditoria / LGPD

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- consulta da auditoria exige `id_instituicao`;
- solicitações LGPD vinculadas ao tenant;
- operações sensíveis possuem auditoria;
- middleware não persiste body, senha, token ou CPF.

Teste manual:
- comparar logs da A e B;
- confirmar ausência total de registros cruzados.

Severidade se falhar: **CRÍTICO**.

### Módulos

Status: **PENDENTE MANUAL**

Teste:
1. Desabilitar CERTIFICA na Instituição A.
2. Confirmar menus ocultos.
3. Confirmar bloqueio de acesso direto às rotas do módulo.
4. Instituição B com módulo ativo continua funcionando.

Severidade se falhar: **ALTA**.

---

## 2. Mobile / Responsividade

Larguras mínimas para homologação:

- 360px;
- 390px;
- 430px;
- 768px;
- desktop de referência.

### Estrutura

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- AdminShell usa drawer no mobile;
- StudentShell usa drawer lateral com `max-w-[88vw]`;
- conteúdo principal usa `min-w-0`;
- paddings reduzem em telas menores.

### Home pública

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Validar:
- header;
- hero;
- acesso rápido;
- validar certificado;
- cursos;
- jornada;
- rodapé;
- botão WhatsApp.

### Login / Primeiro acesso

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- formulário com `w-full max-w-md`;
- padding responsivo;
- sem largura fixa incompatível.

Validar:
- teclado mobile;
- campos;
- botão;
- mensagens de erro;
- rolagem quando teclado estiver aberto.

### Área do aluno

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Validar:
- dashboard;
- cursos;
- inscrições;
- check-in;
- certificados;
- perfil;
- privacidade/LGPD;
- menu drawer.

### Certificados do aluno

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- cards responsivos;
- ações empilham antes de `sm`;
- detalhe usa grid adaptativo.

Validar:
- download em Android/iOS;
- nome do arquivo;
- retorno após download.

### Administração

Status: **OK ESTÁTICO / PENDENTE MANUAL**

Revisado:
- tabelas usam componente com scroll horizontal;
- filtros usam grids responsivos;
- menu vira drawer em telas pequenas.

Validar:
- participantes;
- cursos;
- turmas;
- presenças;
- certificados;
- processamento;
- perfis/permissões;
- configurações;
- auditoria;
- LGPD.

---

## 3. Pontos internos observados

As filas internas:

- `certificado_processamento`;
- `certificado_notificacao`;

possuem algumas atualizações internas pelo ID primário da fila.

Esses IDs são obtidos pelo próprio worker e não são fornecidos por usuários ou endpoints públicos, portanto não foi identificado vetor direto de acesso cross-tenant.

Mesmo assim, pode ser feito endurecimento posterior adicionando `id_instituicao` também aos updates internos para manter uniformidade defensiva.

Não é bloqueador para a homologação atual.

---

## 4. Critérios para go-live

Bloquear produção se ocorrer qualquer um destes cenários:

- instituição acessa dados de outra;
- participante acessa certificado de outro;
- PDF de outro tenant pode ser baixado;
- QR registra presença cruzada;
- validação institucional aceita certificado de outro tenant;
- usuário sem permissão executa operação administrativa;
- CPF/token/senha aparece em auditoria;
- tela principal fica inutilizável em 360px.

---

## 5. Resultado da revisão técnica atual

Até o momento:

**Nenhum vazamento multi-tenant crítico foi encontrado na revisão estática.**

**Nenhum problema estrutural mobile crítico foi identificado na revisão estática.**

Próxima fase obrigatória:

**homologação manual em execução com duas instituições e dispositivos/larguras reais.**
