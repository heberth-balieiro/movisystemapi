unit CatalogoConfig.Service;

interface

uses
  System.SysUtils,
  CatalogoConfig.Model,
  Uni;

type
  TCatalogoConfigService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class function NormalizarSlug(const ASlug: string): string; static;
    class procedure ValidarConfig(const AConfig: TCatalogoConfigModel); static;

  public
    class function SalvarConfig(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64; static;

    class function BuscarPorEmpresa(const AIdEmpresa: Int64): TCatalogoConfigModel; static;

    class function BuscarPorSlug(const ASlug: string): TCatalogoConfigModel; static;

    class function BuscarPorConfigWhatsApp: TCatalogoConfigModel; static;

    class function InserirConfig(const AConn: TUniConnection;
    const AIdEmpresa: Int64; const AConfig: TCatalogoConfigModel): Int64; static;

    class function SalvarConfigWhatsapp(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64; static;

    class function ConexaoLimparToken(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64; static;

  end;

implementation

uses

  App.Config,
  APP.Errors,
  Database.Connection,
  CatalogoConfig.DAO;

class function TCatalogoConfigService.NormalizarSN(const AValor, APadrao: string): string;
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

class function TCatalogoConfigService.NormalizarSlug(const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));

  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  if S.StartsWith('-') then
    Delete(S, 1, 1);

  if S.EndsWith('-') then
    Delete(S, Length(S), 1);

  Result := S;
end;

class procedure TCatalogoConfigService.ValidarConfig(const AConfig: TCatalogoConfigModel);
begin
  if AConfig = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');

  if AConfig.IdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa da configuração não informada.');

  AConfig.Slug := NormalizarSlug(AConfig.Slug);

  if Trim(AConfig.Slug).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o slug do catálogo.');

  if Length(Trim(AConfig.Slug)) > 120 then
    TAppErrors.RaiseBadRequest('O slug deve possuir no máximo 120 caracteres.');

  if Trim(AConfig.TituloCatalogo).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o título do catálogo.');

  if Length(Trim(AConfig.TituloCatalogo)) > 150 then
    TAppErrors.RaiseBadRequest('O título do catálogo deve possuir no máximo 150 caracteres.');

  if Length(Trim(AConfig.CorPrimaria)) > 20 then
    TAppErrors.RaiseBadRequest('A cor primária deve possuir no máximo 20 caracteres.');

  if Length(Trim(AConfig.CorSecundaria)) > 20 then
    TAppErrors.RaiseBadRequest('A cor secundária deve possuir no máximo 20 caracteres.');

  if Length(Trim(AConfig.LogoUrl)) > 500 then
    TAppErrors.RaiseBadRequest('A URL do logo deve possuir no máximo 500 caracteres.');

  if Length(Trim(AConfig.BannerUrl)) > 500 then
    TAppErrors.RaiseBadRequest('A URL do banner deve possuir no máximo 500 caracteres.');

  if AConfig.ValorMinimoPedido < 0 then
    TAppErrors.RaiseBadRequest('O valor mínimo do pedido não pode ser negativo.');

  if Aconfig.tipo_catalogo.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o tipo de catalogo.');

  AConfig.TituloCatalogo    := Trim(AConfig.TituloCatalogo);
  AConfig.Descricao         := Trim(AConfig.Descricao);
  AConfig.CorPrimaria       := Trim(AConfig.CorPrimaria);
  AConfig.CorSecundaria     := Trim(AConfig.CorSecundaria);
  AConfig.LogoUrl           := Trim(AConfig.LogoUrl);
  AConfig.BannerUrl         := Trim(AConfig.BannerUrl);

  AConfig.MostrarPreco      := NormalizarSN(AConfig.MostrarPreco, 'S');
  AConfig.PermitirObservacao := NormalizarSN(AConfig.PermitirObservacao, 'S');
  AConfig.PermitirRetirada  := NormalizarSN(AConfig.PermitirRetirada, 'S');
  AConfig.PermitirEntrega   := NormalizarSN(AConfig.PermitirEntrega, 'N');
  AConfig.Ativo             := NormalizarSN(AConfig.Ativo, 'S');

  Aconfig.permitirficha     := NormalizarSN(AConfig.permitirficha, 'N');

  AConfig.Ecommerce         := NormalizarSN(AConfig.Ecommerce, 'N');
  AConfig.PagSeguro         := NormalizarSN(AConfig.PagSeguro, 'N');
  AConfig.PagSeguroToken    := Trim(AConfig.PagSeguroToken);
  AConfig.PagSeguroAmbiente := UpperCase(Trim(AConfig.PagSeguroAmbiente));

  if AConfig.PagSeguroAmbiente.IsEmpty then
    AConfig.PagSeguroAmbiente := 'PRODUCAO';

  if (AConfig.PagSeguroAmbiente <> 'PRODUCAO') and
     (AConfig.PagSeguroAmbiente <> 'SANDBOX') then
    TAppErrors.RaiseBadRequest('Ambiente do PagSeguro inválido.');

  if AConfig.Ecommerce = 'N' then
  begin
    AConfig.PagSeguro := 'N';
    AConfig.PagSeguroToken := '';
  end;

  if (AConfig.Ecommerce = 'S') and
     (AConfig.PagSeguro = 'S') and
     AConfig.PagSeguroToken.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o token do PagSeguro.');


end;

class function TCatalogoConfigService.SalvarConfig(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ConfigAtual: TCatalogoConfigModel;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AConfig = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');

  AConfig.IdEmpresa := AIdEmpresa;

  ValidarConfig(AConfig);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TCatalogoConfigDAO.ExisteSlug(Conn, AConfig.Slug, AIdEmpresa) then
      TAppErrors.RaiseBadRequest('Este slug já está sendo utilizado por outro catálogo.');

    ConfigAtual := TCatalogoConfigDAO.BuscarPorEmpresa(Conn, AIdEmpresa);
    try
      if ConfigAtual = nil then
      begin
        Result := TCatalogoConfigDAO.Inserir(Conn, AConfig);
      end
      else
      begin
        AConfig.IdConfig      := ConfigAtual.IdConfig;
        TCatalogoConfigDAO.Atualizar(Conn, AConfig);
        Result := ConfigAtual.IdConfig;
      end;
    finally
      ConfigAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TCatalogoConfigService.SalvarConfigWhatsapp(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ConfigAtual: TCatalogoConfigModel;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AConfig = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');

  AConfig.IdEmpresa := AIdEmpresa;

  //ValidarConfig(AConfig);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try

    ConfigAtual     := TCatalogoConfigDAO.BuscarPorEmpresa(Conn, AIdEmpresa);
    try
      if ConfigAtual = nil then
      begin
        TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');
      end
      else
      begin
        AConfig.IdConfig        := ConfigAtual.IdConfig;
        TCatalogoConfigDAO.AtualizarConexao(Conn, AConfig);
        Result := ConfigAtual.IdConfig;
      end;
    finally
      ConfigAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TCatalogoConfigService.ConexaoLimparToken(const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  ConfigAtual: TCatalogoConfigModel;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AConfig = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');

  AConfig.IdEmpresa := AIdEmpresa;

  //ValidarConfig(AConfig);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try

    ConfigAtual     := TCatalogoConfigDAO.BuscarPorEmpresa(Conn, AIdEmpresa);
    try
      if ConfigAtual = nil then
      begin
        TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');
      end
      else
      begin
        AConfig.IdConfig        := ConfigAtual.IdConfig;
        TCatalogoConfigDAO.ConexaoLimparToken(Conn, AConfig);
        Result := ConfigAtual.IdConfig;
      end;
    finally
      ConfigAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;



//
class function TCatalogoConfigService.InserirConfig(const AConn: TUniConnection;const AIdEmpresa: Int64;const AConfig: TCatalogoConfigModel): Int64;
var
  Config: TAppApiConfig;
  //Conn: TUniConnection;
  ConfigAtual: TCatalogoConfigModel;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AConfig = nil then
    TAppErrors.RaiseBadRequest('Dados da configuração do catálogo não informados.');

  AConfig.IdEmpresa := AIdEmpresa;

  ValidarConfig(AConfig);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  //Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TCatalogoConfigDAO.ExisteSlug(AConn, AConfig.Slug, AIdEmpresa) then
      TAppErrors.RaiseBadRequest('Este slug já está sendo utilizado por outro catálogo.');

    ConfigAtual := TCatalogoConfigDAO.BuscarPorEmpresa(AConn, AIdEmpresa);
    try
      if ConfigAtual = nil then
      begin
        Result := TCatalogoConfigDAO.Inserir(AConn, AConfig);
      end
      else
      begin
        AConfig.IdConfig := ConfigAtual.IdConfig;
        TCatalogoConfigDAO.Atualizar(AConn, AConfig);
        Result := ConfigAtual.IdConfig;
      end;
    finally
      ConfigAtual.Free;
    end;
  finally
    //Conn.Free;
  end;
end;


class function TCatalogoConfigService.BuscarPorEmpresa(const AIdEmpresa: Int64): TCatalogoConfigModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCatalogoConfigDAO.BuscarPorEmpresa(Conn, AIdEmpresa);

    if Result = nil then
      TAppErrors.RaiseNotFound('Configuração do catálogo não encontrada.');
  finally
    Conn.Free;
  end;
end;

class function TCatalogoConfigService.BuscarPorConfigWhatsApp(): TCatalogoConfigModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCatalogoConfigDAO.BuscarPorConfigWhatsApp(Conn);

    if Result = nil then
      TAppErrors.RaiseNotFound('Configuração do catálogo não encontrada.');
  finally
    Conn.Free;
  end;
end;

class function TCatalogoConfigService.BuscarPorSlug(const ASlug: string): TCatalogoConfigModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
begin
  Result := nil;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCatalogoConfigDAO.BuscarPorSlug(Conn, Slug);

    if Result = nil then
      TAppErrors.RaiseNotFound('Catálogo não encontrado.');

    if UpperCase(Trim(Result.Ativo)) <> 'S' then
      TAppErrors.RaiseForbidden('Catálogo inativo.');
  finally
    Conn.Free;
  end;
end;

end.
