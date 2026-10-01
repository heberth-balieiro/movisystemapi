unit EncontroCheckin.DAO;

interface

uses Uni, EncontroCheckin.Model;

type
  TEncontroCheckinDAO = class
  public
    class function Administrar(C: TUniConnection; Tenant, Usuario, Turma, Encontro: Int64;
      const Acao, Hash: string): TEncontroCheckinInfo; static;
    class function Consultar(C: TUniConnection; Tenant, Participante: Int64;
      const Hash: string): TEncontroCheckinInfo; static;
    class procedure Confirmar(C: TUniConnection; Tenant, Usuario: Int64;
      var Info: TEncontroCheckinInfo); static;
    class function AdministrarTurma(C: TUniConnection; Tenant, Usuario, Turma: Int64;
      const Acao, Hash: string): TEncontroCheckinInfo; static;
    class function TokenTurmaExiste(C: TUniConnection; Tenant: Int64;
      const Hash: string): Boolean; static;
    class function ConsultarTurma(C: TUniConnection; Tenant, Participante: Int64;
      const Hash: string): TEncontroCheckinInfo; static;
    class procedure ConfirmarTurma(C: TUniConnection; Tenant, Usuario: Int64;
      var Info: TEncontroCheckinInfo); static;
    class function ListarPresencasTurma(C: TUniConnection; Tenant, Turma: Int64): TTurmaPresencaLista; static;
    class procedure Auditar(C: TUniConnection; Tenant, Usuario, Registro: Int64;
      const Acao, Entidade: string); static;
  end;

implementation

uses System.SysUtils, APP.Errors;

class procedure TEncontroCheckinDAO.Auditar(C: TUniConnection;
  Tenant, Usuario, Registro: Int64; const Acao, Entidade: string);
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text := 'INSERT INTO auditoria_log (id_instituicao, id_usuario_instituicao, ' +
      'acao, entidade, registro_id) VALUES (:t, :u, :a, :e, :r)';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('u').AsLargeInt := Usuario;
    Q.ParamByName('a').AsString := Acao;
    Q.ParamByName('e').AsString := Entidade;
    Q.ParamByName('r').AsString := IntToStr(Registro);
    Q.ExecSQL;
  finally Q.Free; end;
end;

class function TEncontroCheckinDAO.Administrar(C: TUniConnection;
  Tenant, Usuario, Turma, Encontro: Int64; const Acao, Hash: string): TEncontroCheckinInfo;
