unit PlataformaParlamentar.Service;

interface

uses
  System.JSON;

type
  TPlataformaParlamentarService = class
  private
    class function BuscarPaginaDeputados(
      const AUF: string;
      const APagina, AItens: Integer
    ): TJSONObject; static;
    class function BuscarSenadores: TJSONObject; static;
  public
    class function SincronizarDeputadosFederais(
      const AIdUsuario: Int64;
      const AUF, AIP, AUserAgent: string
    ): TJSONObject; static;
    class function SincronizarSenadores(
      const AIdUsuario: Int64;
      const AUF, AIP, AUserAgent: string
    ): TJSONObject; static;
    class function ListarParlamentares(
      const ABusca, ACargo, AUF, APartido: string;
      const AUnaleAssociado, AEmExercicio, APagina, APorPagina: Integer
    ): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Net.HttpClient,
  System.Net.URLClient,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaParlamentar.DAO,
  PlataformaContato.DAO;

const
  CAMARA_API = 'https://dadosabertos.camara.leg.br/api/v2';
  SENADO_API = 'https://legis.senado.leg.br/dadosabertos/senador/lista/atual.json';
  FONTE_CAMARA = 'CAMARA_DADOS_ABERTOS';
  FONTE_SENADO = 'SENADO_DADOS_ABERTOS';
  CARGO_DEPUTADO_FEDERAL = 'DEPUTADO_FEDERAL';
  CARGO_SENADOR = 'SENADOR';

function NovaConexao: TUniConnection;
var
  C: TAppApiConfig;
begin
  C := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Result := TDatabaseConnection.NewConnection(C.Database);
end;

function JsonString(const AObj: TJSONObject; const ANome: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  if AObj = nil then
    Exit;
  V := AObj.GetValue(ANome);
  if (V <> nil) and not (V is TJSONNull) then
    Result := V.Value;
end;

function JsonObject(const AObj: TJSONObject; const ANome: string): TJSONObject;
var
  V: TJSONValue;
begin
  Result := nil;
  if AObj = nil then
    Exit;
  V := AObj.GetValue(ANome);
  if V is TJSONObject then
    Result := V as TJSONObject;
end;

function JsonArray(const AObj: TJSONObject; const ANome: string): TJSONArray;
var
  V: TJSONValue;
begin
  Result := nil;
  if AObj = nil then
    Exit;
  V := AObj.GetValue(ANome);
  if V is TJSONArray then
    Result := V as TJSONArray;
end;

class function TPlataformaParlamentarService.BuscarPaginaDeputados(
  const AUF: string;
  const APagina, AItens: Integer
): TJSONObject;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
  URL: string;
  Raw: TJSONValue;
begin
  Result := nil;
  URL := CAMARA_API + '/deputados?pagina=' + APagina.ToString +
    '&itens=' + AItens.ToString + '&ordem=ASC&ordenarPor=nome';

  if not Trim(AUF).IsEmpty then
    URL := URL + '&siglaUf=' + UpperCase(Trim(AUF));

  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 10000;
    Client.ResponseTimeout := 30000;
    Client.UserAgent := 'MoviSystem/1.0';
    Resp := Client.Get(URL);

    if Resp.StatusCode <> 200 then
      TAppErrors.RaiseBadRequest(
        'Falha ao consultar Dados Abertos da Câmara. HTTP ' +
        Resp.StatusCode.ToString + '.'
      );

    Raw := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8));
    if not (Raw is TJSONObject) then
    begin
      Raw.Free;
      TAppErrors.RaiseBadRequest('Resposta inválida da API da Câmara dos Deputados.');
    end;
    Result := Raw as TJSONObject;
  finally
    Client.Free;
  end;
end;

class function TPlataformaParlamentarService.BuscarSenadores: TJSONObject;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
  Raw: TJSONValue;
begin
  Result := nil;
  Client := THTTPClient.Create;
  try
    Client.ConnectionTimeout := 10000;
    Client.ResponseTimeout := 30000;
    Client.UserAgent := 'MoviSystem/1.0';
    Resp := Client.Get(SENADO_API);

    if Resp.StatusCode <> 200 then
      TAppErrors.RaiseBadRequest(
        'Falha ao consultar Dados Abertos do Senado. HTTP ' +
        Resp.StatusCode.ToString + '.'
      );

    Raw := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8));
    if not (Raw is TJSONObject) then
    begin
      Raw.Free;
      TAppErrors.RaiseBadRequest('Resposta inválida da API do Senado Federal.');
    end;
    Result := Raw as TJSONObject;
  finally
    Client.Free;
  end;
