# MVP - Fluxo configurável de turma, inscrição pública e QR Code da turma

Data: 30/09/2026

## Objetivo

Adicionar ao MoviSystem Certifica um fluxo simplificado para Educação, Câmara, Prefeitura e capacitações institucionais, sem substituir o fluxo existente baseado em encontros.

Fluxo alvo:

```
CURSO
  ↓
TURMA
  ↓
LINK PÚBLICO DE INSCRIÇÃO
  ↓
PARTICIPANTE SOLICITA INSCRIÇÃO
  ↓
INSTITUIÇÃO APROVA (ou aprovação automática configurada)
  ↓
PARTICIPANTE MATRICULADO
  ↓
QR CODE DA TURMA
  ↓
PARTICIPANTE REGISTRA PRESENÇA
  ↓
CONCLUSÃO
  ↓
CERTIFICADO
```

## Compatibilidade com o fluxo existente

O modelo por encontro não foi removido nem substituído.

Turmas existentes permanecem com:
- `aprovacao_inscricao = MANUAL`;
- `controle_presenca = ENCONTRO`.

A configuração da turma permite escolher:
- `ENCONTRO`: mantém o fluxo atual;
- `TURMA`: utiliza um QR Code único/temporário da turma;
- `SEM_CONTROLE`: não exibe controle de presença.

Os dados de encontros existentes não são excluídos quando o modo de presença é alterado.

## Banco de dados

### Migration 052 - Fluxo configurável da turma

Novas colunas em `turma`:
- `aprovacao_inscricao` - padrão `MANUAL`;
- `controle_presenca` - padrão `ENCONTRO`;
- `exigir_presenca_conclusao` - reservado para evolução das regras automáticas;
- `conclusao_automatica` - reservado para evolução;
- `certificado_automatico` - reservado para evolução.

Nesta entrega, a interface operacional expõe apenas as configurações já funcionais: aprovação da inscrição e tipo de controle de presença.

### Migration 053 - QR Code e presença direta da turma

Nova tabela `turma_checkin`:
- sessão temporária do QR;
- token armazenado somente como SHA-256;
- validade de até 30 minutos ou até o término da turma;
- abertura/encerramento controlados;
- vínculo por instituição e turma.

Nova tabela `turma_presenca`:
- uma presença por inscrição/turma;
- vínculo multi-tenant;
- origem do registro;
- usuário responsável;
- sem alteração da tabela legada `presenca`, que continua vinculada a encontro.

## API

### Turma

O CRUD de turma passou a ler/gravar:
- `aprovacao_inscricao`;
- `controle_presenca`;
- campos reservados para automações futuras.

Validações:
- aprovação: `MANUAL | AUTOMATICA`;
- presença: `ENCONTRO | TURMA | SEM_CONTROLE`.

### Inscrição

A inscrição pública autenticada reaproveita o fluxo já existente.

Quando a turma usa `MANUAL`:
- inscrição nasce como `INSCRITO`;
- instituição aprova/rejeita pelo fluxo administrativo existente.

Quando usa `AUTOMATICA`:
- inscrição é criada e confirmada na mesma transação;
- limite de participantes é validado;
- histórico registra a confirmação automática.

### Página pública da turma

Novo endpoint:

`GET /v1/certifica/publico/instituicoes/:slug/turmas/:codigo_turma`

Regras:
- instituição ativa;
- curso ativo e público;
- turma com inscrição pública;
- situação `INSCRICOES_ABERTAS`;
- período de inscrição válido;
- isolamento por `id_instituicao`;
- rate limit.

### QR Code da turma

Novos endpoints administrativos:

```
GET  /v1/certifica/instituicao/turmas/:id_turma/checkin
POST /v1/certifica/instituicao/turmas/:id_turma/checkin/abrir
POST /v1/certifica/instituicao/turmas/:id_turma/checkin/encerrar
```

Os endpoints do aluno não mudaram:

```
POST /v1/certifica/aluno/checkin/consultar
POST /v1/certifica/aluno/checkin/confirmar
```

O backend detecta se o token pertence a um encontro ou à turma.

