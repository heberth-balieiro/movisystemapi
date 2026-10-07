unit EasyOneIntegracao.Service;

interface

uses
  System.JSON;

type
  TEasyOneIntegracaoContexto = record
    IdEmpresaAPI: Integer;  // empresa.id
    IdEmpresa   : Integer;  // empresa.id_empresa do EasyOne
    UUID        : string;
  end;

  TEasyOneIntegracaoService = class
  private
    class function GerarHash(const AValor: string): string; static;
    class function HashIgual(const AHash1, AHash2: string): Boolean; static;
  public
    class function Autenticar(const AUUID, AAPIKey: string): TEasyOneIntegracaoContexto; static;
    class procedure ValidarBootstrap(const AUsuario, ASenha: string); static;
    class function ListarAtualizacoesCadastraisPendentes(const AIdEmpresaAPI: Integer): TJSONArray; static;
  end;

implementation

uses
  System.SysUtils,
  System.Hash,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  EasyOneIntegracao.Dao,
  System.IniFiles;

{ TEasyOneIntegracaoService }

class function TEasyOneIntegracaoService.GerarHash(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(Trim(AValor)));
end;

class function TEasyOneIntegracaoService.HashIgual(const AHash1, AHash2: string): Boolean;
var
  I, Diferenca: Integer;
  Hash1, Hash2: string;
begin
  Hash1 := UpperCase(Trim(AHash1));
  Hash2 := UpperCase(Trim(AHash2));

  if Length(Hash1) <> Length(Hash2) then
    Exit(False);

  Diferenca := 0;

  for I := 1 to Length(Hash1) do
    Diferenca := Diferenca or (Ord(Hash1[I]) xor Ord(Hash2[I]));

  Result := Diferenca = 0;
end;

class procedure TEasyOneIntegracaoService.ValidarBootstrap(const AUsuario,ASenha: string);
var
  Ini: TIniFile;
  UsuarioConfig, SenhaConfig: string;
begin
  if Trim(AUsuario).IsEmpty or Trim(ASenha).IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  try
    UsuarioConfig := Trim(Ini.ReadString('API','Usuario',''));
    SenhaConfig   := Trim(Ini.ReadString('API','Senha',''));
  finally
    Ini.Free;
  end;
  if UsuarioConfig.IsEmpty or SenhaConfig.IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  if not SameText(Trim(AUsuario),UsuarioConfig) then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
  if not HashIgual(Trim(ASenha),SenhaConfig) then
    TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');
end;

class function TEasyOneIntegracaoService.Autenticar(const AUUID, AAPIKey: string): TEasyOneIntegracaoContexto;
var
  Config: TAppApiConfig;
  Conn  : TUniConnection;
  Dados : TEasyOneIntegracaoDados;
  Hash  : string;
begin
  Result := Default(TEasyOneIntegracaoContexto);

  if Trim(AUUID).IsEmpty or Trim(AAPIKey).IsEmpty then
    TAppErrors.RaiseUnauthorized('Credenciais de integração não informadas.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TEasyOneIntegracaoDAO.BuscarEmpresaPorUUID(Conn,AUUID,Dados) then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if not SameText(Trim(Dados.Ativo),'S') then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if not SameText(Trim(Dados.IntegracaoAtiva),'S') then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    if Trim(Dados.APIKeyHash).IsEmpty then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    Hash := GerarHash(AAPIKey);

    if not HashIgual(Hash,Dados.APIKeyHash) then
      TAppErrors.RaiseUnauthorized('Credenciais de integração inválidas.');

    Result.IdEmpresaAPI := Dados.Id;
    Result.IdEmpresa    := Dados.IdEmpresa;
    Result.UUID         := Dados.UUID;
  finally
    Conn.Free;
  end;
end;

class function TEasyOneIntegracaoService.ListarAtualizacoesCadastraisPendentes(
  const AIdEmpresaAPI: Integer): TJSONArray;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'SELECT ac.id, ac.pessoa_id, p.nome, p.cpf, p.matricula, ' +
        '       ac.email_novo, ac.telefone_novo, ac.whatsapp_novo, ' +
        '       ac.cep_novo, ac.endereco_novo, ac.numero_novo, ac.bairro_novo, ' +
        '       ac.complemento_novo, ac.cidade_nova, ac.criado_em ' +
        'FROM eleicao_atualizacao_cadastral ac ' +
        'INNER JOIN pessoa p ON p.id = ac.pessoa_id AND p.empresa_id = ac.empresa_id ' +
        'WHERE ac.empresa_id = :empresa ' +
        'AND ac.situacao = ''PENDENTE'' ' +
        'ORDER BY ac.id';
      Qry.ParamByName('empresa').AsInteger := AIdEmpresaAPI;
      Qry.Open;

      while not Qry.Eof do
      begin
        Item := TJSONObject.Create;
        Item.AddPair('id_solicitacao', TJSONNumber.Create(Qry.FieldByName('id').AsLargeInt));
        Item.AddPair('pessoa_id_api', TJSONNumber.Create(Qry.FieldByName('pessoa_id').AsLargeInt));
        Item.AddPair('nome', Qry.FieldByName('nome').AsString);
        Item.AddPair('cpf', Qry.FieldByName('cpf').AsString);
        Item.AddPair('matricula', Qry.FieldByName('matricula').AsString);
        Item.AddPair('email_novo', Qry.FieldByName('email_novo').AsString);
        Item.AddPair('telefone_novo', Qry.FieldByName('telefone_novo').AsString);
        Item.AddPair('whatsapp_novo', Qry.FieldByName('whatsapp_novo').AsString);
        Item.AddPair('cep_novo', Qry.FieldByName('cep_novo').AsString);
        Item.AddPair('endereco_novo', Qry.FieldByName('endereco_novo').AsString);
        Item.AddPair('numero_novo', Qry.FieldByName('numero_novo').AsString);
        Item.AddPair('bairro_novo', Qry.FieldByName('bairro_novo').AsString);
        Item.AddPair('complemento_novo', Qry.FieldByName('complemento_novo').AsString);
        Item.AddPair('cidade_nova', Qry.FieldByName('cidade_nova').AsString);
        Item.AddPair('criado_em', FormatDateTime('yyyy-mm-dd hh:nn:ss', Qry.FieldByName('criado_em').AsDateTime));
        Result.AddElement(Item);
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;
  except
    Result.Free;
    raise;
  end;
  Conn.Free;
end;

end.