var Q: TUniQuery;
begin
  Result := Default(TEncontroCheckinInfo);
  Result.Tipo := 'ENCONTRO';
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    // All operations lock the meeting before the QR session, including student requests.
    Q.SQL.Text := 'SELECT e.titulo, t.nome AS turma_nome, e.situacao, t.situacao AS turma_situacao, ' +
      '(CURRENT_TIMESTAMP(3) >= e.data_hora_inicio AND CURRENT_TIMESTAMP(3) < e.data_hora_fim) AS no_horario ' +
      'FROM turma_encontro e JOIN turma t ON t.id_instituicao=e.id_instituicao AND t.id=e.id_turma ' +
      'JOIN instituicao i ON i.id=e.id_instituicao AND i.situacao=''ATIVA'' ' +
      'JOIN usuario_instituicao ui ON ui.id_instituicao=i.id AND ui.id=:u AND ui.situacao=''ATIVO'' ' +
      'JOIN usuario us ON us.id=ui.id_usuario AND us.situacao=''ATIVO'' ' +
      'WHERE e.id_instituicao=:t AND e.id_turma=:turma AND e.id=:e FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('u').AsLargeInt := Usuario;
    Q.ParamByName('turma').AsLargeInt := Turma;
    Q.ParamByName('e').AsLargeInt := Encontro;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('Encontro indisponível.');
    Result.IdTurma := Turma;
    Result.IdEncontro := Encontro;
    Result.Titulo := Q.FieldByName('titulo').AsString;
    Result.TurmaNome := Q.FieldByName('turma_nome').AsString;
    if Acao = 'abrir' then
      if (Q.FieldByName('situacao').AsString <> 'AGENDADO') or
         (Q.FieldByName('turma_situacao').AsString <> 'EM_ANDAMENTO') or
         not Q.FieldByName('no_horario').AsBoolean then
        TAppErrors.RaiseBadRequest('Abra o check-in durante o horário de um encontro agendado, com a turma em andamento.');
    Q.Close;
    if Acao = 'abrir' then
    begin
      Q.SQL.Text := 'INSERT INTO encontro_checkin (id_instituicao,id_turma,id_encontro,token_hash,expira_em,aberto_por) ' +
        'SELECT id_instituicao,id_turma,id,:hash,LEAST(data_hora_fim,DATE_ADD(CURRENT_TIMESTAMP(3),INTERVAL 15 MINUTE)),:u ' +
        'FROM turma_encontro WHERE id_instituicao=:t AND id_turma=:turma AND id=:e ' +
        'ON DUPLICATE KEY UPDATE token_hash=VALUES(token_hash), expira_em=VALUES(expira_em), ' +
        'aberto_por=VALUES(aberto_por), aberto_em=CURRENT_TIMESTAMP(3), encerrado_em=NULL';
      Q.ParamByName('hash').AsString := Hash;
      Q.ParamByName('u').AsLargeInt := Usuario;
      Q.ParamByName('turma').AsLargeInt := Turma;
    end
    else if Acao = 'encerrar' then
      Q.SQL.Text := 'UPDATE encontro_checkin SET encerrado_em=COALESCE(encerrado_em,CURRENT_TIMESTAMP(3)) ' +
        'WHERE id_instituicao=:t AND id_encontro=:e';
    if Acao <> 'consultar' then
    begin
      Q.ParamByName('t').AsLargeInt := Tenant;
      Q.ParamByName('e').AsLargeInt := Encontro;
      Q.ExecSQL;
      Auditar(C, Tenant, Usuario, Encontro, 'CHECKIN_' + UpperCase(Acao), 'turma_encontro');
    end;
    Q.SQL.Text := 'SELECT c.expira_em, GREATEST(0,TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP(3), ' +
      'LEAST(c.expira_em,e.data_hora_fim))) AS segundos, ' +
      '(c.encerrado_em IS NULL AND c.expira_em>CURRENT_TIMESTAMP(3) AND e.situacao=''AGENDADO'' ' +
      'AND t.situacao=''EM_ANDAMENTO'' AND CURRENT_TIMESTAMP(3)>=e.data_hora_inicio ' +
      'AND CURRENT_TIMESTAMP(3)<e.data_hora_fim) AS aberto ' +
      'FROM encontro_checkin c JOIN turma_encontro e ON e.id_instituicao=c.id_instituicao ' +
      'AND e.id_turma=c.id_turma AND e.id=c.id_encontro JOIN turma t ON t.id_instituicao=e.id_instituicao AND t.id=e.id_turma ' +
      'WHERE c.id_instituicao=:t AND c.id_encontro=:e';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('e').AsLargeInt := Encontro;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Result.ExpiraEm := Q.FieldByName('expira_em').AsDateTime;
      Result.Aberto := Q.FieldByName('aberto').AsInteger = 1;
      if Result.Aberto then Result.SegundosRestantes := Q.FieldByName('segundos').AsInteger;
    end;
  finally Q.Free; end;
end;

class function TEncontroCheckinDAO.Consultar(C: TUniConnection;
  Tenant, Participante: Int64; const Hash: string): TEncontroCheckinInfo;
