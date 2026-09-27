unit Pedido.Service;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Pedido.Model,
  PedidoItem.Model,
  RegistroEvento.Service,
  NotificacaoFila.Service,
  Empresa.DAO;

type
  TCriarPedidoResult = record
    IdPedido: Int64;
    ValorTotal: Currency;
  end;

  TPedidoService = class
  private
    class function NormalizarSlug(const ASlug: string): string; static;
    class function NormalizarTipoEntrega(const ATipo: string): string; static;
    class function NormalizarStatus(const AStatus: string): string; static;

    class procedure ValidarPedidoPublico(const APedido: TPedidoModel); static;
    class procedure ValidarStatusPedido(const AStatus: string); static;
  public
    class function CriarPedidoPublico(
      const ASlug: string;
      const APedido: TPedidoModel
    ): TCriarPedidoResult; static;

    class function ListarPedidos(
      const AIdEmpresa: Int64
    ): TObjectList<TPedidoModel>; static;

    class function BuscarPedido(
      const AIdEmpresa: Int64;
      const AIdPedido: Int64
    ): TPedidoModel; static;

    class procedure AtualizarStatus(
      const AIdEmpresa: Int64;
      const AIdPedido: Int64;
      const AStatus: string
    ); static;
  end;

implementation

uses
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  Pedido.DAO;

class function TPedidoService.NormalizarSlug(const ASlug: string): string;
var
  S: string;
