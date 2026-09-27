unit InstituicaoPresencaQr.DAO;

interface

uses
  Uni;

type
  TParticipanteQrInfo = record
    Encontrado: Boolean;
    IdParticipante: Int64;
    Nome: string;
    CpfMascarado: string;
    Matricula: string;
  end;

  TInscricaoQrInfo = record
    Encontrada: Boolean;
    IdInscricao: Int64;
    Situacao: string;
  end;

  TInstituicaoPresencaQrDAO = class
  public
    class function BuscarParticipante(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigoPublico: string
    ): TParticipanteQrInfo; static;

    class function BuscarInscricaoAprovada(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdParticipante: Int64
    ): TInscricaoQrInfo; static;

    class function EncontroValido(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro: Int64
    ): Boolean; static;

    class procedure RegistrarPresenca(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            AIdInscricao,
            ARegistradoPor: Int64
    ); static;
  end;

implementation

class function TInstituicaoPresencaQrDAO.BuscarParticipante(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigoPublico: string
): TParticipanteQrInfo;
var
  Qry: TUniQuery;
begin
  Result := Default(TParticipanteQrInfo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, nome, cpf_mascarado, matricula ' +
      'FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND codigo_publico = :codigo_publico ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('codigo_publico').AsString := ACodigoPublico;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado := True;
    Result.IdParticipante := Qry.FieldByName('id').AsLargeInt;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.CpfMascarado := Qry.FieldByName('cpf_mascarado').AsString;
    Result.Matricula := Qry.FieldByName('matricula').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPresencaQrDAO.BuscarInscricaoAprovada(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdParticipante: Int64
): TInscricaoQrInfo;
var
  Qry: TUniQuery;
begin
  Result := Default(TInscricaoQrInfo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, situacao ' +
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id_participante = :id_participante ' +
      'AND situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'') ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_participante').AsLargeInt := AIdParticipante;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrada := True;
    Result.IdInscricao := Qry.FieldByName('id').AsLargeInt;
    Result.Situacao := Qry.FieldByName('situacao').AsString;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPresencaQrDAO.EncontroValido(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM turma_encontro ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id = :id_encontro ' +
      'AND situacao <> ''CANCELADO'' LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_encontro').AsLargeInt := AIdEncontro;
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPresencaQrDAO.RegistrarPresenca(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        AIdInscricao,
        ARegistradoPor: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO presenca (' +
      'id_instituicao, id_turma, id_encontro, id_inscricao, ' +
      'situacao, checkin_em, registrado_por' +
      ') VALUES (' +
      ':id_instituicao, :id_turma, :id_encontro, :id_inscricao, ' +
      '''PRESENTE'', CURRENT_TIMESTAMP(3), :registrado_por' +
      ') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'situacao = ''PRESENTE'', ' +
      'checkin_em = COALESCE(checkin_em, VALUES(checkin_em)), ' +
      'registrado_por = VALUES(registrado_por), ' +
      'justificativa = NULL';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id_encontro').AsLargeInt := AIdEncontro;
    Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
    Qry.ParamByName('registrado_por').AsLargeInt := ARegistradoPor;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
