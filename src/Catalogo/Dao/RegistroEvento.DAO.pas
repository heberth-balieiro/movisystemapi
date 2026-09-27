unit RegistroEvento.DAO;

interface

uses
  Uni,
  RegistroEvento.Model,
  System.Generics.Collections;

type
  TRegistroEventoDAO = class
  public
    class function Inserir(
      const AConn: TUniConnection;
      const ARegistro: TRegistroEventoModel
    ): Int64; static;

    class function ListarPorEmpresa(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ): TObjectList<TRegistroEventoModel>; static;

    class function BuscarPorEntidade(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AEntidade: string;
      const AIdEntidade: Int64
    ): TObjectList<TRegistroEventoModel>; static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const ARegistro: TRegistroEventoModel);
begin
  ARegistro.IdRegistro := Qry.FieldByName('id_registro').AsLargeInt;

  if not Qry.FieldByName('id_empresa').IsNull then
    ARegistro.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;

  if not Qry.FieldByName('id_usuario').IsNull then
    ARegistro.IdUsuario := Qry.FieldByName('id_usuario').AsLargeInt;

  ARegistro.Origem := Qry.FieldByName('origem').AsString;
  ARegistro.Tipo := Qry.FieldByName('tipo').AsString;
  ARegistro.Entidade := Qry.FieldByName('entidade').AsString;

  if not Qry.FieldByName('id_entidade').IsNull then
    ARegistro.IdEntidade := Qry.FieldByName('id_entidade').AsLargeInt;

  ARegistro.Titulo := Qry.FieldByName('titulo').AsString;
  ARegistro.Mensagem := Qry.FieldByName('mensagem').AsString;
  ARegistro.DadosJson := Qry.FieldByName('dados_json').AsString;
  ARegistro.Nivel := Qry.FieldByName('nivel').AsString;
  ARegistro.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;
end;

class function TRegistroEventoDAO.Inserir(
  const AConn: TUniConnection;
  const ARegistro: TRegistroEventoModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO registro_evento (' +
      ' id_empresa, id_usuario, origem, tipo, entidade, id_entidade, ' +
      ' titulo, mensagem, dados_json, nivel ' +
      ') VALUES (' +
      ' :id_empresa, :id_usuario, :origem, :tipo, :entidade, :id_entidade, ' +
      ' :titulo, :mensagem, :dados_json, :nivel ' +
      ')';

    if ARegistro.IdEmpresa > 0 then
      Qry.ParamByName('id_empresa').AsLargeInt := ARegistro.IdEmpresa
    else
      Qry.ParamByName('id_empresa').Clear;

    if ARegistro.IdUsuario > 0 then
      Qry.ParamByName('id_usuario').AsLargeInt := ARegistro.IdUsuario
    else
      Qry.ParamByName('id_usuario').Clear;

    Qry.ParamByName('origem').AsString := UpperCase(Trim(ARegistro.Origem));
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ARegistro.Tipo));
    Qry.ParamByName('entidade').AsString := LowerCase(Trim(ARegistro.Entidade));

    if ARegistro.IdEntidade > 0 then
      Qry.ParamByName('id_entidade').AsLargeInt := ARegistro.IdEntidade
    else
      Qry.ParamByName('id_entidade').Clear;

    Qry.ParamByName('titulo').AsString := Trim(ARegistro.Titulo);
    Qry.ParamByName('mensagem').AsString := Trim(ARegistro.Mensagem);

    if Trim(ARegistro.DadosJson).IsEmpty then
      Qry.ParamByName('dados_json').Clear
    else
      Qry.ParamByName('dados_json').AsString := Trim(ARegistro.DadosJson);

    Qry.ParamByName('nivel').AsString := UpperCase(Trim(ARegistro.Nivel));

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_registro';
    Qry.Open;

    Result := Qry.FieldByName('id_registro').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TRegistroEventoDAO.ListarPorEmpresa(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
): TObjectList<TRegistroEventoModel>;
var
  Qry: TUniQuery;
  Registro: TRegistroEventoModel;
begin
  Result := TObjectList<TRegistroEventoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_registro, id_empresa, id_usuario, origem, tipo, entidade, id_entidade, ' +
      ' titulo, mensagem, dados_json, nivel, data_criacao ' +
      'FROM registro_evento ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY data_criacao DESC, id_registro DESC ' +
      'LIMIT 200';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      Registro := TRegistroEventoModel.Create;
      PreencherModel(Qry, Registro);
      Result.Add(Registro);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TRegistroEventoDAO.BuscarPorEntidade(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const AEntidade: string;
  const AIdEntidade: Int64
): TObjectList<TRegistroEventoModel>;
var
  Qry: TUniQuery;
  Registro: TRegistroEventoModel;
begin
  Result := TObjectList<TRegistroEventoModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_registro, id_empresa, id_usuario, origem, tipo, entidade, id_entidade, ' +
      ' titulo, mensagem, dados_json, nivel, data_criacao ' +
      'FROM registro_evento ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND LOWER(TRIM(entidade)) = LOWER(TRIM(:entidade)) ' +
      'AND id_entidade = :id_entidade ' +
      'ORDER BY data_criacao DESC, id_registro DESC';

    Qry.ParamByName('id_empresa').AsLargeInt    := AIdEmpresa;
    Qry.ParamByName('entidade').AsString        := Trim(AEntidade);
    Qry.ParamByName('id_entidade').AsLargeInt   := AIdEntidade;
    Qry.Open;

    while not Qry.Eof do
    begin
      Registro := TRegistroEventoModel.Create;
      PreencherModel(Qry, Registro);
      Result.Add(Registro);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

end.
