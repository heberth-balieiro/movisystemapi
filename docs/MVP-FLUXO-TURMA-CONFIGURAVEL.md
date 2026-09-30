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
