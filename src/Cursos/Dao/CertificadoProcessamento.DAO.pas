unit CertificadoProcessamento.DAO;

interface

uses
  Uni,
  CertificadoProcessamento.Model;

type
  TCertificadoProcessamentoDAO = class
  public
    class procedure Enfileirar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado,
            ASolicitadoPor: Int64
    ); static;

    class function ReservarProximo(
      const AConn: TUniConnection
    ): TCertificadoProcessamentoItem; static;

    class procedure MarcarConcluido(
      const AConn: TUniConnection;
      const AId: Int64
    ); static;

    class procedure MarcarErro(
      const AConn: TUniConnection;
      const AId: Int64;
      const AErro: string
    ); static;

    class procedure RecuperarTravados(
      const AConn: TUniConnection
    ); static;

    class procedure MarcarCertificadoErro(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils;

class procedure TCertificadoProcessamentoDAO.Enfileirar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado,
        ASolicitadoPor: Int64
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO certificado_processamento ' +
      '(id_instituicao,id_certificado,solicitado_por,situacao) ' +
      'VALUES (:tenant,:certificado,:usuario,''PENDENTE'') ' +
      'ON DUPLICATE KEY UPDATE ' +
      'solicitado_por=VALUES(solicitado_por), ' +
      'situacao=CASE WHEN situacao=''CONCLUIDO'' THEN situacao ELSE ''PENDENTE'' END, ' +
      'proxima_tentativa_em=NULL, ultimo_erro=NULL';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.ParamByName('usuario').AsLargeInt := ASolicitadoPor;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class function TCertificadoProcessamentoDAO.ReservarProximo(
  const AConn: TUniConnection
): TCertificadoProcessamentoItem;
var
  Q: TUniQuery;
begin
  Result := nil;

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT id,id_instituicao,id_certificado,solicitado_por,tentativas ' +
      'FROM certificado_processamento ' +
      'WHERE situacao IN (''PENDENTE'',''ERRO'') ' +
      'AND tentativas < 3 ' +
      'AND (proxima_tentativa_em IS NULL OR proxima_tentativa_em<=CURRENT_TIMESTAMP(3)) ' +
      'ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED';
    Q.Open;

    if Q.IsEmpty then
      Exit;

    Result := TCertificadoProcessamentoItem.Create;
    Result.Id := Q.FieldByName('id').AsLargeInt;
    Result.IdInstituicao := Q.FieldByName('id_instituicao').AsLargeInt;
    Result.IdCertificado := Q.FieldByName('id_certificado').AsLargeInt;
    Result.SolicitadoPor := Q.FieldByName('solicitado_por').AsLargeInt;
    Result.Tentativas := Q.FieldByName('tentativas').AsInteger + 1;

    Q.Close;
    Q.SQL.Text :=
      'UPDATE certificado_processamento SET ' +
      'situacao=''PROCESSANDO'', tentativas=tentativas+1, ' +
      'processando_em=CURRENT_TIMESTAMP(3), ultimo_erro=NULL ' +
      'WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := Result.Id;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoProcessamentoDAO.MarcarConcluido(
  const AConn: TUniConnection;
  const AId: Int64
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado_processamento SET situacao=''CONCLUIDO'', ' +
      'concluido_em=CURRENT_TIMESTAMP(3), proxima_tentativa_em=NULL, ultimo_erro=NULL ' +
      'WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoProcessamentoDAO.MarcarErro(
  const AConn: TUniConnection;
  const AId: Int64;
  const AErro: string
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado_processamento SET situacao=''ERRO'', ' +
      'ultimo_erro=:erro, ' +
      'proxima_tentativa_em=DATE_ADD(CURRENT_TIMESTAMP(3),INTERVAL 5 MINUTE) ' +
      'WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ParamByName('erro').AsString := Copy(Trim(AErro),1,2000);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoProcessamentoDAO.RecuperarTravados(
  const AConn: TUniConnection
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado_processamento SET situacao=''ERRO'', ' +
      'ultimo_erro=''Processamento interrompido; item liberado para nova tentativa.'', ' +
      'proxima_tentativa_em=CURRENT_TIMESTAMP(3) ' +
      'WHERE situacao=''PROCESSANDO'' ' +
      'AND processando_em<DATE_SUB(CURRENT_TIMESTAMP(3),INTERVAL 15 MINUTE)';
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;


class procedure TCertificadoProcessamentoDAO.MarcarCertificadoErro(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado SET situacao=''ERRO'' ' +
      'WHERE id_instituicao=:tenant AND id=:certificado AND situacao=''PENDENTE''';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
