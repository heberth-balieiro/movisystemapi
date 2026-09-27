unit CatalogoPublic.DAO;

interface

uses
  Uni,
  System.JSON;

type
  TCatalogoPublicDAO = class
  private

  public
    class function BuscarCatalogoPorSlug(const AConn: TUniConnection;const ASlug: string): TJSONObject; static;
    class function BuscarCatalogoPorSlugProduto(const AConn: TUniConnection;const ASlug: string; IDProduto: Int64): TJSONObject; static;
    class function BuscarCatalogoPorSlugDestaque(const AConn: TUniConnection;const ASlug: string): TJSONObject; static;
  end;

implementation

uses
  System.SysUtils,
  Assinatura.Service;

class function TCatalogoPublicDAO.BuscarCatalogoPorSlug(const AConn: TUniConnection;const ASlug: string): TJSONObject;
var
  QryConfig       : TUniQuery;
  QryCategorias   : TUniQuery;
  QryProdutos     : TUniQuery;
  QryImagem       : TUniQuery;
  CatalogoJson    : TJSONObject;
  EmpresaJson     : TJSONObject;
  CategoriasArray : TJSONArray;
  CategoriaJson   : TJSONObject;
  ProdutosArray   : TJSONArray;
  ImagemArray     : TJSONArray;
  ImagemJson      : TJSONObject;
  ProdutoJson     : TJSONObject;
  IdEmpresa       : Int64;
  IdCategoria     : Int64;
