unit ContratoFiscalizacao.DAO;

interface

uses
  Uni,
  ContratoFiscalizacao.Model;

type
  TContratoFiscalizacaoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoFiscalizacaoLista; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ADados: TContratoFiscalizacaoCadastro
    ): Int64; static;

    class procedure AtualizarSituacao(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdFiscalizacao: Int64;
      const ASituacao, AProvidencia: string
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TContratoFiscalizacaoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoFiscalizacaoLista;
var
  Qry: TUniQuery;
  Item: TContratoFiscalizacaoItem;
begin
  Result := TContratoFiscalizacaoLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,data_ocorrencia,tipo,descricao,providencia,situacao,registrado_por,criado_em,atualizado_em ' +
      'FROM contrato_fiscalizacao ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato ' +
      'ORDER BY data_ocorrencia DESC,id DESC';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoFiscalizacaoItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.DataOcorrencia := Qry.FieldByName('data_ocorrencia').AsDateTime;
      Item.Tipo := Qry.FieldByName('tipo').AsString;
      Item.Descricao := Qry.FieldByName('descricao').AsString;
      Item.Providencia := Qry.FieldByName('providencia').AsString;
      Item.Situacao := Qry.FieldByName('situacao').AsString;
      Item.RegistradoPor := Qry.FieldByName('registrado_por').AsLargeInt;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;
      Item.AtualizadoEm := Qry.FieldByName('atualizado_em').AsDateTime;
      Result.Add(Item);
      Qry.Next;
    end;
  except
    Result.Free;
    raise;
  finally
    Qry.Free;
  end;
end;

class function TContratoFiscalizacaoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ADados: TContratoFiscalizacaoCadastro
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_fiscalizacao ' +
      '(id_instituicao,id_contrato,data_ocorrencia,tipo,descricao,providencia,situacao,registrado_por) ' +
      'VALUES(:id_instituicao,:id_contrato,:data_ocorrencia,:tipo,:descricao,:providencia,:situacao,:registrado_por)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('data_ocorrencia').AsDateTime := ADados.DataOcorrencia;
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ADados.Tipo));
    Qry.ParamByName('descricao').AsString := Trim(ADados.Descricao);
    if Trim(ADados.Providencia).IsEmpty then Qry.ParamByName('providencia').Clear else Qry.ParamByName('providencia').AsString := Trim(ADados.Providencia);
    Qry.ParamByName('situacao').AsString := UpperCase(Trim(ADados.Situacao));
    Qry.ParamByName('registrado_por').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoFiscalizacaoDAO.AtualizarSituacao(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdFiscalizacao: Int64;
  const ASituacao, AProvidencia: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE contrato_fiscalizacao SET situacao=:situacao,providencia=:providencia ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato AND id=:id';
    Qry.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    if Trim(AProvidencia).IsEmpty then Qry.ParamByName('providencia').Clear else Qry.ParamByName('providencia').AsString := Trim(AProvidencia);
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('id').AsLargeInt := AIdFiscalizacao;
    Qry.ExecSQL;
    if Qry.RowsAffected = 0 then
      raise Exception.Create('Fiscalização não encontrada para o contrato informado.');
  finally
    Qry.Free;
  end;
end;

end.
