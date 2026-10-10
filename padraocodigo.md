# Padrao de codigo para novas tabelas

Este documento resume o padrao usado pelos arquivos de referencia:

- `src/Catalogo/Controller/Marca.Controller.pas`
- `src/Catalogo/Services/Marca.Service.pas`
- `src/Catalogo/Dao/Marca.Dao.pas`
- `src/Catalogo/Model/Marca.Model.pas`

Use a entidade `Marca` como modelo para criar novos CRUDs. Para uma nova tabela, replique a divisao em quatro units: `Controller`, `Service`, `DAO` e `Model`.

## Estrutura de arquivos

Para uma entidade chamada `NovaTabela`, criar:

- `src/Catalogo/Controller/NovaTabela.Controller.pas`
- `src/Catalogo/Services/NovaTabela.Service.pas`
- `src/Catalogo/Dao/NovaTabela.Dao.pas`
- `src/Catalogo/Model/NovaTabela.Model.pas`

Padrao de nomes:

- Unit: `NovaTabela.Controller`, `NovaTabela.Service`, `NovaTabela.DAO`, `NovaTabela.Model`.
- Classe controller: `TNovaTabelaController`.
- Classe service: `TNovaTabelaService`.
- Classe DAO: `TNovaTabelaDAO`.
- Classe model: `TNovaTabelaModel`.
- Chave primaria no banco: seguir o formato `id_nova_tabela`.
- Campo de empresa: manter `id_empresa` para isolamento por empresa.

## Model

O `Model` deve ser uma classe simples, sem regra de negocio e sem acesso a banco.

Padrao observado em `Marca.Model`:

- Declarar fields privados com prefixo `F`.
- Expor propriedades publicas com `read` e `write`.
- Usar tipos simples (`Integer`, `Int64`, `string`, `TDateTime`, etc.).
- Incluir `IdEmpresa` quando a tabela pertence a uma empresa.
- Incluir campos de auditoria quando existirem no banco, como `DataCriacao` e `DataAlteracao`.
- Campos calculados de listagem podem ficar no model, mas devem ser identificados como uso de retorno, como `ProdutoQtde`.

Exemplo base:

```pascal
unit NovaTabela.Model;

interface

uses
  System.SysUtils;

type
  TNovaTabelaModel = class
  private
    FIdNovaTabela: Integer;
    FIdEmpresa: Integer;
    FNome: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdNovaTabela: Integer read FIdNovaTabela write FIdNovaTabela;
    property IdEmpresa: Integer read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
```

## DAO

O `DAO` concentra todo acesso ao banco. A camada de `Service` abre a conexao e passa `TUniConnection` para o DAO.

Padrao observado em `Marca.DAO`:

- Receber sempre `const AConn: TUniConnection`.
- Criar `TUniQuery.Create(nil)` dentro do metodo.
- Definir `Qry.Connection := AConn`.
- Montar SQL parametrizado, nunca concatenando valores informados pelo usuario.
- Preencher parametros via `ParamByName`.
- Liberar `Qry` em `finally`.
- Retornar model em buscas individuais e `TObjectList<TModel>.Create(True)` em listagens.
- Filtrar por `id_empresa` em todas as operacoes da tabela.
- Usar `LAST_INSERT_ID()` apos `INSERT` para retornar o novo id.
- Em `DELETE`, retornar `RowsAffected > 0`.

Metodos esperados para CRUD:

- `ExisteNome`: verifica duplicidade de nome/descricao dentro da empresa.
- `Inserir`: insere registro e retorna a chave gerada.
- `Atualizar`: atualiza registro filtrando por `id_empresa` e id da entidade.
- `Excluir`: remove registro filtrando por `id_empresa` e id da entidade.
- `Listar`: retorna lista por empresa.
- `BuscarPorId`: retorna um model ou `nil`.

Quando a tabela tiver vinculos que impedem exclusao, criar um metodo especifico no DAO, como `MarcaPossuiProduto`, para a `Service` validar antes de excluir.

## Service

O `Service` concentra regra de negocio, validacoes, abertura de conexao e chamada ao DAO.

Padrao observado em `Marca.Service`:

- Metodos publicos `static` para `Listar`, `Buscar`, `Inserir`, `Atualizar` e `Excluir`.
- Metodos privados para normalizacao e validacao, como `NormalizarSN` e `ValidarMarca`.
- Validar `AIdEmpresa <= 0` e id da entidade `<= 0`.
- Validar model `nil`.
- Validar campos obrigatorios e tamanho maximo.
- Normalizar campos antes de gravar, como `Ativo` aceitando apenas `S` ou `N`.
- Carregar configuracao com `TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini')`.
- Abrir conexao com `TDatabaseConnection.NewConnection(Config.Database)`.
- Liberar conexao em `finally`.
- Usar `TAppErrors.RaiseBadRequest` para dados invalidos.
- Usar `TAppErrors.RaiseNotFound` quando o registro nao existir.
- Antes de inserir ou atualizar, validar duplicidade pelo DAO.
- Antes de excluir, buscar o registro e validar vinculos.

Fluxo recomendado para `Inserir`:

