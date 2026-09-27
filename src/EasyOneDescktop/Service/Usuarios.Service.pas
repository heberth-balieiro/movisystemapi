unit Usuarios.Service;

interface

uses
  Uni,
  System.SysUtils,
  Usuarios.Model,
  Usuarios.DAO,
  App.Config,
  Database.Connection,
  APP.Errors;

type
  TCadastroUsuariosResult = record
    IdUsuarios: Integer;
  end;

  TUsuariosService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure ValidarCadastroUsuario(const ADoc: TUsuariosModel); static;
  public
    class function InserirUsuario(const AEmpresaId: Integer; const ADoc: TUsuariosModel): TCadastroUsuariosResult; static;
  end;

implementation

{ TUsuariosService }

class function TUsuariosService.InserirUsuario(const AEmpresaId: Integer; const ADoc: TUsuariosModel): TCadastroUsuariosResult;
var
  Conn  : TUniConnection;
  Config: TAppApiConfig;
begin
  Result.IdUsuarios := 0;

  if AEmpresaId <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada.');

  ValidarCadastroUsuario(ADoc);

  ADoc.ativo := NormalizarSN(ADoc.ativo,'S');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;
    try
      // Localiza o ID interno da pessoa através do ID do associado do EasyOne
      if ADoc.id_socio > 0 then
      begin
        ADoc.pessoa_id  := TUsuariosDao.BuscarPessoaId(Conn,AEmpresaId, ADoc.id_socio);
        if ADoc.pessoa_id <= 0 then
        TAppErrors.RaiseBadRequest('[API] Associado não encontrado para a empresa informada.');
      end;

      if TUsuariosDao.ExisteUsuario(Conn, AEmpresaId, ADoc.pessoa_id) then
        TUsuariosDao.Atualizar(Conn,AEmpresaId,ADoc)
      else
        Result.IdUsuarios := TUsuariosDao.Inserir(Conn,AEmpresaId,ADoc);

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TUsuariosService.NormalizarSN(const AValor, APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'N';

  Result := Valor;
end;

class procedure TUsuariosService.ValidarCadastroUsuario(const ADoc: TUsuariosModel);
begin
  if ADoc = nil then
    TAppErrors.RaiseBadRequest('[API] Dados do usuário/associado não informados.');

  //if ADoc.id_socio <= 0 then
  //  TAppErrors.RaiseBadRequest('ID do associado não informado.');

  if Trim(ADoc.nome).IsEmpty then
    TAppErrors.RaiseBadRequest('[API] Nome do usuário/associado não informado.');

  if Trim(ADoc.ativo).IsEmpty then
    TAppErrors.RaiseBadRequest('[API] Campo ativo não informado.');
end;

end.
