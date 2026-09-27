unit InstituicaoUsuario.Service;

interface

uses
  Uni,
  InstituicaoUsuario.Model;

type
  TInstituicaoUsuarioService = class
  private
    class function EmailValido(
      const AEmail: string
    ): Boolean; static;

    class function GerarSenhaTemporaria: string; static;

    class function NormalizarPerfis(
      const AConn: TUniConnection;
      const AIdInstituicao: Int64;
      const APerfis: TArray<Int64>
    ): TArray<Int64>; static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoUsuarioLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdUsuarioInstituicao: Int64
    ): TInstituicaoUsuarioItem; static;

    class function Cadastrar(
      const AIdInstituicao,
            AIdUsuarioAcao,
            AIdUsuarioInstituicaoAcao: Int64;
      const ADados: TInstituicaoUsuarioCadastro;
      const AIP,
            AUserAgent: string;
      out ASenhaTemporaria: string;
      out AUsuarioJaExistia: Boolean
    ): TInstituicaoUsuarioItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdUsuarioAcao,
            AIdUsuarioInstituicaoAcao: Int64;
      const ADados: TInstituicaoUsuarioAlteracao;
      const AIP,
            AUserAgent: string
    ): TInstituicaoUsuarioItem; static;

    class function AtualizarPerfis(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdUsuarioAcao,
            AIdUsuarioInstituicaoAcao: Int64;
      const APerfis: TArray<Int64>;
      const AIP,
            AUserAgent: string
    ): TInstituicaoUsuarioItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdUsuarioInstituicao,
            AIdUsuarioAcao,
            AIdUsuarioInstituicaoAcao: Int64;
      const ASituacao,
            AIP,
            AUserAgent: string
    ): TInstituicaoUsuarioItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  App.Config,
  APP.Errors,
  Auth.Passwords,
  Database.Connection,
  InstituicaoUsuario.DAO;

class function TInstituicaoUsuarioService.EmailValido(
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

class function TInstituicaoUsuarioService.GerarSenhaTemporaria: string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);

  S := UpperCase(GUIDToString(G));
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);

  Result :=
    'Mv@' +
    Copy(S, 1, 10) +
    '1a';
end;

class function TInstituicaoUsuarioService.NormalizarPerfis(
  const AConn: TUniConnection;
  const AIdInstituicao: Int64;
  const APerfis: TArray<Int64>
): TArray<Int64>;
var
  Lista: TList<Int64>;
  IdPerfil: Int64;
begin
  Lista := TList<Int64>.Create;

  try
    if Length(APerfis) = 0 then
      TAppErrors.RaiseBadRequest(
        'Informe ao menos um perfil para o usuário.'
      );

    for IdPerfil in APerfis do
    begin
      if IdPerfil <= 0 then
        TAppErrors.RaiseBadRequest(
          'Perfil inválido.'
        );

      if Lista.IndexOf(IdPerfil) >= 0 then
        Continue;

      if not TInstituicaoUsuarioDAO.PerfilAtivoPertenceInstituicao(
        AConn,
        AIdInstituicao,
        IdPerfil
      ) then
        TAppErrors.RaiseBadRequest(
          'Um dos perfis informados não existe ou está inativo.'
        );

      Lista.Add(IdPerfil);
    end;

    Result :=
      Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

