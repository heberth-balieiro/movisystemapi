unit PublicoAutoCadastro.Service;

interface

type
  TPublicoAutoCadastroResultado = record
    IdParticipante: Int64;
    Email: string;
  end;

  TPublicoAutoCadastroService = class
  private
    class function GerarCodigoPublico: string; static;
    class function EmailValido(const AEmail: string): Boolean; static;
  public
    class function Cadastrar(
      const ASlug, ANome, ACpf, AEmail, ATelefone, ASenha: string;
      const AAceiteTermos: Boolean
    ): TPublicoAutoCadastroResultado; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  App.ParticipanteSecurity,
  Database.Connection,
  PublicoAutoCadastro.DAO;

class function TPublicoAutoCadastroService.EmailValido(const AEmail: string): Boolean;
var
  P: Integer;
begin
  P := Pos('@', Trim(AEmail));
  Result := (P > 1) and (Pos('.', Copy(Trim(AEmail), P + 2, MaxInt)) > 0);
end;

class function TPublicoAutoCadastroService.GerarCodigoPublico: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);
  S := GUIDToString(G);
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := Copy(UpperCase(S), 1, 26);
end;

class function TPublicoAutoCadastroService.Cadastrar(
  const ASlug, ANome, ACpf, AEmail, ATelefone, ASenha: string;
  const AAceiteTermos: Boolean
): TPublicoAutoCadastroResultado;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Instituicao: TPublicoAutoCadastroInstituicao;
  Usuario: TPublicoAutoCadastroUsuario;
  Nome, Email, Telefone, Cpf, CpfHash, CpfMascarado, Codigo: string;
  IdUsuario, IdUsuarioInstituicao, IdParticipante: Int64;
  Tentativas: Integer;
begin
  Result := Default(TPublicoAutoCadastroResultado);

  Nome := Trim(ANome);
  Email := LowerCase(Trim(AEmail));
  Telefone := Trim(ATelefone);
  Cpf := TParticipanteSecurity.NormalizarCpf(ACpf);

  if Trim(ASlug).IsEmpty then
    TAppErrors.RaiseBadRequest('Instituicao nao informada.');

  if (Nome = '') or (Length(Nome) > 180) then
    TAppErrors.RaiseBadRequest('Informe o nome do participante.');

  if (Email = '') or (Length(Email) > 254) or (not EmailValido(Email)) then
    TAppErrors.RaiseBadRequest('Informe um e-mail valido.');

  if Length(Telefone) > 30 then
    TAppErrors.RaiseBadRequest('Telefone invalido.');

  if not TParticipanteSecurity.CpfValido(Cpf) then
    TAppErrors.RaiseBadRequest('Informe um CPF valido.');

  if (Length(ASenha) < 8) or (Length(ASenha) > 120) then
    TAppErrors.RaiseBadRequest('A senha deve possuir entre 8 e 120 caracteres.');

  if not AAceiteTermos then
    TAppErrors.RaiseBadRequest('E necessario aceitar os termos e a politica de privacidade.');

  CpfHash := TParticipanteSecurity.GerarCpfHashBusca(Cpf);
  CpfMascarado := TParticipanteSecurity.MascararCpf(Cpf);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Instituicao := TPublicoAutoCadastroDAO.BuscarInstituicao(Conn, ASlug);

    if not Instituicao.Encontrada then
      TAppErrors.RaiseBadRequest('Instituicao nao encontrada.');

    if not SameText(Instituicao.Situacao, 'ATIVA') then
      TAppErrors.RaiseForbidden('Instituicao indisponivel para auto cadastro.');

    if not Instituicao.PermitirAutoCadastro then
      TAppErrors.RaiseForbidden('O auto cadastro de participantes nao esta habilitado.');

    if TPublicoAutoCadastroDAO.ExisteCpf(Conn, Instituicao.IdInstituicao, CpfHash) then
      TAppErrors.RaiseBadRequest('Ja existe participante cadastrado com este CPF.');

    Usuario := TPublicoAutoCadastroDAO.BuscarUsuarioPorEmail(Conn, Email);

    if Usuario.Encontrado and not SameText(Usuario.Situacao, 'ATIVO') then
      TAppErrors.RaiseBadRequest('Ja existe uma conta para este e-mail, mas ela nao esta ativa.');

    if Usuario.Encontrado and not VerifySenha(ASenha, Usuario.SenhaHash) then
      TAppErrors.RaiseBadRequest(
        'Este e-mail ja possui uma conta MoviSystem. Informe a mesma senha utilizada nessa conta.'
      );

    Conn.StartTransaction;
    try
      if Usuario.Encontrado then
        IdUsuario := Usuario.IdUsuario
      else
        IdUsuario := TPublicoAutoCadastroDAO.CriarUsuario(
          Conn,
          Nome,
          Email,
          Email,
          HashSenha(ASenha)
        );

      IdUsuarioInstituicao := TPublicoAutoCadastroDAO.BuscarUsuarioInstituicao(
        Conn,
        Instituicao.IdInstituicao,
        IdUsuario
      );

      if IdUsuarioInstituicao > 0 then
      begin
        if TPublicoAutoCadastroDAO.ParticipanteVinculado(
          Conn,
          Instituicao.IdInstituicao,
          IdUsuarioInstituicao
        ) then
          TAppErrors.RaiseBadRequest('Seu cadastro ja existe. Entre com seu acesso.');

        TAppErrors.RaiseBadRequest(
          'Este e-mail ja possui acesso nesta instituicao. Entre com seu acesso.'
        );
      end;

      IdUsuarioInstituicao := TPublicoAutoCadastroDAO.CriarUsuarioInstituicao(
        Conn,
        Instituicao.IdInstituicao,
        IdUsuario
      );

      Tentativas := 0;
      repeat
        Inc(Tentativas);
        Codigo := GerarCodigoPublico;
      until (Tentativas >= 5) or (not TPublicoAutoCadastroDAO.ExisteCpf(
        Conn,
        Instituicao.IdInstituicao,
        CpfHash
      ));

      IdParticipante := TPublicoAutoCadastroDAO.CriarParticipante(
        Conn,
        Instituicao.IdInstituicao,
        IdUsuarioInstituicao,
        Codigo,
        Nome,
        CpfHash,
        CpfMascarado,
        Email,
        Telefone
      );

      TPublicoAutoCadastroDAO.RegistrarAuditoria(
        Conn,
        Instituicao.IdInstituicao,
        IdUsuarioInstituicao,
        IdParticipante
      );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;
      raise;
    end;

    Result.IdParticipante := IdParticipante;
    Result.Email := Email;
  finally
    Conn.Free;
  end;
end;

end.