Para registrar presença por turma são exigidos:
- token válido;
- sessão de presença aberta;
- turma em andamento e dentro do período;
- `controle_presenca = TURMA`;
- participante autenticado;
- inscrição `CONFIRMADO` ou `EM_ANDAMENTO`;
- proteção contra presença duplicada.

As ações de abertura, encerramento e presença são auditadas.

## Frontend

### Cadastro/edição da turma

Nova seção **Fluxo da turma**:
- Aprovação da inscrição:
  - Manual pela instituição;
  - Automática.
- Controle de presença:
  - Por encontro (fluxo atual);
  - QR Code da turma;
  - Sem controle de presença.

### Detalhe da turma

Quando inscrição pública está habilitada:
- botão **Copiar link de inscrição**;
- botão **Abrir inscrição pública**.

O link utiliza `codigo_publico`, não o ID sequencial.

### Página pública de inscrição

Nova rota:

`/[slug]/inscricao/[codigo]`

Exibe:
- curso;
- turma;
- modalidade;
- data/hora;
- carga horária;
- local;
- vagas;
- descrição.

O link é público, mas a solicitação de inscrição exige autenticação do participante. Após o login, o usuário retorna diretamente à turma escolhida.

Decisão de segurança/LGPD desta entrega:
- não foi criado cadastro anônimo de participante por CPF;
- primeiro acesso continua dependendo do convite/token já existente;
- evita permitir que terceiros criem inscrição utilizando CPF de outra pessoa sem validação de identidade.

### Presença

Na tela administrativa da turma:
- `ENCONTRO`: mantém o componente de encontros existente;
- `TURMA`: exibe painel para abrir/gerar/encerrar QR Code da turma;
- `SEM_CONTROLE`: informa que a turma não controla presença.

O mesmo leitor/tela do aluno aceita QR de encontro e QR de turma.

## Conclusão

O cálculo de presença foi estendido:
- `ENCONTRO`: continua usando minutos/carga horária dos encontros;
- `TURMA`: presença registrada = 100%, ausência = 0%;
- `SEM_CONTROLE`: não cria base de cálculo de presença.

As regras já existentes de critérios de conclusão e emissão de certificado foram preservadas. Os campos de automação futura não foram ativados na interface para evitar comportamento parcial.

## Segurança e multi-tenant

Foram mantidos:
- filtro por `id_instituicao`;
- código público de turma não sequencial;
- token de QR imprevisível;
- hash SHA-256 do token no banco;
- expiração automática;
- checagem de matrícula/inscrição;
- prevenção de duplicidade;
- rate limit em endpoint público;
- auditoria dos eventos de check-in;
- compatibilidade com permissões existentes de presença.

## Validação realizada

Branch utilizada em ambos os projetos: `develop`.

Base inicial validada:
- API: `20edf00e89bf492400a730e15e9e9ba7abc2d118`;
- Frontend: `763781fb52a9eb4ebae2d10c407e78000fc9f327`.

Head no momento deste relatório:
- API: `1d4a3c56d04970fac5415b16d232fbbc09fe0eac`;
- Frontend: `3545daa04502c2e67884ac68307d3f33c93f9876`.

Comparação com a base:
- API: somente à frente, sem commits atrás;
- Frontend: somente à frente, sem commits atrás.

Não há workflow GitHub Actions configurado/executado para validar esses commits.

## Testes locais obrigatórios antes da homologação

### API Delphi

1. Atualizar a branch `develop`.
2. Compilar o projeto no Delphi.
3. Subir a API e confirmar execução das migrations 052 e 053.
4. Criar uma turma nova e validar os defaults `MANUAL/ENCONTRO`.
5. Editar para `TURMA` e confirmar persistência.
6. Testar isolamento entre duas instituições.
7. Testar aprovação manual.
8. Testar aprovação automática e limite de vagas.
9. Colocar turma em `EM_ANDAMENTO`, abrir QR e registrar presença.
10. Repetir o mesmo QR para confirmar proteção contra duplicidade.
11. Encerrar/expirar QR e confirmar bloqueio.
12. Validar uma turma antiga por encontro para garantir ausência de regressão.

### Frontend

