unit InstituicaoTurmaCriterioConclusao.DAO;

interface

uses
  Uni,
  InstituicaoTurmaCriterioConclusao.Model;

type
  TInstituicaoTurmaCriterioConclusaoDAO = class
  private
    class function MontarWhere(const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro): string; static;
    class procedure AplicarParametros(const AQry: TUniQuery; const AIdInstituicao, AIdTurma: Int64;
      const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TInstituicaoTurmaCriterioConclusaoItem; static;
  public
    class function TurmaExiste(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64): Boolean; static;
    class function Listar(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
      const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro): TInstituicaoTurmaCriterioConclusaoLista; static;
    class function BuscarPorId(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64): TInstituicaoTurmaCriterioConclusaoItem; static;
    class function Inserir(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
      const ADados: TInstituicaoTurmaCriterioConclusaoCadastro): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64; const ADados: TInstituicaoTurmaCriterioConclusaoAlteracao); static;
    class procedure AlterarSituacao(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64; const ASituacao: string); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoTurmaCriterioConclusaoDAO.MontarWhere(
  const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro): string;
begin
  Result := ' WHERE tc.id_instituicao = :id_instituicao AND tc.id_turma = :id_turma ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result + 'AND tc.nome LIKE :busca ';

  if not Trim(AFiltro.Tipo).IsEmpty then
    Result := Result + 'AND tc.tipo = :tipo ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + 'AND tc.situacao = :situacao ';
end;

class procedure TInstituicaoTurmaCriterioConclusaoDAO.AplicarParametros(
  const AQry: TUniQuery; const AIdInstituicao, AIdTurma: Int64;
  const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
  AQry.ParamByName('id_turma').AsLargeInt := AIdTurma;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Tipo).IsEmpty then
    AQry.ParamByName('tipo').AsString := UpperCase(Trim(AFiltro.Tipo));

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoTurmaCriterioConclusaoDAO.MapearItem(
  const AQry: TUniQuery): TInstituicaoTurmaCriterioConclusaoItem;
begin
  Result := TInstituicaoTurmaCriterioConclusaoItem.Create;
  Result.Id := AQry.FieldByName('id').AsLargeInt;
  Result.IdTurma := AQry.FieldByName('id_turma').AsLargeInt;
  Result.Tipo := AQry.FieldByName('tipo').AsString;
  Result.Nome := AQry.FieldByName('nome').AsString;
  Result.Obrigatorio := AQry.FieldByName('obrigatorio').AsBoolean;
  Result.TemConfiguracao := not AQry.FieldByName('configuracao').IsNull;

  if Result.TemConfiguracao then
    Result.Configuracao := AQry.FieldByName('configuracao').AsString;

  Result.Ordem := AQry.FieldByName('ordem').AsInteger;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.CriadoEm := AQry.FieldByName('criado_em').AsDateTime;
  Result.AtualizadoEm := AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoTurmaCriterioConclusaoDAO.TurmaExiste(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or (AIdTurma <= 0) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM turma ' +
      'WHERE id_instituicao = :id_instituicao AND id = :id_turma LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoDAO.Listar(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
  const AFiltro: TInstituicaoTurmaCriterioConclusaoFiltro): TInstituicaoTurmaCriterioConclusaoLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoTurmaCriterioConclusaoLista.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;
      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text := 'SELECT COUNT(*) AS total FROM turma_criterio_conclusao tc ' + WhereSQL;
      AplicarParametros(Qry, AIdInstituicao, AIdTurma, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT tc.id, tc.id_turma, tc.tipo, tc.nome, tc.obrigatorio, tc.configuracao, ' +
        'tc.ordem, tc.situacao, tc.criado_em, tc.atualizado_em ' +
        'FROM turma_criterio_conclusao tc ' + WhereSQL +
        'ORDER BY tc.ordem, tc.id LIMIT :limite OFFSET :offset';

      AplicarParametros(Qry, AIdInstituicao, AIdTurma, AFiltro);
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

class function TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdCriterio: Int64): TInstituicaoTurmaCriterioConclusaoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT tc.id, tc.id_turma, tc.tipo, tc.nome, tc.obrigatorio, tc.configuracao, ' +
      'tc.ordem, tc.situacao, tc.criado_em, tc.atualizado_em ' +
      'FROM turma_criterio_conclusao tc ' +
      'WHERE tc.id_instituicao = :id_instituicao AND tc.id_turma = :id_turma ' +
      'AND tc.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdCriterio;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoDAO.Inserir(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
  const ADados: TInstituicaoTurmaCriterioConclusaoCadastro): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_criterio_conclusao (' +
      'id_instituicao, id_turma, tipo, nome, obrigatorio, configuracao, ordem, situacao' +
      ') VALUES (' +
      ':id_instituicao, :id_turma, :tipo, :nome, :obrigatorio, :configuracao, :ordem, ''ATIVO'')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('tipo').AsString := ADados.Tipo;
    Qry.ParamByName('nome').AsString := ADados.Nome;
    Qry.ParamByName('obrigatorio').AsBoolean := ADados.Obrigatorio;

    if ADados.TemConfiguracao then
      Qry.ParamByName('configuracao').AsString := ADados.Configuracao
    else
      Qry.ParamByName('configuracao').Clear;

    Qry.ParamByName('ordem').AsInteger := ADados.Ordem;
    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaCriterioConclusaoDAO.Atualizar(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdCriterio: Int64; const ADados: TInstituicaoTurmaCriterioConclusaoAlteracao);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE turma_criterio_conclusao SET ' +
      'tipo = :tipo, nome = :nome, obrigatorio = :obrigatorio, ' +
      'configuracao = :configuracao, ordem = :ordem ' +
      'WHERE id_instituicao = :id_instituicao AND id_turma = :id_turma AND id = :id';

    Qry.ParamByName('tipo').AsString := ADados.Tipo;
    Qry.ParamByName('nome').AsString := ADados.Nome;
    Qry.ParamByName('obrigatorio').AsBoolean := ADados.Obrigatorio;

    if ADados.TemConfiguracao then
      Qry.ParamByName('configuracao').AsString := ADados.Configuracao
    else
      Qry.ParamByName('configuracao').Clear;

    Qry.ParamByName('ordem').AsInteger := ADados.Ordem;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdCriterio;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaCriterioConclusaoDAO.AlterarSituacao(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdCriterio: Int64; const ASituacao: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE turma_criterio_conclusao SET situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao AND id_turma = :id_turma AND id = :id';

    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdCriterio;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
