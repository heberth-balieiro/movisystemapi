unit Assinatura.Service;

interface

uses
  Uni,
  Assinatura.Model,
  System.Generics.Collections;

type
  TProcessarVencimentosResult = record
    CobrancasVencidas: Integer;
    AssinaturasVencidas: Integer;
    TrialsVencidos: Integer;
  end;

type
  TProcessarBloqueiosResult = record
    AssinaturasBloqueadas: Integer;
    DiasAposVencimento: Integer;
  end;

type
  TProcessarRotinaAssinaturaResult = record
    CobrancasVencidas: Integer;
    AssinaturasVencidas: Integer;
    TrialsVencidos: Integer;
    AssinaturasBloqueadas: Integer;
    DiasAposVencimento: Integer;
  end;

type
  TProcessarRotinaGlobalAssinaturaResult = record
    EmpresasProcessadas: Integer;
    CobrancasVencidas: Integer;
    AssinaturasVencidas: Integer;
    TrialsVencidos: Integer;
    AssinaturasBloqueadas: Integer;
    DiasAposVencimento: Integer;
  end;

type
  TAssinaturaStatusResult = record
    IdAssinatura: Int64;
    IdPlano: Int64;
    Recorrencia: string;
    Situacao: string;
    SituacaoAtual: string;
    Valor: Currency;

    IniciadoEm: TDateTime;
    TrialTerminaEm: TDateTime;
    ProximoVencimento: TDateTime;

    PodeAcessar: Boolean;
    Bloqueado: Boolean;
    EmTrial: Boolean;
    ExibirAlerta: Boolean;

    DiasRestantesTrial: Integer;
    DiasParaVencimento: Integer;

    Mensagem: string;
  end;

type
  TAssinaturaService = class
  public
    class function Listar(const AIdEmpresa: Int64;const APesquisa: string = ''): TObjectList<TAssinaturaModel>; static;
    class function Buscar(const AIdEmpresa: Int64;const AIdAssinatura: Int64): TAssinaturaModel; static;
    class function BuscarAtualEmpresa(const AIdEmpresa: Int64): TAssinaturaModel; static;
    class function Inserir(const AIdEmpresa: Int64;const AAssinatura: TAssinaturaModel): Int64; static;
    class procedure Atualizar(const AIdEmpresa: Int64; const AIdAssinatura: Int64;const AAssinatura: TAssinaturaModel); static;
    class procedure Excluir(const AIdEmpresa: Int64;const AIdAssinatura: Int64); static;
    class procedure Cancelar(const AIdEmpresa: Int64;const AIdAssinatura: Int64); static;
    class procedure Bloquear(const AIdEmpresa: Int64;const AIdAssinatura: Int64); static;
    class procedure Ativar(const AIdEmpresa: Int64;const AIdAssinatura: Int64); static;
    class function CriarTrialEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdPlano: Int64;const ARecorrencia: string = 'MENSAL'): Int64; static;

    class function ConfirmarContratacao(const AIdEmpresa: Int64;const AIdAssinatura: Int64): Int64; static;
    class function ProcessarVencimentos(const AIdEmpresa: Int64): TProcessarVencimentosResult; static;
    class function ProcessarBloqueios(const AIdEmpresa: Int64;const ADiasAposVencimento: Integer = 3): TProcessarBloqueiosResult; static;

    class function ProcessarRotinaAssinaturas(const AIdEmpresa: Int64;const ADiasAposVencimento: Integer = 3): TProcessarRotinaAssinaturaResult; static;

    class procedure ValidarAcessoPainel(const AIdEmpresa: Int64); static;
    class procedure ValidarAcessoCatalogoPublico(const AIdEmpresa: Int64); static;

    class function ProcessarRotinaAssinaturasGlobal(const ADiasAposVencimento: Integer = 3): TProcessarRotinaGlobalAssinaturaResult; static;

    class function ConsultarStatus(const AIdEmpresa: Int64): TAssinaturaStatusResult; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  App.Config,
  Database.Connection,
  APP.Errors,
  Assinatura.DAO,
  Plano.DAO,
  Plano.Model,
  AssinaturaCobranca.DAO,
  AssinaturaCobranca.Model;