Executar:

```bash
npm run lint
npm run build
```

Depois validar:
1. criar/editar turma;
2. copiar link público;
3. abrir página pública;
4. fazer login a partir do link e confirmar retorno à turma;
5. solicitar inscrição;
6. aprovar/rejeitar no administrativo;
7. testar aprovação automática;
8. abrir QR da turma;
9. ler QR no celular;
10. confirmar presença;
11. testar o fluxo antigo por encontro.

## Próximas evoluções sugeridas

Não fazem parte desta entrega:
- cadastro público anônimo de novo participante;
- confirmação de identidade por e-mail/WhatsApp/OTP para inscrição sem login;
- automação integral da conclusão ao registrar presença;
- emissão automática do certificado imediatamente após a conclusão;
- painel específico de lista/contagem de presenças da turma;
- regras de janela de presença configuráveis por turma.

Essas evoluções podem ser adicionadas sem remover o fluxo atual.


## Complemento - Listagem administrativa de presenças

Implementado endpoint:

```
GET /v1/certifica/instituicao/turmas/:id_turma/presencas
```

Permissão exigida:
- `presenca.visualizar`.

Retorno:
- total de matriculados;
- total de presentes;
- participante;
- e-mail;
- situação da inscrição;
- situação da presença;
- horário do check-in;
- origem do registro.

No frontend, turmas configuradas com `controle_presenca = TURMA` exibem:
- painel do QR Code;
- cards de Matriculados / Presentes / Sem presença;
- tabela administrativa das presenças;
- atualização manual da lista.

A listagem considera inscrições nos estados:
- `CONFIRMADO`;
- `EM_ANDAMENTO`;
- `CONCLUIDO`.

## Homologação técnica ponta a ponta - revisão de código

Fluxo revisado:

```
Curso ativo e público
  -> Turma com inscrição pública
  -> Link público por codigo_publico
  -> Login do participante
  -> Retorno para a turma
  -> Solicitação de inscrição
  -> Aprovação manual ou automática
  -> Turma EM_ANDAMENTO
  -> Abertura do QR da turma
  -> Validação de participante e inscrição
  -> Registro único em turma_presenca
  -> Listagem administrativa
  -> Cálculo de presença para conclusão
  -> Fluxo existente de conclusão/certificado
```

Validações confirmadas por inspeção:
- isolamento por `id_instituicao`;
- inscrição pública exige curso/turma habilitados e período válido;
- aprovação automática respeita limite de vagas;
- QR da turma exige situação `EM_ANDAMENTO`;
- QR possui token imprevisível e hash persistido;
- participante precisa possuir inscrição `CONFIRMADO` ou `EM_ANDAMENTO`;
- presença possui chave única por instituição/turma/inscrição;
- reuso do QR não cria presença duplicada;
- fluxo por encontro continua separado e preservado;
- cálculo de conclusão reconhece presença direta da turma;
- listagem administrativa exige `presenca.visualizar`.

Correção encontrada durante a homologação:
- a mensagem do frontend para inscrição automática ainda informava que o participante deveria aguardar aprovação;
- agora, quando a API retorna `CONFIRMADO`, a tela informa **Inscrição confirmada com sucesso**.

### Homologação prática ainda necessária no ambiente local

A revisão de código não substitui a execução real. Validar localmente:

1. Compilar a API Delphi.
2. Confirmar migrations 052 e 053 aplicadas.
3. Criar curso ativo com inscrição pública.
4. Criar turma com:
   - inscrição pública = Sim;
   - aprovação = Manual;
   - presença = QR Code da turma.
5. Abrir inscrições e copiar o link público.
6. Entrar como participante pelo link.
7. Solicitar inscrição.
8. Aprovar no administrativo.
9. Alterar turma para `EM_ANDAMENTO`, mantendo horário atual dentro do período da turma.
10. Abrir presença e gerar QR.
11. Ler o QR autenticado como participante.
12. Confirmar presença.
13. Atualizar a lista administrativa e conferir o participante como Presente.
14. Tentar confirmar novamente e validar ausência de duplicidade.
15. Encerrar o QR e validar que o mesmo QR deixa de aceitar presença.
16. Validar conclusão/critério e fluxo de certificado já existente.
17. Repetir com aprovação automática.
18. Repetir uma turma com `controle_presenca = ENCONTRO` para teste de regressão.
19. Repetir com outro tenant para validar isolamento.

