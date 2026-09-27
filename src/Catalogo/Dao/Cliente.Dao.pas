unit Cliente.DAO;

interface

uses
  Uni,
  Cliente.Model,
  System.Generics.Collections;

type
  TClienteDAO = class
  public
    class function Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const APesquisa: string = ''): TObjectList<TClienteModel>; static;
    class function BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCliente: Int64): TClienteModel; static;
    class function ExisteCpfCnpj(const AConn: TUniConnection;const AIdEmpresa: Int64;const ACpfCnpj: string;const AIdClienteIgnorar: Int64 = 0): Boolean; static;
    class function Inserir(const AConn: TUniConnection;const ACliente: TClienteModel): Int64; static;
    class procedure Atualizar(const AConn: TUniConnection;const ACliente: TClienteModel); static;
    class procedure AlterarStatus(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCliente: Int64;const AStatus: string); static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherCliente(const Qry: TUniQuery; const ACliente: TClienteModel);
begin
  ACliente.IdCliente := Qry.FieldByName('id_cliente').AsLargeInt;
  ACliente.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;

  ACliente.TipoPessoa := Qry.FieldByName('tipo_pessoa').AsString;
  ACliente.NomeRazao := Qry.FieldByName('nome_razao').AsString;
  ACliente.NomeFantasia := Qry.FieldByName('nome_fantasia').AsString;
  ACliente.CpfCnpj := Qry.FieldByName('cpf_cnpj').AsString;
  ACliente.RgIe := Qry.FieldByName('rg_ie').AsString;

  ACliente.Telefone := Qry.FieldByName('telefone').AsString;
  ACliente.Whatsapp := Qry.FieldByName('whatsapp').AsString;
  ACliente.Email := Qry.FieldByName('email').AsString;

  ACliente.Cep := Qry.FieldByName('cep').AsString;
  ACliente.Endereco := Qry.FieldByName('endereco').AsString;
  ACliente.Numero := Qry.FieldByName('numero').AsString;
  ACliente.Complemento := Qry.FieldByName('complemento').AsString;
  ACliente.Bairro := Qry.FieldByName('bairro').AsString;
  ACliente.Cidade := Qry.FieldByName('cidade').AsString;
  ACliente.Uf := Qry.FieldByName('uf').AsString;

  ACliente.ResponsavelNome := Qry.FieldByName('responsavel_nome').AsString;
  ACliente.ResponsavelCpf := Qry.FieldByName('responsavel_cpf').AsString;
  ACliente.ResponsavelTelefone := Qry.FieldByName('responsavel_telefone').AsString;

  ACliente.AcessoPortal := Qry.FieldByName('acesso_portal').AsString;
  ACliente.Ecommerce := Qry.FieldByName('ecommerce').AsString;
  ACliente.Consignado := Qry.FieldByName('consignado').AsString;

  ACliente.LimiteConsignado := Qry.FieldByName('limite_consignado').AsFloat;
  ACliente.DiaFechamento := Qry.FieldByName('dia_fechamento').AsInteger;
  ACliente.PrazoPagamentoDias := Qry.FieldByName('prazo_pagamento_dias').AsInteger;

  ACliente.Status := Qry.FieldByName('status').AsString;
  ACliente.Observacao := Qry.FieldByName('observacao').AsString;

  if not Qry.FieldByName('data_cadastro').IsNull then
    ACliente.DataCadastro := Qry.FieldByName('data_cadastro').AsDateTime;

  if not Qry.FieldByName('data_alteracao').IsNull then
    ACliente.DataAlteracao := Qry.FieldByName('data_alteracao').AsDateTime;
end;

class function TClienteDAO.Listar(const AConn: TUniConnection;const AIdEmpresa: Int64;const APesquisa: string): TObjectList<TClienteModel>;
var
  Qry: TUniQuery;
  Cliente: TClienteModel;
begin
  Result := TObjectList<TClienteModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM cliente ' +
      'WHERE id_empresa = :id_empresa ';

    if not Trim(APesquisa).IsEmpty then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND (nome_razao LIKE :pesquisa ' +
        'OR nome_fantasia LIKE :pesquisa ' +
        'OR cpf_cnpj LIKE :pesquisa ' +
        'OR email LIKE :pesquisa ' +
        'OR whatsapp LIKE :pesquisa) ';

    Qry.SQL.Text := Qry.SQL.Text +
      'ORDER BY nome_razao';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Cliente := TClienteModel.Create;
      PreencherCliente(Qry, Cliente);
      Result.Add(Cliente);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

class function TClienteDAO.BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCliente: Int64 ): TClienteModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT * FROM cliente ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cliente = :id_cliente';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_cliente').AsLargeInt := AIdCliente;
    Qry.Open;

    if not Qry.IsEmpty then
    begin
      Result := TClienteModel.Create;
      PreencherCliente(Qry, Result);
    end;
  finally
    Qry.Free;
  end;