class function TInstituicaoUsuarioService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoUsuarioLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoUsuarioFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(TInstituicaoUsuarioFiltro);

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.Situacao :=
    UpperCase(Trim(ASituacao));

  Filtro.Pagina :=
    APagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina :=
    APorPagina;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    if not MatchText(
      Filtro.Situacao,
      ['ATIVO', 'INATIVO', 'BLOQUEADO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Situação inválida.'
      );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      TInstituicaoUsuarioDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoUsuarioService.BuscarPorId(
  const AIdInstituicao,
        AIdUsuarioInstituicao: Int64
): TInstituicaoUsuarioItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseBadRequest(
      'Usuário inválido.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Result :=
      TInstituicaoUsuarioDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    if Result = nil then
      TAppErrors.RaiseNotFound(
        'Usuário da instituição não encontrado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoUsuarioService.Cadastrar(
  const AIdInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao: Int64;
  const ADados: TInstituicaoUsuarioCadastro;
  const AIP,
        AUserAgent: string;
  out ASenhaTemporaria: string;
  out AUsuarioJaExistia: Boolean
): TInstituicaoUsuarioItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoUsuarioCadastro;
  UsuarioGlobal: TInstituicaoUsuarioGlobalDados;
  Perfis: TArray<Int64>;
  IdUsuario: Int64;
  IdUsuarioInstituicao: Int64;
begin
  Result := nil;
  ASenhaTemporaria := '';
  AUsuarioJaExistia := False;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Dados := ADados;
  Dados.Nome := Trim(Dados.Nome);
  Dados.Email := LowerCase(Trim(Dados.Email));
  Dados.Login := Trim(Dados.Login);

  if Dados.Nome.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do usuário.'
    );

  if Length(Dados.Nome) > 180 then
    TAppErrors.RaiseBadRequest(
      'O nome do usuário deve possuir no máximo 180 caracteres.'
    );

  if Dados.Email.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o e-mail do usuário.'
    );

  if (Length(Dados.Email) > 254) or
     (not EmailValido(Dados.Email)) then
    TAppErrors.RaiseBadRequest(
      'Informe um e-mail válido.'
    );

  if Length(Dados.Login) > 80 then
    TAppErrors.RaiseBadRequest(
      'O login deve possuir no máximo 80 caracteres.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Perfis :=
      NormalizarPerfis(
        Conn,
        AIdInstituicao,
        Dados.Perfis
      );

    if TInstituicaoUsuarioDAO.ExisteLogin(
      Conn,
      AIdInstituicao,
      Dados.Login
    ) then
      TAppErrors.RaiseBadRequest(
        'Este login já está sendo utilizado na instituição.'
      );

    AUsuarioJaExistia :=
      TInstituicaoUsuarioDAO.BuscarUsuarioGlobalPorEmail(
        Conn,
        Dados.Email,
        UsuarioGlobal
      );

    if AUsuarioJaExistia then
    begin
      if not SameText(
        UsuarioGlobal.Situacao,
        'ATIVO'
      ) then
        TAppErrors.RaiseBadRequest(
          'Este e-mail pertence a um usuário global que não está ativo.'
        );

      IdUsuario :=
        UsuarioGlobal.Id;

      if TInstituicaoUsuarioDAO.UsuarioJaVinculado(
        Conn,
        AIdInstituicao,
        IdUsuario
      ) then
        TAppErrors.RaiseBadRequest(
          'Este usuário já está vinculado à instituição.'
        );
    end
    else
    begin
      ASenhaTemporaria :=
        GerarSenhaTemporaria;
    end;

    Conn.StartTransaction;
    try
      if not AUsuarioJaExistia then
        IdUsuario :=
          TInstituicaoUsuarioDAO.InserirUsuarioGlobal(
            Conn,
            Dados.Nome,
            Dados.Email,
            HashSenha(
              ASenhaTemporaria
            )
          );

      IdUsuarioInstituicao :=
        TInstituicaoUsuarioDAO.InserirVinculo(
          Conn,
          AIdInstituicao,
          IdUsuario,
          Dados.Login
        );

      TInstituicaoUsuarioDAO.SubstituirPerfis(
        Conn,
        AIdInstituicao,
        IdUsuarioInstituicao,
        Perfis
      );

      TInstituicaoUsuarioDAO.RegistrarAuditoria(
        Conn,
        AIdInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao,
        IdUsuarioInstituicao,
        'INSTITUICAO_USUARIO_CRIADO',
        'POST',
        '/v1/certifica/instituicao/usuarios',
        'Usuário vinculado à instituição.',
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

  Result :=
    BuscarPorId(
      AIdInstituicao,
      IdUsuarioInstituicao
    );
end;

class function TInstituicaoUsuarioService.Atualizar(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao: Int64;
  const ADados: TInstituicaoUsuarioAlteracao;
  const AIP,
        AUserAgent: string
): TInstituicaoUsuarioItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TInstituicaoUsuarioItem;
  Login: string;
begin
  Result := nil;

  Login :=
    Trim(ADados.Login);

  if Length(Login) > 80 then
    TAppErrors.RaiseBadRequest(
      'O login deve possuir no máximo 80 caracteres.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Atual :=
      TInstituicaoUsuarioDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Usuário da instituição não encontrado.'
        );

      if Atual.Principal then
        TAppErrors.RaiseForbidden(
          'O usuário principal da instituição é protegido.'
        );

      if TInstituicaoUsuarioDAO.ExisteLogin(
        Conn,
        AIdInstituicao,
        Login,
        AIdUsuarioInstituicao
      ) then
        TAppErrors.RaiseBadRequest(
          'Este login já está sendo utilizado na instituição.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoUsuarioDAO.AtualizarLogin(
          Conn,
          AIdInstituicao,
          AIdUsuarioInstituicao,
          Login
        );

        TInstituicaoUsuarioDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuarioAcao,
          AIdUsuarioInstituicaoAcao,
          AIdUsuarioInstituicao,
          'INSTITUICAO_USUARIO_ALTERADO',
          'PUT',
          '/v1/certifica/instituicao/usuarios/' +
          AIdUsuarioInstituicao.ToString,
          'Dados do vínculo do usuário alterados.',
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
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;

  Result :=
    BuscarPorId(
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
end;

class function TInstituicaoUsuarioService.AtualizarPerfis(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao: Int64;
  const APerfis: TArray<Int64>;
  const AIP,
        AUserAgent: string
): TInstituicaoUsuarioItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TInstituicaoUsuarioItem;
  Perfis: TArray<Int64>;
begin
  Result := nil;

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Atual :=
      TInstituicaoUsuarioDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Usuário da instituição não encontrado.'
        );

      if Atual.Principal then
        TAppErrors.RaiseForbidden(
          'Os perfis do usuário principal são gerenciados pela aplicação.'
        );

      Perfis :=
        NormalizarPerfis(
          Conn,
          AIdInstituicao,
          APerfis
        );

      Conn.StartTransaction;
      try
        TInstituicaoUsuarioDAO.SubstituirPerfis(
          Conn,
          AIdInstituicao,
          AIdUsuarioInstituicao,
          Perfis
        );

        TInstituicaoUsuarioDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuarioAcao,
          AIdUsuarioInstituicaoAcao,
          AIdUsuarioInstituicao,
          'INSTITUICAO_USUARIO_PERFIS_ALTERADOS',
          'PUT',
          '/v1/certifica/instituicao/usuarios/' +
          AIdUsuarioInstituicao.ToString +
          '/perfis',
          'Perfis do usuário atualizados.',
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
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;

  Result :=
    BuscarPorId(
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
end;

class function TInstituicaoUsuarioService.AlterarSituacao(
  const AIdInstituicao,
        AIdUsuarioInstituicao,
        AIdUsuarioAcao,
        AIdUsuarioInstituicaoAcao: Int64;
  const ASituacao,
        AIP,
        AUserAgent: string
): TInstituicaoUsuarioItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TInstituicaoUsuarioItem;
  Situacao: string;
begin
  Result := nil;

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  if not MatchText(
    Situacao,
    ['ATIVO', 'INATIVO', 'BLOQUEADO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida.'
    );

  Config :=
    TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) +
      'Config.ini'
    );

  Conn :=
    TDatabaseConnection.NewConnection(
      Config.Database
    );

  try
    Atual :=
      TInstituicaoUsuarioDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdUsuarioInstituicao
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Usuário da instituição não encontrado.'
        );

      if Atual.Principal then
        TAppErrors.RaiseForbidden(
          'O usuário principal da instituição não pode ser inativado.'
        );

      if AIdUsuarioInstituicao = AIdUsuarioInstituicaoAcao then
        TAppErrors.RaiseForbidden(
          'Você não pode alterar a situação do próprio usuário.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoUsuarioDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdUsuarioInstituicao,
          Situacao
        );

        TInstituicaoUsuarioDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuarioAcao,
          AIdUsuarioInstituicaoAcao,
          AIdUsuarioInstituicao,
          'INSTITUICAO_USUARIO_SITUACAO_ALTERADA',
          'PATCH',
          '/v1/certifica/instituicao/usuarios/' +
          AIdUsuarioInstituicao.ToString +
          '/situacao',
          'Situação do usuário alterada para ' + Situacao + '.',
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
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;

  Result :=
    BuscarPorId(
      AIdInstituicao,
      AIdUsuarioInstituicao
    );
end;

end.
