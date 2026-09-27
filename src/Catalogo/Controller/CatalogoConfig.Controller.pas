unit CatalogoConfig.Controller;

interface

type
  TCatalogoConfigController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  App.Classes,
  App.Token,
  CatalogoConfig.Model,
  CatalogoConfig.Service,
  Assinatura.Service;

function CatalogoConfigToJson(const AConfig: TCatalogoConfigModel): TJSONObject;
var
 Plano, Visual, Integracao, config  : TJsonObject;
begin
  Result      := TJSONObject.Create;
  Plano       := TJSONObject.Create;
  Visual      := TJSONObject.Create;
  integracao  := TJSONObject.Create;
  config      := TJSONObject.Create;


  Result.AddPair('id_config',             TJSONNumber.Create(AConfig.IdConfig));
  Result.AddPair('slug',                  AConfig.Slug);
  Result.AddPair('titulo_catalogo',       AConfig.TituloCatalogo);
  Result.AddPair('descricao',             AConfig.Descricao);
  Result.AddPair('ativo',                 AConfig.Ativo);
  Result.AddPair('tipo_catalogo',         Aconfig.tipo_catalogo);


  //Visual
  Visual.AddPair('cor_primaria',          AConfig.CorPrimaria);
  Visual.AddPair('cor_secundaria',        AConfig.CorSecundaria);
  Visual.AddPair('logo_url',              AConfig.LogoUrl);
  Visual.AddPair('banner_url',            AConfig.BannerUrl);
  Visual.AddPair('facebook_url',          AConfig.facebook_url);
  Visual.AddPair('instagram_url',         AConfig.instagram_url);
  Visual.AddPair('tiktok_url',            AConfig.tiktok_url);
  Visual.AddPair('youtube_url',           AConfig.youtube_url);
  Visual.AddPair('imagens_destaque',      AConfig.imagens_destaque);
  Visual.AddPair('links_sobrenos',        Aconfig.links_sobrenos);
  Visual.AddPair('links_privacidade',     Aconfig.links_privacidade);
  Visual.AddPair('links_termos',          Aconfig.links_termos);

  Result.AddPair('visual',Visual);

  //Integracao
  integracao.AddPair('url_whatsapp',      AConfig.url_whatsapp);
  integracao.AddPair('instancia_whatsapp',AConfig.instancia_whatsapp);
  integracao.AddPair('token_whatsapp',    AConfig.token_whatsapp);
  integracao.AddPair('apikey_whatsapp',   AConfig.apikey_whatsapp);

  Result.AddPair('integracao',integracao);

  //Configuracao catalogo

  config.AddPair('mostrar_preco',         AConfig.MostrarPreco);
  config.AddPair('permitir_observacao',   AConfig.PermitirObservacao);
  config.AddPair('permitir_retirada',     AConfig.PermitirRetirada);
  config.AddPair('permitir_entrega',      AConfig.PermitirEntrega);
  config.AddPair('valor_minimo_pedido',   TJSONNumber.Create(AConfig.ValorMinimoPedido));
  config.AddPair('permitirficha',         Aconfig.permitirficha);
  config.AddPair('ecommerce',             Aconfig.Ecommerce);
  config.AddPair('pagseguro',             Aconfig.PagSeguro);
  config.AddPair('pagsegurotoken',        Aconfig.PagSeguroToken);
  config.AddPair('pagseguroambiente',     Aconfig.PagSeguroAmbiente);
  config.AddPair('comprasemcadastro',     Aconfig.CompraSemCadastro);
  config.AddPair('exigirclientecadastrado',Aconfig.ExigirClienteCadastrado);
  config.AddPair('permitirconsignado',    Aconfig.PermitirConsignado);


  Result.AddPair('config',config);

  Plano.AddPair('produto_qtde', Aconfig.produto_qtde);
  Plano.AddPair('permite_produto_ilimitado', Aconfig.permite_produto_ilimitado);
  Plano.AddPair('permite_whatsapp', Aconfig.permite_whatsapp);
  Plano.AddPair('permite_email', Aconfig.permite_email);
  Plano.AddPair('permite_pedido', Aconfig.permite_pedido);
  Plano.AddPair('permite_ecommerce', Aconfig.permite_ecommerce);
  Plano.AddPair('permite_pagseguro', Aconfig.permite_pagseguro);
  Plano.AddPair('permite_pedido_ficha', Aconfig.permite_pedido_ficha);
  Plano.AddPair('permite_config_visual', Aconfig.permite_config_visual);
  Plano.AddPair('permite_config_cupom', Aconfig.permite_config_cupom);

  Result.AddPair('plano',plano);

