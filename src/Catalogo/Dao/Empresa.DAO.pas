unit Empresa.DAO;

interface

uses
  Uni,
  Empresa.Model,
  System.Generics.Collections;

type TRecPlano = Record
  Encontrado             : Boolean;
  PermiteProdutoIlimitado: string;
  PermiteWhatsapp        : string;
  PermiteEmail           : string;
  PermitePedido          : string;
  PermiteEcommerce       : string;
  PermitePagSeguro       : string;
  PermitePedidoFicha     : string;
  PermiteConfigVisual    : string;
  permiteconfigcupom     : string;
  TipoCatalogo           : string;
  ProdutoQtde            : Integer;
  CatalogoExibiPreco     : string;
End;

type
  TEmpresaDAO = class
  private

  public
    class function ExisteCnpj(
      const AConn: TUniConnection;
      const ACnpj: string;
      const AIdEmpresaIgnorar: Int64 = 0
    ): Boolean; static;

    class function ExisteEmail(
      const AConn: TUniConnection;
      const AEmail: string;
      const AIdEmpresaIgnorar: Int64 = 0
    ): Boolean; static;

    class function Inserir(
      const AConn: TUniConnection;
      const AEmpresa: TEmpresaModel
    ): Int64; static;

    class function Listar(
      const AConn: TUniConnection;
      const APesquisa: string = ''
    ): TObjectList<TEmpresaModel>; static;

    class function BuscarPorId(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ): TEmpresaModel; static;

    class procedure Atualizar(
      const AConn: TUniConnection;
      const AEmpresa: TEmpresaModel
    ); static;

    class procedure AlterarAtivo(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const AAtivo: string
    ); static;

    class procedure LiberarAcesso(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64;
      const ADataValidade: TDate
    ); static;

    class procedure Excluir(
      const AConn: TUniConnection;
      const AIdEmpresa: Int64
    ); static;


    class function ValidarPlano(const AConn: TUniConnection; const AIDPlano: Int64): TRecPlano; static;
    class function BuscarPlanoAtualEmpresa(const AConn: TUniConnection;const AIDEmpresa: Int64): TRecPlano; static;
  end;

implementation

uses
  System.SysUtils;

procedure PreencherModel(const Qry: TUniQuery; const AEmpresa: TEmpresaModel);
begin
  AEmpresa.IdEmpresa := Qry.FieldByName('id_empresa').AsLargeInt;
  AEmpresa.Nome := Qry.FieldByName('nome').AsString;
  AEmpresa.Cnpj := Qry.FieldByName('cnpj').AsString;
  AEmpresa.Cep := Qry.FieldByName('cep').AsString;
  AEmpresa.Endereco := Qry.FieldByName('endereco').AsString;
  AEmpresa.Numero := Qry.FieldByName('numero').AsString;
  AEmpresa.Complemento := Qry.FieldByName('complemento').AsString;
  AEmpresa.Bairro := Qry.FieldByName('bairro').AsString;
  AEmpresa.Cidade := Qry.FieldByName('cidade').AsString;
  AEmpresa.Uf := Qry.FieldByName('uf').AsString;
  AEmpresa.Whatsapp := Qry.FieldByName('whatsapp').AsString;
  AEmpresa.Email := Qry.FieldByName('email').AsString;
  AEmpresa.NomeResponsavel := Qry.FieldByName('nome_responsavel').AsString;

  if not Qry.FieldByName('data_criacao').IsNull then
    AEmpresa.DataCriacao := Qry.FieldByName('data_criacao').AsDateTime;

  if not Qry.FieldByName('data_validade').IsNull then
    AEmpresa.DataValidade := Qry.FieldByName('data_validade').AsDateTime;

  AEmpresa.Ativo := Qry.FieldByName('ativo').AsString;
  AEmpresa.NotificarPedidoWhatsapp := Qry.FieldByName('notificar_pedido_whatsapp').AsString;
  AEmpresa.NotificarPedidoEmail := Qry.FieldByName('notificar_pedido_email').AsString;
  AEmpresa.ResumoDiario := Qry.FieldByName('resumo_diario').AsString;
  AEmpresa.MensagemModelo := Qry.FieldByName('mensagem_modelo').AsString;
  AEmpresa.idplano        := Qry.FieldByName('idplano').AsInteger;

end;

