unit Eleicao.Dao;

interface

uses
  System.SysUtils,
  Uni,
  Eleicao.Model,
  System.Generics.Collections;

type
  TEleicaoRetornoDados = record
    IdEleicaoInt: Integer;
    Situacao: string;
  end;

Type
TEleicaoDao = Class
  private

  public
    // Eleicao
    class function ExisteEleicao(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicao: Integer): Boolean; static;
    class function Inserir(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoModel): Int64; static;
    class function Atualizar(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoModel):Boolean; static;
    class function BuscarStatusIntegracao(const AConn: TUniConnection; const AIdEmpresa: Integer): TArray<TEleicaoRetornoDados>; static;

    // Config
    class function ExisteEleicaoConfig(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicaoConfig: Integer): Boolean; static;
    class function InserirConfig(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoConfigModel): Int64; static;
    class function AtualizarConfig(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoConfigModel):Boolean; static;
    class function RetornoIDeleicaoAPI(const AConn: TUniConnection; const AEmpresaId:Integer; const AIDEleicaoRetaguarda: Integer):integer; static;

    // Chapa
    class function InserirChapa(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoChapaModel): Int64; static;
    class function AtualizarChapa(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoChapaModel):Boolean; static;
    class function ExisteChapa(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicaoChapa: Integer): Boolean; static;

    // Membros
    class function InserirMembros(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoChapaMembrosModel): Int64; static;
    class function AtualizarMembros(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoChapaMembrosModel):Boolean; static;
    class function ExisteMembros(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicaoChapaMembros: Integer): Boolean; static;
    class function RetornoIDChapaAPI(const AConn: TUniConnection; const AEmpresaId:Integer; const AIDChapaRetaguarda: Integer):integer; static;

    //Questao
    class function InserirQuestao(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoQuestaoModel): Int64; static;
    class function AtualizarQuestao(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoQuestaoModel):Boolean; static;
    class function ExisteQuestao(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicaoQuestao: Integer): Boolean; static;
    class function RetornoIDQuestaoAPI(const AConn: TUniConnection; const AEmpresaId:Integer; const AIDQuestaoRetaguarda: Integer):integer; static;

End;


implementation

{ TEleicaoDao }

{$REGION 'Eleicao'}

