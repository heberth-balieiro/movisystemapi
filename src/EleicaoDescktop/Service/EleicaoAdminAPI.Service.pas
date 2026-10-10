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

  TEleicaoAdminResultadoOpcaoResult = record
    IdOpcao: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoAdminResultadoQuestaoResult = class
  public
    IdQuestao: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TList<TEleicaoAdminResultadoOpcaoResult>;

    constructor Create;
    destructor Destroy; override;
  end;

  TEleicaoAdminResultadoResult = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Situacao: string;
    Operacao: string;

    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;

    Chapas: TList<TEleicaoAdminResultadoChapaResult>;
    Questoes: TObjectList<TEleicaoAdminResultadoQuestaoResult>;
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

{ TEleicaoAdminResultadoQuestaoResult }

constructor TEleicaoAdminResultadoQuestaoResult.Create;
begin
  inherited Create;
  Opcoes := TList<TEleicaoAdminResultadoOpcaoResult>.Create;
end;

destructor TEleicaoAdminResultadoQuestaoResult.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

{ TEleicaoAdminAPIService }

class function TEleicaoAdminAPIService.Login(
  const ASlug: string;
  const AEmail: string;
  const ASenha: string
): TEleicaoAdminLoginResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Usuario: TEleicaoAdminUsuario;
  Roles: TArray<string>;
begin
  Result := Default(TEleicaoAdminLoginResult);

  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if Trim(AEmail).IsEmpty then
    TAppErrors.RaiseBadRequest('E-mail não informado.');

  if Trim(ASenha).IsEmpty then
    TAppErrors.RaiseBadRequest('Senha não informada.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarUsuarioAdmin(Conn,Trim(ASlug),Trim(AEmail),Usuario) then
      TAppErrors.RaiseUnauthorized('Usuário ou senha inválidos.');

    if not VerifySenha(ASenha,Usuario.SenhaHash) then
      TAppErrors.RaiseUnauthorized('Email ou senha inválidos.');

    if not (SameText(Trim(Usuario.Perfil),'ADMIN') or
            SameText(Trim(Usuario.Perfil),'COMISSAO')) then
      TAppErrors.RaiseUnauthorized('Usuário não autorizado para acessar o painel eleitoral.');

    SetLength(Roles,1);
    Roles[0] := UpperCase(Trim(Usuario.Perfil));

    Result.Token := TAppJWT.GerarToken(
      Config.JWT,
      Usuario.IdUsuario,
      Usuario.IdEmpresa,
      Roles,
      Trim(ASlug),
      Config.JWT.TtlAdminMinutos
    );
    Result.Nome := Usuario.Nome;
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
  Result.Evolucao := TList<TEleicaoAdminPainelEvolucao>.Create;

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleição não informada.');

    if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
        TAppErrors.RaiseNotFound('Eleição não encontrada.');

      Result.IdEleicao := Eleicao.IdEleicao;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Situacao := Eleicao.Situacao;
      Result.DataHoraInicio := Eleicao.DataHoraInicio;
      Result.DataHoraFim := Eleicao.DataHoraFim;
      Result.abertura := Eleicao.abertura;
      Result.encerramento := Eleicao.encerramento;

      if not TEleicaoAdminAPIDao.BuscarResumoPainel(
        Conn,AIdEmpresa,Eleicao.IdEleicao,ResumoDAO
      ) then
        TAppErrors.RaiseBadRequest('Não foi possível carregar o resumo da eleição.');

      Result.Resumo.TotalEleitores := ResumoDAO.TotalEleitores;
      Result.Resumo.TotalVotantes := ResumoDAO.TotalVotantes;
      Result.Resumo.TotalNaoVotantes :=
        Result.Resumo.TotalEleitores - Result.Resumo.TotalVotantes;

      if Result.Resumo.TotalNaoVotantes < 0 then
        Result.Resumo.TotalNaoVotantes := 0;

      if Result.Resumo.TotalEleitores > 0 then
        Result.Resumo.PercentualParticipacao :=
          (Result.Resumo.TotalVotantes / Result.Resumo.TotalEleitores) * 100
      else
        Result.Resumo.PercentualParticipacao := 0;

      ListaDAO := TEleicaoAdminAPIListEvolucao.Create;

      TEleicaoAdminAPIService.VerificarAberturaAutomatica(AIdEmpresa,Eleicao.IdEleicao);
      TEleicaoAdminAPIService.VerificarEncerramentoAutomatico(AIdEmpresa,Eleicao.IdEleicao);

      try
        TEleicaoAdminAPIDao.BuscarEvolucaoVotacao(
          Conn,AIdEmpresa,Eleicao.IdEleicao,
          Eleicao.DataHoraInicio,Eleicao.DataHoraFim,ListaDAO
        );

        Acumulado := 0;
        for ItemDAO in ListaDAO do
        begin
          Inc(Acumulado,ItemDAO.Quantidade);
          Item := Default(TEleicaoAdminPainelEvolucao);
          Item.Hora := ItemDAO.Hora;
          Item.Quantidade := ItemDAO.Quantidade;
          Item.Acumulado := Acumulado;
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
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    TAppErrors.RaiseUnauthorized('Acesso não autorizado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao),'ABERTA') then
      TAppErrors.RaiseBadRequest('Somente eleições abertas podem ser encerradas.');

    Conn.StartTransaction;
    try
      if not TEleicaoAdminAPIDao.EncerrarEleicao(Conn,AIdEmpresa,Eleicao.IdEleicao) then
        TAppErrors.RaiseBadRequest('Não foi possível encerrar a eleição.');

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn,AIdEmpresa,Eleicao.IdEleicao,AIdUsuario,
        AUDITORIA_ELEICAO_ENCERRADA,AUDITORIA_ORIGEM_ADMIN,True,
        'Eleição encerrada pelo administrador.',AIP,AUserAgent
      );
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
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao),'ENCERRADA') then
      TAppErrors.RaiseBadRequest('Somente eleições encerradas podem iniciar a apuração.');

    Conn.StartTransaction;
    try
      if not TEleicaoAdminAPIDao.IniciarApuracao(Conn,AIdEmpresa,Eleicao.IdEleicao) then
        TAppErrors.RaiseBadRequest('Não foi possível iniciar a apuração.');

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn,AIdEmpresa,Eleicao.IdEleicao,AIdUsuario,
        AUDITORIA_APURACAO_INICIADA,AUDITORIA_ORIGEM_ADMIN,True,
        'Apuração iniciada pelo administrador.',AIP,AUserAgent
      );
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
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao),'EM_APURACAO') then
      TAppErrors.RaiseBadRequest('Somente eleições em apuração podem ser finalizadas.');

    Conn.StartTransaction;
    try
      if not TEleicaoAdminAPIDao.FinalizarApuracao(Conn,AIdEmpresa,Eleicao.IdEleicao) then
        TAppErrors.RaiseBadRequest('Não foi possível finalizar a apuração.');

      TEleicaoAuditoriaAPIService.RegistrarEvento(
        Conn,AIdEmpresa,Eleicao.IdEleicao,AIdUsuario,
        AUDITORIA_APURACAO_FINALIZADA,AUDITORIA_ORIGEM_ADMIN,True,
        'Apuração finalizada pelo administrador.',AIP,AUserAgent
      );
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
  ResumoPainel: TEleicaoAdminResumo;

  ListaChapasDAO: TEleicaoAdminResultadoLista;
  ItemChapaDAO: TEleicaoAdminResultadoChapa;
  ItemChapa: TEleicaoAdminResultadoChapaResult;

  ListaQuestoesDAO: TEleicaoAdminResultadoQuestoes;
  QuestaoDAO: TEleicaoAdminResultadoQuestao;
  OpcaoDAO: TEleicaoAdminResultadoOpcao;
  Questao: TEleicaoAdminResultadoQuestaoResult;
  Opcao: TEleicaoAdminResultadoOpcaoResult;
