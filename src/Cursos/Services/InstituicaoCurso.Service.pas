unit InstituicaoCurso.Service;

interface

uses
  InstituicaoCurso.Model;

type
  TInstituicaoCursoService = class
  private
    class function GerarCodigoPublico: string; static;
  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca, ASituacao, AModalidade: string;
      const APagina, APorPagina: Integer
    ): TInstituicaoCursoLista; static;

    class function BuscarPorId(
      const AIdInstituicao, AIdCurso: Int64
    ): TInstituicaoCursoItem; static;

    class function Cadastrar(
      const AIdInstituicao: Int64;
      const AIdUsuarioInstituicao: Int64;
      const ADados: TInstituicaoCursoCadastro
    ): TInstituicaoCursoItem; static;

    class function Atualizar(
      const AIdInstituicao, AIdCurso: Int64;
      const ADados: TInstituicaoCursoAlteracao
    ): TInstituicaoCursoItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdCurso: Int64;
      const ASituacao: string
    ): TInstituicaoCursoItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoCurso.DAO,
  InstituicaoCursoCategoria.DAO;

class function TInstituicaoCursoService.AlterarSituacao(
  const AIdInstituicao,
        AIdCurso: Int64;
  const ASituacao: string
): TInstituicaoCursoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  CursoAtual: TInstituicaoCursoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Curso inválido.'
    );

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  if not MatchText(
    Situacao,
    ['RASCUNHO', 'ATIVO', 'INATIVO']
  ) then
  begin
    TAppErrors.RaiseBadRequest(
      'Situação inválida. Utilize RASCUNHO, ATIVO ou INATIVO.'
    );
  end;

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
    CursoAtual :=
      TInstituicaoCursoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCurso
      );

    try
      if CursoAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Curso não encontrado.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoCursoDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdCurso,
          Situacao
        );

        Result :=
          TInstituicaoCursoDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdCurso
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o curso atualizado.'
          );

        Conn.Commit;

      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;

        raise;
      end;

    finally
      CursoAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoService.GerarCodigoPublico: string;
var
  Guid: TGUID;
  S: string;
begin
  CreateGUID(Guid);

  S := GUIDToString(Guid);
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);

  Result := Copy(UpperCase(S), 1, 26);
end;

