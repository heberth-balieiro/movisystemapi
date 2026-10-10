unit EleicaoListaPublicaAPI.Dao;

interface

uses
  System.JSON,
  Uni;

type
  TEleicaoListaPublicaAPIDao = class
  public
    class function ListarProcessosPublicos(
      const AConn: TUniConnection
    ): TJSONArray; static;
  end;

implementation

uses
  System.SysUtils;

class function TEleicaoListaPublicaAPIDao.ListarProcessosPublicos(
  const AConn: TUniConnection
): TJSONArray;
var
  Qry: TUniQuery;
  Item: TJSONObject;
  Situacao: string;
begin
  Result := TJSONArray.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      '  e.id, ' +
      '  e.empresa_id, ' +
      '  e.nome, ' +
      '  COALESCE(e.descricao, '''') AS descricao, ' +
      '  COALESCE(e.operacao, '''') AS operacao, ' +
      '  CASE ' +
      '    WHEN UPPER(TRIM(COALESCE(e.situacao, ''''))) = ''AGENDADA'' ' +
      '      AND ec.data_hora_inicio IS NOT NULL ' +
      '      AND ec.data_hora_inicio <= NOW() ' +
      '      AND (ec.data_hora_fim IS NULL OR ec.data_hora_fim >= NOW()) ' +
      '    THEN ''ABERTA'' ' +
      '    ELSE UPPER(TRIM(COALESCE(e.situacao, ''''))) ' +
      '  END AS situacao_publica, ' +
      '  ec.slug, ' +
      '  COALESCE(ec.nome_exibicao, '''') AS nome_exibicao, ' +
      '  COALESCE(ec.logo, '''') AS logo, ' +
      '  COALESCE(ec.banner, '''') AS banner, ' +
      '  ec.data_hora_inicio, ' +
      '  ec.data_hora_fim, ' +
      '  COALESCE(NULLIF(emp.fantasia, ''''), emp.razao) AS empresa_nome ' +
      'FROM eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id = e.id ' +
      '  AND ec.empresa_id = e.empresa_id ' +
      'INNER JOIN empresa emp ON emp.id = e.empresa_id ' +
      'WHERE e.ativo = ''S'' ' +
      '  AND ec.pagina_publicar = ''S'' ' +
      '  AND COALESCE(TRIM(ec.slug), '''') <> '''' ' +
      '  AND ( ' +
      '    UPPER(TRIM(COALESCE(e.situacao, ''''))) = ''ABERTA'' ' +
      '    OR ( ' +
      '      UPPER(TRIM(COALESCE(e.situacao, ''''))) = ''AGENDADA'' ' +
      '      AND (ec.data_hora_fim IS NULL OR ec.data_hora_fim >= NOW()) ' +
      '    ) ' +
      '  ) ' +
      'ORDER BY ' +
      '  CASE ' +
      '    WHEN UPPER(TRIM(COALESCE(e.situacao, ''''))) = ''ABERTA'' THEN 0 ' +
      '    WHEN ec.data_hora_inicio IS NOT NULL AND ec.data_hora_inicio <= NOW() THEN 0 ' +
      '    ELSE 1 ' +
      '  END, ' +
      '  ec.data_hora_inicio, e.id';
    Qry.Open;

    while not Qry.Eof do
    begin
      Situacao := UpperCase(Trim(Qry.FieldByName('situacao_publica').AsString));

      Item := TJSONObject.Create;
      Item.AddPair('id', TJSONNumber.Create(Qry.FieldByName('id').AsInteger));
      Item.AddPair('empresa_id', TJSONNumber.Create(Qry.FieldByName('empresa_id').AsInteger));
      Item.AddPair('empresa', Qry.FieldByName('empresa_nome').AsString);
      Item.AddPair('nome', Qry.FieldByName('nome').AsString);
      Item.AddPair('nome_exibicao', Qry.FieldByName('nome_exibicao').AsString);
      Item.AddPair('descricao', Qry.FieldByName('descricao').AsString);
      Item.AddPair('operacao', UpperCase(Trim(Qry.FieldByName('operacao').AsString)));
      Item.AddPair('situacao', Situacao);
      Item.AddPair('slug', Qry.FieldByName('slug').AsString);
      Item.AddPair('logo', Qry.FieldByName('logo').AsString);
      Item.AddPair('banner', Qry.FieldByName('banner').AsString);

      if not Qry.FieldByName('data_hora_inicio').IsNull then
        Item.AddPair(
          'data_hora_inicio',
          FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Qry.FieldByName('data_hora_inicio').AsDateTime)
        )
      else
        Item.AddPair('data_hora_inicio', '');

      if not Qry.FieldByName('data_hora_fim').IsNull then
        Item.AddPair(
          'data_hora_fim',
          FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Qry.FieldByName('data_hora_fim').AsDateTime)
        )
      else
        Item.AddPair('data_hora_fim', '');

      Result.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

end.