var Q: TUniQuery;
begin
  Result := Default(TEncontroCheckinInfo);
  Result.Tipo := 'ENCONTRO';
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    // Locate first, then lock the parent. Recheck the hash under the lock after a rotation.
    Q.SQL.Text := 'SELECT id_turma,id_encontro FROM encontro_checkin WHERE id_instituicao=:t AND token_hash=:hash';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('hash').AsString := Hash;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('QR inválido, expirado ou encerrado.');
    Result.IdTurma := Q.FieldByName('id_turma').AsLargeInt;
    Result.IdEncontro := Q.FieldByName('id_encontro').AsLargeInt;
    Q.Close;
    Q.SQL.Text := 'SELECT e.titulo,t.nome AS turma_nome FROM turma_encontro e ' +
      'JOIN turma t ON t.id_instituicao=e.id_instituicao AND t.id=e.id_turma ' +
      'WHERE e.id_instituicao=:t AND e.id_turma=:turma AND e.id=:e AND e.situacao=''AGENDADO'' ' +
      'AND t.situacao=''EM_ANDAMENTO'' AND CURRENT_TIMESTAMP(3)>=e.data_hora_inicio ' +
      'AND CURRENT_TIMESTAMP(3)<e.data_hora_fim FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Result.IdTurma;
    Q.ParamByName('e').AsLargeInt := Result.IdEncontro;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('Encontro indisponível para check-in.');
    Result.Titulo := Q.FieldByName('titulo').AsString;
    Result.TurmaNome := Q.FieldByName('turma_nome').AsString;
    Q.Close;
    Q.SQL.Text := 'SELECT expira_em, GREATEST(0,TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP(3),expira_em)) AS segundos ' +
      'FROM encontro_checkin WHERE id_instituicao=:t AND id_encontro=:e AND token_hash=:hash ' +
      'AND encerrado_em IS NULL AND expira_em>CURRENT_TIMESTAMP(3) FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('e').AsLargeInt := Result.IdEncontro;
    Q.ParamByName('hash').AsString := Hash;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('QR inválido, expirado ou encerrado.');
    Result.Aberto := True;
    Result.ExpiraEm := Q.FieldByName('expira_em').AsDateTime;
    Result.SegundosRestantes := Q.FieldByName('segundos').AsInteger;
    Q.Close;
    Q.SQL.Text := 'SELECT id FROM inscricao WHERE id_instituicao=:t AND id_turma=:turma ' +
      'AND id_participante=:p AND situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'') FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Result.IdTurma;
    Q.ParamByName('p').AsLargeInt := Participante;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseForbidden('Você não possui inscrição confirmada nesta turma.');
    Result.IdInscricao := Q.FieldByName('id').AsLargeInt;
    Q.Close;
    Q.SQL.Text := 'SELECT id,situacao,checkin_em FROM presenca WHERE id_instituicao=:t ' +
      'AND id_encontro=:e AND id_inscricao=:i FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('e').AsLargeInt := Result.IdEncontro;
    Q.ParamByName('i').AsLargeInt := Result.IdInscricao;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Result.IdPresenca := Q.FieldByName('id').AsLargeInt;
      Result.Situacao := Q.FieldByName('situacao').AsString;
      if Result.Situacao <> 'PRESENTE' then
        TAppErrors.RaiseBadRequest('Há um lançamento de presença neste encontro. Solicite a revisão à equipe.');
      Result.JaRegistrada := True;
      if not Q.FieldByName('checkin_em').IsNull then Result.CheckinEm := Q.FieldByName('checkin_em').AsDateTime;
    end;
  finally Q.Free; end;
end;

class procedure TEncontroCheckinDAO.Confirmar(C: TUniConnection;
  Tenant, Usuario: Int64; var Info: TEncontroCheckinInfo);
var Q: TUniQuery;
begin
  if Info.JaRegistrada then Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text := 'INSERT INTO presenca (id_instituicao,id_turma,id_encontro,id_inscricao,situacao,checkin_em,registrado_por,origem) ' +
      'SELECT :t,:turma,:e,:i,''PRESENTE'',CURRENT_TIMESTAMP(3),:u,''AUTO_CHECKIN'' ' +
      'FROM encontro_checkin c JOIN turma_encontro e ON e.id_instituicao=c.id_instituicao ' +
      'AND e.id_turma=c.id_turma AND e.id=c.id_encontro ' +
      'WHERE c.id_instituicao=:t AND c.id_encontro=:e AND c.encerrado_em IS NULL ' +
      'AND CURRENT_TIMESTAMP(3)<c.expira_em AND CURRENT_TIMESTAMP(3)<e.data_hora_fim ' +
      'AND CURRENT_TIMESTAMP(3)>=e.data_hora_inicio AND e.situacao=''AGENDADO''';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Info.IdTurma;
    Q.ParamByName('e').AsLargeInt := Info.IdEncontro;
    Q.ParamByName('i').AsLargeInt := Info.IdInscricao;
    Q.ParamByName('u').AsLargeInt := Usuario;
    Q.ExecSQL;
    if Q.RowsAffected <> 1 then TAppErrors.RaiseBadRequest('O check-in expirou. Solicite outro QR à equipe.');
    Q.SQL.Text := 'SELECT id,checkin_em FROM presenca WHERE id_instituicao=:t AND id_encontro=:e AND id_inscricao=:i';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('e').AsLargeInt := Info.IdEncontro;
    Q.ParamByName('i').AsLargeInt := Info.IdInscricao;
    Q.Open;
    Info.IdPresenca := Q.FieldByName('id').AsLargeInt;
    Info.CheckinEm := Q.FieldByName('checkin_em').AsDateTime;
    Info.Situacao := 'PRESENTE';
    Auditar(C, Tenant, Usuario, Info.IdPresenca, 'PRESENCA_AUTO_CHECKIN', 'presenca');
  finally Q.Free; end;
