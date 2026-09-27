unit RegistroEvento.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  RegistroEvento.Model;

type
  TRegistroEventoService = class
  private
    class function NormalizarNivel(const ANivel: string): string; static;
    class procedure ValidarRegistro(const ARegistro: TRegistroEventoModel); static;
  public
    class function Registrar(
      const ARegistro: TRegistroEventoModel
    ): Int64; overload; static;

    class function Registrar(
      const AIdEmpresa: Int64;
      const AIdUsuario: Int64;
      const AOrigem: string;
      const ATipo: string;
      const AEntidade: string;
      const AIdEntidade: Int64;
      const ATitulo: string;
      const AMensagem: string = '';
      const ADadosJson: string = '';
      const ANivel: string = 'INFO'
    ): Int64; overload; static;

    class function ListarPorEmpresa(
      const AIdEmpresa: Int64
    ): TObjectList<TRegistroEventoModel>; static;

    class function BuscarPorEntidade(
      const AIdEmpresa: Int64;
      const AEntidade: string;
      const AIdEntidade: Int64
    ): TObjectList<TRegistroEventoModel>; static;

    class procedure RegistrarPedidoCriado(
      const AIdEmpresa: Int64;
      const AIdPedido: Int64;
      const AValorTotal: Currency;
      const ANomeCliente: string
    ); static;

    class procedure RegistrarStatusPedidoAlterado(
      const AIdEmpresa: Int64;
      const AIdUsuario: Int64;
      const AIdPedido: Int64;
      const AStatus: string
    ); static;

    class procedure RegistrarLogin(
      const AIdEmpresa: Int64;
      const AIdUsuario: Int64;
      const AEmail: string
    ); static;

    class procedure RegistrarErro(
      const AIdEmpresa: Int64;
      const AOrigem: string;
      const AEntidade: string;
      const AIdEntidade: Int64;
      const ATitulo: string;
      const AMensagem: string
    ); static;
  end;

implementation

uses
  Uni,
  System.JSON,
  App.Config,
  APP.Errors,
  Database.Connection,
  RegistroEvento.DAO;

class function TRegistroEventoService.NormalizarNivel(const ANivel: string): string;
var
  Nivel: string;
begin
  Nivel := UpperCase(Trim(ANivel));

  if Nivel.IsEmpty then
    Nivel := 'INFO';

  if (Nivel <> 'INFO') and (Nivel <> 'WARN') and (Nivel <> 'ERROR') then
    Nivel := 'INFO';

  Result := Nivel;
end;

class procedure TRegistroEventoService.ValidarRegistro(const ARegistro: TRegistroEventoModel);
begin
  if ARegistro = nil then
    TAppErrors.RaiseBadRequest('Dados do registro não informados.');

  if Trim(ARegistro.Origem).IsEmpty then
    TAppErrors.RaiseBadRequest('Origem do registro não informada.');

  if Trim(ARegistro.Tipo).IsEmpty then
    TAppErrors.RaiseBadRequest('Tipo do registro não informado.');

  if Trim(ARegistro.Titulo).IsEmpty then
    TAppErrors.RaiseBadRequest('Título do registro não informado.');

  if Length(Trim(ARegistro.Origem)) > 50 then
    TAppErrors.RaiseBadRequest('Origem do registro deve possuir no máximo 50 caracteres.');

  if Length(Trim(ARegistro.Tipo)) > 50 then
    TAppErrors.RaiseBadRequest('Tipo do registro deve possuir no máximo 50 caracteres.');

  if Length(Trim(ARegistro.Entidade)) > 50 then
    TAppErrors.RaiseBadRequest('Entidade do registro deve possuir no máximo 50 caracteres.');

  if Length(Trim(ARegistro.Titulo)) > 150 then
    TAppErrors.RaiseBadRequest('Título do registro deve possuir no máximo 150 caracteres.');

  ARegistro.Origem := UpperCase(Trim(ARegistro.Origem));
  ARegistro.Tipo := UpperCase(Trim(ARegistro.Tipo));
  ARegistro.Entidade := LowerCase(Trim(ARegistro.Entidade));
  ARegistro.Titulo := Trim(ARegistro.Titulo);
  ARegistro.Mensagem := Trim(ARegistro.Mensagem);
  ARegistro.DadosJson := Trim(ARegistro.DadosJson);
  ARegistro.Nivel := NormalizarNivel(ARegistro.Nivel);
end;

class function TRegistroEventoService.Registrar(
  const ARegistro: TRegistroEventoModel
): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  ValidarRegistro(ARegistro);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TRegistroEventoDAO.Inserir(Conn, ARegistro);
  finally
    Conn.Free;
  end;