end;

class function TPlataformaParlamentarService.ListarParlamentares(
  const ABusca, ACargo, AUF, APartido: string;
  const AUnaleAssociado, AEmExercicio, APagina, APorPagina: Integer
): TJSONObject;
var
  Conn:TUniConnection;
  Cargo:string;
begin
  Cargo:=UpperCase(Trim(ACargo));
  if (not Cargo.IsEmpty) and
     not MatchText(Cargo,['VEREADOR','DEPUTADO_ESTADUAL','DEPUTADO_FEDERAL','SENADOR']) then
    TAppErrors.RaiseBadRequest('Cargo parlamentar inválido.');

  if (not Trim(AUF).IsEmpty) and (Length(Trim(AUF))<>2) then
    TAppErrors.RaiseBadRequest('UF inválida.');

  Conn:=NovaConexao;
  try
    Result:=TPlataformaParlamentarDAO.Listar(
      Conn,ABusca,Cargo,AUF,APartido,
      AUnaleAssociado,AEmExercicio,APagina,APorPagina
    );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaParlamentarService.SincronizarDeputadosFederais(
  const AIdUsuario: Int64;
  const AUF, AIP, AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  Json: TJSONObject;
  Dados: TJSONArray;
  V: TJSONValue;
  D: TJSONObject;
  UF, IdExterno, Nome, Email, Partido, UfDeputado, Foto, Perfil: string;
  Pagina, ItensPorPagina, Processados, I: Integer;
  Continuar: Boolean;
begin
  if AIdUsuario <= 0 then
    TAppErrors.RaiseForbidden('Usuário não identificado.');

  UF := UpperCase(Trim(AUF));
  if (not UF.IsEmpty) and (Length(UF) <> 2) then
    TAppErrors.RaiseBadRequest('UF inválida.');

  Conn := NovaConexao;
  try
    Conn.StartTransaction;
    try
      TPlataformaParlamentarDAO.MarcarForaExercicio(
        Conn,
        FONTE_CAMARA,
        CARGO_DEPUTADO_FEDERAL,
        UF
      );

      Pagina := 1;
      ItensPorPagina := 100;
      Processados := 0;
      Continuar := True;

      while Continuar do
      begin
        Json := BuscarPaginaDeputados(UF, Pagina, ItensPorPagina);
        try
          V := Json.GetValue('dados');
          if not (V is TJSONArray) then
            TAppErrors.RaiseBadRequest(
              'Resposta da Câmara sem a coleção de deputados.'
            );

          Dados := V as TJSONArray;
          if Dados.Count = 0 then
            Break;

          for I := 0 to Dados.Count - 1 do
          begin
            if not (Dados.Items[I] is TJSONObject) then
              Continue;

            D := Dados.Items[I] as TJSONObject;
            IdExterno := JsonString(D, 'id');
            Nome := JsonString(D, 'nome');
            Email := JsonString(D, 'email');
            Partido := JsonString(D, 'siglaPartido');
            UfDeputado := JsonString(D, 'siglaUf');
            Foto := JsonString(D, 'urlFoto');

            if not IdExterno.IsEmpty then
              Perfil := 'https://www.camara.leg.br/deputados/' + IdExterno
            else
              Perfil := '';

            if TPlataformaParlamentarDAO.Upsert(
              Conn,
              AIdUsuario,
              IdExterno,
              Nome,
              Email,
              Partido,
              UfDeputado,
              Perfil,
              Foto
            ) then
              Inc(Processados);
          end;

          Continuar := Dados.Count >= ItensPorPagina;
          Inc(Pagina);
        finally
          Json.Free;
        end;
      end;

      TPlataformaContatoDAO.RegistrarAuditoria(
        Conn,
        AIdUsuario,
        'DEPUTADOS_FEDERAIS_SINCRONIZADOS',
        'plataforma_contato',
        '',
        Format(
          'Sincronização de deputados federais concluída. UF=%s; processados=%d.',
          [IfThen(UF.IsEmpty, 'TODAS', UF), Processados]
        ),
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;

  Result := TJSONObject.Create;
  Result.AddPair('cargo', CARGO_DEPUTADO_FEDERAL);
  if UF.IsEmpty then
    Result.AddPair('uf', TJSONNull.Create)
  else
    Result.AddPair('uf', UF);
  Result.AddPair('processados', TJSONNumber.Create(Processados));
  Result.AddPair('fonte_dados', FONTE_CAMARA);
end;

class function TPlataformaParlamentarService.SincronizarSenadores(
  const AIdUsuario: Int64;
  const AUF, AIP, AUserAgent: string
): TJSONObject;
var
  Conn: TUniConnection;
  Json, Raiz, Parlamentares, Parlamentar, Identificacao: TJSONObject;
  Arr: TJSONArray;
  V: TJSONValue;
  UF, IdExterno, Nome, Email, Partido, UfSenador, Foto, Perfil: string;
  Processados, I: Integer;
begin
  if AIdUsuario <= 0 then
    TAppErrors.RaiseForbidden('Usuário não identificado.');

  UF := UpperCase(Trim(AUF));
  if (not UF.IsEmpty) and (Length(UF) <> 2) then
    TAppErrors.RaiseBadRequest('UF inválida.');

  Json := BuscarSenadores;
  try
    Raiz := JsonObject(Json, 'ListaParlamentarEmExercicio');
    if Raiz = nil then
      TAppErrors.RaiseBadRequest('Resposta do Senado sem ListaParlamentarEmExercicio.');

    Parlamentares := JsonObject(Raiz, 'Parlamentares');
    if Parlamentares = nil then
      TAppErrors.RaiseBadRequest('Resposta do Senado sem Parlamentares.');

    Arr := JsonArray(Parlamentares, 'Parlamentar');
    if Arr = nil then
      TAppErrors.RaiseBadRequest('Resposta do Senado sem a coleção de senadores.');

    Conn := NovaConexao;
    try
      Conn.StartTransaction;
      try
        TPlataformaParlamentarDAO.MarcarForaExercicio(
          Conn,
          FONTE_SENADO,
          CARGO_SENADOR,
          UF
        );

        Processados := 0;
        for I := 0 to Arr.Count - 1 do
        begin
          V := Arr.Items[I];
          if not (V is TJSONObject) then
            Continue;

          Parlamentar := V as TJSONObject;
          Identificacao := JsonObject(Parlamentar, 'IdentificacaoParlamentar');
          if Identificacao = nil then
            Continue;

          IdExterno := JsonString(Identificacao, 'CodigoParlamentar');
          Nome := JsonString(Identificacao, 'NomeParlamentar');
          Email := JsonString(Identificacao, 'EmailParlamentar');
          Partido := JsonString(Identificacao, 'SiglaPartidoParlamentar');
          UfSenador := UpperCase(JsonString(Identificacao, 'UfParlamentar'));
          Foto := JsonString(Identificacao, 'UrlFotoParlamentar');
          Perfil := JsonString(Identificacao, 'UrlPaginaParlamentar');

          if (not UF.IsEmpty) and (not SameText(UF, UfSenador)) then
            Continue;

          if TPlataformaParlamentarDAO.UpsertSenador(
            Conn,
            AIdUsuario,
            IdExterno,
            Nome,
            Email,
            Partido,
            UfSenador,
            Perfil,
            Foto
          ) then
            Inc(Processados);
        end;

        TPlataformaContatoDAO.RegistrarAuditoria(
          Conn,
          AIdUsuario,
          'SENADORES_SINCRONIZADOS',
          'plataforma_contato',
          '',
          Format(
            'Sincronização de senadores concluída. UF=%s; processados=%d.',
            [IfThen(UF.IsEmpty, 'TODAS', UF), Processados]
          ),
          AIP,
          AUserAgent
        );

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        raise;
      end;
    finally
      Conn.Free;
    end;
  finally
    Json.Free;
  end;

  Result := TJSONObject.Create;
  Result.AddPair('cargo', CARGO_SENADOR);
  if UF.IsEmpty then
    Result.AddPair('uf', TJSONNull.Create)
  else
    Result.AddPair('uf', UF);
  Result.AddPair('processados', TJSONNumber.Create(Processados));
  Result.AddPair('fonte_dados', FONTE_SENADO);
end;

end.
