unit EleicaoRateLimitAPI.Service;

interface

type
  TEleicaoRateLimitAPIService = class
  private
    class function SomenteNumeros(const AValor: string): string; static;
    class function GerarHash(const AValor: string): string; static;
    class function GerarChaveLogin(const ASlug, ACPF, AMatricula: string): string; static;
    class function GerarChaveUsuario(const ASlug: string; const AIdUsuario: Integer): string; static;

    class procedure Verificar(const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string;
      const AMaxTentativas, AJanelaMinutos, ABloqueioMinutos: Integer; const AMensagem: string); static;

    class procedure RegistrarTentativa(const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string;
      const AMaxTentativas, AJanelaMinutos, ABloqueioMinutos: Integer); static;

    class procedure Limpar(const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string); static;

  public
    class procedure VerificarLogin(const AIdEmpresa, AIdEleicao: Integer; const ASlug, ACPF, AMatricula: string); static;
    class procedure RegistrarFalhaLogin(const AIdEmpresa, AIdEleicao: Integer; const ASlug, ACPF, AMatricula: string); static;
    class procedure RegistrarSucessoLogin(const AIdEmpresa, AIdEleicao: Integer; const ASlug, ACPF, AMatricula: string); static;

    class procedure VerificarEnvioCodigo(const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string); static;
    class procedure RegistrarEnvioCodigo(const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string); static;

    class procedure VerificarValidacaoCodigo(const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string); static;
    class procedure RegistrarFalhaValidacaoCodigo(const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string); static;
    class procedure RegistrarSucessoValidacaoCodigo(const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string); static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoRateLimitAPI.Dao;

const
  RATE_TIPO_LOGIN             = 'LOGIN';
  RATE_TIPO_CODIGO_ENVIO      = 'CODIGO_ENVIO';
  RATE_TIPO_CODIGO_VALIDACAO  = 'CODIGO_VALIDACAO';

  RATE_LOGIN_MAX              = 5;
  RATE_LOGIN_JANELA_MIN       = 15;
  RATE_LOGIN_BLOQUEIO_MIN     = 15;

  RATE_CODIGO_ENVIO_MAX           = 5;
  RATE_CODIGO_ENVIO_JANELA_MIN    = 30;
  RATE_CODIGO_ENVIO_BLOQUEIO_MIN  = 30;

  RATE_CODIGO_VALIDACAO_MAX           = 5;
  RATE_CODIGO_VALIDACAO_JANELA_MIN    = 10;
  RATE_CODIGO_VALIDACAO_BLOQUEIO_MIN  = 15;

{ TEleicaoRateLimitAPIService }

class function TEleicaoRateLimitAPIService.SomenteNumeros(const AValor: string): string;
var
  C: Char;
begin
  Result := '';

  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

class function TEleicaoRateLimitAPIService.GerarHash(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(AValor));
end;

class function TEleicaoRateLimitAPIService.GerarChaveLogin(const ASlug, ACPF, AMatricula: string): string;
begin
  Result := GerarHash(
    UpperCase(Trim(ASlug)) + '|' +
    SomenteNumeros(ACPF) + '|' +
    UpperCase(Trim(AMatricula))
  );
end;

class function TEleicaoRateLimitAPIService.GerarChaveUsuario(const ASlug: string; const AIdUsuario: Integer): string;
begin
  Result := GerarHash(
    UpperCase(Trim(ASlug)) + '|' +
    IntToStr(AIdUsuario)
  );
end;

class procedure TEleicaoRateLimitAPIService.Verificar(const AIdEmpresa, AIdEleicao: Integer;
  const ATipo, AChave: string; const AMaxTentativas, AJanelaMinutos, ABloqueioMinutos: Integer;
  const AMensagem: string);
var
  Config   : TAppApiConfig;
  Conn     : TUniConnection;
  Dados    : TEleicaoRateLimitDados;
  Bloqueado: Boolean;
