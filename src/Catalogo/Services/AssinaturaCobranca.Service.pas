unit AssinaturaCobranca.Service;

interface

uses
  AssinaturaCobranca.Model,
  System.Generics.Collections;

type
  TAssinaturaCobrancaService = class
  public
    class function Listar(const AIdEmpresa: Int64;const AIdAssinatura: Int64 = 0;const APesquisa: string = ''): TObjectList<TAssinaturaCobrancaModel>; static;
    class function Buscar(const AIdEmpresa: Int64; const AIdCobranca: Int64): TAssinaturaCobrancaModel; static;
    class function Inserir(const AIdEmpresa: Int64;const ACobranca: TAssinaturaCobrancaModel): Int64; static;
    class procedure Atualizar(const AIdEmpresa: Int64;const AIdCobranca: Int64;const ACobranca: TAssinaturaCobrancaModel); static;
    class procedure Excluir(const AIdEmpresa: Int64;const AIdCobranca: Int64); static;
    class procedure MarcarComoPaga(const AIdEmpresa: Int64;const AIdCobranca: Int64); static;
    class procedure MarcarComoVencida(const AIdEmpresa: Int64;const AIdCobranca: Int64); static;
    class procedure Cancelar(const AIdEmpresa: Int64;const AIdCobranca: Int64); static;
    class procedure Reabrir(const AIdEmpresa: Int64;const AIdCobranca: Int64); static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  APP.Errors,
  Assinatura.DAO,
  Assinatura.Model,
  AssinaturaCobranca.DAO,
  System.DateUtils;

function NormalizarSituacaoCobranca(const ASituacao: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(ASituacao));

  if V.IsEmpty then
    V := 'ABERTA';

  if (V <> 'ABERTA') and
     (V <> 'PAGA') and
     (V <> 'VENCIDA') and
     (V <> 'CANCELADA') and
     (V <> 'ESTORNADA') then
    TAppErrors.RaiseBadRequest('Situação da cobrança inválida.');

  Result := V;
end;

procedure NormalizarCobranca(const ACobranca: TAssinaturaCobrancaModel);
begin
  ACobranca.Situacao := NormalizarSituacaoCobranca(ACobranca.Situacao);

  ACobranca.Descricao := Trim(ACobranca.Descricao);
  ACobranca.Referencia := Trim(ACobranca.Referencia);
  ACobranca.FormaPagamento := UpperCase(Trim(ACobranca.FormaPagamento));
  ACobranca.IdTransacao := Trim(ACobranca.IdTransacao);
  ACobranca.LinkPagamento := Trim(ACobranca.LinkPagamento);

  if ACobranca.Valor < 0 then
    ACobranca.Valor := 0;

  if (ACobranca.Situacao = 'PAGA') and (ACobranca.PagoEm <= 0) then
    ACobranca.PagoEm := Now;

  if (ACobranca.Situacao <> 'PAGA') then
    ACobranca.PagoEm := 0;
end;

procedure ValidarCobranca(const ACobranca: TAssinaturaCobrancaModel);
begin
  if ACobranca = nil then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  if ACobranca.IdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if ACobranca.IdAssinatura <= 0 then
    TAppErrors.RaiseBadRequest('Assinatura da cobrança não informada.');

  if ACobranca.Vencimento <= 0 then
    TAppErrors.RaiseBadRequest('Vencimento da cobrança não informado.');

  if ACobranca.Valor < 0 then
    TAppErrors.RaiseBadRequest('Valor da cobrança não pode ser negativo.');
end;

procedure ValidarAssinaturaDaEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64);
var
  Assinatura: TAssinaturaModel;
begin
  Assinatura := TAssinaturaDAO.BuscarPorId(AConn, AIdEmpresa, AIdAssinatura);
  try
    if Assinatura = nil then
      TAppErrors.RaiseNotFound('Assinatura não encontrada para esta empresa.');
  finally
    Assinatura.Free;
  end;
end;

