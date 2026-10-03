unit ContratoResponsavel.Service;

interface

uses
  ContratoResponsavel.Model;

type
  TContratoResponsavelService = class
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoResponsavelLista; static;

    class function Cadastrar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ADados: TContratoResponsavelCadastro
    ): TContratoResponsavelLista; static;

    class function Inativar(
      const AIdInstituicao, AIdUsuario, AIdContrato, AIdResponsavel: Int64
    ): TContratoResponsavelLista; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  Contrato.DAO,
  Contrato.Model,
  ContratoResponsavel.DAO;

class function TContratoResponsavelService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoResponsavelLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.visualizar');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
    finally
      Contrato.Free;
    end;
    Result := TContratoResponsavelDAO.Listar(Conn,AIdInstituicao,AIdContrato);
  finally
    Conn.Free;
  end;
end;

class function TContratoResponsavelService.Cadastrar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ADados: TContratoResponsavelCadastro
): TContratoResponsavelLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
  Dados: TContratoResponsavelCadastro;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.editar');
  Dados := ADados;
  Dados.Funcao := UpperCase(Trim(Dados.Funcao));
  if Trim(Dados.Nome).IsEmpty then TAppErrors.RaiseBadRequest('Nome do responsável não informado.');
  if not MatchText(Dados.Funcao,['GESTOR','FISCAL','SUPLENTE']) then TAppErrors.RaiseBadRequest('Função inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
      Conn.StartTransaction;
      try
        TContratoResponsavelDAO.Inserir(Conn,AIdInstituicao,AIdContrato,Dados);
        TContratoDAO.InserirHistorico(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'RESPONSAVEL_INCLUIDO','Responsável incluído: '+Dados.Nome+' ('+Dados.Funcao+').');
        Result := TContratoResponsavelDAO.Listar(Conn,AIdInstituicao,AIdContrato);
        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free; Result := nil; raise;
      end;
    finally
      Contrato.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TContratoResponsavelService.Inativar(
  const AIdInstituicao, AIdUsuario, AIdContrato, AIdResponsavel: Int64
): TContratoResponsavelLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.editar');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      TContratoResponsavelDAO.Inativar(Conn,AIdInstituicao,AIdContrato,AIdResponsavel);
      TContratoDAO.InserirHistorico(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'RESPONSAVEL_INATIVADO','Responsável do contrato inativado.');
      Result := TContratoResponsavelDAO.Listar(Conn,AIdInstituicao,AIdContrato);
      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      Result.Free; Result := nil; raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
