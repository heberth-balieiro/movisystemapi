unit InstituicaoCertificadoDocumento.Service;

interface

uses
  InstituicaoCertificado.Model;

type
  TInstituicaoCertificadoDocumentoService = class
  private
    class function HtmlEncode(
      const AValor: string
    ): string; static;

    class function CargaHorariaTexto(
      const AMinutos: Integer
    ): string; static;

    class function GerarNomeTemporario(
      const AExtensao: string
    ): string; static;

    class function Sha256Arquivo(
      const AArquivo: string
    ): string; static;

    class function SanitizeFileName(
      const AValor: string
    ): string; static;

    class function MontarUrlValidacao(
      const ABaseUrl,
            ACodigo: string
    ): string; static;

    class function RenderizarTemplate(
      const ATemplateHtml,
            AImagemFundoUrl,
            ATextoValidacao,
            AQrSvg,
            AUrlValidacao: string;
      const ACertificado: TCertificadoItem
    ): string; static;

    class function GerarQrCodeSvg(
      const AUrlValidacao: string
    ): string; static;

    class procedure GerarPdfChromium(
      const AExecutable,
            AExtraArgs,
            AArquivoHtml,
            AArquivoPdf: string
    ); static;

  public
    class function ResolverCaminhoPdf(const AIdInstituicao: Int64;
      const AStorageKey: string): string; static;
    class function CaminhoPdf(const AIdInstituicao, AIdCertificado,
      AIdUsuarioInstituicao: Int64): string; static;
    class function GerarPdf(
      const AIdInstituicao,
            AIdCertificado,
            AUsuarioInstituicao: Int64
    ): TCertificadoItem; static;
  end;

implementation

uses
  System.SysUtils,
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ENDIF}
  System.Classes,
  System.IOUtils,
  System.Hash,
  System.DateUtils,
  System.Generics.Collections,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  App.ProcessRunner,
  InstituicaoCertificadoDocumento.Config,
  InstituicaoCertificadoDocumento.Model,
  InstituicaoCertificadoDocumento.DAO,
  InstituicaoCertificado.Service,
  InstituicaoPermissao.Service,
  DelphiZXingQRCode;

class function TInstituicaoCertificadoDocumentoService.ResolverCaminhoPdf(
  const AIdInstituicao: Int64; const AStorageKey: string): string;
var
  Config: TCertificadoDocumentoConfig;
  Key, Base, Parte, Caminho: string;
  Partes: TArray<string>;
  {$IFDEF MSWINDOWS}
  Attr: DWORD;
  {$ENDIF}
