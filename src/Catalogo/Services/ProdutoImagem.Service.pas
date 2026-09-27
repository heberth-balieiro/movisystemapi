unit ProdutoImagem.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  ProdutoImagem.Model;

type
  TProdutoImagemService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarImagem(const AImagem: TProdutoImagemModel); static;
  public
    class function CriarImagem(
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AImagem: TProdutoImagemModel
    ): Int64; static;

    class function ListarImagens(
      const AIdEmpresa: Int64;
      const AIdProduto: Int64
    ): TObjectList<TProdutoImagemModel>; static;

    class function BuscarImagem(
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AIdImagem: Int64
    ): TProdutoImagemModel; static;

    class procedure AtualizarImagem(
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AIdImagem: Int64;
      const AImagem: TProdutoImagemModel
    ); static;

    class procedure ExcluirImagem(
      const AIdEmpresa: Int64;
      const AIdProduto: Int64;
      const AIdImagem: Int64
    ); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  ProdutoImagem.DAO;

class function TProdutoImagemService.NormalizarSN(const AValor, APadrao: string): string;
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

class procedure TProdutoImagemService.ValidarImagem(const AImagem: TProdutoImagemModel);
begin
  if AImagem = nil then
    TAppErrors.RaiseBadRequest('Dados da imagem não informados.');

  if AImagem.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa da imagem não informada.');

  if AImagem.IdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto da imagem não informado.');

  if Trim(AImagem.UrlImagem).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a URL da imagem.');

  if Length(Trim(AImagem.UrlImagem)) > 500 then
    TAppErrors.RaiseBadRequest('A URL da imagem deve possuir no máximo 500 caracteres.');

  AImagem.UrlImagem := Trim(AImagem.UrlImagem);
  AImagem.Principal := NormalizarSN(AImagem.Principal, 'N');

  if AImagem.Ordem < 0 then
    AImagem.Ordem := 0;
end;

class function TProdutoImagemService.CriarImagem(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AImagem: TProdutoImagemModel
): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  if AImagem = nil then
    TAppErrors.RaiseBadRequest('Dados da imagem não informados.');

  AImagem.IdEmpresa := AIdEmpresa;
  AImagem.IdProduto := AIdProduto;

  ValidarImagem(AImagem);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      if not TProdutoImagemDAO.ProdutoPertenceEmpresa(Conn, AIdEmpresa, AIdProduto) then
        TAppErrors.RaiseBadRequest('Produto inválido ou não pertence à empresa.');

      if AImagem.Principal = 'S' then
        TProdutoImagemDAO.LimparImagemPrincipal(Conn, AIdEmpresa, AIdProduto);

      Result := TProdutoImagemDAO.Inserir(Conn, AImagem);

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TProdutoImagemService.ListarImagens(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64
): TObjectList<TProdutoImagemModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TProdutoImagemDAO.ProdutoPertenceEmpresa(Conn, AIdEmpresa, AIdProduto) then
      TAppErrors.RaiseBadRequest('Produto inválido ou não pertence à empresa.');

    Result := TProdutoImagemDAO.ListarPorProduto(Conn, AIdEmpresa, AIdProduto);
  finally
    Conn.Free;
  end;
end;

class function TProdutoImagemService.BuscarImagem(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AIdImagem: Int64
): TProdutoImagemModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  if AIdImagem <= 0 then
    TAppErrors.RaiseBadRequest('Imagem não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TProdutoImagemDAO.BuscarPorIdEmpresaProduto(
      Conn,
      AIdEmpresa,
      AIdProduto,
      AIdImagem
    );

    if Result = nil then
      TAppErrors.RaiseNotFound('Imagem não encontrada.');
  finally
    Conn.Free;
  end;
end;

class procedure TProdutoImagemService.AtualizarImagem(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AIdImagem: Int64;
  const AImagem: TProdutoImagemModel
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ImagemAtual: TProdutoImagemModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  if AIdImagem <= 0 then
    TAppErrors.RaiseBadRequest('Imagem não informada.');

  if AImagem = nil then
    TAppErrors.RaiseBadRequest('Dados da imagem não informados.');

  AImagem.IdEmpresa := AIdEmpresa;
  AImagem.IdProduto := AIdProduto;
  AImagem.IdImagem := AIdImagem;

  ValidarImagem(AImagem);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      ImagemAtual := TProdutoImagemDAO.BuscarPorIdEmpresaProduto(
        Conn,
        AIdEmpresa,
        AIdProduto,
        AIdImagem
      );
      try
        if ImagemAtual = nil then
          TAppErrors.RaiseNotFound('Imagem não encontrada.');

        if AImagem.Principal = 'S' then
          TProdutoImagemDAO.LimparImagemPrincipal(Conn, AIdEmpresa, AIdProduto);

        TProdutoImagemDAO.Atualizar(Conn, AImagem);
      finally
        ImagemAtual.Free;
      end;

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TProdutoImagemService.ExcluirImagem(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const AIdImagem: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ImagemAtual: TProdutoImagemModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdProduto <= 0 then
    TAppErrors.RaiseBadRequest('Produto não informado.');

  if AIdImagem <= 0 then
    TAppErrors.RaiseBadRequest('Imagem não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    ImagemAtual := TProdutoImagemDAO.BuscarPorIdEmpresaProduto(
      Conn,
      AIdEmpresa,
      AIdProduto,
      AIdImagem
    );
    try
      if ImagemAtual = nil then
        TAppErrors.RaiseNotFound('Imagem não encontrada.');

      TProdutoImagemDAO.Excluir(Conn, AIdEmpresa, AIdProduto, AIdImagem);
    finally
      ImagemAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