class function TEleicaoDao.Atualizar(const AConn: TUniConnection;
                const AEmpresaId: Integer; const ADoc: TEleicaoModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =  'Update eleicao set nome= :nome, descricao= :descricao, ano= :ano, '+
            ' ativo= :ativo, ano_fim= :anofim, tipo= :tipo, operacao= :operacao '+
            ' where empresa_id= :empresa_id and id_eleicao_int= :id_eleicao_int';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text   := StrSql;

    Qry.ParamByName('nome').AsString              := ADoc.nome;
    Qry.ParamByName('descricao').AsString         := ADoc.descricao;
    Qry.ParamByName('ano').AsInteger              := ADoc.ano;
    Qry.ParamByName('ativo').AsString             := ADoc.ativo;
    Qry.ParamByName('anofim').AsInteger           := ADoc.ano_fim;
    Qry.ParamByName('tipo').AsString              := ADoc.Tipo;
    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('id_eleicao_int').AsInteger   := ADoc.id_eleicao_int;
    Qry.ParamByName('operacao').asstring          := ADoc.operacao;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.ExisteEleicao(const AConn: TUniConnection;
                  const AIdEmpresa: Int64; const AIDEleicao: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM eleicao WHERE empresa_id= :id AND id_eleicao_int= :id_eleicao LIMIT 1';
begin
  Result    := False;
  Qry       := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.Params.ParamByName('id').AsInteger  := AIdEmpresa;
    Qry.Params.ParamByName('id_eleicao').AsInteger    := AIDEleicao;
    Qry.Open;
    Result        := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.Inserir(const AConn: TUniConnection;
                  const AEmpresaId: Integer; const ADoc: TEleicaoModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'INSERT INTO eleicao (                         ' +
            ' empresa_id, id_eleicao_int, codigo, nome,  ' +
            ' descricao, ano, ativo, ano_fim, tipo, situacao, operacao) '+
            '  VALUES (                                   ' +
            ' :empresa_id, :id_eleicao_int, :codigo, :nome, :descricao, :ano,'+
            ' :ativo, :ano_fim, :tipo, :situacao, :operacao)';

begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('id_eleicao_int').AsInteger   := ADoc.id_eleicao_int;
    Qry.ParamByName('codigo').AsInteger           := ADoc.Codigo;
    Qry.ParamByName('nome').AsString              := ADoc.nome;
    Qry.ParamByName('descricao').AsString         := ADoc.descricao;
    Qry.ParamByName('ano').AsInteger              := ADoc.ano;
    Qry.ParamByName('ativo').AsString             := ADoc.ativo;
    Qry.ParamByName('ano_fim').AsInteger          := ADoc.ano_fim;
    Qry.ParamByName('tipo').AsString              := ADoc.Tipo;
    Qry.ParamByName('situacao').asstring          := ADoc.situacao;
    Qry.ParamByName('operacao').asstring          := ADoc.operacao;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text  := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result        := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

class function TEleicaoDao.BuscarStatusIntegracao(const AConn: TUniConnection; const AIdEmpresa: Integer): TArray<TEleicaoRetornoDados>;
var
  Qry: TUniQuery;
  Item: TEleicaoRetornoDados;
  I: Integer;
begin
  SetLength(Result,0);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT '+
      ' id_eleicao_int, '+
      ' situacao '+
      'FROM eleicao '+
      'WHERE empresa_id= :idempresa '+
      'AND COALESCE(id_eleicao_int,0) > 0 '+
      'AND situacao IN (''ABERTA'',''ENCERRADA'',''EM_APURACAO'',''APURADA'',''PUBLICADA'') '+
      'ORDER BY id';
    Qry.ParamByName('idempresa').AsInteger := AIdEmpresa;
    Qry.Open;
    I := 0;
    while not Qry.Eof do
    begin
      SetLength(Result,I + 1);
      Item.IdEleicaoInt   := Qry.FieldByName('id_eleicao_int').AsInteger;
      Item.Situacao       := Trim(Qry.FieldByName('situacao').AsString);
      Result[I] := Item;
      Inc(I);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Config'}

class function TEleicaoDao.AtualizarConfig(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TEleicaoConfigModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_configuracao SET ' +
    'eleicao_id=:eleicao_id, slug=:slug, nome_exibicao=:nome_exibicao, logo=:logo, banner= :banner, ' +
    'mensagem_boas_vindas=:mensagem_boas_vindas, url_publica=:url_publica, email=:email, telefone=:telefone, ' +
    'cor_primaria=:cor_primaria, cor_secundaria=:cor_secundaria, url_instagram=:url_instagram, ' +
    'url_facebook=:url_facebook, url_youtube=:url_youtube, pagina_publicar=:pagina_publicar, ' +
    'data_hora_inicio=:data_hora_inicio, data_hora_fim=:data_hora_fim, abertura_automatica= :abertura, '+
    'encerramento_automatico= :encerramento,' +
    'votacao_secreta= :votacao_secreta, exibir_resultado_parcial= :exibir_resultado_parcial, '+
    'publicacao_resultado= :publicacao_resultado, controlar_quorum= :controlar_quorum, tipo_quorum= :tipo_quorum,'+
    'quorum_minimo= :quorum_minimo, quorum_percentual= :quorum_percentual,   '+
    'quorum_base= :quorum_base, controlar_presenca= :controlar_presenca, exigir_presenca_votacao= :exigir_presenca_votacao'+
    'WHERE empresa_id=:empresa_id AND id_config=:id_config';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('eleicao_id').AsInteger         := ADoc.EleicaoId;
    Qry.ParamByName('slug').AsString                := ADoc.Slug;
    Qry.ParamByName('nome_exibicao').AsString       := ADoc.NomeExibicao;
    Qry.ParamByName('logo').AsString                := ADoc.Logo;
    Qry.ParamByName('banner').AsString              := ADoc.Banner;
    Qry.ParamByName('mensagem_boas_vindas').AsString := ADoc.MensagemBoasVindas;
    Qry.ParamByName('url_publica').AsString         := ADoc.Url_Publica;
    Qry.ParamByName('email').AsString               := ADoc.Email;
    Qry.ParamByName('telefone').AsString            := ADoc.Telefone;
    Qry.ParamByName('cor_primaria').AsString        := ADoc.CorPrimaria;
    Qry.ParamByName('cor_secundaria').AsString      := ADoc.CorSecundaria;
    Qry.ParamByName('url_instagram').AsString       := ADoc.UrlInstagram;
    Qry.ParamByName('url_facebook').AsString        := ADoc.UrlFacebook;
    Qry.ParamByName('url_youtube').AsString         := ADoc.UrlYoutube;
    Qry.ParamByName('pagina_publicar').AsString     := ADoc.PaginaPublicar;
    Qry.ParamByName('data_hora_inicio').AsDateTime  := ADoc.DataHoraInicio;
    Qry.ParamByName('data_hora_fim').AsDateTime     := ADoc.DataHoraFim;
    Qry.ParamByName('empresa_id').AsInteger         := AEmpresaId;
    Qry.ParamByName('id_config').AsInteger          := ADoc.IdConfig;
    Qry.ParamByName('abertura').AsString            := ADoc.abertura_automatica;
    Qry.ParamByName('encerramento').AsString        := ADoc.encerramento_automatico;

    Qry.ParamByName('votacao_secreta').AsString          := ADoc.votacao_secreta;
    Qry.ParamByName('exibir_resultado_parcial').AsString          := ADoc.exibir_resultado_parcial;
    Qry.ParamByName('publicacao_resultado').AsString          := ADoc.publicacao_resultado;
    Qry.ParamByName('controlar_quorum').AsString          := ADoc.controlar_quorum;
    Qry.ParamByName('tipo_quorum').AsString          := ADoc.tipo_quorum;
    Qry.ParamByName('quorum_minimo').AsInteger          := ADoc.quorum_minimo;
    Qry.ParamByName('quorum_percentual').AsFloat          := ADoc.quorum_percentual;
    Qry.ParamByName('quorum_base').AsString          := ADoc.quorum_base;
    Qry.ParamByName('controlar_presenca').AsString          := ADoc.controlar_presenca;
    Qry.ParamByName('exigir_presenca_votacao').AsString          := ADoc.exigir_presenca_votacao;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.ExisteEleicaoConfig(const AConn: TUniConnection;
            const AIdEmpresa: Int64; const AIDEleicaoConfig: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM eleicao_configuracao WHERE empresa_id= :id AND id_config= :id_config LIMIT 1';
begin
  Result    := False;
  Qry       := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.Params.ParamByName('id').AsInteger            := AIdEmpresa;
    Qry.Params.ParamByName('id_config').AsInteger     := AIDEleicaoConfig;
    Qry.Open;
    Result        := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.InserirConfig(const AConn: TUniConnection; const AEmpresaId: Integer; const ADoc: TEleicaoConfigModel): Int64;
var
  Qry: TUniQuery;
const
  StrSql =
    'INSERT INTO eleicao_configuracao (' +
    'empresa_id, eleicao_id, id_config, slug, nome_exibicao, logo, banner, mensagem_boas_vindas, url_publica, ' +
    'email, telefone, cor_primaria, cor_secundaria, url_instagram, url_facebook, url_youtube, pagina_publicar, ' +
    'data_hora_inicio, data_hora_fim, abertura_automatica, encerramento_automatico,'+
    'votacao_secreta, exibir_resultado_parcial, '+
    'publicacao_resultado, controlar_quorum, tipo_quorum, quorum_minimo, quorum_percentual,   '+
    'quorum_base, controlar_presenca, exigir_presenca_votacao'+
    ') ' +
    'VALUES (' +
    ':empresa_id, :eleicao_id, :id_config, :slug, :nome_exibicao, :logo, :banner, :mensagem_boas_vindas, :url_publica, ' +
    ':email, :telefone, :cor_primaria, :cor_secundaria, :url_instagram, :url_facebook, :url_youtube, :pagina_publicar, ' +
    ':data_hora_inicio, :data_hora_fim, :abertura, :encerramento,'+
    ':votacao_secreta, :exibir_resultado_parcial, '+
    ':publicacao_resultado, :controlar_quorum, :tipo_quorum, :quorum_minimo, :quorum_percentual,   '+
    ':quorum_base, :controlar_presenca, :exigir_presenca_votacao'+
    ')';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('empresa_id').AsInteger           := AEmpresaId;
    Qry.ParamByName('eleicao_id').AsInteger           := ADoc.EleicaoId;
    Qry.ParamByName('id_config').AsInteger            := ADoc.IdConfig;
    Qry.ParamByName('slug').AsString                  := ADoc.Slug;
    Qry.ParamByName('nome_exibicao').AsString         := ADoc.NomeExibicao;
    Qry.ParamByName('logo').AsString                  := ADoc.Logo;
    Qry.ParamByName('banner').AsString                := ADoc.Banner;
    Qry.ParamByName('mensagem_boas_vindas').AsString  := ADoc.MensagemBoasVindas;
    Qry.ParamByName('url_publica').AsString           := ADoc.Url_Publica;
    Qry.ParamByName('email').AsString                 := ADoc.Email;
    Qry.ParamByName('telefone').AsString              := ADoc.Telefone;
    Qry.ParamByName('cor_primaria').AsString          := ADoc.CorPrimaria;
    Qry.ParamByName('cor_secundaria').AsString        := ADoc.CorSecundaria;
    Qry.ParamByName('url_instagram').AsString         := ADoc.UrlInstagram;
    Qry.ParamByName('url_facebook').AsString          := ADoc.UrlFacebook;
    Qry.ParamByName('url_youtube').AsString           := ADoc.UrlYoutube;
    Qry.ParamByName('pagina_publicar').AsString       := ADoc.PaginaPublicar;
    Qry.ParamByName('data_hora_inicio').AsDateTime    := ADoc.DataHoraInicio;
    Qry.ParamByName('data_hora_fim').AsDateTime       := ADoc.DataHoraFim;
    Qry.ParamByName('abertura').AsString              := ADoc.abertura_automatica;
    Qry.ParamByName('encerramento').AsString          := ADoc.encerramento_automatico;

    Qry.ParamByName('votacao_secreta').AsString          := ADoc.votacao_secreta;
    Qry.ParamByName('exibir_resultado_parcial').AsString          := ADoc.exibir_resultado_parcial;
    Qry.ParamByName('publicacao_resultado').AsString          := ADoc.publicacao_resultado;
    Qry.ParamByName('controlar_quorum').AsString          := ADoc.controlar_quorum;
    Qry.ParamByName('tipo_quorum').AsString          := ADoc.tipo_quorum;
    Qry.ParamByName('quorum_minimo').AsInteger          := ADoc.quorum_minimo;
    Qry.ParamByName('quorum_percentual').AsFloat          := ADoc.quorum_percentual;
    Qry.ParamByName('quorum_base').AsString          := ADoc.quorum_base;
    Qry.ParamByName('controlar_presenca').AsString          := ADoc.controlar_presenca;
    Qry.ParamByName('exigir_presenca_votacao').AsString          := ADoc.exigir_presenca_votacao;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Qry.Open;
    Result := Qry.FieldByName('ID').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.RetornoIDeleicaoAPI(const AConn: TUniConnection; const AEmpresaId, AIDEleicaoRetaguarda: Integer): Integer;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT id FROM eleicao WHERE empresa_id=:id AND id_eleicao_int=:id_eleicao_int LIMIT 1';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_eleicao_int').AsInteger := AIDEleicaoRetaguarda;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsInteger;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Chapa'}

class function TEleicaoDao.ExisteChapa(const AConn: TUniConnection;
              const AIdEmpresa: Int64; const AIDEleicaoChapa: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM eleicao_chapa WHERE empresa_id= :id AND id_chapa_int= :id_chapa_int LIMIT 1';
begin
  Result    := False;
  Qry       := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.Params.ParamByName('id').AsInteger            := AIdEmpresa;
    Qry.Params.ParamByName('id_chapa_int').AsInteger  := AIDEleicaoChapa;
    Qry.Open;
    Result        := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.InserirChapa(const AConn: TUniConnection;
              const AEmpresaId: Integer; const ADoc: TEleicaoChapaModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'INSERT INTO eleicao_chapa ('+
            'empresa_id, eleicao_id, id_chapa_int, codigo, situacao, num_chapa, nome_chapa, slogan, obs, ativo) '+
            'VALUES ('+
            ':empresa_id, :eleicao_id, :id_chapa_int, :codigo, :situacao, :num_chapa, :nome_chapa, :slogan, :obs, :ativo)';

begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('empresa_id').AsInteger     := AEmpresaId;
    Qry.ParamByName('eleicao_id').AsInteger     := ADoc.EleicaoId;
    Qry.ParamByName('id_chapa_int').AsInteger   := ADoc.id_chapa_int;
    Qry.ParamByName('codigo').AsInteger         := ADoc.Codigo;
    Qry.ParamByName('situacao').AsString        := ADoc.Situacao;
    Qry.ParamByName('num_chapa').AsInteger      := ADoc.NumChapa;
    Qry.ParamByName('nome_chapa').AsString      := ADoc.NomeChapa;
    Qry.ParamByName('slogan').AsString          := ADoc.Slogan;
    Qry.ParamByName('obs').AsString             := ADoc.Obs;
    Qry.ParamByName('ativo').AsString           := ADoc.Ativo;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text  := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result        := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

class function TEleicaoDao.AtualizarChapa(const AConn: TUniConnection;
  const AEmpresaId: Integer; const ADoc: TEleicaoChapaModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_chapa SET '+
    'eleicao_id=:eleicao_id, '+
    'codigo=:codigo, '+
    'situacao=:situacao, '+
    'num_chapa=:num_chapa, '+
    'nome_chapa=:nome_chapa, '+
    'slogan=:slogan, '+
    'obs=:obs, '+
    'ativo=:ativo '+
    'WHERE empresa_id=:empresa_id AND id_chapa_int=:id_chapa_int';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('eleicao_id').AsInteger := ADoc.EleicaoId;
    Qry.ParamByName('codigo').AsInteger := ADoc.Codigo;
    Qry.ParamByName('situacao').AsString := ADoc.Situacao;
    Qry.ParamByName('num_chapa').AsInteger := ADoc.NumChapa;
    Qry.ParamByName('nome_chapa').AsString := ADoc.NomeChapa;
    Qry.ParamByName('slogan').AsString := ADoc.Slogan;
    Qry.ParamByName('obs').AsString := ADoc.Obs;
    Qry.ParamByName('ativo').AsString := ADoc.Ativo;
    Qry.ParamByName('empresa_id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_chapa_int').AsInteger := ADoc.id_chapa_int;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Membros'}

class function TEleicaoDao.InserirMembros(const AConn: TUniConnection;
        const AEmpresaId: Integer; const ADoc: TEleicaoChapaMembrosModel): Int64;
var
  Qry: TUniQuery;
Const
  StrSql  = 'INSERT INTO eleicao_chapa_membros ('+
              'empresa_id, eleicao_id, eleicao_chapa_id, id_membro_int, codigo, nome, cpf, telefone, email, '+
              'ativo, cargo, tipo, observacao, arquivo_foto, extensao_foto) '+
              'VALUES ('+
              ':empresa_id, :eleicao_id, :eleicao_chapa_id, :id_membro_int, :codigo, :nome, :cpf, :telefone, :email, '+
              ':ativo, :cargo, :tipo, :observacao, :arquivo_foto, :extensao_foto)';

begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;

    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('eleicao_id').AsInteger       := ADoc.EleicaoId;
    Qry.ParamByName('eleicao_chapa_id').AsInteger := ADoc.EleicaoChapaId;
    Qry.ParamByName('id_membro_int').AsInteger    := ADoc.id_membro_int;
    Qry.ParamByName('codigo').AsInteger           := ADoc.Codigo;
    Qry.ParamByName('nome').AsString              := ADoc.Nome;
    Qry.ParamByName('cpf').AsString               := ADoc.Cpf;
    Qry.ParamByName('telefone').AsString          := ADoc.Telefone;
    Qry.ParamByName('email').AsString             := ADoc.Email;
    Qry.ParamByName('ativo').AsString             := ADoc.Ativo;
    Qry.ParamByName('cargo').AsString             := ADoc.Cargo;
    Qry.ParamByName('tipo').AsString              := ADoc.Tipo;
    Qry.ParamByName('observacao').AsString        := ADoc.Observacao;
    Qry.ParamByName('arquivo_foto').AsString      := ADoc.arquivofoto;
    Qry.ParamByName('extensao_foto').AsString     := ADoc.ExtensaoFoto;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text  := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result        := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

class function TEleicaoDao.ExisteMembros(const AConn: TUniConnection;
  const AIdEmpresa: Int64; const AIDEleicaoChapaMembros: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM eleicao_chapa_membros WHERE empresa_id= :id AND id_membro_int= :id_membro_int LIMIT 1';
begin
  Result    := False;
  Qry       := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.Params.ParamByName('id').AsInteger            := AIdEmpresa;
    Qry.Params.ParamByName('id_membro_int').AsInteger := AIDEleicaoChapaMembros;
    Qry.Open;
    Result        := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.AtualizarMembros(const AConn: TUniConnection;
  const AEmpresaId: Integer; const ADoc: TEleicaoChapaMembrosModel): Boolean;
var
  Qry: TUniQuery;
const
  StrSql =
    'UPDATE eleicao_chapa_membros SET '+
    'eleicao_id=:eleicao_id, '+
    'eleicao_chapa_id=:eleicao_chapa_id, '+
    'codigo=:codigo, '+
    'nome=:nome, '+
    'cpf=:cpf, '+
    'telefone=:telefone, '+
    'email=:email, '+
    'ativo=:ativo, '+
    'cargo=:cargo, '+
    'tipo=:tipo, '+
    'observacao=:observacao, '+
    'arquivo_foto=:arquivo_foto, '+
    'extensao_foto=:extensao_foto '+
    'WHERE empresa_id=:empresa_id AND id_membro_int=:id_membro_int';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;

    Qry.ParamByName('eleicao_id').AsInteger       := ADoc.EleicaoId;
    Qry.ParamByName('eleicao_chapa_id').AsInteger := ADoc.EleicaoChapaId;
    Qry.ParamByName('codigo').AsInteger           := ADoc.Codigo;
    Qry.ParamByName('nome').AsString              := ADoc.Nome;
    Qry.ParamByName('cpf').AsString               := ADoc.Cpf;
    Qry.ParamByName('telefone').AsString          := ADoc.Telefone;
    Qry.ParamByName('email').AsString             := ADoc.Email;
    Qry.ParamByName('ativo').AsString             := ADoc.Ativo;
    Qry.ParamByName('cargo').AsString             := ADoc.Cargo;
    Qry.ParamByName('tipo').AsString              := ADoc.Tipo;
    Qry.ParamByName('observacao').AsString        := ADoc.Observacao;
    Qry.ParamByName('arquivo_foto').AsString      := ADoc.arquivofoto;
    Qry.ParamByName('extensao_foto').AsString     := ADoc.ExtensaoFoto;
    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('id_membro_int').AsInteger    := ADoc.id_membro_int;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.RetornoIDChapaAPI(const AConn: TUniConnection;
  const AEmpresaId, AIDChapaRetaguarda: Integer): Integer;
var
  Qry: TUniQuery;
const
  StrSql =
    'SELECT id FROM eleicao_chapa '+
    'WHERE empresa_id=:id AND id_chapa_int=:id_chapa_int LIMIT 1';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_chapa_int').AsInteger := AIDChapaRetaguarda;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsInteger;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Questao'}

class function TEleicaoDao.InserirQuestao(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoQuestaoModel): Int64;
var
  Qry: TUniQuery;
Const
  QryInsert =
    'INSERT INTO eleicao_questao ('+
            ' id_questao_int, eleicao_id, id_eleicao_int, empresa_id, titulo, descricao, '+
            ' ordem, tipo_resposta, obrigatoria, ativo '+
            ') VALUES ('+
            ' :id_questao_int, :eleicao_id, :id_eleicao_int, :empresa_id, :titulo, :descricao, '+
            ' :ordem, :tipo_resposta, :obrigatoria, :ativo '+
            ')';

begin
  Result := 0;

  Qry := TUniQuery.Create(nil);

  Try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := QryInsert;

    Qry.ParamByName('id_questao_int').AsInteger   := ADOC.id_questao_int;
    Qry.ParamByName('eleicao_id').AsInteger       := ADoc.eleicao_id;
    Qry.ParamByName('id_eleicao_int').AsInteger   := ADoc.id_eleicao_int;
    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('titulo').AsString            := ADoc.titulo;
    Qry.ParamByName('descricao').AsString         := ADoc.descricao;
    Qry.ParamByName('ordem').AsInteger            := ADoc.ordem;
    Qry.ParamByName('tipo_resposta').AsString     := ADoc.tipo_resposta;
    Qry.ParamByName('obrigatoria').AsString       := ADoc.obrigatoria;
    Qry.ParamByName('ativo').AsString             := ADoc.Ativo;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text  := ' SELECT LAST_INSERT_ID() AS ID ';
    Qry.Open;

    Result        := Qry.FieldByName('ID').AsLargeInt;
  Finally
    Qry.Free;
  End;
end;

class function TEleicaoDao.AtualizarQuestao(const AConn: TUniConnection; const AEmpresaId:Integer; Const ADoc: TEleicaoQuestaoModel):Boolean;
var
  Qry: TUniQuery;
const
  QryUpdate =
    'UPDATE eleicao_questao SET '+
    ' eleicao_id = :eleicao_id, '+
    ' id_eleicao_int = :id_eleicao_int, '+
    ' empresa_id = :empresa_id, '+
    ' titulo = :titulo, '+
    ' descricao = :descricao, '+
    ' ordem = :ordem, '+
    ' tipo_resposta = :tipo_resposta, '+
    ' obrigatoria = :obrigatoria, '+
    ' ativo = :ativo, '+
    ' data_alteracao = CURRENT_TIMESTAMP '+
    ' WHERE id_questao_int = :id_questao_int '+
    ' AND id_eleicao_int = :id_eleicao_int '+
    ' AND empresa_id = :empresa_id';
begin
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text   := QryUpdate;

    Qry.ParamByName('id_questao_int').AsInteger   := ADOC.id_questao_int;
    Qry.ParamByName('eleicao_id').AsInteger       := ADoc.eleicao_id;
    Qry.ParamByName('id_eleicao_int').AsInteger   := ADoc.id_eleicao_int;
    Qry.ParamByName('empresa_id').AsInteger       := AEmpresaId;
    Qry.ParamByName('titulo').AsString            := ADoc.titulo;
    Qry.ParamByName('descricao').AsString         := ADoc.descricao;
    Qry.ParamByName('ordem').AsInteger            := ADoc.ordem;
    Qry.ParamByName('tipo_resposta').AsString     := ADoc.tipo_resposta;
    Qry.ParamByName('obrigatoria').AsString       := ADoc.obrigatoria;
    Qry.ParamByName('ativo').AsString             := ADoc.Ativo;

    Qry.Execute;
    Result := Qry.RowsAffected > 0;
  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.ExisteQuestao(const AConn: TUniConnection; const AIdEmpresa: Int64; const AIDEleicaoQuestao: Integer): Boolean;
var
  Qry: TUniQuery;
const
  StrSql = 'SELECT 1 FROM eleicao_questao WHERE empresa_id= :id AND id_questao_int= :id_questao_int LIMIT 1';
begin
  Result    := False;
  Qry       := TUniQuery.Create(nil);

  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := StrSql;
    Qry.Params.ParamByName('id').AsInteger              := AIdEmpresa;
    Qry.Params.ParamByName('id_questao_int').AsInteger  := AIDEleicaoQuestao;
    Qry.Open;
    Result        := not Qry.IsEmpty;

  finally
    Qry.Free;
  end;
end;

class function TEleicaoDao.RetornoIDQuestaoAPI(const AConn: TUniConnection; const AEmpresaId:Integer; const AIDQuestaoRetaguarda: Integer):integer;
var
  Qry: TUniQuery;
const
  StrSql =
    'SELECT id FROM eleicao_questao '+
    'WHERE empresa_id=:id AND id_questao_int=:id_questao_int LIMIT 1';
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := StrSql;
    Qry.ParamByName('id').AsInteger := AEmpresaId;
    Qry.ParamByName('id_questao_int').AsInteger := AIDQuestaoRetaguarda;
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id').AsInteger;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

end.
