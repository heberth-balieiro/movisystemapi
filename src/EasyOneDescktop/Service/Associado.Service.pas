unit Associado.Service;

interface

Uses Uni,
  System.SysUtils,
  Associado.Model,
  Associado.DAO,
  App.Config,
  Database.Connection,
  APP.Errors,
  App.Classes;

type
  TCadastroAssociadoResult = record
    IdAssociado           : Int64;
end;

Type
TAssociadoService = Class
  private
    class procedure ValidarCadastroAssociado(const ADoc: TAssociadoModel); static;
  public
    class function InserirAssociado(const AEmpresaId:Integer; const ADoc: TAssociadoModel): TCadastroAssociadoResult; static;
End;

implementation

{ TAssociadoService }

class function TAssociadoService.InserirAssociado(const AEmpresaId:Integer; const ADoc: TAssociadoModel): TCadastroAssociadoResult;
var
  Conn      : TUniConnection;
  Config    : TAppApiConfig;
begin
  Result.IdAssociado := 0;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroAssociado(Adoc);
  Config      := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn        := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      if TAssociadoDAO.ExisteAssociado(Conn,AEmpresaId,ADoc.id_socio) then
        TAssociadoDAO.Atualizar(Conn,AEmpresaId,ADoc)
      else
        Result.IdAssociado := TAssociadoDAO.Inserir(Conn,AEmpresaId,ADoc);

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssociadoService.ValidarCadastroAssociado(const ADoc: TAssociadoModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('Dados do associado não informado.');

  if ADoc.nome.IsEmpty then
    TAppErrors.RaiseBadRequest('Nome do associado não informado.');

  if ADoc.id_socio <=0 then
    TAppErrors.RaiseBadRequest('ID associado não informado.');

  if ADoc.ativo.IsEmpty then
    TAppErrors.RaiseBadRequest('Campo ativo não informado.');

  Adoc.ativo          := TAppClasses.NormalizarSN(Adoc.ativo,'N');
  ADoc.bloqueado := TAppClasses.NormalizarSN(ADoc.bloqueado,'N');
end;

end.
