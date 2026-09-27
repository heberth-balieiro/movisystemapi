unit Marca.DAO;

interface

uses
  System.SysUtils,
  Uni,
  Marca.Model,
  System.Generics.Collections;

type
  TMarcaDAO = class
  private

  public
    class function ExisteNome(const AConn: TUniConnection; Const AIdEmpresa: Int64; const ANome: string; Const AIdMarcaIgnorar: Int64 = 0): Boolean; static;
    class function MarcaPossuiProduto(const AConn: TUniConnection; const AIdEmpresa, AIdMarca: Int64): Boolean; static;

    class function Inserir(const AConn: TUniConnection; const Aidempresa:Int64; Const AMarca: TMarcaModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection; Const AIdEmpresa, AidMarca:Int64; Const AMarca: TMarcaModel); static;
    class function Excluir(const AConn: TUniConnection; Const AIdEmpresa, AIdMarca: Int64):Boolean; static;

    class function Listar(const AConn: TUniConnection; const AIdEmpresa: Int64; const APesquisa: string): TObjectList<TMarcaModel>; static;
    class function BuscarPorId(const AConn: TUniConnection; Const AIdEmpresa, AIdMarca: Int64): TMarcaModel; static;

  end;

implementation

{ TMarcaDAO }

{$REGION 'Funcao'}

