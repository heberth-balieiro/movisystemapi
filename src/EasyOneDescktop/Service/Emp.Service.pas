unit Emp.Service;

interface

uses
  Uni,
  System.SysUtils,
  System.Generics.Collections,
  Emp.Model,
  Emp.DAO,
  App.Config,
  Database.Connection,
  APP.Errors,
  App.JWT;

type
  TCadastroEmpresaResult = record
    RetID   : Integer;
  end;

type
  TEmpresasServices = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class function HashSHA256Valido(const AValor: string): Boolean; static;
    class procedure ValidarCadastroEmpresa(const AEmpresa: TEmpresasModel); static;
  public
    class function InserirEmpresa(const AEmpresa: TEmpresasModel): TCadastroEmpresaResult; static;
  end;

implementation

{ TEmpresasServices }

class function TEmpresasServices.InserirEmpresa(const AEmpresa: TEmpresasModel): TCadastroEmpresaResult;
var
  Conn  : TUniConnection;
  Config: TAppApiConfig;
  Roles : TArray<string>;
  AID   : Integer;
begin
  Result.RetID := 0;

  if AEmpresa <> nil then
  begin
    AEmpresa.ativo := NormalizarSN(AEmpresa.ativo, 'S');
    AEmpresa.easyone_integracao_ativo := NormalizarSN(AEmpresa.easyone_integracao_ativo, 'N');
    AEmpresa.easyone_api_key_hash := UpperCase(Trim(AEmpresa.easyone_api_key_hash));
    AEmpresa.whatsapp_url := Trim(AEmpresa.whatsapp_url);
    AEmpresa.whatsapp_instancia := Trim(AEmpresa.whatsapp_instancia);
    AEmpresa.whatsapp_token := Trim(AEmpresa.whatsapp_token);
  end;

  ValidarCadastroEmpresa(AEmpresa);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try

      if TEmpDAO.ExisteEmpresa(AID, Conn, AEmpresa.id_empresa, AEmpresa.uuid) then
      begin
        TEmpDAO.Atualizar(Conn, AEmpresa);
        Result.RetID := AID;
      end
      else
      begin
        // Para nova empresa, não permite ativar integração sem uma chave.
        if SameText(AEmpresa.easyone_integracao_ativo, 'S') and
           Trim(AEmpresa.easyone_api_key_hash).IsEmpty then
          TAppErrors.RaiseBadRequest('Hash da chave de integração EasyOne não informado.');

        Result.RetID := TEmpDAO.Inserir(Conn, AEmpresa);
      end;

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TEmpresasServices.NormalizarSN(const AValor, APadrao: string): string;
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

class function TEmpresasServices.HashSHA256Valido(const AValor: string): Boolean;
var
  C    : Char;
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Exit(True);

  if Length(Valor) <> 64 then
    Exit(False);

  for C in Valor do
    if not CharInSet(C, ['0'..'9', 'A'..'F']) then
      Exit(False);

  Result := True;
end;

class procedure TEmpresasServices.ValidarCadastroEmpresa(const AEmpresa: TEmpresasModel);
begin
  if AEmpresa = nil then
    TAppErrors.RaiseBadRequest('Dados da empresa não informados.');

  if AEmpresa.id_empresa <= 0 then
    TAppErrors.RaiseBadRequest('Código da empresa não informado.');

  if Trim(AEmpresa.razao).IsEmpty then
    TAppErrors.RaiseBadRequest('Razão Social não informada.');

  if Trim(AEmpresa.uuid).IsEmpty then
    TAppErrors.RaiseBadRequest('UUID não informado.');

  if Trim(AEmpresa.cpfcnpj).IsEmpty then
    TAppErrors.RaiseBadRequest('CPF/CNPJ não informado.');

  if not HashSHA256Valido(AEmpresa.easyone_api_key_hash) then
    TAppErrors.RaiseBadRequest('Hash da chave de integração EasyOne inválido.');
end;

end.
