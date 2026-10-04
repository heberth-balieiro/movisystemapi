unit EleicaoAPIPublic;

interface

uses
  System.SysUtils,
  Uni,
  System.Generics.Collections,
  System.JSON,
  EleicaoAdminAPI.Dao;

type
  TEleicaoConfirmacaoContexto = record
    IdEmpresa: Integer;
    IdEleicao: Integer;
    IdUsuario: Integer;
    IdPessoa: Integer;
    Nome: string;
    Whatsapp: string;
  end;

  TEleicaoConfirmacao = record
    Id: Int64;
    IdEmpresa: Integer;
    IdEleicao: Integer;
    IdUsuario: Integer;
    CodigoHash: string;
    Tentativas: Integer;
    QuantidadeEnvios: Integer;
    EnviadoEm: TDateTime;
    ExpiraEm: TDateTime;
    Confirmado: string;
  end;


Type
TEleicaoAPIPublicDao = Class
  private

  public
    class function BuscarEleicaoPorSlug(const AConn: TUniConnection;const ASlug: string): TJSONObject; static;

    class function BuscarContextoConfirmacao(const AConn: TUniConnection;const ASlug: string;const AIdEmpresa: Integer;
                  const AIdUsuario: Integer; out AContexto: TEleicaoConfirmacaoContexto): Boolean; static;

    class function BuscarConfirmacao(const AConn: TUniConnection;const AIdEleicao: Integer; const AIdUsuario: Integer;
                  out AConfirmacao: TEleicaoConfirmacao): Boolean; static;

    class procedure SalvarCodigoConfirmacao(const AConn: TUniConnection;const AIdEmpresa: Integer;const AIdEleicao: Integer;
                  const AIdUsuario: Integer; const ACodigoHash: string); static;

    class procedure RegistrarEnvioCodigo(const AConn: TUniConnection; const AIdEleicao: Integer; const AIdUsuario: Integer); static;

    class procedure IncrementarTentativa(const AConn: TUniConnection;const AIdConfirmacao: Int64); static;

    class procedure ConfirmarCodigo(const AConn: TUniConnection;const AIdConfirmacao: Int64); static;

    class function BuscarCedulaVotacao(const AConn: TUniConnection;const ASlug: string;const AIdEmpresa: Integer): TJSONObject; static;


End;

implementation

{ TEleicaoAPIPublicDao }

// recupera código/status/tentativas
class function TEleicaoAPIPublicDao.BuscarConfirmacao(const AConn: TUniConnection; const AIdEleicao, AIdUsuario: Integer;
  out AConfirmacao: TEleicaoConfirmacao): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'SELECT ' +
    '  id, empresa_id, eleicao_id, usuario_id, codigo_hash, ' +
    '  tentativas, quantidade_envios, enviado_em, expira_em, confirmado ' +
    ' FROM eleicao_confirmacao ' +
    ' WHERE eleicao_id = :ideleicao ' +
    ' AND usuario_id = :idusuario ' +
    ' LIMIT 1';
begin
  Result := False;

  AConfirmacao.Id           := 0;
  AConfirmacao.IdEmpresa    := 0;
  AConfirmacao.IdEleicao    := 0;
  AConfirmacao.IdUsuario    := 0;
  AConfirmacao.CodigoHash   := '';
  AConfirmacao.Tentativas   := 0;
  AConfirmacao.QuantidadeEnvios := 0;
  AConfirmacao.EnviadoEm    := 0;
  AConfirmacao.ExpiraEm     := 0;
  AConfirmacao.Confirmado   := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;
    AConfirmacao.Id :=
      Qry.FieldByName('id').AsLargeInt;
    AConfirmacao.IdEmpresa :=
      Qry.FieldByName('empresa_id').AsInteger;
    AConfirmacao.IdEleicao :=
      Qry.FieldByName('eleicao_id').AsInteger;
    AConfirmacao.IdUsuario :=
      Qry.FieldByName('usuario_id').AsInteger;

    AConfirmacao.CodigoHash :=
      Qry.FieldByName('codigo_hash').AsString;
    AConfirmacao.Tentativas :=
      Qry.FieldByName('tentativas').AsInteger;
    AConfirmacao.QuantidadeEnvios :=
      Qry.FieldByName('quantidade_envios').AsInteger;
    if not Qry.FieldByName('enviado_em').IsNull then
      AConfirmacao.EnviadoEm :=
        Qry.FieldByName('enviado_em').AsDateTime;
    if not Qry.FieldByName('expira_em').IsNull then
      AConfirmacao.ExpiraEm :=
        Qry.FieldByName('expira_em').AsDateTime;
    AConfirmacao.Confirmado :=
        Qry.FieldByName('confirmado').AsString;

    Result := True;
  finally
    Qry.Free;
  end;

