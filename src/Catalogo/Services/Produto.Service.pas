unit Produto.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Produto.Model,
  Uni;

type
  TProdutoService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarProduto(const AProduto: TProdutoModel); static;
    class procedure ValidarLimiteProduto(const AConn: TUniConnection;const AIdEmpresa: Int64); static;
  public
    class function CriarProduto(const AIdEmpresa: Int64;const AProduto: TProdutoModel): Int64; static;
    class function ListarProdutos(const AIdEmpresa: Int64): TObjectList<TProdutoModel>; static;
    class function BuscarProduto(const AIdEmpresa: Int64;const AIdProduto: Int64): TProdutoModel; static;
    class procedure AtualizarProduto(const AIdEmpresa: Int64;const AIdProduto: Int64;const AProduto: TProdutoModel); static;
    class procedure ExcluirProduto(const AIdEmpresa: Int64;const AIdProduto: Int64); static;
  end;

implementation

uses
  App.Config,
  APP.Errors,
  Database.Connection,
  Produto.DAO,
  Empresa.DAO;

class function TProdutoService.NormalizarSN(const AValor, APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'N';

  Result := Valor;
end;

class procedure TProdutoService.ValidarProduto(const AProduto: TProdutoModel);
begin
  if AProduto = nil then
    TAppErrors.RaiseBadRequest('Dados do produto não informados.');

  if AProduto.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa do produto não informada.');

  if AProduto.IdCategoria <= 0 then
    TAppErrors.RaiseBadRequest('Informe a categoria do produto.');

  if Trim(AProduto.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do produto.');

  if Length(Trim(AProduto.Nome)) > 150 then
    TAppErrors.RaiseBadRequest('O nome do produto deve possuir no máximo 150 caracteres.');

  //if AProduto.Preco < 0 then
  //  TAppErrors.RaiseBadRequest('O preço do produto não pode ser negativo.');

  if AProduto.idunidade <= 0 then
    TAppErrors.RaiseBadRequest('Unidade do produto não informada.');

  AProduto.Nome         := Trim(AProduto.Nome);
  AProduto.Descricao    := Trim(AProduto.Descricao);
  AProduto.Ativo        := NormalizarSN(AProduto.Ativo, 'S');
  AProduto.Destaque     := NormalizarSN(AProduto.Destaque, 'N');

  if AProduto.Ordem < 0 then
    AProduto.Ordem := 0;

  if Aproduto.Preco <= 0 then
    Aproduto.Preco  := 0;
end;

class procedure TProdutoService.ValidarLimiteProduto(const AConn: TUniConnection; const AIdEmpresa: Int64);
var
  LPlano: TRecPlano;
  LTotalProdutos: Integer;
begin
  LPlano := TEmpresaDAO.BuscarPlanoAtualEmpresa(AConn, AIdEmpresa);

  if not LPlano.Encontrado then
    raise Exception.Create('Empresa não possui plano ativo para cadastrar produtos.');
  if SameText(LPlano.PermiteProdutoIlimitado, 'S') then
    Exit;
  if LPlano.ProdutoQtde <= 0 then
    raise Exception.Create('O plano atual não permite cadastro de produtos.');
  LTotalProdutos := TProdutoDAO.ContarProdutosEmpresa(AConn, AIdEmpresa);
  if LTotalProdutos >= LPlano.ProdutoQtde then
    raise Exception.CreateFmt(
      'Limite de produtos atingido. Seu plano permite até %d produto(s).',
      [LPlano.ProdutoQtde]
    );
end;

class function TProdutoService.CriarProduto(const AIdEmpresa: Int64;const AProduto: TProdutoModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AProduto = nil then
    TAppErrors.RaiseBadRequest('Dados do produto não informados.');

  AProduto.IdEmpresa := AIdEmpresa;

  ValidarProduto(AProduto);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TProdutoDAO.CategoriaPertenceEmpresa(Conn, AIdEmpresa, AProduto.IdCategoria) then
      TAppErrors.RaiseBadRequest('Categoria inválida ou não pertence à empresa.');

    if TProdutoDAO.ExisteNome(Conn, AIdEmpresa, AProduto.Nome) then
      TAppErrors.RaiseBadRequest('Já existe um produto com este nome.');

    //Validar o plano se e produto ilimitado ou não
    ValidarLimiteProduto(Conn,AIdEmpresa);


    Result := TProdutoDAO.Inserir(Conn, AProduto);
  finally
    Conn.Free;
  end;
end;

class function TProdutoService.ListarProdutos(const AIdEmpresa: Int64): TObjectList<TProdutoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TProdutoDAO.ListarProdutos(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class function TProdutoService.BuscarProduto(const AIdEmpresa: Int64;const AIdProduto: Int64): TProdutoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TProdutoDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdProduto);

    if Result = nil then
      TAppErrors.RaiseNotFound('Produto não encontrado.');
  finally
    Conn.Free;
  end;
end;

class procedure TProdutoService.AtualizarProduto(const AIdEmpresa: Int64;const AIdProduto: Int64;const AProduto: TProdutoModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ProdutoAtual: TProdutoModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  if AProduto = nil then
    TAppErrors.RaiseBadRequest('Dados do produto não informados.');

  AProduto.IdEmpresa := AIdEmpresa;
  AProduto.IdProduto := AIdProduto;

  ValidarProduto(AProduto);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    ProdutoAtual := TProdutoDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdProduto);
    try
      if ProdutoAtual = nil then
        TAppErrors.RaiseNotFound('Produto não encontrado.');

      if not TProdutoDAO.CategoriaPertenceEmpresa(Conn, AIdEmpresa, AProduto.IdCategoria) then
        TAppErrors.RaiseBadRequest('Categoria inválida ou não pertence à empresa.');

      if TProdutoDAO.ExisteNome(Conn, AIdEmpresa, AProduto.Nome, AIdProduto) then
        TAppErrors.RaiseBadRequest('Já existe outro produto com este nome.');

      TProdutoDAO.Atualizar(Conn, AProduto);
    finally
      ProdutoAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TProdutoService.ExcluirProduto(const AIdEmpresa: Int64;const AIdProduto: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ProdutoAtual: TProdutoModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    ProdutoAtual := TProdutoDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdProduto);
    try
      if ProdutoAtual = nil then
        TAppErrors.RaiseNotFound('Produto não encontrado.');

      if TProdutoDAO.ProdutoPossuiPedido(Conn, AIdEmpresa, AIdProduto) then
         TAppErrors.RaiseBadRequest(
          'Não é possível excluir este produto, pois ele já foi utilizado em pedido. ' +
          'Para manter o histórico, inative o produto em vez de excluir.');

      TProdutoDAO.ExcluirImagem(Conn, AIdEmpresa, AIdProduto);

      if TProdutoDAO.ProdutoPossuiImagem(Conn, AIdEmpresa, AIdProduto) then
         TAppErrors.RaiseBadRequest(
          'Não é possível excluir este produto, pois ele possui imagem vinculada. ' +
          'Remova as imagens do produto antes de excluir.');

      TProdutoDAO.Excluir(Conn, AIdEmpresa, AIdProduto);
    finally
      ProdutoAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
