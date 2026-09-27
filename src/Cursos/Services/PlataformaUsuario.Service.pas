unit PlataformaUsuario.Service;

interface

uses
  System.Generics.Collections,
  PlataformaUsuario.Model;

type
  TPlataformaUsuarioService = class
  private
    class function EmailValido(const AEmail: string): Boolean; static;
    class function GerarSenhaTemporaria: string; static;
  public
    class function Criar(
      const ANome, AEmail: string;
      const AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string;
      out ASenhaTemporaria: string
    ): TPlataformaUsuarioModel; static;

    class function Listar: TObjectList<TPlataformaUsuarioModel>; static;
    class function BuscarPorId(const AId: Int64): TPlataformaUsuarioModel; static;

    class function Atualizar(const AIdUsuario: Int64;const ANome, AEmail: string;const AIdUsuarioAcao: Int64;
                  const AIP, AUserAgent: string): TPlataformaUsuarioModel; static;

    class function AtualizarSituacao(
      const AIdUsuario: Int64;
      const ASituacao: string;
      const AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string
    ): TPlataformaUsuarioModel; static;

    class function RenovarSenha(
      const AIdUsuario: Int64;
      const AIdUsuarioAcao: Int64;
      const AIP, AUserAgent: string
    ): string; static;

  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  PlataformaUsuario.DAO;

class function TPlataformaUsuarioService.EmailValido(
  const AEmail: string
): Boolean;
var
  P: Integer;
  Email: string;
begin
  Email := Trim(AEmail);
  P := Pos('@', Email);

  Result :=
    (P > 1) and
    (Pos('.', Copy(Email, P + 2, MaxInt)) > 0);
end;

class function TPlataformaUsuarioService.GerarSenhaTemporaria: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);

  S := UpperCase(GUIDToString(G));
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);

  Result := 'Mv@' + Copy(S, 1, 10) + '1a';
end;

class function TPlataformaUsuarioService.Listar: TObjectList<TPlataformaUsuarioModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaUsuarioDAO.Listar(Conn);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioService.BuscarPorId(
  const AId: Int64): TPlataformaUsuarioModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Usuário inválido.');

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaUsuarioDAO.BuscarPorId(Conn, AId);

    if Result = nil then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioService.Criar(
  const ANome, AEmail: string;
  const AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string;
  out ASenhaTemporaria: string
): TPlataformaUsuarioModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Nome, Email: string;
  IdUsuario: Int64;
