unit InstituicaoTurma.DAO;

interface

uses
  Uni,
  InstituicaoTurma.Model;

type
  TInstituicaoTurmaDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoTurmaFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoTurmaFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoTurmaItem; static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoTurmaFiltro
    ): TInstituicaoTurmaLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): TInstituicaoTurmaItem; static;

    class function ExisteCodigoPublico(
      const AConn: TUniConnection;
      const ACodigoPublico: string
    ): Boolean; static;

    class function TemInscricoes(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64
    ): Boolean; static;

    class function ExisteCodigoInterno(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigoInterno: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function ExisteCursoAtivo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso: Int64
    ): Boolean; static;

    class function BuscarEntidadeAtendidaAtivaCurso(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCurso: Int64
    ): Int64; static;

    class function ExisteModeloCertificadoAtivo(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdModelo: Int64
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoTurmaCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64;
      const ADados: TInstituicaoTurmaAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdTurma: Int64;
      const ASituacao: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoTurmaDAO.MontarWhere(
  const AFiltro: TInstituicaoTurmaFiltro
): string;
begin
  Result :=
    ' WHERE t.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result :=
      Result +
      ' AND (' +
      't.nome LIKE :busca OR ' +
      't.codigo_interno LIKE :busca OR ' +
      'c.nome LIKE :busca' +
      ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result :=
      Result +
      ' AND t.situacao = :situacao ';

  if not Trim(AFiltro.Modalidade).IsEmpty then
    Result :=
      Result +
      ' AND t.modalidade = :modalidade ';

  if AFiltro.IdCurso > 0 then
    Result :=
      Result +
      ' AND t.id_curso = :id_curso ';
end;

class procedure TInstituicaoTurmaDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoTurmaFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString :=
      UpperCase(Trim(AFiltro.Situacao));

  if not Trim(AFiltro.Modalidade).IsEmpty then
    AQry.ParamByName('modalidade').AsString :=
      UpperCase(Trim(AFiltro.Modalidade));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt :=
      AFiltro.IdCurso;
end;

class function TInstituicaoTurmaDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoTurmaItem;
begin
  Result := TInstituicaoTurmaItem.Create;

  Result.Id :=
    AQry.FieldByName('id').AsLargeInt;

  Result.IdCurso :=
    AQry.FieldByName('id_curso').AsLargeInt;

  Result.CursoNome :=
    AQry.FieldByName('curso_nome').AsString;

  Result.TemEntidadeAtendida :=
    not AQry.FieldByName('id_entidade_atendida').IsNull;

  if Result.TemEntidadeAtendida then
    Result.IdEntidadeAtendida :=
      AQry.FieldByName('id_entidade_atendida').AsLargeInt;

  Result.EntidadeAtendidaNome :=
    AQry.FieldByName('entidade_atendida_nome').AsString;

  Result.TemModeloCertificado :=
    not AQry.FieldByName('id_modelo_certificado').IsNull;

  if Result.TemModeloCertificado then
    Result.IdModeloCertificado :=
      AQry.FieldByName('id_modelo_certificado').AsLargeInt;

  Result.ModeloCertificadoNome :=
    AQry.FieldByName('modelo_certificado_nome').AsString;

  Result.CodigoPublico :=
    AQry.FieldByName('codigo_publico').AsString;

  Result.CodigoInterno :=
    AQry.FieldByName('codigo_interno').AsString;

  Result.Nome :=
    AQry.FieldByName('nome').AsString;

  Result.Modalidade :=
    AQry.FieldByName('modalidade').AsString;

  Result.TipoFluxo :=
    AQry.FieldByName('tipo_fluxo').AsString;

  Result.DataHoraInicio :=
    AQry.FieldByName('data_hora_inicio').AsDateTime;

  Result.DataHoraFim :=
    AQry.FieldByName('data_hora_fim').AsDateTime;

  Result.TemInscricaoInicio :=
    not AQry.FieldByName('inscricao_inicio').IsNull;

  if Result.TemInscricaoInicio then
    Result.InscricaoInicio :=
      AQry.FieldByName('inscricao_inicio').AsDateTime;

  Result.TemInscricaoFim :=
    not AQry.FieldByName('inscricao_fim').IsNull;

  if Result.TemInscricaoFim then
    Result.InscricaoFim :=
      AQry.FieldByName('inscricao_fim').AsDateTime;

  Result.TemLimiteParticipantes :=
    not AQry.FieldByName('limite_participantes').IsNull;

  if Result.TemLimiteParticipantes then
    Result.LimiteParticipantes :=
      AQry.FieldByName('limite_participantes').AsInteger;

  Result.Local :=
    AQry.FieldByName('local').AsString;

  Result.UrlOnline :=
    AQry.FieldByName('url_online').AsString;

  Result.TemCargaHorariaMinutos :=
    not AQry.FieldByName('carga_horaria_minutos').IsNull;

  if Result.TemCargaHorariaMinutos then
    Result.CargaHorariaMinutos :=
      AQry.FieldByName('carga_horaria_minutos').AsInteger;

  Result.PermitirInscricaoPublica :=
    AQry.FieldByName('permitir_inscricao_publica').AsBoolean;

  Result.AprovacaoInscricao := AQry.FieldByName('aprovacao_inscricao').AsString;
  Result.ControlePresenca := AQry.FieldByName('controle_presenca').AsString;
  Result.ExigirPresencaConclusao := AQry.FieldByName('exigir_presenca_conclusao').AsBoolean;
  Result.ConclusaoAutomatica := AQry.FieldByName('conclusao_automatica').AsBoolean;
  Result.CertificadoAutomatico := AQry.FieldByName('certificado_automatico').AsBoolean;

  Result.Situacao :=
    AQry.FieldByName('situacao').AsString;

  Result.CriadoEm :=
    AQry.FieldByName('criado_em').AsDateTime;

  Result.AtualizadoEm :=
    AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoTurmaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoTurmaFiltro
): TInstituicaoTurmaLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result :=
    TInstituicaoTurmaLista.Create;

  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Result.Pagina :=
        AFiltro.Pagina;

      Result.PorPagina :=
        AFiltro.PorPagina;

      WhereSQL :=
        MontarWhere(AFiltro);

      Offset :=
        (AFiltro.Pagina - 1) *
        AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total ' +
        'FROM turma t ' +
        'INNER JOIN curso c ' +
        '  ON c.id_instituicao = t.id_instituicao ' +
        ' AND c.id = t.id_curso ' +
        WhereSQL;

      AplicarParametros(
        Qry,
        AIdInstituicao,
        AFiltro
      );

      Qry.Open;

      Result.Total :=
        Qry.FieldByName('total').AsInteger;

      Qry.Close;

      Qry.SQL.Text :=
        'SELECT ' +
        't.id, ' +
        't.id_curso, ' +
        'c.nome AS curso_nome, ' +
        't.id_entidade_atendida, ' +
        'ea.nome AS entidade_atendida_nome, ' +
        't.id_modelo_certificado, ' +
        'cm.nome AS modelo_certificado_nome, ' +
        't.codigo_publico, ' +
        't.codigo_interno, ' +
        't.nome, ' +
        't.modalidade, ' +
        't.tipo_fluxo, ' +
        't.data_hora_inicio, ' +
        't.data_hora_fim, ' +
        't.inscricao_inicio, ' +
        't.inscricao_fim, ' +
        't.limite_participantes, ' +
        't.local, ' +
        't.url_online, ' +
        't.carga_horaria_minutos, ' +
        't.permitir_inscricao_publica, ' +
        't.aprovacao_inscricao, ' +
        't.controle_presenca, ' +
        't.exigir_presenca_conclusao, ' +
        't.conclusao_automatica, ' +
        't.certificado_automatico, ' +
        't.situacao, ' +
        't.criado_em, ' +
        't.atualizado_em ' +
        'FROM turma t ' +
        'INNER JOIN curso c ' +
        '  ON c.id_instituicao = t.id_instituicao ' +
        ' AND c.id = t.id_curso ' +
        'LEFT JOIN certificado_modelo cm ' +
        '  ON cm.id_instituicao = t.id_instituicao ' +
        ' AND cm.id = t.id_modelo_certificado ' +
        'LEFT JOIN entidade_atendida ea ' +
        '  ON ea.id_instituicao = t.id_instituicao ' +
        ' AND ea.id = t.id_entidade_atendida ' +
        WhereSQL +
        'ORDER BY t.data_hora_inicio DESC, t.id DESC ' +
        'LIMIT :limite OFFSET :offset';

      AplicarParametros(
        Qry,
        AIdInstituicao,
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

class function TInstituicaoTurmaDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): TInstituicaoTurmaItem;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT ' +
      't.id, ' +
      't.id_curso, ' +
      'c.nome AS curso_nome, ' +
      't.id_entidade_atendida, ' +
      'ea.nome AS entidade_atendida_nome, ' +
      't.id_modelo_certificado, ' +
      'cm.nome AS modelo_certificado_nome, ' +
      't.codigo_publico, ' +
      't.codigo_interno, ' +
      't.nome, ' +
      't.modalidade, ' +
        't.tipo_fluxo, ' +
      't.data_hora_inicio, ' +
      't.data_hora_fim, ' +
      't.inscricao_inicio, ' +
      't.inscricao_fim, ' +
      't.limite_participantes, ' +
      't.local, ' +
      't.url_online, ' +
      't.carga_horaria_minutos, ' +
      't.permitir_inscricao_publica, ' +
      't.aprovacao_inscricao, ' +
      't.controle_presenca, ' +
      't.exigir_presenca_conclusao, ' +
      't.conclusao_automatica, ' +
      't.certificado_automatico, ' +
      't.situacao, ' +
      't.criado_em, ' +
      't.atualizado_em ' +
      'FROM turma t ' +
      'INNER JOIN curso c ' +
      '  ON c.id_instituicao = t.id_instituicao ' +
      ' AND c.id = t.id_curso ' +
      'LEFT JOIN certificado_modelo cm ' +
      '  ON cm.id_instituicao = t.id_instituicao ' +
      ' AND cm.id = t.id_modelo_certificado ' +
      'LEFT JOIN entidade_atendida ea ' +
      '  ON ea.id_instituicao = t.id_instituicao ' +
      ' AND ea.id = t.id_entidade_atendida ' +
      'WHERE t.id_instituicao = :id_instituicao ' +
      'AND t.id = :id ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdTurma;

    Qry.Open;

    if not Qry.IsEmpty then
      Result :=
        MapearItem(Qry);

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.ExisteCodigoPublico(
  const AConn: TUniConnection;
  const ACodigoPublico: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM turma ' +
      'WHERE codigo_publico = :codigo_publico ' +
      'LIMIT 1';

    Qry.ParamByName('codigo_publico').AsString :=
      ACodigoPublico;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.TemInscricoes(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM inscricao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id_turma = :id_turma LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.ExisteCodigoInterno(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigoInterno: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ACodigoInterno).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM turma ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND codigo_interno = :codigo_interno ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add(
        'AND id <> :id_ignorar '
      );

    Qry.SQL.Add(
      'LIMIT 1'
    );

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('codigo_interno').AsString :=
      Trim(ACodigoInterno);

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt :=
        AIdIgnorar;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.ExisteCursoAtivo(
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
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      AIdCurso;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.BuscarEntidadeAtendidaAtivaCurso(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCurso: Int64
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  if (AIdInstituicao <= 0) or (AIdCurso <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.id_entidade_atendida ' +
      'FROM curso c ' +
      'JOIN entidade_atendida e ' +
      '  ON e.id_instituicao=c.id_instituicao ' +
      ' AND e.id=c.id_entidade_atendida ' +
      ' AND e.situacao=''ATIVO'' ' +
      'WHERE c.id_instituicao=:id_instituicao ' +
      'AND c.id=:id_curso LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_curso').AsLargeInt := AIdCurso;
    Qry.Open;

    if not Qry.IsEmpty and
       not Qry.FieldByName('id_entidade_atendida').IsNull then
      Result := Qry.FieldByName('id_entidade_atendida').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.ExisteModeloCertificadoAtivo(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdModelo: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or
     (AIdModelo <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM certificado_modelo ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id_modelo ' +
      'AND situacao = ''ATIVO'' ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_modelo').AsLargeInt :=
      AIdModelo;

    Qry.Open;

    Result :=
      not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoTurmaCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO turma (' +
      'id_instituicao, ' +
      'id_curso, ' +
      'id_entidade_atendida, ' +
      'id_modelo_certificado, ' +
      'codigo_publico, ' +
      'codigo_interno, ' +
      'nome, ' +
      'modalidade, ' +
      'tipo_fluxo, ' +
      'data_hora_inicio, ' +
      'data_hora_fim, ' +
      'inscricao_inicio, ' +
      'inscricao_fim, ' +
      'limite_participantes, ' +
      'local, ' +
      'url_online, ' +
      'carga_horaria_minutos, ' +
      'permitir_inscricao_publica, ' +
      'aprovacao_inscricao, ' +
      'controle_presenca, ' +
      'exigir_presenca_conclusao, ' +
      'conclusao_automatica, ' +
      'certificado_automatico, ' +
      'situacao, ' +
      'criado_por' +
      ') VALUES (' +
      ':id_instituicao, ' +
      ':id_curso, ' +
      ':id_entidade_atendida, ' +
      ':id_modelo_certificado, ' +
      ':codigo_publico, ' +
      ':codigo_interno, ' +
      ':nome, ' +
      ':modalidade, ' +
      ':tipo_fluxo, ' +
      ':data_hora_inicio, ' +
      ':data_hora_fim, ' +
      ':inscricao_inicio, ' +
      ':inscricao_fim, ' +
      ':limite_participantes, ' +
      ':local, ' +
      ':url_online, ' +
      ':carga_horaria_minutos, ' +
      ':permitir_inscricao_publica, ' +
      ':aprovacao_inscricao, ' +
      ':controle_presenca, ' +
      ':exigir_presenca_conclusao, ' +
      ':conclusao_automatica, ' +
      ':certificado_automatico, ' +
      ':situacao, ' +
      ':criado_por' +
      ')';

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id_curso').AsLargeInt :=
      ADados.IdCurso;

    if ADados.IdEntidadeAtendida > 0 then
      Qry.ParamByName('id_entidade_atendida').AsLargeInt :=
        ADados.IdEntidadeAtendida
    else
      Qry.ParamByName('id_entidade_atendida').Clear;

    if ADados.IdModeloCertificado > 0 then
      Qry.ParamByName('id_modelo_certificado').AsLargeInt :=
        ADados.IdModeloCertificado
    else
      Qry.ParamByName('id_modelo_certificado').Clear;

    Qry.ParamByName('codigo_publico').AsString :=
      ADados.CodigoPublico;

    if not ADados.CodigoInterno.IsEmpty then
      Qry.ParamByName('codigo_interno').AsString :=
        ADados.CodigoInterno
    else
      Qry.ParamByName('codigo_interno').Clear;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    Qry.ParamByName('modalidade').AsString :=
      ADados.Modalidade;

    Qry.ParamByName('tipo_fluxo').AsString :=
      ADados.TipoFluxo;

    Qry.ParamByName('data_hora_inicio').AsDateTime :=
      ADados.DataHoraInicio;

    Qry.ParamByName('data_hora_fim').AsDateTime :=
      ADados.DataHoraFim;

    if ADados.TemInscricaoInicio then
      Qry.ParamByName('inscricao_inicio').AsDateTime :=
        ADados.InscricaoInicio
    else
      Qry.ParamByName('inscricao_inicio').Clear;

    if ADados.TemInscricaoFim then
      Qry.ParamByName('inscricao_fim').AsDateTime :=
        ADados.InscricaoFim
    else
      Qry.ParamByName('inscricao_fim').Clear;

    if ADados.TemLimiteParticipantes then
      Qry.ParamByName('limite_participantes').AsInteger :=
        ADados.LimiteParticipantes
    else
      Qry.ParamByName('limite_participantes').Clear;

    if not ADados.Local.IsEmpty then
      Qry.ParamByName('local').AsString :=
        ADados.Local
    else
      Qry.ParamByName('local').Clear;

    if not ADados.UrlOnline.IsEmpty then
      Qry.ParamByName('url_online').AsString :=
        ADados.UrlOnline
    else
      Qry.ParamByName('url_online').Clear;

    if ADados.TemCargaHorariaMinutos then
      Qry.ParamByName('carga_horaria_minutos').AsInteger :=
        ADados.CargaHorariaMinutos
    else
      Qry.ParamByName('carga_horaria_minutos').Clear;

    Qry.ParamByName('permitir_inscricao_publica').AsBoolean :=
      ADados.PermitirInscricaoPublica;
    Qry.ParamByName('aprovacao_inscricao').AsString := ADados.AprovacaoInscricao;
    Qry.ParamByName('controle_presenca').AsString := ADados.ControlePresenca;
    Qry.ParamByName('exigir_presenca_conclusao').AsBoolean := ADados.ExigirPresencaConclusao;
    Qry.ParamByName('conclusao_automatica').AsBoolean := ADados.ConclusaoAutomatica;
    Qry.ParamByName('certificado_automatico').AsBoolean := ADados.CertificadoAutomatico;

    Qry.ParamByName('situacao').AsString :=
      ADados.Situacao;

    Qry.ParamByName('criado_por').AsLargeInt :=
      ADados.CriadoPor;

    Qry.ExecSQL;

    Qry.SQL.Text :=
      'SELECT LAST_INSERT_ID() AS id';

    Qry.Open;

    Result :=
      Qry.FieldByName('id').AsLargeInt;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64;
  const ADados: TInstituicaoTurmaAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE turma SET ' +
      'id_curso = :id_curso, ' +
      'id_entidade_atendida = :id_entidade_atendida, ' +
      'id_modelo_certificado = :id_modelo_certificado, ' +
      'codigo_interno = :codigo_interno, ' +
      'nome = :nome, ' +
      'modalidade = :modalidade, ' +
      'tipo_fluxo = :tipo_fluxo, ' +
      'data_hora_inicio = :data_hora_inicio, ' +
      'data_hora_fim = :data_hora_fim, ' +
      'inscricao_inicio = :inscricao_inicio, ' +
      'inscricao_fim = :inscricao_fim, ' +
      'limite_participantes = :limite_participantes, ' +
      'local = :local, ' +
      'url_online = :url_online, ' +
      'carga_horaria_minutos = :carga_horaria_minutos, ' +
      'permitir_inscricao_publica = :permitir_inscricao_publica, ' +
      'aprovacao_inscricao = :aprovacao_inscricao, ' +
      'controle_presenca = :controle_presenca, ' +
      'exigir_presenca_conclusao = :exigir_presenca_conclusao, ' +
      'conclusao_automatica = :conclusao_automatica, ' +
      'certificado_automatico = :certificado_automatico, ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('id_curso').AsLargeInt :=
      ADados.IdCurso;

    if ADados.IdEntidadeAtendida > 0 then
      Qry.ParamByName('id_entidade_atendida').AsLargeInt :=
        ADados.IdEntidadeAtendida
    else
      Qry.ParamByName('id_entidade_atendida').Clear;

    if ADados.IdModeloCertificado > 0 then
      Qry.ParamByName('id_modelo_certificado').AsLargeInt :=
        ADados.IdModeloCertificado
    else
      Qry.ParamByName('id_modelo_certificado').Clear;

    if not ADados.CodigoInterno.IsEmpty then
      Qry.ParamByName('codigo_interno').AsString :=
        ADados.CodigoInterno
    else
      Qry.ParamByName('codigo_interno').Clear;

    Qry.ParamByName('nome').AsString :=
      ADados.Nome;

    Qry.ParamByName('modalidade').AsString :=
      ADados.Modalidade;

    Qry.ParamByName('tipo_fluxo').AsString :=
      ADados.TipoFluxo;

    Qry.ParamByName('data_hora_inicio').AsDateTime :=
      ADados.DataHoraInicio;

    Qry.ParamByName('data_hora_fim').AsDateTime :=
      ADados.DataHoraFim;

    if ADados.TemInscricaoInicio then
      Qry.ParamByName('inscricao_inicio').AsDateTime :=
        ADados.InscricaoInicio
    else
      Qry.ParamByName('inscricao_inicio').Clear;

    if ADados.TemInscricaoFim then
      Qry.ParamByName('inscricao_fim').AsDateTime :=
        ADados.InscricaoFim
    else
      Qry.ParamByName('inscricao_fim').Clear;

    if ADados.TemLimiteParticipantes then
      Qry.ParamByName('limite_participantes').AsInteger :=
        ADados.LimiteParticipantes
    else
      Qry.ParamByName('limite_participantes').Clear;

    if not ADados.Local.IsEmpty then
      Qry.ParamByName('local').AsString :=
        ADados.Local
    else
      Qry.ParamByName('local').Clear;

    if not ADados.UrlOnline.IsEmpty then
      Qry.ParamByName('url_online').AsString :=
        ADados.UrlOnline
    else
      Qry.ParamByName('url_online').Clear;

    if ADados.TemCargaHorariaMinutos then
      Qry.ParamByName('carga_horaria_minutos').AsInteger :=
        ADados.CargaHorariaMinutos
    else
      Qry.ParamByName('carga_horaria_minutos').Clear;

    Qry.ParamByName('permitir_inscricao_publica').AsBoolean :=
      ADados.PermitirInscricaoPublica;

    Qry.ParamByName('aprovacao_inscricao').AsString :=
      ADados.AprovacaoInscricao;

    Qry.ParamByName('controle_presenca').AsString :=
      ADados.ControlePresenca;

    Qry.ParamByName('exigir_presenca_conclusao').AsBoolean :=
      ADados.ExigirPresencaConclusao;

    Qry.ParamByName('conclusao_automatica').AsBoolean :=
      ADados.ConclusaoAutomatica;

    Qry.ParamByName('certificado_automatico').AsBoolean :=
      ADados.CertificadoAutomatico;

    Qry.ParamByName('situacao').AsString :=
      ADados.Situacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdTurma;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdTurma: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE turma SET ' +
      'situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao ' +
      'AND id = :id';

    Qry.ParamByName('situacao').AsString :=
      ASituacao;

    Qry.ParamByName('id_instituicao').AsLargeInt :=
      AIdInstituicao;

    Qry.ParamByName('id').AsLargeInt :=
      AIdTurma;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

end.