1. Validar empresa.
2. Validar model e campos obrigatorios.
3. Abrir conexao.
4. Verificar duplicidade.
5. Chamar DAO para inserir.
6. Liberar conexao.

Fluxo recomendado para `Atualizar`:

1. Validar empresa e id.
2. Validar model.
3. Atribuir o id recebido ao model.
4. Abrir conexao.
5. Buscar registro atual.
6. Validar duplicidade ignorando o proprio id.
7. Chamar DAO para atualizar.
8. Liberar model atual e conexao.

Fluxo recomendado para `Excluir`:

1. Validar id.
2. Abrir conexao.
3. Buscar registro atual.
4. Validar se existem vinculos que impedem exclusao.
5. Chamar DAO para excluir.
6. Se nada foi removido, retornar erro.
7. Liberar model atual e conexao.

## Controller

O `Controller` registra rotas HTTP com Horse, valida token JWT, converte JSON para model e model para JSON.

Padrao observado em `Marca.Controller`:

- Classe publica com `class procedure Registry`.
- Rotas sob `/v1/<entidade>`.
- Validar token em todas as rotas com `ValidarToken`.
- Usar `Claims.IdEmpresa` para chamar a service.
- Envolver cada rota em `try..except`.
- Tratar excecoes com `TAppErrors.HandleException(Res, E)`.
- Responder com `TAppResponse.Ok`, `TAppResponse.Created` ou `TAppResponse.Unauthorized`.
- Converter entrada com uma funcao `JsonTo<Entidade>`.
- Converter saida com uma funcao `<Entidade>ToJson`.
- Usar helpers locais para ler JSON com valor padrao, como `GetJsonString` e `GetJsonInt`.
- Liberar models e listas em `finally`.

Rotas esperadas:

- `GET /v1/nova-tabela`: lista registros da empresa. Pode aceitar query `pesquisa`.
- `GET /v1/nova-tabela/:id`: busca um registro pelo id.
- `POST /v1/nova-tabela`: cria registro e retorna o id.
- `PUT /v1/nova-tabela/:id`: atualiza registro.
- `DELETE /v1/nova-tabela/:id`: exclui registro.

Respostas padrao:

- Listagem: `TAppResponse.Ok(Res, Arr)`.
- Busca por id: `TAppResponse.Ok(Res, EntidadeToJson(Model))`.
- Inclusao: `TAppResponse.Created(Res, Retorno, '<Entidade> cadastrado com sucesso.')`.
- Atualizacao: `TAppResponse.Ok(Res, TJSONObject.Create, '<Entidade> atualizado com sucesso.')`.
- Exclusao: `TAppResponse.Ok(Res, TJSONObject.Create, '<Entidade> excluido com sucesso.')`.

## JSON

O JSON deve seguir os nomes de campos do banco em snake_case para ids e campos tecnicos:

- `id_marca`
- `id_empresa`
- `nome`
- `descricao`
- `ativo`
- `ordem`

Na entrada de `POST` e `PUT`, nao receber `id_empresa` pelo corpo. A empresa deve vir do token (`Claims.IdEmpresa`).

Na entrada de `POST` e `PUT`, nao confiar no id enviado no JSON. O id da atualizacao deve vir da rota `/:id`.

## Banco de dados

Padroes SQL observados:

- Tabelas em minusculo: `marca`, `produto`.
- Campos em snake_case: `id_marca`, `id_empresa`, `data_criacao`, `data_alteracao`.
- `INSERT` preenche `data_criacao` com `NOW()`.
- `UPDATE` preenche `data_alteracao` com `NOW()`.
- Todas as operacoes usam parametros nomeados.
- Buscas e alteracoes sempre filtram por `id_empresa`.
- Listagens devem ter `ORDER BY` consistente, por exemplo `ordem, nome`.

## Checklist para nova tabela

- Criar a tabela no banco com `id_empresa`, chave primaria e campos de auditoria quando aplicavel.
- Criar `Model` com propriedades equivalentes aos campos da tabela.
- Criar `DAO` com CRUD, filtros por empresa e SQL parametrizado.
- Criar `Service` com validacoes, regras de negocio e abertura de conexao.
- Criar `Controller` com rotas Horse e conversao JSON/model.
- Registrar o controller no ponto de inicializacao da API, seguindo o mesmo local onde os controllers existentes sao registrados.
- Validar mensagens de erro e sucesso com `TAppErrors` e `TAppResponse`.
- Testar `GET`, `GET/:id`, `POST`, `PUT` e `DELETE` com token valido.

## Pontos de atencao

- Manter `id_empresa` como criterio obrigatorio para evitar acesso entre empresas.
- Nao abrir conexao no controller nem no DAO; o padrao atual abre conexao na service.
- Nao colocar SQL na service ou no controller.
- Nao colocar validacao de negocio no DAO.
- Sempre liberar `TUniQuery`, conexoes, models e listas.
- Usar `TObjectList<TModel>.Create(True)` quando a lista for dona dos objetos.
- Validar vinculos antes de excluir quando a entidade for referenciada por outras tabelas.
- Padronizar mensagens no singular da entidade.

