unit Cliente.Service;

interface

uses
  Cliente.Model,
  System.Generics.Collections;

type
  TClienteService = class
  public
    class function ListarClientes(const AIdEmpresa: Int64;const APesquisa: string = ''): TObjectList<TClienteModel>; static;
    class function BuscarCliente(const AIdEmpresa: Int64; const AIdCliente: Int64): TClienteModel; static;
    class function CriarCliente(const AIdEmpresa: Int64;const ACliente: TClienteModel): Int64; static;
    class procedure AtualizarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64;const ACliente: TClienteModel); static;
    class procedure InativarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64); static;
    class procedure AtivarCliente(const AIdEmpresa: Int64; const AIdCliente: Int64); static;
    class procedure BloquearCliente(const AIdEmpresa: Int64; const AIdCliente: Int64); static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection,
  APP.Errors,
  Cliente.DAO,
  Usuario.Model,
  Usuario.DAO,
  Auth.Passwords;

procedure CriarUsuarioPortalCliente(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCliente: Int64;const ACliente: TClienteModel);
var
  Usuario: TUsuarioModel;
begin
  if ACliente.AcessoPortal <> 'S' then
    Exit;

  if UpperCase(Trim(ACliente.CriarAcessoPortal)) <> 'S' then
    Exit;

  if Trim(ACliente.Email).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o e-mail do cliente para criar o acesso ao portal.');

  if Trim(ACliente.SenhaPortal).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha inicial do cliente para criar o acesso ao portal.');

  if TUsuarioDAO.ExisteEmailEmpresa(AConn, AIdEmpresa, ACliente.Email, 0) then
    TAppErrors.RaiseBadRequest('Já existe um usuário cadastrado com este e-mail para esta empresa.');

  Usuario := TUsuarioModel.Create;
  try
    Usuario.IdEmpresa := AIdEmpresa;
    Usuario.IdCliente := AIdCliente;
    Usuario.Nome      := ACliente.NomeRazao;
    Usuario.Email     := LowerCase(Trim(ACliente.Email));
    Usuario.SenhaHash := HashSenha(ACliente.SenhaPortal);
    Usuario.Perfil    := 'PORTAL';
    Usuario.Ativo     := 'S';

    TUsuarioDAO.Inserir(AConn, Usuario);
  finally
    Usuario.Free;
  end;
end;


function NormalizarSN(const AValor, APadrao: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(AValor));

  if V.IsEmpty then
    V := APadrao;

  if (V <> 'S') and (V <> 'N') then
    V := APadrao;

  Result := V;
end;

function NormalizarStatusCliente(const AStatus: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(AStatus));

  if V.IsEmpty then
    V := 'ATIVO';

  if (V <> 'ATIVO') and
     (V <> 'INATIVO') and
     (V <> 'BLOQUEADO') and
     (V <> 'PENDENTE') then
    TAppErrors.RaiseBadRequest('Status do cliente inválido.');

  Result := V;
end;

function NormalizarTipoPessoa(const ATipo: string): string;
var
  V: string;
begin
  V := UpperCase(Trim(ATipo));

  if V.IsEmpty then
    V := 'JURIDICA';

  if (V <> 'FISICA') and (V <> 'JURIDICA') then
    TAppErrors.RaiseBadRequest('Tipo de pessoa inválido. Use FISICA ou JURIDICA.');

  Result := V;
end;

procedure NormalizarCliente(const ACliente: TClienteModel);
begin
  ACliente.TipoPessoa := NormalizarTipoPessoa(ACliente.TipoPessoa);

  ACliente.NomeRazao := Trim(ACliente.NomeRazao);
  ACliente.NomeFantasia := Trim(ACliente.NomeFantasia);
  ACliente.CpfCnpj := Trim(ACliente.CpfCnpj);
  ACliente.RgIe := Trim(ACliente.RgIe);

  ACliente.Telefone := Trim(ACliente.Telefone);
  ACliente.Whatsapp := Trim(ACliente.Whatsapp);
  ACliente.Email := LowerCase(Trim(ACliente.Email));

  ACliente.Cep := Trim(ACliente.Cep);
  ACliente.Endereco := Trim(ACliente.Endereco);
  ACliente.Numero := Trim(ACliente.Numero);
  ACliente.Complemento := Trim(ACliente.Complemento);
  ACliente.Bairro := Trim(ACliente.Bairro);
  ACliente.Cidade := Trim(ACliente.Cidade);
  ACliente.Uf := UpperCase(Trim(ACliente.Uf));

  ACliente.ResponsavelNome := Trim(ACliente.ResponsavelNome);
  ACliente.ResponsavelCpf := Trim(ACliente.ResponsavelCpf);
  ACliente.ResponsavelTelefone := Trim(ACliente.ResponsavelTelefone);

  ACliente.AcessoPortal := NormalizarSN(ACliente.AcessoPortal, 'N');
  ACliente.Ecommerce := NormalizarSN(ACliente.Ecommerce, 'S');
  ACliente.Consignado := NormalizarSN(ACliente.Consignado, 'N');

  ACliente.Status := NormalizarStatusCliente(ACliente.Status);

  if ACliente.LimiteConsignado < 0 then
    ACliente.LimiteConsignado := 0;

  if ACliente.DiaFechamento < 0 then
    ACliente.DiaFechamento := 0;

  if ACliente.PrazoPagamentoDias < 0 then
    ACliente.PrazoPagamentoDias := 0;

  ACliente.CriarAcessoPortal  := NormalizarSN(ACliente.CriarAcessoPortal, 'N');
  ACliente.SenhaPortal        := Trim(ACliente.SenhaPortal);