begin
  Result := Default(TEleicaoAdminResultadoResult);
  Result.Chapas := TList<TEleicaoAdminResultadoChapaResult>.Create;
  Result.Questoes := TObjectList<TEleicaoAdminResultadoQuestaoResult>.Create(True);

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleicao nao informada.');

    if (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
      TAppErrors.RaiseUnauthorized('Acesso nao autorizado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
        TAppErrors.RaiseNotFound('Eleicao nao encontrada.');

      if not (SameText(Trim(Eleicao.Situacao),'APURADA') or
              SameText(Trim(Eleicao.Situacao),'PUBLICADA')) then
        TAppErrors.RaiseBadRequest(
          'O resultado somente pode ser consultado apos a apuracao.'
        );

      Result.IdEleicao := Eleicao.IdEleicao;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Situacao := Eleicao.Situacao;
      Result.Operacao := Eleicao.Operacao;

      if SameText(Eleicao.Operacao,'ASSEMBLEIA') then
      begin
        if not TEleicaoAdminAPIDao.BuscarResumoPainel(
          Conn,AIdEmpresa,Eleicao.IdEleicao,ResumoPainel
        ) then
          TAppErrors.RaiseBadRequest(
            'Nao foi possivel carregar o resumo da assembleia.'
          );

        Result.TotalVotos := ResumoPainel.TotalVotantes;
        Result.VotosValidos := 0;
        Result.VotosBrancos := 0;
        Result.VotosNulos := 0;

        ListaQuestoesDAO := TEleicaoAdminResultadoQuestoes.Create(True);
        try
          TEleicaoAdminAPIDao.BuscarResultadoQuestoes(
            Conn,AIdEmpresa,Eleicao.IdEleicao,ListaQuestoesDAO
          );

          for QuestaoDAO in ListaQuestoesDAO do
          begin
            Questao := TEleicaoAdminResultadoQuestaoResult.Create;
            Questao.IdQuestao := QuestaoDAO.IdQuestao;
            Questao.Ordem := QuestaoDAO.Ordem;
            Questao.Titulo := QuestaoDAO.Titulo;
            Questao.TotalVotos := QuestaoDAO.TotalVotos;

            for OpcaoDAO in QuestaoDAO.Opcoes do
            begin
              Opcao := Default(TEleicaoAdminResultadoOpcaoResult);
              Opcao.IdOpcao := OpcaoDAO.IdOpcao;
              Opcao.Ordem := OpcaoDAO.Ordem;
              Opcao.Descricao := OpcaoDAO.Descricao;
              Opcao.QuantidadeVotos := OpcaoDAO.QuantidadeVotos;

              if Questao.TotalVotos > 0 then
                Opcao.Percentual :=
                  (Opcao.QuantidadeVotos / Questao.TotalVotos) * 100
              else
                Opcao.Percentual := 0;

              Questao.Opcoes.Add(Opcao);
            end;

            Result.Questoes.Add(Questao);
          end;
        finally
          ListaQuestoesDAO.Free;
        end;
      end
      else
      begin
        if not TEleicaoAdminAPIDao.BuscarResumoResultado(
          Conn,AIdEmpresa,Eleicao.IdEleicao,Resumo
        ) then
          TAppErrors.RaiseBadRequest(
            'Nao foi possivel carregar o resultado da eleicao.'
          );

        Result.TotalVotos := Resumo.TotalVotos;
        Result.VotosValidos := Resumo.VotosValidos;
        Result.VotosBrancos := Resumo.VotosBrancos;
        Result.VotosNulos := Resumo.VotosNulos;

        ListaChapasDAO := TEleicaoAdminResultadoLista.Create;
        try
          TEleicaoAdminAPIDao.BuscarResultadoChapas(
            Conn,AIdEmpresa,Eleicao.IdEleicao,ListaChapasDAO
          );

          for ItemChapaDAO in ListaChapasDAO do
          begin
            ItemChapa := Default(TEleicaoAdminResultadoChapaResult);
            ItemChapa.IdChapa := ItemChapaDAO.IdChapa;
            ItemChapa.Numero := ItemChapaDAO.Numero;
            ItemChapa.Nome := ItemChapaDAO.Nome;
            ItemChapa.QuantidadeVotos := ItemChapaDAO.QuantidadeVotos;

            if Result.VotosValidos > 0 then
              ItemChapa.Percentual :=
                (ItemChapa.QuantidadeVotos / Result.VotosValidos) * 100
            else
              ItemChapa.Percentual := 0;

            Result.Chapas.Add(ItemChapa);
          end;
        finally
          ListaChapasDAO.Free;
        end;
      end;
    finally
      Conn.Free;
    end;
  except
    Result.Chapas.Free;
    Result.Chapas := nil;
    Result.Questoes.Free;
    Result.Questoes := nil;
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
    if not TEleicaoAdminAPIDao.BuscarEleicao(Conn,Trim(ASlug),AIdEmpresa,Eleicao) then
      TAppErrors.RaiseNotFound('Eleição não encontrada.');

    if not SameText(Trim(Eleicao.Situacao),'APURADA') then
      TAppErrors.RaiseBadRequest('Somente eleições apuradas podem ter o resultado publicado.');

    if not TEleicaoAdminAPIDao.PublicarResultado(Conn,AIdEmpresa,Eleicao.IdEleicao) then
      TAppErrors.RaiseBadRequest('Não foi possível publicar o resultado da eleição.');

    TEleicaoAuditoriaAPIService.RegistrarEvento(
      Conn,AIdEmpresa,Eleicao.IdEleicao,AIdUsuario,
      AUDITORIA_RESULTADO_PUBLICADO,AUDITORIA_ORIGEM_ADMIN,True,
      'Resultado publicado pelo administrador.',AIP,AUserAgent
    );
  finally
    Conn.Free;
  end;
end;

class procedure TEleicaoAdminAPIService.VerificarAberturaAutomatica(
  const AIdEmpresa, AIdEleicao: Integer
);
var
  AConn: TUniConnection;
  Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  AConn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoAdminAPIDao.AbrirAutomaticamente(AConn,AIdEmpresa,AIdEleicao);
  finally
    AConn.Free;
  end;
end;

class procedure TEleicaoAdminAPIService.VerificarEncerramentoAutomatico(
  const AIdEmpresa, AIdEleicao: Integer
);
var
  AConn: TUniConnection;
  Config: TAppApiConfig;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  AConn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TEleicaoAdminAPIDao.EncerrarAutomaticamente(AConn,AIdEmpresa,AIdEleicao);
  finally
    AConn.Free;
  end;
end;

end.
