unit InstituicaoCursoInstrutor.DAO;

interface

uses
  Uni,
  InstituicaoCursoInstrutor.Model;

type
  TInstituicaoCursoInstrutorDAO = class
  private
    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoCursoInstrutorItem; static;

  public
    class function CursoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso: Int64
    ): Boolean; static;

    class function InstrutorAtivoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInstrutor: Int64
    ): Boolean; static;

    class function VinculoExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64
    ): Boolean; static;

    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso: Int64
    ): TInstituicaoCursoInstrutorLista; static;

    class procedure Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ); static;

    class procedure AtualizarPrincipal(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64;
      const APrincipal: Boolean
    ); static;

    class procedure Excluir(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso,
            AIdInstrutor: Int64
    ); static;
  end;

implementation

class function TInstituicaoCursoInstrutorDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoCursoInstrutorItem;
begin
  Result := TInstituicaoCursoInstrutorItem.Create;

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

class function TInstituicaoCursoInstrutorDAO.CursoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdCurso <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM curso ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_curso ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoInstrutorDAO.InstrutorAtivoExiste(
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

class function TInstituicaoCursoInstrutorDAO.VinculoExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso,
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
      'FROM curso_instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_curso = :id_curso ' +
      'AND id_instrutor = :id_instrutor ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.Open;

    Result := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoCursoInstrutorDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso: Int64
): TInstituicaoCursoInstrutorLista;
var
  Qry: TUniQuery;
begin
  Result := TInstituicaoCursoInstrutorLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'ci.id_instrutor, ' +
        'i.nome AS instrutor_nome, ' +
        'i.email AS instrutor_email, ' +
        'i.telefone AS instrutor_telefone, ' +
        'i.situacao AS instrutor_situacao, ' +
        'ci.principal, ' +
        'ci.criado_em ' +
        'FROM curso_instrutor ci ' +
        'INNER JOIN instrutor i ' +
        '  ON i.id_instituicao = ci.id_instituicao ' +
        ' AND i.id = ci.id_instrutor ' +
        'WHERE ci.id_instituicao = :id_instituicao ' +
        'AND ci.id_curso = :id_curso ' +
        'ORDER BY ci.principal DESC, i.nome';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_curso').AsLargeInt :=
        AIdCurso;

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

class procedure TInstituicaoCursoInstrutorDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso,
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
      'INSERT INTO curso_instrutor (' +
      'id_instituicao, ' +
      'id_curso, ' +
      'id_instrutor, ' +
      'principal' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_curso, ' +
      ':id_instrutor, ' +
      ':principal' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ParamByName('principal').AsBoolean :=
      APrincipal;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCursoInstrutorDAO.AtualizarPrincipal(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso,
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
      'UPDATE curso_instrutor SET ' +
      'principal = :principal ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_curso = :id_curso ' +
      'AND id_instrutor = :id_instrutor';

    Qry.ParamByName('principal').AsBoolean :=
      APrincipal;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoCursoInstrutorDAO.Excluir(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso,
        AIdInstrutor: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM curso_instrutor ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_curso = :id_curso ' +
      'AND id_instrutor = :id_instrutor';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.ParamByName('id_instrutor').AsLargeInt :=
      AIdInstrutor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