begin
  Result := nil;
  ASenhaTemporaria := '';

  Nome := Trim(ANome);
  Email := LowerCase(Trim(AEmail));

  if Nome.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do usuário.');

  if Length(Nome) > 180 then
    TAppErrors.RaiseBadRequest('Nome do usuário excede o tamanho permitido.');

  if Email.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o e-mail do usuário.');

  if Length(Email) > 254 then
    TAppErrors.RaiseBadRequest('E-mail excede o tamanho permitido.');

  if not EmailValido(Email) then
    TAppErrors.RaiseBadRequest('Informe um e-mail válido.');

  if AIdUsuarioAcao <= 0 then
    TAppErrors.RaiseForbidden('Usuário responsável pela operação não identificado.');

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TPlataformaUsuarioDAO.ExisteEmail(Conn, Email) then
      TAppErrors.RaiseBadRequest('Já existe um usuário cadastrado com este e-mail.');

    ASenhaTemporaria := GerarSenhaTemporaria;

    Conn.StartTransaction;
    try
      IdUsuario := TPlataformaUsuarioDAO.Inserir(
        Conn,
        Nome,
        Email,
        HashSenha(ASenhaTemporaria)
      );

      TPlataformaUsuarioDAO.RegistrarAuditoria(
        Conn,
        IdUsuario,
        AIdUsuarioAcao,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaUsuarioDAO.BuscarPorId(Conn, IdUsuario);

    if Result = nil then
      raise Exception.Create('Usuário cadastrado, mas não foi possível recuperar seus dados.');
  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioService.Atualizar(
  const AIdUsuario: Int64;
  const ANome, AEmail: string;
  const AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
): TPlataformaUsuarioModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Nome, Email: string;
  UsuarioExistente: TPlataformaUsuarioModel;
begin
  Result := nil;

  Nome := Trim(ANome);
  Email := LowerCase(Trim(AEmail));

  if AIdUsuario <= 0 then
    TAppErrors.RaiseBadRequest('Usuário inválido.');

  if AIdUsuarioAcao <= 0 then
    TAppErrors.RaiseForbidden(
      'Usuário responsável pela operação não identificado.'
    );

  if Nome.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do usuário.'
    );

  if Length(Nome) > 180 then
    TAppErrors.RaiseBadRequest(
      'Nome do usuário excede o tamanho permitido.'
    );

  if Email.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o e-mail do usuário.'
    );

  if Length(Email) > 254 then
    TAppErrors.RaiseBadRequest(
      'E-mail excede o tamanho permitido.'
    );

  if not EmailValido(Email) then
    TAppErrors.RaiseBadRequest(
      'Informe um e-mail válido.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    // Garante que o registro pertence à administração da plataforma.
    UsuarioExistente :=
      TPlataformaUsuarioDAO.BuscarPorId(Conn, AIdUsuario);

    if UsuarioExistente = nil then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );

    UsuarioExistente.Free;

    if TPlataformaUsuarioDAO.ExisteEmailOutroUsuario(
      Conn,
      Email,
      AIdUsuario
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe outro usuário cadastrado com este e-mail.'
      );

    Conn.StartTransaction;
    try
      TPlataformaUsuarioDAO.Atualizar(
        Conn,
        AIdUsuario,
        Nome,
        Email
      );

      TPlataformaUsuarioDAO.RegistrarAuditoriaAlteracao(
        Conn,
        AIdUsuario,
        AIdUsuarioAcao,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    // O retorno vem novamente do banco para refletir exatamente o que foi persistido.
    Result := TPlataformaUsuarioDAO.BuscarPorId(
      Conn,
      AIdUsuario
    );

    if Result = nil then
      raise Exception.Create(
        'Usuário atualizado, mas não foi possível recuperar seus dados.'
      );

  finally
    Conn.Free;
  end;
end;

class function TPlataformaUsuarioService.AtualizarSituacao(
  const AIdUsuario: Int64;
  const ASituacao: string;
  const AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
): TPlataformaUsuarioModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Usuario: TPlataformaUsuarioModel;
begin
  Result := nil;

  Situacao := UpperCase(Trim(ASituacao));

  if AIdUsuario <= 0 then
    TAppErrors.RaiseBadRequest('Usuário inválido.');

  if AIdUsuarioAcao <= 0 then
    TAppErrors.RaiseForbidden(
      'Usuário responsável pela operação não identificado.'
    );

  if (Situacao <> 'ATIVO') and
     (Situacao <> 'INATIVO') then
    TAppErrors.RaiseBadRequest(
      'Situação inválida. Informe ATIVO ou INATIVO.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Usuario := TPlataformaUsuarioDAO.BuscarPorId(
      Conn,
      AIdUsuario
    );

    if Usuario = nil then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );

    try
      // Impede o administrador de retirar o próprio acesso.
      if (Situacao = 'INATIVO') and
         (AIdUsuario = AIdUsuarioAcao) then
        TAppErrors.RaiseBadRequest(
          'Não é possível inativar o próprio usuário.'
        );

      if Usuario.Situacao = Situacao then
        TAppErrors.RaiseBadRequest(
          'O usuário já está com a situação informada.'
        );

      // Mantém pelo menos um administrador ativo na plataforma.
      if (Situacao = 'INATIVO') and
         (TPlataformaUsuarioDAO.QuantidadeSuperAdminsAtivos(Conn) <= 1) then
        TAppErrors.RaiseBadRequest(
          'Não é possível inativar o último Super Administrador ativo.'
        );

    finally
      Usuario.Free;
    end;

    Conn.StartTransaction;
    try
      TPlataformaUsuarioDAO.AtualizarSituacao(
        Conn,
        AIdUsuario,
        Situacao
      );

      TPlataformaUsuarioDAO.RegistrarAuditoriaSituacao(
        Conn,
        AIdUsuario,
        AIdUsuarioAcao,
        Situacao,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaUsuarioDAO.BuscarPorId(
      Conn,
      AIdUsuario
    );

    if Result = nil then
      raise Exception.Create(
        'Situação atualizada, mas não foi possível recuperar o usuário.'
      );

  finally
    Conn.Free;
  end;
end;


class function TPlataformaUsuarioService.RenovarSenha(
  const AIdUsuario: Int64;
  const AIdUsuarioAcao: Int64;
  const AIP, AUserAgent: string
): string;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Usuario: TPlataformaUsuarioModel;
  SenhaTemporaria: string;
begin
  Result := '';

  if AIdUsuario <= 0 then
    TAppErrors.RaiseBadRequest(
      'Usuário inválido.'
    );

  if AIdUsuarioAcao <= 0 then
    TAppErrors.RaiseForbidden(
      'Usuário responsável pela operação não identificado.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    // Garante que o alvo seja realmente um usuário da administração MoviSystem.
    Usuario :=
      TPlataformaUsuarioDAO.BuscarPorId(
        Conn,
        AIdUsuario
      );

    if Usuario = nil then
      TAppErrors.RaiseNotFound(
        'Usuário da plataforma não encontrado.'
      );

    Usuario.Free;

    SenhaTemporaria := GerarSenhaTemporaria;

    Conn.StartTransaction;
    try
      TPlataformaUsuarioDAO.AtualizarSenha(
        Conn,
        AIdUsuario,
        HashSenha(SenhaTemporaria)
      );

      TPlataformaUsuarioDAO.RegistrarAuditoriaRenovacaoSenha(
        Conn,
        AIdUsuario,
        AIdUsuarioAcao,
        AIP,
        AUserAgent
      );

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := SenhaTemporaria;

  finally
    Conn.Free;
  end;
end;

end.