begin
  Result := nil;

  QryConfig       := TUniQuery.Create(nil);
  QryCategorias   := TUniQuery.Create(nil);
  QryProdutos     := TUniQuery.Create(nil);
  QryImagem       := TUniQuery.Create(nil);

  try
    QryConfig.Connection      := AConn;
    QryCategorias.Connection  := AConn;
    QryProdutos.Connection    := AConn;
    QryImagem.Connection      := AConn;

    QryConfig.SQL.Text :=
      'SELECT ' +
      ' cc.id_config, cc.id_empresa, cc.slug, cc.titulo_catalogo, cc.descricao, ' +
      ' cc.cor_primaria, cc.cor_secundaria, cc.logo_url, cc.banner_url, ' +
      ' cc.mostrar_preco, cc.permitir_observacao, cc.permitir_retirada, ' +
      ' cc.permitir_entrega, cc.valor_minimo_pedido, cc.ativo AS catalogo_ativo, ' +
      ' e.nome AS empresa_nome, e.whatsapp, e.email, e.ativo AS empresa_ativo, e.data_validade, ' +
      ' e.cnpj, e.cep, e.endereco, e.numero, e.complemento, e.bairro, e.cidade, e.uf,'+
      ' cc.facebook_url, cc.instagram_url, cc.tiktok_url, cc.youtube_url, cc.imagens_destaque, '+
      ' cc.permitir_consignado, cc.exigir_cliente_cadastrado, cc.compra_sem_cadastro, cc.permitir_ficha, '+
      ' cc.ecommerce, cc.pagseguro,'+
      ' cc.links_sobrenos, cc.links_privacidade, cc.links_termos, cc.tipo_catalogo, a.situacao, a.trial_termina_em, a.proximo_vencimento '+
      ' FROM catalogo_config cc ' +
      ' INNER JOIN empresa e   '+
      ' ON e.id_empresa = cc.id_empresa ' +
      ' inner join assinatura a  '+
      ' on e.id_empresa = a.id_empresa '+
      ' WHERE LOWER(TRIM(cc.slug)) = LOWER(TRIM(:slug)) ' +
      ' LIMIT 1';

    QryConfig.ParamByName('slug').AsString          := Trim(ASlug);
    QryConfig.Open;

    if QryConfig.IsEmpty then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('catalogo_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('empresa_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('situacao').AsString)) = 'TRIAL' then
    begin
      if QryConfig.FieldByName('trial_termina_em').AsDateTime < Date then
      Exit(nil);
    end
    else
    begin
      if QryConfig.FieldByName('proximo_vencimento').AsDateTime < Date then
      Exit(nil);
    end;

    IdEmpresa := QryConfig.FieldByName('id_empresa').AsLargeInt;

    //validar catalogo
    TAssinaturaService.ValidarAcessoCatalogoPublico(IdEmpresa);


    CatalogoJson := TJSONObject.Create;
    CatalogoJson.AddPair('id_config',               TJSONNumber.Create(QryConfig.FieldByName('id_config').AsLargeInt));
    CatalogoJson.AddPair('id_empresa',              TJSONNumber.Create(IdEmpresa));
    CatalogoJson.AddPair('slug',                    QryConfig.FieldByName('slug').AsString);
    CatalogoJson.AddPair('titulo_catalogo',         QryConfig.FieldByName('titulo_catalogo').AsString);
    CatalogoJson.AddPair('descricao',               QryConfig.FieldByName('descricao').AsString);
    CatalogoJson.AddPair('cor_primaria',            QryConfig.FieldByName('cor_primaria').AsString);
    CatalogoJson.AddPair('cor_secundaria',          QryConfig.FieldByName('cor_secundaria').AsString);
    CatalogoJson.AddPair('logo_url',                QryConfig.FieldByName('logo_url').AsString);
    CatalogoJson.AddPair('banner_url',              QryConfig.FieldByName('banner_url').AsString);
    CatalogoJson.AddPair('mostrar_preco',           QryConfig.FieldByName('mostrar_preco').AsString);
    CatalogoJson.AddPair('permitir_observacao',     QryConfig.FieldByName('permitir_observacao').AsString);
    CatalogoJson.AddPair('permitir_retirada',       QryConfig.FieldByName('permitir_retirada').AsString);
    CatalogoJson.AddPair('permitir_entrega',        QryConfig.FieldByName('permitir_entrega').AsString);
    CatalogoJson.AddPair('valor_minimo_pedido',     TJSONNumber.Create(QryConfig.FieldByName('valor_minimo_pedido').AsCurrency));

    CatalogoJson.AddPair('facebook_url',            QryConfig.FieldByName('facebook_url').AsString);
    CatalogoJson.AddPair('instagram_url',           QryConfig.FieldByName('instagram_url').AsString);
    CatalogoJson.AddPair('tiktok_url',              QryConfig.FieldByName('tiktok_url').AsString);
    CatalogoJson.AddPair('youtube_url',             QryConfig.FieldByName('youtube_url').AsString);
    CatalogoJson.AddPair('imagens_destaque',        QryConfig.FieldByName('imagens_destaque').AsString);

    CatalogoJson.AddPair('links_sobrenos',          QryConfig.FieldByName('links_sobrenos').AsString);
    CatalogoJson.AddPair('links_privacidade',       QryConfig.FieldByName('links_privacidade').AsString);
    CatalogoJson.AddPair('links_termos',            QryConfig.FieldByName('links_termos').AsString);
    CatalogoJson.AddPair('permitir_consignado',     QryConfig.FieldByName('permitir_consignado').AsString);
    CatalogoJson.AddPair('exigir_cliente_cadastrado', QryConfig.FieldByName('exigir_cliente_cadastrado').AsString);
    CatalogoJson.AddPair('compra_sem_cadastro',     QryConfig.FieldByName('compra_sem_cadastro').AsString);
    CatalogoJson.AddPair('permitir_ficha',          QryConfig.FieldByName('permitir_ficha').AsString);
    CatalogoJson.AddPair('ecommerce',               QryConfig.FieldByName('ecommerce').AsString);
    CatalogoJson.AddPair('pagseguro',               QryConfig.FieldByName('pagseguro').AsString);
    Catalogojson.AddPair('tipo_catalogo',           QryConfig.FieldByName('tipo_catalogo').AsString);


    EmpresaJson := TJSONObject.Create;
    EmpresaJson.AddPair('id_empresa',               TJSONNumber.Create(IdEmpresa));
    EmpresaJson.AddPair('nome',                     QryConfig.FieldByName('empresa_nome').AsString);
    EmpresaJson.AddPair('whatsapp',                 QryConfig.FieldByName('whatsapp').AsString);
    EmpresaJson.AddPair('email',                    QryConfig.FieldByName('email').AsString);
    EmpresaJson.AddPair('cnpj',                     QryConfig.FieldByName('cnpj').AsString);
    EmpresaJson.AddPair('cep',                      QryConfig.FieldByName('cep').AsString);
    EmpresaJson.AddPair('endereco',                 QryConfig.FieldByName('endereco').AsString);
    EmpresaJson.AddPair('numero',                   QryConfig.FieldByName('numero').AsString);
    EmpresaJson.AddPair('complemento',              QryConfig.FieldByName('complemento').AsString);
    EmpresaJson.AddPair('bairro',                   QryConfig.FieldByName('bairro').AsString);
    EmpresaJson.AddPair('cidade',                   QryConfig.FieldByName('cidade').AsString);
    EmpresaJson.AddPair('uf',                       QryConfig.FieldByName('uf').AsString);

    CategoriasArray := TJSONArray.Create;

    QryCategorias.SQL.Text :=
      'SELECT id_categoria, nome, descricao, ordem, imagem_url FROM categoria ' +
      ' where id_empresa = :id_empresa and ativo = ''S'' order by ordem, nome';

    QryCategorias.ParamByName('id_empresa').AsLargeInt := IdEmpresa;
    QryCategorias.Open;

    while not QryCategorias.Eof do
    begin
      IdCategoria := QryCategorias.FieldByName('id_categoria').AsLargeInt;

      CategoriaJson := TJSONObject.Create;
      CategoriaJson.AddPair('id_categoria',     TJSONNumber.Create(IdCategoria));
      CategoriaJson.AddPair('nome',             QryCategorias.FieldByName('nome').AsString);
      CategoriaJson.AddPair('descricao',        QryCategorias.FieldByName('descricao').AsString);
      CategoriaJson.AddPair('ordem',            TJSONNumber.Create(QryCategorias.FieldByName('ordem').AsInteger));
      CategoriaJson.AddPair('imagem_url',       QryCategorias.FieldByName('imagem_url').AsString);

      ProdutosArray := TJSONArray.Create;

      QryProdutos.Close;
      QryProdutos.SQL.Text :=
        'SELECT ' +
        ' p.id_produto, p.id_categoria, p.nome, p.descricao, p.preco, p.destaque, '+
        ' p.ordem, Coalesce(p.codigo,'''') as codigo, u.sigla, m.nome as nmmarca, '+
        ' Coalesce(p.promocao,0) as promocao, Coalesce(p.referencia,'''') as referencia, ' +
        ' Coalesce(p.tags,'''') as tags, '+
        ' COALESCE((' +
        '   SELECT pi.url_imagem ' +
        '   FROM produto_imagem pi ' +
        '   WHERE pi.id_empresa = p.id_empresa ' +
        '   AND pi.id_produto = p.id_produto ' +
        '   ORDER BY pi.principal DESC, pi.ordem, pi.id_imagem ' +
        '   LIMIT 1' +
        ' ), '''') AS imagem_principal ' +
        ' FROM produto p ' +
        ' inner join unidade u '+
        ' on p.id_unidade = u.id_unidade '+
        ' left join marca m '+
        ' on p.id_marca = m.id_marca '+
        ' where p.id_empresa = :id_empresa ' +
        ' and p.id_categoria = :id_categoria ' +
        ' and p.ativo = ''S'' ' +
        ' order by p.ordem, p.nome';

      QryProdutos.ParamByName('id_empresa').AsLargeInt  := IdEmpresa;
      QryProdutos.ParamByName('id_categoria').AsLargeInt := IdCategoria;
      QryProdutos.Open;

      while not QryProdutos.Eof do
      begin
        ProdutoJson := TJSONObject.Create;
        ProdutoJson.AddPair('id_produto',         TJSONNumber.Create(QryProdutos.FieldByName('id_produto').AsLargeInt));
        ProdutoJson.AddPair('id_categoria',       TJSONNumber.Create(QryProdutos.FieldByName('id_categoria').AsLargeInt));
        ProdutoJson.AddPair('nome',               QryProdutos.FieldByName('nome').AsString);
        ProdutoJson.AddPair('descricao',          QryProdutos.FieldByName('descricao').AsString);
        ProdutoJson.AddPair('preco',              TJSONNumber.Create(QryProdutos.FieldByName('preco').AsCurrency));
        ProdutoJson.AddPair('destaque',           QryProdutos.FieldByName('destaque').AsString);
        ProdutoJson.AddPair('ordem',              TJSONNumber.Create(QryProdutos.FieldByName('ordem').AsInteger));
        ProdutoJson.AddPair('imagem_principal',   QryProdutos.FieldByName('imagem_principal').AsString);

        ProdutoJson.AddPair('codigo',             QryProdutos.FieldByName('codigo').AsString);
        ProdutoJson.AddPair('sigla',              QryProdutos.FieldByName('sigla').AsString);
        ProdutoJson.AddPair('nmmarca',            QryProdutos.FieldByName('nmmarca').AsString);
        ProdutoJson.AddPair('promocao',           TJSONNumber.Create(QryProdutos.FieldByName('promocao').AsCurrency));
        ProdutoJson.AddPair('referencia',         QryProdutos.FieldByName('referencia').AsString);
        ProdutoJson.AddPair('tags',               QryProdutos.FieldByName('tags').AsString);

        ImagemArray         := TJSONArray.Create;
        //imagens buscar
        QryImagem.Close;
        QryImagem.SQL.Text  := 'Select id_imagem, url_imagem, principal from produto_imagem '+
                                ' where id_empresa = :id_empresa and id_produto = :id_produto ';
        QryImagem.ParamByName('id_produto').AsLargeInt    := QryProdutos.FieldByName('id_produto').AsLargeInt;
        QryImagem.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;

        QryImagem.Open;

        while not QryImagem.Eof do
        begin
          ImagemJson      := TJSONObject.Create;

          ImagemJson.AddPair('id_imagem',         TJSONNumber.Create(QryImagem.FieldByName('id_imagem').AsLargeInt));
          ImagemJson.AddPair('url_imagem',        QryImagem.FieldByName('url_imagem').AsString);
          ImagemJson.AddPair('principal',         QryImagem.FieldByName('principal').AsString);

          ImagemArray.AddElement(ImagemJson);

          QryImagem.Next;
        end;

        ProdutoJson.AddPair('imagens',ImagemArray);

        ProdutosArray.AddElement(ProdutoJson);

        //ir para o proximo produto
        QryProdutos.Next;
      end;

      CategoriaJson.AddPair('produtos', ProdutosArray);
      CategoriasArray.AddElement(CategoriaJson);

      QryCategorias.Next;
    end;

    Result := TJSONObject.Create;
    Result.AddPair('catalogo', CatalogoJson);
    Result.AddPair('empresa', EmpresaJson);
    Result.AddPair('categorias', CategoriasArray);

  finally
    QryProdutos.Free;
    QryCategorias.Free;
    QryConfig.Free;
    QryImagem.Free;
  end;
