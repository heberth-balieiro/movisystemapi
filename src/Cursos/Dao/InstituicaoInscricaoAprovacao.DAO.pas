unit InstituicaoInscricaoAprovacao.DAO;

interface

uses
  Uni;

type
  TSolicitacaoInscricaoLock = record
    Encontrada: Boolean;
    IdTurma: Int64;
    Origem: string;
    Situacao: string;
  end;

  TTurmaAprovacaoLock = record
    Encontrada: Boolean;
    Situacao: string;
    TemLimiteParticipantes: Boolean;
    LimiteParticipantes: Integer;
  end;

  TInstituicaoInscricaoAprovacaoDAO = class
  public
    class function BloquearSolicitacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TSolicitacaoInscricaoLock; static;

    class function BloquearTurma(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): TTurmaAprovacaoLock; static;

    class function ContarOcupados(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Integer; static;
  end;

implementation

class function TInstituicaoInscricaoAprovacaoDAO.BloquearSolicitacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TSolicitacaoInscricaoLock;
var
  Qry: TUniQuery;
begin
  Result := Default(TSolicitacaoInscricaoLock);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id_turma, origem, situacao ' +
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id ' +
      'FOR UPDATE';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdInscricao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrada := True;
    Result.IdTurma := Qry.FieldByName('id_turma').AsLargeInt;
    Result.Origem := Qry.FieldByName('origem').AsString;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoAprovacaoDAO.BloquearTurma(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): TTurmaAprovacaoLock;
var
  Qry: TUniQuery;
begin
  Result := Default(TTurmaAprovacaoLock);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT situacao, limite_participantes ' +
      'FROM turma ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id_turma ' +
      'FOR UPDATE';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrada := True;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
    Result.TemLimiteParticipantes := not Qry.FieldByName('limite_participantes').IsNull;

    if Result.TemLimiteParticipantes then
      Result.LimiteParticipantes := Qry.FieldByName('limite_participantes').AsInteger;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoInscricaoAprovacaoDAO.ContarOcupados(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Integer;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

end.
