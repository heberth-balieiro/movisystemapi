unit AssinaturaCobranca.DAO;

interface

uses
  Uni,
  AssinaturaCobranca.Model,
  System.Generics.Collections;

type
  TAssinaturaCobrancaDAO = class
  public
    class function Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64 = 0;const APesquisa: string = ''): TObjectList<TAssinaturaCobrancaModel>; static;
    class function BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64): TAssinaturaCobrancaModel; static;
    class function Inserir(const AConn: TUniConnection; const ACobranca: TAssinaturaCobrancaModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection;const ACobranca: TAssinaturaCobrancaModel); static;
    class function Excluir(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64): Boolean; static;
    class procedure AlterarSituacao(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64;const ASituacao: string;const APagoEm: TDateTime = 0); static;

    class function ExisteAbertaPorAssinatura(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64): Boolean; static;
    class function MarcarAbertasComoVencidas(const AConn: TUniConnection;const AIdEmpresa: Int64): Integer; static;
  end;

implementation

uses
  System.SysUtils;

procedure SetDateParam(const Qry: TUniQuery; const AParam: string; const AValue: TDateTime);
begin
  if AValue > 0 then
    Qry.ParamByName(AParam).AsDateTime := AValue
  else
    Qry.ParamByName(AParam).Clear;
end;

procedure PreencherModel(const Qry: TUniQuery; const AModel: TAssinaturaCobrancaModel);
begin
  AModel.IdCobranca := Qry.FieldByName('id_cobranca').AsLargeInt;
  AModel.IdAssinatura := Qry.FieldByName('id_assinatura').AsLargeInt;
  AModel.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;

  if not Qry.FieldByName('vencimento').IsNull then
    AModel.Vencimento := Qry.FieldByName('vencimento').AsDateTime;

  if not Qry.FieldByName('pago_em').IsNull then
    AModel.PagoEm := Qry.FieldByName('pago_em').AsDateTime;

  AModel.Situacao := Qry.FieldByName('situacao').AsString;
  AModel.Valor := Qry.FieldByName('valor').AsCurrency;
  AModel.Descricao := Qry.FieldByName('descricao').AsString;
  AModel.Referencia := Qry.FieldByName('referencia').AsString;
  AModel.FormaPagamento := Qry.FieldByName('forma_pagamento').AsString;
  AModel.IdTransacao := Qry.FieldByName('id_transacao').AsString;
  AModel.LinkPagamento := Qry.FieldByName('link_pagamento').AsString;

  if not Qry.FieldByName('data_criacao').IsNull then
    AModel.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    AModel.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TAssinaturaCobrancaDAO.Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64 = 0;const APesquisa: string = ''): TObjectList<TAssinaturaCobrancaModel>;
var
  Qry: TUniQuery;
  Model: TAssinaturaCobrancaModel;