end;

class function TCatalogoPublicDAO.BuscarCatalogoPorSlugProduto(const AConn: TUniConnection;const ASlug: string; IDProduto: Int64): TJSONObject;
var
  QryConfig: TUniQuery;
  QryImagem:TUniQuery;
  QryCategorias: TUniQuery;
  QryProdutos: TUniQuery;
  CatalogoJson: TJSONObject;
  EmpresaJson: TJSONObject;
  CategoriaJson: TJSONObject;
  ProdutoJson: TJSONObject;
  RalacionadoArray : TJSONArray;
  ProdutoRelJson : TJSONObject;
  IdEmpresa: Int64;
  IdCategoria: Int64;
  ImagemArray     : TJSONArray;
  ImagemJson      : TJSONObject;
begin
  Result := nil;

  QryConfig       := TUniQuery.Create(nil);
  QryCategorias   := TUniQuery.Create(nil);
  QryProdutos     := TUniQuery.Create(nil);
  QryImagem       := TUniQuery.Create(nil);

  try
    QryConfig.Connection        := AConn;
    QryCategorias.Connection    := AConn;
    QryProdutos.Connection      := AConn;
    QryImagem.Connection        := AConn;

    QryConfig.SQL.Text :=
      'SELECT ' +
      ' cc.id_config, cc.id_empresa, cc.slug, cc.titulo_catalogo, cc.descricao, ' +
      ' cc.cor_primaria, cc.cor_secundaria, cc.logo_url, cc.banner_url, ' +
      ' cc.mostrar_preco, cc.permitir_observacao, cc.permitir_retirada, ' +
      ' cc.permitir_entrega, cc.valor_minimo_pedido, cc.ativo AS catalogo_ativo, ' +
      ' e.nome AS empresa_nome, e.whatsapp, e.email, e.ativo AS empresa_ativo, e.data_validade, ' +
      ' e.cnpj, e.cep, e.endereco, e.numero, e.complemento, e.bairro, e.cidade, e.uf,'+
      ' cc.facebook_url, cc.instagram_url, cc.tiktok_url, cc.youtube_url, cc.imagens_destaque, cc.tipo_catalogo, '+
      ' a.situacao, a.trial_termina_em, a.proximo_vencimento '+
      ' FROM catalogo_config cc ' +
      ' INNER JOIN empresa e   '+
      ' ON e.id_empresa = cc.id_empresa ' +
      ' inner join assinatura a  '+
      ' on e.id_empresa = a.id_empresa '+
      ' WHERE LOWER(TRIM(cc.slug)) = LOWER(TRIM(:slug)) ' +
      ' LIMIT 1';


    QryConfig.ParamByName('slug').AsString := Trim(ASlug);
    QryConfig.Open;

    if QryConfig.IsEmpty then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('catalogo_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('empresa_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('situacao').AsString)) = 'TRIAL' then
    begin
      if QryConfig.FieldByName('trial_termina_em').AsDateTime < Date then
      Exit(nil);
    end
    else
    begin
      if QryConfig.FieldByName('proximo_vencimento').AsDateTime < Date then
      Exit(nil);
    end;

    IdEmpresa := QryConfig.FieldByName('id_empresa').AsLargeInt;

    //catalogo
    CatalogoJson := TJSONObject.Create;
    CatalogoJson.AddPair('id_config',           TJSONNumber.Create(QryConfig.FieldByName('id_config').AsLargeInt));
    CatalogoJson.AddPair('id_empresa',          TJSONNumber.Create(IdEmpresa));
    CatalogoJson.AddPair('slug',                QryConfig.FieldByName('slug').AsString);
    CatalogoJson.AddPair('titulo_catalogo',     QryConfig.FieldByName('titulo_catalogo').AsString);
    CatalogoJson.AddPair('descricao',           QryConfig.FieldByName('descricao').AsString);
    CatalogoJson.AddPair('cor_primaria',        QryConfig.FieldByName('cor_primaria').AsString);
    CatalogoJson.AddPair('cor_secundaria',      QryConfig.FieldByName('cor_secundaria').AsString);
    CatalogoJson.AddPair('logo_url',            QryConfig.FieldByName('logo_url').AsString);
    CatalogoJson.AddPair('banner_url',          QryConfig.FieldByName('banner_url').AsString);
    CatalogoJson.AddPair('mostrar_preco',       QryConfig.FieldByName('mostrar_preco').AsString);
    CatalogoJson.AddPair('permitir_observacao', QryConfig.FieldByName('permitir_observacao').AsString);
    CatalogoJson.AddPair('permitir_retirada',   QryConfig.FieldByName('permitir_retirada').AsString);
    CatalogoJson.AddPair('permitir_entrega',    QryConfig.FieldByName('permitir_entrega').AsString);
    CatalogoJson.AddPair('valor_minimo_pedido', TJSONNumber.Create(QryConfig.FieldByName('valor_minimo_pedido').AsCurrency));
    CatalogoJson.AddPair('tipo_catalogo',       QryConfig.FieldByName('tipo_catalogo').AsString);



    //Empresa
    EmpresaJson := TJSONObject.Create;
    EmpresaJson.AddPair('id_empresa',           TJSONNumber.Create(IdEmpresa));
    EmpresaJson.AddPair('nome',                 QryConfig.FieldByName('empresa_nome').AsString);
    EmpresaJson.AddPair('whatsapp',             QryConfig.FieldByName('whatsapp').AsString);
    EmpresaJson.AddPair('email',                QryConfig.FieldByName('email').AsString);
    EmpresaJson.AddPair('cnpj',                 QryConfig.FieldByName('cnpj').AsString);
    EmpresaJson.AddPair('cep',                  QryConfig.FieldByName('cep').AsString);
    EmpresaJson.AddPair('endereco',             QryConfig.FieldByName('endereco').AsString);
    EmpresaJson.AddPair('numero',               QryConfig.FieldByName('numero').AsString);
    EmpresaJson.AddPair('complemento',          QryConfig.FieldByName('complemento').AsString);
    EmpresaJson.AddPair('bairro',               QryConfig.FieldByName('bairro').AsString);
    EmpresaJson.AddPair('cidade',               QryConfig.FieldByName('cidade').AsString);
    EmpresaJson.AddPair('uf',                   QryConfig.FieldByName('uf').AsString);

    //Produto
    QryProdutos.Close;
    QryProdutos.SQL.Text :=
        'SELECT ' +
        ' p.id_produto, p.id_categoria, p.nome, p.descricao, p.preco, p.destaque, p.ordem, ' +
        ' Coalesce(p.codigo,'''') as codigo, u.sigla, m.nome as nmmarca, '+
        ' Coalesce(p.promocao,0) as promocao, Coalesce(p.referencia,'''') as referencia, ' +
        ' Coalesce(p.tags,'''') as tags, '+
        ' COALESCE((' +
        '   SELECT pi.url_imagem ' +
        '   FROM produto_imagem pi ' +
        '   WHERE pi.id_empresa = p.id_empresa ' +
        '   AND pi.id_produto = p.id_produto ' +
        '   ORDER BY pi.principal DESC, pi.ordem, pi.id_imagem ' +
        '   LIMIT 1' +
        ' ), '''') AS imagem_principal ' +
        ' FROM produto p ' +
        ' inner join unidade u '+
        ' on p.id_unidade = u.id_unidade '+
        ' left join marca m '+
        ' on p.id_marca = m.id_marca '+
        ' where p.id_empresa = :id_empresa ' +
        ' and p.ativo = ''S'' ' +
        ' and p.id_produto= :id '+
        ' ';

    QryProdutos.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;
    QryProdutos.ParamByName('id').AsLargeInt            := IDProduto;
    QryProdutos.Open;

    IdCategoria                         :=  QryProdutos.FieldByName('id_categoria').AsLargeInt;

    ProdutoJson := TJSONObject.Create;
    ProdutoJson.AddPair('id_produto',       TJSONNumber.Create(QryProdutos.FieldByName('id_produto').AsLargeInt));
    ProdutoJson.AddPair('id_categoria',     TJSONNumber.Create(QryProdutos.FieldByName('id_categoria').AsLargeInt));
    ProdutoJson.AddPair('nome',             QryProdutos.FieldByName('nome').AsString);
    ProdutoJson.AddPair('descricao',        QryProdutos.FieldByName('descricao').AsString);
    ProdutoJson.AddPair('preco',            TJSONNumber.Create(QryProdutos.FieldByName('preco').AsCurrency));
    ProdutoJson.AddPair('destaque',         QryProdutos.FieldByName('destaque').AsString);
    ProdutoJson.AddPair('ordem',            TJSONNumber.Create(QryProdutos.FieldByName('ordem').AsInteger));
    ProdutoJson.AddPair('imagem_principal', QryProdutos.FieldByName('imagem_principal').AsString);

    ProdutoJson.AddPair('codigo',             QryProdutos.FieldByName('codigo').AsString);
    ProdutoJson.AddPair('sigla',              QryProdutos.FieldByName('sigla').AsString);
    ProdutoJson.AddPair('nmmarca',            QryProdutos.FieldByName('nmmarca').AsString);
    ProdutoJson.AddPair('promocao',           TJSONNumber.Create(QryProdutos.FieldByName('promocao').AsCurrency));
    ProdutoJson.AddPair('referencia',         QryProdutos.FieldByName('referencia').AsString);
    ProdutoJson.AddPair('tags',               QryProdutos.FieldByName('tags').AsString);

    //Imagem detalhes
    ImagemArray         := TJSONArray.Create;

    QryImagem.Close;
    QryImagem.SQL.Text  := 'Select id_imagem, url_imagem, principal from produto_imagem '+
                                ' where id_empresa = :id_empresa and id_produto = :id_produto ';
    QryImagem.ParamByName('id_produto').AsLargeInt    := IDProduto;
    QryImagem.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;

    QryImagem.Open;

    while not QryImagem.Eof do
    begin
      ImagemJson      := TJSONObject.Create;

      ImagemJson.AddPair('id_imagem',         TJSONNumber.Create(QryImagem.FieldByName('id_imagem').AsLargeInt));
      ImagemJson.AddPair('url_imagem',        QryImagem.FieldByName('url_imagem').AsString);
      ImagemJson.AddPair('principal',         QryImagem.FieldByName('principal').AsString);

      ImagemArray.AddElement(ImagemJson);

      QryImagem.Next;
    end;

    ProdutoJson.AddPair('imagens',ImagemArray);



    //Categoria
    QryCategorias.SQL.Text :=
      'SELECT id_categoria, nome, descricao, ordem ' +
      'FROM categoria ' +
      'WHERE id_empresa = :id_empresa and id_categoria= :id_categoria ' +
      'AND ativo = ''S'' ' +
      '';

    QryCategorias.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;
    Qrycategorias.ParamByName('id_categoria').AsLargeInt  := IdCategoria;
    QryCategorias.Open;

    CategoriaJson := TJSONObject.Create;
    CategoriaJson.AddPair('id_categoria', TJSONNumber.Create(IdCategoria));
    CategoriaJson.AddPair('nome', QryCategorias.FieldByName('nome').AsString);

    //Relacionados
    RalacionadoArray := TJSONArray.Create;

    QryProdutos.Close;
    QryProdutos.SQL.Text :=
        'SELECT ' +
        ' p.id_produto, p.id_categoria, p.nome, p.descricao, p.preco, p.ativo, p.destaque, p.ordem, ' +
        ' COALESCE((' +
        '   SELECT pi.url_imagem ' +
        '   FROM produto_imagem pi ' +
        '   WHERE pi.id_empresa = p.id_empresa ' +
        '   AND pi.id_produto = p.id_produto ' +
        '   ORDER BY pi.principal DESC, pi.ordem, pi.id_imagem ' +
        '   LIMIT 1' +
        ' ), '''') AS imagem_principal ' +
        ' FROM produto p ' +
        ' WHERE p.id_empresa = :id_empresa ' +
        ' AND p.id_categoria = :id_categoria ' +
        ' AND p.ativo = ''S'' ' +
        ' and p.id_produto <> :idproduto '+
        ' ORDER BY p.ordem, p.nome';

    QryProdutos.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;
    QryProdutos.ParamByName('id_categoria').AsLargeInt  := IdCategoria;
    QryProdutos.ParamByName('idproduto').AsLargeInt     := IdProduto;
    QryProdutos.Open;

    while not QryProdutos.Eof do
    begin

      ProdutoRelJson := TJSONObject.Create;
      ProdutoRelJson.AddPair('id_produto', TJSONNumber.Create(QryProdutos.FieldByName('id_produto').AsLargeInt));
      ProdutoRelJson.AddPair('id_categoria', TJSONNumber.Create(QryProdutos.FieldByName('id_categoria').AsLargeInt));
      ProdutoRelJson.AddPair('nome', QryProdutos.FieldByName('nome').AsString);
      ProdutoRelJson.AddPair('descricao', QryProdutos.FieldByName('descricao').AsString);
      ProdutoRelJson.AddPair('preco', TJSONNumber.Create(QryProdutos.FieldByName('preco').AsCurrency));
      ProdutoRelJson.AddPair('ativo', QryProdutos.FieldByName('ativo').AsString);
      ProdutoRelJson.AddPair('destaque', QryProdutos.FieldByName('destaque').AsString);
      ProdutoRelJson.AddPair('ordem', TJSONNumber.Create(QryProdutos.FieldByName('ordem').AsInteger));
      ProdutoRelJson.AddPair('imagem_principal', QryProdutos.FieldByName('imagem_principal').AsString);

      RalacionadoArray.AddElement(ProdutoRelJson);

      QryProdutos.Next;
    end;

    Result := TJSONObject.Create;
    Result.AddPair('catalogo', CatalogoJson);
    Result.AddPair('empresa', EmpresaJson);
    Result.AddPair('categoria', CategoriaJson);
    Result.AddPair('produto', ProdutoJson);
    Result.AddPair('relacionados', RalacionadoArray);

  finally
    QryProdutos.Free;
    QryCategorias.Free;
    QryConfig.Free;
    QryImagem.Free;
  end;
end;

class function TCatalogoPublicDAO.BuscarCatalogoPorSlugDestaque(const AConn: TUniConnection; const ASlug: string): TJSONObject;
var
  QryConfig: TUniQuery;
  QryProdutos: TUniQuery;
  ProdutosArray: TJSONArray;
  ProdutoJson: TJSONObject;
  IdEmpresa: Int64;
begin
  Result        := nil;
  QryConfig     := TUniQuery.Create(nil);
  QryProdutos   := TUniQuery.Create(nil);

  try
    QryConfig.Connection    := AConn;
    QryProdutos.Connection  := AConn;

    QryConfig.SQL.Text :=
      'SELECT ' +
      ' cc.id_config, cc.id_empresa, cc.slug, cc.ativo AS catalogo_ativo, e.ativo AS empresa_ativo, e.data_validade,' +
      ' a.situacao, a.trial_termina_em, a.proximo_vencimento  '+
      ' FROM catalogo_config cc ' +
      ' INNER JOIN empresa e  '+
      ' ON e.id_empresa = cc.id_empresa ' +
      ' inner join assinatura a  '+
      ' on e.id_empresa = a.id_empresa '+
      ' WHERE LOWER(TRIM(cc.slug)) = LOWER(TRIM(:slug)) ' +
      ' LIMIT 1';


    QryConfig.ParamByName('slug').AsString := Trim(ASlug);
    QryConfig.Open;

    if QryConfig.IsEmpty then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('catalogo_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('empresa_ativo').AsString)) <> 'S' then
      Exit(nil);

    if UpperCase(Trim(QryConfig.FieldByName('situacao').AsString)) = 'TRIAL' then
    begin
      if QryConfig.FieldByName('trial_termina_em').AsDateTime < Date then
      Exit(nil);
    end
    else
    begin
      if QryConfig.FieldByName('proximo_vencimento').AsDateTime < Date then
      Exit(nil);
    end;

    IdEmpresa         := QryConfig.FieldByName('id_empresa').AsLargeInt;

    ProdutosArray := TJSONArray.Create;

    QryProdutos.Close;
    QryProdutos.SQL.Text :=
        'SELECT ' +
        ' p.id_produto, p.id_empresa, p.id_categoria, c.nome as categoria, p.nome, p.descricao, p.preco, p.ativo, p.destaque, p.ordem, ' +
        ' COALESCE((' +
        '   SELECT pi.url_imagem ' +
        '   FROM produto_imagem pi ' +
        '   WHERE pi.id_empresa = p.id_empresa ' +
        '   AND pi.id_produto = p.id_produto ' +
        '   ORDER BY pi.principal DESC, pi.ordem, pi.id_imagem ' +
        '   LIMIT 1' +
        ' ), '''') AS imagem_principal ' +
        ' FROM produto p ' +
        ' Inner join categoria c '+
        ' on p.id_categoria = c.id_categoria '+
        ' WHERE p.id_empresa = :id_empresa ' +
        ' AND p.ativo = ''S'' ' +
        ' AND p.destaque = ''S'' '+
        ' ORDER BY p.ordem, p.nome limit 8';

      QryProdutos.ParamByName('id_empresa').AsLargeInt    := IdEmpresa;
      QryProdutos.Open;

      while not QryProdutos.Eof do
      begin
        ProdutoJson := TJSONObject.Create;
        ProdutoJson.AddPair('id_produto',         TJSONNumber.Create(QryProdutos.FieldByName('id_produto').AsLargeInt));
        ProdutoJson.AddPair('id_empresa',         TJSONNumber.Create(QryProdutos.FieldByName('id_empresa').AsLargeInt));
        ProdutoJson.AddPair('id_categoria',       TJSONNumber.Create(QryProdutos.FieldByName('id_categoria').AsLargeInt));
        ProdutoJson.AddPair('categoria',          QryProdutos.FieldByName('categoria').AsString);
        ProdutoJson.AddPair('nome',               QryProdutos.FieldByName('nome').AsString);
        ProdutoJson.AddPair('descricao',          QryProdutos.FieldByName('descricao').AsString);
        ProdutoJson.AddPair('preco',              TJSONNumber.Create(QryProdutos.FieldByName('preco').AsCurrency));
        ProdutoJson.AddPair('ativo',              QryProdutos.FieldByName('ativo').AsString);
        ProdutoJson.AddPair('destaque',           QryProdutos.FieldByName('destaque').AsString);
        ProdutoJson.AddPair('ordem',              TJSONNumber.Create(QryProdutos.FieldByName('ordem').AsInteger));
        ProdutoJson.AddPair('imagem_principal',   QryProdutos.FieldByName('imagem_principal').AsString);

        ProdutosArray.AddElement(ProdutoJson);

        QryProdutos.Next;
      end;

    Result := TJSONObject.Create;
    Result.AddPair('produtos', ProdutosArray);
  finally
    QryProdutos.Free;
    QryConfig.Free;
  end;
end;

end.
