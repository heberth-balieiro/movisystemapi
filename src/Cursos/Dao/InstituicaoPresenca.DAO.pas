unit InstituicaoPresenca.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoPresenca.Model;

type
  TInstituicaoPresencaDAO = class
  private
    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoPresencaItem; static;

    class function MontarWhereEncontro(
      const AFiltro: TInstituicaoPresencaFiltro
    ): string; static;

    class procedure AplicarFiltroEncontro(
      const AQry: TUniQuery;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro: Int64;
      const AFiltro: TInstituicaoPresencaFiltro
    ); static;

  public
    class function EncontroExiste(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro: Int64
    ): Boolean; static;

    class function InscricaoExisteNaTurma(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdInscricao: Int64
    ): Boolean; static;

    class function ListarPorEncontro(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro: Int64;
      const AFiltro: TInstituicaoPresencaFiltro
    ): TInstituicaoPresencaLista; static;

    class function BuscarRegistro(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            AIdInscricao: Int64
    ): TInstituicaoPresencaItem; static;

    class procedure Salvar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma,
            AIdEncontro,
            ARegistradoPor: Int64;
      const ADados: TInstituicaoPresencaRegistro
    ); static;

    class function ListarPorInscricao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdInscricao: Int64
    ): TObjectList<TInstituicaoPresencaItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoPresencaDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoPresencaItem;
begin
  Result :=
    TInstituicaoPresencaItem.Create;

  Result.TemPresenca :=
    not AQry.FieldByName('id').IsNull;

  if Result.TemPresenca then
    Result.Id :=
      AQry.FieldByName('id').AsLargeInt;

  Result.IdTurma :=
    AQry.FieldByName('id_turma').AsLargeInt;

  Result.IdEncontro :=
    AQry.FieldByName('id_encontro').AsLargeInt;

  Result.EncontroTitulo :=
    AQry.FieldByName('encontro_titulo').AsString;

  Result.EncontroInicio :=
    AQry.FieldByName('encontro_inicio').AsDateTime;

  Result.EncontroFim :=
    AQry.FieldByName('encontro_fim').AsDateTime;

  Result.IdInscricao :=
    AQry.FieldByName('id_inscricao').AsLargeInt;

  Result.InscricaoSituacao :=
    AQry.FieldByName('inscricao_situacao').AsString;

  Result.IdParticipante :=
    AQry.FieldByName('id_participante').AsLargeInt;

  Result.ParticipanteNome :=
    AQry.FieldByName('participante_nome').AsString;

  Result.ParticipanteCpfMascarado :=
    AQry.FieldByName('participante_cpf_mascarado').AsString;

  Result.ParticipanteMatricula :=
    AQry.FieldByName('participante_matricula').AsString;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.TemCheckinEm :=
    not AQry.FieldByName('checkin_em').IsNull;

  if Result.TemCheckinEm then
    Result.CheckinEm :=
      AQry.FieldByName('checkin_em').AsDateTime;

  Result.TemCheckoutEm :=
    not AQry.FieldByName('checkout_em').IsNull;

  if Result.TemCheckoutEm then
    Result.CheckoutEm :=
      AQry.FieldByName('checkout_em').AsDateTime;

  Result.TemMinutosPresentes :=
    not AQry.FieldByName('minutos_presentes').IsNull;

  if Result.TemMinutosPresentes then
    Result.MinutosPresentes :=
      AQry.FieldByName('minutos_presentes').AsInteger;

  Result.Justificativa :=
    AQry.FieldByName('justificativa').AsString;

  Result.TemRegistradoPor :=
    not AQry.FieldByName('registrado_por').IsNull;

  if Result.TemRegistradoPor then
    Result.RegistradoPor :=
      AQry.FieldByName('registrado_por').AsLargeInt;

  Result.RegistradoPorNome :=
    AQry.FieldByName('registrado_por_nome').AsString;

  Result.TemCriadoEm :=
    not AQry.FieldByName('criado_em').IsNull;

  if Result.TemCriadoEm then
    Result.CriadoEm :=
      AQry.FieldByName('criado_em').AsDateTime;

  Result.TemAtualizadoEm :=
    not AQry.FieldByName('atualizado_em').IsNull;

  if Result.TemAtualizadoEm then
    Result.AtualizadoEm :=
      AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoPresencaDAO.MontarWhereEncontro(
  const AFiltro: TInstituicaoPresencaFiltro
): string;
begin
  Result :=
    ' WHERE i.id_instituicao = :id_instituicao ' +
    ' AND i.id_turma = :id_turma ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result :=
      Result +
      ' AND (' +
      'p.nome LIKE :busca ' +
      'OR p.email LIKE :busca ' +
      'OR p.matricula LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Situacao).IsEmpty then
  begin
    if SameText(
      AFiltro.Situacao,
      'SEM_REGISTRO'
    ) then
      Result :=
        Result +
        ' AND pr.id IS NULL '
    else
      Result :=
        Result +
        ' AND pr.situacao = :situacao ';
  end;
