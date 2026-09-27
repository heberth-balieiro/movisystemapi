unit Marca.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Marca.Model;

type
  TMarcaService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarMarca(const AMarca: TMarcaModel); static;

  public
    class function Listar(const AIdEmpresa: Integer; const APesquisa: string): TObjectList<TMarcaModel>; static;
    class function BuscarMarca(const AIdEmpresa, AIdMarca: Int64): TMarcaModel; static;

    class function Inserir(Const AIdEmpresa: Int64; const AMarca: TMarcaModel): Int64; static;
    class procedure Atualizar(const AIdEmpresa, AIdMarca: Int64; const AMarca: TMarcaModel); static;
    class procedure Excluir(const AIdEmpresa, AIdMarca: Int64);
  end;

implementation

uses
  Marca.DAO,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection;

{ TMarcaService }

{$REGION 'Funções'}

class function TMarcaService.NormalizarSN(const AValor,APadrao: string): string;
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

class procedure TMarcaService.ValidarMarca(const AMarca: TMarcaModel);
begin

  if AMarca = nil then
    TAppErrors.RaiseBadRequest('Dados da marca não informados.');

  if Trim(AMarca.Nome) = '' then
    TAppErrors.RaiseBadRequest('Informe o nome da marca.');

  if Length(Trim(AMarca.Nome)) > 100 then
    TAppErrors.RaiseBadRequest('O nome da marca deve ter no máximo 100 caracteres.');

  if Length(Trim(AMarca.Descricao)) > 255 then
    TAppErrors.RaiseBadRequest('A descrição da marca deve ter no máximo 255 caracteres.');

  AMarca.Ativo := NormalizarSN(AMarca.Ativo, 'S');

  if AMarca.Ordem < 0 then
    AMarca.Ordem := 0;

end;

{$ENDREGION}


{$REGION 'CRUD'}

class function TMarcaService.Inserir(Const AIdEmpresa: Int64; const AMarca: TMarcaModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin

  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não identificada.');

  ValidarMarca(AMarca);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TMarcaDAO.ExisteNome(Conn, AIdEmpresa, AMarca.nome) then
      TAppErrors.RaiseBadRequest('Já existe uma marca com está descrição.');

    Result := TMarcaDAO.Inserir(Conn, AIdEmpresa, AMarca);
  finally
    Conn.Free;
  end;

end;

class procedure TMarcaService.Atualizar(const AIdEmpresa, AIdMarca: Int64; const AMarca: TMarcaModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  AMarcaAtual: TMarcaModel;
begin

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não identificada.');

  if AIdMarca <= 0 then
    TAppErrors.RaiseBadRequest('Marca não informado.');

  if AMarca = nil then
    TAppErrors.RaiseBadRequest('Dados da marca não informados.');

  AMarca.IdMarca := AIdMarca;
  ValidarMarca(AMarca);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    AMarcaAtual := TMarcaDAO.BuscarPorId(Conn,AIdEmpresa, AIdMarca);
    try
      if AMarcaAtual = nil then
        TAppErrors.RaiseNotFound('Marca não encontrado.');

      if TMarcaDAO.ExisteNome(Conn, AIdEmpresa, AMarca.nome, AIdMarca) then
        TAppErrors.RaiseBadRequest('Já existe outra marca com este nome.');

      TMarcaDAO.Atualizar(Conn, AIdEmpresa, AIdMarca, AMarca);
    finally
      AMarcaAtual.Free;
    end;
  finally
    Conn.Free;
  end;

end;

class procedure TMarcaService.Excluir(const AIdEmpresa, AIdMarca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  MarcaAtual: TMarcaModel;
begin

  if AIdMarca <= 0 then
    TAppErrors.RaiseBadRequest('Marca não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    MarcaAtual := TMarcaDAO.BuscarPorId(Conn, AIdEmpresa, AIdMarca);
    try
      if MarcaAtual = nil then
        TAppErrors.RaiseNotFound('Marca não encontrado.');

      if TMarcaDAO.MarcaPossuiProduto(Conn, AIdEmpresa, AIdMarca) then
        TAppErrors.RaiseBadRequest(
          'Não é possível excluir esta marca, pois ele já foi vinculado ao um produto. ' +
          'Para manter o histórico, inative a marca em vez de excluir.');

      if not TMarcaDAO.Excluir(Conn, AIdEmpresa, AIdMarca) then
        TAppErrors.RaiseBadRequest(
          'Não foi possível excluir esta marca.' +
          'Para manter o histórico, inative a marca em vez de excluir.');

    finally
      MarcaAtual.Free;
    end;
  finally
    Conn.Free;
  end;

end;

class function TMarcaService.Listar(const AIdEmpresa: Integer; const APesquisa: string): TObjectList<TMarcaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TMarcaDAO.Listar(Conn, AIdEmpresa, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TMarcaService.BuscarMarca(const AIdEmpresa, AIdMarca: Int64): TMarcaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdMarca <= 0 then
    TAppErrors.RaiseBadRequest('Marca não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TMarcaDAO.BuscarPorId(Conn, AIdEmpresa, AIdMarca);

    if Result = nil then
      TAppErrors.RaiseNotFound('Marca não encontrado.');
  finally
    Conn.Free;
  end;
end;

{$ENDREGION}

end.
