unit InstituicaoConfiguracao.DAO;

interface

uses
  System.JSON,
  Uni,
  InstituicaoConfiguracao.Model;

type
  TInstituicaoConfiguracaoDAO = class
  public
    class function BuscarInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TJSONObject; static;

    class procedure AtualizarDados(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoDadosInput
    ); static;

    class function ExisteCnpjOutraInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACnpj: string
    ): Boolean; static;

    class procedure GarantirConfiguracao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ); static;

    class procedure AtualizarMidia(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ATipo,
            AUrl: string
    ); static;

    class function BuscarWhatsApp(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TInstituicaoWhatsAppConfig; static;

    class function TemTokenWhatsApp(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): Boolean; static;

    class procedure SalvarWhatsApp(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoWhatsAppInput;
      const ASecret: string
    ); static;

    class function ObterTokenWhatsApp(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ASecret: string
    ): string; static;

  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Data.DB;

class function TInstituicaoConfiguracaoDAO.BuscarInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TJSONObject;
var
  Qry: TUniQuery;
  Tema: TJSONObject;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT i.id, i.slug, i.nome_fantasia, i.razao_social, i.cnpj, ' +
      '       i.descricao, i.email, i.telefone, i.site, ' +
      '       c.nome_exibicao, c.logo_url, c.favicon_url, ' +
      '       c.imagem_login_url, c.banner_url, ' +
      '       c.cor_primaria, c.cor_secundaria, c.cor_destaque, ' +
      '       c.cor_fundo, c.cor_texto ' +
      'FROM instituicao i ' +
      'LEFT JOIN instituicao_configuracao c ' +
      '  ON c.id_instituicao = i.id ' +
      'WHERE i.id = :id_instituicao ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TJSONObject.Create;
    Result.AddPair('id', TJSONNumber.Create(Qry.FieldByName('id').AsLargeInt));
    Result.AddPair('slug', Qry.FieldByName('slug').AsString);
    Result.AddPair('nome', Qry.FieldByName('nome_fantasia').AsString);
    Result.AddPair('razao_social', Qry.FieldByName('razao_social').AsString);

    if Qry.FieldByName('cnpj').IsNull then
      Result.AddPair('cnpj', TJSONNull.Create)
    else
      Result.AddPair('cnpj', Qry.FieldByName('cnpj').AsString);

    Result.AddPair('descricao', Qry.FieldByName('descricao').AsString);
    Result.AddPair('email', Qry.FieldByName('email').AsString);
    Result.AddPair('telefone', Qry.FieldByName('telefone').AsString);

    if Qry.FieldByName('site').IsNull then
      Result.AddPair('site', TJSONNull.Create)
    else
      Result.AddPair('site', Qry.FieldByName('site').AsString);

    Tema := TJSONObject.Create;
    Tema.AddPair(
      'nome_exibicao',
      IfThen(
        Qry.FieldByName('nome_exibicao').AsString <> '',
        Qry.FieldByName('nome_exibicao').AsString,
        Qry.FieldByName('nome_fantasia').AsString
      )
    );
    Tema.AddPair('logo_url', Qry.FieldByName('logo_url').AsString);
    Tema.AddPair('favicon_url', Qry.FieldByName('favicon_url').AsString);
    Tema.AddPair('imagem_login_url', Qry.FieldByName('imagem_login_url').AsString);
    Tema.AddPair('banner_url', Qry.FieldByName('banner_url').AsString);
    Tema.AddPair('cor_primaria', Qry.FieldByName('cor_primaria').AsString);
    Tema.AddPair('cor_secundaria', Qry.FieldByName('cor_secundaria').AsString);
    Tema.AddPair('cor_destaque', Qry.FieldByName('cor_destaque').AsString);
    Tema.AddPair('cor_fundo', Qry.FieldByName('cor_fundo').AsString);
    Tema.AddPair('cor_texto', Qry.FieldByName('cor_texto').AsString);

    Result.AddPair('tema', Tema);
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConfiguracaoDAO.AtualizarDados(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoDadosInput
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE instituicao SET ' +
      '  nome_fantasia = :nome, ' +
      '  razao_social = :razao_social, ' +
      '  cnpj = NULLIF(:cnpj, ''''), ' +
      '  descricao = NULLIF(:descricao, ''''), ' +
      '  email = NULLIF(:email, ''''), ' +
      '  telefone = NULLIF(:telefone, ''''), ' +
      '  site = NULLIF(:site, '''') ' +
      'WHERE id = :id_instituicao';

    Qry.ParamByName('nome').AsString := ADados.Nome;
    Qry.ParamByName('razao_social').AsString := ADados.RazaoSocial;
    Qry.ParamByName('cnpj').AsString := ADados.Cnpj;
    Qry.ParamByName('descricao').AsString := ADados.Descricao;
    Qry.ParamByName('email').AsString := ADados.Email;
    Qry.ParamByName('telefone').AsString := ADados.Telefone;
    Qry.ParamByName('site').AsString := ADados.Site;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConfiguracaoDAO.ExisteCnpjOutraInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACnpj: string
): Boolean;
var
  Qry: TUniQuery;
begin
  if ACnpj = '' then
    Exit(False);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM instituicao ' +
      'WHERE cnpj = :cnpj ' +
      '  AND id <> :id_instituicao ' +
      'LIMIT 1';

    Qry.ParamByName('cnpj').AsString := ACnpj;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConfiguracaoDAO.GarantirConfiguracao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO instituicao_configuracao (' +
      '  id_instituicao, nome_exibicao' +
      ') ' +
      'SELECT i.id, i.nome_fantasia ' +
      'FROM instituicao i ' +
      'WHERE i.id = :id_instituicao ' +
      'ON DUPLICATE KEY UPDATE id_instituicao = VALUES(id_instituicao)';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConfiguracaoDAO.AtualizarMidia(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ATipo,
        AUrl: string
);
var
  Qry: TUniQuery;
begin
  GarantirConfiguracao(AConn, AIdInstituicao);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if SameText(ATipo, 'logo') then
      Qry.SQL.Text :=
        'UPDATE instituicao_configuracao ' +
        'SET logo_url = :url ' +
        'WHERE id_instituicao = :id_instituicao'
    else if SameText(ATipo, 'banner') then
      Qry.SQL.Text :=
        'UPDATE instituicao_configuracao ' +
        'SET banner_url = :url ' +
        'WHERE id_instituicao = :id_instituicao'
    else
      raise Exception.Create('Tipo de midia invalido.');

    Qry.ParamByName('url').AsString := AUrl;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConfiguracaoDAO.BuscarWhatsApp(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TInstituicaoWhatsAppConfig;
var
  Qry: TUniQuery;
begin
  Result := Default(TInstituicaoWhatsAppConfig);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ativo, url, ' +
      '       token_criptografado IS NOT NULL AS token_configurado, ' +
      '       token_hint ' +
      'FROM instituicao_whatsapp_configuracao ' +
      'WHERE id_instituicao = :id_instituicao';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Ativo := Qry.FieldByName('ativo').AsInteger = 1;
    Result.Url := Qry.FieldByName('url').AsString;
    Result.TokenConfigurado :=
      Qry.FieldByName('token_configurado').AsInteger = 1;

    if Result.TokenConfigurado then
      Result.TokenMascarado :=
        '********' + Qry.FieldByName('token_hint').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConfiguracaoDAO.TemTokenWhatsApp(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT token_criptografado IS NOT NULL AS tem_token ' +
      'FROM instituicao_whatsapp_configuracao ' +
      'WHERE id_instituicao = :id_instituicao';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;

    Result :=
      (not Qry.IsEmpty) and
      (Qry.FieldByName('tem_token').AsInteger = 1);
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConfiguracaoDAO.SalvarWhatsApp(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoWhatsAppInput;
  const ASecret: string
);
var
  Qry: TUniQuery;
  Hint: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if ADados.Token <> '' then
    begin
      if Length(ADados.Token) <= 4 then
        Hint := ADados.Token
      else
        Hint := Copy(
          ADados.Token,
          Length(ADados.Token) - 3,
          4
        );

      Qry.SQL.Text :=
        'INSERT INTO instituicao_whatsapp_configuracao (' +
        ' id_instituicao, ativo, url, token_criptografado, token_hint' +
        ') VALUES (' +
        ' :id_instituicao, :ativo, :url, AES_ENCRYPT(:token, :secret), :hint' +
        ') ' +
        'ON DUPLICATE KEY UPDATE ' +
        ' ativo = VALUES(ativo), ' +
        ' url = VALUES(url), ' +
        ' token_criptografado = VALUES(token_criptografado), ' +
        ' token_hint = VALUES(token_hint)';
    end
    else
    begin
      Qry.SQL.Text :=
        'INSERT INTO instituicao_whatsapp_configuracao (' +
        ' id_instituicao, ativo, url' +
        ') VALUES (' +
        ' :id_instituicao, :ativo, :url' +
        ') ' +
        'ON DUPLICATE KEY UPDATE ' +
        ' ativo = VALUES(ativo), ' +
        ' url = VALUES(url)';
    end;

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('ativo').AsInteger := Ord(ADados.Ativo);
    Qry.ParamByName('url').AsString := ADados.Url;

    if ADados.Token <> '' then
    begin
      Qry.ParamByName('token').AsString := ADados.Token;
      Qry.ParamByName('secret').AsString := ASecret;
      Qry.ParamByName('hint').AsString := Hint;
    end;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConfiguracaoDAO.ObterTokenWhatsApp(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ASecret: string
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT CAST(AES_DECRYPT(token_criptografado, :secret) AS CHAR(4096)) AS token ' +
      'FROM instituicao_whatsapp_configuracao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      '  AND token_criptografado IS NOT NULL';

    Qry.ParamByName('secret').AsString := ASecret;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('token').AsString;
  finally
    Qry.Free;
  end;
end;


end.
