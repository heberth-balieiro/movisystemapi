unit PlataformaModulo.DAO;

interface

uses
  Uni,
  System.Generics.Collections,
  PlataformaModulo.Model;

type
  TPlataformaModuloDAO = class
  public
    class function ListarCatalogo(
      const AConn: TUniConnection
    ): TObjectList<TPlataformaModuloItem>; static;

    class function ListarCodigosInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TList<string>; static;

    class function CodigoAtivoExiste(
      const AConn: TUniConnection;
      const ACodigo: string
    ): Boolean; static;

    class procedure SalvarModulosInstituicao(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdUsuarioAcao: Int64;
      const ACodigos: TList<string>
    ); static;

    class function InstituicaoPossuiModulo(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ACodigo: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

class function TPlataformaModuloDAO.ListarCatalogo(
  const AConn: TUniConnection
): TObjectList<TPlataformaModuloItem>;
var
  Qry: TUniQuery;
  Item: TPlataformaModuloItem;
begin
  Result := TObjectList<TPlataformaModuloItem>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id, codigo, nome, descricao, situacao, ordem ' +
      'FROM plataforma_modulo ' +
      'WHERE situacao = ''ATIVO'' ' +
      'ORDER BY ordem, nome, id';
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TPlataformaModuloItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.Codigo := Qry.FieldByName('codigo').AsString;
      Item.Nome := Qry.FieldByName('nome').AsString;
      Item.Descricao := Qry.FieldByName('descricao').AsString;
      Item.Situacao := Qry.FieldByName('situacao').AsString;
      Item.Ordem := Qry.FieldByName('ordem').AsInteger;
      Result.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaModuloDAO.ListarCodigosInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TList<string>;
var
  Qry: TUniQuery;
begin
  Result := TList<string>.Create;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT m.codigo ' +
      'FROM instituicao_modulo im ' +
      'JOIN plataforma_modulo m ON m.id = im.id_modulo ' +
      'WHERE im.id_instituicao = :id_instituicao ' +
      'AND im.ativo = 1 ' +
      'AND m.situacao = ''ATIVO'' ' +
      'ORDER BY m.ordem, m.codigo';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Result.Add(
        UpperCase(
          Trim(
            Qry.FieldByName('codigo').AsString
          )
        )
      );
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaModuloDAO.CodigoAtivoExiste(
  const AConn: TUniConnection;
  const ACodigo: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 FROM plataforma_modulo ' +
      'WHERE codigo = :codigo AND situacao = ''ATIVO'' LIMIT 1';
    Qry.ParamByName('codigo').AsString :=
      UpperCase(Trim(ACodigo));
    Qry.Open;
    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class procedure TPlataformaModuloDAO.SalvarModulosInstituicao(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdUsuarioAcao: Int64;
  const ACodigos: TList<string>
);
var
  Qry: TUniQuery;
  Codigo: string;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE instituicao_modulo ' +
      'SET ativo = 0, atualizado_em = CURRENT_TIMESTAMP(3) ' +
      'WHERE id_instituicao = :id_instituicao';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.Execute;

    Qry.SQL.Text :=
      'INSERT INTO instituicao_modulo ' +
      '(id_instituicao, id_modulo, ativo, liberado_por, liberado_em) ' +
      'SELECT :id_instituicao, m.id, 1, :liberado_por, CURRENT_TIMESTAMP(3) ' +
      'FROM plataforma_modulo m ' +
      'WHERE m.codigo = :codigo AND m.situacao = ''ATIVO'' ' +
      'ON DUPLICATE KEY UPDATE ' +
      'ativo = 1, ' +
      'liberado_por = VALUES(liberado_por), ' +
      'liberado_em = CURRENT_TIMESTAMP(3), ' +
      'atualizado_em = CURRENT_TIMESTAMP(3)';

    for Codigo in ACodigos do
    begin
      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;

      if AIdUsuarioAcao > 0 then
        Qry.ParamByName('liberado_por').AsLargeInt := AIdUsuarioAcao
      else
        Qry.ParamByName('liberado_por').Clear;

      Qry.ParamByName('codigo').AsString :=
        UpperCase(Trim(Codigo));
      Qry.Execute;
    end;
  finally
    Qry.Free;
  end;
end;

class function TPlataformaModuloDAO.InstituicaoPossuiModulo(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ACodigo: string
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if (AIdInstituicao <= 0) or Trim(ACodigo).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM instituicao_modulo im ' +
      'JOIN plataforma_modulo m ON m.id = im.id_modulo ' +
      'WHERE im.id_instituicao = :id_instituicao ' +
      'AND im.ativo = 1 ' +
      'AND m.situacao = ''ATIVO'' ' +
      'AND m.codigo = :codigo ' +
      'LIMIT 1';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('codigo').AsString := UpperCase(Trim(ACodigo));
    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

end.
