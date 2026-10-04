{

Login ADMIN
→ token com role ADMIN

Painel
→ dados da eleição
→ total eleitores
→ total votantes
→ total pendentes
→ percentual
→ evolução por hora
→ acumulado

}

unit EleicaoAdminAPI.Service;

interface

uses
  System.Generics.Collections,
  EleicaoAuditoriaAPI.Service;

type
  TEleicaoAdminLoginResult = record
    Token: string;
    Nome: string;
  end;

  TEleicaoAdminPainelResumo = record
    TotalEleitores: Integer;
    TotalVotantes: Integer;
    TotalNaoVotantes: Integer;
    PercentualParticipacao: Double;
  end;

  TEleicaoAdminPainelEvolucao = record
    Hora: string;
    Quantidade: Integer;
    Acumulado: Integer;
  end;

  TEleicaoAdminPainelResult = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Situacao: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    abertura:string;
    encerramento:string;

    Resumo: TEleicaoAdminPainelResumo;

    Evolucao: TList<TEleicaoAdminPainelEvolucao>;
  end;

{$REGION 'APURACAO'}

type
  TEleicaoAdminResultadoChapaResult = record
    IdChapa: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoAdminResultadoResult = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Situacao: string;

    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;

    Chapas: TList<TEleicaoAdminResultadoChapaResult>;
  end;

{$ENDREGION}

  TEleicaoAdminAPIService = class
  public

    class function Login(
      const ASlug: string;
      const AEmail: string;
      const ASenha: string
    ): TEleicaoAdminLoginResult; static;

    class function BuscarPainel(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer
    ): TEleicaoAdminPainelResult; static;

    class procedure EncerrarEleicao(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const AIP, AUserAgent: string
    ); static;

    class procedure IniciarApuracao(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const AIP, AUserAgent: string
    ); static;

    class procedure FinalizarApuracao(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const AIP, AUserAgent: string
    ); static;

    class function BuscarResultado(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer
    ): TEleicaoAdminResultadoResult; static;

    class procedure PublicarResultado(
      const ASlug: string;
      const AIdUsuario: Integer;
      const AIdEmpresa: Integer;
      const AIP, AUserAgent: string
    ); static;

    class procedure VerificarAberturaAutomatica(const AIdEmpresa, AIdEleicao: Integer);
    class procedure VerificarEncerramentoAutomatico(const AIdEmpresa, AIdEleicao: Integer);
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  App.JWT,
  Auth.Passwords,
  Database.Connection,
  EleicaoAdminAPI.Dao;

{ TEleicaoAdminAPIService }

class function TEleicaoAdminAPIService.Login(const ASlug: string;const AEmail: string;
                                            const ASenha: string): TEleicaoAdminLoginResult;
var
  Config    : TAppApiConfig;
  Conn      : TUniConnection;
  Usuario   : TEleicaoAdminUsuario;
  Roles     : TArray<string>;
begin
  Result    := Default(TEleicaoAdminLoginResult);

  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if Trim(AEmail).IsEmpty then
    TAppErrors.RaiseBadRequest('E-mail não informado.');

  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Senha não informada.');

  Config    := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn      := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarUsuarioAdmin(Conn, Trim(ASlug), Trim(AEmail), Usuario) then
      TAppErrors.RaiseUnauthorized('Usuário ou senha inválidos.');

    if not VerifySenha(ASenha, Usuario.SenhaHash) then
      TAppErrors.RaiseUnauthorized('Email ou senha inválidos.');

    // ADMIN acessa as eleições da empresa; COMISSAO somente a eleição vinculada,
    // regra já validada pelo DAO através do slug.
    if not (SameText(Trim(Usuario.Perfil),'ADMIN') or
            SameText(Trim(Usuario.Perfil),'COMISSAO')) then
      TAppErrors.RaiseUnauthorized('Usuário não autorizado para acessar o painel eleitoral.');

    SetLength(Roles, 1);
    Roles[0] := UpperCase(Trim(Usuario.Perfil));

    //Result.Token := TAppJWT.GerarToken(Config.JWT, Usuario.IdUsuario, Usuario.IdEmpresa, Roles, Trim(ASlug));
    Result.Token := TAppJWT.GerarToken(
                    Config.JWT,
                    Usuario.IdUsuario,
                    Usuario.IdEmpresa,
                    Roles,
                    Trim(ASlug),
                    Config.JWT.TtlAdminMinutos
                  );


    Result.Nome     := Usuario.Nome;

  finally
    Conn.Free;
  end;
