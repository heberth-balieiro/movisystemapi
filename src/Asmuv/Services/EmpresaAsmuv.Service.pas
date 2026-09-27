unit EmpresaAsmuv.Service;

interface

uses
  Uni,
  System.SysUtils,
  System.Generics.Collections,
  EmpresaAsmuv.Model,
  EmpresaAsmuv.DAO,
  App.Config,
  Database.Connection,
  APP.Errors;

type
  TCadastroEmpresaResult = record
    IdEmpresa: Int64;
end;

Type
TEmpresaService = class
  private

    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarCadastroEmpresa(const AEmpresa: TEmpresaModel); static;

  public

    class function InserirEmpresa(const AEmpresa: TEmpresaModel): TCadastroEmpresaResult; static;
    class procedure AtualizarEmpresa(const AIdEmpresa: Int64;const AEmpresa: TEmpresaModel); static;

  end;

implementation

{ TEmpresaService }

class procedure TEmpresaService.AtualizarEmpresa(const AIdEmpresa: Int64;const AEmpresa: TEmpresaModel);
var
  Config      : TAppApiConfig;
  Conn        : TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  AEmpresa.IdEmpresa    := AIdEmpresa;
  ValidarCadastroEmpresa(AEmpresa);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try

    Try
      TEmpresaDAO.Atualizar(Conn, AIdEmpresa, AEmpresa);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TEmpresaService.InserirEmpresa(const AEmpresa: TEmpresaModel): TCadastroEmpresaResult;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
begin
  Result.IdEmpresa := 0;

  ValidarCadastroEmpresa(AEmpresa);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;

    try
      if TEmpresaDAO.ExisteEmpresa(Conn, AEmpresa.IdEmpresa, AEmpresa.RazaoSocial) then
        TAppErrors.RaiseBadRequest('Empresa já cadastrado.');

      Result.IdEmpresa            := TEmpresaDAO.Inserir(Conn, 0, AEmpresa);

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TEmpresaService.NormalizarSN(const AValor,APadrao: string): string;
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

class procedure TEmpresaService.ValidarCadastroEmpresa(const AEmpresa: TEmpresaModel);
begin
  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  if AEmpresa.RazaoSocial.IsEmpty then
    TAppErrors.RaiseBadRequest('Razão Social não informado.');

  if AEmpresa.NomeFantasia.IsEmpty then
    TAppErrors.RaiseBadRequest('Nome Fantasia não informado.');

  if AEmpresa.Ativo.IsEmpty then
    TAppErrors.RaiseBadRequest('Campo ativo não informado.');

end;

end.
