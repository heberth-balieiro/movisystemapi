unit EasyOneIntegracao.Service;

interface

type
  TEasyOneIntegracaoContexto = record
    IdEmpresaAPI: Integer;  // empresa.id
    IdEmpresa   : Integer;  // empresa.id_empresa do EasyOne
    UUID        : string;
  end;

  TEasyOneIntegracaoService = class
  private
    class function GerarHash(const AValor: string): string; static;
    class function HashIgual(const AHash1, AHash2: string): Boolean; static;
  public
    class function Autenticar(const AUUID, AAPIKey: string): TEasyOneIntegracaoContexto; static;
    class procedure ValidarBootstrap(const AUsuario, ASenha: string); static;
  end;

implementation

uses
  System.SysUtils,
  System.Hash,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  EasyOneIntegracao.Dao,
  System.IniFiles;

{ TEasyOneIntegracaoService }

class function TEasyOneIntegracaoService.GerarHash(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(Trim(AValor)));
end;

class function TEasyOneIntegracaoService.HashIgual(const AHash1, AHash2: string): Boolean;
var
  I, Diferenca: Integer;
  Hash1, Hash2: string;
begin
  Hash1 := UpperCase(Trim(AHash1));
  Hash2 := UpperCase(Trim(AHash2));

  if Length(Hash1) <> Length(Hash2) then
    Exit(False);

  Diferenca := 0;

  for I := 1 to Length(Hash1) do
    Diferenca := Diferenca or (Ord(Hash1[I]) xor Ord(Hash2[I]));

  Result := Diferenca = 0;
end;

class procedure TEasyOneIntegracaoService.ValidarBootstrap(const AUsuario,ASenha: string);
var
  Ini: TIniFile;
  UsuarioConfig, SenhaConfig: string;
begin
  if Trim(AUsuario).IsEmpty or Trim(ASenha).IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  try
    UsuarioConfig := Trim(Ini.ReadString('API','Usuario',''));
    SenhaConfig   := Trim(Ini.ReadString('API','Senha',''));
  finally
    Ini.Free;
  end;
  if UsuarioConfig.IsEmpty or SenhaConfig.IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  if not SameText(Trim(AUsuario),UsuarioConfig) then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  if not HashIgual(Trim(ASenha),SenhaConfig) then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
end;

class function TEasyOneIntegracaoService.Autenticar(const AUUID, AAPIKey: string): TEasyOneIntegracaoContexto;
var
  Config: TAppApiConfig;
  Conn  : TUniConnection;
  Dados : TEasyOneIntegracaoDados;
  Hash  : string;
begin
  Result := Default(TEasyOneIntegracaoContexto);

  if Trim(AUUID).IsEmpty or Trim(AAPIKey).IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração não informadas.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEasyOneIntegracaoDAO.BuscarEmpresaPorUUID(Conn,AUUID,Dados) then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if not SameText(Trim(Dados.Ativo),'S') then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if not SameText(Trim(Dados.IntegracaoAtiva),'S') then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if Trim(Dados.APIKeyHash).IsEmpty then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    Hash := GerarHash(AAPIKey);

    if not HashIgual(Hash,Dados.APIKeyHash) then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    Result.IdEmpresaAPI := Dados.Id;
    Result.IdEmpresa    := Dados.IdEmpresa;
    Result.UUID         := Dados.UUID;
  finally
    Conn.Free;
  end;
end;

end.