end;

class function TEleicaoAdminAPIService.BuscarPainel(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer
): TEleicaoAdminPainelResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;

  Eleicao: TEleicaoAdminDados;
  ResumoDAO: TEleicaoAdminResumo;

  ListaDAO: TEleicaoAdminAPIListEvolucao;
  ItemDAO: TEleicaoAdminEvolucao;
  Item: TEleicaoAdminPainelEvolucao;

  Acumulado: Integer;
begin
  Result := Default(TEleicaoAdminPainelResult);

  Result.Evolucao :=
    TList<TEleicaoAdminPainelEvolucao>.Create;

  try

    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest(
        'Eleição não informada.'
      );

    if (AIdUsuario <= 0) or
       (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized(
        'Acesso não autorizado.'
      );

    Config :=
      TAppConfig.Carregar(
        ExtractFilePath(ParamStr(0)) +
        'Config.ini'
      );

    Conn :=
      TDatabaseConnection.NewConnection(
        Config.Database
      );

    try

      //
      // Dados da eleição
      //
      if not TEleicaoAdminAPIDao.BuscarEleicao(
        Conn,
        Trim(ASlug),
        AIdEmpresa,
        Eleicao
      ) then
        TAppErrors.RaiseNotFound(
          'Eleição não encontrada.'
        );

      Result.IdEleicao    := Eleicao.IdEleicao;
      Result.NomeEleicao  := Eleicao.Nome;
      Result.Situacao     := Eleicao.Situacao;
      Result.DataHoraInicio := Eleicao.DataHoraInicio;
      Result.DataHoraFim  := Eleicao.DataHoraFim;
      Result.abertura     := Eleicao.abertura;
      Result.encerramento := Eleicao.encerramento;

      //
      // Resumo
      //
      if not TEleicaoAdminAPIDao.BuscarResumoPainel(
        Conn,
        AIdEmpresa,
        Eleicao.IdEleicao,
        ResumoDAO
      ) then
        TAppErrors.RaiseBadRequest(
          'Não foi possível carregar o resumo da eleição.'
        );

      Result.Resumo.TotalEleitores :=
        ResumoDAO.TotalEleitores;

      Result.Resumo.TotalVotantes :=
        ResumoDAO.TotalVotantes;

      Result.Resumo.TotalNaoVotantes :=
        Result.Resumo.TotalEleitores -
        Result.Resumo.TotalVotantes;

      if Result.Resumo.TotalNaoVotantes < 0 then
        Result.Resumo.TotalNaoVotantes := 0;

      if Result.Resumo.TotalEleitores > 0 then
      begin
        Result.Resumo.PercentualParticipacao :=
          (
            Result.Resumo.TotalVotantes /
            Result.Resumo.TotalEleitores
          ) * 100;
      end
      else
        Result.Resumo.PercentualParticipacao := 0;

      //
      // Evolução por horário
      //
      ListaDAO := TEleicaoAdminAPIListEvolucao.Create;

      //verificar abertura automatica
      TEleicaoAdminAPIService.VerificarAberturaAutomatica(AIdEmpresa,Eleicao.IdEleicao);
      TEleicaoAdminAPIService.VerificarEncerramentoAutomatico(AIdEmpresa,Eleicao.IdEleicao);

      try

        TEleicaoAdminAPIDao.BuscarEvolucaoVotacao(
          Conn,
          AIdEmpresa,
          Eleicao.IdEleicao,
          Eleicao.DataHoraInicio,
          Eleicao.DataHoraFim,
          ListaDAO
        );

        Acumulado := 0;

        for ItemDAO in ListaDAO do
        begin
          Acumulado :=
            Acumulado +
            ItemDAO.Quantidade;

          Item := Default(
            TEleicaoAdminPainelEvolucao
          );

          Item.Hora :=
            ItemDAO.Hora;

          Item.Quantidade :=
            ItemDAO.Quantidade;

          Item.Acumulado :=
            Acumulado;

          Result.Evolucao.Add(Item);
        end;

      finally
        ListaDAO.Free;
      end;

    finally
      Conn.Free;
    end;

  except
    Result.Evolucao.Free;
    Result.Evolucao := nil;
    raise;
  end;
end;

class procedure TEleicaoAdminAPIService.EncerrarEleicao(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const AIP, AUserAgent: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Eleição não informada.'
    );

  if (AIdUsuario <= 0) or
     (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized(
      'Acesso não autorizado.'
    );

  Config :=  TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try

    //
    // Localizar eleição pelo slug
    //
    if not TEleicaoAdminAPIDao.BuscarEleicao(
      Conn,
      Trim(ASlug),
      AIdEmpresa,
      Eleicao
    ) then
      TAppErrors.RaiseNotFound(
        'Eleição não encontrada.'
      );

    //
    // Regra de situação
    //
    if not SameText(
      Trim(Eleicao.Situacao),
      'ABERTA'
    ) then
      TAppErrors.RaiseBadRequest(
        'Somente eleições abertas podem ser encerradas.'
      );

    //
    // Encerrar
    //

    Conn.StartTransaction;
    Try
      if not TEleicaoAdminAPIDao.EncerrarEleicao(Conn, AIdEmpresa, Eleicao.IdEleicao) then
      TAppErrors.RaiseBadRequest('Não foi possível encerrar a eleição.');

      //Auditoria
      TEleicaoAuditoriaAPIService.RegistrarEvento(Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
                                    AUDITORIA_ELEICAO_ENCERRADA, AUDITORIA_ORIGEM_ADMIN, True,
                                    'Eleição encerrada pelo administrador.',AIP, AUserAgent);
      Conn.Commit;
    except
      if Conn.InTransaction then
      Conn.Rollback;
      raise;
    End;

  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoAdminAPIService.IniciarApuracao(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const AIP, AUserAgent: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao), 'ENCERRADA') then
      TAppErrors.RaiseBadRequest('Somente eleições encerradas podem iniciar a apuração.');

    Conn.StartTransaction;
    Try
      if not TEleicaoAdminAPIDao.IniciarApuracao(Conn, AIdEmpresa, Eleicao.IdEleicao) then
      TAppErrors.RaiseBadRequest('Não foi possível iniciar a apuração.');

      //auditoria
      TEleicaoAuditoriaAPIService.RegistrarEvento(Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
                                  AUDITORIA_APURACAO_INICIADA, AUDITORIA_ORIGEM_ADMIN, True,
                                  'Apuração iniciada pelo administrador.',AIP, AUserAgent);
    Conn.Commit;
    except
      if Conn.InTransaction then
      Conn.Rollback;
      raise;
    End;

  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoAdminAPIService.FinalizarApuracao(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const AIP, AUserAgent: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao), 'EM_APURACAO') then
      TAppErrors.RaiseBadRequest('Somente eleições em apuração podem ser finalizadas.');

    Conn.StartTransaction;
    Try
      if not TEleicaoAdminAPIDao.FinalizarApuracao(Conn, AIdEmpresa, Eleicao.IdEleicao) then
      TAppErrors.RaiseBadRequest('Não foi possível finalizar a apuração.');

      //auditoria
      TEleicaoAuditoriaAPIService.RegistrarEvento(Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
                            AUDITORIA_APURACAO_FINALIZADA, AUDITORIA_ORIGEM_ADMIN, True,
                            'Apuração finalizada pelo administrador.',AIP, AUserAgent);
      Conn.Commit;
    except
      if Conn.InTransaction then
      Conn.Rollback;
      raise;
    End;

  finally
    Conn.Free;
  end;
