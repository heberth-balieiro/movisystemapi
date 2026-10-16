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
  public
    class function SincronizarDeputadosFederais(
      const AIdUsuario: Int64;
      const AUF, AIP, AUserAgent: string
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
  FONTE_DADOS = 'CAMARA_DADOS_ABERTOS';
  CARGO = 'DEPUTADO_FEDERAL';

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
        FONTE_DADOS,
        CARGO,
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
  Result.AddPair('cargo', CARGO);
  if UF.IsEmpty then
    Result.AddPair('uf', TJSONNull.Create)
  else
    Result.AddPair('uf', UF);
  Result.AddPair('processados', TJSONNumber.Create(Processados));
  Result.AddPair('fonte_dados', FONTE_DADOS);
end;

end.
