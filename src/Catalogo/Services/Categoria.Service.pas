unit Categoria.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Categoria.Model;

type
  TCategoriaService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarCategoria(const ACategoria: TCategoriaModel); static;
  public
    class function CriarCategoria(const AIdEmpresa: Int64;const ACategoria: TCategoriaModel): Int64; static;
    class function ListarCategorias(const AIdEmpresa: Int64): TObjectList<TCategoriaModel>; static;
    class function BuscarCategoria(const AIdEmpresa: Int64;const AIdCategoria: Int64): TCategoriaModel; static;
    class procedure AtualizarCategoria(const AIdEmpresa: Int64;const AIdCategoria: Int64;const ACategoria: TCategoriaModel); static;
    class procedure ExcluirCategoria(const AIdEmpresa: Int64;const AIdCategoria: Int64); static;
    class procedure AtualizarImagemCategoria(const AIdEmpresa: Int64;const AIdCategoria: Int64;const AImagemUrl: string); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Categoria.DAO;

class function TCategoriaService.NormalizarSN(const AValor, APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'S';

  Result := Valor;
end;

class procedure TCategoriaService.ValidarCategoria(const ACategoria: TCategoriaModel);
begin
  if ACategoria = nil then
    TAppErrors.RaiseBadRequest('Dados da categoria não informados.');

  if ACategoria.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa da categoria não informada.');

  if Trim(ACategoria.Nome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome da categoria.');

  if Length(Trim(ACategoria.Nome)) > 120 then
    TAppErrors.RaiseBadRequest('O nome da categoria deve possuir no máximo 120 caracteres.');

  if Length(Trim(ACategoria.Descricao)) > 255 then
    TAppErrors.RaiseBadRequest('A descrição da categoria deve possuir no máximo 255 caracteres.');

  ACategoria.Nome       := Trim(ACategoria.Nome);
  ACategoria.Descricao  := Trim(ACategoria.Descricao);
  ACategoria.Ativo      := NormalizarSN(ACategoria.Ativo, 'S');

  if ACategoria.Ordem < 0 then
    ACategoria.Ordem := 0;
end;

class function TCategoriaService.CriarCategoria(
  const AIdEmpresa: Int64;
  const ACategoria: TCategoriaModel
): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if ACategoria = nil then
    TAppErrors.RaiseBadRequest('Dados da categoria não informados.');

  ACategoria.IdEmpresa := AIdEmpresa;

  ValidarCategoria(ACategoria);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TCategoriaDAO.ExisteNome(Conn, AIdEmpresa, ACategoria.Nome) then
      TAppErrors.RaiseBadRequest('Já existe uma categoria com este nome.');

    Result := TCategoriaDAO.Inserir(Conn, ACategoria);
  finally
    Conn.Free;
  end;
end;

class function TCategoriaService.ListarCategorias(
  const AIdEmpresa: Int64
): TObjectList<TCategoriaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCategoriaDAO.ListarPorEmpresa(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class procedure TCategoriaService.AtualizarImagemCategoria(const AIdEmpresa,
  AIdCategoria: Int64; const AImagemUrl: string);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CategoriaAtual: TCategoriaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest('Categoria não informada.');
  if Trim(AImagemUrl).IsEmpty then
    TAppErrors.RaiseBadRequest('Imagem da categoria não informada.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    CategoriaAtual := TCategoriaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdCategoria);
    try
      if CategoriaAtual = nil then
        TAppErrors.RaiseNotFound('Categoria não encontrada.');
      TCategoriaDAO.AtualizarImagem(
        Conn,
        AIdEmpresa,
        AIdCategoria,
        Trim(AImagemUrl)
      );
    finally
      CategoriaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TCategoriaService.BuscarCategoria(
  const AIdEmpresa: Int64;
  const AIdCategoria: Int64
): TCategoriaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest('Categoria não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCategoriaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdCategoria);

    if Result = nil then
      TAppErrors.RaiseNotFound('Categoria não encontrada.');
  finally
    Conn.Free;
  end;
end;

class procedure TCategoriaService.AtualizarCategoria(
  const AIdEmpresa: Int64;
  const AIdCategoria: Int64;
  const ACategoria: TCategoriaModel
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CategoriaAtual: TCategoriaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest('Categoria não informada.');

  if ACategoria = nil then
    TAppErrors.RaiseBadRequest('Dados da categoria não informados.');

  ACategoria.IdEmpresa := AIdEmpresa;
  ACategoria.IdCategoria := AIdCategoria;

  ValidarCategoria(ACategoria);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    CategoriaAtual := TCategoriaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdCategoria);
    try
      if CategoriaAtual = nil then
        TAppErrors.RaiseNotFound('Categoria não encontrada.');

      if TCategoriaDAO.ExisteNome(Conn, AIdEmpresa, ACategoria.Nome, AIdCategoria) then
        TAppErrors.RaiseBadRequest('Já existe outra categoria com este nome.');

      TCategoriaDAO.Atualizar(Conn, ACategoria);
    finally
      CategoriaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TCategoriaService.ExcluirCategoria(
  const AIdEmpresa: Int64;
  const AIdCategoria: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CategoriaAtual: TCategoriaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest('Categoria não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    CategoriaAtual := TCategoriaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdCategoria);
    try
      if CategoriaAtual = nil then
        TAppErrors.RaiseNotFound('Categoria não encontrada.');

      TCategoriaDAO.Excluir(Conn, AIdEmpresa, AIdCategoria);
    finally
      CategoriaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
