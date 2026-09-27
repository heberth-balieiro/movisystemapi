unit InstituicaoTurmaEncontro.Service;

interface

uses
  InstituicaoTurmaEncontro.Model;

type
  TInstituicaoTurmaEncontroService = class
  private
    class procedure ValidarDados(const ATitulo, ADescricao: string;
      const ADataHoraInicio, ADataHoraFim: TDateTime;
      const ACargaHorariaMinutos: Integer;
      const ALocal, AUrlOnline: string); static;
    class procedure ValidarSituacao(const ASituacao: string); static;
  public
    class function Listar(const AIdInstituicao, AIdTurma: Int64;
      const ABusca, ASituacao: string; const APagina, APorPagina: Integer): TInstituicaoTurmaEncontroLista; static;
    class function BuscarPorId(const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64): TInstituicaoTurmaEncontroItem; static;
    class function Cadastrar(const AIdInstituicao, AIdTurma: Int64;
      const ADados: TInstituicaoTurmaEncontroCadastro): TInstituicaoTurmaEncontroItem; static;
    class function Atualizar(const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64; const ADados: TInstituicaoTurmaEncontroAlteracao): TInstituicaoTurmaEncontroItem; static;
    class function AlterarSituacao(const AIdInstituicao, AIdTurma,
      AIdEncontro: Int64; const ASituacao: string): TInstituicaoTurmaEncontroItem; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoTurmaEncontro.DAO;

class procedure TInstituicaoTurmaEncontroService.ValidarDados(
  const ATitulo, ADescricao: string;
  const ADataHoraInicio, ADataHoraFim: TDateTime;
  const ACargaHorariaMinutos: Integer;
  const ALocal, AUrlOnline: string);