class function TEmpresaDAO.ExisteCnpj(
  const AConn: TUniConnection;
  const ACnpj: string;
  const AIdEmpresaIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM empresa ' +
      'WHERE cnpj = :cnpj ';

    if AIdEmpresaIgnorar > 0 then
      Qry.SQL.Add('AND id_empresa <> :id_empresa');

    Qry.ParamByName('cnpj').AsString := Trim(ACnpj);

    if AIdEmpresaIgnorar > 0 then
      Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TEmpresaDAO.ExisteEmail(
  const AConn: TUniConnection;
  const AEmail: string;
  const AIdEmpresaIgnorar: Int64
): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS total ' +
      'FROM empresa ' +
      'WHERE LOWER(TRIM(email)) = LOWER(TRIM(:email)) ';

    if AIdEmpresaIgnorar > 0 then
      Qry.SQL.Add('AND id_empresa <> :id_empresa');

    Qry.ParamByName('email').AsString := Trim(AEmail);

    if AIdEmpresaIgnorar > 0 then
      Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresaIgnorar;

    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

class function TEmpresaDAO.Inserir(const AConn: TUniConnection;const AEmpresa: TEmpresaModel
): Int64;
var
  Qry: TUniQuery;
begin
  Result := 0;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO empresa (' +
      ' nome, cnpj, cep, endereco, numero, complemento, bairro, cidade, uf, ' +
      ' whatsapp, email, nome_responsavel, data_validade, ativo, ' +
      ' notificar_pedido_whatsapp, notificar_pedido_email, resumo_diario, mensagem_modelo, id_plano ' +
      ') VALUES (' +
      ' :nome, :cnpj, :cep, :endereco, :numero, :complemento, :bairro, :cidade, :uf, ' +
      ' :whatsapp, :email, :nome_responsavel, :data_validade, :ativo, ' +
      ' :notificar_pedido_whatsapp, :notificar_pedido_email, :resumo_diario, :mensagem_modelo, :idplano ' +
      ')';

    Qry.ParamByName('nome').AsString := Trim(AEmpresa.Nome);
    Qry.ParamByName('cnpj').AsString := Trim(AEmpresa.Cnpj);
    Qry.ParamByName('cep').AsString := Trim(AEmpresa.Cep);
    Qry.ParamByName('endereco').AsString := Trim(AEmpresa.Endereco);
    Qry.ParamByName('numero').AsString := Trim(AEmpresa.Numero);
    Qry.ParamByName('complemento').AsString := Trim(AEmpresa.Complemento);
    Qry.ParamByName('bairro').AsString := Trim(AEmpresa.Bairro);
    Qry.ParamByName('cidade').AsString := Trim(AEmpresa.Cidade);
    Qry.ParamByName('uf').AsString := UpperCase(Trim(AEmpresa.Uf));
    Qry.ParamByName('whatsapp').AsString := Trim(AEmpresa.Whatsapp);
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmpresa.Email));
    Qry.ParamByName('nome_responsavel').AsString := Trim(AEmpresa.NomeResponsavel);
    Qry.ParamByName('data_validade').AsDate := AEmpresa.DataValidade;
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AEmpresa.Ativo));
    Qry.ParamByName('notificar_pedido_whatsapp').AsString := UpperCase(Trim(AEmpresa.NotificarPedidoWhatsapp));
    Qry.ParamByName('notificar_pedido_email').AsString := UpperCase(Trim(AEmpresa.NotificarPedidoEmail));
    Qry.ParamByName('resumo_diario').AsString := UpperCase(Trim(AEmpresa.ResumoDiario));
    Qry.ParamByName('mensagem_modelo').AsString := Trim(AEmpresa.MensagemModelo);
    Qry.ParamByName('idplano').AsInteger        := AEmpresa.idplano;

    Qry.Execute;

    Qry.Close;
    Qry.SQL.Text := 'SELECT LAST_INSERT_ID() AS id_empresa';
    Qry.Open;

    Result := Qry.FieldByName('id_empresa').AsLargeInt;
  finally
    Qry.Free;
  end;
end;

class function TEmpresaDAO.Listar(const AConn: TUniConnection;const APesquisa: string): TObjectList<TEmpresaModel>;
var
  Qry: TUniQuery;
  Empresa: TEmpresaModel;
begin
  Result := TObjectList<TEmpresaModel>.Create(True);

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_empresa, nome, cnpj, cep, endereco, numero, complemento, bairro, cidade, uf, ' +
      ' whatsapp, email, nome_responsavel, data_criacao, data_validade, ativo, ' +
      ' notificar_pedido_whatsapp, notificar_pedido_email, resumo_diario, mensagem_modelo, id_plano as idplano ' +
      ' FROM empresa ' +
      ' WHERE 1 = 1 ';

    if not Trim(APesquisa).IsEmpty then
    begin
      Qry.SQL.Add(
        'AND (' +
        ' LOWER(nome) LIKE LOWER(:pesquisa) OR ' +
        ' LOWER(email) LIKE LOWER(:pesquisa) OR ' +
        ' cnpj LIKE :pesquisa OR ' +
        ' LOWER(nome_responsavel) LIKE LOWER(:pesquisa) ' +
        ') '
      );
    end;

    Qry.SQL.Add('ORDER BY data_criacao DESC, id_empresa DESC');

    if not Trim(APesquisa).IsEmpty then
      Qry.ParamByName('pesquisa').AsString := '%' + Trim(APesquisa) + '%';

    Qry.Open;

    while not Qry.Eof do
    begin
      Empresa := TEmpresaModel.Create;
      PreencherModel(Qry, Empresa);
      Result.Add(Empresa);

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;



