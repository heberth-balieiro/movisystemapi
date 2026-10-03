unit InstituicaoEntidadeAtendida.DAO;

interface

uses
  Uni,
  InstituicaoEntidadeAtendida.Model;

type
  TInstituicaoEntidadeAtendidaDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoEntidadeAtendidaFiltro
    ): string; static;

    class procedure AplicarFiltro(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoEntidadeAtendidaFiltro
    ); static;

    class function MapearItem(
      const AQry: TUniQuery
    ): TInstituicaoEntidadeAtendidaItem; static;
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoEntidadeAtendidaFiltro
    ): TInstituicaoEntidadeAtendidaLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId: Int64
    ): TInstituicaoEntidadeAtendidaItem; static;

    class function ExisteAtiva(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId: Int64
    ): Boolean; static;

    class function ExisteDocumento(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADocumento: string;
      const AIdIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoEntidadeAtendidaCadastro
    ): Int64; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId: Int64;
      const ADados: TInstituicaoEntidadeAtendidaAlteracao
    ); static;

    class procedure AlterarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AId: Int64;
      const ASituacao: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TInstituicaoEntidadeAtendidaDAO.MontarWhere(
  const AFiltro: TInstituicaoEntidadeAtendidaFiltro
): string;
begin
  Result := ' WHERE e.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      'AND (e.nome LIKE :busca OR e.nome_fantasia LIKE :busca OR e.documento LIKE :busca) ';

  if not Trim(AFiltro.Tipo).IsEmpty then
    Result := Result + 'AND e.tipo = :tipo ';

  if not Trim(AFiltro.Situacao).IsEmpty then
    Result := Result + 'AND e.situacao = :situacao ';
end;

class procedure TInstituicaoEntidadeAtendidaDAO.AplicarFiltro(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoEntidadeAtendidaFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString := '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Tipo).IsEmpty then
    AQry.ParamByName('tipo').AsString := UpperCase(Trim(AFiltro.Tipo));

  if not Trim(AFiltro.Situacao).IsEmpty then
    AQry.ParamByName('situacao').AsString := UpperCase(Trim(AFiltro.Situacao));
end;

class function TInstituicaoEntidadeAtendidaDAO.MapearItem(
  const AQry: TUniQuery
): TInstituicaoEntidadeAtendidaItem;
begin
  Result := TInstituicaoEntidadeAtendidaItem.Create;
  Result.Id := AQry.FieldByName('id').AsLargeInt;
  Result.Nome := AQry.FieldByName('nome').AsString;
  Result.NomeFantasia := AQry.FieldByName('nome_fantasia').AsString;
  Result.Tipo := AQry.FieldByName('tipo').AsString;
  Result.Documento := AQry.FieldByName('documento').AsString;
  Result.Situacao := AQry.FieldByName('situacao').AsString;
  Result.Observacao := AQry.FieldByName('observacao').AsString;
  Result.CriadoEm := AQry.FieldByName('criado_em').AsDateTime;
  Result.AtualizadoEm := AQry.FieldByName('atualizado_em').AsDateTime;
end;

class function TInstituicaoEntidadeAtendidaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoEntidadeAtendidaFiltro
): TInstituicaoEntidadeAtendidaLista;
var
  Qry: TUniQuery;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoEntidadeAtendidaLista.Create;
  Qry := TUniQuery.Create(nil);

  try
    try
      Qry.Connection := AConn;
      Result.Pagina := AFiltro.Pagina;
      Result.PorPagina := AFiltro.PorPagina;

      WhereSQL := MontarWhere(AFiltro);
      Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

      Qry.SQL.Text :=
        'SELECT COUNT(*) AS total FROM entidade_atendida e ' +
        WhereSQL;
      AplicarFiltro(Qry, AIdInstituicao, AFiltro);
      Qry.Open;
      Result.Total := Qry.FieldByName('total').AsInteger;
      Qry.Close;

      Qry.SQL.Text :=
        'SELECT e.id,e.nome,e.nome_fantasia,e.tipo,e.documento,' +
        'e.situacao,e.observacao,e.criado_em,e.atualizado_em ' +
        'FROM entidade_atendida e ' +
        WhereSQL +
        'ORDER BY e.nome,e.id LIMIT :limite OFFSET :offset';

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

class function TInstituicaoEntidadeAtendidaDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId: Int64
): TInstituicaoEntidadeAtendidaItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT e.id,e.nome,e.nome_fantasia,e.tipo,e.documento,' +
      'e.situacao,e.observacao,e.criado_em,e.atualizado_em ' +
      'FROM entidade_atendida e ' +
      'WHERE e.id_instituicao=:id_instituicao AND e.id=:id LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := MapearItem(Qry);
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaDAO.ExisteAtiva(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if (AIdInstituicao <= 0) or (AId <= 0) then Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM entidade_atendida ' +
      'WHERE id_instituicao=:id_instituicao AND id=:id ' +
      'AND situacao=''ATIVO'' LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaDAO.ExisteDocumento(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADocumento: string;
  const AIdIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  if Trim(ADocumento).IsEmpty then Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM entidade_atendida ' +
      'WHERE id_instituicao=:id_instituicao AND documento=:documento ';

    if AIdIgnorar > 0 then
      Qry.SQL.Add('AND id<>:id_ignorar ');

    Qry.SQL.Add('LIMIT 1');
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('documento').AsString := ADocumento;

    if AIdIgnorar > 0 then
      Qry.ParamByName('id_ignorar').AsLargeInt := AIdIgnorar;

    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TInstituicaoEntidadeAtendidaDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoEntidadeAtendidaCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO entidade_atendida ' +
      '(id_instituicao,nome,nome_fantasia,tipo,documento,situacao,observacao) ' +
      'VALUES (:id_instituicao,:nome,:nome_fantasia,:tipo,:documento,:situacao,:observacao)';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('nome').AsString := ADados.Nome;

    if ADados.NomeFantasia.IsEmpty then Qry.ParamByName('nome_fantasia').Clear
    else Qry.ParamByName('nome_fantasia').AsString := ADados.NomeFantasia;

    Qry.ParamByName('tipo').AsString := ADados.Tipo;

    if ADados.Documento.IsEmpty then Qry.ParamByName('documento').Clear
    else Qry.ParamByName('documento').AsString := ADados.Documento;

    Qry.ParamByName('situacao').AsString := ADados.Situacao;

    if ADados.Observacao.IsEmpty then Qry.ParamByName('observacao').Clear
    else Qry.ParamByName('observacao').AsString := ADados.Observacao;

    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoEntidadeAtendidaDAO.Atualizar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId: Int64;
  const ADados: TInstituicaoEntidadeAtendidaAlteracao
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE entidade_atendida SET nome=:nome,nome_fantasia=:nome_fantasia,' +
      'tipo=:tipo,documento=:documento,situacao=:situacao,observacao=:observacao ' +
      'WHERE id_instituicao=:id_instituicao AND id=:id';

    Qry.ParamByName('nome').AsString := ADados.Nome;

    if ADados.NomeFantasia.IsEmpty then Qry.ParamByName('nome_fantasia').Clear
    else Qry.ParamByName('nome_fantasia').AsString := ADados.NomeFantasia;

    Qry.ParamByName('tipo').AsString := ADados.Tipo;

    if ADados.Documento.IsEmpty then Qry.ParamByName('documento').Clear
    else Qry.ParamByName('documento').AsString := ADados.Documento;

    Qry.ParamByName('situacao').AsString := ADados.Situacao;

    if ADados.Observacao.IsEmpty then Qry.ParamByName('observacao').Clear
    else Qry.ParamByName('observacao').AsString := ADados.Observacao;

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TInstituicaoEntidadeAtendidaDAO.AlterarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AId: Int64;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE entidade_atendida SET situacao=:situacao ' +
      'WHERE id_instituicao=:id_instituicao AND id=:id';
    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
