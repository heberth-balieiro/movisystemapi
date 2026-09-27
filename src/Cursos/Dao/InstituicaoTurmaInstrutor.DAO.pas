unit InstituicaoTurmaInstrutor.DAO;

interface

uses
  Uni,
  InstituicaoTurmaInstrutor.Model;

type
  TInstituicaoTurmaInstrutorDAO = class
  private
    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoTurmaInstrutorItem; static;

  public
    class function TurmaExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Boolean; static;

    class function InstrutorAtivoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInstrutor: Int64
    ): Boolean; static;

    class function VinculoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64
    ): Boolean; static;

    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): TInstituicaoTurmaInstrutorLista; static;

    class procedure Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ); static;

    class procedure AtualizarPrincipal(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ); static;

    class procedure Excluir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInstrutor: Int64
    ); static;
  end;

implementation

class function TInstituicaoTurmaInstrutorDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoTurmaInstrutorItem;
begin
  Result := TInstituicaoTurmaInstrutorItem.Create;

  Result.IdInstrutor :=
    AQry.FieldByName('id_instrutor').AsLargeInt;

  Result.InstrutorNome :=
    AQry.FieldByName('instrutor_nome').AsString;

  Result.InstrutorEmail :=
    AQry.FieldByName('instrutor_email').AsString;

  Result.InstrutorTelefone :=
    AQry.FieldByName('instrutor_telefone').AsString;

  Result.InstrutorSituacao :=
    AQry.FieldByName('instrutor_situacao').AsString;

  Result.Principal :=
    AQry.FieldByName('principal').AsBoolean;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;
end;

class function TInstituicaoTurmaInstrutorDAO.TurmaExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdTurma <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM turma ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_turma ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaInstrutorDAO.InstrutorAtivoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInstrutor: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdInstrutor <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_instrutor ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaInstrutorDAO.VinculoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM turma_instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id_instrutor = :id_instrutor ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaInstrutorDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): TInstituicaoTurmaInstrutorLista;
var
  Qry: TUniQuery;
begin
  Result := TInstituicaoTurmaInstrutorLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'ti.id_instrutor, ' +
        'i.nome AS instrutor_nome, ' +
        'i.email AS instrutor_email, ' +
        'i.telefone AS instrutor_telefone, ' +
        'i.situacao AS instrutor_situacao, ' +
        'ti.principal, ' +
        'ti.criado_em ' +
        'FROM turma_instrutor ti ' +
        'INNER JOIN instrutor i ' +
        '  ON i.id_instituicao = ti.id_instituicao ' +
        ' AND i.id = ti.id_instrutor ' +
        'WHERE ti.id_instituicao = :id_instituicao ' +
        'AND ti.id_turma = :id_turma ' +
        'ORDER BY ti.principal DESC, i.nome';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_turma').AsLargeInt :=
        AIdTurma;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(
          MapearItem(Qry)
        );

        Qry.Next;
      end;

    except
      Result.Free;
      raise;
    end;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaInstrutorDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO turma_instrutor (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_instrutor, ' +
      'principal' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_instrutor, ' +
      ':principal' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ParamByName('principal').AsBoolean :=
      APrincipal;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaInstrutorDAO.AtualizarPrincipal(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64;
  const APrincipal: Boolean
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE turma_instrutor SET ' +
      'principal = :principal ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id_instrutor = :id_instrutor';

    Qry.ParamByName('principal').AsBoolean :=
      APrincipal;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaInstrutorDAO.Excluir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInstrutor: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM turma_instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id_instrutor = :id_instrutor';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
