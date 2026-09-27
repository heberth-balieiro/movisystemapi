unit Dashboard.Controller;

interface

type
  TDashboardController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  APP.Classes,
  App.Token,
  Dashboard.Service,
  Assinatura.Service;


class procedure TDashboardController.Registry;
begin
  THorse.Get('/v1/dashboard/resumo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        TAssinaturaService.ValidarAcessoPainel(Claims.IdEmpresa);

        Dados := TDashboardService.BuscarResumo(Claims.IdEmpresa);

        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
