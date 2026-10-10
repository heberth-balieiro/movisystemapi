{

BuscarUsuarioAdmin
→ identifica usuário da empresa da eleição

BuscarEleicao
→ dados da eleição pelo slug

BuscarResumoPainel
→ total de eleitores aptos
→ total que já votou

BuscarEvolucaoVotacao
→ quantidade de votos registrados por hora

}

unit EleicaoAdminAPI.Dao;

interface

uses
  Uni,
  System.Generics.Collections;

type
  TEleicaoAdminUsuario = record
    IdUsuario: Integer;
    IdEmpresa: Integer;
    Nome: string;
    Login: string;
    SenhaHash: string;
    Perfil: string;
    Email: string;
  end;

  TEleicaoAdminDados = record
    IdEleicao: Integer;
    IdEmpresa: Integer;
    Nome: string;
    Situacao: string;
    Operacao: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    abertura: string;
    encerramento: string;
  end;

  TEleicaoAdminResumo = record
    TotalEleitores: Integer;
    TotalVotantes: Integer;
  end;

  TEleicaoAdminEvolucao = record
    Hora: string;
    Quantidade: Integer;
  end;

  TEleicaoAdminAPIListEvolucao = TList<TEleicaoAdminEvolucao>;

{$REGION 'APURACAO'}

type
  TEleicaoAdminResultadoResumo = record
    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;
  end;

  TEleicaoAdminResultadoChapa = record
    IdChapa: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoAdminResultadoOpcao = record
    IdOpcao: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoAdminResultadoOpcoes = TList<TEleicaoAdminResultadoOpcao>;

  TEleicaoAdminResultadoQuestao = class
  public
    IdQuestao: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TEleicaoAdminResultadoOpcoes;

    constructor Create;
    destructor Destroy; override;
  end;

  TEleicaoAdminResultadoLista = TList<TEleicaoAdminResultadoChapa>;
  TEleicaoAdminResultadoQuestoes = TObjectList<TEleicaoAdminResultadoQuestao>;

{$ENDREGION}

  TEleicaoAdminAPIDao = class
  public
    class function BuscarUsuarioAdmin(
      const AConn: TUniConnection;
      const ASlug: string;
      const AEmail: string;
      out AUsuario: TEleicaoAdminUsuario
    ): Boolean; static;

    class function BuscarEleicao(
      const AConn: TUniConnection;
      const ASlug: string;
      const AIdEmpresa: Integer;
      out AEleicao: TEleicaoAdminDados
    ): Boolean; static;

    class function BuscarResumoPainel(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      out AResumo: TEleicaoAdminResumo
    ): Boolean; static;

    class procedure BuscarEvolucaoVotacao(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer;
      const ADataHoraInicio, ADataHoraFim: TDateTime;
      const ALista: TEleicaoAdminAPIListEvolucao
    ); static;

    class function EncerrarEleicao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): Boolean; static;

    class function IniciarApuracao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): Boolean; static;

    class function FinalizarApuracao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): Boolean; static;

    class function BuscarResumoResultado(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      out AResumo: TEleicaoAdminResultadoResumo
    ): Boolean; static;

    class procedure BuscarResultadoChapas(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const ALista: TEleicaoAdminResultadoLista
    ); static;

    class procedure BuscarResultadoQuestoes(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const ALista: TEleicaoAdminResultadoQuestoes
    ); static;

    class function PublicarResultado(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): Boolean; static;

    class function AbrirAutomaticamente(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer
    ): Boolean; static;

    class function EncerrarAutomaticamente(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer
    ): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TEleicaoAdminResultadoQuestao }

constructor TEleicaoAdminResultadoQuestao.Create;
begin
  inherited Create;
  Opcoes := TEleicaoAdminResultadoOpcoes.Create;
end;

destructor TEleicaoAdminResultadoQuestao.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

{ TEleicaoAdminAPIDao }

