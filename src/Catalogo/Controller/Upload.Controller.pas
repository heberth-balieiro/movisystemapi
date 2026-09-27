unit Upload.Controller;

interface

type
  TUploadController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  Horse.Upload,
  System.SysUtils,
  System.JSON,
  System.IOUtils,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors,
  App.Classes,
  App.Token,
  Produto.Service,
  ProdutoImagem.Model,
  ProdutoImagem.Service,
  System.Generics.Collections,
  Categoria.Service;

function NormalizarTipoCatalogoUpload(const ATipo: string): string;
begin
  Result := LowerCase(Trim(ATipo));
  if (Result <> 'logo') and (Result <> 'banner') then
    TAppErrors.RaiseBadRequest('Tipo de upload inválido. Use logo ou banner.');
end;

function LimparNomeArquivo(const ANome: string): string;
var
  S: string;
begin
  S := Trim(ANome);

  S := StringReplace(S, ' ', '-', [rfReplaceAll]);
  S := StringReplace(S, '\', '-', [rfReplaceAll]);
  S := StringReplace(S, '/', '-', [rfReplaceAll]);
  S := StringReplace(S, ':', '-', [rfReplaceAll]);
  S := StringReplace(S, '*', '-', [rfReplaceAll]);
  S := StringReplace(S, '?', '-', [rfReplaceAll]);
  S := StringReplace(S, '"', '-', [rfReplaceAll]);
  S := StringReplace(S, '<', '-', [rfReplaceAll]);
  S := StringReplace(S, '>', '-', [rfReplaceAll]);
  S := StringReplace(S, '|', '-', [rfReplaceAll]);

  while Pos('--', S) > 0 do
    S := StringReplace(S, '--', '-', [rfReplaceAll]);

  Result := LowerCase(S);
end;

function MontarUrlArquivo(
  const ABaseUrl: string;
  const AIdEmpresa: Int64;
  const AIdProduto: Int64;
  const ANomeArquivo: string
): string;
begin
  Result :=
    ABaseUrl.TrimRight(['/']) +
    '/produtos/' +
    AIdEmpresa.ToString +
    '/' +
    AIdProduto.ToString +
    '/' +
    ANomeArquivo;
end;

function MontarUrlArquivoCatalogo(
  const ABaseUrl: string;
  const AIdEmpresa: Int64;
  const ATipo: string;
  const ANomeArquivo: string
): string;
begin
  Result :=
    ABaseUrl.TrimRight(['/']) +
    '/catalogo/' +
    AIdEmpresa.ToString +
    '/' +
    LowerCase(Trim(ATipo)) +
    '/' +
    ANomeArquivo;
end;

function MontarUrlArquivoCategoria(const ABaseUrl: string;const AIdEmpresa: Int64;const AIdCategoria: Int64; const ANomeArquivo: string
): string;
begin
  Result :=
    ABaseUrl.TrimRight(['/']) +
    '/categoria/' +
    AIdEmpresa.ToString +
    '/' +
    AIdCategoria.ToString +
    '/' +
    ANomeArquivo;
end;


function GetContentTypeArquivo(const ANomeArquivo: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(ANomeArquivo));

  if (Ext = '.jpg') or (Ext = '.jpeg') then
    Result := 'image/jpeg'
  else if Ext = '.png' then
    Result := 'image/png'
  else if Ext = '.gif' then
    Result := 'image/gif'
  else if Ext = '.webp' then
    Result := 'image/webp'
  else if Ext = '.svg' then
    Result := 'image/svg+xml'
  else
    Result := 'application/octet-stream';
end;

function ExtensaoPermitida(const ANomeArquivo: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(ANomeArquivo));

  Result :=
    (Ext = '.jpg') or
    (Ext = '.jpeg') or
    (Ext = '.png') or
    (Ext = '.webp') or
    (Ext = '.gif');
end;

function ArquivoDentroDoLimite(const ASize: Int64; const AMaxMB: Integer): Boolean;
var
  MaxBytes: Int64;
begin
  MaxBytes := Int64(AMaxMB) * 1024 * 1024;
  Result := ASize <= MaxBytes;
end;

function ProdutoPossuiImagem(
  const AIdEmpresa: Int64;
  const AIdProduto: Int64
): Boolean;
var
  Lista: System.Generics.Collections.TObjectList<TProdutoImagemModel>;
begin
  Result := False;

  Lista := TProdutoImagemService.ListarImagens(AIdEmpresa, AIdProduto);
  try
    Result := Lista.Count > 0;
  finally
    Lista.Free;
  end;
end;

class procedure TUploadController.Registry;
begin
  THorse.Post('/v1/uploads/produtos/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdProduto: Int64;
      Config: TAppApiConfig;
      PastaBase: string;
      PastaProduto: string;
      UploadConfig: TUploadConfig;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        IdProduto := StrToInt64Def(Req.Params['id'], 0);

        if IdProduto <= 0 then
          TAppErrors.RaiseBadRequest('Produto não informado.');

        // Valida se o produto pertence à empresa logada.
        // Se não existir, o service já dispara erro.
        with TProdutoService.BuscarProduto(Claims.IdEmpresa, IdProduto) do
        begin
          Free;
        end;

        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);
        PastaProduto := TPath.Combine(
          TPath.Combine(
            TPath.Combine(PastaBase, 'produtos'),
            Claims.IdEmpresa.ToString
          ),
          IdProduto.ToString
        );

        ForceDirectories(PastaProduto);

        UploadConfig := TUploadConfig.Create(PastaProduto);
        UploadConfig.ForceDir := True;
        UploadConfig.OverrideFiles := False;

        UploadConfig.UploadFileCallBack :=
        procedure(Sender: TObject; AFile: TUploadFileInfo)
        var
          NomeArquivo: string;
          UrlImagem: string;
          Imagem: TProdutoImagemModel;
          PrimeiraImagem: Boolean;
        begin
          NomeArquivo := LimparNomeArquivo(ExtractFileName(AFile.filename));

          if NomeArquivo.Trim.IsEmpty then
            NomeArquivo := 'imagem-produto.jpg';

          if not ExtensaoPermitida(NomeArquivo) then
            TAppErrors.RaiseBadRequest('Extensão de imagem não permitida. Use JPG, JPEG, PNG, WEBP ou GIF.');

          if not ArquivoDentroDoLimite(AFile.Size, Config.Upload.MaxMB) then
            TAppErrors.RaiseBadRequest(
              'Imagem excede o tamanho máximo permitido de ' +
              Config.Upload.MaxMB.ToString +
              ' MB.'
            );

          UrlImagem := MontarUrlArquivo(
            Config.Upload.PublicURL,
            Claims.IdEmpresa,
            IdProduto,
            NomeArquivo
          );

          PrimeiraImagem := not ProdutoPossuiImagem(Claims.IdEmpresa, IdProduto);

          Imagem := TProdutoImagemModel.Create;
          try
            Imagem.UrlImagem := UrlImagem;

            if PrimeiraImagem then
              Imagem.Principal := 'S'
            else
              Imagem.Principal := 'N';

            Imagem.Ordem := 0;

            TProdutoImagemService.CriarImagem(
              Claims.IdEmpresa,
              IdProduto,
              Imagem
            );
          finally
            Imagem.Free;
          end;
        end;

        Res.Send<TUploadConfig>(UploadConfig);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  //Imagem para categoria

  THorse.Post('/v1/uploads/categorias/:id',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    IdCategoria: Int64;
    Config: TAppApiConfig;
    PastaBase: string;
    PastaCategoria: string;
    UploadConfig: TUploadConfig;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      IdCategoria := StrToInt64Def(Req.Params['id'], 0);

      if IdCategoria <= 0 then
        TAppErrors.RaiseBadRequest('Categoria não informada.');

      // Valida se a categoria pertence à empresa logada.
      // Se não existir, o service já dispara erro.
      with TCategoriaService.BuscarCategoria(Claims.IdEmpresa, IdCategoria) do
      begin
        Free;
      end;

      Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

      PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);

      // Estrutura física:
      // uploads/categoria/{id_empresa}/{id_categoria}
      PastaCategoria := TPath.Combine(
        TPath.Combine(
          TPath.Combine(PastaBase, 'categoria'),
          Claims.IdEmpresa.ToString
        ),
        IdCategoria.ToString
      );

      ForceDirectories(PastaCategoria);

      UploadConfig := TUploadConfig.Create(PastaCategoria);
      UploadConfig.ForceDir := True;
      UploadConfig.OverrideFiles := True;

      UploadConfig.UploadFileCallBack :=
        procedure(Sender: TObject; AFile: TUploadFileInfo)
        var
          NomeArquivoOriginal: string;
          NomeArquivo: string;
          Extensao: string;
          CaminhoOrigem: string;
          CaminhoDestino: string;
          UrlImagem: string;
        begin
          NomeArquivoOriginal := ExtractFileName(AFile.filename);
          Extensao := LowerCase(ExtractFileExt(NomeArquivoOriginal));

          NomeArquivo := LimparNomeArquivo(NomeArquivoOriginal);

          if NomeArquivo.Trim.IsEmpty then
            NomeArquivo := 'categoria' + Extensao;

          if not ExtensaoPermitida(NomeArquivo) then
          begin
            CaminhoOrigem := AFile.filename;

            if not TFile.Exists(CaminhoOrigem) then
              CaminhoOrigem := TPath.Combine(PastaCategoria, NomeArquivoOriginal);

            if TFile.Exists(CaminhoOrigem) then
              TFile.Delete(CaminhoOrigem);

            TAppErrors.RaiseBadRequest(
              'Extensão de imagem não permitida. Use JPG, JPEG, PNG, WEBP ou GIF.'
            );
          end;

          if not ArquivoDentroDoLimite(AFile.Size, Config.Upload.MaxMB) then
          begin
            CaminhoOrigem := AFile.filename;

            if not TFile.Exists(CaminhoOrigem) then
              CaminhoOrigem := TPath.Combine(PastaCategoria, NomeArquivoOriginal);

            if TFile.Exists(CaminhoOrigem) then
              TFile.Delete(CaminhoOrigem);

            TAppErrors.RaiseBadRequest(
              'Imagem excede o tamanho máximo permitido de ' +
              Config.Upload.MaxMB.ToString +
              ' MB.'
            );
          end;

          // Padroniza o nome salvo para evitar espaços/caracteres inválidos.
          CaminhoOrigem := AFile.filename;

          if not TFile.Exists(CaminhoOrigem) then
            CaminhoOrigem := TPath.Combine(PastaCategoria, NomeArquivoOriginal);

          CaminhoDestino := TPath.Combine(PastaCategoria, NomeArquivo);

          if TFile.Exists(CaminhoOrigem) and
             (not SameText(CaminhoOrigem, CaminhoDestino)) then
          begin
            if TFile.Exists(CaminhoDestino) then
              TFile.Delete(CaminhoDestino);

            TFile.Move(CaminhoOrigem, CaminhoDestino);
          end;

          UrlImagem := MontarUrlArquivoCategoria(
            Config.Upload.PublicURL,
            Claims.IdEmpresa,
            IdCategoria,
            NomeArquivo
          );

          // Atualiza a coluna categoria.imagem_url.
          TCategoriaService.AtualizarImagemCategoria(
            Claims.IdEmpresa,
            IdCategoria,
            UrlImagem
          );
        end;

      Res.Send<TUploadConfig>(UploadConfig);
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);








  THorse.Get('/v1/public/arquivos/produtos/:id_empresa/:id_produto/:arquivo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Config: TAppApiConfig;
      IdEmpresa: Int64;
      IdProduto: Int64;
      NomeArquivo: string;
      PastaBase: string;
      CaminhoArquivo: string;
    begin
      try
        IdEmpresa := StrToInt64Def(Req.Params['id_empresa'], 0);
        IdProduto := StrToInt64Def(Req.Params['id_produto'], 0);
        NomeArquivo := LimparNomeArquivo(Req.Params['arquivo']);

        if IdEmpresa <= 0 then
          TAppErrors.RaiseBadRequest('Empresa não informada.');

        if IdProduto <= 0 then
          TAppErrors.RaiseBadRequest('Produto não informado.');

        if NomeArquivo.Trim.IsEmpty then
          TAppErrors.RaiseBadRequest('Arquivo não informado.');

        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);

        CaminhoArquivo := TPath.Combine(
          TPath.Combine(
            TPath.Combine(
              TPath.Combine(PastaBase, 'produtos'),
              IdEmpresa.ToString
            ),
            IdProduto.ToString
          ),
          NomeArquivo
        );

        if not TFile.Exists(CaminhoArquivo) then
        begin
          TAppResponse.NotFound(Res, 'Arquivo não encontrado.');
          Exit;
        end;

        Res.RawWebResponse.ContentType := GetContentTypeArquivo(NomeArquivo);
        Res.SendFile(CaminhoArquivo);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

    //listar categoria publico
    THorse.Get('/v1/public/arquivos/categoria/:id_empresa/:id_categoria/:arquivo',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Config: TAppApiConfig;
    IdEmpresa: Int64;
    IdCategoria: Int64;
    NomeArquivo: string;
    PastaBase: string;
    CaminhoArquivo: string;
  begin
    try
      IdEmpresa   := StrToInt64Def(Req.Params['id_empresa'], 0);
      IdCategoria := StrToInt64Def(Req.Params['id_categoria'], 0);
      NomeArquivo := LimparNomeArquivo(Req.Params['arquivo']);

      if IdEmpresa <= 0 then
        TAppErrors.RaiseBadRequest('Empresa não informada.');

      if IdCategoria <= 0 then
        TAppErrors.RaiseBadRequest('Categoria não informada.');

      if NomeArquivo.Trim.IsEmpty then
        TAppErrors.RaiseBadRequest('Arquivo não informado.');

      Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

      PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);

      CaminhoArquivo := TPath.Combine(
        TPath.Combine(
          TPath.Combine(
            TPath.Combine(PastaBase, 'categoria'),
            IdEmpresa.ToString
          ),
          IdCategoria.ToString
        ),
        NomeArquivo
      );

      if not TFile.Exists(CaminhoArquivo) then
      begin
        TAppResponse.NotFound(Res, 'Arquivo não encontrado.');
        Exit;
      end;

      Res.RawWebResponse.ContentType := GetContentTypeArquivo(NomeArquivo);
      Res.SendFile(CaminhoArquivo);
    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end);


  {$REGION 'LOGO CONFIG'}

    THorse.Post('/v1/catalogo/config/upload',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Config: TAppApiConfig;
      Tipo: string;
      PastaBase: string;
      PastaCatalogo: string;
      PastaTipo: string;
      UploadConfig: TUploadConfig;
      UrlGerada: string;
      //NomeArquivoFinal: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        Tipo := NormalizarTipoCatalogoUpload(TAppClasses.GetFormField(Req, 'tipo'));

        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);

        PastaCatalogo := TPath.Combine(
          TPath.Combine(PastaBase, 'catalogo'),
          Claims.IdEmpresa.ToString
        );

        PastaTipo := TPath.Combine(PastaCatalogo, Tipo);

        ForceDirectories(PastaTipo);

        UrlGerada := '';

        UploadConfig := TUploadConfig.Create(PastaTipo);
        UploadConfig.ForceDir := True;
        UploadConfig.OverrideFiles := True;

        UploadConfig.UploadFileCallBack :=
          procedure(Sender: TObject; AFile: TUploadFileInfo)
          var
            NomeArquivo: string;
            CaminhoArquivo: string;
          begin
            NomeArquivo := LimparNomeArquivo(ExtractFileName(AFile.filename));

            if NomeArquivo.Trim.IsEmpty then
              NomeArquivo := Tipo + '.png';

            if not ExtensaoPermitida(NomeArquivo) then
            begin
              CaminhoArquivo := TPath.Combine(PastaTipo, NomeArquivo);

              if TFile.Exists(CaminhoArquivo) then
                TFile.Delete(CaminhoArquivo);

              TAppErrors.RaiseBadRequest('Arquivo inválido. Envie uma imagem PNG, JPG, JPEG ou WEBP.');
            end;

            if not ArquivoDentroDoLimite(AFile.Size, Config.Upload.MaxMB) then
            begin
              CaminhoArquivo := TPath.Combine(PastaTipo, NomeArquivo);

              if TFile.Exists(CaminhoArquivo) then
                TFile.Delete(CaminhoArquivo);

              TAppErrors.RaiseBadRequest('Imagem excede o tamanho máximo permitido.');
            end;

            //NomeArquivoFinal := NomeArquivo;

            UrlGerada := MontarUrlArquivoCatalogo(
              Config.Upload.PublicURL,
              Claims.IdEmpresa,
              Tipo,
              NomeArquivo
            );
          end;

        Res.Send<TUploadConfig>(UploadConfig);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

    THorse.Get('/v1/public/arquivos/catalogo/:id_empresa/:tipo/:arquivo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Config: TAppApiConfig;
      IdEmpresa: Int64;
      Tipo: string;
      NomeArquivo: string;
      PastaBase: string;
      CaminhoArquivo: string;
    begin
      try
        IdEmpresa   := StrToInt64Def(Req.Params['id_empresa'], 0);
        Tipo        := NormalizarTipoCatalogoUpload(Req.Params['tipo']);
        NomeArquivo := LimparNomeArquivo(Req.Params['arquivo']);

        if IdEmpresa <= 0 then
          TAppErrors.RaiseBadRequest('Empresa não informada.');

        if NomeArquivo.Trim.IsEmpty then
          TAppErrors.RaiseBadRequest('Arquivo não informado.');

        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        PastaBase := TPath.Combine(ExtractFilePath(ParamStr(0)), Config.Upload.Pasta);

        CaminhoArquivo := TPath.Combine(
          TPath.Combine(
            TPath.Combine(
              TPath.Combine(PastaBase, 'catalogo'),
              IdEmpresa.ToString
            ),
            Tipo
          ),
          NomeArquivo
        );

        if not TFile.Exists(CaminhoArquivo) then
        begin
          TAppResponse.NotFound(Res, 'Arquivo não encontrado.');
          Exit;
        end;

        Res.RawWebResponse.ContentType := GetContentTypeArquivo(NomeArquivo);
        Res.SendFile(CaminhoArquivo);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);


  {$ENDREGION}

end;

end.
