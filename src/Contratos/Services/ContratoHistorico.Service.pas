unit ContratoHistorico.Service;

interface

uses
  ContratoHistorico.Model;

type
  TContratoHistoricoService = class
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoHistoricoLista; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  Contrato.Model,
  Contrato.DAO,
  ContratoHistorico.DAO;

class function TContratoHistoricoService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoHistoricoLista;
var
  Config:TAppApiConfig;
  Conn:TUniConnection;
  Contrato:TContratoItem;
begin
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.visualizar');
  Config:=TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn:=TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato:=TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
    finally
      Contrato.Free;
    end;
    Result:=TContratoHistoricoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
  finally
    Conn.Free;
  end;
end;

end.
