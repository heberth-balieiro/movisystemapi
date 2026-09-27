unit CatalogoConfig.Model;

interface

uses
  System.SysUtils;

type
  TCatalogoConfigModel = class
  private
    FIdConfig: Int64;
    FIdEmpresa: Int64;
    FSlug: string;
    FTituloCatalogo: string;
    FDescricao: string;
    FCorPrimaria: string;
    FCorSecundaria: string;
    FLogoUrl: string;
    FBannerUrl: string;
    FMostrarPreco: string;
    FPermitirObservacao: string;
    FPermitirRetirada: string;
    FPermitirEntrega: string;
    FValorMinimoPedido: Currency;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    Furl_whatsapp: string;
    Finstancia_whatsapp: string;
    Ftoken_whatsapp: string;
    Fapikey_whatsapp: String;
    Finstagram_url: string;
    Ffacebook_url: string;
    Ftiktok_url: string;
    Fyoutube_url: string;
    Fimagens_destaque: string;
    Fpermitirficha: string;
    FEcommerce: string;
    FPagSeguroToken: string;
    FPagSeguroAmbiente: string;
    FPagSeguro: string;
    FExigirClienteCadastrado: string;
    FPermitirConsignado: string;
    FCompraSemCadastro: string;
    Fpermite_pedido_ficha: string;
    Fpermite_produto_ilimitado: string;
    Fpermite_config_visual: string;
    Fpermite_ecommerce: string;
    Fpermite_email: string;
    Fpermite_pedido: string;
    Fpermite_whatsapp: string;
    Fpermite_pagseguro: string;
    Fproduto_qtde: integer;
    Flinks_privacidade: string;
    Flinks_termos: string;
    Flinks_sobrenos: string;
    Ftipo_catalogo: String;
    Fpermite_config_cupom: string;
    Fidsegmento: Int64;
  public
    property IdConfig: Int64 read FIdConfig write FIdConfig;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Slug: string read FSlug write FSlug;
    property TituloCatalogo: string read FTituloCatalogo write FTituloCatalogo;
    property Descricao: string read FDescricao write FDescricao;
    property CorPrimaria: string read FCorPrimaria write FCorPrimaria;
    property CorSecundaria: string read FCorSecundaria write FCorSecundaria;
    property LogoUrl: string read FLogoUrl write FLogoUrl;
    property BannerUrl: string read FBannerUrl write FBannerUrl;
    property MostrarPreco: string read FMostrarPreco write FMostrarPreco;
    property PermitirObservacao: string read FPermitirObservacao write FPermitirObservacao;
    property PermitirRetirada: string read FPermitirRetirada write FPermitirRetirada;
    property PermitirEntrega: string read FPermitirEntrega write FPermitirEntrega;
    property ValorMinimoPedido: Currency read FValorMinimoPedido write FValorMinimoPedido;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property url_whatsapp       : string read Furl_whatsapp write  Furl_whatsapp;
    property instancia_whatsapp : string read Finstancia_whatsapp write Finstancia_whatsapp;
    property token_whatsapp     : string read Ftoken_whatsapp write Ftoken_whatsapp;
    property apikey_whatsapp    : String read Fapikey_whatsapp write Fapikey_whatsapp;
    property facebook_url       : string read Ffacebook_url   write Ffacebook_url;
    property instagram_url      : string read Finstagram_url  write Finstagram_url;
    property tiktok_url         : string read Ftiktok_url     write Ftiktok_url;
    property youtube_url        : string read Fyoutube_url    write Fyoutube_url;
    property imagens_destaque   : string read Fimagens_destaque write Fimagens_destaque;
    property permitirficha      : string read Fpermitirficha  write Fpermitirficha;

    property Ecommerce: string read FEcommerce write FEcommerce;
    property PagSeguro: string read FPagSeguro write FPagSeguro;
    property PagSeguroToken: string read FPagSeguroToken write FPagSeguroToken;
    property PagSeguroAmbiente: string read FPagSeguroAmbiente write FPagSeguroAmbiente;

    property CompraSemCadastro: string read FCompraSemCadastro write FCompraSemCadastro;
    property ExigirClienteCadastrado: string read FExigirClienteCadastrado write FExigirClienteCadastrado;
    property PermitirConsignado: string read FPermitirConsignado write FPermitirConsignado;

    property links_sobrenos     :string read  Flinks_sobrenos write Flinks_sobrenos;
    property links_privacidade  :string read  Flinks_privacidade write Flinks_privacidade;
    property links_termos       :string read  Flinks_termos   write Flinks_termos;
    property tipo_catalogo      :String read  Ftipo_catalogo  write Ftipo_catalogo;


    //campo de plano
    property produto_qtde               : integer read Fproduto_qtde              write Fproduto_qtde;
    property permite_produto_ilimitado  : string read Fpermite_produto_ilimitado  write Fpermite_produto_ilimitado;
    property permite_whatsapp           : string read Fpermite_whatsapp           write Fpermite_whatsapp;
    property permite_email              : string read Fpermite_email              write Fpermite_email;
    property permite_pedido             : string read Fpermite_pedido             write Fpermite_pedido;
    property permite_ecommerce          : string read Fpermite_ecommerce          write Fpermite_ecommerce;
    property permite_pagseguro          : string read Fpermite_pagseguro          write Fpermite_pagseguro;
    property permite_pedido_ficha       : string read Fpermite_pedido_ficha       write Fpermite_pedido_ficha;
    property permite_config_visual      : string read Fpermite_config_visual      write Fpermite_config_visual;
    property permite_config_cupom       : string read Fpermite_config_cupom       write Fpermite_config_cupom;

    property idsegmento:Int64 read Fidsegmento  write Fidsegmento;
  end;

implementation

end.
