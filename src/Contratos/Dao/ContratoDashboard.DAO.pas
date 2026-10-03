unit ContratoDashboard.DAO;

interface

uses
  Uni;

type
  TContratoDashboardDados = record
    Vigentes: Integer;
    AVencer30Dias: Integer;
    Vencidos: Integer;
    FiscalizacoesPendentes: Integer;
    ValorContratado: Double;
    ValorRealizado: Double;
    SaldoProjetado: Double;
  end;

  TContratoDashboardDAO = class
  public
    class function Buscar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64
    ): TContratoDashboardDados; static;
  end;

implementation

class function TContratoDashboardDAO.Buscar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64
): TContratoDashboardDados;
var
  Qry: TUniQuery;
begin
  Result := Default(TContratoDashboardDados);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      '(SELECT COUNT(*) FROM contrato c WHERE c.id_instituicao=:id1 AND c.situacao=''ATIVO'' AND c.data_fim>=CURRENT_DATE) vigentes,' +
      '(SELECT COUNT(*) FROM contrato c WHERE c.id_instituicao=:id2 AND c.situacao=''ATIVO'' AND c.data_fim BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE,INTERVAL 30 DAY)) a_vencer_30_dias,' +
      '(SELECT COUNT(*) FROM contrato c WHERE c.id_instituicao=:id3 AND c.situacao=''ATIVO'' AND c.data_fim<CURRENT_DATE) vencidos,' +
      '(SELECT COUNT(*) FROM contrato_fiscalizacao f WHERE f.id_instituicao=:id4 AND f.situacao IN(''ABERTA'',''EM_TRATAMENTO'')) fiscalizacoes_pendentes,' +
      '(SELECT COALESCE(SUM(c.valor_atual),0) FROM contrato c WHERE c.id_instituicao=:id5 AND c.situacao<>''CANCELADO'') valor_contratado,' +
      '(SELECT COALESCE(SUM(p.valor_realizado),0) FROM contrato_projecao p WHERE p.id_instituicao=:id6) valor_realizado,' +
      '(SELECT COALESCE(SUM(p.valor_previsto-p.valor_realizado),0) FROM contrato_projecao p WHERE p.id_instituicao=:id7) saldo_projetado';

    Qry.ParamByName('id1').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id2').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id3').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id4').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id5').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id6').AsLargeInt := AIdInstituicao;
    Qry.ParamByName('id7').AsLargeInt := AIdInstituicao;
    Qry.Open;

    Result.Vigentes := Qry.FieldByName('vigentes').AsInteger;
    Result.AVencer30Dias := Qry.FieldByName('a_vencer_30_dias').AsInteger;
    Result.Vencidos := Qry.FieldByName('vencidos').AsInteger;
    Result.FiscalizacoesPendentes := Qry.FieldByName('fiscalizacoes_pendentes').AsInteger;
    Result.ValorContratado := Qry.FieldByName('valor_contratado').AsFloat;
    Result.ValorRealizado := Qry.FieldByName('valor_realizado').AsFloat;
    Result.SaldoProjetado := Qry.FieldByName('saldo_projetado').AsFloat;
  finally
    Qry.Free;
  end;
end;

end.
