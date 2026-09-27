unit Assinatura.DAO;

interface

uses
  Uni,
  Assinatura.Model,
  System.Generics.Collections;

type
  TAssinaturaDAO = class
  public
    class function Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const APesquisa: string = ''): TObjectList<TAssinaturaModel>; static;
    class function BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64): TAssinaturaModel; static;
    class function BuscarAtualEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TAssinaturaModel; static;
    class function Inserir(const AConn: TUniConnection;const AAssinatura: TAssinaturaModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection;const AAssinatura: TAssinaturaModel); static;
    class function Excluir(const AConn: TUniConnection; const AIdEmpresa: Int64;const AIdAssinatura: Int64): Boolean; static;
    class function PossuiCobranca(const AConn: TUniConnection; const AIdEmpresa: Int64;const AIdAssinatura: Int64): Boolean; static;
    class procedure AlterarSituacao(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIdAssinatura: Int64; const ASituacao: string); static;

    class function MarcarTrialsVencidos(const AConn: TUniConnection;const AIdEmpresa: Int64): Integer; static;
    class function MarcarAssinaturasComCobrancaVencida(const AConn: TUniConnection;const AIdEmpresa: Int64): Integer; static;
    class function MarcarVencidasComoBloqueadas(const AConn: TUniConnection;const AIdEmpresa: Int64;const ADiasAposVencimento: Integer): Integer; static;

    class function ListarEmpresasComAssinatura(const AConn: TUniConnection): TList<Int64>; static;

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

procedure PreencherModel(const Qry: TUniQuery; const AModel: TAssinaturaModel);
begin
  AModel.IdAssinatura := Qry.FieldByName('id_assinatura').AsLargeInt;
  AModel.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
  AModel.IdPlano := Qry.FieldByName('id_plano').AsLargeInt;
  AModel.Recorrencia := Qry.FieldByName('recorrencia').AsString;
  AModel.Situacao := Qry.FieldByName('situacao').AsString;

  if not Qry.FieldByName('iniciado_em').IsNull then
    AModel.IniciadoEm := Qry.FieldByName('iniciado_em').AsDateTime;

  if not Qry.FieldByName('trial_termina_em').IsNull then
    AModel.TrialTerminaEm := Qry.FieldByName('trial_termina_em').AsDateTime;

  if not Qry.FieldByName('proximo_vencimento').IsNull then
    AModel.ProximoVencimento := Qry.FieldByName('proximo_vencimento').AsDateTime;

  if not Qry.FieldByName('cancelado_em').IsNull then
    AModel.CanceladoEm := Qry.FieldByName('cancelado_em').AsDateTime;

  if not Qry.FieldByName('termina_em').IsNull then
    AModel.TerminaEm := Qry.FieldByName('termina_em').AsDateTime;

  AModel.Valor := Qry.FieldByName('valor').AsCurrency;
  AModel.Observacao := Qry.FieldByName('observacao').AsString;

  if not Qry.FieldByName('data_criacao').IsNull then
    AModel.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    AModel.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TAssinaturaDAO.Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const APesquisa: string = ''): TObjectList<TAssinaturaModel>;
var
  Qry: TUniQuery;
  Model: TAssinaturaModel;
