unit EleicaoPublicMedia.Service;

interface

uses
  System.JSON;

type
  TEleicaoPublicMediaService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;
  public
    class function BuscarEleicaoLeve(const ASlug: string): TJSONObject; static;
    class function BuscarMidia(const ASlug, ATipo: string; out ABytes: TBytes; out AMimeType: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.NetEncoding,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  EleicaoAdminAPI.Dao;

class function TEleicaoPublicMediaService.NormalizarSlug(const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));
  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  if S.StartsWith('-') then
    Delete(S, 1, 1);

  if S.EndsWith('-') then
    Delete(S, Length(S), 1);

  Result := S;
end;

class function TEleicaoPublicMediaService.BuscarEleicaoLeve(const ASlug: string): TJSONObject;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  QryEleicao: TUniQuery;
  Slug: string;
  IdEleicao: Integer;
  ConfiguracaoJson: TJSONObject;
  EleicaoJson: TJSONObject;
const
  SQL_CONFIG =
    'SELECT eleicao_id, slug, nome_exibicao, mensagem_boas_vindas, email, telefone, ' +
    'cor_primaria, cor_secundaria, url_instagram, url_facebook, url_youtube, ' +
    'pagina_publicar, data_hora_inicio, data_hora_fim, empresa_id ' +
    'FROM eleicao_configuracao ' +
    'WHERE LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) LIMIT 1';
  SQL_ELEICAO =
    'SELECT id, codigo, nome, descricao, ano, ano_fim, tipo, situacao ' +
    'FROM eleicao WHERE id = :id LIMIT 1';
begin
  Result := nil;
  Slug := NormalizarSlug(ASlug);

  if Slug.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  Qry := TUniQuery.Create(nil);
  QryEleicao := TUniQuery.Create(nil);
  ConfiguracaoJson := nil;
  EleicaoJson := nil;
  try
    Qry.Connection := Conn;
    Qry.SQL.Text := SQL_CONFIG;
    Qry.ParamByName('slug').AsString := Slug;
    Qry.Open;

    if Qry.IsEmpty then
      TAppErrors.RaiseNotFound('Empresa não encontrada ou indisponível.');

    if not SameText(Trim(Qry.FieldByName('pagina_publicar').AsString), 'S') then
      TAppErrors.RaiseNotFound('Empresa não encontrada ou indisponível.');

    IdEleicao := Qry.FieldByName('eleicao_id').AsInteger;

    TEleicaoAdminAPIDao.AbrirAutomaticamente(
      Conn,
      Qry.FieldByName('empresa_id').AsInteger,
      IdEleicao
    );
    TEleicaoAdminAPIDao.EncerrarAutomaticamente(
      Conn,
      Qry.FieldByName('empresa_id').AsInteger,
      IdEleicao
    );

    QryEleicao.Connection := Conn;
    QryEleicao.SQL.Text := SQL_ELEICAO;
    QryEleicao.ParamByName('id').AsInteger := IdEleicao;
    QryEleicao.Open;

    if QryEleicao.IsEmpty then
      TAppErrors.RaiseNotFound('Eleição não encontrada ou indisponível.');

    ConfiguracaoJson := TJSONObject.Create;
    ConfiguracaoJson.AddPair('slug', Qry.FieldByName('slug').AsString);
    ConfiguracaoJson.AddPair('nome_exibicao', Qry.FieldByName('nome_exibicao').AsString);
    ConfiguracaoJson.AddPair('mensagem_boas_vindas', Qry.FieldByName('mensagem_boas_vindas').AsString);
    ConfiguracaoJson.AddPair('email', Qry.FieldByName('email').AsString);
    ConfiguracaoJson.AddPair('telefone', Qry.FieldByName('telefone').AsString);
    ConfiguracaoJson.AddPair('cor_primaria', Qry.FieldByName('cor_primaria').AsString);
    ConfiguracaoJson.AddPair('cor_secundaria', Qry.FieldByName('cor_secundaria').AsString);
    ConfiguracaoJson.AddPair('url_instagram', Qry.FieldByName('url_instagram').AsString);
    ConfiguracaoJson.AddPair('url_facebook', Qry.FieldByName('url_facebook').AsString);
    ConfiguracaoJson.AddPair('url_youtube', Qry.FieldByName('url_youtube').AsString);
    ConfiguracaoJson.AddPair('pagina_publicar', Qry.FieldByName('pagina_publicar').AsString);
    ConfiguracaoJson.AddPair(
      'logo',
      '/api/v1/public/eleicao/' + Slug + '/midia/logo'
    );
    ConfiguracaoJson.AddPair(
      'banner',
      '/api/v1/public/eleicao/' + Slug + '/midia/banner'
    );
    ConfiguracaoJson.AddPair(
      'data_hora_inicio',
      FormatDateTime('dd/mm/yyyy hh:nn', Qry.FieldByName('data_hora_inicio').AsDateTime)
    );
    ConfiguracaoJson.AddPair(
      'data_hora_fim',
      FormatDateTime('dd/mm/yyyy hh:nn', Qry.FieldByName('data_hora_fim').AsDateTime)
    );

    EleicaoJson := TJSONObject.Create;
    EleicaoJson.AddPair('id', TJSONNumber.Create(QryEleicao.FieldByName('id').AsInteger));
    EleicaoJson.AddPair('codigo', TJSONNumber.Create(QryEleicao.FieldByName('codigo').AsInteger));
    EleicaoJson.AddPair('nome', QryEleicao.FieldByName('nome').AsString);
    EleicaoJson.AddPair('descricao', QryEleicao.FieldByName('descricao').AsString);
    EleicaoJson.AddPair('ano', TJSONNumber.Create(QryEleicao.FieldByName('ano').AsInteger));
    EleicaoJson.AddPair('tipo', QryEleicao.FieldByName('tipo').AsString);
    EleicaoJson.AddPair('situacao', QryEleicao.FieldByName('situacao').AsString);

    Result := TJSONObject.Create;
    Result.AddPair('entidade', ConfiguracaoJson);
    Result.AddPair('eleicao', EleicaoJson);
    ConfiguracaoJson := nil;
    EleicaoJson := nil;
  finally
    ConfiguracaoJson.Free;
    EleicaoJson.Free;
    QryEleicao.Free;
    Qry.Free;
    Conn.Free;
  end;
