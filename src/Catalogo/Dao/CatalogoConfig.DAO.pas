unit CatalogoConfig.DAO;

interface

uses
  Uni,
  CatalogoConfig.Model,
  System.JSON;

type
  TCatalogoConfigDAO = class

  private

  public
    class function ExisteSlug(const AConn: TUniConnection;const ASlug: string;const AIdEmpresaIgnorar: Int64 = 0): Boolean; static;
    class function BuscarPorEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TCatalogoConfigModel; static;
    class function BuscarPorSlug(const AConn: TUniConnection;const ASlug: string): TCatalogoConfigModel; static;
    class function Inserir(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel); static;
    class function BuscarPorConfigWhatsApp(const AConn: TUniConnection): TCatalogoConfigModel; static;
    class procedure AtualizarConexao(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel); static;
    class procedure ConexaoLimparToken(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel); static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const AConfig: TCatalogoConfigModel);
begin
  AConfig.IdConfig            := Qry.FieldByName('id_config').AsLargeInt;
  AConfig.Slug                := Qry.FieldByName('slug').AsString;
  AConfig.TituloCatalogo      := Qry.FieldByName('titulo_catalogo').AsString;
  AConfig.Descricao           := Qry.FieldByName('descricao').AsString;
  AConfig.CorPrimaria         := Qry.FieldByName('cor_primaria').AsString;
  AConfig.CorSecundaria       := Qry.FieldByName('cor_secundaria').AsString;
  AConfig.LogoUrl             := Qry.FieldByName('logo_url').AsString;
  AConfig.BannerUrl           := Qry.FieldByName('banner_url').AsString;
  AConfig.MostrarPreco        := Qry.FieldByName('mostrar_preco').AsString;
  AConfig.PermitirObservacao  := Qry.FieldByName('permitir_observacao').AsString;
  AConfig.PermitirRetirada    := Qry.FieldByName('permitir_retirada').AsString;
  AConfig.PermitirEntrega     := Qry.FieldByName('permitir_entrega').AsString;
  AConfig.ValorMinimoPedido   := Qry.FieldByName('valor_minimo_pedido').AsCurrency;
  AConfig.Ativo               := Qry.FieldByName('ativo').AsString;
  AConfig.url_whatsapp        := Qry.FieldByName('url_whatsapp').AsString;
  AConfig.instancia_whatsapp  := Qry.FieldByName('instancia_whatsapp').AsString;
  AConfig.token_whatsapp      := Qry.FieldByName('token_whatsapp').AsString;
  AConfig.apikey_whatsapp     := Qry.FieldByName('apikey_whatsapp').AsString;
  AConfig.facebook_url        := Qry.FieldByName('facebook_url').AsString;
  AConfig.instagram_url       := Qry.FieldByName('instagram_url').AsString;
  AConfig.tiktok_url          := Qry.FieldByName('tiktok_url').AsString;
  AConfig.youtube_url         := Qry.FieldByName('youtube_url').AsString;
  AConfig.imagens_destaque    := Qry.FieldByName('imagens_destaque').AsString;
  Aconfig.permitirficha       := Qry.FieldByName('permitir_ficha').AsString;
  Aconfig.Ecommerce           := Qry.FieldByName('Ecommerce').AsString;
  Aconfig.PagSeguro           := Qry.FieldByName('PagSeguro').AsString;
  Aconfig.PagSeguroToken      := Qry.FieldByName('PagSeguro_Token').AsString;
  Aconfig.PagSeguroAmbiente   := Qry.FieldByName('PagSeguro_Ambiente').AsString;
  Aconfig.CompraSemCadastro   := Qry.FieldByName('compra_sem_cadastro').AsString;
  Aconfig.ExigirClienteCadastrado   := Qry.FieldByName('exigir_cliente_cadastrado').AsString;
  Aconfig.PermitirConsignado  := Qry.FieldByName('permitir_consignado').AsString;
  Aconfig.links_sobrenos      := Qry.FieldByName('links_sobrenos').AsString;
  Aconfig.links_privacidade   := Qry.FieldByName('links_privacidade').AsString;
  Aconfig.links_termos        := Qry.FieldByName('links_termos').AsString;
  Aconfig.tipo_catalogo       := Qry.FieldByName('tipo_catalogo').AsString;

