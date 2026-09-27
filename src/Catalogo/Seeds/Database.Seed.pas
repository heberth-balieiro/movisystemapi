unit Database.Seed;

interface

type
  TDatabaseSeed = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  Uni,
  App.Config,
  Database.Connection,
  Empresa.DAO,
  Empresa.Model,
  Usuario.DAO,
  Usuario.Model,
  CatalogoConfig.Model,
  CatalogoConfig.Service,
  Auth.Passwords;

const
  SEED_ADMIN_NOME        = 'EasyOne Catálogo Admin';
  SEED_ADMIN_CNPJ        = '48227867000100';
  SEED_ADMIN_EMAIL       = 'conesulsistemas@gmail.com';
  SEED_ADMIN_SENHA       = 'Hd860412@';
  SEED_ADMIN_RESPONSAVEL = 'Heberth Balieiro';
  SEED_ADMIN_WHATSAPP    = '69992161179';
  SEED_ADMIN_CIDADE      = 'Osasco';
  SEED_ADMIN_UF          = 'SP';

function RemoverAcentosSlug(const ATexto: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ATexto));

  S := StringReplace(S, 'á', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'à', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ã', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'â', 'a', [rfReplaceAll]);
  S := StringReplace(S, 'ä', 'a', [rfReplaceAll]);

  S := StringReplace(S, 'é', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'è', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'ê', 'e', [rfReplaceAll]);
  S := StringReplace(S, 'ë', 'e', [rfReplaceAll]);

  S := StringReplace(S, 'í', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ì', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'î', 'i', [rfReplaceAll]);
  S := StringReplace(S, 'ï', 'i', [rfReplaceAll]);

  S := StringReplace(S, 'ó', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ò', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'õ', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ô', 'o', [rfReplaceAll]);
  S := StringReplace(S, 'ö', 'o', [rfReplaceAll]);

  S := StringReplace(S, 'ú', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ù', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'û', 'u', [rfReplaceAll]);
  S := StringReplace(S, 'ü', 'u', [rfReplaceAll]);

  S := StringReplace(S, 'ç', 'c', [rfReplaceAll]);

  Result := S;
end;

function GerarSlugEmpresa(const ANome: string; const AIdEmpresa: Int64): string;
var
  S: string;
  I: Integer;
  C: Char;
begin
  S := RemoverAcentosSlug(ANome);
  Result := '';

  for I := 1 to Length(S) do
  begin
    C := S[I];

    if CharInSet(C, ['a'..'z', '0'..'9']) then
      Result := Result + C
    else if CharInSet(C, [' ', '-', '_', '.', '/', '\']) then
      Result := Result + '-';
  end;

  while Pos('--', Result) > 0 do
    Result := StringReplace(Result, '--', '-', [rfReplaceAll]);

  while (Length(Result) > 0) and (Result[1] = '-') do
    Delete(Result, 1, 1);

  while (Length(Result) > 0) and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);

  if Result.IsEmpty then
    Result := 'catalogo-admin';

  Result := Result + '-' + AIdEmpresa.ToString;
end;

function EmpresaExistePorEmail(const AConn: TUniConnection; const AEmail: string): Boolean;
begin
  Result := TEmpresaDAO.ExisteEmail(AConn, AEmail);
end;

function BuscarIdEmpresaPorEmail(const AConn: TUniConnection; const AEmail: string): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'Select id_empresa ' +
      ' from empresa ' +
      ' where lower(trim(email)) = lower(trim(:email)) ' +
      ' limit 1';

    Qry.ParamByName('email').AsString := Trim(AEmail);
    Qry.Open;

    if not Qry.IsEmpty then
      Result := Qry.FieldByName('id_empresa').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

function CatalogoConfigExiste(const AConn: TUniConnection; const AIdEmpresa: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'select count(*) as total ' +
      ' from catalogo_config ' +
      ' where id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class procedure TDatabaseSeed.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Empresa: TEmpresaModel;
  Usuario: TUsuarioModel;
  ConfigCat: TCatalogoConfigModel;
  IdEmpresa: Int64;
  IdUsuario: Int64;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if EmpresaExistePorEmail(Conn, SEED_ADMIN_EMAIL) then
    begin
      Writeln('Seed ADMIN: empresa administradora já existe. Nenhuma ação necessária.');
      Exit;
    end;

    Conn.StartTransaction;
    try
      IdEmpresa := 0;
      IdUsuario := 0;

      Empresa := TEmpresaModel.Create;
      try
        Empresa.Nome := SEED_ADMIN_NOME;
        Empresa.Cnpj := SEED_ADMIN_CNPJ;
        Empresa.Cep := '';
        Empresa.Endereco := '';
        Empresa.Numero := '';
        Empresa.Complemento := '';
        Empresa.Bairro := '';
        Empresa.Cidade := SEED_ADMIN_CIDADE;
        Empresa.Uf := SEED_ADMIN_UF;
        Empresa.Whatsapp := SEED_ADMIN_WHATSAPP;
        Empresa.Email := LowerCase(SEED_ADMIN_EMAIL);
        Empresa.NomeResponsavel := SEED_ADMIN_RESPONSAVEL;
        Empresa.DataValidade := IncYear(Date, 10);
        Empresa.Ativo := 'S';
        Empresa.NotificarPedidoWhatsapp := 'N';
        Empresa.NotificarPedidoEmail := 'N';
        Empresa.ResumoDiario := 'N';
        Empresa.MensagemModelo := '';

        IdEmpresa := TEmpresaDAO.Inserir(Conn, Empresa);
      finally
        Empresa.Free;
      end;

      Usuario := TUsuarioModel.Create;
      try
        Usuario.IdEmpresa := IdEmpresa;
        Usuario.Nome := SEED_ADMIN_RESPONSAVEL;
        Usuario.Email := LowerCase(SEED_ADMIN_EMAIL);
        Usuario.SenhaHash := HashSenha(SEED_ADMIN_SENHA);
        Usuario.Perfil := 'ADMIN';
        Usuario.Ativo := 'S';

        IdUsuario := TUsuarioDAO.Inserir(Conn, Usuario);
      finally
        Usuario.Free;
      end;

      if not CatalogoConfigExiste(Conn, IdEmpresa) then
      begin
        ConfigCat := TCatalogoConfigModel.Create;
        try
          ConfigCat.IdConfig := 0;
          ConfigCat.IdEmpresa := IdEmpresa;
          ConfigCat.Slug := GerarSlugEmpresa(SEED_ADMIN_NOME, IdEmpresa);
          ConfigCat.TituloCatalogo := 'Catálogo da ' + SEED_ADMIN_NOME;
          ConfigCat.Descricao := 'Catálogo administrativo do EasyOne Catálogo Digital.';
          ConfigCat.CorPrimaria := '#FF6600';
          ConfigCat.CorSecundaria := '#222222';
          ConfigCat.LogoUrl := '';
          ConfigCat.BannerUrl := '';
          ConfigCat.MostrarPreco := 'S';
          ConfigCat.PermitirObservacao := 'S';
          ConfigCat.PermitirRetirada := 'S';
          ConfigCat.PermitirEntrega := 'N';
          ConfigCat.ValorMinimoPedido := 0;
          ConfigCat.Ativo := 'S';
          ConfigCat.url_whatsapp := '';
          ConfigCat.instancia_whatsapp := '';
          ConfigCat.token_whatsapp := '';

          TCatalogoConfigService.InserirConfig(Conn, IdEmpresa, ConfigCat);
        finally
          ConfigCat.Free;
        end;
      end;

      Conn.Commit;

      Writeln('Seed ADMIN criado com sucesso.');
      Writeln('Empresa ID: ' + IdEmpresa.ToString);
      Writeln('Usuario ID: ' + IdUsuario.ToString);
      Writeln('Email ADMIN: ' + SEED_ADMIN_EMAIL);
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