end;

class function TEleicaoPublicMediaService.BuscarMidia(
  const ASlug,
        ATipo: string;
  out ABytes: TBytes;
  out AMimeType: string
): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  Slug: string;
  Tipo: string;
  Campo: string;
  Valor: string;
  PosBase64: Integer;
  Cabecalho: string;
  ConteudoBase64: string;
begin
  Result := False;
  ABytes := nil;
  AMimeType := 'image/png';

  Slug := NormalizarSlug(ASlug);
  Tipo := LowerCase(Trim(ATipo));

  if Slug.IsEmpty then
    Exit;

  if Tipo = 'logo' then
    Campo := 'logo'
  else if Tipo = 'banner' then
    Campo := 'banner'
  else
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conn;
    Qry.SQL.Text :=
      'SELECT ' + Campo + ' AS midia ' +
      'FROM eleicao_configuracao ' +
      'WHERE LOWER(TRIM(slug)) = LOWER(TRIM(:slug)) ' +
      'AND pagina_publicar = ''S'' LIMIT 1';
    Qry.ParamByName('slug').AsString := Slug;
    Qry.Open;

    if Qry.IsEmpty or Qry.FieldByName('midia').IsNull then
      Exit;

    Valor := Trim(Qry.FieldByName('midia').AsString);
    if Valor.IsEmpty then
      Exit;

    ConteudoBase64 := Valor;
    if Valor.StartsWith('data:', True) then
    begin
      PosBase64 := Pos(';base64,', LowerCase(Valor));
      if PosBase64 <= 0 then
        Exit;

      Cabecalho := Copy(Valor, 6, PosBase64 - 6);
      if not Trim(Cabecalho).IsEmpty then
        AMimeType := Trim(Cabecalho);

      ConteudoBase64 := Copy(
        Valor,
        PosBase64 + Length(';base64,'),
        MaxInt
      );
    end;

    ConteudoBase64 := StringReplace(ConteudoBase64, #13, '', [rfReplaceAll]);
    ConteudoBase64 := StringReplace(ConteudoBase64, #10, '', [rfReplaceAll]);

    try
      ABytes := TNetEncoding.Base64.DecodeStringToBytes(ConteudoBase64);
    except
      ABytes := nil;
      Exit;
    end;

    Result := Length(ABytes) > 0;
  finally
    Qry.Free;
    Conn.Free;
  end;
end;

end.
