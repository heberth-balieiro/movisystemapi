unit PlataformaAuditoria.DAO;

interface

uses
  Uni,
  PlataformaAuditoria.Model;

type
  TPlataformaAuditoriaDAO = class
  private
    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AFiltro: TPlataformaAuditoriaFiltro
    ); static;

    class function MontarWhere(
      const AFiltro: TPlataformaAuditoriaFiltro
    ): string; static;
  public
    class function Listar(
      const AConn: TUniConnection;
      const AFiltro: TPlataformaAuditoriaFiltro
    ): TPlataformaAuditoriaResultado; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

class function TPlataformaAuditoriaDAO.MontarWhere(
  const AFiltro: TPlataformaAuditoriaFiltro
): string;
begin
  // A auditoria da plataforma é separada pela rota administrativa global.
  Result :=
    ' WHERE a.rota LIKE ''/v1/certifica/plataforma/%'' ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (' +
      'u.nome LIKE :busca OR ' +
      'u.email LIKE :busca OR ' +
      'a.acao LIKE :busca OR ' +
      'a.entidade LIKE :busca OR ' +
      'a.registro_id LIKE :busca OR ' +
      'a.mensagem LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Acao).IsEmpty then
    Result := Result + ' AND a.acao = :acao ';

  if AFiltro.TemDataInicio then
    Result := Result + ' AND a.criado_em >= :data_inicio ';

  if AFiltro.TemDataFim then
    Result := Result + ' AND a.criado_em < :data_fim ';
end;

class procedure TPlataformaAuditoriaDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AFiltro: TPlataformaAuditoriaFiltro
);
begin
  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Acao).IsEmpty then
    AQry.ParamByName('acao').AsString :=
      UpperCase(Trim(AFiltro.Acao));

  if AFiltro.TemDataInicio then
    AQry.ParamByName('data_inicio').AsDateTime :=
      StartOfTheDay(AFiltro.DataInicio);

  // Utilizamos < dia seguinte para incluir corretamente todo o último dia.
  if AFiltro.TemDataFim then
    AQry.ParamByName('data_fim').AsDateTime :=
      StartOfTheDay(AFiltro.DataFim + 1);
end;

class function TPlataformaAuditoriaDAO.Listar(
  const AConn: TUniConnection;
  const AFiltro: TPlataformaAuditoriaFiltro
): TPlataformaAuditoriaResultado;
var
  Qry: TUniQuery;
  Item: TPlataformaAuditoriaItem;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TPlataformaAuditoriaResultado.Create;

  Result.Pagina := AFiltro.Pagina;
  Result.PorPagina := AFiltro.PorPagina;

  WhereSQL := MontarWhere(AFiltro);
  Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    // Total para paginação.
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM auditoria_log a ' +
      'LEFT JOIN usuario u ON u.id = a.id_usuario ' +
      WhereSQL;

    AplicarParametros(Qry, AFiltro);
    Qry.Open;

    Result.Total := Qry.FieldByName('total').AsInteger;

    Qry.Close;
    Qry.SQL.Clear;

    Qry.SQL.Text :=
      'SELECT ' +
      'a.id, ' +
      'a.criado_em, ' +
      'a.id_usuario, ' +
      'u.nome AS usuario_nome, ' +
      'u.email AS usuario_email, ' +
      'a.acao, ' +
      'a.entidade, ' +
      'a.registro_id, ' +
      'a.metodo_http, ' +
      'a.rota, ' +
      'a.ip, ' +
      'a.sucesso, ' +
      'a.mensagem ' +
      'FROM auditoria_log a ' +
      'LEFT JOIN usuario u ON u.id = a.id_usuario ' +
      WhereSQL +
      'ORDER BY a.criado_em DESC, a.id DESC ' +
      'LIMIT :limite OFFSET :offset';

    AplicarParametros(Qry, AFiltro);

    Qry.ParamByName('limite').AsInteger := AFiltro.PorPagina;
    Qry.ParamByName('offset').AsInteger := Offset;

    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TPlataformaAuditoriaItem.Create;

      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;

      if not Qry.FieldByName('id_usuario').IsNull then
        Item.IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;

      Item.UsuarioNome := Qry.FieldByName('usuario_nome').AsString;
      Item.UsuarioEmail := Qry.FieldByName('usuario_email').AsString;
      Item.Acao := Qry.FieldByName('acao').AsString;
      Item.Entidade := Qry.FieldByName('entidade').AsString;
      Item.RegistroId := Qry.FieldByName('registro_id').AsString;
      Item.MetodoHttp := Qry.FieldByName('metodo_http').AsString;
      Item.Rota := Qry.FieldByName('rota').AsString;
      Item.IP := Qry.FieldByName('ip').AsString;

      // O UniDAC mapeia TINYINT(1) como Boolean.
      Item.Sucesso := Qry.FieldByName('sucesso').AsBoolean;

      Item.Mensagem := Qry.FieldByName('mensagem').AsString;

      Result.Itens.Add(Item);
      Qry.Next;
    end;

  except
    Result.Free;
    raise;
  end;

  Qry.Free;
end;

end.
