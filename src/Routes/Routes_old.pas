unit Routes;

interface

type
  TRoutes = class
  public
    class procedure Registry;
  end;

implementation

uses
  //Adicionar rotas futuras
  Usuario.Controller,
  Database.Controller,
  Empresa.Controller,
  Auth.Controller,
  Categoria.Controller,
  Produto.Controller,
  ProdutoImagem.Controller,
  CatalogoConfig.Controller,
  CatalogoPublic.Controller,
  Pedido.Controller,
  RegistroEvento.Controller,
  NotificacaoFila.Controller,
  Dashboard.Controller,
  Upload.Controller,
  Ajuda.Controller,
  Plano.Controller,
  Unidade.Controller,
  Cliente.Controller,
  Marca.Controller,
  Assinatura.Controller,
  AssinaturaCobranca.Controller,
  Cupom.Controller;

class procedure TRoutes.Registry;
begin
  TUsuarioController.Registry;
  TDatabaseController.Registry;
  TEmpresaController.Registry;
  TAuthController.Registry;
  TCategoriaController.Registry;
  TProdutoController.Registry;
  TProdutoImagemController.Registry;
  TCatalogoConfigController.Registry;
  TCatalogoPublicController.Registry;
  TPedidoController.Registry;
  TRegistroEventoController.Registry;
  TNotificacaoFilaController.Registry;
  TDashboardController.Registry;
  TUploadController.Registry;
  TAjudaController.Registry;
  TPlanoController.Registry;
  TUnidadeController.Registry;
  TClienteController.Registry;
  TMarcaController.Registry;
  TAssinaturaController.Registry;
  TAssinaturaCobrancaController.Registry;
  TCupomController.Registry;
end;

end.
