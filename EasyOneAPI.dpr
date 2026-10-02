program EasyOneAPI;

{API nova para windows e linux}


{$APPTYPE CONSOLE}

{$R *.res}

uses
  EncontroCheckin.Controller in 'src\Cursos\Controller\EncontroCheckin.Controller.pas',
  EncontroCheckin.DAO in 'src\Cursos\Dao\EncontroCheckin.DAO.pas',
  EncontroCheckin.Model in 'src\Cursos\Model\EncontroCheckin.Model.pas',
  EncontroCheckin.Service in 'src\Cursos\Services\EncontroCheckin.Service.pas',
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Horse.CORS,
  Horse.Upload,
  Uni,
  Middleware.JWT in 'src\Middlewares\Middleware.JWT.pas',
  Middleware.Roles in 'src\Middlewares\Middleware.Roles.pas',
  Middleware.SecurityHeaders in 'src\Middlewares\Middleware.SecurityHeaders.pas',
  Middleware.Auditoria in 'src\Middlewares\Middleware.Auditoria.pas',
  App.Config in 'src\Core\App.Config.pas',
  APP.Errors in 'src\Core\APP.Errors.pas',
  App.JWT in 'src\Core\App.JWT.pas',
  App.Response in 'src\Core\App.Response.pas',
  App.RateLimit in 'src\Core\App.RateLimit.pas',
  Auditoria.DAO in 'src\Cursos\Dao\Auditoria.DAO.pas',
  Auditoria.Service in 'src\Cursos\Services\Auditoria.Service.pas',
  InstituicaoAuditoria.Model in 'src\Cursos\Model\InstituicaoAuditoria.Model.pas',
  InstituicaoAuditoria.DAO in 'src\Cursos\Dao\InstituicaoAuditoria.DAO.pas',
  InstituicaoAuditoria.Service in 'src\Cursos\Services\InstituicaoAuditoria.Service.pas',
  InstituicaoAuditoria.Controller in 'src\Cursos\Controller\InstituicaoAuditoria.Controller.pas',
  PlataformaCampanha.DAO in 'src\Cursos\Dao\PlataformaCampanha.DAO.pas',
  PlataformaCampanha.Service in 'src\Cursos\Services\PlataformaCampanha.Service.pas',
  PlataformaCampanha.Worker in 'src\Cursos\Services\PlataformaCampanha.Worker.pas',
  PlataformaCampanha.Controller in 'src\Cursos\Controller\PlataformaCampanha.Controller.pas',
  PlataformaModulo.Model in 'src\Cursos\Model\PlataformaModulo.Model.pas',
  PlataformaModulo.DAO in 'src\Cursos\Dao\PlataformaModulo.DAO.pas',
  PlataformaModulo.Service in 'src\Cursos\Services\PlataformaModulo.Service.pas',
  PlataformaModulo.Controller in 'src\Cursos\Controller\PlataformaModulo.Controller.pas',
  PlataformaUsuarioWhatsApp.DAO in 'src\Cursos\Dao\PlataformaUsuarioWhatsApp.DAO.pas',
  PlataformaUsuarioWhatsApp.Service in 'src\Cursos\Services\PlataformaUsuarioWhatsApp.Service.pas',
  PlataformaUsuarioWhatsApp.Controller in 'src\Cursos\Controller\PlataformaUsuarioWhatsApp.Controller.pas',
  LgpdSolicitacao.Model in 'src\Cursos\Model\LgpdSolicitacao.Model.pas',
  LgpdSolicitacao.DAO in 'src\Cursos\Dao\LgpdSolicitacao.DAO.pas',
  LgpdSolicitacao.Service in 'src\Cursos\Services\LgpdSolicitacao.Service.pas',
  LgpdSolicitacao.Controller in 'src\Cursos\Controller\LgpdSolicitacao.Controller.pas',
  Auth.Passwords in 'src\Core\Auth.Passwords.pas',
  Database.Connection in 'src\Core\Database.Connection.pas',
  Ajuda.Controller in 'src\Catalogo\Controller\Ajuda.Controller.pas',
  Auth.Controller in 'src\Catalogo\Controller\Auth.Controller.pas',
  CatalogoConfig.Controller in 'src\Catalogo\Controller\CatalogoConfig.Controller.pas',
  CatalogoPublic.Controller in 'src\Catalogo\Controller\CatalogoPublic.Controller.pas',
  Cliente.Controller in 'src\Catalogo\Controller\Cliente.Controller.pas',
  Dashboard.Controller in 'src\Catalogo\Controller\Dashboard.Controller.pas',
  Database.Controller in 'src\Catalogo\Controller\Database.Controller.pas',
  Empresa.Controller in 'src\Catalogo\Controller\Empresa.Controller.pas',
  Marca.Controller in 'src\Catalogo\Controller\Marca.Controller.pas',
  NotificacaoFila.Controller in 'src\Catalogo\Controller\NotificacaoFila.Controller.pas',
  Pedido.Controller in 'src\Catalogo\Controller\Pedido.Controller.pas',
  Plano.Controller in 'src\Catalogo\Controller\Plano.Controller.pas',
  Produto.Controller in 'src\Catalogo\Controller\Produto.Controller.pas',
  ProdutoImagem.Controller in 'src\Catalogo\Controller\ProdutoImagem.Controller.pas',
  RegistroEvento.Controller in 'src\Catalogo\Controller\RegistroEvento.Controller.pas',
  Unidade.Controller in 'src\Catalogo\Controller\Unidade.Controller.pas',
  Upload.Controller in 'src\Catalogo\Controller\Upload.Controller.pas',
  Usuario.Controller in 'src\Catalogo\Controller\Usuario.Controller.pas',
  Ajuda.DAO in 'src\Catalogo\Dao\Ajuda.DAO.pas',
  CatalogoConfig.DAO in 'src\Catalogo\Dao\CatalogoConfig.DAO.pas',
  CatalogoPublic.DAO in 'src\Catalogo\Dao\CatalogoPublic.DAO.pas',
  Categoria.DAO in 'src\Catalogo\Dao\Categoria.DAO.pas',
  Cliente.Dao in 'src\Catalogo\Dao\Cliente.Dao.pas',
  Dashboard.DAO in 'src\Catalogo\Dao\Dashboard.DAO.pas',
  Empresa.DAO in 'src\Catalogo\Dao\Empresa.DAO.pas',
  Marca.Dao in 'src\Catalogo\Dao\Marca.Dao.pas',
  NotificacaoFila.DAO in 'src\Catalogo\Dao\NotificacaoFila.DAO.pas',
  Pedido.DAO in 'src\Catalogo\Dao\Pedido.DAO.pas',
  Plano.DAO in 'src\Catalogo\Dao\Plano.DAO.pas',
  Produto.DAO in 'src\Catalogo\Dao\Produto.DAO.pas',
  ProdutoImagem.DAO in 'src\Catalogo\Dao\ProdutoImagem.DAO.pas',
  RegistroEvento.DAO in 'src\Catalogo\Dao\RegistroEvento.DAO.pas',
  Unidade.DAO in 'src\Catalogo\Dao\Unidade.DAO.pas',
  Usuario.DAO in 'src\Catalogo\Dao\Usuario.DAO.pas',
  Ajuda.Model in 'src\Catalogo\Model\Ajuda.Model.pas',
  CatalogoConfig.Model in 'src\Catalogo\Model\CatalogoConfig.Model.pas',
  Categoria.Model in 'src\Catalogo\Model\Categoria.Model.pas',
  Cliente.Model in 'src\Catalogo\Model\Cliente.Model.pas',
  Empresa.Model in 'src\Catalogo\Model\Empresa.Model.pas',
  Marca.Model in 'src\Catalogo\Model\Marca.Model.pas',
  NotificacaoFila.Model in 'src\Catalogo\Model\NotificacaoFila.Model.pas',
  Pedido.Model in 'src\Catalogo\Model\Pedido.Model.pas',
  PedidoItem.Model in 'src\Catalogo\Model\PedidoItem.Model.pas',
  Plano.Model in 'src\Catalogo\Model\Plano.Model.pas',
  Produto.Model in 'src\Catalogo\Model\Produto.Model.pas',
  ProdutoImagem.Model in 'src\Catalogo\Model\ProdutoImagem.Model.pas',
  RegistroEvento.Model in 'src\Catalogo\Model\RegistroEvento.Model.pas',
  Unidade.Model in 'src\Catalogo\Model\Unidade.Model.pas',
  Usuario.Model in 'src\Catalogo\Model\Usuario.Model.pas',
  Ajuda.Service in 'src\Catalogo\Services\Ajuda.Service.pas',
  CatalogoConfig.Service in 'src\Catalogo\Services\CatalogoConfig.Service.pas',
  CatalogoPublic.Service in 'src\Catalogo\Services\CatalogoPublic.Service.pas',
  Categoria.Service in 'src\Catalogo\Services\Categoria.Service.pas',
  Cliente.Service in 'src\Catalogo\Services\Cliente.Service.pas',
  Dashboard.Service in 'src\Catalogo\Services\Dashboard.Service.pas',
  Empresa.Service in 'src\Catalogo\Services\Empresa.Service.pas',
  Marca.Service in 'src\Catalogo\Services\Marca.Service.pas',
  NotificacaoFila.Service in 'src\Catalogo\Services\NotificacaoFila.Service.pas',
  Pedido.Service in 'src\Catalogo\Services\Pedido.Service.pas',
  Plano.Service in 'src\Catalogo\Services\Plano.Service.pas',
  Produto.Service in 'src\Catalogo\Services\Produto.Service.pas',
  ProdutoImagem.Service in 'src\Catalogo\Services\ProdutoImagem.Service.pas',
  RegistroEvento.Service in 'src\Catalogo\Services\RegistroEvento.Service.pas',
  Unidade.Service in 'src\Catalogo\Services\Unidade.Service.pas',
  Usuario.Service in 'src\Catalogo\Services\Usuario.Service.pas',
  Assinatura.Model in 'src\Catalogo\Model\Assinatura.Model.pas',
  Assinatura.DAO in 'src\Catalogo\Dao\Assinatura.DAO.pas',
  Assinatura.Service in 'src\Catalogo\Services\Assinatura.Service.pas',
  Assinatura.Controller in 'src\Catalogo\Controller\Assinatura.Controller.pas',
  AssinaturaCobranca.Model in 'src\Catalogo\Model\AssinaturaCobranca.Model.pas',
  AssinaturaCobranca.DAO in 'src\Catalogo\Dao\AssinaturaCobranca.DAO.pas',
  AssinaturaCobranca.Service in 'src\Catalogo\Services\AssinaturaCobranca.Service.pas',
  AssinaturaCobranca.Controller in 'src\Catalogo\Controller\AssinaturaCobranca.Controller.pas',
  Categoria.Controller in 'src\Catalogo\Controller\Categoria.Controller.pas',
  Cupom.Model in 'src\Catalogo\Model\Cupom.Model.pas',
  Cupom.Dao in 'src\Catalogo\Dao\Cupom.Dao.pas',
  Cupom.Service in 'src\Catalogo\Services\Cupom.Service.pas',
  Cupom.Controller in 'src\Catalogo\Controller\Cupom.Controller.pas',
  App.Classes in 'src\Core\App.Classes.pas',
  App.Token in 'src\Core\App.Token.pas',
  App.ModuloAccess in 'src\Core\App.ModuloAccess.pas',
  Catalogo.Migration in 'src\Catalogo\Migrations\Catalogo.Migration.pas',
  Catalogo.Routes in 'src\Catalogo\Routes\Catalogo.Routes.pas',
  Database.Seed in 'src\Catalogo\Seeds\Database.Seed.pas',
  Database.Seed.Planos in 'src\Catalogo\Seeds\Database.Seed.Planos.pas',
  Database.Seed.Unidade in 'src\Catalogo\Seeds\Database.Seed.Unidade.pas',
  Catalogo.Seeds in 'src\Catalogo\Seeds\Catalogo.Seeds.pas',
  Asmuv.Routes in 'src\Asmuv\Routes\Asmuv.Routes.pas',
  Asmuv.Migration in 'src\Asmuv\Migrations\Asmuv.Migration.pas',
  Asmuv.Seeds in 'src\Asmuv\Seeds\Asmuv.Seeds.pas',
  Segmento.Model in 'src\Catalogo\Model\Segmento.Model.pas',
  Segmento.DAO in 'src\Catalogo\Dao\Segmento.DAO.pas',
  Segmento.Service in 'src\Catalogo\Services\Segmento.Service.pas',
  Segmento.Controller in 'src\Catalogo\Controller\Segmento.Controller.pas',
  Database.Seed.Segmento in 'src\Catalogo\Seeds\Database.Seed.Segmento.pas',
  Autorizacao.Model in 'src\Asmuv\Model\Autorizacao.Model.pas',
  Autorizacao.DAO in 'src\Asmuv\Dao\Autorizacao.DAO.pas',
  Autorizacao.Controller in 'src\Asmuv\Controller\Autorizacao.Controller.pas',
  Campanha.Model in 'src\Asmuv\Model\Campanha.Model.pas',
  Campanha.Controller in 'src\Asmuv\Controller\Campanha.Controller.pas',
  Autorizacao.Service in 'src\Asmuv\Services\Autorizacao.Service.pas',
  Campanha.Service in 'src\Asmuv\Services\Campanha.Service.pas',
  Campanha.DAO in 'src\Asmuv\Dao\Campanha.DAO.pas',
  EmpresaAsmuv.Model in 'src\Asmuv\Model\EmpresaAsmuv.Model.pas',
  UsuarioAsmuv.Model in 'src\Asmuv\Model\UsuarioAsmuv.Model.pas',
  Candidato.Model in 'src\Asmuv\Model\Candidato.Model.pas',
  Socio.Model in 'src\Asmuv\Model\Socio.Model.pas',
  VerificaCode.Model in 'src\Asmuv\Model\VerificaCode.Model.pas',
  Convenio.Model in 'src\Asmuv\Model\Convenio.Model.pas',
  Membro.Model in 'src\Asmuv\Model\Membro.Model.pas',
  SindicatoDependente.Model in 'src\Asmuv\Model\SindicatoDependente.Model.pas',
  CampanhaHistorico.Model in 'src\Asmuv\Model\CampanhaHistorico.Model.pas',
  Carteira.Model in 'src\Asmuv\Model\Carteira.Model.pas',
  Notificacao.Model in 'src\Asmuv\Model\Notificacao.Model.pas',
  NotificacaoLida.Model in 'src\Asmuv\Model\NotificacaoLida.Model.pas',
  Secretaria.Model in 'src\Asmuv\Model\Secretaria.Model.pas',
  SindicatoProfissao.Model in 'src\Asmuv\Model\SindicatoProfissao.Model.pas',
  SindicatoRegistro.Model in 'src\Asmuv\Model\SindicatoRegistro.Model.pas',
  Votos.Model in 'src\Asmuv\Model\Votos.Model.pas',
  EmpresaAsmuv.DAO in 'src\Asmuv\Dao\EmpresaAsmuv.DAO.pas',
  EmpresaAsmuv.Service in 'src\Asmuv\Services\EmpresaAsmuv.Service.pas',
  Eleicao.Controller in 'src\EleicaoDescktop\Controller\Eleicao.Controller.pas',
  Eleicao.Service in 'src\EleicaoDescktop\Service\Eleicao.Service.pas',
  Eleicao.Migration in 'src\EleicaoDescktop\Migrations\Eleicao.Migration.pas',
  Eleicao.Routes in 'src\EleicaoDescktop\Routes\Eleicao.Routes.pas',
  Eleicao.Seeds in 'src\EleicaoDescktop\Seeds\Eleicao.Seeds.pas',
  Emp.Controller in 'src\EasyOneDescktop\Controller\Emp.Controller.pas',
  Emp.Dao in 'src\EasyOneDescktop\Dao\Emp.Dao.pas',
  EasyOne.Migration in 'src\EasyOneDescktop\Migrations\EasyOne.Migration.pas',
  Emp.Model in 'src\EasyOneDescktop\Model\Emp.Model.pas',
  EasyOne.Routes in 'src\EasyOneDescktop\Routes\EasyOne.Routes.pas',
  EasyOne.Seeds in 'src\EasyOneDescktop\Seeds\EasyOne.Seeds.pas',
  Emp.Service in 'src\EasyOneDescktop\Service\Emp.Service.pas',
  Associado.Controller in 'src\EasyOneDescktop\Controller\Associado.Controller.pas',
  Associado.Dao in 'src\EasyOneDescktop\Dao\Associado.Dao.pas',
  Associado.Model in 'src\EasyOneDescktop\Model\Associado.Model.pas',
  Associado.Service in 'src\EasyOneDescktop\Service\Associado.Service.pas',
  Usuarios.Model in 'src\EasyOneDescktop\Model\Usuarios.Model.pas',
  Usuarios.Dao in 'src\EasyOneDescktop\Dao\Usuarios.Dao.pas',
  Usuarios.Service in 'src\EasyOneDescktop\Service\Usuarios.Service.pas',
  Usuarios.Controller in 'src\EasyOneDescktop\Controller\Usuarios.Controller.pas',
  Eleicao.Model in 'src\EleicaoDescktop\Model\Eleicao.Model.pas',
  Eleicao.Dao in 'src\EleicaoDescktop\Dao\Eleicao.Dao.pas',
  EleicaoAPIPublic in 'src\EleicaoDescktop\Dao\EleicaoAPIPublic.pas',
  EleicaoAPIPublic.Service in 'src\EleicaoDescktop\Service\EleicaoAPIPublic.Service.pas',
  EleicaoAPIPublic.Controller in 'src\EleicaoDescktop\Controller\EleicaoAPIPublic.Controller.pas',
  EleicaoLoginAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoLoginAPI.Dao.pas',
  EleicaoConfirmacaoAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoConfirmacaoAPI.Controller.pas',
  WhatsApp.Service in 'src\EleicaoDescktop\Service\WhatsApp.Service.pas',
  EleicaoVotacaoAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoVotacaoAPI.Controller.pas',
  EleicaoVotacaoAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoVotacaoAPI.Dao.pas',
  EleicaoVotacaoAPI.Service in 'src\EleicaoDescktop\Service\EleicaoVotacaoAPI.Service.pas',
  EleicaoComprovanteAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoComprovanteAPI.Dao.pas',
  EleicaoComprovanteAPI.Service in 'src\EleicaoDescktop\Service\EleicaoComprovanteAPI.Service.pas',
  EleicaoComprovanteAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoComprovanteAPI.Controller.pas',
  EleicaoAdminAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoAdminAPI.Dao.pas',
  EleicaoAdminAPI.Service in 'src\EleicaoDescktop\Service\EleicaoAdminAPI.Service.pas',
  EleicaoAdminAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoAdminAPI.Controller.pas',
  EleicaoResultadoPublicoAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoResultadoPublicoAPI.Dao.pas',
  EleicaoResultadoPublicoAPI.Service in 'src\EleicaoDescktop\Service\EleicaoResultadoPublicoAPI.Service.pas',
  EleicaoResultadoPublicoAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoResultadoPublicoAPI.Controller.pas',
  EleicaoHorarioAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoHorarioAPI.Dao.pas',
  EleicaoHorarioAPI.Service in 'src\EleicaoDescktop\Service\EleicaoHorarioAPI.Service.pas',
  EleicaoAuditoriaAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoAuditoriaAPI.Dao.pas',
  EleicaoAuditoriaAPI.Service in 'src\EleicaoDescktop\Service\EleicaoAuditoriaAPI.Service.pas',
  App.RequestInfo in 'src\Core\App.RequestInfo.pas',
  EleicaoMembroFotoAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoMembroFotoAPI.Dao.pas',
  EleicaoMembroFotoAPI.Service in 'src\EleicaoDescktop\Service\EleicaoMembroFotoAPI.Service.pas',
  EleicaoMembroFotoAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoMembroFotoAPI.Controller.pas',
  EleicaoRelatorioAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoRelatorioAPI.Dao.pas',
  EleicaoRelatorioAPI.Service in 'src\EleicaoDescktop\Service\EleicaoRelatorioAPI.Service.pas',
  EleicaoRelatorioAPI.Controller in 'src\EleicaoDescktop\Controller\EleicaoRelatorioAPI.Controller.pas',
  EleicaoRateLimitAPI.Dao in 'src\EleicaoDescktop\Dao\EleicaoRateLimitAPI.Dao.pas',
  EleicaoRateLimitAPI.Service in 'src\EleicaoDescktop\Service\EleicaoRateLimitAPI.Service.pas',
  WhatsAppConfigAPI.Dao in 'src\EleicaoDescktop\Dao\WhatsAppConfigAPI.Dao.pas',
  WhatsAppConfigAPI.Service in 'src\EleicaoDescktop\Service\WhatsAppConfigAPI.Service.pas',
  EasyOneIntegracao.Dao in 'src\EasyOneDescktop\Dao\EasyOneIntegracao.Dao.pas',
  EasyOneIntegracao.Service in 'src\EasyOneDescktop\Service\EasyOneIntegracao.Service.pas',
  EasyOneIntegracao.Controller in 'src\EasyOneDescktop\Controller\EasyOneIntegracao.Controller.pas',
  Cursos.Migration in 'src\Cursos\Migrations\Cursos.Migration.pas',
  DelphiZXingQRCode in 'src\ThirdParty\DelphiZXingQRCode.pas',
  Cursos.Routes in 'src\Cursos\Routes\Cursos.Routes.pas',
  PublicoAutoCadastro.DAO in 'src\Cursos\Dao\PublicoAutoCadastro.DAO.pas',
  PublicoAutoCadastro.Service in 'src\Cursos\Services\PublicoAutoCadastro.Service.pas',
  PublicoAutoCadastro.Controller in 'src\Cursos\Controller\PublicoAutoCadastro.Controller.pas',
  PlataformaAuth.Controller in 'src\Cursos\Controller\PlataformaAuth.Controller.pas',
  PlataformaAuth.Service in 'src\Cursos\Services\PlataformaAuth.Service.pas',
  Certifica.Seeds in 'src\Cursos\Seeds\Certifica.Seeds.pas',
  PlataformaAuth.DAO in 'src\Cursos\Dao\PlataformaAuth.DAO.pas',
  Certifica.DatabaseBootstrap in 'src\Cursos\Migrations\Certifica.DatabaseBootstrap.pas',
  PlataformaInstituicao.Controller in 'src\Cursos\Controller\PlataformaInstituicao.Controller.pas',
  PlataformaInstituicao.DAO in 'src\Cursos\Dao\PlataformaInstituicao.DAO.pas',
  PlataformaInstituicao.Model in 'src\Cursos\Model\PlataformaInstituicao.Model.pas',
  PlataformaInstituicao.Service in 'src\Cursos\Services\PlataformaInstituicao.Service.pas',
  PlataformaUsuario.Model in 'src\Cursos\Model\PlataformaUsuario.Model.pas',
  PlataformaUsuario.DAO in 'src\Cursos\Dao\PlataformaUsuario.DAO.pas',
  PlataformaUsuario.Service in 'src\Cursos\Services\PlataformaUsuario.Service.pas',
  PlataformaUsuario.Controller in 'src\Cursos\Controller\PlataformaUsuario.Controller.pas',
  PlataformaAuditoria.Model in 'src\Cursos\Model\PlataformaAuditoria.Model.pas',
  PlataformaAuditoria.DAO in 'src\Cursos\Dao\PlataformaAuditoria.DAO.pas',
  PlataformaAuditoria.Service in 'src\Cursos\Services\PlataformaAuditoria.Service.pas',
  PlataformaAuditoria.Controller in 'src\Cursos\Controller\PlataformaAuditoria.Controller.pas',
  InstituicaoAuth.DAO in 'src\Cursos\Dao\InstituicaoAuth.DAO.pas',
  InstituicaoAuth.Service in 'src\Cursos\Services\InstituicaoAuth.Service.pas',
  InstituicaoAuth.Controller in 'src\Cursos\Controller\InstituicaoAuth.Controller.pas',
  InstituicaoDashboard.DAO in 'src\Cursos\Dao\InstituicaoDashboard.DAO.pas',
  InstituicaoDashboard.Service in 'src\Cursos\Services\InstituicaoDashboard.Service.pas',
  InstituicaoDashboard.Controller in 'src\Cursos\Controller\InstituicaoDashboard.Controller.pas',
  InstituicaoCurso.Model in 'src\Cursos\Model\InstituicaoCurso.Model.pas',
  InstituicaoCurso.DAO in 'src\Cursos\Dao\InstituicaoCurso.DAO.pas',
  InstituicaoCurso.Service in 'src\Cursos\Services\InstituicaoCurso.Service.pas',
  InstituicaoCurso.Controller in 'src\Cursos\Controller\InstituicaoCurso.Controller.pas',
  InstituicaoCursoCategoria.Model in 'src\Cursos\Model\InstituicaoCursoCategoria.Model.pas',
  InstituicaoCursoCategoria.DAO in 'src\Cursos\Dao\InstituicaoCursoCategoria.DAO.pas',
  InstituicaoCursoCategoria.Service in 'src\Cursos\Services\InstituicaoCursoCategoria.Service.pas',
  InstituicaoCursoCategoria.Controller in 'src\Cursos\Controller\InstituicaoCursoCategoria.Controller.pas',
  InstituicaoCertificadoModelo.Model in 'src\Cursos\Model\InstituicaoCertificadoModelo.Model.pas',
  InstituicaoCertificadoModelo.DAO in 'src\Cursos\Dao\InstituicaoCertificadoModelo.DAO.pas',
  InstituicaoCertificadoModelo.Service in 'src\Cursos\Services\InstituicaoCertificadoModelo.Service.pas',
  InstituicaoCertificadoModelo.Controller in 'src\Cursos\Controller\InstituicaoCertificadoModelo.Controller.pas',
  InstituicaoTurma.Model in 'src\Cursos\Model\InstituicaoTurma.Model.pas',
  InstituicaoTurma.DAO in 'src\Cursos\Dao\InstituicaoTurma.DAO.pas',
  InstituicaoTurma.Service in 'src\Cursos\Services\InstituicaoTurma.Service.pas',
  InstituicaoTurma.Controller in 'src\Cursos\Controller\InstituicaoTurma.Controller.pas',
  InstituicaoInstrutor.Model in 'src\Cursos\Model\InstituicaoInstrutor.Model.pas',
  InstituicaoInstrutor.DAO in 'src\Cursos\Dao\InstituicaoInstrutor.DAO.pas',
  InstituicaoInstrutor.Service in 'src\Cursos\Services\InstituicaoInstrutor.Service.pas',
  InstituicaoInstrutor.Controller in 'src\Cursos\Controller\InstituicaoInstrutor.Controller.pas',
  InstituicaoCursoInstrutor.Controller in 'src\Cursos\Controller\InstituicaoCursoInstrutor.Controller.pas',
  InstituicaoCursoInstrutor.DAO in 'src\Cursos\Dao\InstituicaoCursoInstrutor.DAO.pas',
  InstituicaoCursoInstrutor.Model in 'src\Cursos\Model\InstituicaoCursoInstrutor.Model.pas',
  InstituicaoCursoInstrutor.Service in 'src\Cursos\Services\InstituicaoCursoInstrutor.Service.pas',
  InstituicaoTurmaInstrutor.Controller in 'src\Cursos\Controller\InstituicaoTurmaInstrutor.Controller.pas',
  InstituicaoTurmaInstrutor.DAO in 'src\Cursos\Dao\InstituicaoTurmaInstrutor.DAO.pas',
  InstituicaoTurmaInstrutor.Model in 'src\Cursos\Model\InstituicaoTurmaInstrutor.Model.pas',
  InstituicaoTurmaInstrutor.Service in 'src\Cursos\Services\InstituicaoTurmaInstrutor.Service.pas',
  InstituicaoTurmaEncontro.Controller in 'src\Cursos\Controller\InstituicaoTurmaEncontro.Controller.pas',
  InstituicaoTurmaEncontro.DAO in 'src\Cursos\Dao\InstituicaoTurmaEncontro.DAO.pas',
  InstituicaoTurmaEncontro.Model in 'src\Cursos\Model\InstituicaoTurmaEncontro.Model.pas',
  InstituicaoTurmaEncontro.Service in 'src\Cursos\Services\InstituicaoTurmaEncontro.Service.pas',
  InstituicaoTurmaCriterioConclusao.Controller in 'src\Cursos\Controller\InstituicaoTurmaCriterioConclusao.Controller.pas',
  InstituicaoTurmaCriterioConclusao.DAO in 'src\Cursos\Dao\InstituicaoTurmaCriterioConclusao.DAO.pas',
  InstituicaoTurmaCriterioConclusao.Model in 'src\Cursos\Model\InstituicaoTurmaCriterioConclusao.Model.pas',
  InstituicaoTurmaCriterioConclusao.Service in 'src\Cursos\Services\InstituicaoTurmaCriterioConclusao.Service.pas',
  App.ParticipanteSecurity in 'src\Core\App.ParticipanteSecurity.pas',
  InstituicaoParticipante.Controller in 'src\Cursos\Controller\InstituicaoParticipante.Controller.pas',
  InstituicaoParticipante.DAO in 'src\Cursos\Dao\InstituicaoParticipante.DAO.pas',
  InstituicaoParticipante.Model in 'src\Cursos\Model\InstituicaoParticipante.Model.pas',
  InstituicaoParticipante.Service in 'src\Cursos\Services\InstituicaoParticipante.Service.pas',
  InstituicaoInscricao.Controller in 'src\Cursos\Controller\InstituicaoInscricao.Controller.pas',
  InstituicaoInscricao.DAO in 'src\Cursos\Dao\InstituicaoInscricao.DAO.pas',
  InstituicaoInscricao.Model in 'src\Cursos\Model\InstituicaoInscricao.Model.pas',
  InstituicaoInscricao.Service in 'src\Cursos\Services\InstituicaoInscricao.Service.pas',
  InstituicaoPresenca.Controller in 'src\Cursos\Controller\InstituicaoPresenca.Controller.pas',
  InstituicaoPresenca.DAO in 'src\Cursos\Dao\InstituicaoPresenca.DAO.pas',
  InstituicaoPresenca.Model in 'src\Cursos\Model\InstituicaoPresenca.Model.pas',
  InstituicaoPresenca.Service in 'src\Cursos\Services\InstituicaoPresenca.Service.pas',
  InstituicaoConclusao.Controller in 'src\Cursos\Controller\InstituicaoConclusao.Controller.pas',
  InstituicaoConclusao.DAO in 'src\Cursos\Dao\InstituicaoConclusao.DAO.pas',
  InstituicaoConclusao.Model in 'src\Cursos\Model\InstituicaoConclusao.Model.pas',
  InstituicaoConclusao.Service in 'src\Cursos\Services\InstituicaoConclusao.Service.pas',
  InstituicaoCertificado.Controller in 'src\Cursos\Controller\InstituicaoCertificado.Controller.pas',
  InstituicaoCertificado.DAO in 'src\Cursos\Dao\InstituicaoCertificado.DAO.pas',
  InstituicaoCertificado.Model in 'src\Cursos\Model\InstituicaoCertificado.Model.pas',
  InstituicaoCertificado.Service in 'src\Cursos\Services\InstituicaoCertificado.Service.pas',
  App.ProcessRunner in 'src\Core\App.ProcessRunner.pas',
  InstituicaoCertificadoDocumento.Config in 'src\Cursos\Config\InstituicaoCertificadoDocumento.Config.pas',
  InstituicaoCertificadoDocumento.Controller in 'src\Cursos\Controller\InstituicaoCertificadoDocumento.Controller.pas',
  InstituicaoCertificadoDocumento.DAO in 'src\Cursos\Dao\InstituicaoCertificadoDocumento.DAO.pas',
  InstituicaoCertificadoDocumento.Model in 'src\Cursos\Model\InstituicaoCertificadoDocumento.Model.pas',
  InstituicaoCertificadoDocumento.Service in 'src\Cursos\Services\InstituicaoCertificadoDocumento.Service.pas',
  AlunoPortal.Controller in 'src\Cursos\Controller\AlunoPortal.Controller.pas',
  InstituicaoParticipanteAcesso.Controller in 'src\Cursos\Controller\InstituicaoParticipanteAcesso.Controller.pas',
  AlunoPortal.DAO in 'src\Cursos\Dao\AlunoPortal.DAO.pas',
  InstituicaoParticipanteAcesso.DAO in 'src\Cursos\Dao\InstituicaoParticipanteAcesso.DAO.pas',
  AlunoPortal.Model in 'src\Cursos\Model\AlunoPortal.Model.pas',
  InstituicaoParticipanteAcesso.Model in 'src\Cursos\Model\InstituicaoParticipanteAcesso.Model.pas',
  AlunoPortal.Service in 'src\Cursos\Services\AlunoPortal.Service.pas',
  InstituicaoParticipanteAcesso.Service in 'src\Cursos\Services\InstituicaoParticipanteAcesso.Service.pas',
  AlunoCursoDisponivel.Controller in 'src\Cursos\Controller\AlunoCursoDisponivel.Controller.pas',
  AlunoQrParticipante.Controller in 'src\Cursos\Controller\AlunoQrParticipante.Controller.pas',
  InstituicaoInscricaoAprovacao.Controller in 'src\Cursos\Controller\InstituicaoInscricaoAprovacao.Controller.pas',
  InstituicaoPresencaQr.Controller in 'src\Cursos\Controller\InstituicaoPresencaQr.Controller.pas',
  AlunoCursoDisponivel.DAO in 'src\Cursos\Dao\AlunoCursoDisponivel.DAO.pas',
  InstituicaoInscricaoAprovacao.DAO in 'src\Cursos\Dao\InstituicaoInscricaoAprovacao.DAO.pas',
  InstituicaoPresencaQr.DAO in 'src\Cursos\Dao\InstituicaoPresencaQr.DAO.pas',
  AlunoCursoDisponivel.Model in 'src\Cursos\Model\AlunoCursoDisponivel.Model.pas',
  AlunoQrParticipante.Model in 'src\Cursos\Model\AlunoQrParticipante.Model.pas',
  AlunoCursoDisponivel.Service in 'src\Cursos\Services\AlunoCursoDisponivel.Service.pas',
  AlunoQrParticipante.Service in 'src\Cursos\Services\AlunoQrParticipante.Service.pas',
  InstituicaoInscricaoAprovacao.Service in 'src\Cursos\Services\InstituicaoInscricaoAprovacao.Service.pas',
  InstituicaoPresencaQr.Service in 'src\Cursos\Services\InstituicaoPresencaQr.Service.pas',
  PublicoInstituicao.Controller in 'src\Cursos\Controller\PublicoInstituicao.Controller.pas',
  PublicoInstituicao.DAO in 'src\Cursos\Dao\PublicoInstituicao.DAO.pas',
  PublicoInstituicao.Model in 'src\Cursos\Model\PublicoInstituicao.Model.pas',
  PublicoInstituicao.Service in 'src\Cursos\Services\PublicoInstituicao.Service.pas',
  InstituicaoConfiguracao.Controller in 'src\Cursos\Controller\InstituicaoConfiguracao.Controller.pas',
  InstituicaoConfiguracao.DAO in 'src\Cursos\Dao\InstituicaoConfiguracao.DAO.pas',
  InstituicaoConfiguracao.Model in 'src\Cursos\Model\InstituicaoConfiguracao.Model.pas',
  Certifica.Secrets in 'src\Cursos\Security\Certifica.Secrets.pas',
  InstituicaoConfiguracao.Service in 'src\Cursos\Services\InstituicaoConfiguracao.Service.pas',
  InstituicaoEmail.Service in 'src\Cursos\Services\InstituicaoEmail.Service.pas',
  InstituicaoPermissao.DAO in 'src\Cursos\Dao\InstituicaoPermissao.DAO.pas',
  InstituicaoPermissao.Service in 'src\Cursos\Services\InstituicaoPermissao.Service.pas',
  InstituicaoPerfil.Model in 'src\Cursos\Model\InstituicaoPerfil.Model.pas',
  InstituicaoPerfil.DAO in 'src\Cursos\Dao\InstituicaoPerfil.DAO.pas',
  InstituicaoPerfil.Service in 'src\Cursos\Services\InstituicaoPerfil.Service.pas',
  InstituicaoPerfil.Controller in 'src\Cursos\Controller\InstituicaoPerfil.Controller.pas',
  InstituicaoUsuario.Model in 'src\Cursos\Model\InstituicaoUsuario.Model.pas',
  InstituicaoUsuario.DAO in 'src\Cursos\Dao\InstituicaoUsuario.DAO.pas',
  InstituicaoUsuario.Service in 'src\Cursos\Services\InstituicaoUsuario.Service.pas',
  InstituicaoUsuario.Controller in 'src\Cursos\Controller\InstituicaoUsuario.Controller.pas',
  PlataformaWhatsApp.Model in 'src\Cursos\Model\PlataformaWhatsApp.Model.pas',
  PlataformaWhatsApp.DAO in 'src\Cursos\Dao\PlataformaWhatsApp.DAO.pas',
  PlataformaWhatsApp.Service in 'src\Cursos\Services\PlataformaWhatsApp.Service.pas',
  PlataformaWhatsApp.Controller in 'src\Cursos\Controller\PlataformaWhatsApp.Controller.pas',
  PlataformaEmail.Controller in 'src\Cursos\Controller\PlataformaEmail.Controller.pas',
  PlataformaIdentidade.Model in 'src\Cursos\Model\PlataformaIdentidade.Model.pas',
  PlataformaIdentidade.DAO in 'src\Cursos\Dao\PlataformaIdentidade.DAO.pas',
  PlataformaIdentidade.Service in 'src\Cursos\Services\PlataformaIdentidade.Service.pas',
  PlataformaIdentidade.Controller in 'src\Cursos\Controller\PlataformaIdentidade.Controller.pas',
  PlataformaEmail.DAO in 'src\Cursos\Dao\PlataformaEmail.DAO.pas',
  PlataformaEmail.Model in 'src\Cursos\Model\PlataformaEmail.Model.pas',
  PlataformaEmail.Service in 'src\Cursos\Services\PlataformaEmail.Service.pas',
  PlataformaEmailEnvio.Service in 'src\Cursos\Services\PlataformaEmailEnvio.Service.pas',
  PublicoRecuperacaoSenha.Controller in 'src\Cursos\Controller\PublicoRecuperacaoSenha.Controller.pas',
  PublicoRecuperacaoSenha.DAO in 'src\Cursos\Dao\PublicoRecuperacaoSenha.DAO.pas',
  PublicoRecuperacaoSenha.Service in 'src\Cursos\Services\PublicoRecuperacaoSenha.Service.pas',
  InstituicaoWhatsApp.Model in 'src\Cursos\Model\InstituicaoWhatsApp.Model.pas',
  InstituicaoWhatsApp.DAO in 'src\Cursos\Dao\InstituicaoWhatsApp.DAO.pas',
  EvolutionApi.Service in 'src\Cursos\Services\EvolutionApi.Service.pas',
  InstituicaoWhatsApp.Service in 'src\Cursos\Services\InstituicaoWhatsApp.Service.pas',
  InstituicaoWhatsApp.Controller in 'src\Cursos\Controller\InstituicaoWhatsApp.Controller.pas',
  PublicoPrimeiroAcesso.DAO in 'src\Cursos\Dao\PublicoPrimeiroAcesso.DAO.pas',
  PublicoPrimeiroAcesso.Service in 'src\Cursos\Services\PublicoPrimeiroAcesso.Service.pas',
  PublicoPrimeiroAcesso.Controller in 'src\Cursos\Controller\PublicoPrimeiroAcesso.Controller.pas',
  PlataformaAjuda.Controller in 'src\Cursos\Controller\PlataformaAjuda.Controller.pas',
  PlataformaAjuda.DAO in 'src\Cursos\Dao\PlataformaAjuda.DAO.pas',
  PlataformaAjuda.Model in 'src\Cursos\Model\PlataformaAjuda.Model.pas',
  PlataformaAjuda.Service in 'src\Cursos\Services\PlataformaAjuda.Service.pas',
  Cursos.Seeds in 'src\Cursos\Seeds\Cursos.Seeds.pas',
  Cursos.DemoSeeds in 'src\Cursos\Seeds\Cursos.DemoSeeds.pas',
  CertificadoProcessamento.Model in 'src\Cursos\Model\CertificadoProcessamento.Model.pas',
  CertificadoProcessamento.DAO in 'src\Cursos\Dao\CertificadoProcessamento.DAO.pas',
  CertificadoProcessamento.Service in 'src\Cursos\Services\CertificadoProcessamento.Service.pas',
  CertificadoProcessamento.Worker in 'src\Cursos\Services\CertificadoProcessamento.Worker.pas',
  CertificadoProcessamento.Controller in 'src\Cursos\Controller\CertificadoProcessamento.Controller.pas',
  CertificadoNotificacao.Model in 'src\Cursos\Model\CertificadoNotificacao.Model.pas',
  CertificadoNotificacao.DAO in 'src\Cursos\Dao\CertificadoNotificacao.DAO.pas',
  CertificadoNotificacao.Service in 'src\Cursos\Services\CertificadoNotificacao.Service.pas',
  CertificadoNotificacao.Worker in 'src\Cursos\Services\CertificadoNotificacao.Worker.pas';

