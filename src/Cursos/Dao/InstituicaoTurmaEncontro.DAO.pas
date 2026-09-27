unit InstituicaoTurmaEncontro.DAO;

interface

uses
  Uni,
  InstituicaoTurmaEncontro.Model;

type
  TInstituicaoTurmaEncontroDAO = class
  private
    class function MontarWhere(const AFiltro: TInstituicaoTurmaEncontroFiltro): string; static;
    class procedure AplicarParametros(const AQry: TUniQuery; const AIdInstituicao, AIdTurma: Int64;
      const AFiltro: TInstituicaoTurmaEncontroFiltro); static;
    class function MapearItem(const AQry: TUniQuery): TInstituicaoTurmaEncontroItem; static;
  public
    class function TurmaExiste(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64): Boolean; static;
    class function Listar(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
      const AFiltro: TInstituicaoTurmaEncontroFiltro): TInstituicaoTurmaEncontroLista; static;
    class function BuscarPorId(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64): TInstituicaoTurmaEncontroItem; static;
    class function Inserir(const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
      const ADados: TInstituicaoTurmaEncontroCadastro): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64; const ADados: TInstituicaoTurmaEncontroAlteracao); static;
    class procedure AlterarSituacao(const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64; const ASituacao: string); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoTurmaEncontroDAO.MontarWhere(
  const AFiltro: TInstituicaoTurmaEncontroFiltro): string;
begin
  Result := ' WHERE te.id_instituicao = :id_instituicao AND te.id_turma = :id_turma ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      'AND (te.titulo LIKE :busca OR te.descricao LIKE :busca OR te.local LIKE :busca) ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + 'AND te.situacao = :situacao ';
end;

class procedure TInstituicaoTurmaEncontroDAO.AplicarParametros(
  const AQry: TUniQuery; const AIdInstituicao, AIdTurma: Int64;
  const AFiltro: TInstituicaoTurmaEncontroFiltro);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
  AQry.ParamByName('id_turma').AsLargeInt := AIdTurma;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoTurmaEncontroDAO.MapearItem(
  const AQry: TUniQuery): TInstituicaoTurmaEncontroItem;
