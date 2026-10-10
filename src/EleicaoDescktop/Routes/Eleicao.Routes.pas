unit Eleicao.Routes;

interface
type
  TEleicaoRoutes = class
  public
    class procedure Registry; static;
  end;

implementation

Uses
    Eleicao.Controller,
    EleicaoAPIPublic.Controller,
    EleicaoConfirmacaoAPI.Controller,
    EleicaoVotacaoAPI.Controller,
    EleicaoComprovanteAPI.Controller,
    EleicaoAdminAPI.Controller,
    EleicaoApuracaoEvolucaoAPI.Controller,
    EleicaoResultadoPublicoAPI.Controller,
    EleicaoMembroFotoAPI.Controller,
    EleicaoRelatorioAPI.Controller,
    EleicaoAtualizacaoCadastralAPI.Controller,
    EleicaoIntegracaoResultado.Controller,
    EleicaoListaPublicaAPI.Controller,
    EleicaoEmailConfigAPI.Controller;
{ TEleicaoRoutes }

class procedure TEleicaoRoutes.Registry;
begin
  //
  TEleicaoController.Registry;
  TEleicaoController.RegistryConfig;
  TEleicaoController.RegistryChapa;
  TEleicaoController.RegistryMembros;
  TEleicaoController.RegistryComissao;
  TEleicaoController.RegistryQuestao;
  TEleicaoController.RegistryQuestaoOpcao;
  TEleicaoAPIConfirmacaoController.Registry;
  TEleicaoAPIVotacaoController.Registry;
  TEleicaoComprovanteAPIController.Registry;
  TEleicaoAdminAPIController.Registry;
  TEleicaoApuracaoEvolucaoAPIController.Registry;
  TEleicaoResultadoPublicoAPIController.Registry;
  TEleicaoMembroFotoAPIController.Registry;
  TEleicaoRelatorioAPIController.Registry;
  TEleicaoAtualizacaoCadastralAPIController.Registry;
  TEleicaoIntegracaoResultadoController.Registry;
  TEleicaoListaPublicaAPIController.Registry;
  TEleicaoEmailConfigAPIController.Registry;

  //Rota API
  TEleicaoAPIPublicController.Registry;
end;

end.
