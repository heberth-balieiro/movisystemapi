unit ContratoAditivo.DAO;

interface

uses
  Uni,
  ContratoAditivo.Model;

type
  TContratoAditivoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoAditivoLista; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ADados: TContratoAditivoCadastro
    ): Int64; static;
  end;

implementation

uses
  System.SysUtils;

class function TContratoAditivoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoAditivoLista;
var
  Qry: TUniQuery;
  Item: TContratoAditivoItem;
begin
  Result := TContratoAditivoLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,numero,tipo,data_assinatura,nova_data_fim,valor_acrescimo,valor_supressao,justificativa,criado_em ' +
      'FROM contrato_aditivo ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato ' +
      'ORDER BY criado_em DESC,id DESC';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoAditivoItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.Numero := Qry.FieldByName('numero').AsString;
      Item.Tipo := Qry.FieldByName('tipo').AsString;
      if not Qry.FieldByName('data_assinatura').IsNull then
        Item.DataAssinatura := Qry.FieldByName('data_assinatura').AsDateTime;
      if not Qry.FieldByName('nova_data_fim').IsNull then
        Item.NovaDataFim := Qry.FieldByName('nova_data_fim').AsDateTime;
      Item.ValorAcrescimo := Qry.FieldByName('valor_acrescimo').AsFloat;
      Item.ValorSupressao := Qry.FieldByName('valor_supressao').AsFloat;
      Item.Justificativa := Qry.FieldByName('justificativa').AsString;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;
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

class function TContratoAditivoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ADados: TContratoAditivoCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_aditivo ' +
      '(id_instituicao,id_contrato,numero,tipo,data_assinatura,nova_data_fim,valor_acrescimo,valor_supressao,justificativa,criado_por) ' +
      'VALUES(:id_instituicao,:id_contrato,:numero,:tipo,:data_assinatura,:nova_data_fim,:valor_acrescimo,:valor_supressao,:justificativa,:criado_por)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('numero').AsString := Trim(ADados.Numero);
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ADados.Tipo));
    if ADados.DataAssinatura > 0 then Qry.ParamByName('data_assinatura').AsDateTime := ADados.DataAssinatura else Qry.ParamByName('data_assinatura').Clear;
    if ADados.NovaDataFim > 0 then Qry.ParamByName('nova_data_fim').AsDateTime := ADados.NovaDataFim else Qry.ParamByName('nova_data_fim').Clear;
    Qry.ParamByName('valor_acrescimo').AsFloat := ADados.ValorAcrescimo;
    Qry.ParamByName('valor_supressao').AsFloat := ADados.ValorSupressao;
    if Trim(ADados.Justificativa).IsEmpty then Qry.ParamByName('justificativa').Clear else Qry.ParamByName('justificativa').AsString := Trim(ADados.Justificativa);
    Qry.ParamByName('criado_por').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

end.
