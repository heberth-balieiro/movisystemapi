unit EleicaoResultadoPublicoAPI.Dao;

interface

uses
  Uni,
  System.Generics.Collections;

type
  TEleicaoResultadoPublicoDados = record
    IdEleicao: Integer;
    IdEmpresa: Integer;
    Nome: string;
    Situacao: string;
    Operacao: string;
  end;

  TEleicaoResultadoPublicoResumo = record
    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;
  end;

  TEleicaoResultadoPublicoChapa = record
    IdChapa: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoResultadoPublicoOpcao = record
    IdOpcao: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
  end;

  TEleicaoResultadoPublicoOpcoes = TList<TEleicaoResultadoPublicoOpcao>;

  TEleicaoResultadoPublicoQuestao = class
  public
    IdQuestao: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TEleicaoResultadoPublicoOpcoes;

    constructor Create;
    destructor Destroy; override;
  end;

  TEleicaoResultadoPublicoLista = TList<TEleicaoResultadoPublicoChapa>;
  TEleicaoResultadoPublicoQuestoes = TObjectList<TEleicaoResultadoPublicoQuestao>;

  TEleicaoResultadoPublicoAPIDao = class
  public
    class function BuscarEleicaoPublicada(
      const AConn: TUniConnection;
      const ASlug: string;
      out AEleicao: TEleicaoResultadoPublicoDados
    ): Boolean; static;

    class function BuscarResumo(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer;
      out AResumo: TEleicaoResultadoPublicoResumo
    ): Boolean; static;

    class function BuscarTotalVotantes(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer
    ): Integer; static;

    class procedure BuscarChapas(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer;
      const ALista: TEleicaoResultadoPublicoLista
    ); static;

    class procedure BuscarQuestoes(
      const AConn: TUniConnection;
      const AIdEmpresa, AIdEleicao: Integer;
      const ALista: TEleicaoResultadoPublicoQuestoes
    ); static;
  end;

implementation

uses
  System.SysUtils;

constructor TEleicaoResultadoPublicoQuestao.Create;
begin
  inherited Create;
  Opcoes := TEleicaoResultadoPublicoOpcoes.Create;
end;

destructor TEleicaoResultadoPublicoQuestao.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

class function TEleicaoResultadoPublicoAPIDao.BuscarEleicaoPublicada(
  const AConn: TUniConnection;
  const ASlug: string;
  out AEleicao: TEleicaoResultadoPublicoDados
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AEleicao := Default(TEleicaoResultadoPublicoDados);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT e.id,e.empresa_id,e.nome,e.situacao,COALESCE(e.operacao,'''') AS operacao ' +
      'FROM eleicao e ' +
      'INNER JOIN eleicao_configuracao ec ON ec.eleicao_id=e.id AND ec.empresa_id=e.empresa_id ' +
      'WHERE LOWER(TRIM(ec.slug))=LOWER(TRIM(:slug)) ' +
      '  AND ec.pagina_publicar=''S'' ' +
      '  AND e.ativo=''S'' ' +
      '  AND e.situacao=''PUBLICADA'' ' +
      'LIMIT 1';

    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AEleicao.IdEleicao := Qry.FieldByName('id').AsInteger;
    AEleicao.IdEmpresa := Qry.FieldByName('empresa_id').AsInteger;
    AEleicao.Nome := Qry.FieldByName('nome').AsString;
    AEleicao.Situacao := Qry.FieldByName('situacao').AsString;
    AEleicao.Operacao := UpperCase(Trim(Qry.FieldByName('operacao').AsString));
    Result := True;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoResultadoPublicoAPIDao.BuscarResumo(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer;
  out AResumo: TEleicaoResultadoPublicoResumo
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AResumo := Default(TEleicaoResultadoPublicoResumo);

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

class function TEleicaoResultadoPublicoAPIDao.BuscarTotalVotantes(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer
): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM eleicao_votante ' +
      'WHERE empresa_id=:idempresa AND eleicao_id=:ideleicao AND votou=''S''';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;
    Result := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoResultadoPublicoAPIDao.BuscarChapas(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer;
  const ALista: TEleicaoResultadoPublicoLista
);
var
  Qry: TUniQuery;
  Item: TEleicaoResultadoPublicoChapa;
begin
  ALista.Clear;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT c.id,c.num_chapa,c.nome_chapa,COUNT(v.id) AS quantidade_votos ' +
      'FROM eleicao_chapa c ' +
      'LEFT JOIN eleicao_voto v ON v.eleicao_chapa_id=c.id ' +
      ' AND v.empresa_id=c.empresa_id AND v.eleicao_id=c.eleicao_id ' +
      ' AND v.tipo_voto=''CHAPA'' ' +
      'WHERE c.empresa_id=:idempresa AND c.eleicao_id=:ideleicao AND c.ativo=''S'' ' +
      'GROUP BY c.id,c.num_chapa,c.nome_chapa ' +
      'ORDER BY quantidade_votos DESC,c.num_chapa';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := Default(TEleicaoResultadoPublicoChapa);
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

class procedure TEleicaoResultadoPublicoAPIDao.BuscarQuestoes(
  const AConn: TUniConnection;
  const AIdEmpresa, AIdEleicao: Integer;
  const ALista: TEleicaoResultadoPublicoQuestoes
);
var
  QryQuestao, QryOpcao: TUniQuery;
  Questao: TEleicaoResultadoPublicoQuestao;
  Opcao: TEleicaoResultadoPublicoOpcao;
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
      'GROUP BY q.id,q.ordem,q.titulo ' +
      'ORDER BY q.ordem,q.id';
    QryQuestao.ParamByName('idempresa').AsInteger := AIdEmpresa;
    QryQuestao.ParamByName('ideleicao').AsInteger := AIdEleicao;
    QryQuestao.Open;

    while not QryQuestao.Eof do
    begin
      Questao := TEleicaoResultadoPublicoQuestao.Create;
      Questao.IdQuestao := QryQuestao.FieldByName('id').AsInteger;
      Questao.Ordem := QryQuestao.FieldByName('ordem').AsInteger;
      Questao.Titulo := QryQuestao.FieldByName('titulo').AsString;
      Questao.TotalVotos := QryQuestao.FieldByName('total_votos').AsInteger;

      QryOpcao.Close;
      QryOpcao.SQL.Text :=
        'SELECT o.id,o.ordem,o.descricao,COUNT(v.id) AS quantidade_votos ' +
        'FROM eleicao_questao_opcao o ' +
        'LEFT JOIN eleicao_questao_voto v ON v.opcao_id=o.id ' +
        ' AND v.questao_id=o.questao_id AND v.empresa_id=o.empresa_id ' +
        ' AND v.eleicao_id=o.eleicao_id ' +
        'WHERE o.empresa_id=:idempresa AND o.eleicao_id=:ideleicao ' +
        ' AND o.questao_id=:idquestao AND o.ativo=''S'' ' +
        'GROUP BY o.id,o.ordem,o.descricao ' +
        'ORDER BY o.ordem,o.id';
      QryOpcao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryOpcao.ParamByName('ideleicao').AsInteger := AIdEleicao;
      QryOpcao.ParamByName('idquestao').AsInteger := Questao.IdQuestao;
      QryOpcao.Open;

      while not QryOpcao.Eof do
      begin
        Opcao := Default(TEleicaoResultadoPublicoOpcao);
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

end.
