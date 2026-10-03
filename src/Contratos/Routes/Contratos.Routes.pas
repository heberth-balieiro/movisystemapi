unit Contratos.Routes;

interface

type
  TContratosRoutes = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Contrato.Controller,
  ContratoProjecao.Controller,
  ContratoResponsavel.Controller,
  ContratoDashboard.Controller,
  ContratoAditivo.Controller,
  ContratoFiscalizacao.Controller;

class procedure TContratosRoutes.Registry;
begin
  TContratoController.Registry;
  TContratoProjecaoController.Registry;
  TContratoResponsavelController.Registry;
  TContratoDashboardController.Registry;
  TContratoAditivoController.Registry;
  TContratoFiscalizacaoController.Registry;
end;

end.
