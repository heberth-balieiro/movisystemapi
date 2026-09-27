unit InstituicaoConfiguracao.Service;

interface

uses
  System.Classes,
  System.JSON,
  InstituicaoConfiguracao.Model;

type
  TInstituicaoConfiguracaoService = class
  private
    class procedure ValidarTenant(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ); static;

    class function SomenteDigitos(
      const AValue: string
    ): string; static;

    class function DetectarExtensaoImagem(
      const AStream: TStream
    ): string; static;

    class function NovoNomeArquivo(
      const AExtensao: string
    ): string; static;

    class function DiretorioMidia(
      const AIdInstituicao: Int64;
      const ATipo: string
    ): string; static;

    class function CaminhoMidiaPublica(
      const AIdInstituicao: Int64;
      const ATipo,
            AArquivo: string
    ): string; static;

    class function NormalizarUrl(
      const AUrl: string
    ): string; static;

  public
    class function AtualizarInstituicao(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoDadosInput
    ): TJSONObject; static;

    class function SalvarMidia(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ATipo,
            ABaseUrl: string;
      const AStream: TStream
    ): TJSONObject; static;

    class function BuscarWhatsApp(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoWhatsAppConfig; static;

    class function AtualizarWhatsApp(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoWhatsAppInput
    ): TInstituicaoWhatsAppConfig; static;

    class function ResolverMidiaPublica(
      const AIdInstituicao: Int64;
      const ATipo,
            AArquivo: string
    ): string; static;

    class function ObterTokenWhatsApp(
      const AIdInstituicao: Int64
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Net.URLClient,
  Uni,
  App.Config,
  APP.Errors,
  App.JWT,
  Database.Connection,
  Certifica.Secrets,
  InstituicaoConfiguracao.DAO,
  InstituicaoPermissao.Service;

const
  MAX_IMAGE_SIZE = 5 * 1024 * 1024;

class procedure TInstituicaoConfiguracaoService.ValidarTenant(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
);
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'configuracao.editar'
  );
end;

class function TInstituicaoConfiguracaoService.SomenteDigitos(
  const AValue: string
): string;
var
  C: Char;
begin
  Result := '';
  for C in AValue do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class function TInstituicaoConfiguracaoService.NormalizarUrl(
  const AUrl: string
): string;
begin
  Result := Trim(AUrl);

  if Result = '' then
    Exit;

  if not (
    Result.ToLower.StartsWith('http://') or
    Result.ToLower.StartsWith('https://')
  ) then
    TAppErrors.RaiseBadRequest(
      'Informe uma URL HTTP ou HTTPS valida.'
    );
end;

class function TInstituicaoConfiguracaoService.AtualizarInstituicao(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoDadosInput
): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoDadosInput;
begin
  Result := nil;
  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  Dados := ADados;
  Dados.Nome := Trim(Dados.Nome);
  Dados.RazaoSocial := Trim(Dados.RazaoSocial);
  Dados.Cnpj := SomenteDigitos(Dados.Cnpj);
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.Email := Trim(Dados.Email);
  Dados.Telefone := Trim(Dados.Telefone);
  Dados.Site := Trim(Dados.Site);

  if Dados.Nome = '' then
    TAppErrors.RaiseBadRequest(
      'Informe o nome da instituicao.'
    );

  if Length(Dados.Nome) > 180 then
    TAppErrors.RaiseBadRequest(
      'O nome da instituicao deve possuir no maximo 180 caracteres.'
    );

  if (Dados.RazaoSocial <> '') and
     (Length(Dados.RazaoSocial) > 180) then
    TAppErrors.RaiseBadRequest(
      'A razao social deve possuir no maximo 180 caracteres.'
    );

  if (Dados.Cnpj <> '') and
     (Length(Dados.Cnpj) <> 14) then
    TAppErrors.RaiseBadRequest(
      'CNPJ invalido.'
    );

  if Length(Dados.Email) > 254 then
    TAppErrors.RaiseBadRequest(
      'E-mail invalido.'
    );

  if Length(Dados.Telefone) > 30 then
    TAppErrors.RaiseBadRequest(
      'Telefone invalido.'
    );

  if Length(Dados.Site) > 500 then
    TAppErrors.RaiseBadRequest(
      'Site invalido.'
    );

  if Dados.Site <> '' then
    Dados.Site := NormalizarUrl(Dados.Site);

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    if TInstituicaoConfiguracaoDAO.ExisteCnpjOutraInstituicao(
      Conn,
      AIdInstituicao,
      Dados.Cnpj
    ) then
      TAppErrors.RaiseBadRequest(
        'Ja existe outra instituicao utilizando este CNPJ.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.AtualizarDados(
        Conn,
        AIdInstituicao,
        Dados
      );

      TInstituicaoConfiguracaoDAO.GarantirConfiguracao(
        Conn,
        AIdInstituicao
      );

      Result :=
        TInstituicaoConfiguracaoDAO.BuscarInstituicao(
          Conn,
          AIdInstituicao
        );

      if Result = nil then
        raise Exception.Create(
          'Nao foi possivel recuperar a instituicao atualizada.'
        );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.DetectarExtensaoImagem(
  const AStream: TStream
): string;
var
  B: array[0..11] of Byte;
  Posicao: Int64;
  Lidos: Integer;
begin
  Result := '';

  if (AStream = nil) or (AStream.Size <= 0) then
    TAppErrors.RaiseBadRequest(
      'Arquivo nao informado.'
    );

  if AStream.Size > MAX_IMAGE_SIZE then
    TAppErrors.RaiseBadRequest(
      'A imagem deve possuir no maximo 5 MB.'
    );

  Posicao := AStream.Position;
  try
    AStream.Position := 0;
    FillChar(B, SizeOf(B), 0);
    Lidos := AStream.Read(B, SizeOf(B));

    if (Lidos >= 8) and
       (B[0] = $89) and
       (B[1] = $50) and
       (B[2] = $4E) and
       (B[3] = $47) and
       (B[4] = $0D) and
       (B[5] = $0A) and
       (B[6] = $1A) and
       (B[7] = $0A) then
      Exit('.png');

    if (Lidos >= 3) and
       (B[0] = $FF) and
       (B[1] = $D8) and
       (B[2] = $FF) then
      Exit('.jpg');

    if (Lidos >= 12) and
       (B[0] = Ord('R')) and
       (B[1] = Ord('I')) and
       (B[2] = Ord('F')) and
       (B[3] = Ord('F')) and
       (B[8] = Ord('W')) and
       (B[9] = Ord('E')) and
       (B[10] = Ord('B')) and
       (B[11] = Ord('P')) then
      Exit('.webp');

    TAppErrors.RaiseBadRequest(
      'Formato invalido. Utilize PNG, JPG ou WEBP.'
    );
  finally
    AStream.Position := Posicao;
  end;
end;

class function TInstituicaoConfiguracaoService.NovoNomeArquivo(
  const AExtensao: string
): string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result :=
    LowerCase(
      StringReplace(
        StringReplace(
          GUIDToString(G),
          '{',
          '',
          [rfReplaceAll]
        ),
        '}',
        '',
        [rfReplaceAll]
      )
    ) +
    AExtensao;
end;

class function TInstituicaoConfiguracaoService.DiretorioMidia(
  const AIdInstituicao: Int64;
  const ATipo: string
): string;
begin
  Result :=
    TPath.Combine(
      TPath.Combine(
        TPath.Combine(
          ExtractFilePath(ParamStr(0)),
          'uploads'
        ),
        'instituicoes'
      ),
      AIdInstituicao.ToString
    );

  Result :=
    TPath.Combine(
      Result,
      LowerCase(ATipo)
    );
end;

class function TInstituicaoConfiguracaoService.CaminhoMidiaPublica(
  const AIdInstituicao: Int64;
  const ATipo,
        AArquivo: string
): string;
begin
  Result :=
    TPath.Combine(
      DiretorioMidia(
        AIdInstituicao,
        ATipo
      ),
      AArquivo
    );
end;

class function TInstituicaoConfiguracaoService.SalvarMidia(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ATipo,
        ABaseUrl: string;
  const AStream: TStream
): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Tipo: string;
  Extensao: string;
  NomeArquivo: string;
  Diretorio: string;
  Caminho: string;
  Url: string;
  Arquivo: TFileStream;
begin
  Result := nil;

  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  Tipo := LowerCase(Trim(ATipo));

  if (Tipo <> 'logo') and
     (Tipo <> 'banner') then
    TAppErrors.RaiseBadRequest(
      'Tipo de midia invalido.'
    );

  Extensao :=
    DetectarExtensaoImagem(
      AStream
    );

  NomeArquivo :=
    NovoNomeArquivo(
      Extensao
    );

  Diretorio :=
    DiretorioMidia(
      AIdInstituicao,
      Tipo
    );

  ForceDirectories(
    Diretorio
  );

  Caminho :=
    TPath.Combine(
      Diretorio,
      NomeArquivo
    );

  AStream.Position := 0;

  Arquivo := TFileStream.Create(
    Caminho,
    fmCreate
  );
  try
    Arquivo.CopyFrom(
      AStream,
      0
    );
  finally
    Arquivo.Free;
  end;

  Url := ABaseUrl;
  while Url.EndsWith('/') do
    Delete(Url, Length(Url), 1);

  Url :=
    Url +
    '/v1/certifica/publico/midias/instituicoes/' +
    AIdInstituicao.ToString + '/' +
    Tipo + '/' +
    NomeArquivo;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.AtualizarMidia(
        Conn,
        AIdInstituicao,
        Tipo,
        Url
      );

      Result :=
        TInstituicaoConfiguracaoDAO.BuscarInstituicao(
          Conn,
          AIdInstituicao
        );

      if Result = nil then
        raise Exception.Create(
          'Nao foi possivel recuperar a instituicao apos o upload.'
        );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;

      if TFile.Exists(Caminho) then
        TFile.Delete(Caminho);

      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.BuscarWhatsApp(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoWhatsAppConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Result :=
      TInstituicaoConfiguracaoDAO.BuscarWhatsApp(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.AtualizarWhatsApp(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoWhatsAppInput
): TInstituicaoWhatsAppConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoWhatsAppInput;
  Secret: string;
begin
  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  Dados := ADados;
  Dados.Url := NormalizarUrl(Dados.Url);
  Dados.Token := Trim(Dados.Token);

  if Dados.Ativo and
     (Dados.Url = '') then
    TAppErrors.RaiseBadRequest(
      'Informe a URL da Evolution API.'
    );

  if Length(Dados.Url) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL da Evolution API deve possuir no maximo 1000 caracteres.'
    );

  if Length(Dados.Token) > 4096 then
    TAppErrors.RaiseBadRequest(
      'Token do WhatsApp invalido.'
    );

  Secret :=
    TCertificaSecrets.WhatsAppTokenSecret;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    if Dados.Ativo and
       (Dados.Token = '') and
       (not TInstituicaoConfiguracaoDAO.TemTokenWhatsApp(
          Conn,
          AIdInstituicao
       )) then
      TAppErrors.RaiseBadRequest(
        'Informe a chave/token da Evolution API.'
      );

    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.SalvarWhatsApp(
        Conn,
        AIdInstituicao,
        Dados,
        Secret
      );

      Result :=
        TInstituicaoConfiguracaoDAO.BuscarWhatsApp(
          Conn,
          AIdInstituicao
        );

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

class function TInstituicaoConfiguracaoService.ResolverMidiaPublica(
  const AIdInstituicao: Int64;
  const ATipo,
        AArquivo: string
): string;
var
  Tipo: string;
  Arquivo: string;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Instituicao invalida.'
    );

  Tipo := LowerCase(Trim(ATipo));

  if (Tipo <> 'logo') and
     (Tipo <> 'banner') then
    TAppErrors.RaiseBadRequest(
      'Tipo de midia invalido.'
    );

  Arquivo := ExtractFileName(Trim(AArquivo));

  if (Arquivo = '') or
     (Arquivo <> Trim(AArquivo)) then
    TAppErrors.RaiseBadRequest(
      'Arquivo invalido.'
    );

  Result :=
    CaminhoMidiaPublica(
      AIdInstituicao,
      Tipo,
      Arquivo
    );

  if not TFile.Exists(Result) then
    TAppErrors.RaiseBadRequest(
      'Arquivo nao encontrado.'
    );
end;

class function TInstituicaoConfiguracaoService.ObterTokenWhatsApp(
  const AIdInstituicao: Int64
): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Secret: string;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituicao nao identificada.'
    );

  Secret :=
    TCertificaSecrets.WhatsAppTokenSecret;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );
  try
    Result :=
      TInstituicaoConfiguracaoDAO.ObterTokenWhatsApp(
        Conn,
        AIdInstituicao,
        Secret
      );
  finally
    Conn.Free;
  end;
end;

end.

