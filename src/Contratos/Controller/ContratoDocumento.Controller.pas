unit ContratoDocumento.Controller;

interface

type
  TContratoDocumentoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  Horse.Upload,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  ContratoDocumento.Model,
  ContratoDocumento.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;
  if not TAppToken.ValidarToken(Req,Res,AClaims) then Exit;

  if (AClaims.IdInstituicao<=0) or
     (AClaims.IdUsuarioInstituicao<=0) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto válido de instituição e usuário.'
    );
    Exit;
  end;

  Result := True;
end;

function ListaParaJson(
  const ALista: TContratoDocumentoLista
): TJSONObject;
var
  Arr: TJSONArray;
  Item: TContratoDocumentoItem;
  Obj: TJSONObject;
begin
  Result := TJSONObject.Create;
  Arr := TJSONArray.Create;

  for Item in ALista do
  begin
    Obj := TJSONObject.Create;
    Obj.AddPair('id',TJSONNumber.Create(Item.Id));
    Obj.AddPair('tipo',Item.Tipo);
    Obj.AddPair('nome',Item.Nome);
    Obj.AddPair('mime_type',Item.MimeType);
    Obj.AddPair('tamanho_bytes',TJSONNumber.Create(Item.TamanhoBytes));
    Obj.AddPair('sha256',Item.Sha256);
    Obj.AddPair('observacao',Item.Observacao);
    Obj.AddPair('enviado_por',TJSONNumber.Create(Item.EnviadoPor));
    Obj.AddPair(
      'criado_em',
      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz',Item.CriadoEm)
    );
    Arr.AddElement(Obj);
  end;

  Result.AddPair('itens',Arr);
end;

class procedure TContratoDocumentoController.Registry;
begin
  THorse.Get(
    '/v1/contratos/instituicao/contratos/:id/documentos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      Lista:TContratoDocumentoLista;
      IdContrato:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);

        Lista:=TContratoDocumentoService.Listar(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato
        );
        try
          TAppResponse.Ok(
            Res,
            ListaParaJson(Lista),
            'Documentos carregados com sucesso.'
          );
        finally
          Lista.Free;
        end;
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Post(
    '/v1/contratos/instituicao/contratos/:id/documentos',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      IdContrato:Int64;
      Tipo,Observacao,Pasta:string;
      UploadConfig:TUploadConfig;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;

        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        Tipo:=Trim(Req.Query.Items['tipo']);
        Observacao:=Trim(Req.Query.Items['observacao']);

        Pasta:=TContratoDocumentoService.PastaUpload(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato
        );

        UploadConfig:=TUploadConfig.Create(Pasta);
        UploadConfig.ForceDir:=True;
        UploadConfig.OverrideFiles:=False;
        UploadConfig.UploadFileCallBack :=
          procedure(Sender:TObject; AFile:TUploadFileInfo)
          begin
            if SameText(AFile.status,'ok') then
              TContratoDocumentoService.RegistrarArquivo(
                Claims.IdInstituicao,
                Claims.IdUsuarioInstituicao,
                IdContrato,
                Tipo,
                Observacao,
                AFile.fullpath,
                AFile.filename,
                AFile.size
              );
          end;

        Res.Send<TUploadConfig>(UploadConfig);
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Get(
    '/v1/contratos/instituicao/contratos/:id/documentos/:documentoId/download',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      IdContrato,IdDocumento:Int64;
      Caminho,Nome,Mime:string;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;

        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        IdDocumento:=StrToInt64Def(Req.Params.Items['documentoId'],0);

        Caminho:=TContratoDocumentoService.CaminhoDownload(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          IdDocumento,
          Nome,
          Mime
        );

        Res.RawWebResponse.SetCustomHeader('Cache-Control','private, no-store');
        Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options','nosniff');
        Res.RawWebResponse.ContentType:=Mime;
        Res.RawWebResponse.SetCustomHeader(
          'Content-Disposition',
          'attachment; filename="'+StringReplace(Nome,'"','',[rfReplaceAll])+'"'
        );
        Res.SendFile(Caminho);
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );

  THorse.Delete(
    '/v1/contratos/instituicao/contratos/:id/documentos/:documentoId',
    procedure(Req:THorseRequest; Res:THorseResponse; Next:TProc)
    var
      Claims:TJWTClaims;
      IdContrato,IdDocumento:Int64;
    begin
      try
        if not AutorizarInstituicao(Req,Res,Claims) then Exit;
        IdContrato:=StrToInt64Def(Req.Params.Items['id'],0);
        IdDocumento:=StrToInt64Def(Req.Params.Items['documentoId'],0);

        TContratoDocumentoService.Excluir(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          IdContrato,
          IdDocumento
        );

        TAppResponse.Ok(
          Res,
          TJSONObject.Create,
          'Documento removido com sucesso.'
        );
      except
        on E:Exception do TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
