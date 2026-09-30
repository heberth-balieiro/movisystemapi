unit CertificadoNotificacao.DAO;

interface

uses
  Uni,
  CertificadoNotificacao.Model;

type
  TCertificadoNotificacaoDAO = class
  public
    class function BuscarContexto(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoNotificacaoContexto; static;

    class procedure Enfileirar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64;
      const ACanal,
            ADestinatario: string
    ); static;

    class function ReservarProximo(
      const AConn: TUniConnection
    ): TCertificadoNotificacaoItem; static;

    class procedure MarcarEnviado(
      const AConn: TUniConnection;
      const AId: Int64
    ); static;

    class procedure MarcarErro(
      const AConn: TUniConnection;
      const AId: Int64;
      const AErro: string
    ); static;

    class procedure MarcarIgnorado(
      const AConn: TUniConnection;
      const AId: Int64;
      const AMotivo: string
    ); static;

    class procedure RecuperarTravados(
      const AConn: TUniConnection
    ); static;
  end;

implementation

uses
  System.SysUtils;

class function TCertificadoNotificacaoDAO.BuscarContexto(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoNotificacaoContexto;
var
  Q: TUniQuery;
begin
  Result := nil;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT c.id_instituicao,c.id,c.numero_publico,c.participante_nome,c.curso_nome,c.instituicao_nome,' +
      'p.email,p.telefone,i.slug ' +
      'FROM certificado c ' +
      'JOIN participante p ON p.id_instituicao=c.id_instituicao AND p.id=c.id_participante ' +
      'JOIN instituicao i ON i.id=c.id_instituicao ' +
      'WHERE c.id_instituicao=:tenant AND c.id=:certificado AND c.situacao=''VALIDO'' LIMIT 1';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.Open;

    if Q.IsEmpty then Exit;

    Result := TCertificadoNotificacaoContexto.Create;
    Result.IdInstituicao := Q.FieldByName('id_instituicao').AsLargeInt;
    Result.IdCertificado := Q.FieldByName('id').AsLargeInt;
    Result.NumeroPublico := Q.FieldByName('numero_publico').AsString;
    Result.ParticipanteNome := Q.FieldByName('participante_nome').AsString;
    Result.ParticipanteEmail := Q.FieldByName('email').AsString;
    Result.ParticipanteTelefone := Q.FieldByName('telefone').AsString;
    Result.CursoNome := Q.FieldByName('curso_nome').AsString;
    Result.InstituicaoNome := Q.FieldByName('instituicao_nome').AsString;
    Result.InstituicaoSlug := Q.FieldByName('slug').AsString;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoNotificacaoDAO.Enfileirar(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64;
  const ACanal,
        ADestinatario: string
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'INSERT INTO certificado_notificacao ' +
      '(id_instituicao,id_certificado,canal,destinatario,situacao) ' +
      'VALUES (:tenant,:certificado,:canal,:destinatario,''PENDENTE'') ' +
      'ON DUPLICATE KEY UPDATE destinatario=VALUES(destinatario)';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.ParamByName('canal').AsString := UpperCase(Trim(ACanal));
    Q.ParamByName('destinatario').AsString := Trim(ADestinatario);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class function TCertificadoNotificacaoDAO.ReservarProximo(
  const AConn: TUniConnection
): TCertificadoNotificacaoItem;
var
  Q: TUniQuery;
begin
  Result := nil;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT id,id_instituicao,id_certificado,canal,destinatario,tentativas ' +
      'FROM certificado_notificacao ' +
      'WHERE situacao IN (''PENDENTE'',''ERRO'') AND tentativas<3 ' +
      'AND (proxima_tentativa_em IS NULL OR proxima_tentativa_em<=CURRENT_TIMESTAMP(3)) ' +
      'ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED';
    Q.Open;
    if Q.IsEmpty then Exit;

    Result := TCertificadoNotificacaoItem.Create;
    Result.Id := Q.FieldByName('id').AsLargeInt;
    Result.IdInstituicao := Q.FieldByName('id_instituicao').AsLargeInt;
    Result.IdCertificado := Q.FieldByName('id_certificado').AsLargeInt;
    Result.Canal := Q.FieldByName('canal').AsString;
    Result.Destinatario := Q.FieldByName('destinatario').AsString;
    Result.Tentativas := Q.FieldByName('tentativas').AsInteger + 1;

    Q.Close;
    Q.SQL.Text :=
      'UPDATE certificado_notificacao SET situacao=''PROCESSANDO'',tentativas=tentativas+1,' +
      'processando_em=CURRENT_TIMESTAMP(3),ultimo_erro=NULL WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := Result.Id;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoNotificacaoDAO.MarcarEnviado(
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
      'UPDATE certificado_notificacao SET situacao=''ENVIADO'',enviado_em=CURRENT_TIMESTAMP(3),' +
      'proxima_tentativa_em=NULL,ultimo_erro=NULL WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoNotificacaoDAO.MarcarErro(
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
      'UPDATE certificado_notificacao SET situacao=''ERRO'',ultimo_erro=:erro,' +
      'proxima_tentativa_em=DATE_ADD(CURRENT_TIMESTAMP(3),INTERVAL 5 MINUTE) WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ParamByName('erro').AsString := Copy(Trim(AErro),1,2000);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;


class procedure TCertificadoNotificacaoDAO.MarcarIgnorado(
  const AConn: TUniConnection;
  const AId: Int64;
  const AMotivo: string
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado_notificacao SET situacao=''IGNORADO'',ultimo_erro=:motivo,' +
      'proxima_tentativa_em=NULL WHERE id=:id';
    Q.ParamByName('id').AsLargeInt := AId;
    Q.ParamByName('motivo').AsString := Copy(Trim(AMotivo),1,2000);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoNotificacaoDAO.RecuperarTravados(
  const AConn: TUniConnection
);
var
  Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'UPDATE certificado_notificacao SET situacao=''ERRO'',' +
      'ultimo_erro=''Processamento interrompido; item liberado para nova tentativa.'',' +
      'proxima_tentativa_em=CURRENT_TIMESTAMP(3) ' +
      'WHERE situacao=''PROCESSANDO'' AND processando_em<DATE_SUB(CURRENT_TIMESTAMP(3),INTERVAL 15 MINUTE)';
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
