unit EleicaoListaPublicaAPI.Controller;

interface

type
  TEleicaoListaPublicaAPIController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Response,
  App.Errors,
  EleicaoListaPublicaAPI.Service;

class procedure TEleicaoListaPublicaAPIController.Registry;
begin
  THorse.Get(
    '/api/v1/public/processos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Dados: TJSONArray;
    begin
      try
        Dados := TEleicaoListaPublicaAPIService.ListarProcessosPublicos;
        TAppResponse.Ok(Res, Dados, '');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
