unit EleicaoRateLimitAPI.Dao;

interface

uses
  System.SysUtils,
  Uni;

type
  TEleicaoRateLimitDados = record
    Id: Int64;
    Tentativas: Integer;
    JanelaInicio: TDateTime;
    BloqueadoAte: TDateTime;
    DataHoraAtual: TDateTime;
    TemBloqueadoAte: Boolean;
  end;

  TEleicaoRateLimitAPIDao = class
  public
    class function Buscar(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer;
      const ATipo, AChave: string; out ADados: TEleicaoRateLimitDados): Boolean; static;

    class procedure Criar(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer;
      const ATipo, AChave: string); static;

    class procedure Reiniciar(const AConn: TUniConnection; const AId: Int64); static;

    class procedure IncrementarTentativa(const AConn: TUniConnection; const AId: Int64); static;

    class procedure Bloquear(const AConn: TUniConnection; const AId: Int64;
      const AMinutos: Integer); static;

    class procedure Excluir(const AConn: TUniConnection; const AIdEmpresa, AIdEleicao: Integer;
      const ATipo, AChave: string); static;
  end;

implementation

{ TEleicaoRateLimitAPIDao }

class function TEleicaoRateLimitAPIDao.Buscar(const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string;
  out ADados: TEleicaoRateLimitDados): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  ADados := Default(TEleicaoRateLimitDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id, tentativas, janela_inicio, bloqueado_ate, NOW() AS data_hora_atual ' +
      'FROM eleicao_rate_limit ' +
      'WHERE empresa_id = :idempresa ' +
      'AND eleicao_id = :ideleicao ' +
      'AND tipo = :tipo ' +
      'AND chave = :chave ' +
      'LIMIT 1 ' +
      'FOR UPDATE';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ATipo));
    Qry.ParamByName('chave').AsString := Trim(AChave);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    ADados.Id := Qry.FieldByName('id').AsLargeInt;
    ADados.Tentativas := Qry.FieldByName('tentativas').AsInteger;
    ADados.JanelaInicio := Qry.FieldByName('janela_inicio').AsDateTime;
    ADados.DataHoraAtual := Qry.FieldByName('data_hora_atual').AsDateTime;
    ADados.TemBloqueadoAte := not Qry.FieldByName('bloqueado_ate').IsNull;

    if ADados.TemBloqueadoAte then
      ADados.BloqueadoAte := Qry.FieldByName('bloqueado_ate').AsDateTime;

    Result := True;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIDao.Criar(const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_rate_limit ' +
      '(empresa_id, eleicao_id, tipo, chave, tentativas, janela_inicio, bloqueado_ate) ' +
      'VALUES ' +
      '(:idempresa, :ideleicao, :tipo, :chave, 1, NOW(), NULL)';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ATipo));
    Qry.ParamByName('chave').AsString := Trim(AChave);

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIDao.Reiniciar(const AConn: TUniConnection;
  const AId: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE eleicao_rate_limit SET ' +
      'tentativas = 1, ' +
      'janela_inicio = NOW(), ' +
      'bloqueado_ate = NULL ' +
      'WHERE id = :id';

    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIDao.IncrementarTentativa(const AConn: TUniConnection; const AId: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE eleicao_rate_limit SET ' +
      'tentativas = tentativas + 1 ' +
      'WHERE id = :id';

    Qry.ParamByName('id').AsLargeInt := AId;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIDao.Bloquear(const AConn: TUniConnection;
  const AId: Int64; const AMinutos: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE eleicao_rate_limit SET ' +
      'bloqueado_ate = DATE_ADD(NOW(), INTERVAL :minutos MINUTE) ' +
      'WHERE id = :id';

    Qry.ParamByName('minutos').AsInteger := AMinutos;
    Qry.ParamByName('id').AsLargeInt := AId;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRateLimitAPIDao.Excluir(const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer; const ATipo, AChave: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM eleicao_rate_limit ' +
      'WHERE empresa_id = :idempresa ' +
      'AND eleicao_id = :ideleicao ' +
      'AND tipo = :tipo ' +
      'AND chave = :chave';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('tipo').AsString := UpperCase(Trim(ATipo));
    Qry.ParamByName('chave').AsString := Trim(AChave);

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
