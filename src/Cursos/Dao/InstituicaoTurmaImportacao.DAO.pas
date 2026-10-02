unit InstituicaoTurmaImportacao.DAO;

interface

uses
  Uni;

type
  TInstituicaoTurmaImportacaoDAO = class
  public
    class function TurmaEhSomenteCertificacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Boolean; static;

    class function BuscarParticipantePorCpfHash(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACpfHash: string
    ): Int64; static;

    class function CriarImportacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AImportadoPor: Int64;
      const ANomeArquivo: string;
      const ATotalRegistros: Integer
    ): Int64; static;

    class procedure RegistrarErro(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdImportacao: Int64;
      const ALinha: Integer;
      const AMensagem: string
    ); static;

    class procedure AtualizarTotais(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdImportacao: Int64;
      const AImportados,
            AErros: Integer
    ); static;

    class procedure ConcluirInscricaoCertificacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao,
            AAtualizadoPor: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoTurmaImportacaoDAO.TurmaEhSomenteCertificacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM turma ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_turma ' +
      'AND tipo_fluxo = ''CERTIFICACAO'' ' +
      'LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaImportacaoDAO.BuscarParticipantePorCpfHash(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACpfHash: string
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id FROM participante ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND cpf_hash_busca = :cpf_hash ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('cpf_hash').AsString := ACpfHash;
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaImportacaoDAO.CriarImportacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AImportadoPor: Int64;
  const ANomeArquivo: string;
  const ATotalRegistros: Integer
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_importacao ' +
      '(id_instituicao,id_turma,nome_arquivo,total_registros,importado_por) ' +
      'VALUES (:id_instituicao,:id_turma,:nome_arquivo,:total_registros,:importado_por)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('nome_arquivo').AsString := Copy(Trim(ANomeArquivo), 1, 255);
    Qry.ParamByName('total_registros').AsInteger := ATotalRegistros;
    Qry.ParamByName('importado_por').AsLargeInt := AImportadoPor;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaImportacaoDAO.RegistrarErro(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdImportacao: Int64;
  const ALinha: Integer;
  const AMensagem: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_importacao_erro ' +
      '(id_instituicao,id_importacao,linha,mensagem) ' +
      'VALUES (:id_instituicao,:id_importacao,:linha,:mensagem)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_importacao').AsLargeInt := AIdImportacao;
    Qry.ParamByName('linha').AsInteger := ALinha;
    Qry.ParamByName('mensagem').AsString := Copy(Trim(AMensagem), 1, 500);
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaImportacaoDAO.AtualizarTotais(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdImportacao: Int64;
  const AImportados,
        AErros: Integer
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE turma_importacao SET ' +
      'total_importados = :importados, total_erros = :erros ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id';
    Qry.ParamByName('importados').AsInteger := AImportados;
    Qry.ParamByName('erros').AsInteger := AErros;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdImportacao;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaImportacaoDAO.ConcluirInscricaoCertificacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao,
        AAtualizadoPor: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE inscricao SET ' +
      'situacao = ''CONCLUIDO'', ' +
      'confirmado_em = COALESCE(confirmado_em,CURRENT_TIMESTAMP(3)), ' +
      'concluido_em = COALESCE(concluido_em,CURRENT_TIMESTAMP(3)), ' +
      'percentual_presenca = NULL, percentual_progresso = 100, ' +
      'elegivel_certificado = 1, atualizado_por = :usuario ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id';
    Qry.ParamByName('usuario').AsLargeInt := AAtualizadoPor;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AIdInscricao;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
