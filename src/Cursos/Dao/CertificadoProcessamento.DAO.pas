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

    class function Listar(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TCertificadoProcessamentoLista; static;

    class function BuscarPorCertificado(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado: Int64
    ): TCertificadoProcessamentoItem; static;

    class procedure Reprocessar(
      const AConn: TUniConnection;
      const AIdInstituicao,
            AIdCertificado,
            ASolicitadoPor: Int64
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
      'tentativas=CASE WHEN situacao=''CONCLUIDO'' THEN tentativas ELSE 0 END, ' +
      'proxima_tentativa_em=NULL, processando_em=NULL, ultimo_erro=NULL';
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


class function TCertificadoProcessamentoDAO.Listar(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TCertificadoProcessamentoLista;
var
  Q: TUniQuery;
  Item: TCertificadoProcessamentoItem;
  WhereSql: string;
  Offset: Integer;
begin
  Result := TCertificadoProcessamentoLista.Create;
  Result.Pagina := APagina;
  Result.PorPagina := APorPagina;
  Offset := (APagina - 1) * APorPagina;

  WhereSql := ' WHERE cp.id_instituicao=:tenant ';

  if not Trim(ABusca).IsEmpty then
    WhereSql := WhereSql +
      ' AND (c.numero_publico LIKE :busca OR c.participante_nome LIKE :busca OR c.curso_nome LIKE :busca) ';

  if not Trim(ASituacao).IsEmpty then
    WhereSql := WhereSql + ' AND cp.situacao=:situacao ';

  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;

    Q.SQL.Text :=
      'SELECT COUNT(*) AS total FROM certificado_processamento cp ' +
      'JOIN certificado c ON c.id=cp.id_certificado AND c.id_instituicao=cp.id_instituicao ' +
      WhereSql;
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    if not Trim(ABusca).IsEmpty then
      Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ASituacao).IsEmpty then
      Q.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    Q.Open;
    Result.Total := Q.FieldByName('total').AsInteger;

    Q.Close;
    Q.SQL.Text :=
      'SELECT cp.id,cp.id_instituicao,cp.id_certificado,cp.solicitado_por,cp.situacao,' +
      'cp.tentativas,cp.proxima_tentativa_em,cp.processando_em,cp.concluido_em,' +
      'cp.ultimo_erro,cp.criado_em,cp.atualizado_em,' +
      'c.numero_publico,c.participante_nome,c.curso_nome,c.situacao AS certificado_situacao ' +
      'FROM certificado_processamento cp ' +
      'JOIN certificado c ON c.id=cp.id_certificado AND c.id_instituicao=cp.id_instituicao ' +
      WhereSql +
      'ORDER BY cp.criado_em DESC,cp.id DESC LIMIT :limite OFFSET :offset';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    if not Trim(ABusca).IsEmpty then
      Q.ParamByName('busca').AsString := '%' + Trim(ABusca) + '%';
    if not Trim(ASituacao).IsEmpty then
      Q.ParamByName('situacao').AsString := UpperCase(Trim(ASituacao));
    Q.ParamByName('limite').AsInteger := APorPagina;
    Q.ParamByName('offset').AsInteger := Offset;
    Q.Open;

    while not Q.Eof do
    begin
      Item := TCertificadoProcessamentoItem.Create;
      Item.Id := Q.FieldByName('id').AsLargeInt;
      Item.IdInstituicao := Q.FieldByName('id_instituicao').AsLargeInt;
      Item.IdCertificado := Q.FieldByName('id_certificado').AsLargeInt;
      Item.SolicitadoPor := Q.FieldByName('solicitado_por').AsLargeInt;
      Item.Situacao := Q.FieldByName('situacao').AsString;
      Item.Tentativas := Q.FieldByName('tentativas').AsInteger;
      Item.UltimoErro := Q.FieldByName('ultimo_erro').AsString;
      Item.NumeroPublico := Q.FieldByName('numero_publico').AsString;
      Item.ParticipanteNome := Q.FieldByName('participante_nome').AsString;
      Item.CursoNome := Q.FieldByName('curso_nome').AsString;
      Item.CertificadoSituacao := Q.FieldByName('certificado_situacao').AsString;
      Item.CriadoEm := Q.FieldByName('criado_em').AsDateTime;
      Item.AtualizadoEm := Q.FieldByName('atualizado_em').AsDateTime;
      Item.TemProximaTentativaEm := not Q.FieldByName('proxima_tentativa_em').IsNull;
      if Item.TemProximaTentativaEm then Item.ProximaTentativaEm := Q.FieldByName('proxima_tentativa_em').AsDateTime;
      Item.TemProcessandoEm := not Q.FieldByName('processando_em').IsNull;
      if Item.TemProcessandoEm then Item.ProcessandoEm := Q.FieldByName('processando_em').AsDateTime;
      Item.TemConcluidoEm := not Q.FieldByName('concluido_em').IsNull;
      if Item.TemConcluidoEm then Item.ConcluidoEm := Q.FieldByName('concluido_em').AsDateTime;
      Result.Itens.Add(Item);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

class function TCertificadoProcessamentoDAO.BuscarPorCertificado(
  const AConn: TUniConnection;
  const AIdInstituicao,
        AIdCertificado: Int64
): TCertificadoProcessamentoItem;
var
  Q: TUniQuery;
begin
  Result := nil;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := AConn;
    Q.SQL.Text :=
      'SELECT cp.id,cp.id_instituicao,cp.id_certificado,cp.solicitado_por,cp.situacao,' +
      'cp.tentativas,cp.proxima_tentativa_em,cp.processando_em,cp.concluido_em,' +
      'cp.ultimo_erro,cp.criado_em,cp.atualizado_em,' +
      'c.numero_publico,c.participante_nome,c.curso_nome,c.situacao AS certificado_situacao ' +
      'FROM certificado_processamento cp ' +
      'JOIN certificado c ON c.id=cp.id_certificado AND c.id_instituicao=cp.id_instituicao ' +
      'WHERE cp.id_instituicao=:tenant AND cp.id_certificado=:certificado LIMIT 1';
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.Open;
    if Q.IsEmpty then Exit;

    Result := TCertificadoProcessamentoItem.Create;
    Result.Id := Q.FieldByName('id').AsLargeInt;
    Result.IdInstituicao := Q.FieldByName('id_instituicao').AsLargeInt;
    Result.IdCertificado := Q.FieldByName('id_certificado').AsLargeInt;
    Result.SolicitadoPor := Q.FieldByName('solicitado_por').AsLargeInt;
    Result.Situacao := Q.FieldByName('situacao').AsString;
    Result.Tentativas := Q.FieldByName('tentativas').AsInteger;
    Result.UltimoErro := Q.FieldByName('ultimo_erro').AsString;
    Result.NumeroPublico := Q.FieldByName('numero_publico').AsString;
    Result.ParticipanteNome := Q.FieldByName('participante_nome').AsString;
    Result.CursoNome := Q.FieldByName('curso_nome').AsString;
    Result.CertificadoSituacao := Q.FieldByName('certificado_situacao').AsString;
    Result.CriadoEm := Q.FieldByName('criado_em').AsDateTime;
    Result.AtualizadoEm := Q.FieldByName('atualizado_em').AsDateTime;
    Result.TemProximaTentativaEm := not Q.FieldByName('proxima_tentativa_em').IsNull;
    if Result.TemProximaTentativaEm then Result.ProximaTentativaEm := Q.FieldByName('proxima_tentativa_em').AsDateTime;
    Result.TemProcessandoEm := not Q.FieldByName('processando_em').IsNull;
    if Result.TemProcessandoEm then Result.ProcessandoEm := Q.FieldByName('processando_em').AsDateTime;
    Result.TemConcluidoEm := not Q.FieldByName('concluido_em').IsNull;
    if Result.TemConcluidoEm then Result.ConcluidoEm := Q.FieldByName('concluido_em').AsDateTime;
  finally
    Q.Free;
  end;
end;

class procedure TCertificadoProcessamentoDAO.Reprocessar(
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
      'UPDATE certificado_processamento cp ' +
      'JOIN certificado c ON c.id=cp.id_certificado AND c.id_instituicao=cp.id_instituicao ' +
      'SET cp.situacao=''PENDENTE'',cp.tentativas=0,cp.proxima_tentativa_em=NULL,' +
      'cp.processando_em=NULL,cp.concluido_em=NULL,cp.ultimo_erro=NULL,cp.solicitado_por=:usuario,' +
      'c.situacao=CASE WHEN c.situacao=''ERRO'' THEN ''PENDENTE'' ELSE c.situacao END ' +
      'WHERE cp.id_instituicao=:tenant AND cp.id_certificado=:certificado ' +
      'AND cp.situacao=''ERRO'' AND c.situacao IN (''PENDENTE'',''ERRO'')';
    Q.ParamByName('usuario').AsLargeInt := ASolicitadoPor;
    Q.ParamByName('tenant').AsLargeInt := AIdInstituicao;
    Q.ParamByName('certificado').AsLargeInt := AIdCertificado;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
