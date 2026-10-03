unit ContratoDocumento.Service;

interface

uses
  ContratoDocumento.Model;

type
  TContratoDocumentoService = class
  private
    class function MimePorExtensao(const AExtensao: string): string; static;
    class function Sha256Arquivo(const AArquivo: string): string; static;
    class procedure ValidarArquivo(const AArquivo: string; const ATamanho: Int64); static;
  public
    class function PastaUpload(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): string; static;

    class procedure RegistrarArquivo(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
      const ATipo, AObservacao, AArquivoCompleto, ANomeArquivo: string;
      const ATamanhoBytes: Int64
    ); static;

    class function Listar(
      const AIdInstituicao, AIdUsuario, AIdContrato: Int64
    ): TContratoDocumentoLista; static;

    class function CaminhoDownload(
      const AIdInstituicao, AIdUsuario, AIdContrato, AIdDocumento: Int64;
      out ANomeArquivo, AMimeType: string
    ): string; static;

    class procedure Excluir(
      const AIdInstituicao, AIdUsuario, AIdContrato, AIdDocumento: Int64
    ); static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Hash,
  System.Classes,
  Uni,
  App.Config,
  APP.Errors,
  Database.Connection,
  InstituicaoPermissao.Service,
  InstituicaoCertificadoDocumento.Config,
  Contrato.Model,
  Contrato.DAO,
  ContratoDocumento.DAO;

class function TContratoDocumentoService.MimePorExtensao(
  const AExtensao: string
): string;
var
  Ext: string;
begin
  Ext := LowerCase(AExtensao);
  if Ext='.pdf' then Exit('application/pdf');
  if Ext='.png' then Exit('image/png');
  if (Ext='.jpg') or (Ext='.jpeg') then Exit('image/jpeg');
  if Ext='.doc' then Exit('application/msword');
  if Ext='.docx' then Exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
  if Ext='.xls' then Exit('application/vnd.ms-excel');
  if Ext='.xlsx' then Exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  Result := 'application/octet-stream';
end;

class function TContratoDocumentoService.Sha256Arquivo(
  const AArquivo: string
): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AArquivo,fmOpenRead or fmShareDenyWrite);
  try
    Result := LowerCase(
      THashSHA2.GetHashString(
        Stream,
        THashSHA2.TSHA2Version.SHA256
      )
    );
  finally
    Stream.Free;
  end;
end;

class procedure TContratoDocumentoService.ValidarArquivo(
  const AArquivo: string;
  const ATamanho: Int64
);
var
  Ext: string;
begin
  if ATamanho<=0 then
    TAppErrors.RaiseBadRequest('Arquivo vazio.');

  if ATamanho>(20*1024*1024) then
    TAppErrors.RaiseBadRequest('Arquivo excede o limite de 20 MB.');

  Ext := LowerCase(ExtractFileExt(AArquivo));
  if not (
    (Ext='.pdf') or
    (Ext='.png') or
    (Ext='.jpg') or
    (Ext='.jpeg') or
    (Ext='.doc') or
    (Ext='.docx') or
    (Ext='.xls') or
    (Ext='.xlsx')
  ) then
    TAppErrors.RaiseBadRequest(
      'Tipo de arquivo não permitido. Utilize PDF, imagem, Word ou Excel.'
    );
end;

class function TContratoDocumentoService.PastaUpload(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): string;
var
  ConfigDoc: TCertificadoDocumentoConfig;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contrato: TContratoItem;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,AIdUsuario,'contrato.documento.gerenciar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Contrato := TContratoDAO.BuscarPorId(Conn,AIdInstituicao,AIdContrato);
    try
      if Contrato=nil then
        TAppErrors.RaiseBadRequest('Contrato não encontrado.');
    finally
      Contrato.Free;
    end;
  finally
    Conn.Free;
  end;

  ConfigDoc := TInstituicaoCertificadoDocumentoConfig.Carregar(False);
  Result := TPath.Combine(
    ConfigDoc.StoragePath,
    TPath.Combine(
      'contratos',
      TPath.Combine(
        IntToStr(AIdInstituicao),
        IntToStr(AIdContrato)
      )
    )
  );
end;

class procedure TContratoDocumentoService.RegistrarArquivo(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64;
  const ATipo, AObservacao, AArquivoCompleto, ANomeArquivo: string;
  const ATamanhoBytes: Int64
);
var
  ConfigDoc: TCertificadoDocumentoConfig;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  StorageKey, Mime, Hash: string;
  IdDocumento: Int64;
