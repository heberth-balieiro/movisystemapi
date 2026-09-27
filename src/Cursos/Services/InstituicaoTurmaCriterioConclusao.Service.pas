unit InstituicaoTurmaCriterioConclusao.Service;

interface

uses
  InstituicaoTurmaCriterioConclusao.Model;

type
  TInstituicaoTurmaCriterioConclusaoService = class
  private
    class procedure ValidarTipo(const ATipo: string); static;
    class procedure ValidarSituacao(const ASituacao: string); static;
    class procedure ValidarDados(const ATipo, ANome, AConfiguracao: string;
      const ATemConfiguracao: Boolean; const AOrdem: Integer); static;
  public
    class function Listar(const AIdInstituicao, AIdTurma: Int64;
      const ABusca, ATipo, ASituacao: string;
      const APagina, APorPagina: Integer): TInstituicaoTurmaCriterioConclusaoLista; static;
    class function BuscarPorId(const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64): TInstituicaoTurmaCriterioConclusaoItem; static;
    class function Cadastrar(const AIdInstituicao, AIdTurma: Int64;
      const ADados: TInstituicaoTurmaCriterioConclusaoCadastro): TInstituicaoTurmaCriterioConclusaoItem; static;
    class function Atualizar(const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64; const ADados: TInstituicaoTurmaCriterioConclusaoAlteracao): TInstituicaoTurmaCriterioConclusaoItem; static;
    class function AlterarSituacao(const AIdInstituicao, AIdTurma,
      AIdCriterio: Int64; const ASituacao: string): TInstituicaoTurmaCriterioConclusaoItem; static;
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
  InstituicaoTurmaCriterioConclusao.DAO;

class procedure TInstituicaoTurmaCriterioConclusaoService.ValidarTipo(
  const ATipo: string);
begin
  if not MatchText(
    UpperCase(Trim(ATipo)),
    ['PRESENCA_MINIMA', 'AULAS_CONCLUIDAS', 'AVALIACAO',
     'ATIVIDADE', 'APROVACAO_MANUAL', 'OUTRO']
  ) then
    TAppErrors.RaiseBadRequest('Tipo de critério inválido.');
end;

class procedure TInstituicaoTurmaCriterioConclusaoService.ValidarSituacao(
  const ASituacao: string);
begin
  if not MatchText(UpperCase(Trim(ASituacao)), ['ATIVO', 'INATIVO']) then
    TAppErrors.RaiseBadRequest('Situação inválida. Utilize ATIVO ou INATIVO.');
end;

class procedure TInstituicaoTurmaCriterioConclusaoService.ValidarDados(
  const ATipo, ANome, AConfiguracao: string;
  const ATemConfiguracao: Boolean; const AOrdem: Integer);
var
  JSONValue: TJSONValue;