begin
  Result := TObjectList<TAssinaturaCobrancaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM assinatura_cobranca ' +
      'WHERE id_empresa = :id_empresa ';

    if AIdAssinatura > 0 then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND id_assinatura = :id_assinatura ';

    if not Trim(APesquisa).IsEmpty then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND (situacao LIKE :pesquisa ' +
        'OR descricao LIKE :pesquisa ' +
        'OR referencia LIKE :pesquisa ' +
        'OR forma_pagamento LIKE :pesquisa ' +
        'OR id_transacao LIKE :pesquisa) ';

    Qry.SQL.Text := Qry.SQL.Text +
      'ORDER BY vencimento DESC, id_cobranca DESC';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;

    if AIdAssinatura > 0 then
      Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Model := TAssinaturaCobrancaModel.Create;
      PreencherModel(Qry, Model);
      Result.Add(Model);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaCobrancaDAO.BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64): TAssinaturaCobrancaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM assinatura_cobranca ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cobranca = :id_cobranca';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_cobranca').AsLargeInt := AIdCobranca;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      Result := TAssinaturaCobrancaModel.Create;
      PreencherModel(Qry, Result);
    end;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaCobrancaDAO.Inserir(const AConn: TUniConnection; const ACobranca: TAssinaturaCobrancaModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO assinatura_cobranca ( ' +
      ' id_assinatura, id_empresa, vencimento, pago_em, situacao, valor, ' +
      ' descricao, referencia, forma_pagamento, id_transacao, link_pagamento ' +
      ') VALUES ( ' +
      ' :id_assinatura, :id_empresa, :vencimento, :pago_em, :situacao, :valor, ' +
      ' :descricao, :referencia, :forma_pagamento, :id_transacao, :link_pagamento ' +
      ')';

    Qry.ParamByName('id_assinatura').AsLargeInt := ACobranca.IdAssinatura;
    Qry.ParamByName('id_empresa').AsLargeInt := ACobranca.IdEmpresa;
    Qry.ParamByName('vencimento').AsDateTime := ACobranca.Vencimento;
    SetDateParam(Qry, 'pago_em', ACobranca.PagoEm);
    Qry.ParamByName('situacao').AsString := ACobranca.Situacao;
    Qry.ParamByName('valor').AsCurrency := ACobranca.Valor;
    Qry.ParamByName('descricao').AsString := ACobranca.Descricao;
    Qry.ParamByName('referencia').AsString := ACobranca.Referencia;
    Qry.ParamByName('forma_pagamento').AsString := ACobranca.FormaPagamento;
    Qry.ParamByName('id_transacao').AsString := ACobranca.IdTransacao;
    Qry.ParamByName('link_pagamento').AsString := ACobranca.LinkPagamento;

    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;

    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TAssinaturaCobrancaDAO.Atualizar(const AConn: TUniConnection;const ACobranca: TAssinaturaCobrancaModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura_cobranca SET ' +
      ' id_assinatura = :id_assinatura, ' +
      ' vencimento = :vencimento, ' +
      ' pago_em = :pago_em, ' +
      ' situacao = :situacao, ' +
      ' valor = :valor, ' +
      ' descricao = :descricao, ' +
      ' referencia = :referencia, ' +
      ' forma_pagamento = :forma_pagamento, ' +
      ' id_transacao = :id_transacao, ' +
      ' link_pagamento = :link_pagamento, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cobranca = :id_cobranca';

    Qry.ParamByName('id_empresa').AsLargeInt := ACobranca.IdEmpresa;
    Qry.ParamByName('id_cobranca').AsLargeInt := ACobranca.IdCobranca;
    Qry.ParamByName('id_assinatura').AsLargeInt := ACobranca.IdAssinatura;
    Qry.ParamByName('vencimento').AsDateTime := ACobranca.Vencimento;
    SetDateParam(Qry, 'pago_em', ACobranca.PagoEm);
    Qry.ParamByName('situacao').AsString := ACobranca.Situacao;
    Qry.ParamByName('valor').AsCurrency := ACobranca.Valor;
    Qry.ParamByName('descricao').AsString := ACobranca.Descricao;
    Qry.ParamByName('referencia').AsString := ACobranca.Referencia;
    Qry.ParamByName('forma_pagamento').AsString := ACobranca.FormaPagamento;
    Qry.ParamByName('id_transacao').AsString := ACobranca.IdTransacao;
    Qry.ParamByName('link_pagamento').AsString := ACobranca.LinkPagamento;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaCobrancaDAO.Excluir(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM assinatura_cobranca ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cobranca = :id_cobranca';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_cobranca').AsLargeInt := AIdCobranca;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TAssinaturaCobrancaDAO.AlterarSituacao(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCobranca: Int64;const ASituacao: string;const APagoEm: TDateTime = 0);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura_cobranca SET ' +
      ' situacao = :situacao, ' +
      ' pago_em = :pago_em, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cobranca = :id_cobranca';

    Qry.ParamByName('situacao').AsString := ASituacao;
    SetDateParam(Qry, 'pago_em', APagoEm);
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_cobranca').AsLargeInt := AIdCobranca;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;



class function TAssinaturaCobrancaDAO.ExisteAbertaPorAssinatura(const AConn: TUniConnection; const AIdEmpresa, AIdAssinatura: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM assinatura_cobranca ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_assinatura = :id_assinatura ' +
      'AND situacao = ''ABERTA''';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaCobrancaDAO.MarcarAbertasComoVencidas(const AConn: TUniConnection; const AIdEmpresa: Int64): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura_cobranca SET ' +
      ' situacao = ''VENCIDA'', ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND situacao = ''ABERTA'' ' +
      'AND vencimento < NOW()';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;

    Qry.Execute;

    Result := Qry.RowsAffected;
  finally
    Qry.Free;
  end;
end;

end.