end;

class function TRegistroEventoService.Registrar(
  const AIdEmpresa: Int64;
  const AIdUsuario: Int64;
  const AOrigem: string;
  const ATipo: string;
  const AEntidade: string;
  const AIdEntidade: Int64;
  const ATitulo: string;
  const AMensagem: string;
  const ADadosJson: string;
  const ANivel: string
): Int64;
var
  Registro: TRegistroEventoModel;
begin
  Registro := TRegistroEventoModel.Create;
  try
    Registro.IdEmpresa := AIdEmpresa;
    Registro.IdUsuario := AIdUsuario;
    Registro.Origem := AOrigem;
    Registro.Tipo := ATipo;
    Registro.Entidade := AEntidade;
    Registro.IdEntidade := AIdEntidade;
    Registro.Titulo := ATitulo;
    Registro.Mensagem := AMensagem;
    Registro.DadosJson := ADadosJson;
    Registro.Nivel := ANivel;

    Result := Registrar(Registro);
  finally
    Registro.Free;
  end;
end;

class function TRegistroEventoService.ListarPorEmpresa(
  const AIdEmpresa: Int64
): TObjectList<TRegistroEventoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TRegistroEventoDAO.ListarPorEmpresa(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class function TRegistroEventoService.BuscarPorEntidade(
  const AIdEmpresa: Int64;
  const AEntidade: string;
  const AIdEntidade: Int64
): TObjectList<TRegistroEventoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if Trim(AEntidade).IsEmpty then
    TAppErrors.RaiseBadRequest('Entidade não informada.');

  if AIdEntidade <= 0 then
    TAppErrors.RaiseBadRequest('Identificador da entidade não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TRegistroEventoDAO.BuscarPorEntidade(Conn, AIdEmpresa, AEntidade, AIdEntidade);
  finally
    Conn.Free;
  end;
end;

class procedure TRegistroEventoService.RegistrarPedidoCriado(
  const AIdEmpresa: Int64;
  const AIdPedido: Int64;
  const AValorTotal: Currency;
  const ANomeCliente: string
);
var
  Dados: TJSONObject;
begin
  Dados := TJSONObject.Create;
  try
    Dados.AddPair('valor_total', TJSONNumber.Create(AValorTotal));
    Dados.AddPair('nome_cliente', Trim(ANomeCliente));

    Registrar(
      AIdEmpresa,
      0,
      'PUBLICO',
      'PEDIDO_CRIADO',
      'pedido',
      AIdPedido,
      'Novo pedido recebido',
      'Pedido recebido pelo catálogo público. Cliente: ' + Trim(ANomeCliente),
      Dados.ToJSON,
      'INFO'
    );
  finally
    Dados.Free;
  end;
end;

class procedure TRegistroEventoService.RegistrarStatusPedidoAlterado(
  const AIdEmpresa: Int64;
  const AIdUsuario: Int64;
  const AIdPedido: Int64;
  const AStatus: string
);
var
  Dados: TJSONObject;
begin
  Dados := TJSONObject.Create;
  try
    Dados.AddPair('status', UpperCase(Trim(AStatus)));

    Registrar(
      AIdEmpresa,
      AIdUsuario,
      'PAINEL',
      'STATUS_PEDIDO_ALTERADO',
      'pedido',
      AIdPedido,
      'Status do pedido alterado',
      'Pedido alterado para o status: ' + UpperCase(Trim(AStatus)),
      Dados.ToJSON,
      'INFO'
    );
  finally
    Dados.Free;
  end;
end;

class procedure TRegistroEventoService.RegistrarLogin(
  const AIdEmpresa: Int64;
  const AIdUsuario: Int64;
  const AEmail: string
);
begin
  Registrar(
    AIdEmpresa,
    AIdUsuario,
    'PAINEL',
    'LOGIN',
    'usuario',
    AIdUsuario,
    'Login realizado',
    'Login realizado pelo usuário: ' + LowerCase(Trim(AEmail)),
    '',
    'INFO'
  );
end;

class procedure TRegistroEventoService.RegistrarErro(
  const AIdEmpresa: Int64;
  const AOrigem: string;
  const AEntidade: string;
  const AIdEntidade: Int64;
  const ATitulo: string;
  const AMensagem: string
);
begin
  Registrar(
    AIdEmpresa,
    0,
    AOrigem,
    'ERRO',
    AEntidade,
    AIdEntidade,
    ATitulo,
    AMensagem,
    '',
    'ERROR'
  );
end;

end.
