unit Cupom.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Cupom.Model;

type
  TCupomService = class
  private
    class function NormalizarSN(const AValor, APadrao: string): string; static;
    class procedure Validar(const ACupom: TCupomModel); static;
    class function NormalizarTipodesconto(const AValor: String): String; static;

  Public
    class function Listar(const AIdEmpresa: Integer; const APesquisa: string): TObjectList<TCupomModel>; static;
    class function Buscar(const AIdEmpresa, AIdCupom: Int64): TCupomModel; static;

    class function Inserir(Const AIdEmpresa: Int64; const ACupom: TCupomModel): Int64; static;
    class procedure Atualizar(const AIdEmpresa, AIdCupom: Int64; const ACupom: TCupomModel); static;
    class procedure Excluir(const AIdEmpresa, AIdCupom: Int64);

end;

implementation

uses
  Cupom.DAO,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection;

{ TCupomService }

class procedure TCupomService.Atualizar(const AIdEmpresa, AIdCupom: Int64;const ACupom: TCupomModel);
var
  Config: TAppApiConfig;
  Conn        : TUniConnection;
  ACupomAtual: TCupomModel;
begin

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não identificada.');

  if AIdCupom <= 0 then
    TAppErrors.RaiseBadRequest('Cupom não informado.');

  if ACupom = nil then
    TAppErrors.RaiseBadRequest('Dados do cupom não informado.');

  ACupom.id_cupom := AIdcupom;
  Validar(ACupom);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    ACupomAtual := TCupomDAO.BuscarPorId(Conn,AIdEmpresa, AIdCupom);
    try
      if ACupomAtual = nil then
        TAppErrors.RaiseNotFound('Cupom não encontrado.');

      if TCupomDAO.ExisteNome(Conn, AIdEmpresa, ACupom.codigo, AIdCupom) then
        TAppErrors.RaiseBadRequest('Já existe outro cupom com este código.');

      TcupomDAO.Atualizar(Conn, AIdEmpresa, AIdcupom, Acupom);
    finally
      ACupomAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TCupomService.Buscar(const AIdEmpresa,AIdCupom: Int64): TCupomModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := nil;

  if AIdCupom <= 0 then
    TAppErrors.RaiseBadRequest('Cupom não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCupomDAO.BuscarPorId(Conn, AIdEmpresa, AIdCupom);

    if Result = nil then
      TAppErrors.RaiseNotFound('Cupom não encontrado.');
  finally
    Conn.Free;
  end;
end;

class procedure TCupomService.Excluir(const AIdEmpresa, AIdCupom: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  CupomAtual: TCupomModel;
begin

  if AIdCupom <= 0 then
    TAppErrors.RaiseBadRequest('Cupom não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    CupomAtual := TCupomDAO.BuscarPorId(Conn, AIdEmpresa, AIdCupom);
    try
      if CupomAtual = nil then
        TAppErrors.RaiseNotFound('Cupom não encontrado.');

//      if TCupomDAO.CupomPossuiPedido(Conn, AIdEmpresa, AIdCupom) then
//        TAppErrors.RaiseBadRequest(
//          'Não é possível excluir este cupom, pois ele já foi vinculado ao um pedido. ' +
//          'Para manter o histórico, inative o cupom em vez de excluir.');

      if not TCupomDAO.Excluir(Conn, AIdEmpresa, AIdcupom) then
        TAppErrors.RaiseBadRequest(
          'Não foi possível excluir este copom.' +
          'Para manter o histórico, inative o cupom em vez de excluir.');

    finally
      cupomAtual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class function TCupomService.Inserir(const AIdEmpresa: Int64;const ACupom: TCupomModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Result := 0;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseBadRequest('Empresa não identificada.');

  Validar(ACupom);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if TCupomDAO.ExisteNome(Conn, AIdEmpresa, Acupom.codigo) then
      TAppErrors.RaiseBadRequest('Já existe um cupom com este código.');

    Result := TCupomDAO.Inserir(Conn, AIdEmpresa, ACupom);
  finally
    Conn.Free;
  end;
end;

class function TCupomService.Listar(const AIdEmpresa: Integer;const APesquisa: string): TObjectList<TCupomModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TCupomDAO.Listar(Conn, AIdEmpresa, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TCupomService.NormalizarSN(const AValor,APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'S';

  Result := Valor;
end;

class function TCupomService.NormalizarTipodesconto(const AValor:String):String;
var
  V: string;
begin
  V := UpperCase(Trim(AValor));

  if V.IsEmpty then
    V := 'PERCENTUAL';

  if (V <> 'VALOR') and (V <> 'PERCENTUAL') then
    TAppErrors.RaiseBadRequest('Tipo de desconto inválido. Use VALOR ou PERCENTUAL.');

  Result := V;
end;

class procedure TCupomService.Validar(const ACupom: TCupomModel);
begin
  if ACupom = nil then
    TAppErrors.RaiseBadRequest('Dados do cupom não informado.');

  if Trim(Acupom.codigo) = '' then
    TAppErrors.RaiseBadRequest('Informe o código do cupom.');

  if Length(Trim(Acupom.codigo)) > 50 then
    TAppErrors.RaiseBadRequest('O código do cupom deve ter no máximo 50 caracteres.');

  if Length(Trim(Acupom.Descricao)) > 255 then
    TAppErrors.RaiseBadRequest('A descrição do cupom deve ter no máximo 255 caracteres.');

  Acupom.codigo               := UpperCase(trim(ACupom.codigo));
  Acupom.descricao            := UpperCase(trim(ACupom.descricao));
  Acupom.tipo_desconto        := NormalizarTipodesconto(ACupom.tipo_desconto);

  if Acupom.valor_desconto <= 0 then
  Acupom.valor_desconto       := 0;

  if Acupom.valor_minimo_pedido <= 0 then
  Acupom.valor_minimo_pedido  := 0;

  if Acupom.valor_maximo_desconto <= 0 then
  Acupom.valor_maximo_desconto:= 0;

  if Acupom.limite_total <=0 then
  Acupom.limite_total         := 0;

  if Acupom.quantidade_utilizada <=0 then
  Acupom.quantidade_utilizada := 0;

  if Acupom.limite_por_cliente <=0 then
  Acupom.limite_por_cliente   := 0;

//  Acupom.data_inicio          :=
//  Acupom.data_fim             :=

  Acupom.Ativo                := NormalizarSN(ACupom.Ativo, 'S');


end;

end.