begin
  Result := TInstituicaoTurmaEncontroItem.Create;
  Result.Id := AQry.FieldByName('id').AsLargeInt;
  Result.IdTurma := AQry.FieldByName('id_turma').AsLargeInt;
  Result.Titulo := AQry.FieldByName('titulo').AsString;
  Result.Descricao := AQry.FieldByName('descricao').AsString;
  Result.DataHoraInicio := AQry.FieldByName('data_hora_inicio').AsDateTime;
  Result.DataHoraFim := AQry.FieldByName('data_hora_fim').AsDateTime;
  Result.TemCargaHoraria := not AQry.FieldByName('carga_horaria_minutos').IsNull;

  if Result.TemCargaHoraria then
    Result.CargaHorariaMinutos := AQry.FieldByName('carga_horaria_minutos').AsInteger;

  Result.Local := AQry.FieldByName('local').AsString;
  Result.UrlOnline := AQry.FieldByName('url_online').AsString;
  Result.Obrigatorio := AQry.FieldByName('obrigatorio').AsBoolean;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.CriadoEm := AQry.FieldByName('criado_em').AsDateTime;
  Result.AtualizadoEm := AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoTurmaEncontroDAO.TurmaExiste(
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

class function TInstituicaoTurmaEncontroDAO.Listar(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
  const AFiltro: TInstituicaoTurmaEncontroFiltro): TInstituicaoTurmaEncontroLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoTurmaEncontroLista.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;
      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text := 'SELECT COUNT(*) AS total FROM turma_encontro te ' + WhereSQL;
      AplicarParametros(Qry, AIdInstituicao, AIdTurma, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT te.id, te.id_turma, te.titulo, te.descricao, te.data_hora_inicio, ' +
        'te.data_hora_fim, te.carga_horaria_minutos, te.local, te.url_online, ' +
        'te.obrigatorio, te.situacao, te.criado_em, te.atualizado_em ' +
        'FROM turma_encontro te ' + WhereSQL +
        'ORDER BY te.data_hora_inicio, te.id LIMIT :limite OFFSET :offset';

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

class function TInstituicaoTurmaEncontroDAO.BuscarPorId(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdEncontro: Int64): TInstituicaoTurmaEncontroItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT te.id, te.id_turma, te.titulo, te.descricao, te.data_hora_inicio, ' +
      'te.data_hora_fim, te.carga_horaria_minutos, te.local, te.url_online, ' +
      'te.obrigatorio, te.situacao, te.criado_em, te.atualizado_em ' +
      'FROM turma_encontro te ' +
      'WHERE te.id_instituicao = :id_instituicao AND te.id_turma = :id_turma ' +
      'AND te.id = :id LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdEncontro;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoTurmaEncontroDAO.Inserir(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma: Int64;
  const ADados: TInstituicaoTurmaEncontroCadastro): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO turma_encontro (' +
      'id_instituicao, id_turma, titulo, descricao, data_hora_inicio, data_hora_fim, ' +
      'carga_horaria_minutos, local, url_online, obrigatorio, situacao) VALUES (' +
      ':id_instituicao, :id_turma, :titulo, :descricao, :data_hora_inicio, :data_hora_fim, ' +
      ':carga_horaria_minutos, :local, :url_online, :obrigatorio, ''AGENDADO'')';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('titulo').AsString := ADados.Titulo;

    if ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').Clear
    else
      Qry.ParamByName('descricao').AsString := ADados.Descricao;

    Qry.ParamByName('data_hora_inicio').AsDateTime := ADados.DataHoraInicio;
    Qry.ParamByName('data_hora_fim').AsDateTime := ADados.DataHoraFim;

    if ADados.CargaHorariaMinutos > 0 then
      Qry.ParamByName('carga_horaria_minutos').AsInteger := ADados.CargaHorariaMinutos
    else
      Qry.ParamByName('carga_horaria_minutos').Clear;

    if ADados.Local.IsEmpty then
      Qry.ParamByName('local').Clear
    else
      Qry.ParamByName('local').AsString := ADados.Local;

    if ADados.UrlOnline.IsEmpty then
      Qry.ParamByName('url_online').Clear
    else
      Qry.ParamByName('url_online').AsString := ADados.UrlOnline;

    Qry.ParamByName('obrigatorio').AsBoolean := ADados.Obrigatorio;
    Qry.ExecSQL;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaEncontroDAO.Atualizar(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdEncontro: Int64; const ADados: TInstituicaoTurmaEncontroAlteracao);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE turma_encontro SET titulo = :titulo, descricao = :descricao, ' +
      'data_hora_inicio = :data_hora_inicio, data_hora_fim = :data_hora_fim, ' +
      'carga_horaria_minutos = :carga_horaria_minutos, local = :local, ' +
      'url_online = :url_online, obrigatorio = :obrigatorio ' +
      'WHERE id_instituicao = :id_instituicao AND id_turma = :id_turma AND id = :id';

    Qry.ParamByName('titulo').AsString := ADados.Titulo;

    if ADados.Descricao.IsEmpty then
      Qry.ParamByName('descricao').Clear
    else
      Qry.ParamByName('descricao').AsString := ADados.Descricao;

    Qry.ParamByName('data_hora_inicio').AsDateTime := ADados.DataHoraInicio;
    Qry.ParamByName('data_hora_fim').AsDateTime := ADados.DataHoraFim;

    if ADados.CargaHorariaMinutos > 0 then
      Qry.ParamByName('carga_horaria_minutos').AsInteger := ADados.CargaHorariaMinutos
    else
      Qry.ParamByName('carga_horaria_minutos').Clear;

    if ADados.Local.IsEmpty then
      Qry.ParamByName('local').Clear
    else
      Qry.ParamByName('local').AsString := ADados.Local;

    if ADados.UrlOnline.IsEmpty then
      Qry.ParamByName('url_online').Clear
    else
      Qry.ParamByName('url_online').AsString := ADados.UrlOnline;

    Qry.ParamByName('obrigatorio').AsBoolean := ADados.Obrigatorio;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdEncontro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoTurmaEncontroDAO.AlterarSituacao(
  const AConn: TUniConnection; const AIdInstituicao, AIdTurma,
  AIdEncontro: Int64; const ASituacao: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE turma_encontro SET situacao = :situacao ' +
      'WHERE id_instituicao = :id_instituicao AND id_turma = :id_turma AND id = :id';

    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_turma').AsLargeInt := AIdTurma;
    Qry.ParamByName('id').AsLargeInt := AIdEncontro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
