unit ContratoFiscalizacao.Service;

interface

uses
  ContratoFiscalizacao.Model;

type
  TContratoFiscalizacaoService = class
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoFiscalizacaoLista; static;

    class function Cadastrar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ADados: TContratoFiscalizacaoCadastro
    ): TContratoFiscalizacaoLista; static;

    class function AtualizarSituacao(
      const AIdInstituicao, AIdUsuario, AIdContrato, AIdFiscalizacao: Int64;
      const ASituacao, AProvidencia: string
    ): TContratoFiscalizacaoLista; static;
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
  Contrato.Model,
  Contrato.DAO,
  ContratoFiscalizacao.DAO;

class function TContratoFiscalizacaoService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoFiscalizacaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.visualizar');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');
    finally
      Contrato.Free;
    end;
    Result := TContratoFiscalizacaoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
  finally
    Conn.Free;
  end;
end;

class function TContratoFiscalizacaoService.Cadastrar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ADados: TContratoFiscalizacaoCadastro
): TContratoFiscalizacaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
  Situacao: string;
  Dados: TContratoFiscalizacaoCadastro;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.fiscalizacao.gerenciar');

  if ADados.DataOcorrencia<=0 then TAppErrors.RaiseBadRequest('Data da ocorrência não informada.');
  if Trim(ADados.Tipo).IsEmpty then TAppErrors.RaiseBadRequest('Tipo da ocorrência não informado.');
  if Trim(ADados.Descricao).IsEmpty then TAppErrors.RaiseBadRequest('Descrição da ocorrência não informada.');

  Situacao := UpperCase(Trim(ADados.Situacao));
  if Situacao.IsEmpty then Situacao := 'ABERTA';
  if not MatchText(Situacao,['ABERTA','EM_TRATAMENTO','RESOLVIDA','CANCELADA']) then TAppErrors.RaiseBadRequest('Situação da fiscalização inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');

      Conn.StartTransaction;
      try
        Dados := ADados;
        Dados.Situacao := Situacao;
        TContratoFiscalizacaoDAO.Inserir(Conn,AIdInstituicao,AIdContrato,AIdUsuario,Dados);
        TContratoDAO.InserirHistorico(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'FISCALIZACAO_REGISTRADA','Ocorrência de fiscalização registrada.');
        Result := TContratoFiscalizacaoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
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

class function TContratoFiscalizacaoService.AtualizarSituacao(
  const AIdInstituicao, AIdUsuario, AIdContrato, AIdFiscalizacao: Int64;
  const ASituacao, AProvidencia: string
): TContratoFiscalizacaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.fiscalizacao.gerenciar');
  Situacao := UpperCase(Trim(ASituacao));
  if not MatchText(Situacao,['ABERTA','EM_TRATAMENTO','RESOLVIDA','CANCELADA']) then TAppErrors.RaiseBadRequest('Situação da fiscalização inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      TContratoFiscalizacaoDAO.AtualizarSituacao(Conn,AIdInstituicao,AIdContrato,AIdFiscalizacao,Situacao,AProvidencia);
      TContratoDAO.InserirHistorico(Conn,AIdInstituicao,AIdContrato,AIdUsuario,'FISCALIZACAO_ATUALIZADA','Situação de fiscalização alterada para '+Situacao+'.');
      Result := TContratoFiscalizacaoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
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
