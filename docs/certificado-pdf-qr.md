# Certificado PDF + QR — configuração e homologação

A API registra `POST /v1/certifica/instituicao/certificados/:id/gerar-pdf`.
Enviar o JWT da instituição. O certificado deve estar PENDENTE ou ERRO e
possuir modelo associado. O modelo HTML deve conter `{{qr_code_svg}}` para
exibir o QR e pode usar `{{url_validacao}}` para o link de validação.

## Config.ini do servidor

Adicionar/ajustar a seção abaixo no Config.ini junto ao executável da API.
Os valores são exemplos; substituir pelos caminhos e domínio reais.

```ini
[CERTIFICADO_DOCUMENTO]
StoragePath=C:\MoviSystem\storage
PublicValidationBaseUrl=https://certifica.exemplo.com.br/validar
QrEncodeExecutable=C:\Ferramentas\qrencode.exe
ChromiumExecutable=C:\Program Files\Google\Chrome\Application\chrome.exe
ChromiumArgs=--headless --disable-gpu --no-pdf-header-footer
```

Instalar qrencode e Chrome/Chromium na máquina da API. Informar o caminho do
executável sem aspas adicionais. A conta do serviço precisa executar ambos e
ter acesso de gravação ao storage e ao diretório temporário. O storage deve
ficar fora da pasta pública do servidor web. Não disponibilizar acesso direto
à pasta; download autenticado será tratado na tarefa específica.

No Linux, usar caminhos absolutos, por exemplo `/srv/certifica/storage`,
`/usr/bin/qrencode` e `/usr/bin/chromium`. Manter o sandbox do Chromium ativo.
A URL de validação aponta para o frontend; a API acrescenta `/codigo`.
Usar HTTPS em produção. HTTP é aceito para homologação local.

## Alterações

- Registro da rota de geração existente.
- Verificação do cabeçalho `%PDF-` antes da gravação/finalização (não equivale
  a uma validação completa da estrutura ou do conteúdo visual do PDF).
- Perfil temporário individual do Chromium para cada geração.
- Nome de arquivo único por tentativa, sem apagar PDFs anteriores.
- Cópia para storage que pode estar em outro volume.
- Finalização condicional no banco: somente PENDENTE/ERRO podem virar VALIDO;
  uma tentativa concorrente recusada não registra novo histórico de emissão.
- Validação básica do protocolo da URL e de executáveis não vazios.

Não há migração de banco para este ajuste.

## Testes pendentes no ambiente real

1. Compilar a API no Delphi 11 e reiniciar o serviço.
2. Gerar PDF de certificado PENDENTE com modelo contendo QR. Conferir nomes,
   acentuação, carga horária, data, paginação e leitura do QR pelo celular.
3. Conferir status VALIDO, hash/tamanho e histórico PDF_GERADO/EMITIDO.
4. Repetir para certificado em ERRO. Tentar gerar para VALIDO/CANCELADO e
   confirmar recusa sem alterar o arquivo já emitido.
5. Disparar duas gerações do mesmo certificado: somente uma deve finalizar;
   o arquivo da vencedora deve continuar disponível e com o hash registrado.
6. Tentar acesso com JWT de outra instituição e sem autenticação.
7. Testar executável ausente e storage sem permissão: não deve emitir o
   certificado. Corrigir a configuração e tentar novamente.
8. Testar caminhos com espaços e storage em volume diferente.

Este ambiente de revisão não possui Delphi, MySQL nem os executáveis de
renderização. Compilação, concorrência real e PDF visual ainda não homologados.
O executor de processos existente continua sem timeout; isolamento do renderer
para templates não confiáveis deve ser tratado antes de produção.

## Download autenticado

Rotas GET (Authorization: Bearer):

- `/v1/certifica/instituicao/certificados/:id/pdf`: exige usuário ativo com
  `certificado.visualizar` e consulta o certificado dentro da instituição do JWT.
- `/v1/certifica/aluno/certificados/:id/pdf`: resolve o participante associado ao
  usuário e exige certificado desse participante e dessa instituição.

Ambas entregam somente certificados VALIDOS com PDF disponível, como anexo,
com `Content-Type: application/pdf`, `Cache-Control: private, no-store` e
`X-Content-Type-Options: nosniff`. Não recebem caminho de arquivo do cliente.
O download depende apenas de StoragePath; não exige configuração do gerador.

O caminho armazenado deve começar com `certificados/{id_instituicao}/`, terminar
em `.pdf` e não conter navegação de diretórios ou caminho absoluto. No Windows,
junctions/reparse points são recusados. O storage e seus diretórios ancestrais
precisam ser controlados exclusivamente pelo serviço/administrador; não permitir
escrita de terceiros nem links simbólicos no Linux. A checagem de caminho não
protege contra substituição concorrente de arquivos por um usuário do servidor.

### Roteiro de homologação do download

- Admin autorizado e aluno proprietário: PDF abre e corresponde ao certificado.
- Sem JWT/expirado: recusa; usuário sem permissão: recusa na rota administrativa.
- Outra instituição e outro participante: recusa, sem retornar arquivo.
- PENDENTE, ERRO ou CANCELADO: recusa, mesmo havendo arquivo antigo no storage.
- PDF ausente: mensagem controlada, sem caminho físico na resposta.
- Em banco de teste, alterar a chave para `../`, caminho absoluto ou pasta de
  outra instituição: recusa. Restaurar o valor após o teste.
- Inspecionar os três cabeçalhos e o nome do anexo na resposta real do Horse.

Compilação Delphi e testes HTTP com banco e tokens reais permanecem pendentes.

## Ciclo do certificado

- Rotas administrativas exigem `certificado.visualizar`, `certificado.emitir`,
  `certificado.cancelar` ou `certificado.configurar`, conforme a operação.
- `pdf-finalizado` não aceita mais metadados enviados pelo cliente: retorna erro
  orientando usar `gerar-pdf`. Nenhuma alteração de status ocorre nessa rota.
- Emissão inicial, criação de reemissão e finalização serializam a operação pela
  inscrição (bloqueio transacional no MySQL). Reemissão/finalização exigem a
  versão mais recente. Uma nova versão PENDENTE impede outra reemissão.
- Cancelamentos concorrentes não sobrescrevem o motivo nem duplicam o histórico.
- O certificado válido anterior só é cancelado quando o novo PDF finaliza.
  A busca considera a inscrição, inclusive quando houve versões intermediárias
  canceladas antes da conclusão. Cada alteração fica no histórico transacional.

### Homologação do ciclo (pendente)

1. Emitir PENDENTE, gerar PDF, consultar como VALIDO e baixar.
2. Cancelar com motivo: consulta pública CANCELADO e download recusado.
3. Reemitir: novo número/código/versão PENDENTE; anterior ainda válido até gerar.
4. Cancelar essa versão pendente, reemitir a partir dela e finalizar. Confirmar
   cancelamento do certificado que permaneceu válido antes dessas tentativas.
5. Duas emissões iniciais simultâneas: apenas uma criação. Duas reemissões:
   apenas uma nova versão pendente. Duas finalizações: apenas uma emissão.
6. Reemitir versão antiga: recusa. Cancelar simultaneamente: um único histórico.
7. Perfil sem permissão e JWT de outra instituição: operações recusadas.
8. Chamar pdf-finalizado com metadados falsos: recusa sem mudança no banco.

Não há migração para este ajuste. Compilação e testes concorrentes exigem Delphi
11 e MySQL no ambiente de homologação; não foram executados nesta revisão.
