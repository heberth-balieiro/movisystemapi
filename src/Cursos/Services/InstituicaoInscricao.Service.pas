unit InstituicaoInscricao.Service;

interface

uses
  InstituicaoInscricao.Model;

type
  TInstituicaoInscricaoService = class
  private
    class function GerarCodigoPublico: string; static;

    class procedure ValidarSituacao(
      const ASituacao: string
    ); static;

    class procedure ValidarOrigem(
      const AOrigem: string
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca: string;
      const AIdTurma,
            AIdParticipante: Int64;
      const ASituacao,
            AOrigem: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoInscricaoLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TInstituicaoInscricaoItem; static;

    class function CadastrarAdministrativa(
      const AIdInstituicao,
            AUsuarioInstituicao: Int64;
      const ADados: TInstituicaoInscricaoCadastro
    ): TInstituicaoInscricaoItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao: Int64;
      const ADados: TInstituicaoInscricaoSituacaoAlteracao
    ): TInstituicaoInscricaoItem; static;

    class function ListarHistorico(
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TInstituicaoInscricaoHistoricoLista; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoInscricao.DAO;

class function TInstituicaoInscricaoService.GerarCodigoPublico: string;
var
  Guid: TGUID;
  S: string;
begin
  CreateGUID(Guid);

  S :=
    GUIDToString(Guid);

  S :=
    StringReplace(
      S,
      '{',
      '',
      [rfReplaceAll]
    );

  S :=
    StringReplace(
      S,
      '}',
      '',
      [rfReplaceAll]
    );

  S :=
    StringReplace(
      S,
      '-',
      '',
      [rfReplaceAll]
    );

  Result :=
    Copy(
      UpperCase(S),
      1,
      26
    );
end;

class procedure TInstituicaoInscricaoService.ValidarSituacao(
  const ASituacao: string
);
begin
  if not MatchText(
    UpperCase(Trim(ASituacao)),
    [
      'INSCRITO',
      'CONFIRMADO',
      'EM_ANDAMENTO',
      'CONCLUIDO',
      'CANCELADO',
      'REPROVADO',
      'DESISTENTE'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação da inscrição inválida.'
    );
end;

class procedure TInstituicaoInscricaoService.ValidarOrigem(
  const AOrigem: string
);
begin
  if not MatchText(
    UpperCase(Trim(AOrigem)),
    [
      'PUBLICA',
      'ADMIN',
      'IMPORTACAO',
      'API'
    ]
  ) then
    TAppErrors.RaiseBadRequest(
      'Origem da inscrição inválida.'
    );
end;

class function TInstituicaoInscricaoService.Listar(
  const AIdInstituicao: Int64;
  const ABusca: string;
  const AIdTurma,
        AIdParticipante: Int64;
  const ASituacao,
        AOrigem: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoInscricaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoInscricaoFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoInscricaoFiltro
    );

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.IdTurma :=
    AIdTurma;

  Filtro.IdParticipante :=
    AIdParticipante;

  Filtro.Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  Filtro.Origem :=
    UpperCase(
      Trim(AOrigem)
    );

  Filtro.Pagina :=
    APagina;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacao(
      Filtro.Situacao
    );

  if not Filtro.Origem.IsEmpty then
    ValidarOrigem(
      Filtro.Origem
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
    Result :=
      TInstituicaoInscricaoDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInscricaoService.BuscarPorId(
  const AIdInstituicao,
        AIdInscricao: Int64
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
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
    Result :=
      TInstituicaoInscricaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Inscrição não encontrada.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInscricaoService.CadastrarAdministrativa(
  const AIdInstituicao,
        AUsuarioInstituicao: Int64;
  const ADados: TInstituicaoInscricaoCadastro
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CodigoPublico: string;
  CodigoDisponivel: Boolean;
  Tentativas: Integer;
  IdInscricao: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if ADados.IdTurma <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe uma turma válida.'
    );

  if ADados.IdParticipante <= 0 then
    TAppErrors.RaiseBadRequest(
      'Informe um participante válido.'
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
    if not TInstituicaoInscricaoDAO.TurmaExiste(
      Conn,
      AIdInstituicao,
      ADados.IdTurma
    ) then
      TAppErrors.RaiseBadRequest(
        'Turma não encontrada.'
      );

    if not TInstituicaoInscricaoDAO.ParticipanteAtivoExiste(
      Conn,
      AIdInstituicao,
      ADados.IdParticipante
    ) then
      TAppErrors.RaiseBadRequest(
        'Participante não encontrado ou inativo.'
      );

    if TInstituicaoInscricaoDAO.ParticipanteJaInscrito(
      Conn,
      AIdInstituicao,
      ADados.IdTurma,
      ADados.IdParticipante
    ) then
      TAppErrors.RaiseBadRequest(
        'O participante já possui inscrição nesta turma.'
      );

    Tentativas := 0;
    CodigoDisponivel := False;

    repeat
      Inc(Tentativas);

      CodigoPublico :=
        GerarCodigoPublico;

      CodigoDisponivel :=
        not TInstituicaoInscricaoDAO.ExisteCodigoPublico(
          Conn,
          CodigoPublico
        );

    until
      CodigoDisponivel or
      (Tentativas >= 5);

    if not CodigoDisponivel then
      raise Exception.Create(
        'Não foi possível gerar um código público único para a inscrição.'
      );

    Conn.StartTransaction;

    try
      IdInscricao :=
        TInstituicaoInscricaoDAO.Inserir(
          Conn,
          AIdInstituicao,
          AUsuarioInstituicao,
          CodigoPublico,
          'ADMIN',
          ADados
        );

      TInstituicaoInscricaoDAO.InserirHistorico(
        Conn,
        AIdInstituicao,
        ADados.IdTurma,
        IdInscricao,
        AUsuarioInstituicao,
        '',
        'INSCRITO',
        'Inscrição administrativa realizada.'
      );

      Result :=
        TInstituicaoInscricaoDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdInscricao
        );

      if Result = nil then
        raise Exception.Create(
          'Inscrição cadastrada, mas não foi possível recuperar os dados.'
        );

      Conn.Commit;

    except
      if Conn.InTransaction then
        Conn.Rollback;

      Result.Free;
      Result := nil;

      raise;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInscricaoService.AlterarSituacao(
  const AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao: Int64;
  const ADados: TInstituicaoInscricaoSituacaoAlteracao
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TInstituicaoInscricaoItem;
  SituacaoNova: string;
  ObservacaoHistorico: string;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
    );

  SituacaoNova :=
    UpperCase(
      Trim(ADados.Situacao)
    );

  ValidarSituacao(
    SituacaoNova
  );

  if Length(Trim(ADados.Observacao)) > 500 then
    TAppErrors.RaiseBadRequest(
      'A observação deve possuir no máximo 500 caracteres.'
    );

  if Length(Trim(ADados.MotivoCancelamento)) > 500 then
    TAppErrors.RaiseBadRequest(
      'O motivo do cancelamento deve possuir no máximo 500 caracteres.'
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
    Atual :=
      TInstituicaoInscricaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest(
          'Inscrição não encontrada.'
        );

      if SameText(
        Atual.Situacao,
        SituacaoNova
      ) then
      begin
        Result :=
          TInstituicaoInscricaoDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdInscricao
          );

        Exit;
      end;

      ObservacaoHistorico :=
        Trim(
          ADados.Observacao
        );

      if
        ObservacaoHistorico.IsEmpty and
        SameText(
          SituacaoNova,
          'CANCELADO'
        )
      then
        ObservacaoHistorico :=
          Trim(
            ADados.MotivoCancelamento
          );

      Conn.StartTransaction;

      try
        TInstituicaoInscricaoDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdInscricao,
          AUsuarioInstituicao,
          SituacaoNova,
          ADados.MotivoCancelamento
        );

        TInstituicaoInscricaoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          Atual.IdTurma,
          AIdInscricao,
          AUsuarioInstituicao,
          Atual.Situacao,
          SituacaoNova,
          ObservacaoHistorico
        );

        Result :=
          TInstituicaoInscricaoDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdInscricao
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar a inscrição atualizada.'
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      Atual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoInscricaoService.ListarHistorico(
  const AIdInstituicao,
        AIdInscricao: Int64
): TInstituicaoInscricaoHistoricoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Inscricao: TInstituicaoInscricaoItem;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Inscrição inválida.'
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
    Inscricao :=
      TInstituicaoInscricaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

    try
      if Inscricao = nil then
        TAppErrors.RaiseBadRequest(
          'Inscrição não encontrada.'
        );

      Result :=
        TInstituicaoInscricaoDAO.ListarHistorico(
          Conn,
          AIdInstituicao,
          AIdInscricao
        );

    finally
      Inscricao.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
