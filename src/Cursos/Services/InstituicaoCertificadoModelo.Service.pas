unit InstituicaoCertificadoModelo.Service;

interface

uses
  InstituicaoCertificadoModelo.Model;

type
  TInstituicaoCertificadoModeloService = class
  private
    class procedure ValidarNome(
      const ANome: string
    ); static;

    class procedure ValidarDescricao(
      const ADescricao: string
    ); static;

    class procedure ValidarImagemFundoUrl(
      const AImagemFundoUrl: string
    ); static;

    class procedure ValidarTemplateConfiguracao(
      const ATemplateConfiguracao: string
    ); static;

  public
    class function Listar(
      const AIdInstituicao: Int64;
      const ABusca,
            ASituacao: string;
      const APagina,
            APorPagina: Integer
    ): TInstituicaoCertificadoModeloLista; static;

    class function BuscarPorId(
      const AIdInstituicao,
            AIdModelo: Int64
    ): TInstituicaoCertificadoModeloItem; static;

    class function Cadastrar(
      const AIdInstituicao: Int64;
      const ADados: TInstituicaoCertificadoModeloCadastro
    ): TInstituicaoCertificadoModeloItem; static;

    class function Atualizar(
      const AIdInstituicao,
            AIdModelo: Int64;
      const ADados: TInstituicaoCertificadoModeloAlteracao
    ): TInstituicaoCertificadoModeloItem; static;

    class function AlterarSituacao(
      const AIdInstituicao,
            AIdModelo: Int64;
      const ASituacao: string
    ): TInstituicaoCertificadoModeloItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  System.JSON,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoCertificadoModelo.DAO;

class procedure TInstituicaoCertificadoModeloService.ValidarNome(
  const ANome: string
);
begin
  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Informe o nome do modelo de certificado.'
    );

  if Length(Trim(ANome)) > 120 then
    TAppErrors.RaiseBadRequest(
      'O nome do modelo deve possuir no máximo 120 caracteres.'
    );
end;

class procedure TInstituicaoCertificadoModeloService.ValidarDescricao(
  const ADescricao: string
);
begin
  if Length(Trim(ADescricao)) > 500 then
    TAppErrors.RaiseBadRequest(
      'A descrição deve possuir no máximo 500 caracteres.'
    );
end;

class procedure TInstituicaoCertificadoModeloService.ValidarImagemFundoUrl(
  const AImagemFundoUrl: string
);
begin
  if Length(Trim(AImagemFundoUrl)) > 1000 then
    TAppErrors.RaiseBadRequest(
      'A URL da imagem de fundo deve possuir no máximo 1000 caracteres.'
    );
end;

class procedure TInstituicaoCertificadoModeloService.ValidarTemplateConfiguracao(
  const ATemplateConfiguracao: string
);
var
  Json: TJSONValue;
begin
  if Trim(ATemplateConfiguracao).IsEmpty then
    Exit;

  Json :=
    TJSONObject.ParseJSONValue(
      ATemplateConfiguracao
    );

  try
    if Json = nil then
      TAppErrors.RaiseBadRequest(
        'A configuração do template deve conter um JSON válido.'
      );
  finally
    Json.Free;
  end;
end;