begin
  if Trim(ATipo).IsEmpty then
  begin
    if TFile.Exists(AArquivoCompleto) then TFile.Delete(AArquivoCompleto);
    TAppErrors.RaiseBadRequest('Tipo do documento não informado.');
  end;

  try
    ValidarArquivo(AArquivoCompleto,ATamanhoBytes);
    ConfigDoc := TInstituicaoCertificadoDocumentoConfig.Carregar(False);

    StorageKey :=
      'contratos/' + IntToStr(AIdInstituicao) + '/' +
      IntToStr(AIdContrato) + '/' + ExtractFileName(AArquivoCompleto);

    Mime := MimePorExtensao(ExtractFileExt(AArquivoCompleto));
    Hash := Sha256Arquivo(AArquivoCompleto);

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);
    try
      Conn.StartTransaction;
      try
        IdDocumento := TContratoDocumentoDAO.Inserir(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          ATipo,
          ANomeArquivo,
          StorageKey,
          Mime,
          Hash,
          AObservacao,
          ATamanhoBytes
        );

        TContratoDAO.InserirHistorico(
          Conn,
          AIdInstituicao,
          AIdContrato,
          AIdUsuario,
          'DOCUMENTO_INCLUIDO',
          'Documento incluído: '+ANomeArquivo+'.'
        );

        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        raise;
      end;
    finally
      Conn.Free;
    end;
  except
    if TFile.Exists(AArquivoCompleto) then
      TFile.Delete(AArquivoCompleto);
    raise;
  end;
end;

class function TContratoDocumentoService.Listar(
  const AIdInstituicao, AIdUsuario, AIdContrato: Int64
): TContratoDocumentoLista;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,AIdUsuario,'contrato.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Result := TContratoDocumentoDAO.Listar(
      Conn,AIdInstituicao,AIdContrato
    );
  finally
    Conn.Free;
  end;
end;

class function TContratoDocumentoService.CaminhoDownload(
  const AIdInstituicao, AIdUsuario, AIdContrato, AIdDocumento: Int64;
  out ANomeArquivo, AMimeType: string
): string;
var
  ConfigDoc: TCertificadoDocumentoConfig;
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Item: TContratoDocumentoItem;
  Base, Esperado, Key: string;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,AIdUsuario,'contrato.visualizar'
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Item := TContratoDocumentoDAO.BuscarPorId(
      Conn,AIdInstituicao,AIdContrato,AIdDocumento
    );
    try
      if Item=nil then
        TAppErrors.RaiseBadRequest('Documento não encontrado.');

      Key := Trim(Item.StorageKey);
      Esperado := 'contratos/'+IntToStr(AIdInstituicao)+'/'+IntToStr(AIdContrato)+'/';
      if not Key.StartsWith(Esperado) or
         (Pos('..',Key)>0) or (Pos('\',Key)>0) or (Pos(':',Key)>0) then
        TAppErrors.RaiseForbidden('Referência de documento inválida.');

      ConfigDoc := TInstituicaoCertificadoDocumentoConfig.Carregar(False);
      Base := IncludeTrailingPathDelimiter(ExpandFileName(ConfigDoc.StoragePath));
      Result := ExpandFileName(
        TPath.Combine(
          Base,
          StringReplace(Key,'/',PathDelim,[rfReplaceAll])
        )
      );

      {$IFDEF MSWINDOWS}
      if not SameText(Copy(Result,1,Length(Base)),Base) then
      {$ELSE}
      if Copy(Result,1,Length(Base))<>Base then
      {$ENDIF}
        TAppErrors.RaiseForbidden('Referência de documento inválida.');

      if not TFile.Exists(Result) then
        TAppErrors.RaiseBadRequest('Arquivo do documento não está disponível.');

      ANomeArquivo := Item.Nome;
      AMimeType := Item.MimeType;
    finally
      Item.Free;
    end;
  finally
    Conn.Free;
  end;
end;

class procedure TContratoDocumentoService.Excluir(
  const AIdInstituicao, AIdUsuario, AIdContrato, AIdDocumento: Int64
);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Item: TContratoDocumentoItem;
  Caminho, Nome, Mime: string;
begin
  TInstituicaoPermissaoService.Exigir(
    AIdInstituicao,AIdUsuario,'contrato.documento.gerenciar'
  );

  Caminho := CaminhoDownload(
    AIdInstituicao,AIdUsuario,AIdContrato,AIdDocumento,Nome,Mime
  );

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0))+'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    Item := TContratoDocumentoDAO.BuscarPorId(
      Conn,AIdInstituicao,AIdContrato,AIdDocumento
    );
    try
      if Item=nil then
        TAppErrors.RaiseBadRequest('Documento não encontrado.');

      Conn.StartTransaction;
      try
        TContratoDocumentoDAO.ExcluirLogicamente(
          Conn,AIdInstituicao,AIdContrato,AIdDocumento,AIdUsuario
        );

        TContratoDAO.InserirHistorico(
          Conn,AIdInstituicao,AIdContrato,AIdUsuario,
          'DOCUMENTO_EXCLUIDO',
          'Documento removido: '+Item.Nome+'.'
        );

        Conn.Commit;
      except
        if Conn.InTransaction then Conn.Rollback;
        raise;
      end;
    finally
      Item.Free;
    end;
  finally
    Conn.Free;
  end;

  if TFile.Exists(Caminho) then
    TFile.Delete(Caminho);
end;

end.
