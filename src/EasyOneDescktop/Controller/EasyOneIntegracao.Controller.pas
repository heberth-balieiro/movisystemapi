unit EasyOneIntegracao.Controller;

interface

type
  TEasyOneIntegracaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  APP.Errors,
  App.Response,
  EasyOneIntegracao.Service;

{ TEasyOneIntegracaoController }

class procedure TEasyOneIntegracaoController.Registry;
begin
  THorse.Get('/api/v1/integracao/easyone/autenticar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID    : string;
      APIKey  : string;
      Contexto: TEasyOneIntegracaoContexto;
      Retorno : TJSONObject;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID, APIKey);

        Retorno := TJSONObject.Create;
        Retorno.AddPair('autenticado', 'S');
        Retorno.AddPair('id_empresa', TJSONNumber.Create(Contexto.IdEmpresa));
        Retorno.AddPair('uuid', Contexto.UUID);

        TAppResponse.OK(Res, Retorno, 'Integração autenticada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
