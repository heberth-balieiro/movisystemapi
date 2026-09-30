unit InstituicaoConclusao.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoConclusao.Model;

type
  TInstituicaoConclusaoDAO = class
  public
    class function BuscarContexto(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TConclusaoInscricaoContexto; static;

    class function CalcularPresenca(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao: Int64;
      const AJustificadaContaComoPresenca: Boolean
    ): TConclusaoMetricaPresenca; static;

    class function CalcularAulas(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdCurso,
            AIdInscricao: Int64
    ): TConclusaoMetricaAulas; static;

    class function ListarCriterios(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao: Int64
    ): TConclusaoCriterioLista; static;

    class procedure SalvarResultadoAutomatico(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao,
            AIdCriterio: Int64;
      const ATemAtendido,
            AAtendido: Boolean;
      const AResultadoJson: string
    ); static;

    class procedure SalvarResultadoManual(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao,
            AIdCriterio,
            AAvaliadoPor: Int64;
      const ATemAtendido,
            AAtendido: Boolean;
      const AResultadoJson: string
    ); static;

    class procedure AtualizarResumoInscricao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao,
            AAtualizadoPor: Int64;
      const AMetricaPresenca: TConclusaoMetricaPresenca;
      const APercentualProgresso: Double;
      const AElegivelCertificado: Boolean
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoConclusaoDAO.BuscarContexto(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TConclusaoInscricaoContexto;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'i.id AS id_inscricao, ' +
      'i.id_turma, ' +
      't.id_curso, ' +
      'i.situacao, ' +
      'p.nome AS participante_nome, ' +
      'c.nome AS curso_nome, ' +
      't.nome AS turma_nome ' +
      'FROM inscricao i ' +
      'INNER JOIN turma t ' +
      '  ON t.id_instituicao = i.id_instituicao ' +
      ' AND t.id = i.id_turma ' +
      'INNER JOIN curso c ' +
      '  ON c.id_instituicao = t.id_instituicao ' +
      ' AND c.id = t.id_curso ' +
      'INNER JOIN participante p ' +
      '  ON p.id_instituicao = i.id_instituicao ' +
      ' AND p.id = i.id_participante ' +
      'WHERE i.id_instituicao = :id_instituicao ' +
      'AND i.id = :id_inscricao ' +
      'LIMIT 1';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result :=
      TConclusaoInscricaoContexto.Create;

    Result.IdInscricao :=
      Qry.FieldByName(
        'id_inscricao'
      ).AsLargeInt;

    Result.IdTurma :=
      Qry.FieldByName(
        'id_turma'
      ).AsLargeInt;

    Result.IdCurso :=
      Qry.FieldByName(
        'id_curso'
      ).AsLargeInt;

    Result.Situacao :=
      Qry.FieldByName(
        'situacao'
      ).AsString;

    Result.ParticipanteNome :=
      Qry.FieldByName(
        'participante_nome'
      ).AsString;

    Result.CursoNome :=
      Qry.FieldByName(
        'curso_nome'
      ).AsString;

    Result.TurmaNome :=
      Qry.FieldByName(
        'turma_nome'
      ).AsString;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConclusaoDAO.CalcularPresenca(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao: Int64;
  const AJustificadaContaComoPresenca: Boolean
): TConclusaoMetricaPresenca;
var
  Qry: TUniQuery;
begin
  Result :=
    Default(
      TConclusaoMetricaPresenca
    );

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT controle_presenca FROM turma ' +
      'WHERE id_instituicao=:id_instituicao AND id=:id_turma LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      if SameText(Qry.FieldByName('controle_presenca').AsString, 'SEM_CONTROLE') then
        Exit;

      if SameText(Qry.FieldByName('controle_presenca').AsString, 'TURMA') then
      begin
        Qry.Close;
        Qry.SQL.Text :=
          'SELECT COUNT(*) AS total FROM turma_presenca ' +
          'WHERE id_instituicao=:id_instituicao AND id_turma=:id_turma ' +
          'AND id_inscricao=:id_inscricao AND situacao=''PRESENTE''';
        Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
        Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
        Qry.ParamByName('id_inscricao').AsLargeInt := AIdInscricao;
        Qry.Open;

        Result.MinutosPrevistos := 1;
        Result.MinutosComputados := Ord(Qry.FieldByName('total').AsInteger > 0);
        Result.TemBaseCalculo := True;
        if Result.MinutosComputados > 0 then
          Result.Percentual := 100
        else
          Result.Percentual := 0;
        Exit;
      end;
    end;

    Qry.Close;
    Qry.SQL.Text :=
      'SELECT ' +
      'COALESCE(SUM(' +
      '  CASE ' +
      '    WHEN e.carga_horaria_minutos IS NOT NULL ' +
      '      THEN e.carga_horaria_minutos ' +
      '    ELSE GREATEST(TIMESTAMPDIFF(MINUTE, e.data_hora_inicio, e.data_hora_fim), 0) ' +
      '  END' +
      '), 0) AS minutos_previstos, ' +

      'COALESCE(SUM(' +
      '  CASE ' +
      '    WHEN pr.situacao = ''PRESENTE'' THEN ' +
      '      CASE ' +
      '        WHEN e.carga_horaria_minutos IS NOT NULL ' +
      '          THEN e.carga_horaria_minutos ' +
      '        ELSE GREATEST(TIMESTAMPDIFF(MINUTE, e.data_hora_inicio, e.data_hora_fim), 0) ' +
      '      END ' +

      '    WHEN pr.situacao = ''JUSTIFICADA'' AND :justificada = 1 THEN ' +
      '      CASE ' +
      '        WHEN e.carga_horaria_minutos IS NOT NULL ' +
      '          THEN e.carga_horaria_minutos ' +
      '        ELSE GREATEST(TIMESTAMPDIFF(MINUTE, e.data_hora_inicio, e.data_hora_fim), 0) ' +
      '      END ' +

      '    WHEN pr.situacao = ''PARCIAL'' THEN ' +
      '      LEAST(' +
      '        COALESCE(pr.minutos_presentes, 0), ' +
      '        CASE ' +
      '          WHEN e.carga_horaria_minutos IS NOT NULL ' +
      '            THEN e.carga_horaria_minutos ' +
      '          ELSE GREATEST(TIMESTAMPDIFF(MINUTE, e.data_hora_inicio, e.data_hora_fim), 0) ' +
      '        END' +
      '      ) ' +

      '    ELSE 0 ' +
      '  END' +
      '), 0) AS minutos_computados ' +

      'FROM turma_encontro e ' +
      'LEFT JOIN presenca pr ' +
      '  ON pr.id_instituicao = e.id_instituicao ' +
      ' AND pr.id_turma = e.id_turma ' +
      ' AND pr.id_encontro = e.id ' +
      ' AND pr.id_inscricao = :id_inscricao ' +
      'WHERE e.id_instituicao = :id_instituicao ' +
      'AND e.id_turma = :id_turma ' +
      'AND e.obrigatorio = 1 ' +
      'AND e.situacao <> ''CANCELADO''';

    Qry.ParamByName(
      'justificada'
    ).AsInteger :=
      Ord(
        AJustificadaContaComoPresenca
      );

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AIdTurma;

    Qry.Open;

    Result.MinutosPrevistos :=
      Qry.FieldByName(
        'minutos_previstos'
      ).AsLargeInt;

    Result.MinutosComputados :=
      Qry.FieldByName(
        'minutos_computados'
      ).AsLargeInt;

    Result.TemBaseCalculo :=
      Result.MinutosPrevistos > 0;

    if Result.TemBaseCalculo then
      Result.Percentual :=
        (
          Result.MinutosComputados *
          100.0
        ) /
        Result.MinutosPrevistos
    else
      Result.Percentual := 0;

    if Result.Percentual > 100 then
      Result.Percentual := 100;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConclusaoDAO.CalcularAulas(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdCurso,
        AIdInscricao: Int64
): TConclusaoMetricaAulas;
var
  Qry: TUniQuery;
begin
  Result :=
    Default(
      TConclusaoMetricaAulas
    );

  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'COUNT(a.id) AS total_aulas, ' +
      'COALESCE(SUM(' +
      '  CASE ' +
      '    WHEN ap.concluido_em IS NOT NULL OR COALESCE(ap.percentual, 0) >= 100 ' +
      '      THEN 1 ' +
      '    ELSE 0 ' +
      '  END' +
      '), 0) AS aulas_concluidas ' +
      'FROM curso_aula a ' +
      'LEFT JOIN inscricao_aula_progresso ap ' +
      '  ON ap.id_instituicao = a.id_instituicao ' +
      ' AND ap.id_curso = a.id_curso ' +
      ' AND ap.id_aula = a.id ' +
      ' AND ap.id_turma = :id_turma ' +
      ' AND ap.id_inscricao = :id_inscricao ' +
      'WHERE a.id_instituicao = :id_instituicao ' +
      'AND a.id_curso = :id_curso ' +
      'AND a.obrigatoria = 1 ' +
      'AND a.situacao = ''ATIVA''';

    Qry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AIdTurma;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_curso'
    ).AsLargeInt :=
      AIdCurso;

    Qry.Open;

    Result.TotalAulas :=
      Qry.FieldByName(
        'total_aulas'
      ).AsInteger;

    Result.AulasConcluidas :=
      Qry.FieldByName(
        'aulas_concluidas'
      ).AsInteger;

    Result.TemAulasObrigatorias :=
      Result.TotalAulas > 0;

    if Result.TemAulasObrigatorias then
      Result.Percentual :=
        (
          Result.AulasConcluidas *
          100.0
        ) /
        Result.TotalAulas
    else
      Result.Percentual := 0;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoConclusaoDAO.ListarCriterios(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao: Int64
): TConclusaoCriterioLista;
var
  Qry: TUniQuery;
  Item: TConclusaoCriterioItem;
begin
  Result :=
    TConclusaoCriterioLista.Create(
      True
    );

  Qry :=
    TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'c.id AS id_criterio, ' +
        'c.tipo, ' +
        'c.nome, ' +
        'c.obrigatorio, ' +
        'c.configuracao, ' +
        'c.ordem, ' +
        'r.atendido, ' +
        'r.resultado, ' +
        'r.avaliado_por, ' +
        'u.nome AS avaliado_por_nome, ' +
        'r.avaliado_em ' +
        'FROM turma_criterio_conclusao c ' +
        'LEFT JOIN inscricao_criterio_resultado r ' +
        '  ON r.id_instituicao = c.id_instituicao ' +
        ' AND r.id_turma = c.id_turma ' +
        ' AND r.id_criterio = c.id ' +
        ' AND r.id_inscricao = :id_inscricao ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = r.id_instituicao ' +
        ' AND ui.id = r.avaliado_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        'WHERE c.id_instituicao = :id_instituicao ' +
        'AND c.id_turma = :id_turma ' +
        'AND c.situacao = ''ATIVO'' ' +
        'ORDER BY c.ordem, c.id';

      Qry.ParamByName(
        'id_inscricao'
      ).AsLargeInt :=
        AIdInscricao;

      Qry.ParamByName(
        'id_instituicao'
      ).AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName(
        'id_turma'
      ).AsLargeInt :=
        AIdTurma;

      Qry.Open;

      while not Qry.Eof do
      begin
        Item :=
          TConclusaoCriterioItem.Create;

        Item.IdCriterio :=
          Qry.FieldByName(
            'id_criterio'
          ).AsLargeInt;

        Item.Tipo :=
          Qry.FieldByName(
            'tipo'
          ).AsString;

        Item.Nome :=
          Qry.FieldByName(
            'nome'
          ).AsString;

        Item.Obrigatorio :=
          Qry.FieldByName(
            'obrigatorio'
          ).AsBoolean;

        Item.Configuracao :=
          Qry.FieldByName(
            'configuracao'
          ).AsString;

        Item.Ordem :=
          Qry.FieldByName(
            'ordem'
          ).AsInteger;

        Item.TemAtendido :=
          not Qry.FieldByName(
            'atendido'
          ).IsNull;

        if Item.TemAtendido then
          Item.Atendido :=
            Qry.FieldByName(
              'atendido'
            ).AsBoolean;

        Item.Resultado :=
          Qry.FieldByName(
            'resultado'
          ).AsString;

        Item.TemAvaliadoPor :=
          not Qry.FieldByName(
            'avaliado_por'
          ).IsNull;

        if Item.TemAvaliadoPor then
          Item.AvaliadoPor :=
            Qry.FieldByName(
              'avaliado_por'
            ).AsLargeInt;

        Item.AvaliadoPorNome :=
          Qry.FieldByName(
            'avaliado_por_nome'
          ).AsString;

        Item.TemAvaliadoEm :=
          not Qry.FieldByName(
            'avaliado_em'
          ).IsNull;

        if Item.TemAvaliadoEm then
          Item.AvaliadoEm :=
            Qry.FieldByName(
              'avaliado_em'
            ).AsDateTime;

        Result.Add(
          Item
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

class procedure TInstituicaoConclusaoDAO.SalvarResultadoAutomatico(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao,
        AIdCriterio: Int64;
  const ATemAtendido,
        AAtendido: Boolean;
  const AResultadoJson: string
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO inscricao_criterio_resultado (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_inscricao, ' +
      'id_criterio, ' +
      'atendido, ' +
      'resultado, ' +
      'avaliado_por, ' +
      'avaliado_em' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_inscricao, ' +
      ':id_criterio, ' +
      ':atendido, ' +
      ':resultado, ' +
      'NULL, ' +
      ':avaliado_em' +
      ') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'atendido = VALUES(atendido), ' +
      'resultado = VALUES(resultado), ' +
      'avaliado_por = NULL, ' +
      'avaliado_em = VALUES(avaliado_em)';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AIdTurma;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.ParamByName(
      'id_criterio'
    ).AsLargeInt :=
      AIdCriterio;

    if ATemAtendido then
      Qry.ParamByName(
        'atendido'
      ).AsBoolean :=
        AAtendido
    else
      Qry.ParamByName(
        'atendido'
      ).Clear;

    if Trim(AResultadoJson).IsEmpty then
      Qry.ParamByName(
        'resultado'
      ).Clear
    else
      Qry.ParamByName(
        'resultado'
      ).AsString :=
        AResultadoJson;

    if ATemAtendido then
      Qry.ParamByName(
        'avaliado_em'
      ).AsDateTime :=
        Now
    else
      Qry.ParamByName(
        'avaliado_em'
      ).Clear;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConclusaoDAO.SalvarResultadoManual(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao,
        AIdCriterio,
        AAvaliadoPor: Int64;
  const ATemAtendido,
        AAtendido: Boolean;
  const AResultadoJson: string
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO inscricao_criterio_resultado (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_inscricao, ' +
      'id_criterio, ' +
      'atendido, ' +
      'resultado, ' +
      'avaliado_por, ' +
      'avaliado_em' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_inscricao, ' +
      ':id_criterio, ' +
      ':atendido, ' +
      ':resultado, ' +
      ':avaliado_por, ' +
      ':avaliado_em' +
      ') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'atendido = VALUES(atendido), ' +
      'resultado = VALUES(resultado), ' +
      'avaliado_por = VALUES(avaliado_por), ' +
      'avaliado_em = VALUES(avaliado_em)';

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_turma'
    ).AsLargeInt :=
      AIdTurma;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.ParamByName(
      'id_criterio'
    ).AsLargeInt :=
      AIdCriterio;

    if ATemAtendido then
    begin
      Qry.ParamByName(
        'atendido'
      ).AsBoolean :=
        AAtendido;

      Qry.ParamByName(
        'avaliado_por'
      ).AsLargeInt :=
        AAvaliadoPor;

      Qry.ParamByName(
        'avaliado_em'
      ).AsDateTime :=
        Now;
    end
    else
    begin
      Qry.ParamByName(
        'atendido'
      ).Clear;

      Qry.ParamByName(
        'avaliado_por'
      ).Clear;

      Qry.ParamByName(
        'avaliado_em'
      ).Clear;
    end;

    if Trim(AResultadoJson).IsEmpty then
      Qry.ParamByName(
        'resultado'
      ).Clear
    else
      Qry.ParamByName(
        'resultado'
      ).AsString :=
        AResultadoJson;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoConclusaoDAO.AtualizarResumoInscricao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao,
        AAtualizadoPor: Int64;
  const AMetricaPresenca: TConclusaoMetricaPresenca;
  const APercentualProgresso: Double;
  const AElegivelCertificado: Boolean
);
var
  Qry: TUniQuery;
begin
  Qry :=
    TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE inscricao SET ' +
      'percentual_presenca = :percentual_presenca, ' +
      'percentual_progresso = :percentual_progresso, ' +
      'elegivel_certificado = :elegivel_certificado, ' +
      'atualizado_por = :atualizado_por ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_inscricao';

    if AMetricaPresenca.TemBaseCalculo then
      Qry.ParamByName(
        'percentual_presenca'
      ).AsFloat :=
        AMetricaPresenca.Percentual
    else
      Qry.ParamByName(
        'percentual_presenca'
      ).Clear;

    Qry.ParamByName(
      'percentual_progresso'
    ).AsFloat :=
      APercentualProgresso;

    Qry.ParamByName(
      'elegivel_certificado'
    ).AsBoolean :=
      AElegivelCertificado;

    Qry.ParamByName(
      'atualizado_por'
    ).AsLargeInt :=
      AAtualizadoPor;

    Qry.ParamByName(
      'id_instituicao'
    ).AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName(
      'id_inscricao'
    ).AsLargeInt :=
      AIdInscricao;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