class function TInstituicaoCursoService.BuscarPorId(
  const AIdInstituicao, AIdCurso: Int64
): TInstituicaoCursoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Curso inválido.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    Result := TInstituicaoCursoDAO.BuscarPorId(
      Conn,
      AIdInstituicao,
      AIdCurso
    );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Curso não encontrado.'
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoService.Cadastrar(
  const AIdInstituicao: Int64;
  const AIdUsuarioInstituicao: Int64;
  const ADados: TInstituicaoCursoCadastro
): TInstituicaoCursoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCursoCadastro;
  IdCurso: Int64;
  Tentativas: Integer;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Vínculo do usuário com a instituição não identificado.'
    );

  Dados := ADados;

  Dados.Nome := Trim(Dados.Nome);
  Dados.CodigoInterno := Trim(Dados.CodigoInterno);
  Dados.Slug := LowerCase(Trim(Dados.Slug));
  Dados.Modalidade := UpperCase(Trim(Dados.Modalidade));
  Dados.Situacao := UpperCase(Trim(Dados.Situacao));
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.Objetivo := Trim(Dados.Objetivo);
  Dados.ImagemUrl := Trim(Dados.ImagemUrl);
  Dados.CriadoPor := AIdUsuarioInstituicao;

  if Dados.Nome.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do curso.'
    );

  if Length(Dados.Nome) > 200 then
    TAppErrors.RaiseBadRequest(
      'O nome do curso deve possuir no máximo 200 caracteres.'
    );

  if Dados.CargaHorariaMinutos <= 0 then
    TAppErrors.RaiseBadRequest(
      'A carga horária deve ser maior que zero.'
    );

  if not MatchText(
    Dados.Modalidade,
    ['PRESENCIAL', 'ONLINE', 'HIBRIDO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Modalidade inválida.'
    );

  if Dados.Situacao.IsEmpty then
    Dados.Situacao := 'RASCUNHO';

  if not MatchText(
    Dados.Situacao,
    ['RASCUNHO', 'ATIVO', 'INATIVO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida.'
    );

  if Length(Dados.CodigoInterno) > 50 then
    TAppErrors.RaiseBadRequest(
      'O código interno deve possuir no máximo 50 caracteres.'
    );

  if Length(Dados.Slug) > 160 then
    TAppErrors.RaiseBadRequest(
      'O slug deve possuir no máximo 160 caracteres.'
    );

  if Length(Dados.ImagemUrl) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL da imagem deve possuir no máximo 1000 caracteres.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    if Dados.IdCategoria > 0 then
    begin
      if not TInstituicaoCursoCategoriaDAO.ExisteCategoriaAtiva(
        Conn,
        AIdInstituicao,
        Dados.IdCategoria
      ) then
        TAppErrors.RaiseBadRequest(
          'Categoria não encontrada, não pertence à instituição ou está inativa.'
        );
    end;

    if TInstituicaoCursoDAO.ExisteCodigoInterno(
      Conn,
      AIdInstituicao,
      Dados.CodigoInterno
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe um curso com este código interno.'
      );

    if TInstituicaoCursoDAO.ExisteSlug(
      Conn,
      AIdInstituicao,
      Dados.Slug
    ) then
      TAppErrors.RaiseBadRequest(
        'Já existe um curso com este slug.'
      );

    Tentativas := 0;

    repeat
      Inc(Tentativas);
      Dados.CodigoPublico := GerarCodigoPublico;
    until
      (not TInstituicaoCursoDAO.ExisteCodigoPublico(
        Conn,
        Dados.CodigoPublico
      )) or
      (Tentativas >= 5);

    if TInstituicaoCursoDAO.ExisteCodigoPublico(
      Conn,
      Dados.CodigoPublico
    ) then
      raise Exception.Create(
        'Não foi possível gerar um código público único para o curso.'
      );

    Conn.StartTransaction;
    try
      IdCurso := TInstituicaoCursoDAO.Inserir(
        Conn,
        AIdInstituicao,
        Dados
      );

      Result := TInstituicaoCursoDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        IdCurso
      );

      if Result = nil then
        raise Exception.Create(
          'Curso cadastrado, mas não foi possível recuperar seus dados.'
        );

      Conn.Commit;
    except
      if Conn.InTransaction then
        Conn.Rollback;

      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoService.Atualizar(
  const AIdInstituicao, AIdCurso: Int64;
  const ADados: TInstituicaoCursoAlteracao
): TInstituicaoCursoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCursoAlteracao;
  CursoAtual: TInstituicaoCursoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCurso <= 0 then
    TAppErrors.RaiseBadRequest(
      'Curso inválido.'
    );

  Dados := ADados;

  Dados.Nome := Trim(Dados.Nome);
  Dados.CodigoInterno := Trim(Dados.CodigoInterno);
  Dados.Slug := LowerCase(Trim(Dados.Slug));
  Dados.Modalidade := UpperCase(Trim(Dados.Modalidade));
  Dados.Situacao := UpperCase(Trim(Dados.Situacao));
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.Objetivo := Trim(Dados.Objetivo);
  Dados.ImagemUrl := Trim(Dados.ImagemUrl);

  if Dados.Nome.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do curso.'
    );

  if Length(Dados.Nome) > 200 then
    TAppErrors.RaiseBadRequest(
      'O nome do curso deve possuir no máximo 200 caracteres.'
    );

  if Dados.CargaHorariaMinutos <= 0 then
    TAppErrors.RaiseBadRequest(
      'A carga horária deve ser maior que zero.'
    );

  if not MatchText(
    Dados.Modalidade,
    ['PRESENCIAL', 'ONLINE', 'HIBRIDO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Modalidade inválida.'
    );

  if not MatchText(
    Dados.Situacao,
    ['RASCUNHO', 'ATIVO', 'INATIVO']
  ) then
    TAppErrors.RaiseBadRequest(
      'Situação inválida.'
    );

  if Length(Dados.CodigoInterno) > 50 then
    TAppErrors.RaiseBadRequest(
      'O código interno deve possuir no máximo 50 caracteres.'
    );

  if Length(Dados.Slug) > 160 then
    TAppErrors.RaiseBadRequest(
      'O slug deve possuir no máximo 160 caracteres.'
    );

  if Length(Dados.ImagemUrl) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL da imagem deve possuir no máximo 1000 caracteres.'
    );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    CursoAtual := TInstituicaoCursoDAO.BuscarPorId(
      Conn,
      AIdInstituicao,
      AIdCurso
    );

    try
      if CursoAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Curso não encontrado.'
        );

      // Categoria já vinculada pode permanecer mesmo se foi inativada depois.
      // Ao trocar de categoria, a nova precisa estar ATIVA no mesmo tenant.
      if (Dados.IdCategoria > 0) and
         (Dados.IdCategoria <> CursoAtual.IdCategoria) then
      begin
        if not TInstituicaoCursoCategoriaDAO.ExisteCategoriaAtiva(
          Conn,
          AIdInstituicao,
          Dados.IdCategoria
        ) then
          TAppErrors.RaiseBadRequest(
            'Categoria não encontrada, não pertence à instituição ou está inativa.'
          );
      end;

      if TInstituicaoCursoDAO.ExisteCodigoInterno(
        Conn,
        AIdInstituicao,
        Dados.CodigoInterno,
        AIdCurso
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe um curso com este código interno.'
        );

      if TInstituicaoCursoDAO.ExisteSlug(
        Conn,
        AIdInstituicao,
        Dados.Slug,
        AIdCurso
      ) then
        TAppErrors.RaiseBadRequest(
          'Já existe um curso com este slug.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoCursoDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdCurso,
          Dados
        );

        Result := TInstituicaoCursoDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          AIdCurso
        );

        if Result = nil then
          raise Exception.Create(
            'Curso atualizado, mas não foi possível recuperar seus dados.'
          );

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;

        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      CursoAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoService.Listar(
  const AIdInstituicao: Int64;
  const ABusca, ASituacao, AModalidade: string;
  const APagina, APorPagina: Integer
): TInstituicaoCursoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoCursoFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro := Default(TInstituicaoCursoFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Situacao := UpperCase(Trim(ASituacao));
  Filtro.Modalidade := UpperCase(Trim(AModalidade));

  Filtro.Pagina := APagina;
  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  Filtro.PorPagina := APorPagina;
  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    if not MatchText(
      Filtro.Situacao,
      ['RASCUNHO', 'ATIVO', 'INATIVO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Situação inválida.'
      );

  if not Filtro.Modalidade.IsEmpty then
    if not MatchText(
      Filtro.Modalidade,
      ['PRESENCIAL', 'ONLINE', 'HIBRIDO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Modalidade inválida.'
      );

  Config := TAppConfig.Carregar(
    ExtractFilePath(ParamStr(0)) + 'Config.ini'
  );

  Conn := TDatabaseConnection.NewConnection(
    Config.Database
  );

  try
    Result := TInstituicaoCursoDAO.Listar(
      Conn,
      AIdInstituicao,
      Filtro
    );
  finally
    Conn.Free;
  end;
end;

end.
