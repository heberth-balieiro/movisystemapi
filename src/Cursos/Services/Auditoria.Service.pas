unit Auditoria.Service;

interface

uses
  Horse,
  App.JWT;

type
  TAuditoriaService = class
  public
    class procedure TryRegistrarRequest(
      const AReq: THorseRequest;
      const AClaims: TJWTClaims;
      const AAcao,
            AEntidade,
            ARegistroId,
            AMensagem: string;
      const ASucesso: Boolean
    ); static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.RequestInfo,
  Database.Connection,
  Auditoria.DAO;

class procedure TAuditoriaService.TryRegistrarRequest(
  const AReq: THorseRequest;
  const AClaims: TJWTClaims;
  const AAcao,
        AEntidade,
        ARegistroId,
        AMensagem: string;
  const ASucesso: Boolean
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Registro: TAuditoriaRegistro;
begin
  try
    Registro := Default(TAuditoriaRegistro);

    Registro.IdInstituicao := AClaims.IdInstituicao;
    Registro.IdUsuario := AClaims.UserId;
    Registro.IdUsuarioInstituicao := AClaims.IdUsuarioInstituicao;
    Registro.Acao := AAcao;
    Registro.Entidade := AEntidade;
    Registro.RegistroId := ARegistroId;
    Registro.MetodoHttp := AReq.RawWebRequest.Method;
    Registro.Rota := AReq.RawWebRequest.PathInfo;
    Registro.IP := TAppRequestInfo.GetIP(AReq);
    Registro.UserAgent := TAppRequestInfo.GetUserAgent(AReq);
    Registro.Sucesso := ASucesso;
    Registro.Mensagem := AMensagem;

    // LGPD: o middleware nunca persiste body, senha, token, CPF ou e-mail.
    Registro.DadosAnteriores := '';
    Registro.DadosNovos := '';

    Config :=
      TAppConfig.Carregar(
        ExtractFilePath(ParamStr(0)) + 'Config.ini'
      );

    Conn :=
      TDatabaseConnection.NewConnection(
        Config.Database
      );
    try
      TAuditoriaDAO.Inserir(
        Conn,
        Registro
      );
    finally
      Conn.Free;
    end;
  except
    // Auditoria é best-effort: falha do log não pode desfazer uma operação
    // que já foi concluída no banco. A revisão operacional deve monitorar isso.
  end;
end;

end.
