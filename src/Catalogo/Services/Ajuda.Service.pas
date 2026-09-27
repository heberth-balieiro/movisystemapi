unit Ajuda.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Ajuda.Model;

type
  TAjudaService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarAjuda(const AAjuda: TAjudaModel); static;
  public
    class function CriarAjuda(
      const AIdEmpresa: Int64;
      const AAjuda: TAjudaModel
    ): Int64; static;

    class function ListarAjudas(
      const AIdEmpresa: Int64;
      const AApenasAtivos: Boolean = False
    ): TObjectList<TAjudaModel>; static;

    class function BuscarAjuda(
      const AIdEmpresa: Int64;
      const AIdAjuda: Int64
    ): TAjudaModel; static;

    class procedure AtualizarAjuda(
      const AIdEmpresa: Int64;
      const AIdAjuda: Int64;
      const AAjuda: TAjudaModel
    ); static;

    class procedure ExcluirAjuda(
      const AIdEmpresa: Int64;
      const AIdAjuda: Int64
    ); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Ajuda.DAO;

class function TAjudaService.NormalizarSN(const AValor, APadrao: string): string;
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

class procedure TAjudaService.ValidarAjuda(const AAjuda: TAjudaModel);
begin
  if AAjuda = nil then
    TAppErrors.RaiseBadRequest('Dados da ajuda não informados.');

  if AAjuda.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa da ajuda não informada.');

  if Trim(AAjuda.Titulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o título da ajuda.');

  if Length(Trim(AAjuda.Titulo)) > 150 then
    TAppErrors.RaiseBadRequest('O título da ajuda deve possuir no máximo 150 caracteres.');

  if Trim(AAjuda.Url).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a URL da ajuda.');

  if Length(Trim(AAjuda.Url)) > 500 then
    TAppErrors.RaiseBadRequest('A URL da ajuda deve possuir no máximo 500 caracteres.');

  AAjuda.Titulo := Trim(AAjuda.Titulo);
  AAjuda.Url := Trim(AAjuda.Url);
  AAjuda.Descricao := Trim(AAjuda.Descricao);
  AAjuda.Ativo := NormalizarSN(AAjuda.Ativo, 'S');

  if AAjuda.Ordem < 0 then
    AAjuda.Ordem := 0;
end;

class function TAjudaService.CriarAjuda(
  const AIdEmpresa: Int64;
  const AAjuda: TAjudaModel
): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AAjuda = nil then
    TAppErrors.RaiseBadRequest('Dados da ajuda não informados.');

  AAjuda.IdEmpresa := AIdEmpresa;

  ValidarAjuda(AAjuda);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TAjudaDAO.ExisteTitulo(Conn, AIdEmpresa, AAjuda.Titulo) then
      TAppErrors.RaiseBadRequest('Já existe uma ajuda com este título.');

    Result := TAjudaDAO.Inserir(Conn, AAjuda);
  finally
    Conn.Free;
  end;
end;

class function TAjudaService.ListarAjudas(
  const AIdEmpresa: Int64;
  const AApenasAtivos: Boolean
): TObjectList<TAjudaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAjudaDAO.ListarPorEmpresa(Conn, AIdEmpresa, AApenasAtivos);
  finally
    Conn.Free;
  end;
end;

class function TAjudaService.BuscarAjuda(
  const AIdEmpresa: Int64;
  const AIdAjuda: Int64
): TAjudaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAjuda <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAjudaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdAjuda);

    if Result = nil then
      TAppErrors.RaiseNotFound('Ajuda não encontrada.');
  finally
    Conn.Free;
  end;
end;

class procedure TAjudaService.AtualizarAjuda(
  const AIdEmpresa: Int64;
  const AIdAjuda: Int64;
  const AAjuda: TAjudaModel
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  AjudaAtual: TAjudaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAjuda <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda não informada.');

  if AAjuda = nil then
    TAppErrors.RaiseBadRequest('Dados da ajuda não informados.');

  AAjuda.IdEmpresa := AIdEmpresa;
  AAjuda.IdAjuda := AIdAjuda;

  ValidarAjuda(AAjuda);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    AjudaAtual := TAjudaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdAjuda);
    try
      if AjudaAtual = nil then
        TAppErrors.RaiseNotFound('Ajuda não encontrada.');

      if TAjudaDAO.ExisteTitulo(Conn, AIdEmpresa, AAjuda.Titulo, AIdAjuda) then
        TAppErrors.RaiseBadRequest('Já existe outra ajuda com este título.');

      TAjudaDAO.Atualizar(Conn, AAjuda);
    finally
      AjudaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAjudaService.ExcluirAjuda(
  const AIdEmpresa: Int64;
  const AIdAjuda: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  AjudaAtual: TAjudaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAjuda <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    AjudaAtual := TAjudaDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdAjuda);
    try
      if AjudaAtual = nil then
        TAppErrors.RaiseNotFound('Ajuda não encontrada.');

      TAjudaDAO.Excluir(Conn, AIdEmpresa, AIdAjuda);
    finally
      AjudaAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