end;

class function TEleicaoAdminAPIService.BuscarResultado(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer
): TEleicaoAdminResultadoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
  Resumo: TEleicaoAdminResultadoResumo;
  ListaDAO: TEleicaoAdminResultadoLista;
  ItemDAO: TEleicaoAdminResultadoChapa;
  Item: TEleicaoAdminResultadoChapaResult;
begin
  Result := Default(TEleicaoAdminResultadoResult);
  Result.Chapas := TList<TEleicaoAdminResultadoChapaResult>.Create;

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleição não informada.');

    if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
        TAppErrors.RaiseNotFound('Eleição não encontrada.');

      if not (SameText(Trim(Eleicao.Situacao), 'APURADA') or SameText(Trim(Eleicao.Situacao), 'PUBLICADA')) then
        TAppErrors.RaiseBadRequest('O resultado somente pode ser consultado após a apuração.');

      Result.IdEleicao := Eleicao.IdEleicao;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Situacao := Eleicao.Situacao;

      if not TEleicaoAdminAPIDao.BuscarResumoResultado(Conn, AIdEmpresa, Eleicao.IdEleicao, Resumo) then
        TAppErrors.RaiseBadRequest('Não foi possível carregar o resultado da eleição.');

      Result.TotalVotos := Resumo.TotalVotos;
      Result.VotosValidos := Resumo.VotosValidos;
      Result.VotosBrancos := Resumo.VotosBrancos;
      Result.VotosNulos := Resumo.VotosNulos;

      ListaDAO := TEleicaoAdminResultadoLista.Create;
      try
        TEleicaoAdminAPIDao.BuscarResultadoChapas(Conn, AIdEmpresa, Eleicao.IdEleicao, ListaDAO);

        for ItemDAO in ListaDAO do
        begin
          Item := Default(TEleicaoAdminResultadoChapaResult);

          Item.IdChapa := ItemDAO.IdChapa;
          Item.Numero := ItemDAO.Numero;
          Item.Nome := ItemDAO.Nome;
          Item.QuantidadeVotos := ItemDAO.QuantidadeVotos;

          if Result.VotosValidos > 0 then
            Item.Percentual := (Item.QuantidadeVotos / Result.VotosValidos) * 100
          else
            Item.Percentual := 0;

          Result.Chapas.Add(Item);
        end;
      finally
        ListaDAO.Free;
      end;

    finally
      Conn.Free;
    end;

  except
    Result.Chapas.Free;
    Result.Chapas := nil;
    raise;
  end;
