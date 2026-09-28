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