class function TEleicaoAdminAPIDao.BuscarUsuarioAdmin(
  const AConn: TUniConnection;
  const ASlug: string;
  const AEmail: string;
  out AUsuario: TEleicaoAdminUsuario
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AUsuario := Default(TEleicaoAdminUsuario);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT u.id,u.empresa_id,u.nome,u.login,u.senha_hash,u.perfil,u.email ' +
      'FROM usuario u ' +
      'INNER JOIN eleicao_configuracao ec ON ec.empresa_id=u.empresa_id ' +
      'INNER JOIN eleicao e ON e.id=ec.eleicao_id AND e.empresa_id=ec.empresa_id ' +
      'LEFT JOIN eleicao_comissao cm ON cm.usuario_id=u.id ' +
      ' AND cm.empresa_id=u.empresa_id AND cm.eleicao_id=e.id AND cm.ativo=''S'' ' +
      'WHERE LOWER(TRIM(ec.slug))=LOWER(TRIM(:slug)) ' +
      ' AND LOWER(TRIM(u.email))=LOWER(TRIM(:email)) ' +
      ' AND u.ativo=''S'' AND e.ativo=''S'' AND ec.pagina_publicar=''S'' ' +
      ' AND (u.perfil=''ADMIN'' OR (u.perfil=''COMISSAO'' AND cm.id IS NOT NULL)) ' +
      'ORDER BY CASE WHEN u.perfil=''ADMIN'' THEN 0 ELSE 1 END LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.ParamByName('email').AsString := Trim(AEmail);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AUsuario.IdUsuario := Qry.FieldByName('id').AsInteger;
    AUsuario.IdEmpresa := Qry.FieldByName('empresa_id').AsInteger;
    AUsuario.Nome := Qry.FieldByName('nome').AsString;
    AUsuario.Email := Qry.FieldByName('email').AsString;
    AUsuario.SenhaHash := Qry.FieldByName('senha_hash').AsString;
    AUsuario.Perfil := Qry.FieldByName('perfil').AsString;
    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.AbrirAutomaticamente(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id=e.id ' +
      'SET e.situacao=''ABERTA'' ' +
      'WHERE e.id=:ideleicao AND e.empresa_id=:idempresa ' +
      'AND e.situacao=''AGENDADA'' AND ec.abertura_automatica=''S'' ' +
      'AND NOW()>=ec.data_hora_inicio AND NOW()<ec.data_hora_fim';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.EncerrarAutomaticamente(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id=e.id ' +
      'SET e.situacao=''ENCERRADA'' ' +
      'WHERE e.id=:ideleicao AND e.empresa_id=:idempresa ' +
      'AND e.situacao=''ABERTA'' AND ec.encerramento_automatico=''S'' ' +
      'AND NOW()>=ec.data_hora_fim';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.BuscarEleicao(
  const AConn: TUniConnection;
  const ASlug: string;
  const AIdEmpresa: Integer;
  out AEleicao: TEleicaoAdminDados
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AEleicao := Default(TEleicaoAdminDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT e.id,e.empresa_id,e.nome,e.situacao,COALESCE(e.operacao,'''') AS operacao,' +
      ' ec.data_hora_inicio,ec.data_hora_fim,ec.abertura_automatica,ec.encerramento_automatico ' +
      'FROM eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id=e.id AND ec.empresa_id=e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug))=LOWER(TRIM(:slug)) ' +
      ' AND e.empresa_id=:idempresa AND e.ativo=''S'' AND ec.pagina_publicar=''S'' LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AEleicao.IdEleicao := Qry.FieldByName('id').AsInteger;
    AEleicao.IdEmpresa := Qry.FieldByName('empresa_id').AsInteger;
    AEleicao.Nome := Qry.FieldByName('nome').AsString;
    AEleicao.Situacao := Qry.FieldByName('situacao').AsString;
    AEleicao.Operacao := UpperCase(Trim(Qry.FieldByName('operacao').AsString));
    AEleicao.DataHoraInicio := Qry.FieldByName('data_hora_inicio').AsDateTime;
    AEleicao.DataHoraFim := Qry.FieldByName('data_hora_fim').AsDateTime;
    AEleicao.abertura := Qry.FieldByName('abertura_automatica').AsString;
    AEleicao.encerramento := Qry.FieldByName('encerramento_automatico').AsString;
    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.BuscarResumoPainel(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  out AResumo: TEleicaoAdminResumo
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoAdminResumo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' (SELECT COUNT(DISTINCT u.id) FROM usuario u ' +
      '  INNER JOIN pessoa p ON p.id=u.pessoa_id AND p.empresa_id=u.empresa_id ' +
      '  WHERE u.empresa_id=:idempresa AND u.ativo=''S'' AND p.ativo=''S'' ' +
      '   AND COALESCE(p.bloqueado,''N'')=''N'' AND COALESCE(p.excluido,0)=0) AS total_eleitores,' +
      ' (SELECT COUNT(*) FROM eleicao_votante ev ' +
      '  WHERE ev.empresa_id=:idempresa AND ev.eleicao_id=:ideleicao AND ev.votou=''S'') AS total_votantes';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AResumo.TotalEleitores := Qry.FieldByName('total_eleitores').AsInteger;
    AResumo.TotalVotantes := Qry.FieldByName('total_votantes').AsInteger;
    Result := True;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoAdminAPIDao.BuscarEvolucaoVotacao(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer;
  const ADataHoraInicio, ADataHoraFim: TDateTime;
  const ALista: TEleicaoAdminAPIListEvolucao
);
var
  Qry: TUniQuery;
  Item: TEleicaoAdminEvolucao;
begin
  ALista.Clear;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT DATE_FORMAT(votado_em,''%H:00'') AS hora,COUNT(*) AS quantidade ' +
      'FROM eleicao_votante ' +
      'WHERE empresa_id=:idempresa AND eleicao_id=:ideleicao AND votou=''S'' ' +
      'AND votado_em>=:inicio AND votado_em<=:fim ' +
      'GROUP BY DATE_FORMAT(votado_em,''%H:00'') ORDER BY DATE_FORMAT(votado_em,''%H:00'')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('inicio').AsDateTime := ADataHoraInicio;
    Qry.ParamByName('fim').AsDateTime := ADataHoraFim;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoAdminEvolucao);
      Item.Hora := Qry.FieldByName('hora').AsString;
      Item.Quantidade := Qry.FieldByName('quantidade').AsInteger;
      ALista.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.EncerrarEleicao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao SET situacao=''ENCERRADA'' ' +
      'WHERE id=:ideleicao AND empresa_id=:idempresa AND ativo=''S'' AND situacao=''ABERTA''';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.IniciarApuracao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao SET situacao=''EM_APURACAO'' ' +
      'WHERE id=:ideleicao AND empresa_id=:idempresa AND ativo=''S'' AND situacao=''ENCERRADA''';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.FinalizarApuracao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao SET situacao=''APURADA'' ' +
      'WHERE id=:ideleicao AND empresa_id=:idempresa AND ativo=''S'' AND situacao=''EM_APURACAO''';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoAdminAPIDao.BuscarResumoResultado(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  out AResumo: TEleicaoAdminResultadoResumo
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoAdminResultadoResumo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total_votos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''CHAPA'' THEN 1 ELSE 0 END),0) AS votos_validos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''BRANCO'' THEN 1 ELSE 0 END),0) AS votos_brancos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''NULO'' THEN 1 ELSE 0 END),0) AS votos_nulos ' +
      'FROM eleicao_voto WHERE empresa_id=:idempresa AND eleicao_id=:ideleicao';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AResumo.TotalVotos := Qry.FieldByName('total_votos').AsInteger;
    AResumo.VotosValidos := Qry.FieldByName('votos_validos').AsInteger;
    AResumo.VotosBrancos := Qry.FieldByName('votos_brancos').AsInteger;
    AResumo.VotosNulos := Qry.FieldByName('votos_nulos').AsInteger;
    Result := True;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoAdminAPIDao.BuscarResultadoChapas(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const ALista: TEleicaoAdminResultadoLista
);
var
  Qry: TUniQuery;
  Item: TEleicaoAdminResultadoChapa;
begin
  ALista.Clear;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.id,c.num_chapa,c.nome_chapa,COUNT(v.id) AS quantidade_votos ' +
      'FROM eleicao_chapa c ' +
      'LEFT JOIN eleicao_voto v ON v.eleicao_chapa_id=c.id ' +
      ' AND v.empresa_id=c.empresa_id AND v.eleicao_id=c.eleicao_id AND v.tipo_voto=''CHAPA'' ' +
      'WHERE c.empresa_id=:idempresa AND c.eleicao_id=:ideleicao AND c.ativo=''S'' ' +
      'GROUP BY c.id,c.num_chapa,c.nome_chapa ORDER BY quantidade_votos DESC,c.num_chapa';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoAdminResultadoChapa);
      Item.IdChapa := Qry.FieldByName('id').AsInteger;
      Item.Numero := Qry.FieldByName('num_chapa').AsInteger;
      Item.Nome := Qry.FieldByName('nome_chapa').AsString;
      Item.QuantidadeVotos := Qry.FieldByName('quantidade_votos').AsInteger;
      ALista.Add(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoAdminAPIDao.BuscarResultadoQuestoes(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const ALista: TEleicaoAdminResultadoQuestoes
);
var
  QryQuestao, QryOpcao: TUniQuery;
  Questao: TEleicaoAdminResultadoQuestao;
  Opcao: TEleicaoAdminResultadoOpcao;
begin
  ALista.Clear;

  QryQuestao := TUniQuery.Create(nil);
  QryOpcao := TUniQuery.Create(nil);
  try
    QryQuestao.Connection := AConn;
    QryOpcao.Connection := AConn;

    QryQuestao.SQL.Text :=
      'SELECT q.id,q.ordem,q.titulo,COUNT(v.id) AS total_votos ' +
      'FROM eleicao_questao q ' +
      'LEFT JOIN eleicao_questao_voto v ON v.questao_id=q.id ' +
      ' AND v.empresa_id=q.empresa_id AND v.eleicao_id=q.eleicao_id ' +
      'WHERE q.empresa_id=:idempresa AND q.eleicao_id=:ideleicao AND q.ativo=''S'' ' +
      'GROUP BY q.id,q.ordem,q.titulo ORDER BY q.ordem,q.id';
    QryQuestao.ParamByName('idempresa').AsInteger := AIdEmpresa;
    QryQuestao.ParamByName('ideleicao').AsInteger := AIdEleicao;
    QryQuestao.Open;

    while not QryQuestao.Eof do
    begin
      Questao := TEleicaoAdminResultadoQuestao.Create;
      Questao.IdQuestao := QryQuestao.FieldByName('id').AsInteger;
      Questao.Ordem := QryQuestao.FieldByName('ordem').AsInteger;
      Questao.Titulo := QryQuestao.FieldByName('titulo').AsString;
      Questao.TotalVotos := QryQuestao.FieldByName('total_votos').AsInteger;

      QryOpcao.Close;
      QryOpcao.SQL.Text :=
        'SELECT o.id,o.ordem,o.descricao,COUNT(v.id) AS quantidade_votos ' +
        'FROM eleicao_questao_opcao o ' +
        'LEFT JOIN eleicao_questao_voto v ON v.opcao_id=o.id ' +
        ' AND v.questao_id=o.questao_id AND v.empresa_id=o.empresa_id AND v.eleicao_id=o.eleicao_id ' +
        'WHERE o.empresa_id=:idempresa AND o.eleicao_id=:ideleicao ' +
        ' AND o.questao_id=:idquestao AND o.ativo=''S'' ' +
        'GROUP BY o.id,o.ordem,o.descricao ORDER BY o.ordem,o.id';
      QryOpcao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryOpcao.ParamByName('ideleicao').AsInteger := AIdEleicao;
      QryOpcao.ParamByName('idquestao').AsInteger := Questao.IdQuestao;
      QryOpcao.Open;

      while not QryOpcao.Eof do
      begin
        Opcao := Default(TEleicaoAdminResultadoOpcao);
        Opcao.IdOpcao := QryOpcao.FieldByName('id').AsInteger;
        Opcao.Ordem := QryOpcao.FieldByName('ordem').AsInteger;
        Opcao.Descricao := QryOpcao.FieldByName('descricao').AsString;
        Opcao.QuantidadeVotos := QryOpcao.FieldByName('quantidade_votos').AsInteger;
        Questao.Opcoes.Add(Opcao);
        QryOpcao.Next;
      end;

      ALista.Add(Questao);
      QryQuestao.Next;
    end;
  finally
    QryOpcao.Free;
    QryQuestao.Free;
  end;
end;

class function TEleicaoAdminAPIDao.PublicarResultado(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE eleicao SET situacao=''PUBLICADA'' ' +
      'WHERE id=:ideleicao AND empresa_id=:idempresa AND ativo=''S'' AND situacao=''APURADA''';
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ExecSQL;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

end.
