unit Segmento.DAO;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Uni,
  Segmento.Model;

type
  TSegmentoDAO = class
  public
    class function ExisteNome(const AConn: TUniConnection;const ANome: string; const AIdSegmentoIgnorar: Int64 = 0): Boolean; static;
    class function Inserir(const AConn: TUniConnection;const ASegmento: TSegmentoModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection; const ASegmento: TSegmentoModel); static;
    class function Excluir(const AConn: TUniConnection;const AIdSegmento: Int64): Boolean; static;
    class function Listar(const AConn: TUniConnection;const APesquisa: string = ''): TObjectList<TSegmentoModel>; static;
    class function BuscarPorId(const AConn: TUniConnection; const AIdSegmento: Int64): TSegmentoModel; static;
    class function SegmentoPossuiCatalogo(const AConn: TUniConnection; const AIDEmpresa: int64; const AIdSegmento: Int64): Boolean; static;
    class function ListarDash(const AConn: TUniConnection): TObjectList<TSegmentoModel>; static;
  end;

implementation

class function TSegmentoDAO.ExisteNome(const AConn: TUniConnection;const ANome: string; const AIdSegmentoIgnorar: Int64 = 0): Boolean;
var
  Qry: TUniQuery;
const
  QryStr =
    'select count(*) as total ' +
    'from segmento ' +
    'where upper(nome) = upper(:nome) ' +
    '  and (:id_segmento_ignorar = 0 or id_segmento <> :id_segmento_ignorar)';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;

    Qry.ParamByName('nome').AsString := Trim(ANome);
    Qry.ParamByName('id_segmento_ignorar').AsLargeInt := AIdSegmentoIgnorar;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.Inserir(const AConn: TUniConnection;const ASegmento: TSegmentoModel): Int64;
var
  Qry: TUniQuery;
const
  QryStr =
    'insert into segmento ( ' +
    '  nome, descricao, ativo, ordem, data_criacao ' +
    ') values ( ' +
    '  :nome, :descricao, :ativo, :ordem, now() ' +
    ')';

  QryIdStr = 'select last_insert_id() as id_segmento';
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;

    Qry.ParamByName('nome').AsString := ASegmento.Nome;
    Qry.ParamByName('descricao').AsString := ASegmento.Descricao;
    Qry.ParamByName('ativo').AsString := ASegmento.Ativo;
    Qry.ParamByName('ordem').AsInteger := ASegmento.Ordem;
    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := QryIdStr;
    Qry.Open;

    Result := Qry.FieldByName('id_segmento').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TSegmentoDAO.Atualizar(const AConn: TUniConnection; const ASegmento: TSegmentoModel);
var
  Qry: TUniQuery;
const
  QryStr =
    'update segmento set ' +
    '  nome = :nome, ' +
    '  descricao = :descricao, ' +
    '  ativo = :ativo, ' +
    '  ordem = :ordem, ' +
    '  data_alteracao = now() ' +
    'where id_segmento = :id_segmento';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;
    Qry.ParamByName('nome').AsString          := ASegmento.Nome;
    Qry.ParamByName('descricao').AsString     := ASegmento.Descricao;
    Qry.ParamByName('ativo').AsString         := ASegmento.Ativo;
    Qry.ParamByName('ordem').AsInteger        := ASegmento.Ordem;
    Qry.ParamByName('id_segmento').AsLargeInt := ASegmento.IdSegmento;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.Excluir(const AConn: TUniConnection;const AIdSegmento: Int64): Boolean;
var
  Qry: TUniQuery;
const
  QryStr =
    'delete from segmento ' +
    'where id_segmento = :id_segmento';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;
    Qry.ParamByName('id_segmento').AsLargeInt := AIdSegmento;
    Qry.Execute;

    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.Listar(const AConn: TUniConnection;const APesquisa: string = ''): TObjectList<TSegmentoModel>;
var
  Qry: TUniQuery;
  Item: TSegmentoModel;
  SQL: string;
begin
  Result := TObjectList<TSegmentoModel>.Create(True);

  SQL :=
    'select ' +
    '  id_segmento, nome, descricao, ativo, ordem ' +
    ' from segmento ' +
    ' where 1=1 ';

  if Trim(APesquisa) <> '' then
    SQL := SQL +
      'and (upper(nome) like upper(:pesquisa) ' +
      ' or upper(descricao) like upper(:pesquisa)) ';

  SQL := SQL + 'order by ordem, nome';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;

    if Trim(APesquisa) <> '' then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Item              := TSegmentoModel.Create;
      Item.IdSegmento   := Qry.FieldByName('id_segmento').AsLargeInt;
      Item.Nome         := Qry.FieldByName('nome').AsString;
      Item.Descricao    := Qry.FieldByName('descricao').AsString;
      Item.Ativo        := Qry.FieldByName('ativo').AsString;
      Item.Ordem        := Qry.FieldByName('ordem').AsInteger;

      Result.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.ListarDash(const AConn: TUniConnection): TObjectList<TSegmentoModel>;
var
  Qry: TUniQuery;
  Segmento  :TSegmentoModel;
Const
  QryStr = 'select id_segmento, nome, descricao, ordem from segmento where ativo=''S'' order by ordem';
begin
  Result := TObjectList<TSegmentoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := QryStr;
    Qry.Open;
    qry.First;

    while not Qry.Eof do
    begin

      Segmento  := TSegmentoModel.Create;

      Segmento.IdSegmento   := Qry.FieldByName('id_segmento').AsLargeInt;
      Segmento.Nome         := Qry.FieldByName('nome').AsString;
      Segmento.Descricao    := Qry.FieldByName('descricao').AsString;
      Segmento.Ordem        := Qry.FieldByName('ordem').AsInteger;

      Result.Add(segmento);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.BuscarPorId(const AConn: TUniConnection; const AIdSegmento: Int64): TSegmentoModel;
var
  Qry: TUniQuery;
const
  QryStr =
    'select ' +
    '  id_segmento, nome, descricao, ativo, ordem' +
    ' from segmento ' +
    ' where id_segmento = :id_segmento ' +
    ' limit 1';
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;
    Qry.ParamByName('id_segmento').AsLargeInt := AIdSegmento;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result              := TSegmentoModel.Create;
    Result.IdSegmento   := Qry.FieldByName('id_segmento').AsLargeInt;
    Result.Nome         := Qry.FieldByName('nome').AsString;
    Result.Descricao    := Qry.FieldByName('descricao').AsString;
    Result.Ativo        := Qry.FieldByName('ativo').AsString;
    Result.Ordem        := Qry.FieldByName('ordem').AsInteger;
    
  finally
    Qry.Free;
  end;
end;

class function TSegmentoDAO.SegmentoPossuiCatalogo(const AConn: TUniConnection;const AIDEmpresa: int64; const AIdSegmento: Int64): Boolean;
var
  Qry: TUniQuery;
const
  QryStr =
    'select count(*) as total ' +
    'from catalogo_config ' +
    'where id_empresa = :id_empresa ' +
    '  and id_segmento = :id_segmento';
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := QryStr;
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_segmento').AsLargeInt := AIdSegmento;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

end.
