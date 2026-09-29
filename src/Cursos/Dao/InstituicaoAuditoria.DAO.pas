unit InstituicaoAuditoria.DAO;

interface

uses
  Uni,
  InstituicaoAuditoria.Model;

type
  TInstituicaoAuditoriaDAO = class
  private
    class function MontarWhere(
      const AFiltro: TInstituicaoAuditoriaFiltro
    ): string; static;

    class procedure AplicarParametros(
      const AQry: TUniQuery;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoAuditoriaFiltro
    ); static;

  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const AFiltro: TInstituicaoAuditoriaFiltro
    ): TInstituicaoAuditoriaResultado; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils;

class function TInstituicaoAuditoriaDAO.MontarWhere(
  const AFiltro: TInstituicaoAuditoriaFiltro
): string;
begin
  Result :=
    ' WHERE a.id_instituicao = :id_instituicao ';

  if not Trim(AFiltro.Busca).IsEmpty then
    Result := Result +
      ' AND (' +
      'u.nome LIKE :busca OR ' +
      'u.email LIKE :busca OR ' +
      'a.acao LIKE :busca OR ' +
      'a.entidade LIKE :busca OR ' +
      'a.registro_id LIKE :busca OR ' +
      'a.rota LIKE :busca OR ' +
      'a.mensagem LIKE :busca' +
      ') ';

  if not Trim(AFiltro.Acao).IsEmpty then
    Result := Result +
      ' AND a.acao = :acao ';

  if not Trim(AFiltro.Entidade).IsEmpty then
    Result := Result +
      ' AND a.entidade = :entidade ';

  if AFiltro.TemDataInicio then
    Result := Result +
      ' AND a.criado_em >= :data_inicio ';

  if AFiltro.TemDataFim then
    Result := Result +
      ' AND a.criado_em < :data_fim ';
end;

class procedure TInstituicaoAuditoriaDAO.AplicarParametros(
  const AQry: TUniQuery;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoAuditoriaFiltro
);
begin
  AQry.ParamByName('id_instituicao').AsLargeInt :=
    AIdInstituicao;

  if not Trim(AFiltro.Busca).IsEmpty then
    AQry.ParamByName('busca').AsString :=
      '%' + Trim(AFiltro.Busca) + '%';

  if not Trim(AFiltro.Acao).IsEmpty then
    AQry.ParamByName('acao').AsString :=
      UpperCase(Trim(AFiltro.Acao));

  if not Trim(AFiltro.Entidade).IsEmpty then
    AQry.ParamByName('entidade').AsString :=
      LowerCase(Trim(AFiltro.Entidade));

  if AFiltro.TemDataInicio then
    AQry.ParamByName('data_inicio').AsDateTime :=
      StartOfTheDay(AFiltro.DataInicio);

  if AFiltro.TemDataFim then
    AQry.ParamByName('data_fim').AsDateTime :=
      StartOfTheDay(AFiltro.DataFim + 1);
end;

class function TInstituicaoAuditoriaDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const AFiltro: TInstituicaoAuditoriaFiltro
): TInstituicaoAuditoriaResultado;
var
  Qry: TUniQuery;
  Item: TInstituicaoAuditoriaItem;
  WhereSQL: string;
  Offset: Integer;
begin
  Result := TInstituicaoAuditoriaResultado.Create;
  Result.Pagina := AFiltro.Pagina;
  Result.PorPagina := AFiltro.PorPagina;

  WhereSQL := MontarWhere(AFiltro);
  Offset := (AFiltro.Pagina - 1) * AFiltro.PorPagina;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM auditoria_log a ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = a.id_instituicao ' +
      ' AND ui.id = a.id_usuario_instituicao ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      WhereSQL;

    AplicarParametros(
      Qry,
      AIdInstituicao,
      AFiltro
    );

    Qry.Open;
    Result.Total := Qry.FieldByName('total').AsInteger;

    Qry.Close;
    Qry.SQL.Clear;

    Qry.SQL.Text :=
      'SELECT ' +
      'a.id, a.criado_em, a.id_usuario_instituicao, ' +
      'u.nome AS usuario_nome, ' +
      'a.acao, a.entidade, a.registro_id, ' +
      'a.metodo_http, a.rota, a.ip, a.sucesso, a.mensagem ' +
      'FROM auditoria_log a ' +
      'LEFT JOIN usuario_instituicao ui ' +
      '  ON ui.id_instituicao = a.id_instituicao ' +
      ' AND ui.id = a.id_usuario_instituicao ' +
      'LEFT JOIN usuario u ON u.id = ui.id_usuario ' +
      WhereSQL +
      'ORDER BY a.criado_em DESC, a.id DESC ' +
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
      Item := TInstituicaoAuditoriaItem.Create;

      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;

      if not Qry.FieldByName('id_usuario_instituicao').IsNull then
        Item.IdUsuarioInstituicao :=
          Qry.FieldByName('id_usuario_instituicao').AsLargeInt;

      Item.UsuarioNome := Qry.FieldByName('usuario_nome').AsString;
      Item.Acao := Qry.FieldByName('acao').AsString;
      Item.Entidade := Qry.FieldByName('entidade').AsString;
      Item.RegistroId := Qry.FieldByName('registro_id').AsString;
      Item.MetodoHttp := Qry.FieldByName('metodo_http').AsString;
      Item.Rota := Qry.FieldByName('rota').AsString;
      Item.IP := Qry.FieldByName('ip').AsString;
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
