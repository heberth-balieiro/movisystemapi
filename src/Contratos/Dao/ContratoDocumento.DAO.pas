unit ContratoDocumento.DAO;

interface

uses
  Uni,
  ContratoDocumento.Model;

type
  TContratoDocumentoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoDocumentoLista; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdDocumento: Int64
    ): TContratoDocumentoItem; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ATipo, ANome, AStorageKey, AMimeType, ASha256, AObservacao: string;
      const ATamanhoBytes: Int64
    ): Int64; static;

    class procedure ExcluirLogicamente(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdDocumento, AIdUsuario: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TContratoDocumentoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoDocumentoLista;
var
  Qry: TUniQuery;
  Item: TContratoDocumentoItem;
begin
  Result := TContratoDocumentoLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,tipo,nome,storage_key,mime_type,tamanho_bytes,sha256,observacao,enviado_por,criado_em ' +
      'FROM contrato_documento ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato AND ativo=1 ' +
      'ORDER BY criado_em DESC,id DESC';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoDocumentoItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.Tipo := Qry.FieldByName('tipo').AsString;
      Item.Nome := Qry.FieldByName('nome').AsString;
      Item.StorageKey := Qry.FieldByName('storage_key').AsString;
      Item.MimeType := Qry.FieldByName('mime_type').AsString;
      if not Qry.FieldByName('tamanho_bytes').IsNull then
        Item.TamanhoBytes := Qry.FieldByName('tamanho_bytes').AsLargeInt;
      Item.Sha256 := Qry.FieldByName('sha256').AsString;
      Item.Observacao := Qry.FieldByName('observacao').AsString;
      Item.EnviadoPor := Qry.FieldByName('enviado_por').AsLargeInt;
      Item.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;
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

class function TContratoDocumentoDAO.BuscarPorId(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdDocumento: Int64
): TContratoDocumentoItem;
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,tipo,nome,storage_key,mime_type,tamanho_bytes,sha256,observacao,enviado_por,criado_em ' +
      'FROM contrato_documento ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato AND id=:id AND ativo=1 LIMIT 1';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('id').AsLargeInt := AIdDocumento;
    Qry.Open;
    if Qry.IsEmpty then Exit;

    Result := TContratoDocumentoItem.Create;
    Result.Id := Qry.FieldByName('id').AsLargeInt;
    Result.Tipo := Qry.FieldByName('tipo').AsString;
    Result.Nome := Qry.FieldByName('nome').AsString;
    Result.StorageKey := Qry.FieldByName('storage_key').AsString;
    Result.MimeType := Qry.FieldByName('mime_type').AsString;
    if not Qry.FieldByName('tamanho_bytes').IsNull then Result.TamanhoBytes := Qry.FieldByName('tamanho_bytes').AsLargeInt;
    Result.Sha256 := Qry.FieldByName('sha256').AsString;
    Result.Observacao := Qry.FieldByName('observacao').AsString;
    Result.EnviadoPor := Qry.FieldByName('enviado_por').AsLargeInt;
    Result.CriadoEm := Qry.FieldByName('criado_em').AsDateTime;
  finally
    Qry.Free;
  end;
end;

class function TContratoDocumentoDAO.Inserir(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ATipo, ANome, AStorageKey, AMimeType, ASha256, AObservacao: string;
  const ATamanhoBytes: Int64
): Int64;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_documento ' +
      '(id_instituicao,id_contrato,tipo,nome,arquivo_url,storage_key,mime_type,tamanho_bytes,sha256,observacao,enviado_por,ativo) ' +
      'VALUES(:id_instituicao,:id_contrato,:tipo,:nome,:arquivo_url,:storage_key,:mime_type,:tamanho_bytes,:sha256,:observacao,:enviado_por,1)';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ATipo));
    Qry.ParamByName('nome').AsString := ANome;
    Qry.ParamByName('arquivo_url').AsString := AStorageKey;
    Qry.ParamByName('storage_key').AsString := AStorageKey;
    Qry.ParamByName('mime_type').AsString := AMimeType;
    Qry.ParamByName('tamanho_bytes').AsLargeInt := ATamanhoBytes;
    Qry.ParamByName('sha256').AsString := ASha256;
    if Trim(AObservacao).IsEmpty then Qry.ParamByName('observacao').Clear else Qry.ParamByName('observacao').AsString := Copy(Trim(AObservacao),1,500);
    Qry.ParamByName('enviado_por').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;
    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoDocumentoDAO.ExcluirLogicamente(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdDocumento, AIdUsuario: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE contrato_documento SET ativo=0,excluido_em=CURRENT_TIMESTAMP(3),excluido_por=:usuario ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato AND id=:id AND ativo=1';
    Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('id').AsLargeInt := AIdDocumento;
    Qry.ExecSQL;
    if Qry.RowsAffected=0 then
      raise Exception.Create('Documento não encontrado para o contrato informado.');
  finally
    Qry.Free;
  end;
end;

end.