end;

procedure ValidarCliente(const ACliente: TClienteModel);
begin
  if ACliente.NomeRazao.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome ou razão social do cliente.');

  if (ACliente.AcessoPortal = 'S') and ACliente.Email.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o e-mail do cliente para liberar acesso ao portal.');

  if ACliente.SenhaPortal.IsEmpty then
    TAppErrors.RaiseBadRequest('Informe a senha inicial para criar o acesso ao portal.');
  if Length(ACliente.SenhaPortal) < 6 then
    TAppErrors.RaiseBadRequest('A senha inicial do portal deve ter no mínimo 6 caracteres.');

  if (ACliente.Consignado = 'S') and (ACliente.Status <> 'ATIVO') then
    TAppErrors.RaiseBadRequest('Para liberar consignado, o cliente precisa estar ativo.');
end;

class function TClienteService.ListarClientes(const AIdEmpresa: Int64;const APesquisa: string): TObjectList<TClienteModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TClienteDAO.Listar(Conn, AIdEmpresa, APesquisa);
  finally
    Conn.Free;
  end;
end;

class function TClienteService.BuscarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64): TClienteModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCliente <= 0 then
    TAppErrors.RaiseBadRequest('Cliente não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TClienteDAO.BuscarPorId(Conn, AIdEmpresa, AIdCliente);

    if Result = nil then
      TAppErrors.RaiseNotFound('Cliente não encontrado.');
  finally
    Conn.Free;
  end;
end;

class function TClienteService.CriarCliente(const AIdEmpresa: Int64;const ACliente: TClienteModel): Int64;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');
  ACliente.IdEmpresa := AIdEmpresa;
  NormalizarCliente(ACliente);
  ValidarCliente(ACliente);
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      if TClienteDAO.ExisteCpfCnpj(Conn, AIdEmpresa, ACliente.CpfCnpj) then
        TAppErrors.RaiseBadRequest('CPF/CNPJ já cadastrado para esta empresa.');
      Result := TClienteDAO.Inserir(Conn, ACliente);
      CriarUsuarioPortalCliente(Conn, AIdEmpresa, Result, ACliente);
      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TClienteService.AtualizarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64;const ACliente: TClienteModel);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Atual: TClienteModel;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdCliente <= 0 then
    TAppErrors.RaiseBadRequest('Cliente não informado.');

  ACliente.IdEmpresa := AIdEmpresa;
  ACliente.IdCliente := AIdCliente;

  NormalizarCliente(ACliente);
  ValidarCliente(ACliente);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Atual := TClienteDAO.BuscarPorId(Conn, AIdEmpresa, AIdCliente);
    try
      if Atual = nil then
        TAppErrors.RaiseNotFound('Cliente não encontrado.');

      if TClienteDAO.ExisteCpfCnpj(Conn, AIdEmpresa, ACliente.CpfCnpj, AIdCliente) then
        TAppErrors.RaiseBadRequest('CPF/CNPJ já cadastrado para outro cliente.');

      TClienteDAO.Atualizar(Conn, ACliente);
    finally
      Atual.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TClienteService.InativarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TClienteDAO.AlterarStatus(Conn, AIdEmpresa, AIdCliente, 'INATIVO');
  finally
    Conn.Free;
  end;
end;

class procedure TClienteService.AtivarCliente(const AIdEmpresa: Int64;const AIdCliente: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TClienteDAO.AlterarStatus(Conn, AIdEmpresa, AIdCliente, 'ATIVO');
  finally
    Conn.Free;
  end;
end;

class procedure TClienteService.BloquearCliente(const AIdEmpresa: Int64;const AIdCliente: Int64);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    TClienteDAO.AlterarStatus(Conn, AIdEmpresa, AIdCliente, 'BLOQUEADO');
  finally
    Conn.Free;
  end;
end;



end.
