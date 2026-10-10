unit EleicaoCodigoTemporarioAPI.Service;

interface

uses
  System.Generics.Collections,
  EleicaoCodigoTemporarioAPI.Dao;

type
  TEleicaoCodigoTemporarioGerado = record
    Codigo: string;
    ExpiraEm: TDateTime;
    ValidadeSegundos: Integer;
  end;

  TEleicaoCodigoTemporarioAPIService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;
    class function GerarCodigo: string; static;
    class function HashCodigo(const ACodigo: string): string; static;
    class function DescricaoSegura(
      const AIdEleitor, AIdOperador: Integer;
      const AComplemento: string = ''
    ): string; static;
  public
    class function BuscarEleitores(
      const ASlug: string;
      const AIdOperador, AIdEmpresa: Integer;
      const ATermo: string
    ): TEleicaoCodigoTemporarioEleitores; static;

    class function Gerar(
      const ASlug: string;
      const AIdOperador, AIdEmpresa, AIdUsuarioEleitor: Integer;
      const AIP, AUserAgent: string
    ): TEleicaoCodigoTemporarioGerado; static;

    class function Validar(
      const ASlug: string;
      const AIdUsuario, AIdEmpresa: Integer;
      const ACodigo, AIP, AUserAgent: string;
      out ATokenVotacao: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.Hash,
  System.DateUtils,
  Uni,
  App.Config,
  App.JWT,
  APP.Errors,
  Database.Connection,
  EleicaoAdminAPI.Dao,
  EleicaoHorarioAPI.Service,
  EleicaoAuditoriaAPI.Service,
  EleicaoRateLimitAPI.Service;

const
  VALIDADE_MINUTOS = 5;
  LIMITE_ELEITOR = 3;
  LIMITE_OPERADOR = 20;
  JANELA_LIMITE_MINUTOS = 30;
  ORIGEM_CODIGO = 'ADMIN_CONTINGENCIA';

class function TEleicaoCodigoTemporarioAPIService.NormalizarSlug(
  const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));
  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);
  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);
  if S.StartsWith('-') then Delete(S,1,1);
  if S.EndsWith('-') then Delete(S,Length(S),1);
  Result := S;
end;

class function TEleicaoCodigoTemporarioAPIService.GerarCodigo: string;
var
  Guid: TGUID;
  Hash: string;
  Numero: Integer;
begin
  CreateGUID(Guid);
  Hash := THashSHA2.GetHashString(GUIDToString(Guid), SHA256);
  Numero := StrToInt('$' + Copy(Hash,1,7));
  Numero := 100000 + (Numero mod 900000);
  Result := Format('%.6d',[Numero]);
end;

class function TEleicaoCodigoTemporarioAPIService.HashCodigo(
  const ACodigo: string): string;
begin
  Result := THashSHA2.GetHashString(Trim(ACodigo), SHA256);
end;

class function TEleicaoCodigoTemporarioAPIService.DescricaoSegura(
  const AIdEleitor, AIdOperador: Integer;
  const AComplemento: string): string;
begin
  Result := 'origem=' + ORIGEM_CODIGO +
            '; eleitor_usuario_id=' + AIdEleitor.ToString +
            '; operador_usuario_id=' + AIdOperador.ToString;
  if not Trim(AComplemento).IsEmpty then
    Result := Result + '; ' + Trim(AComplemento);
end;

class function TEleicaoCodigoTemporarioAPIService.BuscarEleitores(
  const ASlug: string; const AIdOperador, AIdEmpresa: Integer;
  const ATermo: string): TEleicaoCodigoTemporarioEleitores;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
begin
  Result := TEleicaoCodigoTemporarioEleitores.Create;
  try
    if (AIdOperador <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);
    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, NormalizarSlug(ASlug), AIdEmpresa, Eleicao) then
        TAppErrors.RaiseNotFound('Eleição não encontrada.');

      TEleicaoCodigoTemporarioAPIDao.GarantirEstrutura(Conn);
      TEleicaoCodigoTemporarioAPIDao.BuscarEleitores(
        Conn, AIdEmpresa, Eleicao.IdEleicao, ATermo, Result
      );
    finally
      Conn.Free;
    end;
  except
    Result.Free;
    Result := nil;
    raise;
  end;