begin
  ValidarTipo(ATipo);

  if Trim(ANome).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do critério.');

  if Length(Trim(ANome)) > 180 then
    TAppErrors.RaiseBadRequest('O nome deve possuir no máximo 180 caracteres.');

  if AOrdem <= 0 then
    TAppErrors.RaiseBadRequest('A ordem deve ser maior que zero.');

  if ATemConfiguracao then
  begin
    if Trim(AConfiguracao).IsEmpty then
      TAppErrors.RaiseBadRequest('A configuração informada é inválida.');

    JSONValue := TJSONObject.ParseJSONValue(AConfiguracao);
    try
      if JSONValue = nil then
        TAppErrors.RaiseBadRequest('A configuração deve conter um JSON válido.');
    finally
      JSONValue.Free;
    end;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoService.Listar(
  const AIdInstituicao, AIdTurma: Int64;
  const ABusca, ATipo, ASituacao: string;
  const APagina, APorPagina: Integer): TInstituicaoTurmaCriterioConclusaoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoTurmaCriterioConclusaoFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Filtro := Default(TInstituicaoTurmaCriterioConclusaoFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Tipo := UpperCase(Trim(ATipo));
  Filtro.Situacao := UpperCase(Trim(ASituacao));
  Filtro.Pagina := APagina;
  Filtro.PorPagina := APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Tipo.IsEmpty then
    ValidarTipo(Filtro.Tipo);

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacao(Filtro.Situacao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TInstituicaoTurmaCriterioConclusaoDAO.TurmaExiste(
      Conn, AIdInstituicao, AIdTurma) then
      TAppErrors.RaiseBadRequest('Turma não encontrada.');

    Result := TInstituicaoTurmaCriterioConclusaoDAO.Listar(
      Conn, AIdInstituicao, AIdTurma, Filtro);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoService.BuscarPorId(
  const AIdInstituicao, AIdTurma,
  AIdCriterio: Int64): TInstituicaoTurmaCriterioConclusaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdCriterio <= 0) then
    TAppErrors.RaiseBadRequest('Critério inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Result := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdCriterio);

    if Result = nil then
      TAppErrors.RaiseBadRequest('Critério não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoService.Cadastrar(
  const AIdInstituicao, AIdTurma: Int64;
  const ADados: TInstituicaoTurmaCriterioConclusaoCadastro): TInstituicaoTurmaCriterioConclusaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaCriterioConclusaoCadastro;
  IdCriterio: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Dados := ADados;
  Dados.Tipo := UpperCase(Trim(Dados.Tipo));
  Dados.Nome := Trim(Dados.Nome);

  ValidarDados(Dados.Tipo, Dados.Nome, Dados.Configuracao,
    Dados.TemConfiguracao, Dados.Ordem);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TInstituicaoTurmaCriterioConclusaoDAO.TurmaExiste(
      Conn, AIdInstituicao, AIdTurma) then
      TAppErrors.RaiseBadRequest('Turma não encontrada.');

    Conn.StartTransaction;
    try
      IdCriterio := TInstituicaoTurmaCriterioConclusaoDAO.Inserir(
        Conn, AIdInstituicao, AIdTurma, Dados);

      Result := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
        Conn, AIdInstituicao, AIdTurma, IdCriterio);

      if Result = nil then
        raise Exception.Create('Critério cadastrado, mas não foi possível recuperar os dados.');

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

class function TInstituicaoTurmaCriterioConclusaoService.Atualizar(
  const AIdInstituicao, AIdTurma, AIdCriterio: Int64;
  const ADados: TInstituicaoTurmaCriterioConclusaoAlteracao): TInstituicaoTurmaCriterioConclusaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaCriterioConclusaoAlteracao;
  Atual: TInstituicaoTurmaCriterioConclusaoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdCriterio <= 0) then
    TAppErrors.RaiseBadRequest('Critério inválido.');

  Dados := ADados;
  Dados.Tipo := UpperCase(Trim(Dados.Tipo));
  Dados.Nome := Trim(Dados.Nome);

  ValidarDados(Dados.Tipo, Dados.Nome, Dados.Configuracao,
    Dados.TemConfiguracao, Dados.Ordem);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Atual := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdCriterio);
    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Critério não encontrado.');

      Conn.StartTransaction;
      try
        TInstituicaoTurmaCriterioConclusaoDAO.Atualizar(
          Conn, AIdInstituicao, AIdTurma, AIdCriterio, Dados);

        Result := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
          Conn, AIdInstituicao, AIdTurma, AIdCriterio);

        if Result = nil then
          raise Exception.Create('Não foi possível recuperar o critério atualizado.');

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaCriterioConclusaoService.AlterarSituacao(
  const AIdInstituicao, AIdTurma, AIdCriterio: Int64;
  const ASituacao: string): TInstituicaoTurmaCriterioConclusaoItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TInstituicaoTurmaCriterioConclusaoItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdCriterio <= 0) then
    TAppErrors.RaiseBadRequest('Critério inválido.');

  Situacao := UpperCase(Trim(ASituacao));
  ValidarSituacao(Situacao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Atual := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdCriterio);
    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Critério não encontrado.');

      Conn.StartTransaction;
      try
        TInstituicaoTurmaCriterioConclusaoDAO.AlterarSituacao(
          Conn, AIdInstituicao, AIdTurma, AIdCriterio, Situacao);

        Result := TInstituicaoTurmaCriterioConclusaoDAO.BuscarPorId(
          Conn, AIdInstituicao, AIdTurma, AIdCriterio);

        if Result = nil then
          raise Exception.Create('Não foi possível recuperar o critério atualizado.');

        Conn.Commit;
      except
        if Conn.InTransaction then
          Conn.Rollback;
        Result.Free;
        Result := nil;
        raise;
      end;
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
