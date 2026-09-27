unit EasyOne.Routes;

interface

type
  TEasyOneRoutes = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  //Adicionar rotas futuras
  Emp.Controller,
  Associado.Controller,
  Usuarios.Controller,
  EasyOneIntegracao.Controller;

{ TEasyOneRoutes }

class procedure TEasyOneRoutes.Registry;
begin
  TEmpresasController.Registry;
  TAssociadoController.Registry;
  TUsuariosController.Registry;
  TEasyOneIntegracaoController.Registry;
end;

end.