end;

class function TEleicaoCodigoTemporarioAPIService.Gerar(
  const ASlug: string; const AIdOperador, AIdEmpresa, AIdUsuarioEleitor: Integer;
  const AIP, AUserAgent: string): TEleicaoCodigoTemporarioGerado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
  NomeEleitor: string;
  JaVotou: Boolean;
  Codigo: string;
  CodigoHash: string;
  QuantidadeInvalidados: Integer;
begin
  Result := Default(TEleicaoCodigoTemporarioGerado);

  if (AIdOperador <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');
  if AIdUsuarioEleitor <= 0 then
    TAppErrors.RaiseBadRequest('Eleitor não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, NormalizarSlug(ASlug), AIdEmpresa, Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Eleicao.Situacao, 'ABERTA') then
      TAppErrors.RaiseBadRequest('A eleição não está aberta para votação.');

    if not TEleicaoCodigoTemporarioAPIDao.EleitorValido(
      Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuarioEleitor, NomeEleitor, JaVotou
    ) then
      TAppErrors.RaiseNotFound('Eleitor não encontrado nesta empresa.');

    if JaVotou then
      TAppErrors.RaiseBadRequest('O voto deste eleitor já foi registrado.');

    TEleicaoCodigoTemporarioAPIDao.GarantirEstrutura(Conn);

    if TEleicaoCodigoTemporarioAPIDao.QuantidadeGeracoesEleitor(
      Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuarioEleitor, JANELA_LIMITE_MINUTOS
    ) >= LIMITE_ELEITOR then
      TAppErrors.RaiseBadRequest('Limite de códigos temporários para este eleitor atingido. Tente novamente mais tarde.');

    if TEleicaoCodigoTemporarioAPIDao.QuantidadeGeracoesOperador(
      Conn, AIdEmpresa, Eleicao.IdEleicao, AIdOperador, JANELA_LIMITE_MINUTOS
    ) >= LIMITE_OPERADOR then
      TAppErrors.RaiseBadRequest('Limite de geração de códigos temporários pelo operador atingido. Tente novamente mais tarde.');

    Codigo := GerarCodigo;
    CodigoHash := HashCodigo(Codigo);

    Conn.StartTransaction;
    try
      QuantidadeInvalidados := TEleicaoCodigoTemporarioAPIDao.InvalidarAtivos(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuarioEleitor
      );

      if QuantidadeInvalidados > 0 then
        TEleicaoAuditoriaAPIService.RegistrarEvento(
          Conn, AIdEmpresa, Eleicao.IdEleicao, AIdOperador,
          AUDITORIA_CODIGO_TEMP_INVALIDADO, AUDITORIA_ORIGEM_ADMIN, True,
          DescricaoSegura(AIdUsuarioEleitor,AIdOperador,
            'motivo=NOVO_CODIGO; quantidade=' + QuantidadeInvalidados.ToString),
          AIP, AUserAgent
        );

      TEleicaoCodigoTemporarioAPIDao.InvalidarConfirmacaoNormal(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuarioEleitor
      );
      TEleicaoCodigoTemporarioAPIDao.Inserir(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuarioEleitor, AIdOperador,
        CodigoHash, VALIDADE_MINUTOS, AIP, AUserAgent
      );

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdOperador,
        AUDITORIA_CODIGO_TEMP_GERADO, AUDITORIA_ORIGEM_ADMIN, True,
        DescricaoSegura(AIdUsuarioEleitor,AIdOperador,
          'validade_minutos=' + VALIDADE_MINUTOS.ToString),
        AIP, AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;

    Result.Codigo := Codigo;
    Result.ValidadeSegundos := VALIDADE_MINUTOS * 60;
    Result.ExpiraEm := IncMinute(Now, VALIDADE_MINUTOS);
  finally
    Codigo := '';
    CodigoHash := '';
    NomeEleitor := '';
    Conn.Free;
  end;
end;

class function TEleicaoCodigoTemporarioAPIService.Validar(
  const ASlug: string; const AIdUsuario, AIdEmpresa: Integer;
  const ACodigo, AIP, AUserAgent: string; out ATokenVotacao: string): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
  Dados: TEleicaoCodigoTemporarioDados;
  Roles: TArray<string>;
  CodigoHash: string;
begin
  Result := False;
  ATokenVotacao := '';

  if Length(Trim(ACodigo)) <> 6 then Exit;
  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, NormalizarSlug(ASlug), AIdEmpresa, Eleicao) then
      Exit;

    TEleicaoHorarioAPIService.ValidarPeriodoVotacao(Conn, NormalizarSlug(ASlug), AIdEmpresa);
    TEleicaoCodigoTemporarioAPIDao.GarantirEstrutura(Conn);

    if not TEleicaoCodigoTemporarioAPIDao.BuscarAtivo(
      Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario, Dados
    ) then
      Exit;

    if Dados.ExpiraEm <= Now then
    begin
      Conn.StartTransaction;
      try
        TEleicaoCodigoTemporarioAPIDao.MarcarExpirado(Conn, Dados.Id);
        TEleicaoAuditoriaAPIService.RegistrarEvento(
          Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
          AUDITORIA_CODIGO_TEMP_EXPIRADO, AUDITORIA_ORIGEM_SISTEMA, True,
          DescricaoSegura(AIdUsuario,Dados.OperadorUsuarioId,'status=EXPIRADO'),
          AIP, AUserAgent
        );
        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        raise;
      end;
      Exit;
    end;

    TEleicaoRateLimitAPIService.VerificarValidacaoCodigo(
      AIdEmpresa, Eleicao.IdEleicao, AIdUsuario, NormalizarSlug(ASlug)
    );

    CodigoHash := HashCodigo(Trim(ACodigo));
    if not SameText(CodigoHash, Dados.CodigoHash) then
    begin
      TEleicaoRateLimitAPIService.RegistrarFalhaValidacaoCodigo(
        AIdEmpresa, Eleicao.IdEleicao, AIdUsuario, NormalizarSlug(ASlug)
      );
      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
        AUDITORIA_CODIGO_TEMP_INVALIDO, AUDITORIA_ORIGEM_ELEITOR, False,
        DescricaoSegura(AIdUsuario,Dados.OperadorUsuarioId,'resultado=INVALIDO'),
        AIP, AUserAgent
      );
      TAppErrors.RaiseBadRequest('Código inválido ou expirado.');
    end;

    Conn.StartTransaction;
    try
      TEleicaoCodigoTemporarioAPIDao.MarcarUtilizado(Conn, Dados.Id);
      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
        AUDITORIA_CODIGO_TEMP_VALIDADO, AUDITORIA_ORIGEM_ELEITOR, True,
        DescricaoSegura(AIdUsuario,Dados.OperadorUsuarioId,'status=UTILIZADO'),
        AIP, AUserAgent
      );
      Conn.Commit;
    except
      if Conn.InTransaction then Conn.Rollback;
      raise;
    end;

    SetLength(Roles,1);
    Roles[0] := 'ELEITOR_VOTACAO';
    ATokenVotacao := TAppJWT.GerarToken(
      Config.JWT,
      AIdUsuario,
      AIdEmpresa,
      Roles,
      NormalizarSlug(ASlug),
      Config.JWT.TtlVotacaoMinutos
    );

    TEleicaoRateLimitAPIService.RegistrarSucessoValidacaoCodigo(
      AIdEmpresa, Eleicao.IdEleicao, AIdUsuario, NormalizarSlug(ASlug)
    );

    CodigoHash := '';
    Result := True;
  finally
    CodigoHash := '';
    Conn.Free;
  end;
end;

end.