end;

class procedure TCatalogoConfigController.Registry;
begin
  //Rota para buscar as configuração por empresa conectada
  THorse.Get('/v1/catalogo/config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      ConfigCatalogo: TCatalogoConfigModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        //validar acesso
        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        ConfigCatalogo := TCatalogoConfigService.BuscarPorEmpresa(Claims.IdEmpresa);
        try
          Json := CatalogoConfigToJson(ConfigCatalogo);
          TAppResponse.Ok(Res, Json);
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  //rota publica n8n
  THorse.Get('/v1/catalogo/n8n/config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      ConfigCatalogo: TCatalogoConfigModel;
      Json: TJSONObject;
    begin
      try
        //if not ValidarToken(Req, Res, Claims) then
        //  Exit;

        ConfigCatalogo := TCatalogoConfigService.BuscarPorConfigWhatsApp();
        try
          Json := CatalogoConfigToJson(ConfigCatalogo);
          TAppResponse.Ok(Res, Json);
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/catalogo/config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      ConfigCatalogo: TCatalogoConfigModel;
      IdConfig: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ConfigCatalogo := TCatalogoConfigModel.Create;
        try
          ConfigCatalogo.Slug               := TAppClasses.GetJsonString(Body, 'slug');
          ConfigCatalogo.TituloCatalogo     := TAppClasses.GetJsonString(Body, 'titulo_catalogo');
          ConfigCatalogo.Descricao          := TAppClasses.GetJsonString(Body, 'descricao');
          ConfigCatalogo.CorPrimaria        := TAppClasses.GetJsonString(Body, 'cor_primaria');
          ConfigCatalogo.CorSecundaria      := TAppClasses.GetJsonString(Body, 'cor_secundaria');
          ConfigCatalogo.LogoUrl            := TAppClasses.GetJsonString(Body, 'logo_url');
          ConfigCatalogo.BannerUrl          := TAppClasses.GetJsonString(Body, 'banner_url');

          ConfigCatalogo.MostrarPreco       := TAppClasses.GetJsonString(Body, 'mostrar_preco', 'S');
          ConfigCatalogo.PermitirObservacao := TAppClasses.GetJsonString(Body, 'permitir_observacao', 'S');
          ConfigCatalogo.PermitirRetirada   := TAppClasses.GetJsonString(Body, 'permitir_retirada', 'S');
          ConfigCatalogo.PermitirEntrega    := TAppClasses.GetJsonString(Body, 'permitir_entrega', 'N');

          ConfigCatalogo.ValorMinimoPedido  := TAppClasses.GetJsonCurrency(Body, 'valor_minimo_pedido', 0);
          ConfigCatalogo.Ativo              := TAppClasses.GetJsonString(Body, 'ativo', 'S');

          ConfigCatalogo.facebook_url       := TAppClasses.GetJsonString(Body, 'facebook_url');
          ConfigCatalogo.instagram_url      := TAppClasses.GetJsonString(Body, 'instagram_url');
          ConfigCatalogo.tiktok_url         := TAppClasses.GetJsonString(Body, 'tiktok_url');
          ConfigCatalogo.youtube_url        := TAppClasses.GetJsonString(Body, 'youtube_url');
          ConfigCatalogo.imagens_destaque   := TAppClasses.GetJsonString(Body, 'imagens_destaque');

          ConfigCatalogo.permitirficha      := TAppClasses.GetJsonString(Body, 'permitirficha', 'N');

          ConfigCatalogo.Ecommerce          := TAppClasses.GetJsonString(Body, 'Ecommerce', 'N');
          ConfigCatalogo.PagSeguro          := TAppClasses.GetJsonString(Body, 'PagSeguro', 'N');
          ConfigCatalogo.PagSeguroToken     := TAppClasses.GetJsonString(Body, 'PagSeguroToken');
          ConfigCatalogo.PagSeguroAmbiente  := TAppClasses.GetJsonString(Body, 'PagSeguroAmbiente');
          configCatalogo.tipo_catalogo      := TAppClasses.GetJsonString(Body, 'tipo_catalogo');

          configCatalogo.links_sobrenos     := TAppClasses.GetJsonString(Body, 'links_sobrenos');
          configCatalogo.links_privacidade  := TAppClasses.GetJsonString(Body, 'links_privacidade');
          configCatalogo.links_termos       := TAppClasses.GetJsonString(Body, 'links_termos');

          configCatalogo.url_whatsapp       := TAppClasses.GetJsonString(Body, 'url_whatsapp');
          configCatalogo.instancia_whatsapp := TAppClasses.GetJsonString(Body, 'instancia_whatsapp');
          configCatalogo.token_whatsapp     := TAppClasses.GetJsonString(Body, 'token_whatsapp');
          configCatalogo.apikey_whatsapp    := TAppClasses.GetJsonString(Body, 'apikey_whatsapp');


          IdConfig := TCatalogoConfigService.SalvarConfig(Claims.IdEmpresa, ConfigCatalogo);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_config', TJSONNumber.Create(IdConfig));

          TAppResponse.Ok(Res, Retorno, 'Configuração do catálogo salva com sucesso.');
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$REGION 'Whatsapp'}

  THorse.Get('/v1/catalogo/config/whatsapp',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      ConfigCatalogo: TCatalogoConfigModel;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        ConfigCatalogo := TCatalogoConfigService.BuscarPorEmpresa(Claims.IdEmpresa);
        try
          Json := CatalogoConfigToJson(ConfigCatalogo);
          TAppResponse.Ok(Res, Json);
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Put('/v1/catalogo/config/whatsapp',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      ConfigCatalogo: TCatalogoConfigModel;
      IdConfig: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ConfigCatalogo              := TCatalogoConfigModel.Create;
        try
          ConfigCatalogo.url_whatsapp       :=  TAppClasses.GetJsonString(Body,'url_whatsapp');
          ConfigCatalogo.instancia_whatsapp :=  TAppClasses.GetJsonString(Body,'instancia_whatsapp');
          ConfigCatalogo.token_whatsapp     :=  TAppClasses.GetJsonString(Body,'token_whatsapp');
          ConfigCatalogo.apikey_whatsapp     := TAppClasses.GetJsonString(Body,'apikey_whatsapp');

          IdConfig := TCatalogoConfigService.SalvarConfigWhatsapp(Claims.IdEmpresa, ConfigCatalogo);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_config', TJSONNumber.Create(IdConfig));

          TAppResponse.Ok(Res, Retorno, 'Configuração do catálogo salva com sucesso.');
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

   THorse.Put('/v1/catalogo/config/whatsapptoken',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      ConfigCatalogo: TCatalogoConfigModel;
      IdConfig: Int64;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        ConfigCatalogo              := TCatalogoConfigModel.Create;
        try

          ConfigCatalogo.token_whatsapp     :=  TAppClasses.GetJsonString(Body,'token_whatsapp');

          IdConfig := TCatalogoConfigService.ConexaoLimparToken(Claims.IdEmpresa, ConfigCatalogo);

          Retorno := TJSONObject.Create;
          Retorno.AddPair('id_config', TJSONNumber.Create(IdConfig));

          TAppResponse.Ok(Res, Retorno, 'Configuração do catálogo salva com sucesso.');
        finally
          ConfigCatalogo.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  


end;

end.