end;

class function TEncontroCheckinDAO.AdministrarTurma(C: TUniConnection;
  Tenant, Usuario, Turma: Int64; const Acao, Hash: string): TEncontroCheckinInfo;
var Q: TUniQuery;
begin
  Result := Default(TEncontroCheckinInfo);
  Result.Tipo := 'TURMA';
  Result.IdTurma := Turma;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text :=
      'SELECT t.nome,t.situacao,t.controle_presenca,t.data_hora_inicio,t.data_hora_fim ' +
      'FROM turma t JOIN instituicao i ON i.id=t.id_instituicao AND i.situacao=''ATIVA'' ' +
      'JOIN usuario_instituicao ui ON ui.id_instituicao=t.id_instituicao AND ui.id=:u AND ui.situacao=''ATIVO'' ' +
      'WHERE t.id_instituicao=:t AND t.id=:turma FOR UPDATE';
    Q.ParamByName('u').AsLargeInt := Usuario;
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Turma;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('Turma indisponível.');
    Result.Titulo := 'Presença da turma';
    Result.TurmaNome := Q.FieldByName('nome').AsString;

    if not SameText(Q.FieldByName('controle_presenca').AsString, 'TURMA') then
      TAppErrors.RaiseBadRequest('Esta turma não utiliza presença por QR Code da turma.');

    if Acao = 'abrir' then
    begin
      if Q.FieldByName('situacao').AsString <> 'EM_ANDAMENTO' then
        TAppErrors.RaiseBadRequest('A presença só pode ser aberta quando a turma estiver em andamento.');

      if Now < Q.FieldByName('data_hora_inicio').AsDateTime then
        TAppErrors.RaiseBadRequest(
          'A presença poderá ser aberta a partir de ' +
          FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('data_hora_inicio').AsDateTime) +
          '.'
        );

      if Now >= Q.FieldByName('data_hora_fim').AsDateTime then
        TAppErrors.RaiseBadRequest(
          'A presença não pode ser aberta porque o horário da turma já foi encerrado.'
        );
    end;

    Q.Close;

    if Acao = 'abrir' then
    begin
      Q.SQL.Text :=
        'INSERT INTO turma_checkin (id_instituicao,id_turma,token_hash,expira_em,aberto_por) ' +
        'SELECT id_instituicao,id,:hash,LEAST(data_hora_fim,DATE_ADD(CURRENT_TIMESTAMP(3),INTERVAL 30 MINUTE)),:u ' +
        'FROM turma WHERE id_instituicao=:t AND id=:turma ' +
        'ON DUPLICATE KEY UPDATE token_hash=VALUES(token_hash),expira_em=VALUES(expira_em),' +
        'aberto_por=VALUES(aberto_por),aberto_em=CURRENT_TIMESTAMP(3),encerrado_em=NULL';
      Q.ParamByName('hash').AsString := Hash;
      Q.ParamByName('u').AsLargeInt := Usuario;
      Q.ParamByName('t').AsLargeInt := Tenant;
      Q.ParamByName('turma').AsLargeInt := Turma;
      Q.ExecSQL;
      Auditar(C, Tenant, Usuario, Turma, 'CHECKIN_TURMA_ABRIR', 'turma');
    end
    else if Acao = 'encerrar' then
    begin
      Q.SQL.Text := 'UPDATE turma_checkin SET encerrado_em=COALESCE(encerrado_em,CURRENT_TIMESTAMP(3)) ' +
        'WHERE id_instituicao=:t AND id_turma=:turma';
      Q.ParamByName('t').AsLargeInt := Tenant;
      Q.ParamByName('turma').AsLargeInt := Turma;
      Q.ExecSQL;
      Auditar(C, Tenant, Usuario, Turma, 'CHECKIN_TURMA_ENCERRAR', 'turma');
    end;

    Q.Close;
    Q.SQL.Text :=
      'SELECT expira_em,GREATEST(0,TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP(3),expira_em)) AS segundos,' +
      '(encerrado_em IS NULL AND expira_em>CURRENT_TIMESTAMP(3)) AS aberto ' +
      'FROM turma_checkin WHERE id_instituicao=:t AND id_turma=:turma';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Turma;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Result.ExpiraEm := Q.FieldByName('expira_em').AsDateTime;
      Result.Aberto := Q.FieldByName('aberto').AsInteger = 1;
      if Result.Aberto then Result.SegundosRestantes := Q.FieldByName('segundos').AsInteger;
    end;
  finally
    Q.Free;
  end;
