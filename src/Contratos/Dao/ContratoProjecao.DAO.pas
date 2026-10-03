unit ContratoProjecao.DAO;

interface

uses
  Uni,
  ContratoProjecao.Model;

type
  TContratoProjecaoDAO = class
  public
    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato: Int64
    ): TContratoProjecaoLista; static;

    class procedure GerarAutomaticas(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ADataInicio, ADataFim: TDateTime;
      const AValorTotal: Double;
      const APreservarManuais: Boolean;
      const AOrigem: string = 'AUTOMATICA'
    ); static;

    class procedure AtualizarManual(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const ACompetencia: TDateTime;
      const AValorPrevisto, AValorRealizado: Double;
      const AObservacao: string
    ); static;

    class procedure RegistrarHistoricoAtual(
      const AConn: TUniConnection;
      const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
      const AEvento: string
    ); static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Math;

class function TContratoProjecaoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato: Int64
): TContratoProjecaoLista;
var
  Qry: TUniQuery;
  Item: TContratoProjecaoItem;
begin
  Result := TContratoProjecaoLista.Create(True);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,competencia,valor_previsto,valor_realizado,origem,observacao ' +
      'FROM contrato_projecao ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato ' +
      'ORDER BY competencia';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TContratoProjecaoItem.Create;
      Item.Id := Qry.FieldByName('id').AsLargeInt;
      Item.Competencia := Qry.FieldByName('competencia').AsDateTime;
      Item.ValorPrevisto := Qry.FieldByName('valor_previsto').AsFloat;
      Item.ValorRealizado := Qry.FieldByName('valor_realizado').AsFloat;
      Item.Origem := Qry.FieldByName('origem').AsString;
      Item.Observacao := Qry.FieldByName('observacao').AsString;
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

class procedure TContratoProjecaoDAO.RegistrarHistoricoAtual(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const AEvento: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_projecao_historico ' +
      '(id_instituicao,id_contrato,id_projecao,competencia,valor_previsto,valor_realizado,evento,usuario) ' +
      'SELECT id_instituicao,id_contrato,id,competencia,valor_previsto,valor_realizado,:evento,:usuario ' +
      'FROM contrato_projecao ' +
      'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato';

    Qry.ParamByName('evento').AsString := Copy(UpperCase(Trim(AEvento)), 1, 30);
    Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoProjecaoDAO.GerarAutomaticas(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ADataInicio, ADataFim: TDateTime;
  const AValorTotal: Double;
  const APreservarManuais: Boolean;
  const AOrigem: string
);
var
  Qry: TUniQuery;
  Inicio, Fim, Competencia: TDateTime;
  AnoInicio, MesInicio, DiaTmp: Word;
  AnoFim, MesFim: Word;
  Meses, I: Integer;
  ValorMes, ValorAcumulado, ValorAtual: Double;
begin
  DecodeDate(ADataInicio, AnoInicio, MesInicio, DiaTmp);
  DecodeDate(ADataFim, AnoFim, MesFim, DiaTmp);

  Inicio := EncodeDate(AnoInicio, MesInicio, 1);
  Fim := EncodeDate(AnoFim, MesFim, 1);
  Meses := ((AnoFim - AnoInicio) * 12) + (MesFim - MesInicio) + 1;

  if Meses <= 0 then
    Exit;

  RegistrarHistoricoAtual(
    AConn,
    AIdInstituicao,
    AIdContrato,
    AIdUsuario,
    'RECALCULO'
  );

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    if APreservarManuais then
      Qry.SQL.Text :=
        'DELETE FROM contrato_projecao ' +
        'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato ' +
        'AND origem<>''MANUAL'''
    else
      Qry.SQL.Text :=
        'DELETE FROM contrato_projecao ' +
        'WHERE id_instituicao=:id_instituicao AND id_contrato=:id_contrato';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ExecSQL;

    ValorMes := RoundTo(AValorTotal / Meses, -2);
    ValorAcumulado := 0;

    for I := 0 to Meses - 1 do
    begin
      Competencia := IncMonth(Inicio, I);

      if I = Meses - 1 then
        ValorAtual := AValorTotal - ValorAcumulado
      else
        ValorAtual := ValorMes;

      Qry.SQL.Text :=
        'INSERT INTO contrato_projecao ' +
        '(id_instituicao,id_contrato,competencia,valor_previsto,valor_realizado,origem,atualizado_por) ' +
        'VALUES(:id_instituicao,:id_contrato,:competencia,:valor_previsto,0,:origem,:usuario) ' +
        'ON DUPLICATE KEY UPDATE ' +
        'valor_previsto=IF(origem=''MANUAL'',valor_previsto,VALUES(valor_previsto)),' +
        'origem=IF(origem=''MANUAL'',origem,VALUES(origem)),' +
        'atualizado_por=:usuario';

      Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
      Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
      Qry.ParamByName('competencia').AsDateTime := Competencia;
      Qry.ParamByName('valor_previsto').AsFloat := ValorAtual;
      Qry.ParamByName('origem').AsString := UpperCase(Trim(AOrigem));
      Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
      Qry.ExecSQL;

      ValorAcumulado := ValorAcumulado + ValorAtual;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TContratoProjecaoDAO.AtualizarManual(
  const AConn: TUniConnection;
  const AIdInstituicao, AIdContrato, AIdUsuario: Int64;
  const ACompetencia: TDateTime;
  const AValorPrevisto, AValorRealizado: Double;
  const AObservacao: string
);
var
  Qry: TUniQuery;
  Ano, Mes, Dia: Word;
  Competencia: TDateTime;
begin
  DecodeDate(ACompetencia, Ano, Mes, Dia);
  Competencia := EncodeDate(Ano, Mes, 1);

  RegistrarHistoricoAtual(
    AConn,
    AIdInstituicao,
    AIdContrato,
    AIdUsuario,
    'AJUSTE_MANUAL'
  );

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO contrato_projecao ' +
      '(id_instituicao,id_contrato,competencia,valor_previsto,valor_realizado,origem,observacao,atualizado_por) ' +
      'VALUES(:id_instituicao,:id_contrato,:competencia,:valor_previsto,:valor_realizado,''MANUAL'',:observacao,:usuario) ' +
      'ON DUPLICATE KEY UPDATE ' +
      'valor_previsto=VALUES(valor_previsto),' +
      'valor_realizado=VALUES(valor_realizado),' +
      'origem=''MANUAL'',' +
      'observacao=VALUES(observacao),' +
      'atualizado_por=:usuario';

    Qry.ParamByName('id_instituicao').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id_contrato').AsLargeInt := AIdContrato;
    Qry.ParamByName('competencia').AsDateTime := Competencia;
    Qry.ParamByName('valor_previsto').AsFloat := AValorPrevisto;
    Qry.ParamByName('valor_realizado').AsFloat := AValorRealizado;
    if Trim(AObservacao).IsEmpty then
      Qry.ParamByName('observacao').Clear
    else
      Qry.ParamByName('observacao').AsString := Copy(Trim(AObservacao), 1, 500);
    Qry.ParamByName('usuario').AsLargeInt := AIdUsuario;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
