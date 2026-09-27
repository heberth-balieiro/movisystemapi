unit InstituicaoCursoCategoria.Service;

interface

uses
  InstituicaoCursoCategoria.Model,
  InstituicaoCursoCategoria.DAO;

type
  TInstituicaoCursoCategoriaService = class
  private
    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarDescricao(
      const ADescricao: string
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoCursoCategoriaLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdCategoria: Int64
    ): TInstituicaoCursoCategoriaItem; static;

    class function Cadastrar(
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoCursoCategoriaCadastro
    ): TInstituicaoCursoCategoriaItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdCategoria: Int64;
      const ADados: TInstituicaoCursoCategoriaAlteracao
    ): TInstituicaoCursoCategoriaItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdCategoria: Int64;
      const ASituacao: string
    ): TInstituicaoCursoCategoriaItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection;

class procedure TInstituicaoCursoCategoriaService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome da categoria.'
    );

  if Length(Trim(ANome)) > 120 then
    TAppErrors.RaiseBadRequest(
      'O nome da categoria deve possuir no máximo 120 caracteres.'
    );
end;

class procedure TInstituicaoCursoCategoriaService.ValidarDescricao(
  const ADescricao: string
);
begin
  if Length(Trim(ADescricao)) > 500 then
    TAppErrors.RaiseBadRequest(
      'A descrição deve possuir no máximo 500 caracteres.'
    );
end;

class function TInstituicaoCursoCategoriaService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoCursoCategoriaLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoCursoCategoriaFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoCursoCategoriaFiltro
    );

  Filtro.Busca :=
    Trim(ABusca);

  Filtro.Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

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
  begin
    if not MatchText(
      Filtro.Situacao,
      ['ATIVA', 'INATIVA']
    ) then
    begin
      TAppErrors.RaiseBadRequest(
        'Situação inválida.'
      );
    end;
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
    Result :=
      TInstituicaoCursoCategoriaDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoCategoriaService.BuscarPorId(
  const AIdInstituicao,
        AIdCategoria: Int64
): TInstituicaoCursoCategoriaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest(
      'Categoria inválida.'
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
      TInstituicaoCursoCategoriaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCategoria
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Categoria não encontrada.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoCategoriaService.Cadastrar(
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoCursoCategoriaCadastro
): TInstituicaoCursoCategoriaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCursoCategoriaCadastro;
  IdCategoria: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Dados :=
    ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Descricao :=
    Trim(Dados.Descricao);

  ValidarNome(
    Dados.Nome
  );

  ValidarDescricao(
    Dados.Descricao
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

    if
      TInstituicaoCursoCategoriaDAO.ExisteNome(
        Conn,
        AIdInstituicao,
        Dados.Nome
      )
    then
    begin
      TAppErrors.RaiseBadRequest(
        'Já existe uma categoria com este nome.'
      );
    end;

    Conn.StartTransaction;
    try
      IdCategoria :=
        TInstituicaoCursoCategoriaDAO.Inserir(
          Conn,
          AIdInstituicao,
          Dados
        );

      Result :=
        TInstituicaoCursoCategoriaDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdCategoria
        );

      if Result = nil then
        raise Exception.Create(
          'Categoria cadastrada, mas não foi possível recuperar os dados.'
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

class function TInstituicaoCursoCategoriaService.Atualizar(
  const AIdInstituicao,
        AIdCategoria: Int64;
  const ADados: TInstituicaoCursoCategoriaAlteracao
): TInstituicaoCursoCategoriaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCursoCategoriaAlteracao;
  CategoriaAtual: TInstituicaoCursoCategoriaItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest(
      'Categoria inválida.'
    );

  Dados :=
    ADados;

  Dados.Nome :=
    Trim(Dados.Nome);

  Dados.Descricao :=
    Trim(Dados.Descricao);

  ValidarNome(
    Dados.Nome
  );

  ValidarDescricao(
    Dados.Descricao
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
    CategoriaAtual :=
      TInstituicaoCursoCategoriaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCategoria
      );

    try
      if CategoriaAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Categoria não encontrada.'
        );

      if
        TInstituicaoCursoCategoriaDAO.ExisteNome(
          Conn,
          AIdInstituicao,
          Dados.Nome,
          AIdCategoria
        )
      then
      begin
        TAppErrors.RaiseBadRequest(
          'Já existe uma categoria com este nome.'
        );
      end;

      Conn.StartTransaction;
      try
        TInstituicaoCursoCategoriaDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdCategoria,
          Dados
        );

        Result :=
          TInstituicaoCursoCategoriaDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdCategoria
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar a categoria atualizada.'
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
      CategoriaAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCursoCategoriaService.AlterarSituacao(
  const AIdInstituicao,
        AIdCategoria: Int64;
  const ASituacao: string
): TInstituicaoCursoCategoriaItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  CategoriaAtual: TInstituicaoCursoCategoriaItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdCategoria <= 0 then
    TAppErrors.RaiseBadRequest(
      'Categoria inválida.'
    );

  Situacao :=
    UpperCase(
      Trim(ASituacao)
    );

  if not MatchText(
    Situacao,
    ['ATIVA', 'INATIVA']
  ) then
  begin
    TAppErrors.RaiseBadRequest(
      'Situação inválida. Utilize ATIVA ou INATIVA.'
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
    CategoriaAtual :=
      TInstituicaoCursoCategoriaDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdCategoria
      );

    try
      if CategoriaAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Categoria não encontrada.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoCursoCategoriaDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdCategoria,
          Situacao
        );

        Result :=
          TInstituicaoCursoCategoriaDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdCategoria
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar a categoria.'
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
      CategoriaAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
