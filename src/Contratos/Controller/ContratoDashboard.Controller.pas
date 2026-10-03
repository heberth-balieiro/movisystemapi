unit ContratoDashboard.Controller;

interface

type
  TContratoDashboardController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  ContratoDashboard.DAO,
  ContratoDashboard.Service;

class procedure TContratoDashboardController.Registry;
begin
  THorse.Get(
    '/v1/contratos/instituicao/dashboard',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TContratoDashboardDados;
      Json: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then Exit;

        if (Claims.IdInstituicao<=0) or (Claims.IdUsuarioInstituicao<=0) then
        begin
          TAppResponse.Forbidden(Res,'Token sem contexto válido de instituição e usuário.');
          Exit;
        end;

        Dados:=TContratoDashboardService.Buscar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );

        Json:=TJSONObject.Create;
        Json.AddPair('vigentes',TJSONNumber.Create(Dados.Vigentes));
        Json.AddPair('a_vencer_30_dias',TJSONNumber.Create(Dados.AVencer30Dias));
        Json.AddPair('vencidos',TJSONNumber.Create(Dados.Vencidos));
        Json.AddPair('fiscalizacoes_pendentes',TJSONNumber.Create(Dados.FiscalizacoesPendentes));
        Json.AddPair('valor_contratado',TJSONNumber.Create(Dados.ValorContratado));
        Json.AddPair('valor_realizado',TJSONNumber.Create(Dados.ValorRealizado));
        Json.AddPair('saldo_projetado',TJSONNumber.Create(Dados.SaldoProjetado));

        TAppResponse.Ok(Res,Json,'Dashboard de contratos carregado com sucesso.');
      except
        on E: Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
