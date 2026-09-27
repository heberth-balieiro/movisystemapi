unit InstituicaoInscricaoAprovacao.Service;

interface

uses
  InstituicaoInscricao.Model;

type
  TInstituicaoInscricaoAprovacaoService = class
  public
    class function Aprovar(
      const AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao: Int64
    ): TInstituicaoInscricaoItem; static;

    class function Rejeitar(
      const AIdInstituicao,
            AIdInscricao,
            AUsuarioInstituicao: Int64;
      const AMotivo: string
    ): TInstituicaoInscricaoItem; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoInscricao.DAO,
  InstituicaoInscricaoAprovacao.DAO;

class function TInstituicaoInscricaoAprovacaoService.Aprovar(
  const AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao: Int64
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Solicitacao: TSolicitacaoInscricaoLock;
  Turma: TTurmaAprovacaoLock;
  Ocupados: Integer;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Usuário da instituição não identificado.');

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest('Inscrição inválida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Solicitacao := TInstituicaoInscricaoAprovacaoDAO.BloquearSolicitacao(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

      if not Solicitacao.Encontrada then
        TAppErrors.RaiseBadRequest('Inscrição não encontrada.');

      if not SameText(Solicitacao.Origem, 'PUBLICA') then
        TAppErrors.RaiseBadRequest(
          'Somente solicitações de inscrição realizadas pelo participante podem ser aprovadas por esta operação.'
        );

      if not SameText(Solicitacao.Situacao, 'INSCRITO') then
        TAppErrors.RaiseBadRequest(
          'Esta solicitação não está aguardando aprovação.'
        );

      Turma := TInstituicaoInscricaoAprovacaoDAO.BloquearTurma(
        Conn,
        AIdInstituicao,
        Solicitacao.IdTurma
      );

      if not Turma.Encontrada then
        TAppErrors.RaiseBadRequest('Turma não encontrada.');

      if SameText(Turma.Situacao, 'CANCELADA') or
         SameText(Turma.Situacao, 'ENCERRADA') then
        TAppErrors.RaiseBadRequest(
          'Não é possível aprovar inscrição para turma cancelada ou encerrada.'
        );

      if Turma.TemLimiteParticipantes then
      begin
        Ocupados := TInstituicaoInscricaoAprovacaoDAO.ContarOcupados(
          Conn,
          AIdInstituicao,
          Solicitacao.IdTurma
        );

        if Ocupados >= Turma.LimiteParticipantes then
          TAppErrors.RaiseBadRequest(
            'A turma atingiu o limite de participantes confirmados.'
          );
      end;

      TInstituicaoInscricaoDAO.AlterarSituacao(
        Conn,
        AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao,
        'CONFIRMADO',
        ''
      );

      TInstituicaoInscricaoDAO.InserirHistorico(
        Conn,
        AIdInstituicao,
        Solicitacao.IdTurma,
        AIdInscricao,
        AUsuarioInstituicao,
        'INSCRITO',
        'CONFIRMADO',
        'Solicitação de inscrição aprovada pela instituição.'
      );

      Result := TInstituicaoInscricaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

      if Result = nil then
        raise Exception.Create(
          'Inscrição aprovada, mas não foi possível recuperar os dados.'
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

class function TInstituicaoInscricaoAprovacaoService.Rejeitar(
  const AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao: Int64;
  const AMotivo: string
): TInstituicaoInscricaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Solicitacao: TSolicitacaoInscricaoLock;
  Motivo: string;
begin
  Result := nil;
  Motivo := Trim(AMotivo);

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Usuário da instituição não identificado.');

  if AIdInscricao <= 0 then
    TAppErrors.RaiseBadRequest('Inscrição inválida.');

  if Motivo.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o motivo da rejeição.');

  if Length(Motivo) > 500 then
    TAppErrors.RaiseBadRequest('O motivo deve possuir no máximo 500 caracteres.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      Solicitacao := TInstituicaoInscricaoAprovacaoDAO.BloquearSolicitacao(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

      if not Solicitacao.Encontrada then
        TAppErrors.RaiseBadRequest('Inscrição não encontrada.');

      if not SameText(Solicitacao.Origem, 'PUBLICA') then
        TAppErrors.RaiseBadRequest(
          'Somente solicitações de inscrição realizadas pelo participante podem ser rejeitadas por esta operação.'
        );

      if not SameText(Solicitacao.Situacao, 'INSCRITO') then
        TAppErrors.RaiseBadRequest(
          'Esta solicitação não está aguardando aprovação.'
        );

      TInstituicaoInscricaoDAO.AlterarSituacao(
        Conn,
        AIdInstituicao,
        AIdInscricao,
        AUsuarioInstituicao,
        'CANCELADO',
        Motivo
      );

      TInstituicaoInscricaoDAO.InserirHistorico(
        Conn,
        AIdInstituicao,
        Solicitacao.IdTurma,
        AIdInscricao,
        AUsuarioInstituicao,
        'INSCRITO',
        'CANCELADO',
        Motivo
      );

      Result := TInstituicaoInscricaoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdInscricao
      );

      if Result = nil then
        raise Exception.Create(
          'Inscrição rejeitada, mas não foi possível recuperar os dados.'
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

end.
