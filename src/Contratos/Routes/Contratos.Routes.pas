unit Contratos.Routes;

interface

type
  TContratosRoutes = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Contrato.Controller;

class procedure TContratosRoutes.Registry;
begin
  TContratoController.Registry;
end;

end.
