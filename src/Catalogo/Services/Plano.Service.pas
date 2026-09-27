unit Plano.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Plano.Model;

type
  TPlanoService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarPlano(const APlano: TPlanoModel); static;

  public
    class function CriarPlano(const APlano: TPlanoModel): Int64; static;
    class function ListarPlanos(const APesquisa: string = ''): TObjectList<TPlanoModel>; static;
    class function ListarPlanosDash: TObjectList<TPlanoModel>; static;
    class function BuscarPlano(const AIdPlano: Int64): TPlanoModel; static;
    class procedure AtualizarPlano(const AIdPlano: Int64;const APlano: TPlanoModel); static;
    class procedure ExcluirPlano(const AIdPlano: Int64); static;

  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Plano.DAO;

class function TPlanoService.NormalizarSN(const AValor, APadrao: string): string;
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

class procedure TPlanoService.ValidarPlano(const APlano: TPlanoModel);
begin
  if APlano = nil then
    TAppErrors.RaiseBadRequest('Dados do plano não informados.');

  if Trim(APlano.Descricao).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a descrição do plano.');

  if Length(Trim(APlano.Descricao)) > 150 then
    TAppErrors.RaiseBadRequest('A descrição do plano deve possuir no máximo 150 caracteres.');

  if APlano.Valor < 0 then
    TAppErrors.RaiseBadRequest('O valor do plano não pode ser negativo.');

  if APlano.CatalogoQtde < 0 then
    APlano.CatalogoQtde := 0;

  APlano.Descricao              := Trim(APlano.Descricao);
  APlano.Catalogo               := NormalizarSN(APlano.Catalogo, 'S');
  APlano.Interno                := NormalizarSN(APlano.Interno, 'N');
  APlano.Ativo                  := NormalizarSN(APlano.Ativo, 'S');
  APlano.PermiteProdutoIlimitado:= NormalizarSN(APlano.PermiteProdutoIlimitado, 'N');
  APlano.PermiteWhatsapp        := NormalizarSN(APlano.PermiteWhatsapp, 'N');
  APlano.PermiteEmail           := NormalizarSN(APlano.PermiteEmail, 'N');
  APlano.PermitePedido          := NormalizarSN(APlano.PermitePedido, 'N');
  APlano.PermiteEcommerce       := NormalizarSN(APlano.PermiteEcommerce, 'N');
  APlano.PermitePagSeguro       := NormalizarSN(APlano.PermitePagSeguro, 'N');
  APlano.PermitePedidoFicha     := NormalizarSN(APlano.PermitePedidoFicha, 'N');
  APlano.PermiteConfigVisual    := NormalizarSN(APlano.PermiteConfigVisual, 'N');
  Aplano.permiteconfigcupom     := NormalizarSN(Aplano.permiteconfigcupom,'N');

end;

class function TPlanoService.CriarPlano(const APlano: TPlanoModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  ValidarPlano(APlano);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TPlanoDAO.ExisteDescricao(Conn, APlano.Descricao) then
      TAppErrors.RaiseBadRequest('Já existe um plano com esta descrição.');

    Result := TPlanoDAO.Inserir(Conn, APlano);
  finally
    Conn.Free;
  end;
end;

class function TPlanoService.ListarPlanos(const APesquisa: string): TObjectList<TPlanoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlanoDAO.Listar(Conn, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TPlanoService.ListarPlanosDash: TObjectList<TPlanoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlanoDAO.ListarDash(Conn);
  finally
    Conn.Free;
  end;
end;

class function TPlanoService.BuscarPlano(const AIdPlano: Int64): TPlanoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdPlano <= 0 then
    TAppErrors.RaiseBadRequest('Plano não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlanoDAO.BuscarPorId(Conn, AIdPlano);

    if Result = nil then
      TAppErrors.RaiseNotFound('Plano não encontrado.');
  finally
    Conn.Free;
  end;
end;

class procedure TPlanoService.AtualizarPlano(const AIdPlano: Int64;const APlano: TPlanoModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  PlanoAtual: TPlanoModel;
begin
  if AIdPlano <= 0 then
    TAppErrors.RaiseBadRequest('Plano não informado.');

  if APlano = nil then
    TAppErrors.RaiseBadRequest('Dados do plano não informados.');

  APlano.IdPlano := AIdPlano;
  ValidarPlano(APlano);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    PlanoAtual := TPlanoDAO.BuscarPorId(Conn, AIdPlano);
    try
      if PlanoAtual = nil then
        TAppErrors.RaiseNotFound('Plano não encontrado.');

      if TPlanoDAO.ExisteDescricao(Conn, APlano.Descricao, AIdPlano) then
        TAppErrors.RaiseBadRequest('Já existe outro plano com esta descrição.');

      TPlanoDAO.Atualizar(Conn, APlano);
    finally
      PlanoAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TPlanoService.ExcluirPlano(const AIdPlano: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  PlanoAtual: TPlanoModel;
begin
  if AIdPlano <= 0 then
    TAppErrors.RaiseBadRequest('Plano não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    PlanoAtual := TPlanoDAO.BuscarPorId(Conn, AIdPlano);
    try
      if PlanoAtual = nil then
        TAppErrors.RaiseNotFound('Plano não encontrado.');

      TPlanoDAO.Excluir(Conn, AIdPlano);
    finally
      PlanoAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
