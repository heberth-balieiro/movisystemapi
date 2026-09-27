unit InstituicaoDashboard.DAO;

interface

uses
  Uni;

type
  TInstituicaoDashboardDados = record
    Cursos: Integer;
    Participantes: Integer;
    Turmas: Integer;
    Certificados: Integer;
    EmAndamento: Integer;
    Concluidos: Integer;
    HorasCapacitacao: Double;
  end;

  TInstituicaoDashboardDAO = class
  public
    class function Buscar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TInstituicaoDashboardDados; static;
  end;

implementation

class function TInstituicaoDashboardDAO.Buscar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TInstituicaoDashboardDados;
var
  Qry: TUniQuery;
begin
  Result := Default(TInstituicaoDashboardDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +

      '(SELECT COUNT(*) ' +
      ' FROM curso c ' +
      ' WHERE c.id_instituicao = :id1) AS cursos, ' +

      '(SELECT COUNT(*) ' +
      ' FROM participante p ' +
      ' WHERE p.id_instituicao = :id2) AS participantes, ' +

      '(SELECT COUNT(*) ' +
      ' FROM turma t ' +
      ' WHERE t.id_instituicao = :id3) AS turmas, ' +

      '(SELECT COUNT(*) ' +
      ' FROM certificado ce ' +
      ' WHERE ce.id_instituicao = :id4 ' +
      '   AND ce.situacao <> ''CANCELADO'') AS certificados, ' +

      '(SELECT COUNT(*) ' +
      ' FROM turma t ' +
      ' WHERE t.id_instituicao = :id5 ' +
      '   AND t.situacao = ''EM_ANDAMENTO'') AS em_andamento, ' +

      '(SELECT COUNT(*) ' +
      ' FROM turma t ' +
      ' WHERE t.id_instituicao = :id6 ' +
      '   AND t.situacao = ''CONCLUIDA'') AS concluidos, ' +

      '(SELECT COALESCE(SUM(c.carga_horaria_minutos), 0) ' +
      ' FROM curso c ' +
      ' WHERE c.id_instituicao = :id7) AS horas_capacitacao';

    Qry.ParamByName('id1').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id2').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id3').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id4').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id5').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id6').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id7').AsLargeInt := AIdInstituicao;

    Qry.Open;

    Result.Cursos :=
      Qry.FieldByName('cursos').AsInteger;

    Result.Participantes :=
      Qry.FieldByName('participantes').AsInteger;

    Result.Turmas :=
      Qry.FieldByName('turmas').AsInteger;

    Result.Certificados :=
      Qry.FieldByName('certificados').AsInteger;

    Result.EmAndamento :=
      Qry.FieldByName('em_andamento').AsInteger;

    Result.Concluidos :=
      Qry.FieldByName('concluidos').AsInteger;

    Result.HorasCapacitacao :=
      Qry.FieldByName('horas_capacitacao').AsFloat;
  finally
    Qry.Free;
  end;
end;

end.