var
  LConfig       : TAppApiConfig;
  LConn         : TUniConnection;
  LDatabaseCfg  : TAppDatabaseConfig;
  LCertDocCfg   : TCertificadoDocumentoConfig;
begin
  try
    // Carrega sempre o Config.ini da mesma pasta do executável.
    Writeln('Config.ini: ' + ExtractFilePath(ParamStr(0)) + 'Config.ini');

    LConfig := TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

    case LConfig.Produto of
      apCatalogo:  Writeln('Produto configurado: CATALOGO');
      apEasyOne:   Writeln('Produto configurado: EASYONE');
      apMoviSystem: Writeln('Produto configurado: MOVISYSTEM');
    end;

    Writeln('Ambiente configurado: ' + LConfig.Ambiente);
    Writeln('Banco configurado: ' + LConfig.Database.Database);
    Writeln('Servidor configurado: ' + LConfig.Database.Server);
    Writeln('--------------------------------------------');

    case LConfig.Produto of

      {$REGION 'Catalogo'}
      apCatalogo:
        begin
          TCatalogoMigration.Run(LConfig.Database);
          Writeln('Migrations do catalogo executadas com sucesso.');

          TCatalogoSeeds.Run;
          Writeln('Seeds do catalogo executadas com sucesso.');
        end;
      {$ENDREGION}

      {$REGION 'EasyOne'}
      apEasyOne:
        begin
          //asmuv
          //TAsmuvMigration.Run(LConfig.Database);
          //Writeln('Migrations do Asmuv executadas com sucesso.');

          //TAsmuvSeeds.Run;
          //Writeln('Seeds do Asmuv executadas com sucesso.');

          //EasyONe
          TEasyOneMigration.Run(LConfig.Database);
          Writeln('Migrations do Asmuv executadas com sucesso.');

          TeasyOneSeeds.Run;
          Writeln('Seeds do EasyOne executadas com sucesso.');

          //Eleicao
          TEleicaoMigration.Run(LConfig.Database);
          Writeln('Migrations do Eleição executadas com sucesso.');

          TEleicaoSeeds.Run;
          Writeln('Seeds do Eleição executadas com sucesso.');

        end;
      {$ENDREGION}

      {$REGION 'MoviSystem'}
      apMoviSystem:
        begin
          // Cria uma configuração temporária sem banco selecionado.
          // Assim conseguimos conectar no servidor MySQL mesmo quando
          // o banco configurado ainda não existe.
          LDatabaseCfg          := LConfig.Database;
          LDatabaseCfg.Database := '';
          LConn := TDatabaseConnection.NewConnection(LDatabaseCfg);
          try
            // Garante que o banco configurado exista antes das migrations.
            TCursosDatabaseBootstrap.EnsureDatabase(LConn,LConfig.Database.Database);
            Writeln('Banco MoviSystem verificado/criado com sucesso.');
          finally
            LConn.Free;
          end;

          //Roda tabelas
          TCursosMigration.Run(LConfig.Database);

          if SameText(LConfig.Ambiente, 'PRODUCAO') then
          begin
            LCertDocCfg :=
              TInstituicaoCertificadoDocumentoConfig.Carregar(True);

            Writeln(
              'Configuracao de documentos de certificado validada com sucesso.'
            );
          end;

          //Roda o seeds com dados inicial
          TCertificaSeeds.Run;
          Writeln('Seed do administrador MoviSystem executado com sucesso.');

          TCursosSeeds.Run;
          Writeln('Seeds de permissoes e perfis executadas com sucesso.');

          if LConfig.RunDemoSeeds then
          begin
            TCursosDemoSeeds.Run;
            Writeln('Seeds de demo executadas com sucesso.');
          end
          else
            Writeln('Seeds de demo desabilitadas.');

          TPlataformaCampanhaWorker.Start;
          Writeln('Worker de campanhas iniciado com sucesso.');

          TCertificadoProcessamentoWorker.Start;
          Writeln('Worker de certificados iniciado com sucesso.');

          TCertificadoNotificacaoWorker.Start;
          Writeln('Worker de notificacoes de certificados iniciado com sucesso.');


        end;
      {$ENDREGION}

    end;

    HorseCORS
      .AllowedOrigin(LConfig.CorsAllowedOrigin)
      .AllowedCredentials(False)
      .AllowedHeaders('Authorization, Content-Type, Accept')
      .AllowedMethods('GET, POST, PUT, PATCH, DELETE, OPTIONS')
      .ExposedHeaders('');

    THorse.Use(TMiddlewareSecurityHeaders.Headers);
    THorse.Use(CORS);
    THorse.Use(TMiddlewareAuditoria.Registrar);
    THorse.Use(Jhonson);
    THorse.Use(Horse.Upload.Upload);

    case LConfig.Produto of

      {$REGION 'Catalogo'}
      apCatalogo:
        begin
          TCatalogoRoutes.Registry;
          Writeln('Rotas do catalogo registradas com sucesso.');
        end;
      {$ENDREGION}

      {$REGION 'EasyOne'}
      apEasyOne:
        begin
          TAsmuvRoutes.Registry;
          Writeln('Rotas do ASMUV registradas com sucesso.');

          TEasyOneRoutes.Registry;
          Writeln('Rotas do EasyOne registradas com sucesso.');

          TEleicaoRoutes.Registry;
          Writeln('Rotas do Eleição registradas com sucesso.');
        end;
      {$ENDREGION}

      {$REGION 'MoviSystem'}
      apMoviSystem:
        begin
          //registro das rotas
          TCursosRoutes.Registry;
            Writeln('Rotas MoviSystem registrada com sucesso.');
        end;

      {$ENDREGION}
    end;

    case LConfig.Produto of
      apCatalogo:
        Writeln('Modulo ativo: CATALOGO');
      apEasyOne:
        Writeln('Modulo ativo: EASYONE');
      apMoviSystem:
        Writeln('Modulo ativo: MoviSystem');
    end;

    Writeln('API iniciada na porta ' + LConfig.Porta.ToString);
    Writeln('Ambiente: Windows/Linux');


    Writeln('Pressione CTRL + C para finalizar.');

    THorse.Listen(LConfig.Porta);
  except
    on E: Exception do
    begin
      Writeln('Erro ao iniciar API: ' + E.Message);
      Writeln;
      Writeln('Pressione ENTER para fechar...');
      Readln;
    end;
  end;
end.
