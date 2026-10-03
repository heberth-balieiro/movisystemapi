unit ContratoHistorico.DAO;

interface

uses
  Uni,
  ContratoHistorico.Model;

type
  TContratoHistoricoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoHistoricoLista; static;
  end;

implementation

class function TContratoHistoricoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoHistoricoLista;
var
  Qry: TUniQuery;
  Item: TContratoHistoricoItem;
begin
  Result := TContratoHistoricoLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT h.id,h.evento,h.descricao,h.referencia_tipo,h.referencia_id,h.detalhes_json,' +
      'h.usuario,h.criado_em,COALESCE(u.nome,'''') usuario_nome ' +
      'FROM contrato_historico h ' +
      'LEFT JOIN usuario_instituicao ui ON ui.id_instituicao=h.id_instituicao AND ui.id=h.usuario ' +
      'LEFT JOIN usuario u ON u.id=ui.id_usuario ' +
      'WHERE h.id_instituicao=:id_instituicao AND h.id_contrato=:id_contrato ' +
      'ORDER BY h.criado_em DESC,h.id DESC';
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoHistoricoItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.Evento := Qry.FieldByName('evento').AsString;
      Item.Descricao := Qry.FieldByName('descricao').AsString;
      Item.ReferenciaTipo := Qry.FieldByName('referencia_tipo').AsString;
      if not Qry.FieldByName('referencia_id').IsNull then Item.ReferenciaId := Qry.FieldByName('referencia_id').AsLargeInt;
      Item.DetalhesJson := Qry.FieldByName('detalhes_json').AsString;
      if not Qry.FieldByName('usuario').IsNull then Item.Usuario := Qry.FieldByName('usuario').AsLargeInt;
      Item.UsuarioNome := Qry.FieldByName('usuario_nome').AsString;
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

end.
