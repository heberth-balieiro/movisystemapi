unit ContratoProjecao.Service;

interface

uses
  ContratoProjecao.Model;

type
  TContratoProjecaoService = class
  public
    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoProjecaoLista; static;

    class function Recalcular(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoProjecaoLista; static;

    class function AjustarManual(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ACompetencia: TDateTime;
      const AValorPrevisto, AValorRealizado: Double;
      const AObservacao: string
    ): TContratoProjecaoLista; static;
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
  ContratoProjecao.DAO;

class function TContratoProjecaoService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoProjecaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuario,
    'contrato.projecao.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
    try
      if Contrato = nil then
        TAppErrors.RaiseBadRequest('Contrato não encontrado.');
    finally
      Contrato.Free;
    end;

    Result := TContratoProjecaoDAO.Listar(
      Conn,
      AIdInstituicao,
      AIdContrato
    );
  finally
    Conn.Free;
  end;
end;

class function TContratoProjecaoService.Recalcular(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoProjecaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuario,
    'contrato.projecao.editar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
    try
      if Contrato = nil then
        TAppErrors.RaiseBadRequest('Contrato não encontrado.');

      Conn.StartTransaction;
      try
        TContratoProjecaoDAO.GerarAutomaticas(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          Contrato.DataInicio,
          Contrato.DataFim,
          Contrato.ValorAtual,
          True
        );

        TContratoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          'PROJECAO_RECALCULADA',
          'Projeção financeira automática recalculada.'
        );

        Result := TContratoProjecaoDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdContrato
        );

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

class function TContratoProjecaoService.AjustarManual(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ACompetencia: TDateTime;
  const AValorPrevisto, AValorRealizado: Double;
  const AObservacao: string
): TContratoProjecaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  Result := nil;

  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,
    AIdUsuario,
    'contrato.projecao.editar'
  );

  if ACompetencia <= 0 then
    TAppErrors.RaiseBadRequest('Competência inválida.');

  if (AValorPrevisto < 0) or (AValorRealizado < 0) then
    TAppErrors.RaiseBadRequest('Valores de projeção não podem ser negativos.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn, AIdInstituicao, AIdContrato);
    try
      if Contrato = nil then
        TAppErrors.RaiseBadRequest('Contrato não encontrado.');

      Conn.StartTransaction;
      try
        TContratoProjecaoDAO.AtualizarManual(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          ACompetencia,
          AValorPrevisto,
          AValorRealizado,
          AObservacao
        );

        TContratoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          'PROJECAO_AJUSTADA',
          'Projeção financeira ajustada manualmente.'
        );

        Result := TContratoProjecaoDAO.Listar(
          Conn,
          AIdInstituicao,
          AIdContrato
        );

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