end;

procedure PreencherModelWhatsApp(const Qry: TUniQuery; const AConfig: TCatalogoConfigModel);
begin

  AConfig.IdConfig            := Qry.FieldByName('id_config').AsLargeInt;
  AConfig.url_whatsapp        := Qry.FieldByName('url_whatsapp').AsString;
  AConfig.instancia_whatsapp  := Qry.FieldByName('instancia_whatsapp').AsString;
  AConfig.token_whatsapp      := Qry.FieldByName('token_whatsapp').AsString;
  AConfig.apikey_whatsapp      := Qry.FieldByName('apikey_whatsapp').AsString;

end;

class function TCatalogoConfigDAO.ExisteSlug(const AConn: TUniConnection;const ASlug: string;const AIdEmpresaIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM catalogo_config ' +
      'WHERE LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) ';

    if AIdEmpresaIgnorar > 0 then
      Qry.SQL.Add('AND id_empresa <> :id_empresa');

    Qry.ParamByName('slug').AsString := Trim(ASlug);

    if AIdEmpresaIgnorar > 0 then
      Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TCatalogoConfigDAO.BuscarPorEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TCatalogoConfigModel;
var
  Qry, QryPlano: TUniQuery;
Const
  QryStr  = 'SELECT                   '+
            'c.id_config,             '+
            'c.slug,                  '+
            'c.titulo_catalogo,       '+
            'c.descricao,             '+
            'c.cor_primaria,          '+
            'c.cor_secundaria,        '+
            'c.logo_url,              '+
            'c.banner_url,            '+
            'c.mostrar_preco,         '+
            'c.permitir_observacao,   '+
            'c.permitir_retirada,     '+
            'c.permitir_entrega,      '+
            'c.valor_minimo_pedido,   '+
            'c.ativo,                 '+
            'c.url_whatsapp,          '+
            'c.instancia_whatsapp,    '+
            'c.token_whatsapp,        '+
            'c.apikey_whatsapp,       '+
            'c.facebook_url,          '+
            'c.instagram_url,         '+
            'c.tiktok_url,            '+
            'c.youtube_url,           '+
            'c.imagens_destaque,      '+
            'c.permitir_ficha,        '+
            'c.ecommerce,             '+
            'c.pagseguro,             '+
            'c.pagseguro_token,       '+
            'c.pagseguro_ambiente,    '+
            'c.compra_sem_cadastro,   '+
            'c.exigir_cliente_cadastrado, '+
            'c.permitir_consignado,   '+
            'c.links_sobrenos,        '+
            'c.links_privacidade,     '+
            'c.links_termos,          '+
            'c.tipo_catalogo          '+
            ' FROM catalogo_config c  '+
            ' where c.id_empresa = :id_empresa limit 1 '+
            '';
begin
  //dao para retorno para a page de configuracao
  Result := nil;

  Qry       := TUniQuery.Create(nil);
  QryPlano  := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := QryStr;

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    //Buscar Plano
    QryPlano.Connection := AConn;
    QryPlano.SQL.Text   := 'Select p.produto_qtde, p.permite_produto_ilimitado, p.permite_whatsapp, p.permite_email,'+
                           ' p.permite_pedido, p.permite_ecommerce, p.permite_pagseguro, '+
                           ' p.permite_pedido_ficha, p.permite_config_visual, p.permite_config_cupom from empresa e '+
                           ' inner join plano p '+
                           ' on e.id_plano = p.id_plano'+
                           ' where e.id_empresa= :id_empresa';

    QryPlano.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    QryPlano.Open;

    if QryPlano.IsEmpty then
      Exit(nil);

    Result      := TCatalogoConfigModel.Create;

    Result.produto_qtde              := QryPlano.FieldByName('produto_qtde').AsInteger;
    Result.permite_produto_ilimitado := QryPlano.FieldByName('permite_produto_ilimitado').AsString;
    Result.permite_whatsapp          := QryPlano.FieldByName('permite_whatsapp').AsString;
    Result.permite_email             := QryPlano.FieldByName('permite_email').AsString;
    Result.permite_pedido            := QryPlano.FieldByName('permite_pedido').AsString;
    Result.permite_ecommerce         := QryPlano.FieldByName('permite_ecommerce').AsString;
    Result.permite_pagseguro         := QryPlano.FieldByName('permite_pagseguro').AsString;
    Result.permite_pedido_ficha      := QryPlano.FieldByName('permite_pedido_ficha').AsString;
    Result.permite_config_visual     := QryPlano.FieldByName('permite_config_visual').AsString;
    Result.permite_config_cupom      := QryPlano.FieldByName('permite_config_cupom').AsString;

    PreencherModel(Qry, Result);

  finally
    Qry.Free;
    QryPlano.Free;
  end;
end;

//config whatsapp
class function TCatalogoConfigDAO.BuscarPorConfigWhatsApp(const AConn: TUniConnection): TCatalogoConfigModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select ' +
      ' id_config, url_whatsapp, instancia_whatsapp, token_whatsapp, apikey_whatsapp ' +
      ' from catalogo_config ' +
      ' where 1=1 ' +
      ' limit 1';

    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TCatalogoConfigModel.Create;
    PreencherModelWhatsApp(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class function TCatalogoConfigDAO.BuscarPorSlug(const AConn: TUniConnection;const ASlug: string): TCatalogoConfigModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_config, id_empresa, slug, titulo_catalogo, descricao, ' +
      ' cor_primaria, cor_secundaria, logo_url, banner_url, ' +
      ' mostrar_preco, permitir_observacao, permitir_retirada, permitir_entrega, ' +
      ' valor_minimo_pedido, ativo, data_criacao, data_alteracao, ' +
      ' facebook_url,     '+
      ' instagram_url,   '+
      ' tiktok_url,         '+
      ' youtube_url, imagens_destaque, permitir_ficha, ecommerce, pagseguro, '+
      ' pagseguro_token, pagseguro_ambiente, tipo_catalogo       '+
      ' from catalogo_config ' +
      ' where LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) ' +
      ' limit 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TCatalogoConfigModel.Create;
    PreencherModel(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class function TCatalogoConfigDAO.Inserir(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO catalogo_config (' +
      ' id_empresa, slug, titulo_catalogo, descricao, ' +
      ' cor_primaria, cor_secundaria, logo_url, banner_url, ' +
      ' mostrar_preco, permitir_observacao, permitir_retirada, permitir_entrega, ' +
      ' valor_minimo_pedido, ativo, permitir_ficha, ecommerce, pagseguro, pagseguro_token, pagseguro_ambiente, tipo_catalogo, id_segmento ' +
      ') VALUES (' +
      ' :id_empresa, :slug, :titulo_catalogo, :descricao, ' +
      ' :cor_primaria, :cor_secundaria, :logo_url, :banner_url, ' +
      ' :mostrar_preco, :permitir_observacao, :permitir_retirada, :permitir_entrega, ' +
      ' :valor_minimo_pedido, :ativo, :permitirficha, :ecommerce, :pagseguro, :pagsegurotoken, :pagseguroambiente, :tipo_catalogo, : id_segmento ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt        := AConfig.IdEmpresa;
    Qry.ParamByName('slug').AsString                := LowerCase(Trim(AConfig.Slug));
    Qry.ParamByName('titulo_catalogo').AsString     := Trim(AConfig.TituloCatalogo);
    Qry.ParamByName('descricao').AsString           := Trim(AConfig.Descricao);
    Qry.ParamByName('cor_primaria').AsString        := Trim(AConfig.CorPrimaria);
    Qry.ParamByName('cor_secundaria').AsString      := Trim(AConfig.CorSecundaria);
    Qry.ParamByName('logo_url').AsString            := Trim(AConfig.LogoUrl);
    Qry.ParamByName('banner_url').AsString          := Trim(AConfig.BannerUrl);
    Qry.ParamByName('mostrar_preco').AsString       := UpperCase(Trim(AConfig.MostrarPreco));
    Qry.ParamByName('permitir_observacao').AsString := UpperCase(Trim(AConfig.PermitirObservacao));
    Qry.ParamByName('permitir_retirada').AsString   := UpperCase(Trim(AConfig.PermitirRetirada));
    Qry.ParamByName('permitir_entrega').AsString    := UpperCase(Trim(AConfig.PermitirEntrega));
    Qry.ParamByName('valor_minimo_pedido').AsCurrency := AConfig.ValorMinimoPedido;
    Qry.ParamByName('ativo').AsString               := UpperCase(Trim(AConfig.Ativo));
    Qry.ParamByName('permitirficha').AsString       := UpperCase(Trim(AConfig.permitirficha));

    Qry.ParamByName('ecommerce').AsString           := UpperCase(Trim(AConfig.ecommerce));
    Qry.ParamByName('pagseguro').AsString           := UpperCase(Trim(AConfig.pagseguro));
    Qry.ParamByName('pagsegurotoken').AsString      := UpperCase(Trim(AConfig.pagsegurotoken));
    Qry.ParamByName('pagseguroambiente').AsString   := UpperCase(Trim(AConfig.pagseguroambiente));
    Qry.ParamByName('tipo_catalogo').AsString       := UpperCase(Aconfig.tipo_catalogo);
    Qry.ParamByName('id_segmento').AsLargeInt        := AConfig.idsegmento;
    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_config';
    Qry.Open;

    Result := Qry.FieldByName('id_config').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TCatalogoConfigDAO.Atualizar(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE catalogo_config SET ' +
      ' slug = :slug, ' +
      ' titulo_catalogo = :titulo_catalogo, ' +
      ' descricao = :descricao, ' +
      ' cor_primaria = :cor_primaria, ' +
      ' cor_secundaria = :cor_secundaria, ' +
      ' logo_url = :logo_url, ' +
      ' banner_url = :banner_url, ' +
      ' mostrar_preco = :mostrar_preco, ' +
      ' permitir_observacao = :permitir_observacao, ' +
      ' permitir_retirada = :permitir_retirada, ' +
      ' permitir_entrega = :permitir_entrega, ' +
      ' valor_minimo_pedido = :valor_minimo_pedido, ' +
      ' ativo = :ativo, ' +
      ' facebook_url = :facebook_url,     '+
      ' instagram_url = :instagram_url,   '+
      ' tiktok_url = :tiktok_url,         '+
      ' youtube_url = :youtube_url,       '+
      ' imagens_destaque= :imagens_destaque, '+
      ' data_alteracao = NOW(), ' +
      ' permitir_ficha = :permitirficha, '+
      ' ecommerce = :ecommerce, '+
      ' pagseguro = :pagseguro, '+
      ' pagseguro_token = :pagsegurotoken, '+
      ' pagseguro_ambiente = :pagseguroambiente,'+
      ' tipo_catalogo = :tipo_catalogo,  '+
      ' links_sobrenos = :links_sobrenos,        '+
      ' links_privacidade = :links_privacidade,     '+
      ' links_termos = :links_termos,          '+
      ' url_whatsapp = :url_whatsapp,          '+
      ' instancia_whatsapp = :instancia_whatsapp,    '+
      ' token_whatsapp = :token_whatsapp,        '+
      ' apikey_whatsapp = :apikey_whatsapp       '+

      ' WHERE id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AConfig.IdEmpresa;
    Qry.ParamByName('slug').AsString := LowerCase(Trim(AConfig.Slug));
    Qry.ParamByName('titulo_catalogo').AsString := Trim(AConfig.TituloCatalogo);
    Qry.ParamByName('descricao').AsString := Trim(AConfig.Descricao);
    Qry.ParamByName('cor_primaria').AsString := Trim(AConfig.CorPrimaria);
    Qry.ParamByName('cor_secundaria').AsString := Trim(AConfig.CorSecundaria);
    Qry.ParamByName('logo_url').AsString := Trim(AConfig.LogoUrl);
    Qry.ParamByName('banner_url').AsString := Trim(AConfig.BannerUrl);
    Qry.ParamByName('mostrar_preco').AsString := UpperCase(Trim(AConfig.MostrarPreco));
    Qry.ParamByName('permitir_observacao').AsString := UpperCase(Trim(AConfig.PermitirObservacao));
    Qry.ParamByName('permitir_retirada').AsString := UpperCase(Trim(AConfig.PermitirRetirada));
    Qry.ParamByName('permitir_entrega').AsString := UpperCase(Trim(AConfig.PermitirEntrega));
    Qry.ParamByName('valor_minimo_pedido').AsCurrency := AConfig.ValorMinimoPedido;
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AConfig.Ativo));

    Qry.ParamByName('facebook_url').AsString := Trim(AConfig.facebook_url);
    Qry.ParamByName('instagram_url').AsString := Trim(AConfig.instagram_url);
    Qry.ParamByName('tiktok_url').AsString := Trim(AConfig.tiktok_url);
    Qry.ParamByName('youtube_url').AsString := Trim(AConfig.youtube_url);
    Qry.ParamByName('imagens_destaque').AsString := Trim(AConfig.imagens_destaque);
    Qry.ParamByName('permitirficha').AsString := UpperCase(Trim(AConfig.permitirficha));

    Qry.ParamByName('ecommerce').AsString         := Trim(AConfig.ecommerce);
    Qry.ParamByName('pagseguro').AsString         := Trim(AConfig.pagseguro);
    Qry.ParamByName('pagsegurotoken').AsString    := Trim(AConfig.pagsegurotoken);
    Qry.ParamByName('pagseguroambiente').AsString := Trim(AConfig.pagseguroambiente);
    qry.ParamByName('tipo_catalogo').AsString     := Trim(Aconfig.tipo_catalogo);

    qry.ParamByName('links_sobrenos').AsString      := Trim(Aconfig.links_sobrenos);
    qry.ParamByName('links_privacidade').AsString   := Trim(Aconfig.links_privacidade);
    qry.ParamByName('links_termos').AsString        := Trim(Aconfig.links_termos);

    qry.ParamByName('url_whatsapp').AsString        := Trim(Aconfig.url_whatsapp);
    qry.ParamByName('instancia_whatsapp').AsString  := Trim(Aconfig.instancia_whatsapp);
    qry.ParamByName('token_whatsapp').AsString      := Trim(Aconfig.token_whatsapp);
    qry.ParamByName('apikey_whatsapp').AsString     := Trim(Aconfig.apikey_whatsapp);

    Qry.Execute;

  finally
    Qry.Free;
  end;
end;

class procedure TCatalogoConfigDAO.AtualizarConexao(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE catalogo_config SET ' +
      ' url_whatsapp = :url_whatsapp, ' +
      ' instancia_whatsapp = :instancia_whatsapp, '+
      ' token_whatsapp = :token_whatsapp, '+
      ' apikey_whatsapp= :apikey_whatsapp, '+
      ' data_alteracao = NOW() ' +
      ' where id_empresa = :id_empresa and id_config = :id';

    Qry.ParamByName('id_empresa').AsLargeInt      := AConfig.IdEmpresa;
    Qry.ParamByName('id').AsLargeInt              := AConfig.IdConfig;
    Qry.ParamByName('url_whatsapp').AsString      := Trim(AConfig.url_whatsapp);
    Qry.ParamByName('instancia_whatsapp').AsString:= Trim(AConfig.instancia_whatsapp);
    Qry.ParamByName('token_whatsapp').AsString    := Trim(AConfig.token_whatsapp);
    Qry.ParamByName('apikey_whatsapp').AsString   := Trim(AConfig.apikey_whatsapp);


    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TCatalogoConfigDAO.ConexaoLimparToken(const AConn: TUniConnection;const AConfig: TCatalogoConfigModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE catalogo_config SET ' +
      ' token_whatsapp = :token_whatsapp, '+
      ' data_alteracao = NOW() ' +
      ' WHERE id_empresa = :id_empresa and id_config = :id';

    Qry.ParamByName('id_empresa').AsLargeInt      := AConfig.IdEmpresa;
    Qry.ParamByName('id').AsLargeInt              := AConfig.IdConfig;
    Qry.ParamByName('token_whatsapp').AsString    := Trim(AConfig.token_whatsapp);

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;


end.