begin
  Result := TObjectList<TAssinaturaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM assinatura ' +
      'WHERE id_empresa = :id_empresa ';

    if not Trim(APesquisa).IsEmpty then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND (recorrencia LIKE :pesquisa ' +
        'OR situacao LIKE :pesquisa ' +
        'OR observacao LIKE :pesquisa) ';

    Qry.SQL.Text := Qry.SQL.Text +
      'ORDER BY id_assinatura DESC';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Model := TAssinaturaModel.Create;
      PreencherModel(Qry, Model);
      Result.Add(Model);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdAssinatura: Int64): TAssinaturaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM assinatura ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_assinatura = :id_assinatura';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      Result := TAssinaturaModel.Create;
      PreencherModel(Qry, Result);
    end;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.BuscarAtualEmpresa(const AConn: TUniConnection;const AIdEmpresa: Int64): TAssinaturaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM assinatura ' +
      'WHERE id_empresa = :id_empresa ' +
      'ORDER BY id_assinatura DESC ' +
      'LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      Result := TAssinaturaModel.Create;
      PreencherModel(Qry, Result);
    end;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.Inserir(const AConn: TUniConnection;const AAssinatura: TAssinaturaModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO assinatura ( ' +
      ' id_empresa, id_plano, recorrencia, situacao, iniciado_em, ' +
      ' trial_termina_em, proximo_vencimento, cancelado_em, termina_em, ' +
      ' valor, observacao ' +
      ') VALUES ( ' +
      ' :id_empresa, :id_plano, :recorrencia, :situacao, :iniciado_em, ' +
      ' :trial_termina_em, :proximo_vencimento, :cancelado_em, :termina_em, ' +
      ' :valor, :observacao ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := AAssinatura.IdEmpresa;
    Qry.ParamByName('id_plano').AsLargeInt := AAssinatura.IdPlano;
    Qry.ParamByName('recorrencia').AsString := AAssinatura.Recorrencia;
    Qry.ParamByName('situacao').AsString := AAssinatura.Situacao;

    if AAssinatura.IniciadoEm > 0 then
      Qry.ParamByName('iniciado_em').AsDateTime := AAssinatura.IniciadoEm
    else
      Qry.ParamByName('iniciado_em').AsDateTime := Now;

    SetDateParam(Qry, 'trial_termina_em', AAssinatura.TrialTerminaEm);
    SetDateParam(Qry, 'proximo_vencimento', AAssinatura.ProximoVencimento);
    SetDateParam(Qry, 'cancelado_em', AAssinatura.CanceladoEm);
    SetDateParam(Qry, 'termina_em', AAssinatura.TerminaEm);

    Qry.ParamByName('valor').AsCurrency := AAssinatura.Valor;
    Qry.ParamByName('observacao').AsString := AAssinatura.Observacao;

    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;

    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TAssinaturaDAO.Atualizar(const AConn: TUniConnection;const AAssinatura: TAssinaturaModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura SET ' +
      ' id_plano = :id_plano, ' +
      ' recorrencia = :recorrencia, ' +
      ' situacao = :situacao, ' +
      ' iniciado_em = :iniciado_em, ' +
      ' trial_termina_em = :trial_termina_em, ' +
      ' proximo_vencimento = :proximo_vencimento, ' +
      ' cancelado_em = :cancelado_em, ' +
      ' termina_em = :termina_em, ' +
      ' valor = :valor, ' +
      ' observacao = :observacao, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_assinatura = :id_assinatura';

    Qry.ParamByName('id_empresa').AsLargeInt := AAssinatura.IdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AAssinatura.IdAssinatura;
    Qry.ParamByName('id_plano').AsLargeInt := AAssinatura.IdPlano;
    Qry.ParamByName('recorrencia').AsString := AAssinatura.Recorrencia;
    Qry.ParamByName('situacao').AsString := AAssinatura.Situacao;

    if AAssinatura.IniciadoEm > 0 then
      Qry.ParamByName('iniciado_em').AsDateTime := AAssinatura.IniciadoEm
    else
      Qry.ParamByName('iniciado_em').AsDateTime := Now;

    SetDateParam(Qry, 'trial_termina_em', AAssinatura.TrialTerminaEm);
    SetDateParam(Qry, 'proximo_vencimento', AAssinatura.ProximoVencimento);
    SetDateParam(Qry, 'cancelado_em', AAssinatura.CanceladoEm);
    SetDateParam(Qry, 'termina_em', AAssinatura.TerminaEm);

    Qry.ParamByName('valor').AsCurrency := AAssinatura.Valor;
    Qry.ParamByName('observacao').AsString := AAssinatura.Observacao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.Excluir(const AConn: TUniConnection; const AIdEmpresa: Int64;const AIdAssinatura: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM assinatura ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_assinatura = :id_assinatura';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.PossuiCobranca(const AConn: TUniConnection; const AIdEmpresa: Int64;const AIdAssinatura: Int64): Boolean;
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
      'AND id_assinatura = :id_assinatura';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TAssinaturaDAO.AlterarSituacao(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIdAssinatura: Int64; const ASituacao: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura SET ' +
      ' situacao = :situacao, ' +
      ' cancelado_em = CASE WHEN :cancelada = ''S'' THEN NOW() ELSE cancelado_em END, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_assinatura = :id_assinatura';

    Qry.ParamByName('situacao').AsString := ASituacao;

    if SameText(ASituacao, 'CANCELADA') then
      Qry.ParamByName('cancelada').AsString := 'S'
    else
      Qry.ParamByName('cancelada').AsString := 'N';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_assinatura').AsLargeInt := AIdAssinatura;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;




class function TAssinaturaDAO.MarcarAssinaturasComCobrancaVencida(const AConn: TUniConnection; const AIdEmpresa: Int64): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura a SET ' +
      ' a.situacao = ''VENCIDA'', ' +
      ' a.data_alteracao = NOW() ' +
      'WHERE a.id_empresa = :id_empresa ' +
      'AND a.situacao IN (''TRIAL'', ''ATIVA'') ' +
      'AND EXISTS ( ' +
      ' SELECT 1 ' +
      ' FROM assinatura_cobranca c ' +
      ' WHERE c.id_empresa = a.id_empresa ' +
      ' AND c.id_assinatura = a.id_assinatura ' +
      ' AND c.situacao = ''VENCIDA'' ' +
      ')';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Execute;
    Result := Qry.RowsAffected;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.MarcarTrialsVencidos(const AConn: TUniConnection;const AIdEmpresa: Int64): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura SET ' +
      ' situacao = ''VENCIDA'', ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND situacao = ''TRIAL'' ' +
      'AND trial_termina_em IS NOT NULL ' +
      'AND trial_termina_em < NOW()';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Execute;
    Result := Qry.RowsAffected;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.MarcarVencidasComoBloqueadas(const AConn: TUniConnection; const AIdEmpresa: Int64;
  const ADiasAposVencimento: Integer): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE assinatura SET ' +
      ' situacao = ''BLOQUEADA'', ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND situacao = ''VENCIDA'' ' +
      'AND proximo_vencimento IS NOT NULL ' +
      'AND proximo_vencimento < DATE_SUB(NOW(), INTERVAL :dias DAY)';
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('dias').AsInteger := ADiasAposVencimento;
    Qry.Execute;
    Result := Qry.RowsAffected;
  finally
    Qry.Free;
  end;
end;

class function TAssinaturaDAO.ListarEmpresasComAssinatura(const AConn: TUniConnection): TList<Int64>;
var
  Qry: TUniQuery;
begin
  Result := TList<Int64>.Create;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT DISTINCT id_empresa ' +
      'FROM assinatura ' +
      'ORDER BY id_empresa';
    Qry.Open;
    while not Qry.Eof do
    begin
      Result.Add(Qry.FieldByName('id_empresa').AsLargeInt);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;


end.
