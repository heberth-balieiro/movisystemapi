unit Certifica.Seeds;

interface
type
  TCertificaSeeds = class
  public
    class procedure Run; static;
  end;
implementation
uses
  System.SysUtils,
  System.IniFiles,
  Uni,
  App.Config,
  Auth.Passwords,
  Database.Connection;
class procedure TCertificaSeeds.Run;
var
  Config: TAppApiConfig;
  Ini: TIniFile;
  Conn: TUniConnection;
  Qry: TUniQuery;
  CriarInicial: Boolean;
  Nome, Email, Senha: string;
begin
  // O seed é opt-in para evitar criar credencial conhecida automaticamente em produção.
  Ini := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  try
    CriarInicial := Ini.ReadBool('CERTIFICA_ADMIN', 'CriarInicial', False);
    if not CriarInicial then
      Exit;

    Nome  := Trim(Ini.ReadString('CERTIFICA_ADMIN', 'Nome', 'Administrador MoviSystem'));
    Email := LowerCase(Trim(Ini.ReadString('CERTIFICA_ADMIN', 'Email', '')));
    Senha := Ini.ReadString('CERTIFICA_ADMIN', 'Senha', '');
  finally
    Ini.Free;
  end;
  if Email.IsEmpty then
    raise Exception.Create('CERTIFICA_ADMIN.Email não configurado no Config.ini.');
  if Senha.IsEmpty then
    raise Exception.Create('CERTIFICA_ADMIN.Senha não configurada no Config.ini.');
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text := 'SELECT id FROM usuario WHERE email_normalizado = :email LIMIT 1';
      Qry.ParamByName('email').AsString := Email;
      Qry.Open;
      if not Qry.IsEmpty then
      begin
        Writeln('Certifica Seed: Super Admin já cadastrado.');
        Exit;
      end;
      Qry.Close;
      Qry.SQL.Text :=
        'INSERT INTO usuario ' +
        '(nome, email, email_normalizado, senha_hash, is_super_admin, situacao, senha_alterada_em) ' +
        'VALUES (:nome, :email, :email_normalizado, :senha_hash, 1, ''ATIVO'', CURRENT_TIMESTAMP(3))';
      Qry.ParamByName('nome').AsString := Nome;
      Qry.ParamByName('email').AsString := Email;
      Qry.ParamByName('email_normalizado').AsString := Email;
      Qry.ParamByName('senha_hash').AsString := HashSenha(Senha);
      Qry.Execute;
      Writeln('Certifica Seed: Super Admin criado com sucesso para ' + Email + '.');
      Writeln('Certifica Seed: após o primeiro acesso, altere CERTIFICA_ADMIN.CriarInicial para False.');
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;
end.

