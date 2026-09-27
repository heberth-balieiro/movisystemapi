unit Segmento.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Segmento.Model;

type
  TSegmentoService = class
  private
    class function NormalizarSN(const AValor: string): string; static;
    class procedure ValidarSegmento(const ASegmento: TSegmentoModel); static;
  public
    class function Listar(const APesquisa: string = ''): TObjectList<TSegmentoModel>; static;
    class function Buscar(const AIdSegmento: Int64): TSegmentoModel; static;
    class function Inserir(const ASegmento: TSegmentoModel): Int64; static;
    class procedure Atualizar(const AIdSegmento: Int64;const ASegmento: TSegmentoModel); static;
    class procedure Excluir(const AIdSegmento: Int64); static;

    class function ListarSegmentoDash:TObjectList<TSegmentoModel>; static;
  end;

implementation

uses
  App.Config,
  APP.Errors,
  Database.Connection,
  Segmento.DAO,
  Uni;

class function TSegmentoService.NormalizarSN(const AValor: string): string;
begin
  Result := UpperCase(Trim(AValor));

  if not (Result = 'S') and not (Result = 'N') then
    Result := 'S';
end;

class procedure TSegmentoService.ValidarSegmento(const ASegmento: TSegmentoModel);
begin
  if not Assigned(ASegmento) then
    TAppErrors.RaiseBadRequest('Dados do segmento não foram informados.');

  ASegmento.Nome := Trim(ASegmento.Nome);
  ASegmento.Descricao := Trim(ASegmento.Descricao);
  ASegmento.Ativo := NormalizarSN(ASegmento.Ativo);

  if ASegmento.Nome = '' then
    TAppErrors.RaiseBadRequest('Informe o nome do segmento.');

  if Length(ASegmento.Nome) > 100 then
    TAppErrors.RaiseBadRequest('O nome do segmento deve ter no máximo 100 caracteres.');

  if Length(ASegmento.Descricao) > 255 then
    TAppErrors.RaiseBadRequest('A descrição do segmento deve ter no máximo 255 caracteres.');

  if ASegmento.Ordem < 0 then
    ASegmento.Ordem := 0;
end;

class function TSegmentoService.Listar(const APesquisa: string = ''): TObjectList<TSegmentoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TSegmentoDAO.Listar(Conn, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TSegmentoService.ListarSegmentoDash: TObjectList<TSegmentoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TSegmentoDAO.ListarDash(Conn);
  finally
    Conn.Free;
  end;
end;

class function TSegmentoService.Buscar(const AIdSegmento: Int64): TSegmentoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin

  if AIdSegmento <= 0 then
    TAppErrors.RaiseBadRequest('Segmento inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TSegmentoDAO.BuscarPorId(Conn, AIdSegmento);

    if not Assigned(Result) then
      TAppErrors.RaiseNotFound('Segmento não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TSegmentoService.Inserir(const ASegmento: TSegmentoModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  ValidarSegmento(ASegmento);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TSegmentoDAO.ExisteNome(Conn, ASegmento.Nome) then
      TAppErrors.RaiseBadRequest('Já existe um segmento cadastrado com este nome.');

    Result := TSegmentoDAO.Inserir(Conn, ASegmento);
  finally
    Conn.Free;
  end;
end;

class procedure TSegmentoService.Atualizar(const AIdSegmento: Int64;const ASegmento: TSegmentoModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TSegmentoModel;
begin

  if AIdSegmento <= 0 then
    TAppErrors.RaiseBadRequest('Segmento inválido.');

  ValidarSegmento(ASegmento);

  ASegmento.IdSegmento := AIdSegmento;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TSegmentoDAO.BuscarPorId(Conn, AIdSegmento);
    try
      if not Assigned(Atual) then
        TAppErrors.RaiseNotFound('Segmento não encontrado.');

      if TSegmentoDAO.ExisteNome(Conn, ASegmento.Nome, AIdSegmento) then
        TAppErrors.RaiseBadRequest('Já existe outro segmento cadastrado com este nome.');

      TSegmentoDAO.Atualizar(Conn, ASegmento);
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TSegmentoService.Excluir(const AIdSegmento: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TSegmentoModel;
begin

  if AIdSegmento <= 0 then
    TAppErrors.RaiseBadRequest('Segmento inválido.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TSegmentoDAO.BuscarPorId(Conn, AIdSegmento);
    try
      if not Assigned(Atual) then
        TAppErrors.RaiseNotFound('Segmento não encontrado.');

      if TSegmentoDAO.SegmentoPossuiCatalogo(Conn, 0, AIdSegmento) then
        TAppErrors.RaiseBadRequest('Este segmento está vinculado a um catálogo e não pode ser excluído.');

      if not TSegmentoDAO.Excluir(Conn, AIdSegmento) then
        TAppErrors.RaiseBadRequest('Não foi possível excluir o segmento.');
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
