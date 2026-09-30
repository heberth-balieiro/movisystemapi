unit App.Config;

interface

uses
  System.IniFiles;

type
  TAppProduto = (apCatalogo, apEasyOne, apMoviSystem);

  TAppJWTConfig = record
    Secret: string;
    Issuer: string;
    TtlMinutos: Integer;
    //Novo para admin
    TtlIdentificacaoMinutos: Integer;
    TtlVotacaoMinutos: Integer;
    TtlAdminMinutos: Integer;
  end;

  TAppDatabaseConfig = record
    Driver: string;
    Server: string;
    Port: Integer;
    Database: string;
    Username: string;
    Password: string;
  end;

  TAppUploadConfig = record
    Pasta: string;
    PublicURL: string;
    MaxMB: Integer;
  end;

  TAppWebConfig = record
    PublicURL: string;
  end;

  TAppApiConfig = record
    Produto: TAppProduto;
    Porta: Integer;
    SSL: Boolean;
    UsuarioBasic: string;
    SenhaBasic: string;
    JWT: TAppJWTConfig;
    Database: TAppDatabaseConfig;
    Upload: TAppUploadConfig;
    Web: TAppWebConfig;
  end;

  TAppConfig = class
  private
    class function LerProduto(const AValor: string): TAppProduto; static;
  public
    class function Carregar(const ACaminhoIni: string): TAppApiConfig; static;
  end;

implementation

uses
  System.SysUtils;

class function TAppConfig.LerProduto(const AValor: string): TAppProduto;
var
  LProduto: string;
begin
  LProduto := UpperCase(Trim(AValor));

  if LProduto = 'EASYONE' then
    Exit(apEasyOne);

  if LProduto = 'CATALOGO' then
    Exit(apCatalogo);

  if LProduto = 'MOVISYSTEM' then
    Exit(apMoviSystem);

  raise Exception.Create(
    'APP.Produto inválido no Config.ini. Valores permitidos: CATALOGO, EASYONE ou MOVISYSTEM. Valor recebido: "' +
    Trim(AValor) + '".'
  );
end;

class function TAppConfig.Carregar(const ACaminhoIni: string): TAppApiConfig;
var
  Ini: TIniFile;
  PortaStr: string;
  SSLStr: string;
begin
  if not FileExists(ACaminhoIni) then
    raise Exception.Create('Config.ini não encontrado em: ' + ACaminhoIni);

  Ini := TIniFile.Create(ACaminhoIni);
  try
    // O produto é obrigatório. Nunca assumir módulo por padrão,
    // pois a mesma API atende bancos e estruturas diferentes.
    PortaStr := Trim(Ini.ReadString('APP', 'Produto', ''));

    if PortaStr.IsEmpty then
      raise Exception.Create(
        'APP.Produto não configurado no Config.ini. Informe CATALOGO, EASYONE ou MOVISYSTEM.'
      );

    Result.Produto := LerProduto(PortaStr);

    // --- DATABASE / DADOS
    Result.Database.Driver   := Ini.ReadString('DADOS', 'DriverID', 'MySQL');
    Result.Database.Server   := Ini.ReadString('DADOS', 'Server', 'localhost');
    Result.Database.Port     := Ini.ReadInteger('DADOS', 'Port', 3306);
    Result.Database.Database := Ini.ReadString('DADOS', 'Database', '');
    Result.Database.Username := Ini.ReadString('DADOS', 'User_Name', '');
    Result.Database.Password := Ini.ReadString('DADOS', 'Password', '');

    if Result.Database.Database.Trim.IsEmpty then
      raise Exception.Create('DADOS.Database não configurado no Config.ini.');

    if Result.Database.Server.Trim.IsEmpty then
      raise Exception.Create('DADOS.Server não configurado no Config.ini.');

    if Result.Database.Username.Trim.IsEmpty then
      raise Exception.Create('DADOS.User_Name não configurado no Config.ini.');

    if Result.Database.Port <= 0 then
      Result.Database.Port := 3306;

    // --- API
    PortaStr := Ini.ReadString('API', 'Porta', '9000');
    Result.Porta := StrToIntDef(Trim(PortaStr), 9000);

    SSLStr := Ini.ReadString('API', 'SSL', 'False');
    Result.SSL :=
      SameText(Trim(SSLStr), 'True') or
      SameText(Trim(SSLStr), '1') or
      SameText(Trim(SSLStr), 'S') or
      SameText(Trim(SSLStr), 'Sim');

    Result.UsuarioBasic := Ini.ReadString('API', 'Usuario', '');
    Result.SenhaBasic   := Ini.ReadString('API', 'Senha', '');

    if Result.Porta <= 0 then
      Result.Porta := 9000;

    // --- JWT
    Result.JWT.Secret                   := Ini.ReadString('JWT', 'Secret', '');
    Result.JWT.Issuer                   := Ini.ReadString('JWT', 'Issuer', 'EASYONEDIGITAL');
    Result.JWT.TtlMinutos               := Ini.ReadInteger('JWT', 'TTL_Minutos', 60);
    // --- Alteracao para admin
    Result.JWT.TtlIdentificacaoMinutos  := Ini.ReadInteger('JWT', 'TTL_Identificacao_Minutos', 10);
    Result.JWT.TtlVotacaoMinutos        := Ini.ReadInteger('JWT', 'TTL_Votacao_Minutos', 30);
    Result.JWT.TtlAdminMinutos          := Ini.ReadInteger('JWT', 'TTL_Admin_Minutos', 120);

    if Result.JWT.Secret.Trim.IsEmpty then
      raise Exception.Create('JWT.Secret não configurado no Config.ini.');

    if Result.JWT.Issuer.Trim.IsEmpty then
      Result.JWT.Issuer     := 'EASYONEDIGITAL';

    if Result.JWT.TtlMinutos <= 0 then
      Result.JWT.TtlMinutos     := 60;

    // --- Validar os campos admin votacao
    if Result.JWT.TtlIdentificacaoMinutos <= 0 then
      Result.JWT.TtlIdentificacaoMinutos := 10;
    if Result.JWT.TtlVotacaoMinutos <= 0 then
      Result.JWT.TtlVotacaoMinutos := 30;
    if Result.JWT.TtlAdminMinutos <= 0 then
      Result.JWT.TtlAdminMinutos := 120;

    // --- UPLOAD
    Result.Upload.Pasta       := Ini.ReadString('UPLOAD', 'Pasta', 'uploads');
    Result.Upload.PublicURL   := Ini.ReadString('UPLOAD', 'PublicURL', 'http://localhost:9000/v1/public/arquivos');
    Result.Upload.MaxMB       := Ini.ReadInteger('UPLOAD', 'MaxMB', 5);

    if Result.Upload.MaxMB <= 0 then
      Result.Upload.MaxMB := 5;

    // --- WEB / FRONTEND PÚBLICO
    Result.Web.PublicURL :=
      Ini.ReadString(
        'WEB',
        'PublicURL',
        'http://localhost:3000'
      );

    while Result.Web.PublicURL.EndsWith('/') do
      Delete(
        Result.Web.PublicURL,
        Length(Result.Web.PublicURL),
        1
      );
  finally
    Ini.Free;
  end;
end;

end.
