unit InstituicaoPerfil.Service;

interface

uses
  Uni,
  System.Generics.Collections,
  InstituicaoPerfil.Model;

type
  TInstituicaoPerfilService = class
  private
    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarDescricao(
      const ADescricao: string
    ); static;

    class function NormalizarPermissoes(
      const AConn: TUniConnection;
      const APermissoes: TArray<Int64>
    ): TArray<Int64>; static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoPerfilLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdPerfil: Int64
    ): TInstituicaoPerfilItem; static;

    class function ListarPermissoes(
      const AIdInstituicao,
            AIdPerfil: Int64
    ): TObjectList<TInstituicaoPermissaoItem>; static;

    class function Cadastrar(
      const AIdInstituicao,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoPerfilCadastro;
      const APermissoes: TArray<Int64>;
      const AIP,
            AUserAgent: string
    ): TInstituicaoPerfilItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdPerfil,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoPerfilAlteracao;
      const AIP,
            AUserAgent: string
    ): TInstituicaoPerfilItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdPerfil,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const ASituacao,
            AIP,
            AUserAgent: string
    ): TInstituicaoPerfilItem; static;

    class function AtualizarPermissoes(
      const AIdInstituicao,
            AIdPerfil,
            AIdUsuario,
            AIdUsuarioInstituicao: Int64;
      const APermissoes: TArray<Int64>;
      const AIP,
            AUserAgent: string
    ): TInstituicaoPerfilItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPerfil.DAO;

class procedure TInstituicaoPerfilService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do perfil.'
    );

  if Length(Trim(ANome)) > 100 then
    TAppErrors.RaiseBadRequest(
      'O nome do perfil deve possuir no máximo 100 caracteres.'
    );
end;

class procedure TInstituicaoPerfilService.ValidarDescricao(
  const ADescricao: string
);
begin
  if Length(Trim(ADescricao)) > 255 then
    TAppErrors.RaiseBadRequest(
      'A descrição deve possuir no máximo 255 caracteres.'
    );
end;

class function TInstituicaoPerfilService.NormalizarPermissoes(
  const AConn: TUniConnection;
  const APermissoes: TArray<Int64>
): TArray<Int64>;
var
  Lista: TList<Int64>;
  IdPermissao: Int64;
begin
  Lista := TList<Int64>.Create;

  try
    for IdPermissao in APermissoes do
    begin
      if IdPermissao <= 0 then
        TAppErrors.RaiseBadRequest(
          'Permissão inválida.'
        );

      if Lista.IndexOf(IdPermissao) >= 0 then
        Continue;

      if not TInstituicaoPerfilDAO.ExistePermissaoAtiva(
        AConn,
        IdPermissao
      ) then
        TAppErrors.RaiseBadRequest(
          'Uma das permissões informadas não existe ou está inativa.'
        );

      Lista.Add(IdPermissao);
    end;

    Result :=
      Lista.ToArray;
  finally
    Lista.Free;
  end;
end;

class function TInstituicaoPerfilService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoPerfilLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoPerfilFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(TInstituicaoPerfilFiltro);

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
      ['ATIVO', 'INATIVO']
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
      TInstituicaoPerfilDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoPerfilService.BuscarPorId(
  const AIdInstituicao,
        AIdPerfil: Int64
): TInstituicaoPerfilItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Permissoes: TObjectList<TInstituicaoPermissaoItem>;
  Permissao: TInstituicaoPermissaoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdPerfil <= 0 then
    TAppErrors.RaiseBadRequest(
      'Perfil inválido.'
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
      TInstituicaoPerfilDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );

    if Result = nil then
      TAppErrors.RaiseNotFound(
        'Perfil não encontrado.'
      );

    Permissoes :=
      TInstituicaoPerfilDAO.ListarPermissoes(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );

    try
      while Permissoes.Count > 0 do
      begin
        Permissao :=
          Permissoes.Extract(
            Permissoes[0]
          );

        Result.Permissoes.Add(
          Permissao
        );
      end;
    finally
      Permissoes.Free;
    end;

  except
    Result.Free;
    Result := nil;
    raise;
  end;

  Conn.Free;
end;