end;

class procedure TEleicaoAdminAPIService.PublicarResultado(
  const ASlug: string;
  const AIdUsuario: Integer;
  const AIdEmpresa: Integer;
  const AIP, AUserAgent: string
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoAdminDados;
begin
  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn, Trim(ASlug), AIdEmpresa, Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao), 'APURADA') then
      TAppErrors.RaiseBadRequest('Somente eleições apuradas podem ter o resultado publicado.');

    if not TEleicaoAdminAPIDao.PublicarResultado(Conn, AIdEmpresa, Eleicao.IdEleicao) then
      TAppErrors.RaiseBadRequest('Não foi possível publicar o resultado da eleição.');

    //auditoria
    TEleicaoAuditoriaAPIService.RegistrarEvento(Conn, AIdEmpresa, Eleicao.IdEleicao, AIdUsuario,
    AUDITORIA_RESULTADO_PUBLICADO, AUDITORIA_ORIGEM_ADMIN, True,
    'Resultado publicado pelo administrador.',AIP, AUserAgent);
  finally
    Conn.Free;
  end;
end;


class procedure TEleicaoAdminAPIService.VerificarAberturaAutomatica(
                                  const AIdEmpresa, AIdEleicao: Integer);
var
AConn: TUniConnection;
Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  AConn := TDatabaseConnection.NewConnection(Config.Database);

  Try
    TEleicaoAdminAPIDao.AbrirAutomaticamente(AConn,AIdEmpresa, AIdEleicao);
  finally
    AConn.Free;
  end;
end;

class procedure TEleicaoAdminAPIService.VerificarEncerramentoAutomatico(
  const AIdEmpresa, AIdEleicao: Integer);
var
AConn: TUniConnection;
Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  AConn := TDatabaseConnection.NewConnection(Config.Database);

  Try
    TEleicaoAdminAPIDao.EncerrarAutomaticamente(AConn,AIdEmpresa, AIdEleicao);
  finally
    AConn.Free;
  end;
end;

end.