end;

// identifica eleição + usuário + WhatsApp
class function TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
  const AConn: TUniConnection; const ASlug: string; const AIdEmpresa,
  AIdUsuario: Integer; out AContexto: TEleicaoConfirmacaoContexto): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'SELECT ' +
    '  ec.empresa_id, ' +
    '  ec.eleicao_id, ' +
    '  u.id AS id_usuario, ' +
    '  p.id AS id_pessoa, ' +
    '  p.nome, ' +
    '  COALESCE(p.whatsapp, '''') AS whatsapp ' +
    'FROM eleicao_configuracao ec ' +
    'INNER JOIN eleicao e ON ' +
    '  e.id = ec.eleicao_id ' +
    '  AND e.empresa_id = ec.empresa_id ' +
    'INNER JOIN usuario u ON ' +
    '  u.id = :idusuario ' +
    '  AND u.empresa_id = ec.empresa_id ' +
    '  AND u.ativo = ''S'' ' +
    'INNER JOIN pessoa p ON ' +
    '  p.id = u.pessoa_id ' +
    '  AND p.empresa_id = ec.empresa_id ' +
    '  AND p.ativo = ''S'' ' +
    '  AND p.excluido = 0 ' +
    '  AND p.bloqueado = ''N'' ' +
    'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
    '  AND ec.empresa_id = :idempresa ' +
    '  AND ec.pagina_publicar = ''S'' ' +
    '  AND e.ativo = ''S'' ' +
    '  AND e.situacao = ''ABERTA'' ' +
    'LIMIT 1';
begin
  Result := False;

  AContexto.IdEmpresa := 0;
  AContexto.IdEleicao := 0;
  AContexto.IdUsuario := 0;
  AContexto.IdPessoa  := 0;
  AContexto.Nome      := '';
  AContexto.Whatsapp  := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('slug').AsString := Trim(ASlug);
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;
    Qry.Open;
    if Qry.IsEmpty then
      Exit;
    AContexto.IdEmpresa :=
      Qry.FieldByName('empresa_id').AsInteger;
    AContexto.IdEleicao :=
      Qry.FieldByName('eleicao_id').AsInteger;

    AContexto.IdUsuario :=
      Qry.FieldByName('id_usuario').AsInteger;
    AContexto.IdPessoa :=
      Qry.FieldByName('id_pessoa').AsInteger;
    AContexto.Nome :=
      Qry.FieldByName('nome').AsString;
    AContexto.Whatsapp :=
      Qry.FieldByName('whatsapp').AsString;
    Result := True;
  finally
    Qry.Free;
  end;

end;

// Pagina bublica
class function TEleicaoAPIPublicDao.BuscarEleicaoPorSlug(const AConn: TUniConnection;
                                              const ASlug: string): TJSONObject;
var
  Qry         : TUniQuery;
  QryEleicao  : TUniQuery;

  AIdEleicao  : Integer;

  ConfiguracaoJson  : TJSONObject;
  EleicoJson        : TJSONObject;

const
  StrSqlA = 'Select                                                          '+
             ' eleicao_id, slug, nome_exibicao, mensagem_boas_vindas, email, telefone,   '+
             ' cor_primaria, cor_secundaria, url_instagram, url_facebook,    '+
             ' url_youtube, pagina_publicar, logo, banner, data_hora_inicio, data_hora_fim, empresa_id  '+
             ' from eleicao_configuracao where LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) limit 1';

  StrSqlB = 'Select                                                          '+
            ' id, codigo, nome, descricao, ano, ano_fim, tipo, situacao      '+
            ' from eleicao where id= :id limit 1';
begin
  Result      := nil;
  EleicoJson  := nil;
  ConfiguracaoJson := nil;
  Qry         := TUniQuery.Create(nil);
  QryEleicao  := TUniQuery.Create(nil);


  Try
    Qry.Connection          := AConn;
    QryEleicao.Connection   := AConn;

    //Carregar a config
    Qry.SQL.Text                              := StrSqlA;
    Qry.ParamByName('slug').AsString          := Trim(ASlug);
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    if UpperCase(Trim(Qry.FieldByName('pagina_publicar').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(Qry.FieldByName('slug').AsString)) = '' then
      Exit(nil);

    AIdEleicao    := Qry.FieldByName('eleicao_id').AsInteger;

    //Criar Json
    ConfiguracaoJson := TJSONObject.Create;
    ConfiguracaoJson.AddPair('slug',                  Qry.FieldByName('slug').AsString);
    ConfiguracaoJson.AddPair('nome_exibicao',         Qry.FieldByName('nome_exibicao').AsString);
    ConfiguracaoJson.AddPair('mensagem_boas_vindas',  Qry.FieldByName('mensagem_boas_vindas').AsString);
    ConfiguracaoJson.AddPair('email',                 Qry.FieldByName('email').AsString);
    ConfiguracaoJson.AddPair('telefone',              Qry.FieldByName('telefone').AsString);
    ConfiguracaoJson.AddPair('cor_primaria',          Qry.FieldByName('cor_primaria').AsString);
    ConfiguracaoJson.AddPair('cor_secundaria',        Qry.FieldByName('cor_secundaria').AsString);
    ConfiguracaoJson.AddPair('url_instagram',         Qry.FieldByName('url_instagram').AsString);
    ConfiguracaoJson.AddPair('url_facebook',          Qry.FieldByName('url_facebook').AsString);
    ConfiguracaoJson.AddPair('url_youtube',           Qry.FieldByName('url_youtube').AsString);
    ConfiguracaoJson.AddPair('pagina_publicar',       Qry.FieldByName('pagina_publicar').AsString);
    ConfiguracaoJson.AddPair('logo',                  Qry.FieldByName('logo').AsString);
    ConfiguracaoJson.AddPair('banner',                Qry.FieldByName('banner').AsString);
    ConfiguracaoJson.AddPair('data_hora_inicio',      FormatDateTime('dd/mm/yyyy hh:nn',Qry.FieldByName('data_hora_inicio').AsDateTime));
    ConfiguracaoJson.AddPair('data_hora_fim',         FormatDateTime('dd/mm/yyyy hh:nn',Qry.FieldByName('data_hora_fim').AsDateTime));

    //Validar abertura
    TEleicaoAdminAPIDao.AbrirAutomaticamente(AConn, Qry.FieldByName('empresa_id').AsInteger, AIdEleicao);
    TEleicaoAdminAPIDao.EncerrarAutomaticamente(AConn, Qry.FieldByName('empresa_id').AsInteger, AIdEleicao);

    //Carregar Eleicao
    QryEleicao.SQL.Text                               := StrSqlB;
    QryEleicao.ParamByName('id').AsInteger            := AIdEleicao;
    QryEleicao.Open;

    if QryEleicao.IsEmpty then
    begin
      ConfiguracaoJson.Free;
      Exit(nil);
    end;

    if not QryEleicao.IsEmpty then
    begin
      EleicoJson        := TJSONObject.Create;

      EleicoJson.AddPair('id',                TJSONNumber.Create(QryEleicao.FieldByName('id').AsInteger));
      EleicoJson.AddPair('codigo',            TJSONNumber.Create(QryEleicao.FieldByName('codigo').AsInteger));
      EleicoJson.AddPair('nome',              QryEleicao.FieldByName('nome').AsString);
      EleicoJson.AddPair('descricao',         QryEleicao.FieldByName('descricao').AsString);
      EleicoJson.AddPair('ano',               QryEleicao.FieldByName('ano').AsInteger);
      EleicoJson.AddPair('tipo',              QryEleicao.FieldByName('tipo').AsString);
      EleicoJson.AddPair('situacao',          QryEleicao.FieldByName('situacao').AsString);
//      EleicoJson.AddPair('data_hora_inicio',  FormatDateTime('dd/mm/yyyy', Now));
//      EleicoJson.AddPair('data_hora_fim',     FormatDateTime('dd/mm/yyyy', Now));
    end;

    //Retorno

    Result      := TJSONObject.Create;
    Result.AddPair('entidade', ConfiguracaoJson);
    Result.AddPair('eleicao', EleicoJson);

  Finally
    Qry.Free;
    Qryeleicao.Free;
  End;

end;

//código validado
class procedure TEleicaoAPIPublicDao.ConfirmarCodigo(
                      const AConn: TUniConnection; const AIdConfirmacao: Int64);
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_confirmacao SET ' +
    ' confirmado = ''S'', ' +
    ' confirmado_em = NOW() ' +
    'WHERE id = :id';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('id').AsLargeInt := AIdConfirmacao;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

//código informado incorretamente
class procedure TEleicaoAPIPublicDao.IncrementarTentativa(
            const AConn: TUniConnection; const AIdConfirmacao: Int64);
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_confirmacao SET ' +
    ' tentativas = tentativas + 1 ' +
    'WHERE id = :id';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.ParamByName('id').AsLargeInt := AIdConfirmacao;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

//WhatsApp foi enviado
class procedure TEleicaoAPIPublicDao.RegistrarEnvioCodigo(
  const AConn: TUniConnection; const AIdEleicao, AIdUsuario: Integer);
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_confirmacao SET ' +
    ' enviado_em = NOW(), ' +
    ' expira_em = DATE_ADD(NOW(), INTERVAL 5 MINUTE), ' +
    ' quantidade_envios = quantidade_envios + 1 ' +
    'WHERE eleicao_id = :ideleicao ' +
    '  AND usuario_id = :idusuario';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

//grava hash do novo código
class procedure TEleicaoAPIPublicDao.SalvarCodigoConfirmacao(
  const AConn: TUniConnection; const AIdEmpresa, AIdEleicao,
  AIdUsuario: Integer; const ACodigoHash: string);
var
  Qry: TUniQuery;
const
  StrSql =
    'INSERT INTO eleicao_confirmacao ( ' +
    ' empresa_id, eleicao_id, usuario_id, codigo_hash, ' +
    ' tentativas, quantidade_envios, enviado_em, expira_em, confirmado ' +
    ') VALUES ( ' +
    ' :idempresa, :ideleicao, :idusuario, :codigohash, ' +
    ' 0, 0, NULL, DATE_ADD(NOW(), INTERVAL 5 MINUTE), ''N'' ' +
    ') ' +
    'ON DUPLICATE KEY UPDATE ' +
    ' codigo_hash = VALUES(codigo_hash), ' +
    ' tentativas = 0, ' +
    ' enviado_em = NULL, ' +
    ' expira_em = DATE_ADD(NOW(), INTERVAL 5 MINUTE), ' +
    ' confirmado = ''N'', ' +
    ' confirmado_em = NULL';
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.ParamByName('ideleicao').AsInteger := AIdEleicao;
    Qry.ParamByName('idusuario').AsInteger := AIdUsuario;
    Qry.ParamByName('codigohash').AsString := ACodigoHash;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

// Buscar cedula para votacao
class function TEleicaoAPIPublicDao.BuscarCedulaVotacao(
  const AConn: TUniConnection;
  const ASlug: string;
  const AIdEmpresa: Integer
): TJSONObject;
var
  QryEleicao : TUniQuery;
  QryChapa   : TUniQuery;
  QryMembro  : TUniQuery;

  IdEleicao  : Integer;

  EleicaoJson : TJSONObject;
  ChapaJson   : TJSONObject;
  MembroJson  : TJSONObject;

  ChapasArray : TJSONArray;
  MembrosArray: TJSONArray;

const
  SQL_ELEICAO =
    'SELECT ' +
    '  e.id, ' +
    '  e.codigo, ' +
    '  e.nome, ' +
    '  e.descricao, ' +
    '  e.ano, ' +
    '  e.tipo, ' +
    '  e.situacao ' +
    'FROM eleicao_configuracao ec ' +
    'INNER JOIN eleicao e ON ' +
    '  e.id = ec.eleicao_id ' +
    '  AND e.empresa_id = ec.empresa_id ' +
    'WHERE LOWER(TRIM(ec.slug)) = LOWER(TRIM(:slug)) ' +
    '  AND ec.empresa_id = :idempresa ' +
    '  AND ec.pagina_publicar = ''S'' ' +
    '  AND e.ativo = ''S'' ' +
    '  AND e.situacao = ''ABERTA'' ' +
    'LIMIT 1';

  SQL_CHAPAS =
    'SELECT ' +
    '  id, ' +
    '  codigo, ' +
    '  num_chapa, ' +
    '  nome_chapa, ' +
    '  slogan, ' +
    '  obs, ' +
    '  situacao ' +
    'FROM eleicao_chapa ' +
    'WHERE empresa_id = :idempresa ' +
    '  AND eleicao_id = :ideleicao ' +
    '  AND ativo = ''S'' ' +
    'ORDER BY num_chapa';

  SQL_MEMBROS =
    'SELECT ' +
    '  id, ' +
    '  codigo, ' +
    '  nome, ' +
    '  cargo, ' +
    '  tipo, ' +
    '  observacao, ' +
    '  CASE ' +
    '    WHEN arquivo_foto IS NULL THEN ''N'' ' +
    '    ELSE ''S'' ' +
    '  END AS tem_foto ' +
    'FROM eleicao_chapa_membros ' +
    'WHERE empresa_id = :idempresa ' +
    '  AND eleicao_id = :ideleicao ' +
    '  AND eleicao_chapa_id = :idchapa ' +
    '  AND ativo = ''S'' ' +
    'ORDER BY id';
begin
  Result := nil;

  QryEleicao := TUniQuery.Create(nil);
  QryChapa   := TUniQuery.Create(nil);
  QryMembro  := TUniQuery.Create(nil);

  try
    QryEleicao.Connection := AConn;
    QryChapa.Connection   := AConn;
    QryMembro.Connection  := AConn;

    //
    // 1. Identifica a eleição pelo slug
    //
    QryEleicao.SQL.Text := SQL_ELEICAO;
    QryEleicao.ParamByName('slug').AsString := Trim(ASlug);
    QryEleicao.ParamByName('idempresa').AsInteger := AIdEmpresa;
    QryEleicao.Open;

    if QryEleicao.IsEmpty then
      Exit(nil);

    IdEleicao :=
      QryEleicao.FieldByName('id').AsInteger;

    //
    // 2. Dados básicos da eleição
    //
    EleicaoJson := TJSONObject.Create;

    EleicaoJson.AddPair(
      'id',
      TJSONNumber.Create(IdEleicao)
    );

    EleicaoJson.AddPair(
      'codigo',
      TJSONNumber.Create(
        QryEleicao.FieldByName('codigo').AsInteger
      )
    );

    EleicaoJson.AddPair(
      'nome',
      QryEleicao.FieldByName('nome').AsString
    );

    EleicaoJson.AddPair(
      'descricao',
      QryEleicao.FieldByName('descricao').AsString
    );

    EleicaoJson.AddPair(
      'ano',
      TJSONNumber.Create(
        QryEleicao.FieldByName('ano').AsInteger
      )
    );

    EleicaoJson.AddPair(
      'tipo',
      QryEleicao.FieldByName('tipo').AsString
    );

    EleicaoJson.AddPair(
      'situacao',
      QryEleicao.FieldByName('situacao').AsString
    );

    //
    // 3. Carregar chapas
    //
    ChapasArray := TJSONArray.Create;

    QryChapa.SQL.Text := SQL_CHAPAS;
    QryChapa.ParamByName('idempresa').AsInteger := AIdEmpresa;
    QryChapa.ParamByName('ideleicao').AsInteger := IdEleicao;
    QryChapa.Open;

    while not QryChapa.Eof do
    begin
      ChapaJson := TJSONObject.Create;

      ChapaJson.AddPair(
        'id',
        TJSONNumber.Create(
          QryChapa.FieldByName('id').AsInteger
        )
      );

      ChapaJson.AddPair(
        'codigo',
        TJSONNumber.Create(
          QryChapa.FieldByName('codigo').AsInteger
        )
      );

      ChapaJson.AddPair(
        'numero',
        TJSONNumber.Create(
          QryChapa.FieldByName('num_chapa').AsInteger
        )
      );

      ChapaJson.AddPair(
        'nome',
        QryChapa.FieldByName('nome_chapa').AsString
      );

      ChapaJson.AddPair(
        'slogan',
        QryChapa.FieldByName('slogan').AsString
      );

      ChapaJson.AddPair(
        'observacao',
        QryChapa.FieldByName('obs').AsString
      );

      ChapaJson.AddPair(
        'situacao',
        QryChapa.FieldByName('situacao').AsString
      );

      //
      // 4. Membros da chapa
      //
      MembrosArray := TJSONArray.Create;

      QryMembro.Close;
      QryMembro.SQL.Text := SQL_MEMBROS;

      QryMembro.ParamByName('idempresa').AsInteger :=
        AIdEmpresa;

      QryMembro.ParamByName('ideleicao').AsInteger :=
        IdEleicao;

      QryMembro.ParamByName('idchapa').AsInteger :=
        QryChapa.FieldByName('id').AsInteger;

      QryMembro.Open;

      while not QryMembro.Eof do
      begin
        MembroJson := TJSONObject.Create;

        MembroJson.AddPair(
          'id',
          TJSONNumber.Create(
            QryMembro.FieldByName('id').AsInteger
          )
        );

        MembroJson.AddPair(
          'codigo',
          TJSONNumber.Create(
            QryMembro.FieldByName('codigo').AsInteger
          )
        );

        MembroJson.AddPair(
          'nome',
          QryMembro.FieldByName('nome').AsString
        );

        MembroJson.AddPair(
          'cargo',
          QryMembro.FieldByName('cargo').AsString
        );

        MembroJson.AddPair(
          'tipo',
          QryMembro.FieldByName('tipo').AsString
        );

        MembroJson.AddPair(
          'observacao',
          QryMembro.FieldByName('observacao').AsString
        );

        MembroJson.AddPair(
          'tem_foto',
          QryMembro.FieldByName('tem_foto').AsString
        );
        //add
        if SameText(QryMembro.FieldByName('tem_foto').AsString, 'S') then
          MembroJson.AddPair(
            'foto_url',
            Format(
              '/api/v1/public/eleicao/%s/membro/%d/foto',
              [
                Trim(ASlug),
                QryMembro.FieldByName('id').AsInteger
              ]
            )
          )
        else
          MembroJson.AddPair(
            'foto_url',
            TJSONNull.Create
          );

        MembrosArray.AddElement(MembroJson);

        QryMembro.Next;
      end;

      ChapaJson.AddPair(
        'membros',
        MembrosArray
      );

      ChapasArray.AddElement(
        ChapaJson
      );

      QryChapa.Next;
    end;

    //
    // 5. Montar retorno
    //
    Result := TJSONObject.Create;

    Result.AddPair(
      'eleicao',
      EleicaoJson
    );

    Result.AddPair(
      'chapas',
      ChapasArray
    );

  finally
    QryEleicao.Free;
    QryChapa.Free;
    QryMembro.Free;
  end;
end;


end.
