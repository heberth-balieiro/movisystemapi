unit Cursos.Routes;

interface

type
  TCursosRoutes = class
  public
    class procedure Registry; static;
  end;

implementation

Uses
  EncontroCheckin.Controller,
  PlataformaAuth.Controller,
  PlataformaInstituicao.Controller,
  PlataformaUsuario.Controller,
  PlataformaAuditoria.Controller,
  PlataformaWhatsApp.Controller,
  PlataformaEmail.Controller,
  PlataformaAjuda.Controller,
  PublicoRecuperacaoSenha.Controller,
  InstituicaoAuth.Controller,
  InstituicaoDashboard.Controller,
  InstituicaoCurso.Controller,
  InstituicaoCursoCategoria.Controller,
  InstituicaoCertificadoModelo.Controller,
  InstituicaoTurma.Controller,
  InstituicaoInstrutor.Controller,
  InstituicaoCursoInstrutor.Controller,
  InstituicaoTurmaInstrutor.Controller,
  InstituicaoTurmaEncontro.Controller,
  InstituicaoTurmaCriterioConclusao.Controller,
  InstituicaoParticipante.Controller,
  InstituicaoInscricao.Controller,
  InstituicaoPresenca.Controller,
  InstituicaoConclusao.Controller,
  InstituicaoCertificado.Controller,
  AlunoPortal.Controller,
  InstituicaoParticipanteAcesso.Controller,
  AlunoCursoDisponivel.Controller,
  AlunoQrParticipante.Controller,
  InstituicaoInscricaoAprovacao.Controller,
  InstituicaoPresencaQr.Controller,
  PublicoInstituicao.Controller,
  InstituicaoConfiguracao.Controller,
  InstituicaoPerfil.Controller,
  InstituicaoUsuario.Controller,
  InstituicaoWhatsApp.Controller,
  PublicoPrimeiroAcesso.Controller;

{ TCursosRoutes }

class procedure TCursosRoutes.Registry;
begin
  TEncontroCheckinController.Registry;
  TPlataformaAuthController.Registry;
  TPlataformaInstituicaoController.Registry;
  TPlataformaUsuarioController.Registry;
  TPlataformaAuditoriaController.Registry;
  TPlataformaWhatsAppController.Registry;
  TPlataformaEmailController.Registry;
  TPlataformaAjudaController.Registry;
  TPublicoRecuperacaoSenhaController.Registry;
  TInstituicaoAuthController.Registry;
  TInstituicaoDashboardController.Registry;
  TInstituicaoCursoController.Registry;
  TInstituicaoCursoCategoriaController.Registry;
  TInstituicaoCertificadoModeloController.Registry;
  TInstituicaoTurmaController.Registry;
  TInstituicaoInstrutorController.Registry;
  TInstituicaoCursoInstrutorController.Registry;
  TInstituicaoTurmaInstrutorController.Registry;
  TInstituicaoTurmaEncontroController.Registry;
  TInstituicaoTurmaCriterioConclusaoController.Registry;
  TInstituicaoParticipanteController.Registry;
  TInstituicaoInscricaoController.Registry;
  TInstituicaoPresencaController.Registry;
  TInstituicaoConclusaoController.Registry;
  TInstituicaoCertificadoController.Registry;
  TAlunoPortalController.Registry;
  TInstituicaoParticipanteAcessoController.Registry;
  TAlunoCursoDisponivelController.Registry;
  TAlunoQrParticipanteController.Registry;
  TInstituicaoInscricaoAprovacaoController.Registry;
  TInstituicaoPresencaQrController.Registry;
  TPublicoInstituicaoController.Registry;
  TInstituicaoConfiguracaoController.Registry;
  TInstituicaoPerfilController.Registry;
  TInstituicaoUsuarioController.Registry;
  TInstituicaoWhatsAppController.Registry;
  TPublicoPrimeiroAcessoController.Registry;
end;

end.
