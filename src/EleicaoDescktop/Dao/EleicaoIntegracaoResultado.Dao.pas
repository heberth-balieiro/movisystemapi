unit EleicaoIntegracaoResultado.Dao;

interface

uses
  Uni,
  System.Generics.Collections;

type
  TEleicaoIntegracaoResultadoEleicao = record
    IdEleicao: Integer;
    IdEleicaoInt: Integer;
    Nome: string;
    Situacao: string;
    Operacao: string;
  end;

  TEleicaoIntegracaoParticipacaoResumo = record
    TotalEleitores: Integer;
    TotalVotantes: Integer;
  end;

  TEleicaoIntegracaoApuracaoResumo = record
    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;
  end;

  TEleicaoIntegracaoResultadoChapa = record
    IdChapaInt: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoIntegracaoResultadoOpcao = record
    IdOpcaoInt: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoIntegracaoResultadoOpcoes = TList<TEleicaoIntegracaoResultadoOpcao>;

  TEleicaoIntegracaoResultadoQuestao = class
  public
    IdQuestaoInt: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TEleicaoIntegracaoResultadoOpcoes;

    constructor Create;
    destructor Destroy; override;
  end;

  TEleicaoIntegracaoResultadoChapas = TList<TEleicaoIntegracaoResultadoChapa>;
  TEleicaoIntegracaoResultadoQuestoes = TObjectList<TEleicaoIntegracaoResultadoQuestao>;

  TEleicaoIntegracaoResultadoDao = class
  public
    class function BuscarEleicao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicaoInt: Integer;
      out AEleicao: TEleicaoIntegracaoResultadoEleicao
    ): Boolean; static;

    class function BuscarResumoParticipacao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      out AResumo: TEleicaoIntegracaoParticipacaoResumo
    ): Boolean; static;

    class function BuscarResumoApuracao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      out AResumo: TEleicaoIntegracaoApuracaoResumo
    ): Boolean; static;

    class procedure BuscarResultadoChapas(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const ALista: TEleicaoIntegracaoResultadoChapas
    ); static;

    class procedure BuscarResultadoQuestoes(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const ALista: TEleicaoIntegracaoResultadoQuestoes
    ); static;
  end;

implementation

uses
  System.SysUtils;

{ TEleicaoIntegracaoResultadoQuestao }

constructor TEleicaoIntegracaoResultadoQuestao.Create;
begin
  inherited Create;
  Opcoes := TEleicaoIntegracaoResultadoOpcoes.Create;
end;

destructor TEleicaoIntegracaoResultadoQuestao.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

{ TEleicaoIntegracaoResultadoDao }