class function TInstituicaoCertificadoModeloService.Listar(
  const AIdInstituicao: Int64;
  const ABusca,
        ASituacao: string;
  const APagina,
        APorPagina: Integer
): TInstituicaoCertificadoModeloLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoCertificadoModeloFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Filtro :=
    Default(
      TInstituicaoCertificadoModeloFiltro
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
      ['ATIVO', 'INATIVO']
    ) then
      TAppErrors.RaiseBadRequest(
        'Situação inválida.'
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
    Result :=
      TInstituicaoCertificadoModeloDAO.Listar(
        Conn,
        AIdInstituicao,
        Filtro
      );
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoModeloService.BuscarPorId(
  const AIdInstituicao,
        AIdModelo: Int64
): TInstituicaoCertificadoModeloItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdModelo <= 0 then
    TAppErrors.RaiseBadRequest(
      'Modelo de certificado inválido.'
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
      TInstituicaoCertificadoModeloDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdModelo
      );

    if Result = nil then
      TAppErrors.RaiseBadRequest(
        'Modelo de certificado não encontrado.'
      );

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoModeloService.Cadastrar(
  const AIdInstituicao: Int64;
  const ADados: TInstituicaoCertificadoModeloCadastro
): TInstituicaoCertificadoModeloItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCertificadoModeloCadastro;
  IdModelo: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  Dados := ADados;

  Dados.Nome := Trim(Dados.Nome);
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.ImagemFundoUrl := Trim(Dados.ImagemFundoUrl);
  Dados.TemplateConfiguracao := Trim(Dados.TemplateConfiguracao);

  ValidarNome(Dados.Nome);
  ValidarDescricao(Dados.Descricao);
  ValidarImagemFundoUrl(Dados.ImagemFundoUrl);
  ValidarTemplateConfiguracao(Dados.TemplateConfiguracao);

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
      TInstituicaoCertificadoModeloDAO.ExisteNome(
        Conn,
        AIdInstituicao,
        Dados.Nome
      )
    then
      TAppErrors.RaiseBadRequest(
        'Já existe um modelo de certificado com este nome.'
      );

    Conn.StartTransaction;
    try
      IdModelo :=
        TInstituicaoCertificadoModeloDAO.Inserir(
          Conn,
          AIdInstituicao,
          Dados
        );

      Result :=
        TInstituicaoCertificadoModeloDAO.BuscarPorId(
          Conn,
          AIdInstituicao,
          IdModelo
        );

      if Result = nil then
        raise Exception.Create(
          'Modelo cadastrado, mas não foi possível recuperar os dados.'
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

class function TInstituicaoCertificadoModeloService.Atualizar(
  const AIdInstituicao,
        AIdModelo: Int64;
  const ADados: TInstituicaoCertificadoModeloAlteracao
): TInstituicaoCertificadoModeloItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoCertificadoModeloAlteracao;
  ModeloAtual: TInstituicaoCertificadoModeloItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdModelo <= 0 then
    TAppErrors.RaiseBadRequest(
      'Modelo de certificado inválido.'
    );

  Dados := ADados;

  Dados.Nome := Trim(Dados.Nome);
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.ImagemFundoUrl := Trim(Dados.ImagemFundoUrl);
  Dados.TemplateConfiguracao := Trim(Dados.TemplateConfiguracao);

  ValidarNome(Dados.Nome);
  ValidarDescricao(Dados.Descricao);
  ValidarImagemFundoUrl(Dados.ImagemFundoUrl);
  ValidarTemplateConfiguracao(Dados.TemplateConfiguracao);

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
    ModeloAtual :=
      TInstituicaoCertificadoModeloDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdModelo
      );

    try
      if ModeloAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Modelo de certificado não encontrado.'
        );

      if
        TInstituicaoCertificadoModeloDAO.ExisteNome(
          Conn,
          AIdInstituicao,
          Dados.Nome,
          AIdModelo
        )
      then
        TAppErrors.RaiseBadRequest(
          'Já existe um modelo de certificado com este nome.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoCertificadoModeloDAO.Atualizar(
          Conn,
          AIdInstituicao,
          AIdModelo,
          Dados
        );

        Result :=
          TInstituicaoCertificadoModeloDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdModelo
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o modelo atualizado.'
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
      ModeloAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

class function TInstituicaoCertificadoModeloService.AlterarSituacao(
  const AIdInstituicao,
        AIdModelo: Int64;
  const ASituacao: string
): TInstituicaoCertificadoModeloItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  ModeloAtual: TInstituicaoCertificadoModeloItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AIdModelo <= 0 then
    TAppErrors.RaiseBadRequest(
      'Modelo de certificado inválido.'
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
    ModeloAtual :=
      TInstituicaoCertificadoModeloDAO.BuscarPorId(
        Conn,
        AIdInstituicao,
        AIdModelo
      );

    try
      if ModeloAtual = nil then
        TAppErrors.RaiseBadRequest(
          'Modelo de certificado não encontrado.'
        );

      Conn.StartTransaction;
      try
        TInstituicaoCertificadoModeloDAO.AlterarSituacao(
          Conn,
          AIdInstituicao,
          AIdModelo,
          Situacao
        );

        Result :=
          TInstituicaoCertificadoModeloDAO.BuscarPorId(
            Conn,
            AIdInstituicao,
            AIdModelo
          );

        if Result = nil then
          raise Exception.Create(
            'Não foi possível recuperar o modelo atualizado.'
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
      ModeloAtual.Free;
    end;

  finally
    Conn.Free;
  end;
end;

end.
