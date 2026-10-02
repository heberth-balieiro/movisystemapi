unit InstituicaoRelatorioParticipante.DAO;

interface

uses
  System.Generics.Collections,
  Uni,
  InstituicaoRelatorioParticipante.Model;

type
  TInstituicaoRelatorioParticipanteDAO = class
  private
    class function MontarWhere(const AFiltro: TRelatorioParticipanteFiltro): string; static;
    class procedure AplicarFiltro(const AQry: TUniQuery; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioParticipanteFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TRelatorioParticipanteItem; static;
  public
    class function ListarFiltros(const AConn: TUniConnection;
      const AIdInstituicao: Int64): TRelatorioParticipanteFiltros; static;
    class function Listar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioParticipanteFiltro): TRelatorioParticipanteResultado; static;
    class function Exportar(const AConn: TUniConnection; const AIdInstituicao: Int64;
      const AFiltro: TRelatorioParticipanteFiltro): TObjectList<TRelatorioParticipanteItem>; static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoRelatorioParticipanteDAO.MontarWhere(
  const AFiltro: TRelatorioParticipanteFiltro): string;
begin
  Result := ' WHERE p.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    Result := Result +
      ' AND (p.nome LIKE :busca OR p.email LIKE :busca OR p.telefone LIKE :busca ';
    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      Result := Result + 'OR p.cpf_hash_busca = :cpf_hash_busca ';
    Result := Result + ') ';
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + ' AND p.situacao = :situacao ';

  if AFiltro.IdCurso > 0 then
    Result := Result +
      ' AND EXISTS (SELECT 1 FROM inscricao i ' +
      'JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
      'WHERE i.id_instituicao = p.id_instituicao ' +
      'AND i.id_participante = p.id AND t.id_curso = :id_curso) ';

  if AFiltro.IdTurma > 0 then
    Result := Result +
      ' AND EXISTS (SELECT 1 FROM inscricao i ' +
      'WHERE i.id_instituicao = p.id_instituicao ' +
      'AND i.id_participante = p.id AND i.id_turma = :id_turma) ';
end;

class procedure TInstituicaoRelatorioParticipanteDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioParticipanteFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
  begin
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';
    if not Trim(AFiltro.CpfHashBusca).IsEmpty then
      AQry.ParamByName('cpf_hash_busca').AsString := AFiltro.CpfHashBusca;
  end;

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));

  if AFiltro.IdCurso > 0 then
    AQry.ParamByName('id_curso').AsLargeInt := AFiltro.IdCurso;

  if AFiltro.IdTurma > 0 then
    AQry.ParamByName('id_turma').AsLargeInt := AFiltro.IdTurma;
end;

class function TInstituicaoRelatorioParticipanteDAO.MapearItem(
  const AQry: TUniQuery): TRelatorioParticipanteItem;
begin
  Result := TRelatorioParticipanteItem.Create;
  Result.IdParticipante := AQry.FieldByName('id_participante').AsLargeInt;
  Result.Nome := AQry.FieldByName('nome').AsString;
  Result.CpfMascarado := AQry.FieldByName('cpf_mascarado').AsString;
  Result.Email := AQry.FieldByName('email').AsString;
  Result.Telefone := AQry.FieldByName('telefone').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.TotalInscricoes := AQry.FieldByName('total_inscricoes').AsInteger;
  Result.TotalConclusoes := AQry.FieldByName('total_conclusoes').AsInteger;
  Result.TotalCertificados := AQry.FieldByName('total_certificados').AsInteger;
end;

class function TInstituicaoRelatorioParticipanteDAO.ListarFiltros(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64): TRelatorioParticipanteFiltros;
var
  Qry: TUniQuery;
  Item: TRelatorioParticipanteFiltroOpcao;
begin
  Result := TRelatorioParticipanteFiltros.Create;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;

      Qry.SQL.Text :=
        'SELECT DISTINCT c.id, c.nome ' +
        'FROM inscricao i ' +
        'JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        'JOIN curso c ON c.id_instituicao = t.id_instituicao AND c.id = t.id_curso ' +
        'WHERE i.id_instituicao = :id_instituicao ORDER BY c.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TRelatorioParticipanteFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Result.Cursos.Add(Item);
        Qry.Next;
      end;

      Qry.Close;
      Qry.SQL.Text :=
        'SELECT DISTINCT t.id, t.nome, t.id_curso ' +
        'FROM inscricao i ' +
        'JOIN turma t ON t.id_instituicao = i.id_instituicao AND t.id = i.id_turma ' +
        'WHERE i.id_instituicao = :id_instituicao ORDER BY t.nome';
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TRelatorioParticipanteFiltroOpcao.Create;
        Item.Id := Qry.FieldByName('id').AsLargeInt;
        Item.Nome := Qry.FieldByName('nome').AsString;
        Item.IdCurso := Qry.FieldByName('id_curso').AsLargeInt;
        Result.Turmas.Add(Item);
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

class function TInstituicaoRelatorioParticipanteDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioParticipanteFiltro): TRelatorioParticipanteResultado;
var
  Qry: TUniQuery;
  WhereSQL, SelectSQL: string;
  Offset: Integer;
  Resumo: TRelatorioParticipanteResumo;
begin
  Result := TRelatorioParticipanteResultado.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;
      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text := 'SELECT COUNT(*) AS total FROM participante p ' + WhereSQL;
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total_participantes, ' +
        'SUM(CASE WHEN p.situacao = ''ATIVO'' THEN 1 ELSE 0 END) AS ativos, ' +
        'SUM(CASE WHEN p.situacao = ''INATIVO'' THEN 1 ELSE 0 END) AS inativos, ' +
        'SUM(CASE WHEN p.situacao = ''ANONIMIZADO'' THEN 1 ELSE 0 END) AS anonimizados, ' +
        'COALESCE(SUM((SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id)),0) AS total_inscricoes, ' +
        'COALESCE(SUM((SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id AND i.situacao = ''CONCLUIDO'')),0) AS total_conclusoes, ' +
        'COALESCE(SUM((SELECT COUNT(*) FROM certificado c WHERE c.id_instituicao = p.id_instituicao AND c.id_participante = p.id AND c.situacao = ''VALIDO'')),0) AS total_certificados ' +
        'FROM participante p ' + WhereSQL;
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      Resumo := Default(TRelatorioParticipanteResumo);
      Resumo.TotalParticipantes := Qry.FieldByName('total_participantes').AsInteger;
      Resumo.Ativos := Qry.FieldByName('ativos').AsInteger;
      Resumo.Inativos := Qry.FieldByName('inativos').AsInteger;
      Resumo.Anonimizados := Qry.FieldByName('anonimizados').AsInteger;
      Resumo.TotalInscricoes := Qry.FieldByName('total_inscricoes').AsInteger;
      Resumo.TotalConclusoes := Qry.FieldByName('total_conclusoes').AsInteger;
      Resumo.TotalCertificados := Qry.FieldByName('total_certificados').AsInteger;
      Result.Resumo := Resumo;
      Qry.Close;

      SelectSQL :=
        'SELECT p.id AS id_participante, p.nome, p.cpf_mascarado, p.email, p.telefone, p.situacao, ' +
        '(SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id) AS total_inscricoes, ' +
        '(SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id AND i.situacao = ''CONCLUIDO'') AS total_conclusoes, ' +
        '(SELECT COUNT(*) FROM certificado c WHERE c.id_instituicao = p.id_instituicao AND c.id_participante = p.id AND c.situacao = ''VALIDO'') AS total_certificados ';

      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text := SelectSQL + 'FROM participante p ' + WhereSQL +
        'ORDER BY p.nome, p.id LIMIT :limite OFFSET :offset';
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
      Qry.ParamByName('offset').AsInteger := Offset;
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Itens.Add(MapearItem(Qry));
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

class function TInstituicaoRelatorioParticipanteDAO.Exportar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TRelatorioParticipanteFiltro): TObjectList<TRelatorioParticipanteItem>;
var
  Qry: TUniQuery;
  WhereSQL: string;
begin
  Result := TObjectList<TRelatorioParticipanteItem>.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      WhereSQL := MontarWhere(AFiltro);

      Qry.SQL.Text :=
        'SELECT p.id AS id_participante, p.nome, p.cpf_mascarado, p.email, p.telefone, p.situacao, ' +
        '(SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id) AS total_inscricoes, ' +
        '(SELECT COUNT(*) FROM inscricao i WHERE i.id_instituicao = p.id_instituicao AND i.id_participante = p.id AND i.situacao = ''CONCLUIDO'') AS total_conclusoes, ' +
        '(SELECT COUNT(*) FROM certificado c WHERE c.id_instituicao = p.id_instituicao AND c.id_participante = p.id AND c.situacao = ''VALIDO'') AS total_certificados ' +
        'FROM participante p ' + WhereSQL +
        'ORDER BY p.nome, p.id LIMIT 50001';

      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;

      while not Qry.Eof do
      begin
        Result.Add(MapearItem(Qry));
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