begin
  if (AIdEmpresa <= 0) or (AIdEleicao <= 0) or Trim(ATipo).IsEmpty or Trim(AChave).IsEmpty then
    Exit;

  Bloqueado := False;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;

    try
      if TEleicaoRateLimitAPIDao.Buscar(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave, Dados) then
      begin

        // Ainda está dentro do período de bloqueio.
        if Dados.TemBloqueadoAte and (Dados.BloqueadoAte > Dados.DataHoraAtual) then
          Bloqueado := True

        // Bloqueio já expirou: inicia um novo ciclo na próxima tentativa.
        else if Dados.TemBloqueadoAte and (Dados.BloqueadoAte <= Dados.DataHoraAtual) then
          TEleicaoRateLimitAPIDao.Excluir(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave)

        // Janela de tentativas expirou.
        else if IncMinute(Dados.JanelaInicio, AJanelaMinutos) <= Dados.DataHoraAtual then
          TEleicaoRateLimitAPIDao.Excluir(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave)

        // Proteção adicional caso o limite tenha sido atingido sem bloqueado_ate.
        else if Dados.Tentativas >= AMaxTentativas then
        begin
          TEleicaoRateLimitAPIDao.Bloquear(Conn, Dados.Id, ABloqueioMinutos);
          Bloqueado := True;
        end;

      end;

      Conn.Commit;

    except
      if Conn.InTransaction then
        Conn.Rollback;

      raise;
    end;

    if Bloqueado then
      TAppErrors.RaiseBadRequest(AMensagem);

  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIService.RegistrarTentativa(const AIdEmpresa, AIdEleicao: Integer;
  const ATipo, AChave: string; const AMaxTentativas, AJanelaMinutos, ABloqueioMinutos: Integer);
var
  Config       : TAppApiConfig;
  Conn         : TUniConnection;
  Dados        : TEleicaoRateLimitDados;
  NovaTentativa: Integer;
begin
  if (AIdEmpresa <= 0) or (AIdEleicao <= 0) or Trim(ATipo).IsEmpty or Trim(AChave).IsEmpty then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Conn.StartTransaction;

    try

      if not TEleicaoRateLimitAPIDao.Buscar(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave, Dados) then
      begin
        TEleicaoRateLimitAPIDao.Criar(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave);
      end
      else
      begin

        // Se já está bloqueado, não aumenta mais o contador.
        if Dados.TemBloqueadoAte and (Dados.BloqueadoAte > Dados.DataHoraAtual) then
        begin
          // Mantém o bloqueio atual.
        end

        // Bloqueio expirou ou a janela terminou: começa novamente com 1 tentativa.
        else if (Dados.TemBloqueadoAte and (Dados.BloqueadoAte <= Dados.DataHoraAtual)) or
                (IncMinute(Dados.JanelaInicio, AJanelaMinutos) <= Dados.DataHoraAtual) then
        begin
          TEleicaoRateLimitAPIDao.Reiniciar(Conn, Dados.Id);
        end
        else
        begin
          NovaTentativa := Dados.Tentativas + 1;

          TEleicaoRateLimitAPIDao.IncrementarTentativa(Conn, Dados.Id);

          if NovaTentativa >= AMaxTentativas then
            TEleicaoRateLimitAPIDao.Bloquear(Conn, Dados.Id, ABloqueioMinutos);
        end;

      end;

      Conn.Commit;

    except
      if Conn.InTransaction then
        Conn.Rollback;

      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIService.Limpar(const AIdEmpresa, AIdEleicao: Integer;
  const ATipo, AChave: string);
var
  Config: TAppApiConfig;
  Conn  : TUniConnection;
begin
  if (AIdEmpresa <= 0) or (AIdEleicao <= 0) or Trim(ATipo).IsEmpty or Trim(AChave).IsEmpty then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    TEleicaoRateLimitAPIDao.Excluir(Conn, AIdEmpresa, AIdEleicao, ATipo, AChave);
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIService.VerificarLogin(const AIdEmpresa, AIdEleicao: Integer;
  const ASlug, ACPF, AMatricula: string);
