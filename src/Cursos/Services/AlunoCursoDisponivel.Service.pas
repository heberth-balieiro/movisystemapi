unit AlunoCursoDisponivel.Service;

interface

uses
  AlunoCursoDisponivel.Model,
  InstituicaoInscricao.Model;

type
  TAlunoCursoDisponivelService = class
  private
    class function GerarCodigoPublico: string; static;

  public
    class function Listar(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64;
      const APagina,
            APorPagina: Integer
    ): TAlunoCursoDisponivelLista; static;

    class function Buscar(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdTurma: Int64
    ): TAlunoCursoDisponivelItem; static;

    class function AutoInscrever(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdTurma: Int64
    ): TInstituicaoInscricaoItem; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  AlunoPortal.Model,
  AlunoPortal.DAO,
  AlunoCursoDisponivel.DAO,
  InstituicaoInscricao.DAO,
  InstituicaoInscricaoAprovacao.DAO;

class function TAlunoCursoDisponivelService.GerarCodigoPublico: string;
var
  Guid: TGUID;
  S: string;
begin
  CreateGUID(Guid);
  S := GUIDToString(Guid);
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := Copy(UpperCase(S), 1, 26);
end;

class function TAlunoCursoDisponivelService.Listar(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64;
  const APagina,
        APorPagina: Integer
): TAlunoCursoDisponivelLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Pagina, PorPagina: Integer;
begin
  Pagina := APagina;
  PorPagina := APorPagina;

  if Pagina <= 0 then
    Pagina := 1;

  if PorPagina <= 0 then
    PorPagina := 20;

  if PorPagina > 100 then
    PorPagina := 100;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Aluno := TAlunoPortalDAO.BuscarContexto(
      Conn,
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
    try
      if Aluno = nil then
        TAppErrors.RaiseForbidden(
          'O usuário autenticado não possui participante ativo vinculado ao portal.'
        );

      Result := TAlunoCursoDisponivelDAO.Listar(
        Conn,
        Aluno,
        Pagina,
        PorPagina
      );
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoCursoDisponivelService.Buscar(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdTurma: Int64
): TAlunoCursoDisponivelItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
begin
  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Aluno := TAlunoPortalDAO.BuscarContexto(
      Conn,
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
    try
      if Aluno = nil then
        TAppErrors.RaiseForbidden(
          'O usuário autenticado não possui participante ativo vinculado ao portal.'
        );

      Result := TAlunoCursoDisponivelDAO.Buscar(Conn, Aluno, AIdTurma);

      if Result = nil then
        TAppErrors.RaiseBadRequest(
          'Curso/turma não está disponível para inscrição.'
        );
    finally
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TAlunoCursoDisponivelService.AutoInscrever(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdTurma: Int64
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Aluno: TAlunoContexto;
  Dados: TInstituicaoInscricaoCadastro;
  CodigoPublico: string;
  CodigoDisponivel: Boolean;
  Tentativas: Integer;
  IdInscricao: Int64;
  Turma: TTurmaAprovacaoLock;
  Ocupados: Integer;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Usuário da instituição não identificado.');

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Aluno := TAlunoPortalDAO.BuscarContexto(
      Conn,
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
    try
      if Aluno = nil then
        TAppErrors.RaiseForbidden(
          'O usuário autenticado não possui participante ativo vinculado ao portal.'
        );

      Conn.StartTransaction;
      try
        if not TAlunoCursoDisponivelDAO.BloquearTurmaDisponivel(
          Conn,
          AIdInstituicao,
          AIdTurma
        ) then
          TAppErrors.RaiseBadRequest(
            'As inscrições desta turma não estão disponíveis.'
          );

        Turma := TInstituicaoInscricaoAprovacaoDAO.BloquearTurma(
          Conn,
          AIdInstituicao,
          AIdTurma
        );

        if not Turma.Encontrada then
          TAppErrors.RaiseBadRequest('Turma não encontrada.');

        if Turma.TemLimiteParticipantes then
        begin
          Ocupados := TInstituicaoInscricaoAprovacaoDAO.ContarOcupados(
            Conn,
            AIdInstituicao,
            AIdTurma
          );

          if Ocupados >= Turma.LimiteParticipantes then
            TAppErrors.RaiseBadRequest('A turma atingiu o limite de participantes.');
        end;

        if TInstituicaoInscricaoDAO.ParticipanteJaInscrito(
          Conn,
          AIdInstituicao,
          AIdTurma,
          Aluno.IdParticipante
        ) then
          TAppErrors.RaiseBadRequest(
            'Você já possui uma inscrição nesta turma.'
          );

        Tentativas := 0;
        CodigoDisponivel := False;

        repeat
          Inc(Tentativas);
          CodigoPublico := GerarCodigoPublico;
          CodigoDisponivel := not TInstituicaoInscricaoDAO.ExisteCodigoPublico(
            Conn,
            CodigoPublico
          );
        until CodigoDisponivel or (Tentativas >= 5);

        if not CodigoDisponivel then
          raise Exception.Create(
            'Não foi possível gerar um código público único para a inscrição.'
          );

        Dados := Default(TInstituicaoInscricaoCadastro);
        Dados.IdTurma := AIdTurma;
        Dados.IdParticipante := Aluno.IdParticipante;

        IdInscricao := TInstituicaoInscricaoDAO.Inserir(
          Conn,
          AIdInstituicao,
          AIdUsuarioInstituicao,
          CodigoPublico,
          'PUBLICA',
          Dados
        );

        TInstituicaoInscricaoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdTurma,
          IdInscricao,
          AIdUsuarioInstituicao,
          '',
          'INSCRITO',
          'Solicitação de inscrição realizada pelo participante.'
        );

        if SameText(Turma.AprovacaoInscricao, 'AUTOMATICA') then
        begin
          TInstituicaoInscricaoDAO.AlterarSituacao(
            Conn,
            AIdInstituicao,
            IdInscricao,
            AIdUsuarioInstituicao,
            'CONFIRMADO',
            ''
          );

          TInstituicaoInscricaoDAO.InserirHistorico(
            Conn,
            AIdInstituicao,
            AIdTurma,
            IdInscricao,
            AIdUsuarioInstituicao,
            'INSCRITO',
            'CONFIRMADO',
            'Inscrição aprovada automaticamente conforme configuração da turma.'
          );
        end;

        Result := TInstituicaoInscricaoDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdInscricao
        );

        if Result = nil then
          raise Exception.Create(
            'Inscrição criada, mas não foi possível recuperar os dados.'
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
      Aluno.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
