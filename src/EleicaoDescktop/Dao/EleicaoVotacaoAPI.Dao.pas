unit EleicaoVotacaoAPI.Dao;

interface

uses
  Uni,
  System.JSON;

type
  TEleicaoVotacaoAPIDao = class
  public
    class procedure GarantirEstruturaVotoQuestao(
      const AConn: TUniConnection
    ); static;

    class function EleitorJaVotou(
      const AConn: TUniConnection;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer
    ): Boolean; static;

    class function ChapaValida(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdChapa: Integer
    ): Boolean; static;

    class function BuscarOperacao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): string; static;

    class procedure AdicionarQuestoesCedula(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const ASlug: string;
      const ACedula: TJSONObject
    ); static;

    class function QuantidadeQuestoesObrigatorias(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer
    ): Integer; static;

    class function QuestaoOpcaoValida(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdQuestao: Integer;
      const AIdOpcao: Integer;
      out AObrigatoria: Boolean
    ): Boolean; static;

    class procedure RegistrarVoto(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdChapa: Integer;
      const ATipoVoto: string;
      const AComprovanteHash: string
    ); static;

    class procedure RegistrarVotoQuestao(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdQuestao: Integer;
      const AIdOpcao: Integer;
      const AComprovanteHash: string
    ); static;

    class procedure RegistrarVotante(
      const AConn: TUniConnection;
      const AIdEmpresa: Integer;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer
    ); static;
  end;

implementation

uses
  System.SysUtils,
  DB;

{ TEleicaoVotacaoAPIDao }

class procedure TEleicaoVotacaoAPIDao.GarantirEstruturaVotoQuestao(
  const AConn: TUniConnection
);
begin
  // A estrutura e criada pela migration 018_E.
  // Mantido para compatibilidade com o fluxo de votacao e apuracao.
end;

class function TEleicaoVotacaoAPIDao.EleitorJaVotou(
  const AConn: TUniConnection;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM eleicao_votante ' +
      'WHERE eleicao_id = :ideleicao ' +
      '  AND usuario_id = :idusuario ' +
      '  AND votou = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoVotacaoAPIDao.ChapaValida(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdChapa: Integer
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT 1 ' +
      'FROM eleicao_chapa ' +
      'WHERE id = :idchapa ' +
      '  AND empresa_id = :idempresa ' +
      '  AND eleicao_id = :ideleicao ' +
      '  AND ativo = ''S'' ' +
      'LIMIT 1';

    Qry.ParamByName('idchapa').AsInteger := AIdChapa;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    Qry.Open;

    Result := not Qry.IsEmpty;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoVotacaoAPIDao.BuscarOperacao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
): string;
var
  Qry: TUniQuery;