end;

class function TClienteDAO.ExisteCpfCnpj(const AConn: TUniConnection;const AIdEmpresa: Int64;const ACpfCnpj: string;const AIdClienteIgnorar: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  if Trim(ACpfCnpj).IsEmpty then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM cliente ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND cpf_cnpj = :cpf_cnpj ';

    if AIdClienteIgnorar > 0 then
      Qry.SQL.Text := Qry.SQL.Text +
        'AND id_cliente <> :id_cliente';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('cpf_cnpj').AsString := Trim(ACpfCnpj);

    if AIdClienteIgnorar > 0 then
      Qry.ParamByName('id_cliente').AsLargeInt := AIdClienteIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TClienteDAO.Inserir(const AConn: TUniConnection;const ACliente: TClienteModel): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO cliente (' +
      ' id_empresa, tipo_pessoa, nome_razao, nome_fantasia, cpf_cnpj, rg_ie, ' +
      ' telefone, whatsapp, email, cep, endereco, numero, complemento, bairro, cidade, uf, ' +
      ' responsavel_nome, responsavel_cpf, responsavel_telefone, ' +
      ' acesso_portal, ecommerce, consignado, limite_consignado, dia_fechamento, prazo_pagamento_dias, ' +
      ' status, observacao ' +
      ') VALUES (' +
      ' :id_empresa, :tipo_pessoa, :nome_razao, :nome_fantasia, :cpf_cnpj, :rg_ie, ' +
      ' :telefone, :whatsapp, :email, :cep, :endereco, :numero, :complemento, :bairro, :cidade, :uf, ' +
      ' :responsavel_nome, :responsavel_cpf, :responsavel_telefone, ' +
      ' :acesso_portal, :ecommerce, :consignado, :limite_consignado, :dia_fechamento, :prazo_pagamento_dias, ' +
      ' :status, :observacao ' +
      ')';

    Qry.ParamByName('id_empresa').AsLargeInt := ACliente.IdEmpresa;
    Qry.ParamByName('tipo_pessoa').AsString := ACliente.TipoPessoa;
    Qry.ParamByName('nome_razao').AsString := ACliente.NomeRazao;
    Qry.ParamByName('nome_fantasia').AsString := ACliente.NomeFantasia;
    Qry.ParamByName('cpf_cnpj').AsString := ACliente.CpfCnpj;
    Qry.ParamByName('rg_ie').AsString := ACliente.RgIe;

    Qry.ParamByName('telefone').AsString := ACliente.Telefone;
    Qry.ParamByName('whatsapp').AsString := ACliente.Whatsapp;
    Qry.ParamByName('email').AsString := ACliente.Email;

    Qry.ParamByName('cep').AsString := ACliente.Cep;
    Qry.ParamByName('endereco').AsString := ACliente.Endereco;
    Qry.ParamByName('numero').AsString := ACliente.Numero;
    Qry.ParamByName('complemento').AsString := ACliente.Complemento;
    Qry.ParamByName('bairro').AsString := ACliente.Bairro;
    Qry.ParamByName('cidade').AsString := ACliente.Cidade;
    Qry.ParamByName('uf').AsString := ACliente.Uf;

    Qry.ParamByName('responsavel_nome').AsString := ACliente.ResponsavelNome;
    Qry.ParamByName('responsavel_cpf').AsString := ACliente.ResponsavelCpf;
    Qry.ParamByName('responsavel_telefone').AsString := ACliente.ResponsavelTelefone;

    Qry.ParamByName('acesso_portal').AsString := ACliente.AcessoPortal;
    Qry.ParamByName('ecommerce').AsString := ACliente.Ecommerce;
    Qry.ParamByName('consignado').AsString := ACliente.Consignado;

    Qry.ParamByName('limite_consignado').AsFloat := ACliente.LimiteConsignado;
    Qry.ParamByName('dia_fechamento').AsInteger := ACliente.DiaFechamento;
    Qry.ParamByName('prazo_pagamento_dias').AsInteger := ACliente.PrazoPagamentoDias;

    Qry.ParamByName('status').AsString := ACliente.Status;
    Qry.ParamByName('observacao').AsString := ACliente.Observacao;

    Qry.Execute;

    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id';
    Qry.Open;

    Result := Qry.FieldByName('id').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class procedure TClienteDAO.Atualizar(const AConn: TUniConnection;const ACliente: TClienteModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE cliente SET ' +
      ' tipo_pessoa = :tipo_pessoa, ' +
      ' nome_razao = :nome_razao, ' +
      ' nome_fantasia = :nome_fantasia, ' +
      ' cpf_cnpj = :cpf_cnpj, ' +
      ' rg_ie = :rg_ie, ' +
      ' telefone = :telefone, ' +
      ' whatsapp = :whatsapp, ' +
      ' email = :email, ' +
      ' cep = :cep, ' +
      ' endereco = :endereco, ' +
      ' numero = :numero, ' +
      ' complemento = :complemento, ' +
      ' bairro = :bairro, ' +
      ' cidade = :cidade, ' +
      ' uf = :uf, ' +
      ' responsavel_nome = :responsavel_nome, ' +
      ' responsavel_cpf = :responsavel_cpf, ' +
      ' responsavel_telefone = :responsavel_telefone, ' +
      ' acesso_portal = :acesso_portal, ' +
      ' ecommerce = :ecommerce, ' +
      ' consignado = :consignado, ' +
      ' limite_consignado = :limite_consignado, ' +
      ' dia_fechamento = :dia_fechamento, ' +
      ' prazo_pagamento_dias = :prazo_pagamento_dias, ' +
      ' status = :status, ' +
      ' observacao = :observacao, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cliente = :id_cliente';

    Qry.ParamByName('id_empresa').AsLargeInt := ACliente.IdEmpresa;
    Qry.ParamByName('id_cliente').AsLargeInt := ACliente.IdCliente;

    Qry.ParamByName('tipo_pessoa').AsString := ACliente.TipoPessoa;
    Qry.ParamByName('nome_razao').AsString := ACliente.NomeRazao;
    Qry.ParamByName('nome_fantasia').AsString := ACliente.NomeFantasia;
    Qry.ParamByName('cpf_cnpj').AsString := ACliente.CpfCnpj;
    Qry.ParamByName('rg_ie').AsString := ACliente.RgIe;

    Qry.ParamByName('telefone').AsString := ACliente.Telefone;
    Qry.ParamByName('whatsapp').AsString := ACliente.Whatsapp;
    Qry.ParamByName('email').AsString := ACliente.Email;

    Qry.ParamByName('cep').AsString := ACliente.Cep;
    Qry.ParamByName('endereco').AsString := ACliente.Endereco;
    Qry.ParamByName('numero').AsString := ACliente.Numero;
    Qry.ParamByName('complemento').AsString := ACliente.Complemento;
    Qry.ParamByName('bairro').AsString := ACliente.Bairro;
    Qry.ParamByName('cidade').AsString := ACliente.Cidade;
    Qry.ParamByName('uf').AsString := ACliente.Uf;

    Qry.ParamByName('responsavel_nome').AsString := ACliente.ResponsavelNome;
    Qry.ParamByName('responsavel_cpf').AsString := ACliente.ResponsavelCpf;
    Qry.ParamByName('responsavel_telefone').AsString := ACliente.ResponsavelTelefone;

    Qry.ParamByName('acesso_portal').AsString := ACliente.AcessoPortal;
    Qry.ParamByName('ecommerce').AsString := ACliente.Ecommerce;
    Qry.ParamByName('consignado').AsString := ACliente.Consignado;

    Qry.ParamByName('limite_consignado').AsFloat := ACliente.LimiteConsignado;
    Qry.ParamByName('dia_fechamento').AsInteger := ACliente.DiaFechamento;
    Qry.ParamByName('prazo_pagamento_dias').AsInteger := ACliente.PrazoPagamentoDias;

    Qry.ParamByName('status').AsString := ACliente.Status;
    Qry.ParamByName('observacao').AsString := ACliente.Observacao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TClienteDAO.AlterarStatus(const AConn: TUniConnection;const AIdEmpresa: Int64;const AIdCliente: Int64; const AStatus: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE cliente SET ' +
      ' status = :status, ' +
      ' data_alteracao = NOW() ' +
      'WHERE id_empresa = :id_empresa ' +
      'AND id_cliente = :id_cliente';

    Qry.ParamByName('status').AsString := AStatus;
    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('id_cliente').AsLargeInt := AIdCliente;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

end.
