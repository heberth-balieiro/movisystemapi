unit ContratoAditivo.Service;

interface

uses
  ContratoAditivo.Model;

type
  TContratoAditivoService = class
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoAditivoLista; static;

    class function Cadastrar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ADados: TContratoAditivoCadastro
    ): TContratoAditivoLista; static;
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
  ContratoAditivo.DAO,
  ContratoProjecao.DAO;

class function TContratoAditivoService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoAditivoLista;
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
    Result := TContratoAditivoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
  finally
    Conn.Free;
  end;
end;

class function TContratoAditivoService.Cadastrar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ADados: TContratoAditivoCadastro
): TContratoAditivoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
  DadosContrato: TContratoCadastro;
  NovoValor: Double;
begin
  Result := nil;
  TInstituicaoPermissaoService.Exigir(AIdInstituicao,AIdUsuario,'contrato.aditivo.gerenciar');

  if Trim(ADados.Numero).IsEmpty then TAppErrors.RaiseBadRequest('Número do aditivo não informado.');
  if not MatchText(UpperCase(Trim(ADados.Tipo)),['PRAZO','VALOR','PRAZO_VALOR','OUTRO']) then TAppErrors.RaiseBadRequest('Tipo de aditivo inválido.');
  if (ADados.ValorAcrescimo<0) or (ADados.ValorSupressao<0) then TAppErrors.RaiseBadRequest('Valores do aditivo não podem ser negativos.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then TAppErrors.RaiseBadRequest('Contrato não encontrado.');

      NovoValor := Contrato.ValorAtual + ADados.ValorAcrescimo - ADados.ValorSupressao;
      if NovoValor < 0 then TAppErrors.RaiseBadRequest('O aditivo resultaria em valor contratual negativo.');

      DadosContrato := Default(TContratoCadastro);
      DadosContrato.DocumentoContratado := Contrato.DocumentoContratado;
      DadosContrato.NomeContratado := Contrato.NomeContratado;
      DadosContrato.Numero := Contrato.Numero;
      DadosContrato.NumeroExterno := Contrato.NumeroExterno;
      DadosContrato.TipoGestao := Contrato.TipoGestao;
      DadosContrato.Tipo := Contrato.Tipo;
      DadosContrato.Titulo := Contrato.Titulo;
      DadosContrato.Objeto := Contrato.Objeto;
      DadosContrato.NumeroProcesso := Contrato.NumeroProcesso;
      DadosContrato.AnoProcesso := Contrato.AnoProcesso;
      DadosContrato.OrigemContratacao := Contrato.OrigemContratacao;
      DadosContrato.Modalidade := Contrato.Modalidade;
      DadosContrato.NumeroLicitacao := Contrato.NumeroLicitacao;
      DadosContrato.IdentificadorPncp := Contrato.IdentificadorPncp;
      DadosContrato.UrlPncp := Contrato.UrlPncp;
      DadosContrato.DataAssinatura := Contrato.DataAssinatura;
      DadosContrato.DataInicio := Contrato.DataInicio;
      DadosContrato.DataFim := Contrato.DataFim;
      if ADados.NovaDataFim > 0 then DadosContrato.DataFim := ADados.NovaDataFim;
      if DadosContrato.DataFim < DadosContrato.DataInicio then TAppErrors.RaiseBadRequest('Nova vigência inválida.');
      DadosContrato.ValorInicial := Contrato.ValorInicial;
      DadosContrato.ValorAtual := NovoValor;
      DadosContrato.Periodicidade := Contrato.Periodicidade;
      DadosContrato.UnidadeResponsavel := Contrato.UnidadeResponsavel;
      DadosContrato.Observacao := Contrato.Observacao;
      DadosContrato.Situacao := Contrato.Situacao;

      Conn.StartTransaction;
      try
        TContratoAditivoDAO.Inserir(Conn,AIdInstituicao,AIdContrato,AIdUsuario,ADados);

        TContratoDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          Contrato.IdEntidade,
          DadosContrato
        );

        TContratoProjecaoDAO.GerarAutomaticas(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          DadosContrato.DataInicio,
          DadosContrato.DataFim,
          DadosContrato.ValorAtual,
          True,
          'ADITIVO'
        );

        TContratoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          'ADITIVO_INCLUIDO',
          'Aditivo '+Trim(ADados.Numero)+' incluído no contrato.'
        );

        Result := TContratoAditivoDAO.Listar(Conn,AIdInstituicao,AIdContrato);
        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      Contrato.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