Frontend:

```bash
npm run lint
npm run build
```


## Complemento - Conclusão automática e certificado automático

Foram ativadas as configurações já previstas na migration 052 para o fluxo simplificado da turma.

### Conclusão automática

Disponível no MVP quando:
- `controle_presenca = TURMA`;
- `conclusao_automatica = 1`.

Ao encerrar a presença da turma:
1. a API localiza inscrições `CONFIRMADO` ou `EM_ANDAMENTO`;
2. executa o motor de conclusão já existente;
3. recalcula presença, aulas e critérios;
4. quando elegível, altera a inscrição para `CONCLUIDO`;
5. registra o histórico da conclusão.

Se não existirem critérios obrigatórios:
- com `exigir_presenca_conclusao = 1`, somente participante com presença da turma registrada é elegível;
- com `exigir_presenca_conclusao = 0`, a conclusão automática pode ocorrer sem exigir presença.

No frontend, ao ativar conclusão automática no modo QR da turma, **Exigir presença** é marcado por padrão.

### Certificado automático

Quando:
- `conclusao_automatica = 1`;
- `certificado_automatico = 1`;
- inscrição foi concluída e ficou elegível;

a API cria automaticamente o certificado em situação `PENDENTE`, reutilizando o mesmo serviço de emissão já existente.

Isso preserva:
- número público sequencial;
- código de validação imprevisível;
- modelo da turma ou modelo padrão;
- proteção contra duplicidade e concorrência;
- multi-tenant;
- histórico e ciclo de reemissão.

Nesta etapa, o fechamento da presença **não gera todos os PDFs sincronamente**. O certificado automático fica preparado como `PENDENTE` para o processo de geração de PDF + QR já existente. Essa decisão evita travar o encerramento de uma turma com muitos participantes.

### Resiliência

Falhas em uma automação não desfazem o encerramento da presença.

São auditadas as situações:
- `CONCLUSAO_AUTOMATICA_ERRO`;
- `CERTIFICADO_AUTOMATICO_ERRO`.

Uma falha em um participante não impede o processamento dos demais.

### Validações

A API rejeita:
- conclusão automática em fluxo diferente de `TURMA`;
- certificado automático sem conclusão automática;
- exigir presença quando `controle_presenca = SEM_CONTROLE`.

### Interface

Na turma agora ficam disponíveis:
- Exigir presença para conclusão;
- Conclusão automática;
- Criar certificado automaticamente.

No detalhe da turma são exibidos os estados das automações configuradas.


## Complemento - Processamento automático de PDF + QR

A geração automática do certificado foi desacoplada do encerramento da presença.

### Migration 054

Nova tabela:

`certificado_processamento`

Responsabilidades:
- fila persistente;
- vínculo com instituição e certificado;
- usuário que originou a emissão;
- situação do job;
- tentativas;
- próxima tentativa;
- horário de processamento;
- conclusão;
- último erro.

Situações:
- `PENDENTE`;
- `PROCESSANDO`;
- `CONCLUIDO`;
- `ERRO`.

### Fluxo

Quando a turma possui:

```
controle_presenca = TURMA
conclusao_automatica = 1
certificado_automatico = 1
```

ao encerrar a presença:

```
avaliar participante
  -> CONCLUIDO
  -> criar certificado PENDENTE
  -> inserir na certificado_processamento
  -> encerrar request administrativo
  -> worker processa em background
  -> gerar QR
  -> renderizar HTML
  -> gerar PDF
  -> calcular SHA-256
  -> finalizar certificado
  -> certificado VALIDO
  -> fila CONCLUIDO
```

O encerramento da turma não aguarda Chromium/qrencode.

### Worker

Novo worker:

`CertificadoProcessamento.Worker.pas`

É iniciado automaticamente no bloco `apMoviSystem` junto com o worker de campanhas.