begin
  if Trim(ATitulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o título do encontro.');

  if Length(Trim(ATitulo)) > 180 then
    TAppErrors.RaiseBadRequest('O título deve possuir no máximo 180 caracteres.');

  if Length(Trim(ADescricao)) > 500 then
    TAppErrors.RaiseBadRequest('A descrição deve possuir no máximo 500 caracteres.');

  if ADataHoraInicio <= 0 then
    TAppErrors.RaiseBadRequest('Informe a data/hora de início.');

  if ADataHoraFim <= 0 then
    TAppErrors.RaiseBadRequest('Informe a data/hora de término.');

  if ADataHoraFim < ADataHoraInicio then
    TAppErrors.RaiseBadRequest('A data/hora de término não pode ser anterior ao início.');

  if ACargaHorariaMinutos < 0 then
    TAppErrors.RaiseBadRequest('A carga horária não pode ser negativa.');

  if Length(Trim(ALocal)) > 255 then
    TAppErrors.RaiseBadRequest('O local deve possuir no máximo 255 caracteres.');

  if Length(Trim(AUrlOnline)) > 1000 then
    TAppErrors.RaiseBadRequest('A URL online deve possuir no máximo 1000 caracteres.');
end;

class procedure TInstituicaoTurmaEncontroService.ValidarSituacao(
  const ASituacao: string);
begin
  if not MatchText(UpperCase(Trim(ASituacao)), ['AGENDADO', 'REALIZADO', 'CANCELADO']) then
    TAppErrors.RaiseBadRequest('Situação inválida. Utilize AGENDADO, REALIZADO ou CANCELADO.');
end;

class function TInstituicaoTurmaEncontroService.Listar(
  const AIdInstituicao, AIdTurma: Int64;
  const ABusca, ASituacao: string;
  const APagina, APorPagina: Integer): TInstituicaoTurmaEncontroLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Filtro: TInstituicaoTurmaEncontroFiltro;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Filtro := Default(TInstituicaoTurmaEncontroFiltro);
  Filtro.Busca := Trim(ABusca);
  Filtro.Situacao := UpperCase(Trim(ASituacao));
  Filtro.Pagina := APagina;
  Filtro.PorPagina := APorPagina;

  if Filtro.Pagina <= 0 then
    Filtro.Pagina := 1;

  if Filtro.PorPagina <= 0 then
    Filtro.PorPagina := 20;

  if Filtro.PorPagina > 100 then
    Filtro.PorPagina := 100;

  if not Filtro.Situacao.IsEmpty then
    ValidarSituacao(Filtro.Situacao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TInstituicaoTurmaEncontroDAO.TurmaExiste(Conn, AIdInstituicao, AIdTurma) then
      TAppErrors.RaiseBadRequest('Turma não encontrada.');

    Result := TInstituicaoTurmaEncontroDAO.Listar(
      Conn, AIdInstituicao, AIdTurma, Filtro);
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaEncontroService.BuscarPorId(
  const AIdInstituicao, AIdTurma, AIdEncontro: Int64): TInstituicaoTurmaEncontroItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest('Encontro inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Result := TInstituicaoTurmaEncontroDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdEncontro);

    if Result = nil then
      TAppErrors.RaiseBadRequest('Encontro não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TInstituicaoTurmaEncontroService.Cadastrar(
  const AIdInstituicao, AIdTurma: Int64;
  const ADados: TInstituicaoTurmaEncontroCadastro): TInstituicaoTurmaEncontroItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaEncontroCadastro;
  IdEncontro: Int64;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if AIdTurma <= 0 then
    TAppErrors.RaiseBadRequest('Turma inválida.');

  Dados := ADados;
  Dados.Titulo := Trim(Dados.Titulo);
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.Local := Trim(Dados.Local);
  Dados.UrlOnline := Trim(Dados.UrlOnline);

  ValidarDados(Dados.Titulo, Dados.Descricao, Dados.DataHoraInicio,
    Dados.DataHoraFim, Dados.CargaHorariaMinutos, Dados.Local, Dados.UrlOnline);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    if not TInstituicaoTurmaEncontroDAO.TurmaExiste(Conn, AIdInstituicao, AIdTurma) then
      TAppErrors.RaiseBadRequest('Turma não encontrada.');

    Conn.StartTransaction;
    try
      IdEncontro := TInstituicaoTurmaEncontroDAO.Inserir(
        Conn, AIdInstituicao, AIdTurma, Dados);

      Result := TInstituicaoTurmaEncontroDAO.BuscarPorId(
        Conn, AIdInstituicao, AIdTurma, IdEncontro);

      if Result = nil then
        raise Exception.Create('Encontro cadastrado, mas não foi possível recuperar os dados.');

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

class function TInstituicaoTurmaEncontroService.Atualizar(
  const AIdInstituicao, AIdTurma, AIdEncontro: Int64;
  const ADados: TInstituicaoTurmaEncontroAlteracao): TInstituicaoTurmaEncontroItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Dados: TInstituicaoTurmaEncontroAlteracao;
  Atual: TInstituicaoTurmaEncontroItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest('Encontro inválido.');

  Dados := ADados;
  Dados.Titulo := Trim(Dados.Titulo);
  Dados.Descricao := Trim(Dados.Descricao);
  Dados.Local := Trim(Dados.Local);
  Dados.UrlOnline := Trim(Dados.UrlOnline);

  ValidarDados(Dados.Titulo, Dados.Descricao, Dados.DataHoraInicio,
    Dados.DataHoraFim, Dados.CargaHorariaMinutos, Dados.Local, Dados.UrlOnline);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Atual := TInstituicaoTurmaEncontroDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdEncontro);

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Encontro não encontrado.');

      Conn.StartTransaction;
      try
        TInstituicaoTurmaEncontroDAO.Atualizar(
          Conn, AIdInstituicao, AIdTurma, AIdEncontro, Dados);

        Result := TInstituicaoTurmaEncontroDAO.BuscarPorId(
          Conn, AIdInstituicao, AIdTurma, AIdEncontro);

        if Result = nil then
          raise Exception.Create('Não foi possível recuperar o encontro atualizado.');

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

class function TInstituicaoTurmaEncontroService.AlterarSituacao(
  const AIdInstituicao, AIdTurma, AIdEncontro: Int64;
  const ASituacao: string): TInstituicaoTurmaEncontroItem;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Atual: TInstituicaoTurmaEncontroItem;
begin
  Result := nil;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized('Instituição não identificada.');

  if (AIdTurma <= 0) or (AIdEncontro <= 0) then
    TAppErrors.RaiseBadRequest('Encontro inválido.');

  Situacao := UpperCase(Trim(ASituacao));
  ValidarSituacao(Situacao);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);

  try
    Atual := TInstituicaoTurmaEncontroDAO.BuscarPorId(
      Conn, AIdInstituicao, AIdTurma, AIdEncontro);

    try
      if Atual = nil then
        TAppErrors.RaiseBadRequest('Encontro não encontrado.');

      Conn.StartTransaction;
      try
        TInstituicaoTurmaEncontroDAO.AlterarSituacao(
          Conn, AIdInstituicao, AIdTurma, AIdEncontro, Situacao);

        Result := TInstituicaoTurmaEncontroDAO.BuscarPorId(
          Conn, AIdInstituicao, AIdTurma, AIdEncontro);

        if Result = nil then
          raise Exception.Create('Não foi possível recuperar o encontro atualizado.');

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