begin
  Key := Trim(AStorageKey);
  if (AIdInstituicao <= 0) or
     not Key.StartsWith('certificados/' + IntToStr(AIdInstituicao) + '/') or
     (Pos('\', Key) > 0) or (Pos(':', Key) > 0) or
     not SameText(ExtractFileExt(Key), '.pdf') then
    TAppErrors.RaiseForbidden('Referência de documento inválida.');

  Partes := Key.Split(['/']);
  for Parte in Partes do
    if (Parte = '') or (Parte = '.') or (Parte = '..') or
       (Trim(Parte) <> Parte) or Parte.EndsWith('.') or
       (Pos(#0, Parte) > 0) then
      TAppErrors.RaiseForbidden('Referência de documento inválida.');

  Config := TInstituicaoCertificadoDocumentoConfig.Carregar(False);
  Base := IncludeTrailingPathDelimiter(ExpandFileName(Config.StoragePath));
  Result := ExpandFileName(TPath.Combine(Base,
    StringReplace(Key, '/', PathDelim, [rfReplaceAll])));
  {$IFDEF MSWINDOWS}
  if not SameText(Copy(Result, 1, Length(Base)), Base) then
  {$ELSE}
  if Copy(Result, 1, Length(Base)) <> Base then
  {$ENDIF}
    TAppErrors.RaiseForbidden('Referência de documento inválida.');

  // No Windows, recusar junctions e links em qualquer componente do caminho.
  {$IFDEF MSWINDOWS}
  Caminho := Result;
  while Caminho <> '' do
  begin
    Attr := GetFileAttributes(PChar(Caminho));
    if (Attr <> INVALID_FILE_ATTRIBUTES) and
       ((Attr and FILE_ATTRIBUTE_REPARSE_POINT) <> 0) then
      TAppErrors.RaiseForbidden('Links de arquivos não são permitidos no storage.');
    Parte := ExtractFileDir(Caminho);
    if Parte = Caminho then Break;
    Caminho := Parte;
  end;
  {$ENDIF}

  if not TFile.Exists(Result) then
    TAppErrors.RaiseBadRequest('PDF do certificado não está disponível.');
end;

class function TInstituicaoCertificadoDocumentoService.CaminhoPdf(
  const AIdInstituicao, AIdCertificado, AIdUsuarioInstituicao: Int64): string;
var
  Item: TCertificadoItem;
begin
  TInstituicaoPermissaoService.Exigir(AIdInstituicao, AIdUsuarioInstituicao,
    'certificado.visualizar');
  Item := TInstituicaoCertificadoService.BuscarPorId(AIdInstituicao, AIdCertificado);
  try
    if not SameText(Item.Situacao, 'VALIDO') or Trim(Item.PdfStorageKey).IsEmpty then
      TAppErrors.RaiseBadRequest('PDF do certificado não está disponível.');
    Result := ResolverCaminhoPdf(AIdInstituicao, Item.PdfStorageKey);
  finally
    Item.Free;
  end;
end;

class function TInstituicaoCertificadoDocumentoService.HtmlEncode(
  const AValor: string
): string;
begin
  Result :=
    StringReplace(
      AValor,
      '&',
      '&amp;',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '<',
      '&lt;',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '>',
      '&gt;',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '"',
      '&quot;',
      [rfReplaceAll]
    );

  Result :=
    StringReplace(
      Result,
      '''',
      '&#39;',
      [rfReplaceAll]
    );
end;

class function TInstituicaoCertificadoDocumentoService.CargaHorariaTexto(
  const AMinutos: Integer
): string;
var
  Horas: Integer;
  Minutos: Integer;
begin
  Horas :=
    AMinutos div 60;

  Minutos :=
    AMinutos mod 60;

  if Minutos = 0 then
    Result :=
      Format(
        '%dh',
        [
          Horas
        ]
      )
  else
    Result :=
      Format(
        '%dh%02d',
        [
          Horas,
          Minutos
        ]
      );
end;

class function TInstituicaoCertificadoDocumentoService.GerarNomeTemporario(
  const AExtensao: string
): string;
var
  Guid: TGUID;
  Nome: string;
begin
  CreateGUID(
    Guid
  );

  Nome :=
    GUIDToString(
      Guid
    );

  Nome :=
    StringReplace(
      Nome,
      '{',
      '',
      [rfReplaceAll]
    );

  Nome :=
    StringReplace(
      Nome,
      '}',
      '',
      [rfReplaceAll]
    );

  Nome :=
    StringReplace(
      Nome,
      '-',
      '',
      [rfReplaceAll]
    );

  Result :=
    TPath.Combine(
      TPath.GetTempPath,
      LowerCase(
        Nome
      ) +
      AExtensao
    );
end;

class function TInstituicaoCertificadoDocumentoService.Sha256Arquivo(
  const AArquivo: string
): string;
var
  Stream: TFileStream;
begin
  Stream :=
    TFileStream.Create(
      AArquivo,
      fmOpenRead or fmShareDenyWrite
    );

  try
    Result :=
      LowerCase(
        THashSHA2.GetHashString(
          Stream,
          THashSHA2.TSHA2Version.SHA256
        )
      );

  finally
    Stream.Free;
  end;
end;

class function TInstituicaoCertificadoDocumentoService.SanitizeFileName(
  const AValor: string
): string;
var
  C: Char;
begin
  Result := '';

  for C in AValor do
  begin
    if
      ((C >= 'A') and (C <= 'Z')) or
      ((C >= 'a') and (C <= 'z')) or
      ((C >= '0') and (C <= '9')) or
      (C = '-') or
      (C = '_') or
      (C = '.')
    then
      Result :=
        Result +
        C
    else
      Result :=
        Result +
        '_';
  end;
end;

class function TInstituicaoCertificadoDocumentoService.MontarUrlValidacao(
  const ABaseUrl,
        ACodigo: string
): string;
begin
  Result :=
    Trim(
      ABaseUrl
    );

  while Result.EndsWith(
    '/'
  ) do
    Delete(
      Result,
      Length(Result),
      1
    );

  Result :=
    Result +
    '/' +
    ACodigo;
end;

class function TInstituicaoCertificadoDocumentoService.RenderizarTemplate(
  const ATemplateHtml,
        AImagemFundoUrl,
        ATextoValidacao,
        AQrSvg,
        AUrlValidacao: string;
  const ACertificado: TCertificadoItem
): string;

  procedure Substituir(
    const AChave,
          AValor: string
  );
  begin
    Result :=
      StringReplace(
        Result,
        '{{' + AChave + '}}',
        AValor,
        [rfReplaceAll, rfIgnoreCase]
      );
  end;

begin
  Result :=
    ATemplateHtml;

  if Trim(
    Result
  ).IsEmpty then
    TAppErrors.RaiseBadRequest(
      'O modelo de certificado não possui template_html.'
    );

  Substituir(
    'participante_nome',
    HtmlEncode(
      ACertificado.ParticipanteNome
    )
  );

  Substituir(
    'curso_nome',
    HtmlEncode(
      ACertificado.CursoNome
    )
  );

  Substituir(
    'instituicao_nome',
    HtmlEncode(
      ACertificado.InstituicaoNome
    )
  );

  Substituir(
    'carga_horaria',
    HtmlEncode(
      CargaHorariaTexto(
        ACertificado.CargaHorariaMinutos
      )
    )
  );

  Substituir(
    'carga_horaria_minutos',
    IntToStr(
      ACertificado.CargaHorariaMinutos
    )
  );

  Substituir(
    'data_conclusao',
    FormatDateTime(
      'dd/mm/yyyy',
      ACertificado.DataConclusao
    )
  );

  Substituir(
    'numero_publico',
    HtmlEncode(
      ACertificado.NumeroPublico
    )
  );

  Substituir(
    'codigo_validacao',
    HtmlEncode(
      ACertificado.CodigoValidacao
    )
  );

  Substituir(
    'url_validacao',
    HtmlEncode(
      AUrlValidacao
    )
  );

  Substituir(
    'texto_validacao',
    HtmlEncode(
      ATextoValidacao
    )
  );

  Substituir(
    'imagem_fundo_url',
    HtmlEncode(
      AImagemFundoUrl
    )
  );

  // O QR já é SVG gerado localmente. Não aplicar HtmlEncode.
  Substituir(
    'qr_code_svg',
    AQrSvg
  );

  if Pos(
    '<html',
    LowerCase(
      Result
    )
  ) = 0 then
    Result :=
      '<!doctype html>' +
      '<html><head><meta charset="utf-8"></head><body>' +
      Result +
      '</body></html>';
end;

class function TInstituicaoCertificadoDocumentoService.GerarQrCodeSvg(
  const AUrlValidacao: string
): string;
var
  Qr: TDelphiZXingQRCode;
  Builder: TStringBuilder;
  Linha, Coluna: Integer;
begin
  if Trim(AUrlValidacao).IsEmpty then
    raise Exception.Create('URL de validação do certificado não informada.');

  Qr := TDelphiZXingQRCode.Create;
  Builder := TStringBuilder.Create;
  try
    Qr.Encoding := qrUTF8NoBOM;
    Qr.QuietZone := 4;
    Qr.Data := AUrlValidacao;

    Builder.Append(
      Format(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" shape-rendering="crispEdges" role="img" aria-label="QR Code de validação">',
        [Qr.Columns, Qr.Rows]
      )
    );
    Builder.Append('<rect width="100%" height="100%" fill="#fff"/>');
    Builder.Append('<path fill="#000" d="');

    for Linha := 0 to Qr.Rows - 1 do
      for Coluna := 0 to Qr.Columns - 1 do
        if Qr.IsBlack[Linha, Coluna] then
          Builder.AppendFormat('M%d %dh1v1h-1z', [Coluna, Linha]);

    Builder.Append('"/></svg>');
    Result := Builder.ToString;
  finally
    Builder.Free;
    Qr.Free;
  end;
end;

class procedure TInstituicaoCertificadoDocumentoService.GerarPdfChromium(
  const AExecutable,
        AExtraArgs,
        AArquivoHtml,
        AArquivoPdf: string
);
var
  Args: TList<string>;
  Partes: TArray<string>;
  Parte: string;
  UrlArquivo: string;
  PastaPerfil: string;
  Executavel: string;
  Stream: TFileStream;
  Cabecalho: array[0..4] of AnsiChar;

  function PrimeiroExecutavelExistente(
    const ACandidatos: array of string
  ): string;
  var
    Candidato: string;
  begin
    Result := '';
    for Candidato in ACandidatos do
      if (not Trim(Candidato).IsEmpty) and TFile.Exists(Candidato) then
        Exit(Candidato);
  end;

begin
  Executavel := Trim(AExecutable);

  {$IFDEF MSWINDOWS}
  if Executavel.IsEmpty or
     SameText(Executavel, 'chromium') or
     SameText(Executavel, 'chrome') or
     SameText(Executavel, 'chrome.exe') or
     SameText(Executavel, 'msedge') or
     SameText(Executavel, 'msedge.exe') or
     not TFile.Exists(Executavel) then
  begin
    Executavel := PrimeiroExecutavelExistente([
      TPath.Combine(
        GetEnvironmentVariable('PROGRAMFILES'),
        'Google\Chrome\Application\chrome.exe'
      ),
      TPath.Combine(
        GetEnvironmentVariable('PROGRAMFILES(X86)'),
        'Google\Chrome\Application\chrome.exe'
      ),
      TPath.Combine(
        GetEnvironmentVariable('LOCALAPPDATA'),
        'Google\Chrome\Application\chrome.exe'
      ),
      TPath.Combine(
        GetEnvironmentVariable('PROGRAMFILES'),
        'Microsoft\Edge\Application\msedge.exe'
      ),
      TPath.Combine(
        GetEnvironmentVariable('PROGRAMFILES(X86)'),
        'Microsoft\Edge\Application\msedge.exe'
      )
    ]);
  end;

  if Executavel.IsEmpty or not TFile.Exists(Executavel) then
    raise Exception.Create(
      'Chrome/Chromium/Edge não encontrado. Configure CERTIFICADO_DOCUMENTO.ChromiumExecutable no Config.ini.'
    );
  {$ENDIF}

  {$IFDEF POSIX}
  if Executavel.IsEmpty then
    Executavel := 'chromium';
  {$ENDIF}

  PastaPerfil := GerarNomeTemporario('.profile');
  Args :=
    TList<string>.Create;

  try
    if not Trim(
      AExtraArgs
    ).IsEmpty then
    begin
      Partes :=
        AExtraArgs.Split(
          [' '],
          TStringSplitOptions.ExcludeEmpty
        );

      for Parte in Partes do
        Args.Add(
          Parte
        );
    end;

    Args.Add('--user-data-dir=' + PastaPerfil);

    Args.Add(
      '--print-to-pdf=' +
      AArquivoPdf
    );

    UrlArquivo :=
      'file://' +
      StringReplace(
        AArquivoHtml,
        '\',
        '/',
        [rfReplaceAll]
      );

    {$IFDEF MSWINDOWS}
    UrlArquivo := StringReplace(UrlArquivo, 'file://', 'file:///', []);
    {$ENDIF}
    UrlArquivo := StringReplace(UrlArquivo, '%', '%25', [rfReplaceAll]);
    UrlArquivo := StringReplace(UrlArquivo, ' ', '%20', [rfReplaceAll]);
    UrlArquivo := StringReplace(UrlArquivo, '#', '%23', [rfReplaceAll]);
    UrlArquivo := StringReplace(UrlArquivo, '?', '%3F', [rfReplaceAll]);
    Args.Add(UrlArquivo);

    TAppProcessRunner.Execute(
      Executavel,
      Args.ToArray
    );

  finally
    Args.Free;
    if TDirectory.Exists(PastaPerfil) then
      TDirectory.Delete(PastaPerfil, True);
  end;

  if not TFile.Exists(
    AArquivoPdf
  ) then
    raise Exception.Create(
      'O Chromium não gerou o arquivo PDF.'
    );

  Stream := TFileStream.Create(AArquivoPdf, fmOpenRead or fmShareDenyWrite);
  try
    if Stream.Size < 5 then
      raise Exception.Create('O PDF gerado está vazio ou incompleto.');
    Stream.ReadBuffer(Cabecalho, SizeOf(Cabecalho));
    if (Cabecalho[0] <> '%') or (Cabecalho[1] <> 'P') or
       (Cabecalho[2] <> 'D') or (Cabecalho[3] <> 'F') or
       (Cabecalho[4] <> '-') then
      raise Exception.Create('O arquivo gerado não possui cabeçalho PDF válido.');
  finally
    Stream.Free;
  end;
end;

class function TInstituicaoCertificadoDocumentoService.GerarPdf(
  const AIdInstituicao,
        AIdCertificado,
        AUsuarioInstituicao: Int64
): TCertificadoItem;
var
  DocumentoConfig: TCertificadoDocumentoConfig;
  ApiConfig: TAppApiConfig;
  Conn: TUniConnection;
  Certificado: TCertificadoItem;
  Template: TCertificadoDocumentoTemplate;

  UrlValidacao: string;
  ArquivoHtml: string;
  ArquivoPdfTemporario: string;
  QrSvg: string;
  Html: string;

  Ano: Integer;
  StorageKey: string;
  PastaDestino: string;
  ArquivoPdfDestino: string;
  NomeArquivo: string;
  Pdf: TCertificadoPdfFinalizacao;
  ArquivoMovido: Boolean;
begin
  Result := nil;
  Template := nil;
  Certificado := nil;

  ArquivoHtml := '';
  ArquivoPdfTemporario := '';
  ArquivoPdfDestino := '';
  ArquivoMovido := False;

  if AIdInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Instituição não identificada.'
    );

  if AUsuarioInstituicao <= 0 then
    TAppErrors.RaiseUnauthorized(
      'Usuário da instituição não identificado.'
    );

  if AIdCertificado <= 0 then
    TAppErrors.RaiseBadRequest(
      'Certificado inválido.'
    );

  DocumentoConfig :=
    TInstituicaoCertificadoDocumentoConfig.Carregar;

  Certificado :=
    TInstituicaoCertificadoService.BuscarPorId(
      AIdInstituicao,
      AIdCertificado
    );

  try
    if not SameText(
      Certificado.Situacao,
      'PENDENTE'
    ) and
    not SameText(
      Certificado.Situacao,
      'ERRO'
    ) then
      TAppErrors.RaiseBadRequest(
        'Somente certificados pendentes ou com erro podem gerar PDF.'
      );

    if not Certificado.TemIdModelo then
      TAppErrors.RaiseBadRequest(
        'O certificado não possui modelo associado.'
      );

    ApiConfig :=
      TAppConfig.Carregar(
        ExtractFilePath(
          ParamStr(0)
        ) +
        'Config.ini'
      );

    Conn :=
      TDatabaseConnection.NewConnection(
        ApiConfig.Database
      );

    try
      Template :=
        TInstituicaoCertificadoDocumentoDAO.BuscarTemplate(
          Conn,
          AIdInstituicao,
          AIdCertificado
        );

      if Template = nil then
        TAppErrors.RaiseBadRequest(
          'Modelo do certificado não encontrado.'
        );

    finally
      Conn.Free;
    end;

    UrlValidacao :=
      MontarUrlValidacao(
        DocumentoConfig.PublicValidationBaseUrl,
        Certificado.CodigoValidacao
      );

    ArquivoHtml :=
      GerarNomeTemporario(
        '.html'
      );

    ArquivoPdfTemporario :=
      GerarNomeTemporario(
        '.pdf'
      );

    QrSvg :=
      GerarQrCodeSvg(
        UrlValidacao
      );

    Html :=
      RenderizarTemplate(
        Template.TemplateHtml,
        Template.ImagemFundoUrl,
        Template.TextoValidacao,
        QrSvg,
        UrlValidacao,
        Certificado
      );

    TFile.WriteAllText(
      ArquivoHtml,
      Html,
      TEncoding.UTF8
    );

    GerarPdfChromium(
      DocumentoConfig.ChromiumExecutable,
      DocumentoConfig.ChromiumArgs,
      ArquivoHtml,
      ArquivoPdfTemporario
    );

    Ano :=
      YearOf(
        Certificado.DataConclusao
      );

    NomeArquivo :=
      SanitizeFileName(
        Certificado.NumeroPublico
      ) +
      '-' + TPath.GetFileNameWithoutExtension(ArquivoPdfTemporario) + '.pdf';

    StorageKey :=
      'certificados/' +
      IntToStr(
        AIdInstituicao
      ) +
      '/' +
      IntToStr(
        Ano
      ) +
      '/' +
      NomeArquivo;

    PastaDestino :=
      TPath.Combine(
        DocumentoConfig.StoragePath,
        TPath.Combine(
          'certificados',
          TPath.Combine(
            IntToStr(
              AIdInstituicao
            ),
            IntToStr(
              Ano
            )
          )
        )
      );

    TDirectory.CreateDirectory(
      PastaDestino
    );

    ArquivoPdfDestino :=
      TPath.Combine(
        PastaDestino,
        NomeArquivo
      );

    // Cada tentativa tem arquivo próprio: nunca remover o PDF de outra geração.
    // Copy também suporta storage em volume diferente do diretório temporário.
    TFile.Copy(
      ArquivoPdfTemporario,
      ArquivoPdfDestino
    );

    ArquivoMovido := True;

    Pdf :=
      Default(
        TCertificadoPdfFinalizacao
      );

    Pdf.PdfStorageKey :=
      StorageKey;

    Pdf.PdfSha256 :=
      Sha256Arquivo(
        ArquivoPdfDestino
      );

    Pdf.PdfTamanhoBytes :=
      TFile.GetSize(
        ArquivoPdfDestino
      );

    try
      Result :=
        TInstituicaoCertificadoService.FinalizarPdf(
          AIdInstituicao,
          AIdCertificado,
          AUsuarioInstituicao,
          Pdf
        );

    except
      if ArquivoMovido and
         TFile.Exists(
           ArquivoPdfDestino
         ) then
        TFile.Delete(
          ArquivoPdfDestino
        );

      raise;
    end;

  finally
    Template.Free;
    Certificado.Free;

    if not ArquivoHtml.IsEmpty and
       TFile.Exists(
         ArquivoHtml
       ) then
      TFile.Delete(
        ArquivoHtml
      );

    if not ArquivoPdfTemporario.IsEmpty and
       TFile.Exists(
         ArquivoPdfTemporario
       ) then
      TFile.Delete(
        ArquivoPdfTemporario
      );
  end;
end;

end.

