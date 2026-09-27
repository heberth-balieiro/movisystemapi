unit Ajuda.DAO;

interface

uses
  Uni,
  Ajuda.Model,
  System.Generics.Collections;

type
  TAjudaDAO = class
  public
    class function ExisteTitulo(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const ATitulo: string;
      const AIdAjudaIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AAjuda: TAjudaModel
    ): Int64; static;

    class function ListarPorEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AApenasAtivos: Boolean = False
    ): TObjectList<TAjudaModel>; static;

    class function BuscarPorIdEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdAjuda: Int64
    ): TAjudaModel; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AAjuda: TAjudaModel
    ); static;

    class procedure Excluir(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AIdAjuda: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const AAjuda: TAjudaModel);
begin
  AAjuda.IdAjuda := Qry.FieldByName('id_ajuda').AsLargeInt;
  AAjuda.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
  AAjuda.Ordem := Qry.FieldByName('ordem').AsInteger;
  AAjuda.Titulo := Qry.FieldByName('titulo').AsString;
  AAjuda.Url := Qry.FieldByName('url').AsString;
  AAjuda.Descricao := Qry.FieldByName('descricao').AsString;
  AAjuda.Ativo := Qry.FieldByName('ativo').AsString;
  AAjuda.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    AAjuda.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TAjudaDAO.ExisteTitulo(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const ATitulo: string;
  const AIdAjudaIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM ajuda ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND LOWER(TRIM(titulo)) = LOWER(TRIM(:titulo)) ';

    if AIdAjudaIgnorar > 0 then
      Qry.SQL.Add('AND id_ajuda <> :id_ajuda');

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('titulo').AsString := Trim(ATitulo);

    if AIdAjudaIgnorar > 0 then
      Qry.ParamByName('id_ajuda').AsLargeInt := AIdAjudaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TAjudaDAO.Inserir(
  const AConn: TUniConnection;
  const AAjuda: TAjudaModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO ajuda (' +
      ' id_empresa, ordem, titulo, url, descricao, ativo ' +
      ') VALUES (' +
      ' :id_empresa, :ordem, :titulo, :url, :descricao, :ativo ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := AAjuda.IdEmpresa;
    Qry.ParamByName('ordem').AsInteger := AAjuda.Ordem;
    Qry.ParamByName('titulo').AsString := Trim(AAjuda.Titulo);
    Qry.ParamByName('url').AsString := Trim(AAjuda.Url);
    Qry.ParamByName('descricao').AsString := Trim(AAjuda.Descricao);
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AAjuda.Ativo));

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_ajuda';
    Qry.Open;

    Result := Qry.FieldByName('id_ajuda').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TAjudaDAO.ListarPorEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AApenasAtivos: Boolean
): TObjectList<TAjudaModel>;
var
  Qry: TUniQuery;
  Ajuda: TAjudaModel;
begin
  Result := TObjectList<TAjudaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_ajuda, id_empresa, ordem, titulo, url, descricao, ativo, ' +
      ' data_criacao, data_alteracao ' +
      'FROM ajuda ' +
      'WHERE id_empresa = :id_empresa ';

    if AApenasAtivos then
      Qry.SQL.Add('AND ativo = ''S'' ');

    Qry.SQL.Add('ORDER BY ordem, titulo');

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Ajuda := TAjudaModel.Create;
      PreencherModel(Qry, Ajuda);
      Result.Add(Ajuda);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TAjudaDAO.BuscarPorIdEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdAjuda: Int64
): TAjudaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_ajuda, id_empresa, ordem, titulo, url, descricao, ativo, ' +
      ' data_criacao, data_alteracao ' +
      'FROM ajuda ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_ajuda = :id_ajuda ' +
      'LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_ajuda').AsLargeInt := AIdAjuda;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TAjudaModel.Create;
    PreencherModel(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class procedure TAjudaDAO.Atualizar(
  const AConn: TUniConnection;
  const AAjuda: TAjudaModel
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE ajuda SET ' +
      ' ordem = :ordem, ' +
      ' titulo = :titulo, ' +
      ' url = :url, ' +
      ' descricao = :descricao, ' +
      ' ativo = :ativo, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_ajuda = :id_ajuda';

    Qry.ParamByName('ordem').AsInteger := AAjuda.Ordem;
    Qry.ParamByName('titulo').AsString := Trim(AAjuda.Titulo);
    Qry.ParamByName('url').AsString := Trim(AAjuda.Url);
    Qry.ParamByName('descricao').AsString := Trim(AAjuda.Descricao);
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AAjuda.Ativo));
    Qry.ParamByName('id_empresa').AsLargeInt := AAjuda.IdEmpresa;
    Qry.ParamByName('id_ajuda').AsLargeInt := AAjuda.IdAjuda;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TAjudaDAO.Excluir(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AIdAjuda: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM ajuda ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_ajuda = :id_ajuda';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_ajuda').AsLargeInt := AIdAjuda;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