class function TMarcaDAO.ExisteNome(const AConn: TUniConnection; Const AIdEmpresa: Int64; const ANome: string; Const AIdMarcaIgnorar: Int64 = 0): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' SELECT COUNT(*) AS total ' +
      ' FROM marca ' +
      ' WHERE id_empresa = :id_empresa ' +
      '   AND UPPER(nome) = UPPER(:nome) ';

    if AIdMarcaIgnorar > 0 then
      Qry.SQL.Add(' AND id_marca <> :id_marca ');

    Qry.ParamByName('id_empresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('nome').AsString := Trim(ANome);

    if AIdMarcaIgnorar > 0 then
      Qry.ParamByName('id_marca').AsInteger := AIdMarcaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;

  finally
    Qry.Free;
  end;
end;

class function TMarcaDAO.MarcaPossuiProduto(const AConn: TUniConnection;const AIdEmpresa, AIdMarca: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from produto ' +
      ' where id_empresa = :id_empresa ' +
      ' and id_marca = :id_marca';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_marca').AsLargeInt := AIdMarca;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'CRUD'}

class function TMarcaDAO.Inserir(const AConn: TUniConnection; const Aidempresa:Int64; Const AMarca: TMarcaModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' INSERT INTO marca ' +
      '   (id_empresa, nome, descricao, ativo, ordem, data_criacao) ' +
      ' VALUES ' +
      '   (:id_empresa, :nome, :descricao, :ativo, :ordem, NOW()) ';

    Qry.ParamByName('id_empresa').AsInteger := Aidempresa;
    Qry.ParamByName('nome').AsString        := Trim(AMarca.Nome);
    Qry.ParamByName('descricao').AsString   := Trim(AMarca.Descricao);
    Qry.ParamByName('ativo').AsString       := AMarca.Ativo;
    Qry.ParamByName('ordem').AsInteger      := AMarca.Ordem;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := ' SELECT LAST_INSERT_ID() AS id_marca ';
    Qry.Open;

    Result := Qry.FieldByName('id_marca').AsInteger;

  finally
    Qry.Free;
  end;
end;

class procedure TMarcaDAO.Atualizar(const AConn: TUniConnection; Const AIdEmpresa, AidMarca:Int64; Const AMarca: TMarcaModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' UPDATE marca SET ' +
      '   nome = :nome, ' +
      '   descricao = :descricao, ' +
      '   ativo = :ativo, ' +
      '   ordem = :ordem, ' +
      '   data_alteracao = NOW() ' +
      ' WHERE id_empresa = :id_empresa ' +
      '   AND id_marca = :id_marca ';

    Qry.ParamByName('id_marca').AsInteger   := AidMarca;
    Qry.ParamByName('id_empresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('nome').AsString        := Trim(AMarca.Nome);
    Qry.ParamByName('descricao').AsString   := Trim(AMarca.Descricao);
    Qry.ParamByName('ativo').AsString       := AMarca.Ativo;
    Qry.ParamByName('ordem').AsInteger      := AMarca.Ordem;

    Qry.Execute;

  finally
    Qry.Free;
  end;
end;

class function TMarcaDAO.Excluir(const AConn: TUniConnection; Const AIdEmpresa, AIdMarca: Int64):Boolean;
var
  Qry: TUniQuery;
begin
  Result  := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' Delete from marca where id_empresa = :id_empresa ' +
      ' and id_marca = :id_marca ';

    Qry.ParamByName('id_empresa').AsLargeInt  := AIdEmpresa;
    Qry.ParamByName('id_marca').AsLargeInt    := AIdMarca;

    Qry.Execute;
    Result  := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;


{$ENDREGION}


{$REGION 'Pesquisas'}

class function TMarcaDAO.BuscarPorId(const AConn: TUniConnection; Const AIdEmpresa, AIdMarca: Int64): TMarcaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' SELECT ' +
      '   m.id_marca, ' +
      '   m.id_empresa, ' +
      '   m.nome, ' +
      '   m.descricao, ' +
      '   m.ativo, ' +
      '   m.ordem, ' +
      '   m.data_criacao, ' +
      '   m.data_alteracao, ' +
      '   COUNT(p.id_produto) AS produto_qtde ' +
      ' FROM marca m ' +
      ' LEFT JOIN produto p ' +
      '   ON p.id_marca = m.id_marca ' +
      '  AND p.id_empresa = m.id_empresa ' +
      ' WHERE m.id_empresa = :id_empresa ' +
      '   AND m.id_marca = :id_marca ' +
      ' GROUP BY ' +
      '   m.id_marca, ' +
      '   m.id_empresa, ' +
      '   m.nome, ' +
      '   m.descricao, ' +
      '   m.ativo, ' +
      '   m.ordem, ' +
      '   m.data_criacao, ' +
      '   m.data_alteracao ';

    Qry.ParamByName('id_empresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('id_marca').AsInteger := AIdMarca;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TMarcaModel.Create;

    Result.IdMarca     := Qry.FieldByName('id_marca').AsInteger;
    Result.IdEmpresa   := Qry.FieldByName('id_empresa').AsInteger;
    Result.Nome        := Qry.FieldByName('nome').AsString;
    Result.Descricao   := Qry.FieldByName('descricao').AsString;
    Result.Ativo       := Qry.FieldByName('ativo').AsString;
    Result.Ordem       := Qry.FieldByName('ordem').AsInteger;
    Result.ProdutoQtde := Qry.FieldByName('produto_qtde').AsInteger;


  finally
    Qry.Free;
  end;
end;

class function TMarcaDAO.Listar(const AConn: TUniConnection;const AIdEmpresa: Int64; const APesquisa: string): TObjectList<TMarcaModel>;
var
  Qry: TUniQuery;
  Marca: TMarcaModel;
begin
  Result := TObjectList<TMarcaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      ' SELECT ' +
      '   m.id_marca, ' +
      '   m.id_empresa, ' +
      '   m.nome, ' +
      '   m.descricao, ' +
      '   m.ativo, ' +
      '   m.ordem, ' +
      '   m.data_criacao, ' +
      '   m.data_alteracao, ' +
      '   COUNT(p.id_produto) AS produto_qtde ' +
      ' FROM marca m ' +
      ' LEFT JOIN produto p ' +
      '   ON p.id_marca = m.id_marca ' +
      '  AND p.id_empresa = m.id_empresa ' +
      ' WHERE m.id_empresa = :id_empresa ' +
      ' GROUP BY ' +
      '   m.id_marca, ' +
      '   m.id_empresa, ' +
      '   m.nome, ' +
      '   m.descricao, ' +
      '   m.ativo, ' +
      '   m.ordem, ' +
      '   m.data_criacao, ' +
      '   m.data_alteracao ' +
      ' ORDER BY m.ordem, m.nome ';

    Qry.ParamByName('id_empresa').AsInteger := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Marca := TMarcaModel.Create;

      Marca.IdMarca     := Qry.FieldByName('id_marca').AsInteger;
      Marca.IdEmpresa   := Qry.FieldByName('id_empresa').AsInteger;
      Marca.Nome        := Qry.FieldByName('nome').AsString;
      Marca.Descricao   := Qry.FieldByName('descricao').AsString;
      Marca.Ativo       := Qry.FieldByName('ativo').AsString;
      Marca.Ordem       := Qry.FieldByName('ordem').AsInteger;
      Marca.ProdutoQtde := Qry.FieldByName('produto_qtde').AsInteger;

      Result.Add(Marca);

      Qry.Next;
    end;

  finally
    Qry.Free;
  end;
end;

{$ENDREGION}


end.