begin
  Result := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COALESCE(operacao,'''') AS operacao ' +
      'FROM eleicao ' +
      'WHERE id = :ideleicao ' +
      '  AND empresa_id = :idempresa ' +
      'LIMIT 1';

    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := UpperCase(Trim(Qry.FieldByName('operacao').AsString));
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.AdicionarQuestoesCedula(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const ASlug: string;
  const ACedula: TJSONObject
);
var
  Qry, QryOpcao: TUniQuery;
  Operacao: string;
  IdEleicao: Integer;
  Questoes, Opcoes: TJSONArray;
  Questao, Opcao: TJSONObject;
begin
  if not Assigned(ACedula) then
    Exit;

  Qry := TUniQuery.Create(nil);
  QryOpcao := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    QryOpcao.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id, COALESCE(operacao,'''') AS operacao ' +
      'FROM eleicao ' +
      'WHERE empresa_id = :idempresa ' +
      '  AND slug = :slug ' +
      'LIMIT 1';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    IdEleicao := Qry.FieldByName('id').AsInteger;
    Operacao := UpperCase(Trim(Qry.FieldByName('operacao').AsString));
    ACedula.AddPair('operacao', Operacao);

    if not SameText(Operacao, 'ASSEMBLEIA') then
      Exit;

    Questoes := TJSONArray.Create;
    ACedula.AddPair('questoes', Questoes);

    Qry.Close;
    Qry.SQL.Text :=
      'SELECT id,id_questao_int,titulo,COALESCE(descricao,'''') AS descricao,' +
      ' ordem,COALESCE(tipo_resposta,'''') AS tipo_resposta,obrigatoria ' +
      'FROM eleicao_questao ' +
      'WHERE empresa_id = :idempresa ' +
      '  AND eleicao_id = :ideleicao ' +
      '  AND ativo = ''S'' ' +
      'ORDER BY ordem,id';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := IdEleicao;
    Qry.Open;

    while not Qry.Eof do
    begin
      Questao := TJSONObject.Create;
      Questao.AddPair('id_questao', TJSONNumber.Create(Qry.FieldByName('id').AsInteger));
      Questao.AddPair('id_questao_int', TJSONNumber.Create(Qry.FieldByName('id_questao_int').AsInteger));
      Questao.AddPair('titulo', Qry.FieldByName('titulo').AsString);
      Questao.AddPair('descricao', Qry.FieldByName('descricao').AsString);
      Questao.AddPair('ordem', TJSONNumber.Create(Qry.FieldByName('ordem').AsInteger));
      Questao.AddPair('tipo_resposta', Qry.FieldByName('tipo_resposta').AsString);
      Questao.AddPair('obrigatoria', Qry.FieldByName('obrigatoria').AsString);

      Opcoes := TJSONArray.Create;
      Questao.AddPair('opcoes', Opcoes);

      QryOpcao.Close;
      QryOpcao.SQL.Text :=
        'SELECT id,id_opcao_int,ordem,descricao ' +
        'FROM eleicao_questao_opcao ' +
        'WHERE empresa_id = :idempresa ' +
        '  AND eleicao_id = :ideleicao ' +
        '  AND questao_id = :idquestao ' +
        '  AND ativo = ''S'' ' +
        'ORDER BY ordem,id';
      QryOpcao.ParamByName('idempresa').AsInteger := AIdEmpresa;
      QryOpcao.ParamByName('ideleicao').AsInteger := IdEleicao;
      QryOpcao.ParamByName('idquestao').AsInteger := Qry.FieldByName('id').AsInteger;
      QryOpcao.Open;

      while not QryOpcao.Eof do
      begin
        Opcao := TJSONObject.Create;
        Opcao.AddPair('id_opcao', TJSONNumber.Create(QryOpcao.FieldByName('id').AsInteger));
        Opcao.AddPair('id_opcao_int', TJSONNumber.Create(QryOpcao.FieldByName('id_opcao_int').AsInteger));
        Opcao.AddPair('ordem', TJSONNumber.Create(QryOpcao.FieldByName('ordem').AsInteger));
        Opcao.AddPair('descricao', QryOpcao.FieldByName('descricao').AsString);
        Opcoes.AddElement(Opcao);
        QryOpcao.Next;
      end;

      Questoes.AddElement(Questao);
      Qry.Next;
    end;
  finally
    QryOpcao.Free;
    Qry.Free;
  end;
end;

class function TEleicaoVotacaoAPIDao.QuantidadeQuestoesObrigatorias(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer
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
      'FROM eleicao_questao ' +
      'WHERE empresa_id = :idempresa ' +
      '  AND eleicao_id = :ideleicao ' +
      '  AND ativo = ''S'' ' +
      '  AND obrigatoria = ''S''';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoVotacaoAPIDao.QuestaoOpcaoValida(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdQuestao: Integer;
  const AIdOpcao: Integer;
  out AObrigatoria: Boolean
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AObrigatoria := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT q.obrigatoria ' +
      'FROM eleicao_questao q ' +
      'INNER JOIN eleicao_questao_opcao o ON o.questao_id = q.id ' +
      ' AND o.eleicao_id = q.eleicao_id ' +
      ' AND o.empresa_id = q.empresa_id ' +
      'WHERE q.id = :idquestao ' +
      '  AND o.id = :idopcao ' +
      '  AND q.empresa_id = :idempresa ' +
      '  AND q.eleicao_id = :ideleicao ' +
      '  AND q.ativo = ''S'' ' +
      '  AND o.ativo = ''S'' ' +
      'LIMIT 1';
    Qry.ParamByName('idquestao').AsInteger := AIdQuestao;
    Qry.ParamByName('idopcao').AsInteger := AIdOpcao;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.Open;

    Result := not Qry.IsEmpty;
    if Result then
      AObrigatoria := SameText(Trim(Qry.FieldByName('obrigatoria').AsString),'S');
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.RegistrarVoto(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdChapa: Integer;
  const ATipoVoto: string;
  const AComprovanteHash: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_voto (' +
      '  empresa_id, ' +
      '  eleicao_id, ' +
      '  eleicao_chapa_id, ' +
      '  tipo_voto, ' +
      '  comprovante_hash ' +
      ') VALUES (' +
      '  :idempresa, ' +
      '  :ideleicao, ' +
      '  :idchapa, ' +
      '  :tipovoto, ' +
      '  :comprovantehash ' +
      ')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;

    if SameText(ATipoVoto, 'CHAPA') then
      Qry.ParamByName('idchapa').AsInteger := AIdChapa
    else
    begin
      Qry.ParamByName('idchapa').DataType := ftLargeint;
      Qry.ParamByName('idchapa').Clear;
    end;

    Qry.ParamByName('tipovoto').AsString :=
      UpperCase(Trim(ATipoVoto));

    if Trim(AComprovanteHash) <> '' then
      Qry.ParamByName('comprovantehash').AsString :=
        AComprovanteHash
    else
    begin
      Qry.ParamByName('comprovantehash').DataType := ftString;
      Qry.ParamByName('comprovantehash').Clear;
    end;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.RegistrarVotoQuestao(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdQuestao: Integer;
  const AIdOpcao: Integer;
  const AComprovanteHash: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_questao_voto (' +
      ' empresa_id,eleicao_id,questao_id,opcao_id,comprovante_hash' +
      ') VALUES (' +
      ' :idempresa,:ideleicao,:idquestao,:idopcao,:comprovante' +
      ')';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idquestao').AsInteger := AIdQuestao;
    Qry.ParamByName('idopcao').AsInteger := AIdOpcao;
    Qry.ParamByName('comprovante').AsString := AComprovanteHash;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoVotacaoAPIDao.RegistrarVotante(
  const AConn: TUniConnection;
  const AIdEmpresa: Integer;
  const AIdEleicao: Integer;
  const AIdUsuario: Integer
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'INSERT INTO eleicao_votante (' +
      '  empresa_id, ' +
      '  eleicao_id, ' +
      '  usuario_id, ' +
      '  votou ' +
      ') VALUES (' +
      '  :idempresa, ' +
      '  :ideleicao, ' +
      '  :idusuario, ' +
      '  ''S'' ' +
      ')';

    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