class function TEleicaoIntegracaoResultadoDao.BuscarEleicao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicaoInt: Integer;
  out AEleicao: TEleicaoIntegracaoResultadoEleicao
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AEleicao := Default(TEleicaoIntegracaoResultadoEleicao);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id,id_eleicao_int,nome,situacao,COALESCE(operacao,'''') AS operacao ' +
      'FROM eleicao ' +
      'WHERE empresa_id=:idempresa AND id_eleicao_int=:ideleicaoint ' +
      'LIMIT 1';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicaoint').AsInteger := AIdEleicaoInt;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AEleicao.IdEleicao := Qry.FieldByName('id').AsInteger;
    AEleicao.IdEleicaoInt := Qry.FieldByName('id_eleicao_int').AsInteger;
    AEleicao.Nome := Qry.FieldByName('nome').AsString;
    AEleicao.Situacao := UpperCase(Trim(Qry.FieldByName('situacao').AsString));
    AEleicao.Operacao := UpperCase(Trim(Qry.FieldByName('operacao').AsString));

    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoIntegracaoResultadoDao.BuscarResumoParticipacao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  out AResumo: TEleicaoIntegracaoParticipacaoResumo
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoIntegracaoParticipacaoResumo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total_eleitores,' +
      ' COALESCE(SUM(CASE WHEN votou=''S'' THEN 1 ELSE 0 END),0) AS total_votantes ' +
      'FROM eleicao_votante ' +
      'WHERE empresa_id=:idempresa AND eleicao_id=:ideleicao';

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

class function TEleicaoIntegracaoResultadoDao.BuscarResumoApuracao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  out AResumo: TEleicaoIntegracaoApuracaoResumo
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoIntegracaoApuracaoResumo);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total_votos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''CHAPA'' THEN 1 ELSE 0 END),0) AS votos_validos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''BRANCO'' THEN 1 ELSE 0 END),0) AS votos_brancos,' +
      ' COALESCE(SUM(CASE WHEN tipo_voto=''NULO'' THEN 1 ELSE 0 END),0) AS votos_nulos ' +
      'FROM eleicao_voto ' +
      'WHERE empresa_id=:idempresa AND eleicao_id=:ideleicao';

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

class procedure TEleicaoIntegracaoResultadoDao.BuscarResultadoChapas(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const ALista: TEleicaoIntegracaoResultadoChapas
);
var
  Qry: TUniQuery;
  Item: TEleicaoIntegracaoResultadoChapa;
begin
  if ALista = nil then
    Exit;

  ALista.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.id_chapa_int,c.num_chapa,c.nome_chapa,COUNT(v.id) AS quantidade_votos ' +
      'FROM eleicao_chapa c ' +
      'LEFT JOIN eleicao_voto v ON v.eleicao_chapa_id=c.id ' +
      ' AND v.empresa_id=c.empresa_id AND v.eleicao_id=c.eleicao_id ' +
      ' AND v.tipo_voto=''CHAPA'' ' +
      'WHERE c.empresa_id=:idempresa AND c.eleicao_id=:ideleicao AND c.ativo=''S'' ' +
      'GROUP BY c.id,c.id_chapa_int,c.num_chapa,c.nome_chapa ' +
      'ORDER BY quantidade_votos DESC,c.num_chapa';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoIntegracaoResultadoChapa);
      Item.IdChapaInt := Qry.FieldByName('id_chapa_int').AsInteger;
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

class procedure TEleicaoIntegracaoResultadoDao.BuscarResultadoQuestoes(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const ALista: TEleicaoIntegracaoResultadoQuestoes
);
var
  QryQuestao, QryOpcao: TUniQuery;
  Questao: TEleicaoIntegracaoResultadoQuestao;
  Opcao: TEleicaoIntegracaoResultadoOpcao;
begin
  if ALista = nil then
    Exit;

  ALista.Clear;

  QryQuestao := TUniQuery.Create(nil);
  QryOpcao := TUniQuery.Create(nil);
  try
    QryQuestao.Connection := AConn;
    QryOpcao.Connection := AConn;

    QryQuestao.SQL.Text :=
      'SELECT q.id,q.id_questao_int,q.ordem,q.titulo,' +
      ' COUNT(v.id) AS total_votos ' +
      'FROM eleicao_questao q ' +
      'LEFT JOIN eleicao_questao_voto v ON v.questao_id=q.id ' +
      ' AND v.empresa_id=q.empresa_id AND v.eleicao_id=q.eleicao_id ' +
      'WHERE q.empresa_id=:idempresa AND q.eleicao_id=:ideleicao AND q.ativo=''S'' ' +
      'GROUP BY q.id,q.id_questao_int,q.ordem,q.titulo ' +
      'ORDER BY q.ordem,q.id';
    QryQuestao.ParamByName('idempresa').AsInteger := AIdEmpresa;
    QryQuestao.ParamByName('ideleicao').AsInteger := AIdEleicao;
    QryQuestao.Open;

    while not QryQuestao.Eof do
    begin
      Questao := TEleicaoIntegracaoResultadoQuestao.Create;
      Questao.IdQuestaoInt := QryQuestao.FieldByName('id_questao_int').AsInteger;
      Questao.Ordem := QryQuestao.FieldByName('ordem').AsInteger;
      Questao.Titulo := QryQuestao.FieldByName('titulo').AsString;
      Questao.TotalVotos := QryQuestao.FieldByName('total_votos').AsInteger;

      QryOpcao.Close;
      QryOpcao.SQL.Text :=
        'SELECT o.id_opcao_int,o.ordem,o.descricao,COUNT(v.id) AS quantidade_votos ' +
        'FROM eleicao_questao_opcao o ' +
        'LEFT JOIN eleicao_questao_voto v ON v.opcao_id=o.id ' +
        ' AND v.questao_id=o.questao_id AND v.empresa_id=o.empresa_id ' +
        ' AND v.eleicao_id=o.eleicao_id ' +
        'WHERE o.empresa_id=:idempresa AND o.eleicao_id=:ideleicao ' +
        ' AND o.questao_id=:idquestao AND o.ativo=''S'' ' +
        'GROUP BY o.id,o.id_opcao_int,o.ordem,o.descricao ' +
        'ORDER BY o.ordem,o.id';
      QryOpcao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryOpcao.ParamByName('ideleicao').AsInteger := AIdEleicao;
      QryOpcao.ParamByName('idquestao').AsInteger := QryQuestao.FieldByName('id').AsInteger;
      QryOpcao.Open;

      while not QryOpcao.Eof do
      begin
        Opcao := Default(TEleicaoIntegracaoResultadoOpcao);
        Opcao.IdOpcaoInt := QryOpcao.FieldByName('id_opcao_int').AsInteger;
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

end.
