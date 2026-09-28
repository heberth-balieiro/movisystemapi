# QR do encontro / auto check-in

Base: develop, 945949d. Migration nova: 048. Rotas existentes /v1/certifica preservadas.

## Regra de negócio

- Somente usuários com `presenca.editar` podem abrir/renovar/encerrar o QR.
- Instituição e usuário ativos. Turma EM_ANDAMENTO, encontro AGENDADO, dentro do intervalo início (inclusive) / fim (exclusive).
- QR compartilhado do encontro: validade de 15 minutos ou até o fim do encontro, o que ocorrer primeiro. Abrir novamente revoga o QR anterior. Encerrar revoga imediatamente.
- Token aleatório de 32 bytes (BCrypt no Windows, /dev/urandom no Linux), hexadecimal. Apenas SHA-256 fica no banco; o valor original só é retornado na abertura.
- O aluno deve estar autenticado e vinculado a participante ativo na instituição do JWT. A API resolve inscrição e participante; nunca aceita esses IDs no payload.
- Inscrição CONFIRMADO ou EM_ANDAMENTO. PRESENTE existente retorna `ja_registrada=true`, sem alterar horário, responsável, origem ou justificativa. Outros lançamentos exigem revisão pela equipe.
- A confirmação grava a presença e a auditoria na mesma transação. Consultar não registra presença.
- O aluno deve confirmar explicitamente. Este recurso não comprova localização física; um QR compartilhado pode ser encaminhado.

## Banco e concorrência

`encontro_checkin`: uma sessão corrente por instituição/encontro, token_hash único, validade, abertura, responsável e encerramento.
`presenca.origem`: LEGADO para registros anteriores; MANUAL, QR_EQUIPE ou AUTO_CHECKIN nos novos lançamentos.
A migration 048 permite retomar após falha entre os DDLs. Não deduz a origem dos registros antigos.

Leitura inicial resolve o encontro pelo hash e tenant. Em seguida bloqueia encontro/turma e revalida a sessão/token em leitura FOR UPDATE. Inscrição e presença também são bloqueadas. Renovação e encerramento usam a mesma ordem de bloqueio do encontro. O índice único existente impede duplicação; a inserção revalida a expiração no relógio do banco. Auditoria não recebe tokens nem CPF.

Permissões também foram adicionadas aos caminhos administrativos de gravação manual e leitura do QR individual; os GETs administrativos exigem `presenca.visualizar`. O histórico próprio continua no AlunoPortal.

## Contrato HTTP

Todos os endpoints exigem Bearer JWT. Respostas usam o envelope existente `{erro,mensagem,dados}` e `Cache-Control: no-store`.

| Método | Caminho após /v1/certifica | Corpo |
|---|---|---|
| GET | /instituicao/turmas/:id_turma/encontros/:id_encontro/checkin | nenhum |
| POST | /instituicao/turmas/:id_turma/encontros/:id_encontro/checkin/abrir | nenhum |
| POST | /instituicao/turmas/:id_turma/encontros/:id_encontro/checkin/encerrar | nenhum |
| POST | /aluno/checkin/consultar | {"token":"64 caracteres hex minúsculos"} |
| POST | /aluno/checkin/confirmar | mesmo corpo |

Dados: id_encontro, titulo, turma_nome, aberto, segundos_restantes, ja_registrada, situacao e checkin_em quando houver. `token` aparece apenas ao abrir. Os segundos usam o relógio do banco para evitar conversões de fuso no contador.

## Homologação obrigatória antes do merge/deploy

A API Delphi e o MySQL não foram executados neste ambiente. Compilar EasyOneAPI.dpr com Delphi/UniDAC/Horse e executar a migration em banco de homologação antes de instalar o frontend correspondente.

1. Fazer backup e confirmar aplicação da migration 048, inclusive reinicialização sem reaplicar DDL.
2. Preparar dois tenants, usuário administrador com presenca.editar/visualizar, aluno vinculado e inscrição confirmada; turma em andamento e encontro no horário do banco.
3. Abrir, consultar e confirmar. Conferir UMA presença AUTO_CHECKIN, usuário correto e UMA auditoria PRESENCA_AUTO_CHECKIN.
4. Repetir confirmação e enviar duas confirmações concorrentes. O mesmo registro deve permanecer, sem alterar checkin_em e sem duplicar auditoria.
5. Renovar QR: o antigo deve falhar. Encerrar: ambos devem falhar. Expiração/fim do encontro devem impedir novas presenças, inclusive no limite da confirmação.
6. Testar token malformado, expirado, tenant diferente, aluno de outra turma, inscrição cancelada/pendente, participante/usuário/instituição inativos e encontro cancelado/realizado.
7. Tentar abrir/encerrar e gravar pelos endpoints manuais e QR_EQUIPE com JWT de aluno: acesso negado.
8. Criar AUSENTE/JUSTIFICADA/PARCIAL e tentar auto check-in: preservar o lançamento e orientar revisão da equipe.
9. Testar leitura da câmera nativa, login/retorno e confirmação nos navegadores de celular usados pelos alunos.
10. Conferir o fuso da conexão MySQL e os horários cadastrados; o novo fluxo segue o padrão DATETIME existente.

Rate limit geral, auditoria de falhas de toda a plataforma e homologação de produção seguem as tarefas separadas do backlog. Não publicar como homologado sem os testes acima.
