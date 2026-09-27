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
    EleicaoResultadoPublicoAPI.Controller,
    EleicaoMembroFotoAPI.Controller,
    EleicaoRelatorioAPI.Controller;
{ TEleicaoRoutes }

class procedure TEleicaoRoutes.Registry;
begin
  //
  TEleicaoController.Registry;
  TEleicaoController.RegistryConfig;
  TEleicaoController.RegistryChapa;
  TEleicaoController.RegistryMembros;
  TEleicaoAPIConfirmacaoController.Registry;
  TEleicaoAPIVotacaoController.Registry;
  TEleicaoComprovanteAPIController.Registry;
  TEleicaoAdminAPIController.Registry;
  TEleicaoResultadoPublicoAPIController.Registry;
  TEleicaoMembroFotoAPIController.Registry;
  TEleicaoRelatorioAPIController.Registry;

  //Rota API
  TEleicaoAPIPublicController.Registry;
end;

end.