function NormalizarRecorrencia(const ARecorrencia: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(ARecorrencia));

  if V.IsEmpty then
    V := 'MENSAL';

  if (V <> 'MENSAL') and (V <> 'ANUAL') then
    TAppErrors.RaiseBadRequest('Recorrência da assinatura inválida. Use MENSAL ou ANUAL.');

  Result := V;
end;

function NormalizarSituacaoAssinatura(const ASituacao: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(ASituacao));

  if V.IsEmpty then
    V := 'TRIAL';

  if (V <> 'TRIAL') and
     (V <> 'ATIVA') and
     (V <> 'INATIVA') and
     (V <> 'VENCIDA') and
     (V <> 'CANCELADA') and
     (V <> 'BLOQUEADA') then
    TAppErrors.RaiseBadRequest('Situação da assinatura inválida.');

  Result := V;
end;

procedure NormalizarAssinatura(const AAssinatura: TAssinaturaModel);
begin
  AAssinatura.Recorrencia := NormalizarRecorrencia(AAssinatura.Recorrencia);
  AAssinatura.Situacao := NormalizarSituacaoAssinatura(AAssinatura.Situacao);
  AAssinatura.Observacao := Trim(AAssinatura.Observacao);

  if AAssinatura.IniciadoEm <= 0 then
    AAssinatura.IniciadoEm := Now;

  if (AAssinatura.Situacao = 'TRIAL') and (AAssinatura.TrialTerminaEm <= 0) then
    AAssinatura.TrialTerminaEm := IncDay(Date, 7);

  if AAssinatura.ProximoVencimento <= 0 then
  begin
    if AAssinatura.TrialTerminaEm > 0 then
      AAssinatura.ProximoVencimento := AAssinatura.TrialTerminaEm
    else if AAssinatura.Recorrencia = 'ANUAL' then
      AAssinatura.ProximoVencimento := IncYear(Date, 1)
    else
      AAssinatura.ProximoVencimento := IncMonth(Date, 1);
  end;

  if AAssinatura.Valor < 0 then
    AAssinatura.Valor := 0;
end;

procedure ValidarAssinatura(const AAssinatura: TAssinaturaModel);
begin
  if AAssinatura = nil then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  if AAssinatura.IdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AAssinatura.IdPlano <= 0 then
    TAppErrors.RaiseBadRequest('Plano da assinatura não informado.');

  if AAssinatura.Valor < 0 then
    TAppErrors.RaiseBadRequest('Valor da assinatura não pode ser negativo.');
end;

function DiasAteData(const AData: TDateTime): Integer;
begin
  Result := 0;
  if AData <= 0 then
    Exit;
  Result := Trunc(DateOf(AData) - Date);
end;

