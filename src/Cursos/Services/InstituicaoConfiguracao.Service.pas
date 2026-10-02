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
    class function EmailValido(const AEmail: string): Boolean; static;

  public
    class function BuscarInstituicao(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TJSONObject; static;

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

    class function BuscarEmail(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoEmailConfig; static;

    class function AtualizarEmail(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoEmailInput
    ): TInstituicaoEmailConfig; static;

    class function ObterEmailConfigurado(
      const AIdInstituicao: Int64;
      out AConfig: TInstituicaoEmailConfig;
      out ASenha: string
    ): Boolean; static;

    class function BuscarAutoCadastro(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoAutoCadastroConfig; static;

    class function AtualizarAutoCadastro(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoAutoCadastroInput
    ): TInstituicaoAutoCadastroConfig; static;

    class function BuscarCertificacao(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoCertificacaoConfig; static;

    class function AtualizarCertificacao(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoCertificacaoInput
    ): TInstituicaoCertificacaoConfig; static;

    class function PermiteTurmaSomenteCertificacao(
      const AIdInstituicao: Int64
    ): Boolean; static;

    class function BuscarAcessoEnvio(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoAcessoEnvioConfig; static;

    class function AtualizarAcessoEnvio(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoAcessoEnvioInput
    ): TInstituicaoAcessoEnvioConfig; static;

    class function ObterAcessoEnvio(
      const AIdInstituicao: Int64
    ): TInstituicaoAcessoEnvioConfig; static;

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

class function TInstituicaoConfiguracaoService.BuscarInstituicao(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoConfiguracaoDAO.BuscarInstituicao(Conn, AIdInstituicao);
    if Result = nil then
      TAppErrors.RaiseBadRequest('Instituicao nao encontrada.');
  finally
    Conn.Free;
  end;
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


class function TInstituicaoConfiguracaoService.EmailValido(const AEmail: string): Boolean;
var
  P: Integer;
begin
  P := Pos('@', Trim(AEmail));
  Result := (P > 1) and (Pos('.', Copy(Trim(AEmail), P + 2, MaxInt)) > 0);
end;

class function TInstituicaoConfiguracaoService.BuscarEmail(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoEmailConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoConfiguracaoDAO.BuscarEmail(Conn, AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.AtualizarEmail(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoEmailInput
): TInstituicaoEmailConfig;
var
  AppConfig: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoEmailInput;
  TemSenha: Boolean;
begin
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);

  Dados := ADados;
  Dados.SmtpHost := Trim(Dados.SmtpHost);
  Dados.Seguranca := UpperCase(Trim(Dados.Seguranca));
  Dados.Usuario := Trim(Dados.Usuario);
  Dados.Senha := Trim(Dados.Senha);
  Dados.RemetenteNome := Trim(Dados.RemetenteNome);
  Dados.RemetenteEmail := LowerCase(Trim(Dados.RemetenteEmail));
  Dados.ResponderPara := LowerCase(Trim(Dados.ResponderPara));

  if Dados.SmtpPorta <= 0 then
    Dados.SmtpPorta := 587;

  if (Dados.SmtpPorta < 1) or (Dados.SmtpPorta > 65535) then
    TAppErrors.RaiseBadRequest('Porta SMTP inválida.');

  if not SameText(Dados.Seguranca, 'STARTTLS') and
     not SameText(Dados.Seguranca, 'SSL_TLS') and
     not SameText(Dados.Seguranca, 'NONE') then
    TAppErrors.RaiseBadRequest('Tipo de segurança SMTP inválido.');

  if Length(Dados.SmtpHost) > 255 then
    TAppErrors.RaiseBadRequest('Servidor SMTP inválido.');

  if Length(Dados.Usuario) > 254 then
    TAppErrors.RaiseBadRequest('Usuário SMTP inválido.');

  if Length(Dados.Senha) > 4096 then
    TAppErrors.RaiseBadRequest('Senha SMTP inválida.');

  if Length(Dados.RemetenteNome) > 180 then
    TAppErrors.RaiseBadRequest('Nome do remetente excede o tamanho permitido.');

  if (Dados.RemetenteEmail <> '') and not EmailValido(Dados.RemetenteEmail) then
    TAppErrors.RaiseBadRequest('E-mail do remetente inválido.');

  if (Dados.ResponderPara <> '') and not EmailValido(Dados.ResponderPara) then
    TAppErrors.RaiseBadRequest('E-mail de resposta inválido.');

  AppConfig := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(AppConfig.Database);
  try
    TemSenha := not Dados.Senha.IsEmpty;
    if not TemSenha then
      TemSenha := TInstituicaoConfiguracaoDAO.TemSenhaEmail(Conn, AIdInstituicao);

    if Dados.Ativo then
    begin
      if Dados.SmtpHost.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o servidor SMTP antes de ativar o envio.');

      if Dados.Usuario.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o usuário SMTP antes de ativar o envio.');

      if not TemSenha then
        TAppErrors.RaiseBadRequest('Informe a senha SMTP antes de ativar o envio.');

      if Dados.RemetenteNome.IsEmpty then
        TAppErrors.RaiseBadRequest('Informe o nome do remetente.');

      if Dados.RemetenteEmail.IsEmpty or not EmailValido(Dados.RemetenteEmail) then
        TAppErrors.RaiseBadRequest('Informe um e-mail válido para o remetente.');
    end;

    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.SalvarEmail(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao,
        Dados,
        TCertificaSecrets.EmailSmtpSecret
      );

      Result := TInstituicaoConfiguracaoDAO.BuscarEmail(Conn, AIdInstituicao);
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

class function TInstituicaoConfiguracaoService.ObterEmailConfigurado(
  const AIdInstituicao: Int64;
  out AConfig: TInstituicaoEmailConfig;
  out ASenha: string
): Boolean;
var
  AppConfig: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := False;
  ASenha := '';
  AConfig := Default(TInstituicaoEmailConfig);

  if AIdInstituicao <= 0 then
    Exit;

  AppConfig := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(AppConfig.Database);
  try
    AConfig := TInstituicaoConfiguracaoDAO.BuscarEmail(Conn, AIdInstituicao);

    if not AConfig.Ativo or
       AConfig.SmtpHost.IsEmpty or
       AConfig.Usuario.IsEmpty or
       not AConfig.SenhaConfigurada or
       AConfig.RemetenteEmail.IsEmpty then
      Exit;

    ASenha := TInstituicaoConfiguracaoDAO.ObterSenhaEmail(
      Conn,
      AIdInstituicao,
      TCertificaSecrets.EmailSmtpSecret
    );

    Result := not ASenha.IsEmpty;
  finally
    Conn.Free;
  end;
end;


class function TInstituicaoConfiguracaoService.BuscarAutoCadastro(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoAutoCadastroConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoConfiguracaoDAO.BuscarAutoCadastro(Conn, AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.AtualizarAutoCadastro(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoAutoCadastroInput
): TInstituicaoAutoCadastroConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.SalvarAutoCadastro(
        Conn,
        AIdInstituicao,
        ADados
      );
      Result := TInstituicaoConfiguracaoDAO.BuscarAutoCadastro(
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

class function TInstituicaoConfiguracaoService.BuscarCertificacao(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoCertificacaoConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuarioInstituicao,
    'turma.visualizar'
  );
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TInstituicaoConfiguracaoDAO.BuscarCertificacao(Conn, AIdInstituicao);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.AtualizarCertificacao(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoCertificacaoInput
): TInstituicaoCertificacaoConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(AIdInstituicao, AIdUsuarioInstituicao);
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.SalvarCertificacao(Conn, AIdInstituicao, ADados);
      Result := TInstituicaoConfiguracaoDAO.BuscarCertificacao(Conn, AIdInstituicao);
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

class function TInstituicaoConfiguracaoService.PermiteTurmaSomenteCertificacao(
  const AIdInstituicao: Int64
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCertificacaoConfig;
begin
  Result := False;
  if AIdInstituicao <= 0 then
    Exit;
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Dados := TInstituicaoConfiguracaoDAO.BuscarCertificacao(Conn, AIdInstituicao);
    Result := Dados.PermitirTurmaSomenteCertificacao;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.BuscarAcessoEnvio(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoAcessoEnvioConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) +
    'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );
  try
    Result :=
      TInstituicaoConfiguracaoDAO.BuscarAcessoEnvio(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoConfiguracaoService.AtualizarAcessoEnvio(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoAcessoEnvioInput
): TInstituicaoAcessoEnvioConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarTenant(
    AIdInstituicao,
    AIdUsuarioInstituicao
  );

  if not ADados.EnviarEmail and
     not ADados.EnviarWhatsApp then
    TAppErrors.RaiseBadRequest(
      'Selecione ao menos um canal para enviar o acesso ao participante.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) +
    'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );
  try
    Conn.StartTransaction;
    try
      TInstituicaoConfiguracaoDAO.SalvarAcessoEnvio(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao,
        ADados
      );

      Result :=
        TInstituicaoConfiguracaoDAO.BuscarAcessoEnvio(
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

class function TInstituicaoConfiguracaoService.ObterAcessoEnvio(
  const AIdInstituicao: Int64
): TInstituicaoAcessoEnvioConfig;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) +
    'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );
  try
    Result :=
      TInstituicaoConfiguracaoDAO.BuscarAcessoEnvio(
        Conn,
        AIdInstituicao
      );
  finally
    Conn.Free;
  end;
end;

end.