class function TEmpresaDAO.BuscarPorId(const AConn: TUniConnection;const AIdEmpresa: Int64): TEmpresaModel;
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT ' +
      ' id_empresa, nome, cnpj, cep, endereco, numero, complemento, bairro, cidade, uf, ' +
      ' whatsapp, email, nome_responsavel, data_criacao, data_validade, ativo, ' +
      ' notificar_pedido_whatsapp, notificar_pedido_email, resumo_diario, mensagem_modelo, id_plano as idplano ' +
      ' FROM empresa ' +
      ' WHERE id_empresa = :id_empresa ' +
      ' LIMIT 1';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit(nil);

    Result := TEmpresaModel.Create;
    PreencherModel(Qry, Result);
  finally
    Qry.Free;
  end;
end;

class procedure TEmpresaDAO.Atualizar(const AConn: TUniConnection;const AEmpresa: TEmpresaModel);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE empresa SET ' +
      ' nome = :nome, ' +
      ' cnpj = :cnpj, ' +
      ' cep = :cep, ' +
      ' endereco = :endereco, ' +
      ' numero = :numero, ' +
      ' complemento = :complemento, ' +
      ' bairro = :bairro, ' +
      ' cidade = :cidade, ' +
      ' uf = :uf, ' +
      ' whatsapp = :whatsapp, ' +
      ' email = :email, ' +
      ' nome_responsavel = :nome_responsavel, ' +
      ' data_validade = :data_validade, ' +
      ' ativo = :ativo, ' +
      ' notificar_pedido_whatsapp = :notificar_pedido_whatsapp, ' +
      ' notificar_pedido_email = :notificar_pedido_email, ' +
      ' resumo_diario = :resumo_diario, ' +
      ' mensagem_modelo = :mensagem_modelo, ' +
      ' id_plano = :idplano     '+
      ' WHERE id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AEmpresa.IdEmpresa;
    Qry.ParamByName('nome').AsString := Trim(AEmpresa.Nome);
    Qry.ParamByName('cnpj').AsString := Trim(AEmpresa.Cnpj);
    Qry.ParamByName('cep').AsString := Trim(AEmpresa.Cep);
    Qry.ParamByName('endereco').AsString := Trim(AEmpresa.Endereco);
    Qry.ParamByName('numero').AsString := Trim(AEmpresa.Numero);
    Qry.ParamByName('complemento').AsString := Trim(AEmpresa.Complemento);
    Qry.ParamByName('bairro').AsString := Trim(AEmpresa.Bairro);
    Qry.ParamByName('cidade').AsString := Trim(AEmpresa.Cidade);
    Qry.ParamByName('uf').AsString := UpperCase(Trim(AEmpresa.Uf));
    Qry.ParamByName('whatsapp').AsString := Trim(AEmpresa.Whatsapp);
    Qry.ParamByName('email').AsString := LowerCase(Trim(AEmpresa.Email));
    Qry.ParamByName('nome_responsavel').AsString := Trim(AEmpresa.NomeResponsavel);
    Qry.ParamByName('data_validade').AsDate := AEmpresa.DataValidade;
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AEmpresa.Ativo));
    Qry.ParamByName('notificar_pedido_whatsapp').AsString := UpperCase(Trim(AEmpresa.NotificarPedidoWhatsapp));
    Qry.ParamByName('notificar_pedido_email').AsString := UpperCase(Trim(AEmpresa.NotificarPedidoEmail));
    Qry.ParamByName('resumo_diario').AsString := UpperCase(Trim(AEmpresa.ResumoDiario));
    Qry.ParamByName('mensagem_modelo').AsString := Trim(AEmpresa.MensagemModelo);
    Qry.ParamByName('idplano').AsInteger        := AEmpresa.idplano;

    Qry.Execute;

  finally
    Qry.Free;
  end;
end;