Comportamento:
- processa um certificado por vez por worker;
- quando há trabalho, intervalo curto de 250ms entre itens;
- sem trabalho, aguarda 2 segundos;
- exceção do worker nunca derruba a API.

### Concorrência

A reserva usa:

`FOR UPDATE SKIP LOCKED`

Assim, mais de uma instância da API pode executar workers sem reservar simultaneamente o mesmo job.

### Retentativas

Cada job possui no máximo 3 tentativas automáticas.

Após falha:
- situação da fila = `ERRO`;
- mensagem salva em `ultimo_erro`;
- nova tentativa programada para 5 minutos.

Após a terceira falha:
- certificado passa de `PENDENTE` para `ERRO`;
- job não é selecionado novamente automaticamente;
- o fluxo manual existente de geração de PDF continua podendo trabalhar com certificado `ERRO`.

### Recuperação de reinício

Jobs que permanecerem em `PROCESSANDO` por mais de 15 minutos são liberados como `ERRO` e ficam disponíveis para nova tentativa.

Se o PDF tiver sido finalizado e o certificado já estiver `VALIDO`, mas a API cair antes de atualizar a fila, o próximo processamento identifica o certificado válido e marca a fila como `CONCLUIDO` sem gerar outro PDF.

### Auditoria

Histórico do certificado:
- `PROCESSAMENTO_AGENDADO`;
- `PDF_GERADO`;
- `EMITIDO`;
- `PROCESSAMENTO_ERRO` após falha definitiva.

### Frontend

A configuração da turma agora informa:

**Gerar certificado automaticamente**

Descrição:
> Após a conclusão, o certificado entra na fila e o PDF + QR Code são gerados em segundo plano.

No detalhe da turma:
- `PDF + QR em segundo plano` quando ativo.

### Dependências de produção

O worker utiliza o gerador de documentos já existente.

O ambiente da API precisa manter configurado:

```ini
[CERTIFICADO_DOCUMENTO]
StoragePath=...
PublicValidationBaseUrl=...
QrEncodeExecutable=...
ChromiumExecutable=...
ChromiumArgs=...
```

Também são necessários no servidor:
- Chromium;
- qrencode;
- permissão de escrita no StoragePath.

### Teste posterior

1. Aplicar migration 054.
2. Confirmar mensagem de inicialização:
   `Worker de certificados iniciado com sucesso.`
3. Criar turma com QR + conclusão automática + certificado automático.
4. Registrar presença.
5. Encerrar presença.
6. Confirmar inscrição `CONCLUIDO`.
7. Confirmar certificado inicialmente `PENDENTE`.
8. Confirmar registro em `certificado_processamento`.
9. Aguardar worker.
10. Confirmar fila `CONCLUIDO`.
11. Confirmar certificado `VALIDO`.
12. Baixar PDF e validar QR público.
13. Simular erro de Chromium e validar retentativas.


## Complemento - Painel de processamento de certificados

Foi adicionado o acompanhamento administrativo da fila de geração automática de PDF + QR Code.

### API

Novo endpoint de listagem:

```
GET /v1/certifica/instituicao/certificados/processamento
```

Filtros:
- `busca`: número do certificado, participante ou curso;
- `situacao`: PENDENTE, PROCESSANDO, CONCLUIDO ou ERRO;
- `page`;
- `page_size`.

Permissão:
- `certificado.visualizar`.

Retorno:
- certificado;
- participante;
- curso;
- situação da fila;
- situação do certificado;
- quantidade de tentativas;
- último erro;
- data de criação;
- última atualização;
- próxima tentativa;
- início do processamento;
- conclusão.

Novo endpoint para reprocessamento:

```
POST /v1/certifica/instituicao/certificados/:id/reprocessar
```

Permissão específica:
- `certificado.reprocessar`.

Regras:
- somente jobs em `ERRO`;
- certificado precisa estar `PENDENTE` ou `ERRO`;
- tentativas são zeradas;
- fila volta para `PENDENTE`;
- certificado `ERRO` volta para `PENDENTE`;
- próximo processamento ocorre pelo worker;
- ação registrada no histórico como `PROCESSAMENTO_REENFILEIRADO`;
- sempre filtrado por `id_instituicao`.