class function TInstituicaoPerfilService.ListarPermissoes(
  const AIdInstituicao,
        AIdPerfil: Int64
): TObjectList<TInstituicaoPermissaoItem>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Perfil: TInstituicaoPerfilItem;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
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
    if AIdPerfil > 0 then
    begin
      Perfil :=
        TInstituicaoPerfilDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          AIdPerfil
        );

      try
        if Perfil = nil then
          TAppErrors.RaiseNotFound(
            'Perfil não encontrado.'
          );
      finally
        Perfil.Free;
      end;
    end;

    Result :=
      TInstituicaoPerfilDAO.ListarPermissoes(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoPerfilService.Cadastrar(
  const AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoPerfilCadastro;
  const APermissoes: TArray<Int64>;
  const AIP,
        AUserAgent: string
): TInstituicaoPerfilItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoPerfilCadastro;
  Permissoes: TArray<Int64>;
  IdPerfil: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Dados := ADados;
  Dados.Nome := Trim(Dados.Nome);
  Dados.Descricao := Trim(Dados.Descricao);

  ValidarNome(Dados.Nome);
  ValidarDescricao(Dados.Descricao);

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
    if TInstituicaoPerfilDAO.ExisteNome(
      Conn,
      AIdInstituicao,
      Dados.Nome
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe um perfil com este nome.'
      );

    Permissoes :=
      NormalizarPermissoes(
        Conn,
        APermissoes
      );

    Conn.StartTransaction;
    try
      IdPerfil :=
        TInstituicaoPerfilDAO.Inserir(
          Conn,
          AIdInstituicao,
          Dados
        );

      TInstituicaoPerfilDAO.SubstituirPermissoes(
        Conn,
        AIdInstituicao,
        IdPerfil,
        Permissoes
      );

      TInstituicaoPerfilDAO.RegistrarAuditoria(
        Conn,
        AIdInstituicao,
        AIdUsuario,
        AIdUsuarioInstituicao,
        IdPerfil,
        'PERFIL_CRIADO',
        'POST',
        '/v1/certifica/instituicao/perfis',
        'Perfil ' + Dados.Nome + ' cadastrado.',
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
      IdPerfil
    );
end;

class function TInstituicaoPerfilService.Atualizar(
  const AIdInstituicao,
        AIdPerfil,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoPerfilAlteracao;
  const AIP,
        AUserAgent: string
): TInstituicaoPerfilItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoPerfilAlteracao;
  Atual: TInstituicaoPerfilItem;
begin
  Result := nil;

  if AIdPerfil <= 0 then
    TAppErrors.RaiseBadRequest(
      'Perfil inválido.'
    );

  Dados := ADados;
  Dados.Nome := Trim(Dados.Nome);
  Dados.Descricao := Trim(Dados.Descricao);

  ValidarNome(Dados.Nome);
  ValidarDescricao(Dados.Descricao);

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
      TInstituicaoPerfilDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Perfil não encontrado.'
        );

      if Atual.Sistema then
        TAppErrors.RaiseForbidden(
          'Perfis de sistema não podem ser alterados.'
        );

      if TInstituicaoPerfilDAO.ExisteNome(
        Conn,
        AIdInstituicao,
        Dados.Nome,
        AIdPerfil
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe outro perfil com este nome.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoPerfilDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdPerfil,
          Dados
        );

        TInstituicaoPerfilDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuario,
          AIdUsuarioInstituicao,
          AIdPerfil,
          'PERFIL_ALTERADO',
          'PUT',
          '/v1/certifica/instituicao/perfis/' + AIdPerfil.ToString,
          'Dados do perfil alterados.',
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
      AIdPerfil
    );
end;

class function TInstituicaoPerfilService.AlterarSituacao(
  const AIdInstituicao,
        AIdPerfil,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const ASituacao,
        AIP,
        AUserAgent: string
): TInstituicaoPerfilItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TInstituicaoPerfilItem;
begin
  Result := nil;

  if AIdPerfil <= 0 then
    TAppErrors.RaiseBadRequest(
      'Perfil inválido.'
    );

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  if not MatchText(
    Situacao,
    ['ATIVO', 'INATIVO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida. Utilize ATIVO ou INATIVO.'
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
      TInstituicaoPerfilDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Perfil não encontrado.'
        );

      if Atual.Sistema then
        TAppErrors.RaiseForbidden(
          'Perfis de sistema não podem ser inativados.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoPerfilDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdPerfil,
          Situacao
        );

        TInstituicaoPerfilDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuario,
          AIdUsuarioInstituicao,
          AIdPerfil,
          'PERFIL_SITUACAO_ALTERADA',
          'PATCH',
          '/v1/certifica/instituicao/perfis/' +
          AIdPerfil.ToString +
          '/situacao',
          'Situação do perfil alterada para ' + Situacao + '.',
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
      AIdPerfil
    );
end;

class function TInstituicaoPerfilService.AtualizarPermissoes(
  const AIdInstituicao,
        AIdPerfil,
        AIdUsuario,
        AIdUsuarioInstituicao: Int64;
  const APermissoes: TArray<Int64>;
  const AIP,
        AUserAgent: string
): TInstituicaoPerfilItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TInstituicaoPerfilItem;
  Permissoes: TArray<Int64>;
begin
  Result := nil;

  if AIdPerfil <= 0 then
    TAppErrors.RaiseBadRequest(
      'Perfil inválido.'
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
      TInstituicaoPerfilDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdPerfil
      );

    try
      if Atual = nil then
        TAppErrors.RaiseNotFound(
          'Perfil não encontrado.'
        );

      if Atual.Sistema then
        TAppErrors.RaiseForbidden(
          'As permissões de perfis de sistema são gerenciadas pela aplicação.'
        );

      Permissoes :=
        NormalizarPermissoes(
          Conn,
          APermissoes
        );

      Conn.StartTransaction;
      try
        TInstituicaoPerfilDAO.SubstituirPermissoes(
          Conn,
          AIdInstituicao,
          AIdPerfil,
          Permissoes
        );

        TInstituicaoPerfilDAO.RegistrarAuditoria(
          Conn,
          AIdInstituicao,
          AIdUsuario,
          AIdUsuarioInstituicao,
          AIdPerfil,
          'PERFIL_PERMISSOES_ALTERADAS',
          'PUT',
          '/v1/certifica/instituicao/perfis/' +
          AIdPerfil.ToString +
          '/permissoes',
          'Permissões do perfil atualizadas.',
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
      AIdPerfil
    );
end;

end.