class function TAssinaturaCobrancaService.Listar(const AIdEmpresa: Int64;const AIdAssinatura: Int64 = 0;const APesquisa: string = ''): TObjectList<TAssinaturaCobrancaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaCobrancaDAO.Listar(Conn, AIdEmpresa, AIdAssinatura, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaCobrancaService.Buscar(const AIdEmpresa: Int64; const AIdCobranca: Int64): TAssinaturaCobrancaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaCobrancaDAO.BuscarPorId(Conn, AIdEmpresa, AIdCobranca);

    if Result = nil then
      TAppErrors.RaiseNotFound('Cobrança não encontrada.');
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaCobrancaService.Inserir(const AIdEmpresa: Int64;const ACobranca: TAssinaturaCobrancaModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if ACobranca = nil then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  ACobranca.IdEmpresa := AIdEmpresa;

  NormalizarCobranca(ACobranca);
  ValidarCobranca(ACobranca);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    ValidarAssinaturaDaEmpresa(Conn, AIdEmpresa, ACobranca.IdAssinatura);
    Result := TAssinaturaCobrancaDAO.Inserir(Conn, ACobranca);
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.Atualizar(const AIdEmpresa: Int64;const AIdCobranca: Int64;const ACobranca: TAssinaturaCobrancaModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TAssinaturaCobrancaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  if ACobranca = nil then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  ACobranca.IdEmpresa := AIdEmpresa;
  ACobranca.IdCobranca := AIdCobranca;

  NormalizarCobranca(ACobranca);
  ValidarCobranca(ACobranca);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TAssinaturaCobrancaDAO.BuscarPorId(Conn, AIdEmpresa, AIdCobranca);
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound('Cobrança não encontrada.');

      ValidarAssinaturaDaEmpresa(Conn, AIdEmpresa, ACobranca.IdAssinatura);

      TAssinaturaCobrancaDAO.Atualizar(Conn, ACobranca);
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.Excluir(const AIdEmpresa: Int64;const AIdCobranca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TAssinaturaCobrancaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TAssinaturaCobrancaDAO.BuscarPorId(Conn, AIdEmpresa, AIdCobranca);
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound('Cobrança não encontrada.');

      if Atual.Situacao = 'PAGA' then
        TAppErrors.RaiseBadRequest('Não é possível excluir uma cobrança paga. Estorne ou cancele a cobrança.');

      if not TAssinaturaCobrancaDAO.Excluir(Conn, AIdEmpresa, AIdCobranca) then
        TAppErrors.RaiseBadRequest('Não foi possível excluir a cobrança.');
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.MarcarComoPaga(const AIdEmpresa: Int64;const AIdCobranca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Cobranca: TAssinaturaCobrancaModel;
  Assinatura: TAssinaturaModel;
  BaseVencimento: TDateTime;
  NovoVencimento: TDateTime;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Cobranca := TAssinaturaCobrancaDAO.BuscarPorId(Conn, AIdEmpresa, AIdCobranca);
      try
        if Cobranca = nil then
          TAppErrors.RaiseNotFound('Cobrança não encontrada.');

        if SameText(Cobranca.Situacao, 'PAGA') then
          TAppErrors.RaiseBadRequest('Esta cobrança já está paga.');

        if SameText(Cobranca.Situacao, 'CANCELADA') then
          TAppErrors.RaiseBadRequest('Não é possível pagar uma cobrança cancelada.');

        if SameText(Cobranca.Situacao, 'ESTORNADA') then
          TAppErrors.RaiseBadRequest('Não é possível pagar uma cobrança estornada.');

        Assinatura := TAssinaturaDAO.BuscarPorId(
          Conn,
          AIdEmpresa,
          Cobranca.IdAssinatura
        );
        try
          if Assinatura = nil then
            TAppErrors.RaiseNotFound('Assinatura vinculada à cobrança não encontrada.');

          if SameText(Assinatura.Situacao, 'CANCELADA') then
            TAppErrors.RaiseBadRequest('Não é possível pagar cobrança de uma assinatura cancelada.');

          BaseVencimento := Cobranca.Vencimento;

          if BaseVencimento <= 0 then
            BaseVencimento := Date;

          if SameText(Assinatura.Recorrencia, 'ANUAL') then
            NovoVencimento := IncYear(BaseVencimento, 1)
          else
            NovoVencimento := IncMonth(BaseVencimento, 1);

          // Marca cobrança como paga
          TAssinaturaCobrancaDAO.AlterarSituacao(
            Conn,
            AIdEmpresa,
            AIdCobranca,
            'PAGA',
            Now
          );

          // Atualiza assinatura
          Assinatura.Situacao := 'ATIVA';
          Assinatura.ProximoVencimento := NovoVencimento;
          Assinatura.CanceladoEm := 0;
          Assinatura.TerminaEm := 0;

          TAssinaturaDAO.Atualizar(Conn, Assinatura);
        finally
          Assinatura.Free;
        end;
      finally
        Cobranca.Free;
      end;

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.MarcarComoVencida(const AIdEmpresa: Int64;const AIdCobranca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaCobrancaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdCobranca, 'VENCIDA', 0);
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.Cancelar(const AIdEmpresa: Int64;const AIdCobranca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaCobrancaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdCobranca, 'CANCELADA', 0);
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaCobrancaService.Reabrir(const AIdEmpresa: Int64;const AIdCobranca: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCobranca <= 0 then
    TAppErrors.RaiseBadRequest('Cobrança não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaCobrancaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdCobranca, 'ABERTA', 0);
  finally
    Conn.Free;
  end;
end;

end.
