unit ContratoResponsavel.DAO;

interface

uses
  Uni,
  ContratoResponsavel.Model;

type
  TContratoResponsavelDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoResponsavelLista; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64;
      const ADados: TContratoResponsavelCadastro
    ): Int64; static;

    class procedure Inativar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdResponsavel: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TContratoResponsavelDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoResponsavelLista;
var
  Qry: TUniQuery;
  Item: TContratoResponsavelItem;
begin
  Result := TContratoResponsavelLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,id_usuario_instituicao,nome,funcao,numero_designacao,data_inicio,data_fim,ativo ' +
      'FROM contrato_responsavel ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato ' +
      'ORDER BY ativo DESC,funcao,nome';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoResponsavelItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      if not Qry.FieldByName('id_usuario_instituicao').IsNull then
        Item.IdUsuarioInstituicao := Qry.FieldByName('id_usuario_instituicao').AsLargeInt;
      Item.Nome := Qry.FieldByName('nome').AsString;
      Item.Funcao := Qry.FieldByName('funcao').AsString;
      Item.NumeroDesignacao := Qry.FieldByName('numero_designacao').AsString;
      if not Qry.FieldByName('data_inicio').IsNull then
        Item.DataInicio := Qry.FieldByName('data_inicio').AsDateTime;
      if not Qry.FieldByName('data_fim').IsNull then
        Item.DataFim := Qry.FieldByName('data_fim').AsDateTime;
      Item.Ativo := Qry.FieldByName('ativo').AsBoolean;
      Result.Add(Item);
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

class function TContratoResponsavelDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64;
  const ADados: TContratoResponsavelCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_responsavel ' +
      '(id_instituicao,id_contrato,id_usuario_instituicao,nome,funcao,numero_designacao,data_inicio,data_fim,ativo) ' +
      'VALUES(:id_instituicao,:id_contrato,:id_usuario,:nome,:funcao,:numero_designacao,:data_inicio,:data_fim,:ativo)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    if ADados.IdUsuarioInstituicao > 0 then Qry.ParamByName('id_usuario').AsLargeInt := ADados.IdUsuarioInstituicao else Qry.ParamByName('id_usuario').Clear;
    Qry.ParamByName('nome').AsString := Trim(ADados.Nome);
    Qry.ParamByName('funcao').AsString := UpperCase(Trim(ADados.Funcao));
    if Trim(ADados.NumeroDesignacao).IsEmpty then Qry.ParamByName('numero_designacao').Clear else Qry.ParamByName('numero_designacao').AsString := Trim(ADados.NumeroDesignacao);
    if ADados.DataInicio > 0 then Qry.ParamByName('data_inicio').AsDateTime := ADados.DataInicio else Qry.ParamByName('data_inicio').Clear;
    if ADados.DataFim > 0 then Qry.ParamByName('data_fim').AsDateTime := ADados.DataFim else Qry.ParamByName('data_fim').Clear;
    Qry.ParamByName('ativo').AsBoolean := ADados.Ativo;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoResponsavelDAO.Inativar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdResponsavel: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE contrato_responsavel SET ativo=0,data_fim=COALESCE(data_fim,CURRENT_DATE) ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato AND id=:id';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('id').AsLargeInt := AIdResponsavel;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
