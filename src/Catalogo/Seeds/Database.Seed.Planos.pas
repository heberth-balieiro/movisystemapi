unit Database.Seed.Planos;

interface

type
  TDatabaseSeedPlanos = class
  public
    class procedure Run; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  Database.Connection;

function PlanoExistePorDescricao(
  const AConn: TUniConnection;
  const ADescricao: string
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
      'FROM plano ' +
      'WHERE LOWER(TRIM(descricao)) = LOWER(TRIM(:descricao))';

    Qry.ParamByName('descricao').AsString := Trim(ADescricao);
    Qry.Open;

    Result := Qry.FieldByName('total').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

procedure InserirPlano(
  const AConn: TUniConnection;
  const ADescricao: string;
  const AValor: Currency;
  const AValorAnual: Currency;
  const AProdutoQtde: Integer;
  const APermiteProdutoIlimitado: string;
  const APermiteWhatsapp: string;
  const APermiteEmail: string;
  const APermitePedido: string;
  const APermiteEcommerce: string;
  const APermitePagSeguro: string;
  const APermitePedidoFicha: string;
  const APermiteConfigVisual: string;
  const ARecursos: string;
  const Apermiteconfigcupom: string;
  const Atipocatalogopadrao:string
);
var
  Qry: TUniQuery;
begin
  if PlanoExistePorDescricao(AConn, ADescricao) then
    Exit;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO plano (' +
      ' descricao, valor, catalogo, catalogo_qtde, interno, ativo, valor_anual, produto_qtde, ' +
      ' permite_produto_ilimitado, permite_whatsapp, permite_email, permite_pedido, ' +
      ' permite_ecommerce, permite_pagseguro, permite_pedido_ficha, permite_config_visual, recursos,permite_config_cupom, tipo_catalogo_padrao ' +
      ') VALUES (' +
      ' :descricao, :valor, :catalogo, :catalogo_qtde, :interno, :ativo, :valor_anual, :produto_qtde, ' +
      ' :permite_produto_ilimitado, :permite_whatsapp, :permite_email, :permite_pedido, ' +
      ' :permite_ecommerce, :permite_pagseguro, :permite_pedido_ficha, :permite_config_visual, :recursos, ' +
      ' :permite_config_cupom, :tipo_catalogo_padrao'+
      ')';

    Qry.ParamByName('descricao').AsString         := ADescricao;
    Qry.ParamByName('valor').AsCurrency           := AValor;
    Qry.ParamByName('catalogo').AsString          := 'S';
    Qry.ParamByName('catalogo_qtde').AsInteger    := 0;
    Qry.ParamByName('interno').AsString           := 'N';
    Qry.ParamByName('ativo').AsString             := 'S';
    Qry.ParamByName('valor_anual').AsCurrency     := AValorAnual;
    Qry.ParamByName('produto_qtde').AsInteger     := AProdutoQtde;

    Qry.ParamByName('permite_produto_ilimitado').AsString := APermiteProdutoIlimitado;
    Qry.ParamByName('permite_whatsapp').AsString          := APermiteWhatsapp;
    Qry.ParamByName('permite_email').AsString             := APermiteEmail;
    Qry.ParamByName('permite_pedido').AsString            := APermitePedido;
    Qry.ParamByName('permite_ecommerce').AsString         := APermiteEcommerce;
    Qry.ParamByName('permite_pagseguro').AsString         := APermitePagSeguro;
    Qry.ParamByName('permite_pedido_ficha').AsString      := APermitePedidoFicha;
    Qry.ParamByName('permite_config_visual').AsString     := APermiteConfigVisual;
    Qry.ParamByName('recursos').AsString                  := ARecursos;
    Qry.ParamByName('permite_config_cupom').AsString      := Apermiteconfigcupom;
    Qry.ParamByName('tipo_catalogo_padrao').AsString      := Atipocatalogopadrao;

    Qry.Execute;
  finally
    Qry.Free;
  end;
end;

class procedure TDatabaseSeedPlanos.Run;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Conn.StartTransaction;
    try
      InserirPlano(Conn, 'Easy Vitrine Start', 49.90, 449.00, 20, 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'Catálogo vitrine com até 20 produtos. Ideal para pequenas empresas que desejam apenas divulgar produtos, sem pedidos, WhatsApp, e-mail ou integrações.', 'N', 'VITRINE');
      InserirPlano(Conn, 'Easy Vitrine Plus', 79.90, 719.00, 50, 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'S', 'Catálogo vitrine com até 50 produtos, configuração visual, logo, banner, redes sociais e páginas institucionais. Sem pedidos, WhatsApp, e-mail ou integrações.', 'N', 'VITRINE');
      InserirPlano(Conn, 'Easy Pedido', 119.90, 1079.00, 0, 'S', 'S', 'S', 'S', 'N', 'N', 'N', 'S', 'Catálogo com produtos ilimitados, pedido ou orçamento pelo catálogo, notificações por WhatsApp e e-mail, além de configuração visual.', 'N', 'PEDIDO_ORCAMENTO');
      InserirPlano(Conn, 'Easy Ficha', 149.90, 1349.00, 0, 'S', 'S', 'S', 'S', 'N', 'N', 'S', 'S', 'Catálogo com produtos ilimitados e pedidos por ficha, mesa ou comanda. Ideal para padarias, restaurantes, lanchonetes e atendimento de balcão.', 'N', 'PEDIDO_ORCAMENTO');
      InserirPlano(Conn, 'Easy Commerce', 199.90, 1799.00, 0, 'S', 'S', 'S', 'S', 'S', 'N', 'N', 'S', 'Catálogo com produtos ilimitados, carrinho de compras, e-commerce habilitado, pedidos online, WhatsApp, e-mail e configuração visual.', 'S', 'ECOMMERCE');
      InserirPlano(Conn, 'Easy Pay', 249.90, 2249.00, 0, 'S', 'S', 'S', 'S', 'S', 'S', 'N', 'S', 'Catálogo com e-commerce completo, integração PagSeguro, pagamentos online, produtos ilimitados, pedidos, WhatsApp, e-mail e configuração visual.', 'S', 'ECOMMERCE');

      Conn.Commit;

      Writeln('Seed PLANOS executado com sucesso.');
    except
      Conn.Rollback;
      raise;
    end;
  finally
    Conn.Free;
  end;
end;

end.