### Permissões

Novo seed:

```
certificado.reprocessar
```

Descrição:
> Reprocessar certificados com erro.

Os perfis administrativos são atualizados pelo fluxo já existente de garantia de permissões.

### Frontend

Nova página:

```
/[slug]/admin/certificados/processamento
```

A tela exibe:
- cards de status;
- busca;
- filtro por situação;
- número público;
- participante;
- curso;
- status;
- tentativas;
- última atualização;
- próxima tentativa;
- último erro;
- botão para abrir o certificado;
- botão Reprocessar quando permitido.

A tela principal de certificados ganhou o botão:

**Processamento**

### Histórico

Novo evento reconhecido pelo frontend:

```
PROCESSAMENTO_REENFILEIRADO
```

Além de:
- PROCESSAMENTO_AGENDADO;
- PROCESSAMENTO_ERRO;
- PDF_GERADO;
- EMITIDO.

### Teste posterior

1. Gerar um erro proposital no processamento automático.
2. Abrir Certificados -> Processamento.
3. Filtrar por ERRO.
4. Conferir tentativas e último erro.
5. Entrar com usuário sem `certificado.reprocessar` e confirmar ausência do botão.
6. Entrar com usuário autorizado.
7. Clicar Reprocessar.
8. Confirmar job PENDENTE.
9. Aguardar worker.
10. Confirmar job CONCLUIDO e certificado VALIDO.
11. Conferir evento PROCESSAMENTO_REENFILEIRADO no histórico.
12. Validar isolamento entre duas instituições.


## Complemento - Download seguro e certificados na área do participante

A área do participante foi endurecida para disponibilizar somente certificados válidos e atuais.

### Regras da API

Endpoints existentes reaproveitados:

```
GET /v1/certifica/aluno/certificados
GET /v1/certifica/aluno/certificados/:id
GET /v1/certifica/aluno/certificados/:id/pdf
```

Não foi criado fluxo paralelo.

A API valida:
- instituição do token;
- usuário da instituição;
- participante ativo vinculado ao usuário;
- certificado pertencente ao mesmo participante;
- certificado pertencente ao mesmo `id_instituicao`;
- situação `VALIDO`;
- existência de PDF;
- versão válida mais recente da inscrição.

Certificados cancelados e versões válidas antigas não aparecem mais na área do participante.

O dashboard também contabiliza somente a versão válida atual de cada inscrição.

### Download

O download continua autenticado e usa o storage interno do certificado.

Antes de disponibilizar o arquivo:
1. resolve o participante autenticado;
2. valida tenant e propriedade do certificado;
3. valida situação `VALIDO`;
4. valida se é a versão válida mais recente;
5. valida `pdf_storage_key`;
6. resolve o caminho físico com proteção contra path traversal;
7. somente então libera o PDF.

Headers:
- `Cache-Control: private, no-store`;
- `X-Content-Type-Options: nosniff`;
- download como `application/pdf`.

### Auditoria

Após localizar o arquivo físico, é registrado no histórico:

```
DOWNLOAD_ALUNO
```

Descrição:
> Download do certificado solicitado pelo participante autenticado.

Não é registrado download quando o arquivo não existe no storage.

### Frontend

Página:

```
/[slug]/aluno/certificados
```

Agora:
- mostra somente certificados válidos atuais;
- informa **Versão atual**;
- possui botão **Ver detalhes**;
- possui botão **Baixar certificado** diretamente no card;
- layout responsivo para desktop e mobile.

Página de detalhes mantém:
- dados do certificado;
- situação;
- carga horária;
- emissão;
- botão de download;
- informação sobre validação pública via QR Code.

### Segurança

A validação pública continua separada do download autenticado.

O código de validação não é exposto na listagem autenticada do aluno.

### Teste posterior

