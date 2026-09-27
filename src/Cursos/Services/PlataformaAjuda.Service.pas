unit PlataformaAjuda.Service;

interface

uses
  System.Generics.Collections,
  PlataformaAjuda.Model;

type
  TPlataformaAjudaService = class
  private
    class procedure Validar(const AModel: TPlataformaAjudaModel); static;
    class function UrlYoutubeValida(const AUrl: string): Boolean; static;
  public
    class function Listar(
      const APesquisa,
            ASituacao: string
    ): TObjectList<TPlataformaAjudaModel>; static;

    class function ListarAtivas: TObjectList<TPlataformaAjudaModel>; static;

    class function Buscar(const AId: Int64): TPlataformaAjudaModel; static;

    class function Criar(
      const AModel: TPlataformaAjudaModel;
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TPlataformaAjudaModel; static;

    class function Atualizar(
      const AId: Int64;
      const AModel: TPlataformaAjudaModel;
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TPlataformaAjudaModel; static;

    class function AlterarSituacao(
      const AId: Int64;
      const ASituacao: string;
      const AIdUsuario: Int64;
      const AIP,
            AUserAgent: string
    ): TPlataformaAjudaModel; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  PlataformaAjuda.DAO;

class function TPlataformaAjudaService.UrlYoutubeValida(
  const AUrl: string
): Boolean;
var
  Url: string;
begin
  Url := LowerCase(Trim(AUrl));
  Result :=
    Url.StartsWith('https://www.youtube.com/') or
    Url.StartsWith('https://youtube.com/') or
    Url.StartsWith('https://youtu.be/') or
    Url.StartsWith('https://m.youtube.com/');
end;

class procedure TPlataformaAjudaService.Validar(
  const AModel: TPlataformaAjudaModel
);
begin
  AModel.UrlYoutube := Trim(AModel.UrlYoutube);
  AModel.Assunto := Trim(AModel.Assunto);
  AModel.Descricao := Trim(AModel.Descricao);
  AModel.Situacao := UpperCase(Trim(AModel.Situacao));

  if AModel.Assunto.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o assunto da ajuda.');

  if Length(AModel.Assunto) > 180 then
    TAppErrors.RaiseBadRequest('O assunto deve possuir no maximo 180 caracteres.');

  if AModel.Descricao.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a descricao da ajuda.');

  if AModel.UrlYoutube.IsEmpty or not UrlYoutubeValida(AModel.UrlYoutube) then
    TAppErrors.RaiseBadRequest('Informe uma URL valida do YouTube.');

  if Length(AModel.UrlYoutube) > 1000 then
    TAppErrors.RaiseBadRequest('A URL do YouTube excede o tamanho permitido.');

  if not SameText(AModel.Situacao, 'ATIVO') and
     not SameText(AModel.Situacao, 'INATIVO') then
    TAppErrors.RaiseBadRequest('Situacao invalida.');

  if AModel.Ordem < 0 then
    TAppErrors.RaiseBadRequest('A ordem nao pode ser negativa.');
end;

class function TPlataformaAjudaService.Listar(
  const APesquisa,
        ASituacao: string
): TObjectList<TPlataformaAjudaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
begin
  Situacao := UpperCase(Trim(ASituacao));
  if not Situacao.IsEmpty and
     not SameText(Situacao, 'ATIVO') and
     not SameText(Situacao, 'INATIVO') then
    TAppErrors.RaiseBadRequest('Situacao invalida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaAjudaDAO.Listar(Conn, APesquisa, Situacao, False);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaAjudaService.ListarAtivas: TObjectList<TPlataformaAjudaModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaAjudaDAO.Listar(Conn, '', '', True);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaAjudaService.Buscar(
  const AId: Int64
): TPlataformaAjudaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda invalida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPlataformaAjudaDAO.BuscarPorId(Conn, AId);
    if Result = nil then
      TAppErrors.RaiseNotFound('Ajuda nao encontrada.');
  finally
    Conn.Free;
  end;
end;

class function TPlataformaAjudaService.Criar(
  const AModel: TPlataformaAjudaModel;
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TPlataformaAjudaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;
  Validar(AModel);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      AModel.Id := TPlataformaAjudaDAO.Inserir(Conn, AModel);
      TPlataformaAjudaDAO.RegistrarAuditoria(
        Conn, AIdUsuario, AModel.Id, 'AJUDA_CRIADA',
        'Ajuda ' + AModel.Assunto + ' cadastrada.',
        'POST', '/v1/certifica/plataforma/ajudas', AIP, AUserAgent
      );
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaAjudaDAO.BuscarPorId(Conn, AModel.Id);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaAjudaService.Atualizar(
  const AId: Int64;
  const AModel: TPlataformaAjudaModel;
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TPlataformaAjudaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Existente: TPlataformaAjudaModel;
begin
  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda invalida.');

  AModel.Id := AId;
  Validar(AModel);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Existente := TPlataformaAjudaDAO.BuscarPorId(Conn, AId);
    if Existente = nil then
      TAppErrors.RaiseNotFound('Ajuda nao encontrada.');
    Existente.Free;

    Conn.StartTransaction;
    try
      TPlataformaAjudaDAO.Atualizar(Conn, AModel);
      TPlataformaAjudaDAO.RegistrarAuditoria(
        Conn, AIdUsuario, AId, 'AJUDA_ALTERADA',
        'Ajuda ' + AModel.Assunto + ' atualizada.',
        'PUT', '/v1/certifica/plataforma/ajudas/' + AId.ToString, AIP, AUserAgent
      );
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaAjudaDAO.BuscarPorId(Conn, AId);
  finally
    Conn.Free;
  end;
end;

class function TPlataformaAjudaService.AlterarSituacao(
  const AId: Int64;
  const ASituacao: string;
  const AIdUsuario: Int64;
  const AIP,
        AUserAgent: string
): TPlataformaAjudaModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Situacao: string;
  Existente: TPlataformaAjudaModel;
begin
  if AId <= 0 then
    TAppErrors.RaiseBadRequest('Ajuda invalida.');

  Situacao := UpperCase(Trim(ASituacao));
  if not SameText(Situacao, 'ATIVO') and
     not SameText(Situacao, 'INATIVO') then
    TAppErrors.RaiseBadRequest('Situacao invalida.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Existente := TPlataformaAjudaDAO.BuscarPorId(Conn, AId);
    if Existente = nil then
      TAppErrors.RaiseNotFound('Ajuda nao encontrada.');
    Existente.Free;

    Conn.StartTransaction;
    try
      TPlataformaAjudaDAO.AtualizarSituacao(Conn, AId, Situacao);
      TPlataformaAjudaDAO.RegistrarAuditoria(
        Conn, AIdUsuario, AId, 'AJUDA_SITUACAO_ALTERADA',
        'Situacao da ajuda alterada para ' + Situacao + '.',
        'PATCH', '/v1/certifica/plataforma/ajudas/' + AId.ToString + '/situacao',
        AIP, AUserAgent
      );
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;

    Result := TPlataformaAjudaDAO.BuscarPorId(Conn, AId);
  finally
    Conn.Free;
  end;
end;

end.