class procedure TEmpresaDAO.AlterarAtivo(const AConn: TUniConnection;const AIdEmpresa: Int64;const AAtivo: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE empresa SET ativo = :ativo ' +
      'WHERE id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('ativo').AsString := UpperCase(Trim(AAtivo));

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TEmpresaDAO.LiberarAcesso(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64;
  const ADataValidade: TDate
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE empresa SET ' +
      ' ativo = ''S'', ' +
      ' data_validade = :data_validade ' +
      'WHERE id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.ParamByName('data_validade').AsDate := ADataValidade;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TEmpresaDAO.Excluir(
  const AConn: TUniConnection;
  const AIdEmpresa: Int64
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'DELETE FROM empresa ' +
      'WHERE id_empresa = :id_empresa';

    Qry.ParamByName('id_empresa').AsLargeInt := AIdEmpresa;
    Qry.Execute;
  finally
    Qry.Free;
  end;
end;


class function TEmpresaDAO.ValidarPlano(const AConn: TUniConnection; const AIDPlano: Int64): TRecPlano;
var
  Qry: TUniQuery;
Const
  QryStr = 'select ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, permite_ecommerce, '+
      ' permite_pagseguro, permite_pedido_ficha, permite_config_visual, permite_config_cupom, tipo_catalogo_padrao, produto_qtde '+
      ' from plano where id_plano = :id_plano limit 1';
begin
  Result.Encontrado := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    :=  QryStr;


    Qry.ParamByName('id_plano').AsLargeInt := AIdPlano;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado               := True;
    Result.PermiteProdutoIlimitado  := Qry.FieldByName('permite_produto_ilimitado').AsString;
    Result.PermiteWhatsapp          := Qry.FieldByName('permite_whatsapp').AsString;
    Result.PermiteEmail             := Qry.FieldByName('permite_email').AsString;
    Result.PermitePedido            := Qry.FieldByName('permite_pedido').AsString;
    Result.PermiteEcommerce         := Qry.FieldByName('permite_ecommerce').AsString;
    Result.PermitePagSeguro         := Qry.FieldByName('permite_pagseguro').AsString;
    Result.PermitePedidoFicha       := Qry.FieldByName('permite_pedido_ficha').AsString;
    Result.PermiteConfigVisual      := Qry.FieldByName('permite_config_visual').AsString;
    Result.permiteconfigcupom       := Qry.FieldByName('permite_config_cupom').AsString;
    Result.TipoCatalogo             := Qry.FieldByName('tipo_catalogo_padrao').AsString;
    Result.ProdutoQtde              := Qry.FieldByName('produto_qtde').AsInteger;

  finally
    Qry.Free;
  end;
end;

class function TEmpresaDAO.BuscarPlanoAtualEmpresa(const AConn: TUniConnection; const AIDEmpresa:Int64): TRecPlano;
var
  Qry: TUniQuery;
Const
  QryStr = 'select ' +
      ' p.permite_produto_ilimitado, p.permite_whatsapp, p.permite_email, p.permite_pedido, p.permite_ecommerce, '+
      ' p.permite_pagseguro, p.permite_pedido_ficha, p.permite_config_visual, '+
      ' p.permite_config_cupom, p.tipo_catalogo_padrao, p.produto_qtde, '+
      ' cc. mostrar_preco  '+
      ' from empresa e '+
      ' Inner join plano p'+
      ' on e.id_plano = p.id_plano'+
      ' inner join catalogo_config cc '+
      ' on e.id_empresa = cc.id_empresa '+
      ' where e.id_empresa = :id_empresa ';
begin
  Result.Encontrado := False;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    :=  QryStr;


    Qry.ParamByName('id_empresa').AsLargeInt := AIDEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result.Encontrado               := True;
    Result.PermiteProdutoIlimitado  := Qry.FieldByName('permite_produto_ilimitado').AsString;
    Result.PermiteWhatsapp          := Qry.FieldByName('permite_whatsapp').AsString;
    Result.PermiteEmail             := Qry.FieldByName('permite_email').AsString;
    Result.PermitePedido            := Qry.FieldByName('permite_pedido').AsString;
    Result.PermiteEcommerce         := Qry.FieldByName('permite_ecommerce').AsString;
    Result.PermitePagSeguro         := Qry.FieldByName('permite_pagseguro').AsString;
    Result.PermitePedidoFicha       := Qry.FieldByName('permite_pedido_ficha').AsString;
    Result.PermiteConfigVisual      := Qry.FieldByName('permite_config_visual').AsString;
    Result.permiteconfigcupom       := Qry.FieldByName('permite_config_cupom').AsString;
    Result.TipoCatalogo             := Qry.FieldByName('tipo_catalogo_padrao').AsString;
    Result.ProdutoQtde              := Qry.FieldByName('produto_qtde').AsInteger;
    Result.CatalogoExibiPreco       := Qry.FieldByName('mostrar_preco').AsString;
  finally
    Qry.Free;
  end;
end;





end.