1. Emitir certificado versão 1.
2. Confirmar exibição na área do aluno.
3. Baixar PDF.
4. Confirmar evento DOWNLOAD_ALUNO.
5. Reemitir versão 2.
6. Confirmar que somente a versão válida mais recente aparece.
7. Cancelar certificado atual.
8. Confirmar que certificado cancelado não aparece para download.
9. Tentar acessar manualmente ID de certificado de outro participante.
10. Tentar acessar certificado de outra instituição.
11. Confirmar bloqueio.
12. Validar em desktop e mobile.


## Complemento - Notificação automática de certificado disponível

Quando o certificado passa definitivamente para `VALIDO`, a API agenda notificações para os canais cadastrados do participante.

### Migration 055

Nova tabela:

```
certificado_notificacao
```

Campos principais:
- `id_instituicao`;
- `id_certificado`;
- `canal`: EMAIL ou WHATSAPP;
- `destinatario`;
- `situacao`: PENDENTE, PROCESSANDO, ENVIADO, ERRO ou IGNORADO;
- `tentativas`;
- `proxima_tentativa_em`;
- `processando_em`;
- `enviado_em`;
- `ultimo_erro`.

Existe unicidade por certificado + canal para evitar duplicidade.

### Agendamento

O agendamento acontece dentro da mesma transação que finaliza o PDF e torna o certificado válido.

Canais:
- EMAIL, quando o participante possui e-mail;
- WHATSAPP, quando o participante possui telefone.

Se nenhum canal estiver cadastrado, nenhuma notificação é criada.

Evento de histórico:
- `NOTIFICACAO_AGENDADA`.

### Worker

Novo worker:

```
TCertificadoNotificacaoWorker
```

É iniciado junto com a API.

Comportamento:
- reserva um job por vez;
- usa `FOR UPDATE SKIP LOCKED`;
- máximo de 3 tentativas;
- nova tentativa após 5 minutos;
- jobs PROCESSANDO por mais de 15 minutos são recuperados;
- falha de SMTP ou WhatsApp não desfaz a emissão do certificado.

### Cancelamento antes do envio

Antes de enviar, o worker verifica novamente se o certificado continua `VALIDO`.

Se deixou de estar válido:
- não envia;
- marca a notificação como `IGNORADO`;
- registra `NOTIFICACAO_IGNORADA`.

### E-mail

Usa a configuração SMTP da própria instituição.

Assunto:
```
Seu certificado está disponível - <curso>
```

Inclui:
- nome do participante;
- curso;
- número público;
- link para a área autenticada do participante.

Evento de sucesso:
- `NOTIFICACAO_EMAIL_ENVIADA`.

Após 3 falhas:
- `NOTIFICACAO_EMAIL_ERRO`.

### WhatsApp

Usa a instância Evolution já configurada para a instituição.

Mensagem inclui:
- aviso de certificado disponível;
- participante;
- curso;
- número público;
- link para a área do participante.

Evento de sucesso:
- `NOTIFICACAO_WHATSAPP_ENVIADA`.

Após 3 falhas:
- `NOTIFICACAO_WHATSAPP_ERRO`.

### Link

O link utiliza:

```
[WEB].PublicURL
```

Formato:

```
{PublicURL}/{slug}/aluno/certificados/{id_certificado}
```

### Frontend

Não foi necessária uma nova tela.

A tela administrativa de detalhes do certificado já exibe o histórico. O tipo do frontend foi atualizado para reconhecer:
- NOTIFICACAO_AGENDADA;
- NOTIFICACAO_EMAIL_ENVIADA;
- NOTIFICACAO_WHATSAPP_ENVIADA;
- NOTIFICACAO_EMAIL_ERRO;
- NOTIFICACAO_WHATSAPP_ERRO;
- NOTIFICACAO_IGNORADA.

### Teste posterior

1. Participante com e-mail e telefone.
2. Finalizar um certificado.
3. Conferir duas linhas na fila.
4. Confirmar envio de e-mail.
5. Confirmar envio de WhatsApp.
6. Conferir os eventos no histórico.
7. Testar somente e-mail.
8. Testar somente telefone.
9. Testar participante sem canais.
10. Desconectar WhatsApp e validar retry.
11. Desabilitar SMTP e validar retry.
12. Cancelar certificado antes do worker e confirmar IGNORADO.
13. Validar isolamento entre instituições.