class function TAssinaturaService.Listar(const AIdEmpresa: Int64;const APesquisa: string): TObjectList<TAssinaturaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaDAO.Listar(Conn, AIdEmpresa, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.Buscar(const AIdEmpresa: Int64;const AIdAssinatura: Int64): TAssinaturaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAssinatura <= 0 then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaDAO.BuscarPorId(Conn, AIdEmpresa, AIdAssinatura);

    if Result = nil then
      TAppErrors.RaiseNotFound('Assinatura não encontrada.');
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.BuscarAtualEmpresa(const AIdEmpresa: Int64): TAssinaturaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaDAO.BuscarAtualEmpresa(Conn, AIdEmpresa);

    if Result = nil then
      TAppErrors.RaiseNotFound('Nenhuma assinatura encontrada para a empresa.');
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.Inserir(const AIdEmpresa: Int64;const AAssinatura: TAssinaturaModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AAssinatura = nil then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  AAssinatura.IdEmpresa := AIdEmpresa;

  NormalizarAssinatura(AAssinatura);
  ValidarAssinatura(AAssinatura);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TAssinaturaDAO.Inserir(Conn, AAssinatura);
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaService.Atualizar(const AIdEmpresa: Int64;const AIdAssinatura: Int64;const AAssinatura: TAssinaturaModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TAssinaturaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAssinatura <= 0 then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  if AAssinatura = nil then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  AAssinatura.IdEmpresa := AIdEmpresa;
  AAssinatura.IdAssinatura := AIdAssinatura;

  NormalizarAssinatura(AAssinatura);
  ValidarAssinatura(AAssinatura);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TAssinaturaDAO.BuscarPorId(Conn, AIdEmpresa, AIdAssinatura);
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound('Assinatura não encontrada.');

      TAssinaturaDAO.Atualizar(Conn, AAssinatura);
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaService.Excluir(const AIdEmpresa: Int64;const AIdAssinatura: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TAssinaturaModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdAssinatura <= 0 then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TAssinaturaDAO.BuscarPorId(Conn, AIdEmpresa, AIdAssinatura);
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound('Assinatura não encontrada.');

      if TAssinaturaDAO.PossuiCobranca(Conn, AIdEmpresa, AIdAssinatura) then
        TAppErrors.RaiseBadRequest(
          'Não é possível excluir esta assinatura, pois ela possui cobranças vinculadas. ' +
          'Cancele ou inative a assinatura.'
        );

      if not TAssinaturaDAO.Excluir(Conn, AIdEmpresa, AIdAssinatura) then
        TAppErrors.RaiseBadRequest('Não foi possível excluir a assinatura.');
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaService.Cancelar(const AIdEmpresa: Int64;const AIdAssinatura: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdAssinatura, 'CANCELADA');
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.CriarTrialEmpresa(const AConn: TUniConnection;
  const AIdEmpresa, AIdPlano: Int64; const ARecorrencia: string): Int64;
var
  Plano: TPlanoModel;
  AssinaturaAtual: TAssinaturaModel;
  Assinatura: TAssinaturaModel;
  Recorrencia: string;
  TrialTerminaEm: TDateTime;
  ValorPlano: Currency;
begin
  Result := 0;
  if AConn = nil then
    TAppErrors.RaiseBadRequest('Conexão não informada para criar assinatura.');
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não informada para criar assinatura.');
  if AIdPlano <= 0 then
    TAppErrors.RaiseBadRequest('Plano não informado para criar assinatura.');
  // Evita duplicar assinatura caso a rotina seja chamada novamente
  AssinaturaAtual := TAssinaturaDAO.BuscarAtualEmpresa(AConn, AIdEmpresa);
  try
    if AssinaturaAtual <> nil then
      Exit(AssinaturaAtual.IdAssinatura);
  finally
    AssinaturaAtual.Free;
  end;
  Recorrencia := NormalizarRecorrencia(ARecorrencia);
  // Ajuste o nome da função abaixo se no seu PlanoDAO estiver diferente
  Plano := TPlanoDAO.BuscarPorId(AConn, AIdPlano);
  try
    if Plano = nil then
      TAppErrors.RaiseBadRequest('Plano informado não foi encontrado.');
    if Recorrencia = 'ANUAL' then
    begin
      if Plano.ValorAnual > 0 then
        ValorPlano := Plano.ValorAnual
      else
        ValorPlano := Plano.Valor * 12;
    end
    else
      ValorPlano := Plano.Valor;
    TrialTerminaEm := IncDay(Date, 7);
    Assinatura := TAssinaturaModel.Create;
    try
      Assinatura.IdEmpresa    := AIdEmpresa;
      Assinatura.IdPlano      := AIdPlano;
      Assinatura.Recorrencia  := Recorrencia;
      Assinatura.Situacao     := 'TRIAL';
      Assinatura.IniciadoEm         := Now;
      Assinatura.TrialTerminaEm     := TrialTerminaEm;
      Assinatura.ProximoVencimento  := TrialTerminaEm;
      Assinatura.CanceladoEm        := 0;
      Assinatura.TerminaEm          := 0;
      Assinatura.Valor := ValorPlano;
      Assinatura.Observacao := 'Assinatura criada automaticamente no cadastro da empresa.';
      Result := TAssinaturaDAO.Inserir(AConn, Assinatura);
    finally
      Assinatura.Free;
    end;
  finally
    Plano.Free;
  end;
end;

class procedure TAssinaturaService.Bloquear(const AIdEmpresa: Int64;const AIdAssinatura: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdAssinatura, 'BLOQUEADA');
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaService.Ativar(const AIdEmpresa: Int64;const AIdAssinatura: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TAssinaturaDAO.AlterarSituacao(Conn, AIdEmpresa, AIdAssinatura, 'ATIVA');
  finally
    Conn.Free;
  end;
end;



class function TAssinaturaService.ConfirmarContratacao(const AIdEmpresa,AIdAssinatura: Int64): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Assinatura: TAssinaturaModel;
  Cobranca: TAssinaturaCobrancaModel;
  ProximoVencimento: TDateTime;
begin
  Result := 0;
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  if AIdAssinatura <= 0 then
    TAppErrors.RaiseBadRequest('Assinatura não informada.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Assinatura := TAssinaturaDAO.BuscarPorId(Conn, AIdEmpresa, AIdAssinatura);
      try
        if Assinatura = nil then
          TAppErrors.RaiseNotFound('Assinatura não encontrada.');
        if SameText(Assinatura.Situacao, 'CANCELADA') then
          TAppErrors.RaiseBadRequest('Não é possível ativar uma assinatura cancelada.');
        if TAssinaturaCobrancaDAO.ExisteAbertaPorAssinatura(
          Conn,
          AIdEmpresa,
          AIdAssinatura
        ) then
          TAppErrors.RaiseBadRequest(
            'Esta assinatura já possui uma cobrança aberta.'
          );
        Assinatura.Recorrencia := NormalizarRecorrencia(Assinatura.Recorrencia);
        if Assinatura.Recorrencia = 'ANUAL' then
          ProximoVencimento := IncYear(Date, 1)
        else
          ProximoVencimento := IncMonth(Date, 1);
        Assinatura.Situacao := 'ATIVA';
        Assinatura.ProximoVencimento := ProximoVencimento;
        Assinatura.TerminaEm := 0;
        Assinatura.CanceladoEm := 0;
        TAssinaturaDAO.Atualizar(Conn, Assinatura);
        Cobranca := TAssinaturaCobrancaModel.Create;
        try
          Cobranca.IdAssinatura := Assinatura.IdAssinatura;
          Cobranca.IdEmpresa := AIdEmpresa;
          Cobranca.Vencimento := ProximoVencimento;
          Cobranca.PagoEm := 0;
          Cobranca.Situacao := 'ABERTA';
          Cobranca.Valor := Assinatura.Valor;
          Cobranca.Descricao :=
            'Cobrança da assinatura ' +
            Assinatura.Recorrencia +
            ' - vencimento ' +
            FormatDateTime('dd/mm/yyyy', ProximoVencimento);
          Cobranca.Referencia := FormatDateTime('yyyy-mm', ProximoVencimento);
          Cobranca.FormaPagamento := '';
          Cobranca.IdTransacao := '';
          Cobranca.LinkPagamento := '';
          Result := TAssinaturaCobrancaDAO.Inserir(Conn, Cobranca);
        finally
          Cobranca.Free;
        end;
      finally
        Assinatura.Free;
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

class function TAssinaturaService.ProcessarBloqueios(const AIdEmpresa: Int64;const ADiasAposVencimento: Integer): TProcessarBloqueiosResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dias: Integer;
begin
  Result.AssinaturasBloqueadas := 0;
  Result.DiasAposVencimento := ADiasAposVencimento;
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  Dias := ADiasAposVencimento;
  if Dias < 0 then
    Dias := 0;
  Result.DiasAposVencimento := Dias;
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Result.AssinaturasBloqueadas :=
        TAssinaturaDAO.MarcarVencidasComoBloqueadas(
          Conn,
          AIdEmpresa,
          Dias
        );
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.ProcessarRotinaAssinaturas(const AIdEmpresa: Int64;
  const ADiasAposVencimento: Integer): TProcessarRotinaAssinaturaResult;
var
  Vencimentos: TProcessarVencimentosResult;
  Bloqueios: TProcessarBloqueiosResult;
begin
  Result.CobrancasVencidas := 0;
  Result.AssinaturasVencidas := 0;
  Result.TrialsVencidos := 0;
  Result.AssinaturasBloqueadas := 0;
  Result.DiasAposVencimento := ADiasAposVencimento;
  Vencimentos := ProcessarVencimentos(AIdEmpresa);
  Bloqueios := ProcessarBloqueios(
    AIdEmpresa,
    ADiasAposVencimento
  );
  Result.CobrancasVencidas := Vencimentos.CobrancasVencidas;
  Result.AssinaturasVencidas := Vencimentos.AssinaturasVencidas;
  Result.TrialsVencidos := Vencimentos.TrialsVencidos;
  Result.AssinaturasBloqueadas := Bloqueios.AssinaturasBloqueadas;
  Result.DiasAposVencimento := Bloqueios.DiasAposVencimento;
end;

class function TAssinaturaService.ProcessarRotinaAssinaturasGlobal(
  const ADiasAposVencimento: Integer): TProcessarRotinaGlobalAssinaturaResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Empresas: TList<Int64>;
  IdEmpresa: Int64;
  Dias: Integer;
  CobrancasVencidas: Integer;
  AssinaturasVencidas: Integer;
  TrialsVencidos: Integer;
  AssinaturasBloqueadas: Integer;
begin
  Result.EmpresasProcessadas := 0;
  Result.CobrancasVencidas := 0;
  Result.AssinaturasVencidas := 0;
  Result.TrialsVencidos := 0;
  Result.AssinaturasBloqueadas := 0;
  Dias := ADiasAposVencimento;
  if Dias < 0 then
    Dias := 0;
  Result.DiasAposVencimento := Dias;
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Empresas := TAssinaturaDAO.ListarEmpresasComAssinatura(Conn);
    try
      for IdEmpresa in Empresas do
      begin
        CobrancasVencidas := 0;
        AssinaturasVencidas := 0;
        TrialsVencidos := 0;
        AssinaturasBloqueadas := 0;
        Conn.StartTransaction;
        try
          CobrancasVencidas :=
            TAssinaturaCobrancaDAO.MarcarAbertasComoVencidas(
              Conn,
              IdEmpresa
            );
          AssinaturasVencidas :=
            TAssinaturaDAO.MarcarAssinaturasComCobrancaVencida(
              Conn,
              IdEmpresa
            );
          TrialsVencidos :=
            TAssinaturaDAO.MarcarTrialsVencidos(
              Conn,
              IdEmpresa
            );
          AssinaturasBloqueadas :=
            TAssinaturaDAO.MarcarVencidasComoBloqueadas(
              Conn,
              IdEmpresa,
              Dias
            );
          Conn.Commit;
          Inc(Result.EmpresasProcessadas);
          Inc(Result.CobrancasVencidas, CobrancasVencidas);
          Inc(Result.AssinaturasVencidas, AssinaturasVencidas);
          Inc(Result.TrialsVencidos, TrialsVencidos);
          Inc(Result.AssinaturasBloqueadas, AssinaturasBloqueadas);
        except
          Conn.Rollback;
          raise;
        end;
      end;
    finally
      Empresas.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAssinaturaService.ProcessarVencimentos(const AIdEmpresa: Int64): TProcessarVencimentosResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result.CobrancasVencidas := 0;
  Result.AssinaturasVencidas := 0;
  Result.TrialsVencidos := 0;
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Result.CobrancasVencidas :=
        TAssinaturaCobrancaDAO.MarcarAbertasComoVencidas(
          Conn,
          AIdEmpresa
        );
      Result.AssinaturasVencidas :=
        TAssinaturaDAO.MarcarAssinaturasComCobrancaVencida(
          Conn,
          AIdEmpresa
        );
      Result.TrialsVencidos :=
        TAssinaturaDAO.MarcarTrialsVencidos(
          Conn,
          AIdEmpresa
        );
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

procedure ValidarAcessoPorAssinatura(const AIdEmpresa: Int64;const AMensagemCatalogoPublico: Boolean);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Assinatura: TAssinaturaModel;
  Situacao: string;
  Mensagem: string;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Assinatura := TAssinaturaDAO.BuscarAtualEmpresa(Conn, AIdEmpresa);
    try
      if Assinatura = nil then
      begin
        if AMensagemCatalogoPublico then
          TAppErrors.RaiseBadRequest('Catálogo temporariamente indisponível.')
        else
          TAppErrors.RaiseBadRequest('Empresa sem assinatura cadastrada.');
        Exit;
      end;
      Situacao := UpperCase(Trim(Assinatura.Situacao));
      if AMensagemCatalogoPublico then
        Mensagem := 'Catálogo temporariamente indisponível. Entre em contato com a empresa.'
      else
        Mensagem := 'Acesso bloqueado. Regularize sua assinatura para continuar utilizando o sistema.';
      if (Situacao = 'VENCIDA') or
         (Situacao = 'BLOQUEADA') or
         (Situacao = 'CANCELADA') or
         (Situacao = 'INATIVA') then
      begin
        TAppErrors.RaiseBadRequest(Mensagem);
        Exit;
      end;
      if Situacao = 'TRIAL' then
      begin
        if (Assinatura.TrialTerminaEm > 0) and
           (Assinatura.TrialTerminaEm < Now) then
        begin
          TAppErrors.RaiseBadRequest(Mensagem);
          Exit;
        end;
      end;
      if Situacao = 'ATIVA' then
      begin
        if (Assinatura.ProximoVencimento > 0) and
           (Assinatura.ProximoVencimento < Now) then
        begin
          TAppErrors.RaiseBadRequest(Mensagem);
          Exit;
        end;
      end;
    finally
      Assinatura.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TAssinaturaService.ValidarAcessoCatalogoPublico(const AIdEmpresa: Int64);
begin
  ValidarAcessoPorAssinatura(AIdEmpresa, True);
end;

class procedure TAssinaturaService.ValidarAcessoPainel(const AIdEmpresa: Int64);
begin
  ValidarAcessoPorAssinatura(AIdEmpresa, False);
end;



class function TAssinaturaService.ConsultarStatus(const AIdEmpresa: Int64): TAssinaturaStatusResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Assinatura: TAssinaturaModel;
  Situacao: string;
begin
  Result.IdAssinatura := 0;
  Result.IdPlano := 0;
  Result.Recorrencia := '';
  Result.Situacao := 'SEM_ASSINATURA';
  Result.SituacaoAtual := 'SEM_ASSINATURA';
  Result.Valor := 0;
  Result.IniciadoEm := 0;
  Result.TrialTerminaEm := 0;
  Result.ProximoVencimento := 0;
  Result.PodeAcessar := False;
  Result.Bloqueado := True;
  Result.EmTrial := False;
  Result.ExibirAlerta := True;
  Result.DiasRestantesTrial := 0;
  Result.DiasParaVencimento := 0;
  Result.Mensagem := 'Empresa sem assinatura cadastrada.';
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Assinatura := TAssinaturaDAO.BuscarAtualEmpresa(Conn, AIdEmpresa);
    try
      if Assinatura = nil then
        Exit;
      Situacao := UpperCase(Trim(Assinatura.Situacao));
      Result.IdAssinatura := Assinatura.IdAssinatura;
      Result.IdPlano := Assinatura.IdPlano;
      Result.Recorrencia := Assinatura.Recorrencia;
      Result.Situacao := Situacao;
      Result.SituacaoAtual := Situacao;
      Result.Valor := Assinatura.Valor;
      Result.IniciadoEm := Assinatura.IniciadoEm;
      Result.TrialTerminaEm := Assinatura.TrialTerminaEm;
      Result.ProximoVencimento := Assinatura.ProximoVencimento;
      Result.DiasRestantesTrial := DiasAteData(Assinatura.TrialTerminaEm);
      Result.DiasParaVencimento := DiasAteData(Assinatura.ProximoVencimento);
      if Situacao = 'TRIAL' then
      begin
        Result.EmTrial := True;
        if Assinatura.TrialTerminaEm <= 0 then
        begin
          Result.PodeAcessar := False;
          Result.Bloqueado := True;
          Result.ExibirAlerta := True;
          Result.SituacaoAtual := 'VENCIDA';
          Result.Mensagem := 'Período de teste sem data de término configurada.';
          Exit;
        end;
        if Assinatura.TrialTerminaEm < Now then
        begin
          Result.PodeAcessar := False;
          Result.Bloqueado := True;
          Result.ExibirAlerta := True;
          Result.SituacaoAtual := 'VENCIDA';
          Result.Mensagem := 'Seu período de teste terminou. Escolha um plano para continuar utilizando o sistema.';
          Exit;
        end;
        Result.PodeAcessar := True;
        Result.Bloqueado := False;
        Result.ExibirAlerta := Result.DiasRestantesTrial <= 3;
        Result.Mensagem :=
          'Você está no período de teste. Restam ' +
          Result.DiasRestantesTrial.ToString +
          ' dia(s).';
        Exit;
      end;
      if Situacao = 'ATIVA' then
      begin
        if Assinatura.ProximoVencimento <= 0 then
        begin
          Result.PodeAcessar := False;
          Result.Bloqueado := True;
          Result.ExibirAlerta := True;
          Result.SituacaoAtual := 'VENCIDA';
          Result.Mensagem := 'Assinatura ativa sem próximo vencimento configurado.';
          Exit;
        end;
        if Assinatura.ProximoVencimento < Now then
        begin
          Result.PodeAcessar := False;
          Result.Bloqueado := True;
          Result.ExibirAlerta := True;
          Result.SituacaoAtual := 'VENCIDA';
          Result.Mensagem := 'Sua assinatura está vencida. Regularize o pagamento para continuar utilizando o sistema.';
          Exit;
        end;
        Result.PodeAcessar := True;
        Result.Bloqueado := False;
        Result.ExibirAlerta := Result.DiasParaVencimento <= 5;
        Result.Mensagem :=
          'Assinatura ativa. Próximo vencimento em ' +
          Result.DiasParaVencimento.ToString +
          ' dia(s).';
        Exit;
      end;
      if Situacao = 'VENCIDA' then
      begin
        Result.PodeAcessar := False;
        Result.Bloqueado := True;
        Result.ExibirAlerta := True;
        Result.Mensagem := 'Sua assinatura está vencida. Regularize o pagamento para continuar.';
        Exit;
      end;
      if Situacao = 'BLOQUEADA' then
      begin
        Result.PodeAcessar := False;
        Result.Bloqueado := True;
        Result.ExibirAlerta := True;
        Result.Mensagem := 'Sua assinatura está bloqueada. Entre em contato com o suporte.';
        Exit;
      end;
      if Situacao = 'CANCELADA' then
      begin
        Result.PodeAcessar := False;
        Result.Bloqueado := True;
        Result.ExibirAlerta := True;
        Result.Mensagem := 'Sua assinatura foi cancelada.';
        Exit;
      end;
      if Situacao = 'INATIVA' then
      begin
        Result.PodeAcessar := False;
        Result.Bloqueado := True;
        Result.ExibirAlerta := True;
        Result.Mensagem := 'Sua assinatura está inativa.';
        Exit;
      end;
      Result.PodeAcessar := False;
      Result.Bloqueado := True;
      Result.ExibirAlerta := True;
      Result.SituacaoAtual := 'INVALIDA';
      Result.Mensagem := 'Situação da assinatura inválida.';
    finally
      Assinatura.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