end;

class function TEncontroCheckinDAO.TokenTurmaExiste(C: TUniConnection;
  Tenant: Int64; const Hash: string): Boolean;
var Q: TUniQuery;
begin
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text := 'SELECT 1 FROM turma_checkin WHERE id_instituicao=:t AND token_hash=:hash LIMIT 1';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('hash').AsString := Hash;
    Q.Open;
    Result := not Q.IsEmpty;
  finally
    Q.Free;
  end;
end;

class function TEncontroCheckinDAO.ConsultarTurma(C: TUniConnection;
  Tenant, Participante: Int64; const Hash: string): TEncontroCheckinInfo;
var Q: TUniQuery;
begin
  Result := Default(TEncontroCheckinInfo);
  Result.Tipo := 'TURMA';
  Result.Titulo := 'Presença da turma';
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text :=
      'SELECT tc.id_turma,t.nome AS turma_nome,tc.expira_em,' +
      'GREATEST(0,TIMESTAMPDIFF(SECOND,CURRENT_TIMESTAMP(3),tc.expira_em)) AS segundos ' +
      'FROM turma_checkin tc JOIN turma t ON t.id_instituicao=tc.id_instituicao AND t.id=tc.id_turma ' +
      'WHERE tc.id_instituicao=:tenant AND tc.token_hash=:hash AND tc.encerrado_em IS NULL ' +
      'AND tc.expira_em>CURRENT_TIMESTAMP(3) AND t.controle_presenca=''TURMA'' ' +
      'AND t.situacao=''EM_ANDAMENTO'' AND CURRENT_TIMESTAMP(3)>=t.data_hora_inicio ' +
      'AND CURRENT_TIMESTAMP(3)<t.data_hora_fim FOR UPDATE';
    Q.ParamByName('tenant').AsLargeInt := Tenant;
    Q.ParamByName('hash').AsString := Hash;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('QR da turma inválido, expirado ou encerrado.');
    Result.IdTurma := Q.FieldByName('id_turma').AsLargeInt;
    Result.TurmaNome := Q.FieldByName('turma_nome').AsString;
    Result.ExpiraEm := Q.FieldByName('expira_em').AsDateTime;
    Result.SegundosRestantes := Q.FieldByName('segundos').AsInteger;
    Result.Aberto := True;
    Q.Close;

    Q.SQL.Text := 'SELECT id FROM inscricao WHERE id_instituicao=:t AND id_turma=:turma ' +
      'AND id_participante=:p AND situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'') FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Result.IdTurma;
    Q.ParamByName('p').AsLargeInt := Participante;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseForbidden('Você não possui inscrição confirmada nesta turma.');
    Result.IdInscricao := Q.FieldByName('id').AsLargeInt;
    Q.Close;

    Q.SQL.Text := 'SELECT id,situacao,checkin_em FROM turma_presenca WHERE id_instituicao=:t ' +
      'AND id_turma=:turma AND id_inscricao=:i FOR UPDATE';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Result.IdTurma;
    Q.ParamByName('i').AsLargeInt := Result.IdInscricao;
    Q.Open;
    if not Q.IsEmpty then
    begin
      Result.IdPresenca := Q.FieldByName('id').AsLargeInt;
      Result.Situacao := Q.FieldByName('situacao').AsString;
      Result.JaRegistrada := SameText(Result.Situacao, 'PRESENTE');
      if not Q.FieldByName('checkin_em').IsNull then
        Result.CheckinEm := Q.FieldByName('checkin_em').AsDateTime;
    end;
  finally
    Q.Free;
  end;
end;

class procedure TEncontroCheckinDAO.ConfirmarTurma(C: TUniConnection;
  Tenant, Usuario: Int64; var Info: TEncontroCheckinInfo);