end;

class procedure TInstituicaoPresencaDAO.AplicarFiltroEncontro(
  const AQry: TUniQuery;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro: Int64;
  const AFiltro: TInstituicaoPresencaFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  AQry.ParamByName('id_turma').AsLargeInt :=
    AIdTurma;

  AQry.ParamByName('id_encontro').AsLargeInt :=
    AIdEncontro;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if
    not Trim(AFiltro.Situacao).IsEmpty and
    not SameText(
      AFiltro.Situacao,
      'SEM_REGISTRO'
    )
  then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(
        Trim(AFiltro.Situacao)
      );
end;

class function TInstituicaoPresencaDAO.EncontroExiste(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro: Int64
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
      'FROM turma_encontro ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id = :id_encontro ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_encontro').AsLargeInt :=
      AIdEncontro;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPresencaDAO.InscricaoExisteNaTurma(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdInscricao: Int64
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
      'FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma ' +
      'AND id = :id_inscricao ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_inscricao').AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPresencaDAO.ListarPorEncontro(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro: Int64;
  const AFiltro: TInstituicaoPresencaFiltro
): TInstituicaoPresencaLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TInstituicaoPresencaLista.Create;

  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Result.Pagina :=
        AFiltro.Pagina;

      Result.PorPagina :=
        AFiltro.PorPagina;

      WhereSQL :=
        MontarWhereEncontro(
          AFiltro
        );

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM inscricao i ' +
        'INNER JOIN participante p ' +
        '  ON p.id_instituicao = i.id_instituicao ' +
        ' AND p.id = i.id_participante ' +
        'LEFT JOIN presenca pr ' +
        '  ON pr.id_instituicao = i.id_instituicao ' +
        ' AND pr.id_turma = i.id_turma ' +
        ' AND pr.id_inscricao = i.id ' +
        ' AND pr.id_encontro = :id_encontro ' +
        WhereSQL;

      AplicarFiltroEncontro(
        Qry,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        'pr.id, ' +
        'i.id_turma, ' +
        'e.id AS id_encontro, ' +
        'e.titulo AS encontro_titulo, ' +
        'e.data_hora_inicio AS encontro_inicio, ' +
        'e.data_hora_fim AS encontro_fim, ' +
        'i.id AS id_inscricao, ' +
        'i.situacao AS inscricao_situacao, ' +
        'i.id_participante, ' +
        'p.nome AS participante_nome, ' +
        'p.cpf_mascarado AS participante_cpf_mascarado, ' +
        'p.matricula AS participante_matricula, ' +
        'pr.situacao, ' +
        'pr.checkin_em, ' +
        'pr.checkout_em, ' +
        'pr.minutos_presentes, ' +
        'pr.justificativa, ' +
        'pr.registrado_por, ' +
        'u.nome AS registrado_por_nome, ' +
        'pr.criado_em, ' +
        'pr.atualizado_em ' +
        'FROM inscricao i ' +
        'INNER JOIN participante p ' +
        '  ON p.id_instituicao = i.id_instituicao ' +
        ' AND p.id = i.id_participante ' +
        'INNER JOIN turma_encontro e ' +
        '  ON e.id_instituicao = i.id_instituicao ' +
        ' AND e.id_turma = i.id_turma ' +
        ' AND e.id = :id_encontro ' +
        'LEFT JOIN presenca pr ' +
        '  ON pr.id_instituicao = i.id_instituicao ' +
        ' AND pr.id_turma = i.id_turma ' +
        ' AND pr.id_inscricao = i.id ' +
        ' AND pr.id_encontro = e.id ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = pr.id_instituicao ' +
        ' AND ui.id = pr.registrado_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        WhereSQL +
        'ORDER BY p.nome, i.id ' +
        'LIMIT :limite OFFSET :offset';

      AplicarFiltroEncontro(
        Qry,
        AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        AFiltro
      );

      Qry.ParamByName('limite').AsInteger :=
        AFiltro.PorPagina;

      Qry.ParamByName('offset').AsInteger :=
        Offset;

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

class function TInstituicaoPresencaDAO.BuscarRegistro(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        AIdInscricao: Int64
): TInstituicaoPresencaItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      'pr.id, ' +
      'pr.id_turma, ' +
      'e.id AS id_encontro, ' +
      'e.titulo AS encontro_titulo, ' +
      'e.data_hora_inicio AS encontro_inicio, ' +
      'e.data_hora_fim AS encontro_fim, ' +
      'pr.id_inscricao, ' +
      'i.situacao AS inscricao_situacao, ' +
      'i.id_participante, ' +
      'p.nome AS participante_nome, ' +
      'p.cpf_mascarado AS participante_cpf_mascarado, ' +
      'p.matricula AS participante_matricula, ' +
      'pr.situacao, ' +
      'pr.checkin_em, ' +
      'pr.checkout_em, ' +
      'pr.minutos_presentes, ' +
      'pr.justificativa, ' +
      'pr.registrado_por, ' +
      'u.nome AS registrado_por_nome, ' +
      'pr.criado_em, ' +
      'pr.atualizado_em ' +
      'FROM presenca pr ' +
      'INNER JOIN turma_encontro e ' +
      '  ON e.id_instituicao = pr.id_instituicao ' +
      ' AND e.id_turma = pr.id_turma ' +
      ' AND e.id = pr.id_encontro ' +
      'INNER JOIN inscricao i ' +
      '  ON i.id_instituicao = pr.id_instituicao ' +
      ' AND i.id_turma = pr.id_turma ' +
      ' AND i.id = pr.id_inscricao ' +
      'INNER JOIN participante p ' +
      '  ON p.id_instituicao = i.id_instituicao ' +
      ' AND p.id = i.id_participante ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = pr.id_instituicao ' +
      ' AND ui.id = pr.registrado_por ' +
      'LEFT JOIN usuario u ' +
      '  ON u.id = ui.id_usuario ' +
      'WHERE pr.id_instituicao = :id_instituicao ' +
      'AND pr.id_turma = :id_turma ' +
      'AND pr.id_encontro = :id_encontro ' +
      'AND pr.id_inscricao = :id_inscricao ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_encontro').AsLargeInt :=
      AIdEncontro;

    Qry.ParamByName('id_inscricao').AsLargeInt :=
      AIdInscricao;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoPresencaDAO.Salvar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma,
        AIdEncontro,
        ARegistradoPor: Int64;
  const ADados: TInstituicaoPresencaRegistro
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO presenca (' +
      'id_instituicao, ' +
      'id_turma, ' +
      'id_encontro, ' +
      'id_inscricao, ' +
      'situacao, ' +
      'checkin_em, ' +
      'checkout_em, ' +
      'minutos_presentes, ' +
      'justificativa, ' +
      'registrado_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_turma, ' +
      ':id_encontro, ' +
      ':id_inscricao, ' +
      ':situacao, ' +
      ':checkin_em, ' +
      ':checkout_em, ' +
      ':minutos_presentes, ' +
      ':justificativa, ' +
      ':registrado_por' +
      ') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'situacao = VALUES(situacao), ' +
      'checkin_em = VALUES(checkin_em), ' +
      'checkout_em = VALUES(checkout_em), ' +
      'minutos_presentes = VALUES(minutos_presentes), ' +
      'justificativa = VALUES(justificativa), ' +
      'registrado_por = VALUES(registrado_por)';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_turma').AsLargeInt :=
      AIdTurma;

    Qry.ParamByName('id_encontro').AsLargeInt :=
      AIdEncontro;

    Qry.ParamByName('id_inscricao').AsLargeInt :=
      ADados.IdInscricao;

    Qry.ParamByName('situacao').AsString :=
      ADados.Situacao;

    if ADados.TemCheckinEm then
      Qry.ParamByName('checkin_em').AsDateTime :=
        ADados.CheckinEm
    else
      Qry.ParamByName('checkin_em').Clear;

    if ADados.TemCheckoutEm then
      Qry.ParamByName('checkout_em').AsDateTime :=
        ADados.CheckoutEm
    else
      Qry.ParamByName('checkout_em').Clear;

    if ADados.TemMinutosPresentes then
      Qry.ParamByName('minutos_presentes').AsInteger :=
        ADados.MinutosPresentes
    else
      Qry.ParamByName('minutos_presentes').Clear;

    if Trim(ADados.Justificativa).IsEmpty then
      Qry.ParamByName('justificativa').Clear
    else
      Qry.ParamByName('justificativa').AsString :=
        Trim(
          ADados.Justificativa
        );

    Qry.ParamByName('registrado_por').AsLargeInt :=
      ARegistradoPor;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoPresencaDAO.ListarPorInscricao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdInscricao: Int64
): TObjectList<TInstituicaoPresencaItem>;
var
  Qry: TUniQuery;
begin
  Result :=
    TObjectList<TInstituicaoPresencaItem>.Create(
      True
    );

  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT ' +
        'pr.id, ' +
        'pr.id_turma, ' +
        'e.id AS id_encontro, ' +
        'e.titulo AS encontro_titulo, ' +
        'e.data_hora_inicio AS encontro_inicio, ' +
        'e.data_hora_fim AS encontro_fim, ' +
        'pr.id_inscricao, ' +
        'i.situacao AS inscricao_situacao, ' +
        'i.id_participante, ' +
        'p.nome AS participante_nome, ' +
        'p.cpf_mascarado AS participante_cpf_mascarado, ' +
        'p.matricula AS participante_matricula, ' +
        'pr.situacao, ' +
        'pr.checkin_em, ' +
        'pr.checkout_em, ' +
        'pr.minutos_presentes, ' +
        'pr.justificativa, ' +
        'pr.registrado_por, ' +
        'u.nome AS registrado_por_nome, ' +
        'pr.criado_em, ' +
        'pr.atualizado_em ' +
        'FROM presenca pr ' +
        'INNER JOIN turma_encontro e ' +
        '  ON e.id_instituicao = pr.id_instituicao ' +
        ' AND e.id_turma = pr.id_turma ' +
        ' AND e.id = pr.id_encontro ' +
        'INNER JOIN inscricao i ' +
        '  ON i.id_instituicao = pr.id_instituicao ' +
        ' AND i.id_turma = pr.id_turma ' +
        ' AND i.id = pr.id_inscricao ' +
        'INNER JOIN participante p ' +
        '  ON p.id_instituicao = i.id_instituicao ' +
        ' AND p.id = i.id_participante ' +
        'LEFT JOIN usuario_instituicao ui ' +
        '  ON ui.id_instituicao = pr.id_instituicao ' +
        ' AND ui.id = pr.registrado_por ' +
        'LEFT JOIN usuario u ' +
        '  ON u.id = ui.id_usuario ' +
        'WHERE pr.id_instituicao = :id_instituicao ' +
        'AND pr.id_inscricao = :id_inscricao ' +
        'ORDER BY e.data_hora_inicio, e.id';

      Qry.ParamByName('id_instituicao').AsLargeInt :=
        AIdInstituicao;

      Qry.ParamByName('id_inscricao').AsLargeInt :=
        AIdInscricao;

      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Add(
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

end.