begin
  Verificar(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_LOGIN,
    GerarChaveLogin(ASlug, ACPF, AMatricula),
    RATE_LOGIN_MAX,
    RATE_LOGIN_JANELA_MIN,
    RATE_LOGIN_BLOQUEIO_MIN,
    'Muitas tentativas de identificação. Tente novamente em alguns minutos.'
  );
end;

class procedure TEleicaoRateLimitAPIService.RegistrarFalhaLogin(const AIdEmpresa, AIdEleicao: Integer;
  const ASlug, ACPF, AMatricula: string);
begin
  RegistrarTentativa(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_LOGIN,
    GerarChaveLogin(ASlug, ACPF, AMatricula),
    RATE_LOGIN_MAX,
    RATE_LOGIN_JANELA_MIN,
    RATE_LOGIN_BLOQUEIO_MIN
  );
end;

class procedure TEleicaoRateLimitAPIService.RegistrarSucessoLogin(const AIdEmpresa, AIdEleicao: Integer;
  const ASlug, ACPF, AMatricula: string);
begin
  Limpar(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_LOGIN,
    GerarChaveLogin(ASlug, ACPF, AMatricula)
  );
end;

class procedure TEleicaoRateLimitAPIService.VerificarEnvioCodigo(const AIdEmpresa, AIdEleicao,
  AIdUsuario: Integer; const ASlug: string);
begin
  Verificar(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_CODIGO_ENVIO,
    GerarChaveUsuario(ASlug, AIdUsuario),
    RATE_CODIGO_ENVIO_MAX,
    RATE_CODIGO_ENVIO_JANELA_MIN,
    RATE_CODIGO_ENVIO_BLOQUEIO_MIN,
    'Limite de envio de código atingido. Tente novamente mais tarde.'
  );
end;

class procedure TEleicaoRateLimitAPIService.RegistrarEnvioCodigo(const AIdEmpresa, AIdEleicao,
  AIdUsuario: Integer; const ASlug: string);
begin
  RegistrarTentativa(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_CODIGO_ENVIO,
    GerarChaveUsuario(ASlug, AIdUsuario),
    RATE_CODIGO_ENVIO_MAX,
    RATE_CODIGO_ENVIO_JANELA_MIN,
    RATE_CODIGO_ENVIO_BLOQUEIO_MIN
  );
end;

class procedure TEleicaoRateLimitAPIService.VerificarValidacaoCodigo(const AIdEmpresa, AIdEleicao,
  AIdUsuario: Integer; const ASlug: string);
begin
  Verificar(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_CODIGO_VALIDACAO,
    GerarChaveUsuario(ASlug, AIdUsuario),
    RATE_CODIGO_VALIDACAO_MAX,
    RATE_CODIGO_VALIDACAO_JANELA_MIN,
    RATE_CODIGO_VALIDACAO_BLOQUEIO_MIN,
    'Muitas tentativas de validação do código. Tente novamente em alguns minutos.'
  );
end;

class procedure TEleicaoRateLimitAPIService.RegistrarFalhaValidacaoCodigo(
  const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string);
begin
  RegistrarTentativa(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_CODIGO_VALIDACAO,
    GerarChaveUsuario(ASlug, AIdUsuario),
    RATE_CODIGO_VALIDACAO_MAX,
    RATE_CODIGO_VALIDACAO_JANELA_MIN,
    RATE_CODIGO_VALIDACAO_BLOQUEIO_MIN
  );
end;

class procedure TEleicaoRateLimitAPIService.RegistrarSucessoValidacaoCodigo(
  const AIdEmpresa, AIdEleicao, AIdUsuario: Integer; const ASlug: string);
begin
  Limpar(
    AIdEmpresa,
    AIdEleicao,
    RATE_TIPO_CODIGO_VALIDACAO,
    GerarChaveUsuario(ASlug, AIdUsuario)
  );
end;

end.