var Q: TUniQuery;
begin
  if Info.JaRegistrada then Exit;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text :=
      'INSERT INTO turma_presenca (id_instituicao,id_turma,id_inscricao,situacao,checkin_em,registrado_por,origem) ' +
      'SELECT :t,:turma,:i,''PRESENTE'',CURRENT_TIMESTAMP(3),:u,''AUTO_CHECKIN'' ' +
      'FROM turma_checkin tc JOIN turma tr ON tr.id_instituicao=tc.id_instituicao AND tr.id=tc.id_turma ' +
      'WHERE tc.id_instituicao=:t AND tc.id_turma=:turma AND tc.encerrado_em IS NULL ' +
      'AND tc.expira_em>CURRENT_TIMESTAMP(3) AND tr.controle_presenca=''TURMA'' ' +
      'AND tr.situacao=''EM_ANDAMENTO'' AND CURRENT_TIMESTAMP(3)>=tr.data_hora_inicio ' +
      'AND CURRENT_TIMESTAMP(3)<tr.data_hora_fim ' +
      'ON DUPLICATE KEY UPDATE situacao=''PRESENTE'',checkin_em=COALESCE(checkin_em,CURRENT_TIMESTAMP(3))';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Info.IdTurma;
    Q.ParamByName('i').AsLargeInt := Info.IdInscricao;
    Q.ParamByName('u').AsLargeInt := Usuario;
    Q.ExecSQL;

    Q.SQL.Text := 'SELECT id,checkin_em FROM turma_presenca WHERE id_instituicao=:t ' +
      'AND id_turma=:turma AND id_inscricao=:i';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Info.IdTurma;
    Q.ParamByName('i').AsLargeInt := Info.IdInscricao;
    Q.Open;
    if Q.IsEmpty then TAppErrors.RaiseBadRequest('O check-in expirou. Solicite outro QR à equipe.');
    Info.IdPresenca := Q.FieldByName('id').AsLargeInt;
    Info.CheckinEm := Q.FieldByName('checkin_em').AsDateTime;
    Info.Situacao := 'PRESENTE';
    Info.JaRegistrada := True;
    Auditar(C, Tenant, Usuario, Info.IdPresenca, 'PRESENCA_TURMA_AUTO_CHECKIN', 'turma_presenca');
  finally
    Q.Free;
  end;
end;


class function TEncontroCheckinDAO.ListarPresencasTurma(C: TUniConnection;
  Tenant, Turma: Int64): TTurmaPresencaLista;
var
  Q: TUniQuery;
  Item: TTurmaPresencaItem;
begin
  Result := TTurmaPresencaLista.Create;
  Q := TUniQuery.Create(nil);
  try
    Q.Connection := C;
    Q.SQL.Text :=
      'SELECT i.id AS id_inscricao,i.id_participante,p.nome AS participante_nome,' +
      'COALESCE(p.email,'''') AS participante_email,i.situacao AS situacao_inscricao,' +
      'tp.situacao AS situacao_presenca,tp.checkin_em,tp.origem ' +
      'FROM inscricao i ' +
      'JOIN participante p ON p.id_instituicao=i.id_instituicao AND p.id=i.id_participante ' +
      'LEFT JOIN turma_presenca tp ON tp.id_instituicao=i.id_instituicao ' +
      'AND tp.id_turma=i.id_turma AND tp.id_inscricao=i.id ' +
      'WHERE i.id_instituicao=:t AND i.id_turma=:turma ' +
      'AND i.situacao IN (''CONFIRMADO'',''EM_ANDAMENTO'',''CONCLUIDO'') ' +
      'ORDER BY p.nome,i.id';
    Q.ParamByName('t').AsLargeInt := Tenant;
    Q.ParamByName('turma').AsLargeInt := Turma;
    Q.Open;

    while not Q.Eof do
    begin
      Item := TTurmaPresencaItem.Create;
      Item.IdInscricao := Q.FieldByName('id_inscricao').AsLargeInt;
      Item.IdParticipante := Q.FieldByName('id_participante').AsLargeInt;
      Item.ParticipanteNome := Q.FieldByName('participante_nome').AsString;
      Item.ParticipanteEmail := Q.FieldByName('participante_email').AsString;
      Item.SituacaoInscricao := Q.FieldByName('situacao_inscricao').AsString;
      Item.TemPresenca := not Q.FieldByName('situacao_presenca').IsNull;
      if Item.TemPresenca then
      begin
        Item.SituacaoPresenca := Q.FieldByName('situacao_presenca').AsString;
        Item.TemCheckinEm := not Q.FieldByName('checkin_em').IsNull;
        if Item.TemCheckinEm then
          Item.CheckinEm := Q.FieldByName('checkin_em').AsDateTime;
        Item.Origem := Q.FieldByName('origem').AsString;
        if SameText(Item.SituacaoPresenca, 'PRESENTE') then
          Inc(Result.TotalPresentes);
      end;
      Inc(Result.TotalMatriculados);
      Result.Itens.Add(Item);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