begin
  S := LowerCase(Trim(ASlug));

  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '_', '-', [rfReplaceAll]);
  S := StringReplace(S, '.', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  if S.StartsWith('-') then
    Delete(S, 1, 1);

  if S.EndsWith('-') then
    Delete(S, Length(S), 1);

  Result := S;
end;

class function TPedidoService.NormalizarTipoEntrega(const ATipo: string): string;
var
  Tipo: string;
begin
  Tipo := UpperCase(Trim(ATipo));

  if Tipo.IsEmpty then
    Tipo := 'RETIRADA';

  if (Tipo <> 'RETIRADA') and (Tipo <> 'ENTREGA') then
    Tipo := 'RETIRADA';

  Result := Tipo;
end;

class function TPedidoService.NormalizarStatus(const AStatus: string): string;
begin
  Result := UpperCase(Trim(AStatus));
end;

class procedure TPedidoService.ValidarStatusPedido(const AStatus: string);
var
  Status: string;
begin
  Status := NormalizarStatus(AStatus);

  if Status.IsEmpty then
    TAppErrors.RaiseBadRequest('Status não informado.');

  if (Status <> 'NOVO') and
     (Status <> 'EM_ATENDIMENTO') and
     (Status <> 'FINALIZADO') and
     (Status <> 'CANCELADO') then
  begin
    TAppErrors.RaiseBadRequest('Status inválido.');
  end;
end;

class procedure TPedidoService.ValidarPedidoPublico(const APedido: TPedidoModel);
begin
  if APedido = nil then
    TAppErrors.RaiseBadRequest('Dados do pedido não informados.');

  if Trim(APedido.NomeCliente).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o nome do cliente.');

  if Length(Trim(APedido.NomeCliente)) > 120 then
    TAppErrors.RaiseBadRequest('O nome do cliente deve possuir no máximo 120 caracteres.');

  if Trim(APedido.WhatsappCliente).IsEmpty then
    TAppErrors.RaiseBadRequest('Informe o WhatsApp do cliente.');

  if Length(Trim(APedido.WhatsappCliente)) > 20 then
    TAppErrors.RaiseBadRequest('O WhatsApp deve possuir no máximo 20 caracteres.');

  if Length(Trim(APedido.EmailCliente)) > 150 then
    TAppErrors.RaiseBadRequest('O email deve possuir no máximo 150 caracteres.');

  APedido.NomeCliente := Trim(APedido.NomeCliente);
  APedido.WhatsappCliente := Trim(APedido.WhatsappCliente);
  APedido.EmailCliente := LowerCase(Trim(APedido.EmailCliente));
  APedido.Observacao := Trim(APedido.Observacao);
  APedido.TipoEntrega := NormalizarTipoEntrega(APedido.TipoEntrega);
  APedido.EnderecoEntrega := Trim(APedido.EnderecoEntrega);
  APedido.Status := 'NOVO';

  if APedido.TipoEntrega = 'ENTREGA' then
  begin
    if APedido.EnderecoEntrega.Trim.IsEmpty then
      TAppErrors.RaiseBadRequest('Informe o endereço de entrega.');
  end;

  if APedido.Itens.Count = 0 then
    TAppErrors.RaiseBadRequest('Informe pelo menos um item no pedido.');
end;

class function TPedidoService.CriarPedidoPublico(const ASlug: string; const APedido: TPedidoModel): TCriarPedidoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Slug: string;
  IdEmpresa: Int64;
  Item: TPedidoItemModel;
  Produto: TPedidoProdutoDTO;
  ValorTotalPedido: Currency;
  TipoPlano:TRecPlano;
begin
  Result.IdPedido     := 0;
  Result.ValorTotal   := 0;

  Slug := NormalizarSlug(ASlug);

  if Slug.Trim.IsEmpty then
    TAppErrors.RaiseBadRequest('Slug não informado.');

  ValidarPedidoPublico(APedido);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      if not TPedidoDAO.BuscarEmpresaPorSlug(Conn, Slug, IdEmpresa) then
        TAppErrors.RaiseNotFound('Catálogo não encontrado ou indisponível.');

      APedido.IdEmpresa   := IdEmpresa;
      APedido.Status      := 'NOVO';
      APedido.ValorTotal  := 0;

      ValorTotalPedido    := 0;

      //Validar tipo_catalogo
      TipoPlano           := TEmpresaDAO.BuscarPlanoAtualEmpresa(Conn,IdEmpresa);


      for Item in APedido.Itens do
      begin
        if Item.IdProduto <= 0 then
          TAppErrors.RaiseBadRequest('Produto não informado em um dos itens.');

        if Item.Quantidade <= 0 then
          TAppErrors.RaiseBadRequest('Quantidade inválida em um dos itens.');

        if not TPedidoDAO.BuscarProdutoAtivo(Conn, IdEmpresa, Item.IdProduto, Produto) then
          TAppErrors.RaiseBadRequest('Produto inválido ou indisponível: ' + Item.IdProduto.ToString);

        Item.IdEmpresa        := IdEmpresa;
        Item.NomeProduto      := Produto.Nome;
        if TipoPlano.CatalogoExibiPreco = 'S' then
        begin
          Item.ValorUnitario  := Produto.Preco;
          Item.ValorTotal     := Item.Quantidade * Item.ValorUnitario;
          ValorTotalPedido    := ValorTotalPedido + Item.ValorTotal;
        end
        else
        begin
          Item.ValorUnitario  := 0;
          Item.ValorTotal     := 0;
          ValorTotalPedido    := 0;
        end;
        Item.Observacao     := Trim(Item.Observacao);

      end;

      if TipoPlano.CatalogoExibiPreco = 'S' then
      APedido.ValorTotal    := ValorTotalPedido
      else
      APedido.ValorTotal    := 0;

      Result.IdPedido       := TPedidoDAO.InserirPedido(Conn, APedido);

      for Item in APedido.Itens do
      begin
        Item.IdPedido     := Result.IdPedido;
        TPedidoDAO.InserirItem(Conn, Item);
      end;

      TPedidoDAO.AtualizarValorTotal(Conn, IdEmpresa, Result.IdPedido, ValorTotalPedido);

      Result.ValorTotal     := ValorTotalPedido;

      Conn.Commit;
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;

  // Registro de evento fora da transação principal.
  // Assim, se o log falhar, o pedido continua criado corretamente.
  try
    TRegistroEventoService.RegistrarPedidoCriado(IdEmpresa,Result.IdPedido,Result.ValorTotal,APedido.NomeCliente);
  except
    on E: Exception do
    begin
      // Futuramente podemos gravar erro em arquivo ou tabela separada.
    end;
  end;


  //registrar notificacao
  try
    TNotificacaoFilaService.CriarNotificacoesPedido(
      IdEmpresa,
      Result.IdPedido,
      APedido.NomeCliente,
      APedido.WhatsappCliente,
      APedido.EmailCliente,
      Result.ValorTotal
    );
  except
    on E: Exception do
    begin
      // Se a fila de notificação falhar, não cancela o pedido.
    end;
  end;


end;

class function TPedidoService.ListarPedidos(const AIdEmpresa: Int64): TObjectList<TPedidoModel>;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPedidoDAO.ListarPorEmpresa(Conn, AIdEmpresa);
  finally
    Conn.Free;
  end;
end;

class function TPedidoService.BuscarPedido(const AIdEmpresa: Int64;const AIdPedido: Int64): TPedidoModel;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Itens: TObjectList<TPedidoItemModel>;
  Item: TPedidoItemModel;
begin
  Result := nil;

  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdPedido <= 0 then
    TAppErrors.RaiseBadRequest('Pedido não informado.');

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TPedidoDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdPedido);

    if Result = nil then
      TAppErrors.RaiseNotFound('Pedido não encontrado.');

    Itens := TPedidoDAO.ListarItens(Conn, AIdEmpresa, AIdPedido);
    try
      for Item in Itens do
        Result.Itens.Add(Item);

      Itens.OwnsObjects := False;
    finally
      Itens.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TPedidoService.AtualizarStatus(const AIdEmpresa: Int64;const AIdPedido: Int64;const AStatus: string);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  PedidoAtual: TPedidoModel;
  Status: string;
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada no token.');

  if AIdPedido <= 0 then
    TAppErrors.RaiseBadRequest('Pedido não informado.');

  Status := NormalizarStatus(AStatus);
  ValidarStatusPedido(Status);

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    PedidoAtual := TPedidoDAO.BuscarPorIdEmpresa(Conn, AIdEmpresa, AIdPedido);
    try
      if PedidoAtual = nil then
        TAppErrors.RaiseNotFound('Pedido não encontrado.');

      TPedidoDAO.AtualizarStatus(Conn, AIdEmpresa, AIdPedido, Status);
    finally
      PedidoAtual.Free;
    end;
  finally
    Conn.Free;
  end;

  // Registra o evento fora do fluxo principal.
  // Se o log falhar, não desfaz nem bloqueia a alteração do status.
  try
    TRegistroEventoService.RegistrarStatusPedidoAlterado(
      AIdEmpresa,
      0,
      AIdPedido,
      Status
    );
  except
    on E: Exception do
    begin
      // arquivo de log.
      // Por enquanto não interrompe o fluxo.
    end;
  end;
end;

end.
