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
  PlataformaModulo.Controller,
  PlataformaUsuario.Controller,
  PlataformaAuditoria.Controller,
  PlataformaWhatsApp.Controller,
  PlataformaEmail.Controller,
  PlataformaIdentidade.Controller,
  PlataformaAjuda.Controller,
  PlataformaCampanha.Controller,
  PlataformaUsuarioWhatsApp.Controller,
  PublicoRecuperacaoSenha.Controller,
  InstituicaoAuth.Controller,
  InstituicaoDashboard.Controller,
  InstituicaoCurso.Controller,
  InstituicaoCursoCategoria.Controller,
  InstituicaoCertificadoModelo.Controller,
  InstituicaoTurma.Controller,
  InstituicaoTurmaImportacao.Controller,
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
  CertificadoProcessamento.Controller,
  InstituicaoCertificadoDocumento.Controller,
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
  InstituicaoAuditoria.Controller,
  InstituicaoRelatorioCertificado.Controller,
  InstituicaoRelatorioTurma.Controller,
  LgpdSolicitacao.Controller,
  PublicoPrimeiroAcesso.Controller,
  PublicoAutoCadastro.Controller;

{ TCursosRoutes }

class procedure TCursosRoutes.Registry;
begin
  TEncontroCheckinController.Registry;
  TPlataformaAuthController.Registry;
  TPlataformaInstituicaoController.Registry;
  TPlataformaModuloController.Registry;
  TPlataformaUsuarioController.Registry;
  TPlataformaAuditoriaController.Registry;
  TPlataformaWhatsAppController.Registry;
  TPlataformaEmailController.Registry;
  TPlataformaIdentidadeController.Registry;
  TPlataformaAjudaController.Registry;
  TPlataformaCampanhaController.Registry;
  TPlataformaUsuarioWhatsAppController.Registry;
  TPublicoRecuperacaoSenhaController.Registry;
  TInstituicaoAuthController.Registry;
  TInstituicaoDashboardController.Registry;
  TInstituicaoCursoController.Registry;
  TInstituicaoCursoCategoriaController.Registry;
  TInstituicaoCertificadoModeloController.Registry;
  TInstituicaoTurmaController.Registry;
  TInstituicaoTurmaImportacaoController.Registry;
  TInstituicaoInstrutorController.Registry;
  TInstituicaoCursoInstrutorController.Registry;
  TInstituicaoTurmaInstrutorController.Registry;
  TInstituicaoTurmaEncontroController.Registry;
  TInstituicaoTurmaCriterioConclusaoController.Registry;
  TInstituicaoParticipanteController.Registry;
  TInstituicaoInscricaoController.Registry;
  TInstituicaoPresencaController.Registry;
  TInstituicaoConclusaoController.Registry;
  TCertificadoProcessamentoController.Registry;
  TInstituicaoCertificadoController.Registry;
  TInstituicaoCertificadoDocumentoController.Registry;
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
  TInstituicaoAuditoriaController.Registry;
  TInstituicaoRelatorioCertificadoController.Registry;
  TInstituicaoRelatorioTurmaController.Registry;
  TLgpdSolicitacaoController.Registry;
  TPublicoPrimeiroAcessoController.Registry;
  TPublicoAutoCadastroController.Registry;
end;

end.
