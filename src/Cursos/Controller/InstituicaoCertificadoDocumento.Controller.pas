unit InstituicaoCertificadoDocumento.Controller;

interface

type
  TInstituicaoCertificadoDocumentoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoPermissao.Service,
  InstituicaoCertificado.Model,
  InstituicaoCertificadoDocumento.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );

    Exit;
  end;

  Result := True;
end;

function DataHoraISO(
  const AData: TDateTime
): string;
begin
  Result :=
    FormatDateTime(
      'yyyy-mm-dd"T"hh:nn:ss.zzz',
      AData
    );
end;

function CertificadoGeradoParaJson(
  const AItem: TCertificadoItem
): TJSONObject;
begin
  Result :=
    TJSONObject.Create;

  Result.AddPair(
    'id',
    TJSONNumber.Create(
      AItem.Id
    )
  );

  Result.AddPair(
    'numero_publico',
    AItem.NumeroPublico
  );

  Result.AddPair(
    'codigo_validacao',
    AItem.CodigoValidacao
  );

  Result.AddPair(
    'versao',
    TJSONNumber.Create(
      AItem.Versao
    )
  );

  Result.AddPair(
    'situacao',
    AItem.Situacao
  );

  Result.AddPair(
    'participante_nome',
    AItem.ParticipanteNome
  );

  Result.AddPair(
    'curso_nome',
    AItem.CursoNome
  );

  Result.AddPair(
    'instituicao_nome',
    AItem.InstituicaoNome
  );

  Result.AddPair(
    'carga_horaria_minutos',
    TJSONNumber.Create(
      AItem.CargaHorariaMinutos
    )
  );

  Result.AddPair(
    'data_conclusao',
    DataHoraISO(
      AItem.DataConclusao
    )
  );

  Result.AddPair(
    'pdf_storage_key',
    AItem.PdfStorageKey
  );

  Result.AddPair(
    'pdf_sha256',
    AItem.PdfSha256
  );

  if AItem.TemPdfTamanhoBytes then
    Result.AddPair(
      'pdf_tamanho_bytes',
      TJSONNumber.Create(
        AItem.PdfTamanhoBytes
      )
    )
  else
    Result.AddPair(
      'pdf_tamanho_bytes',
      TJSONNull.Create
    );

  if AItem.TemPdfGeradoEm then
    Result.AddPair(
      'pdf_gerado_em',
      DataHoraISO(
        AItem.PdfGeradoEm
      )
    )
  else
    Result.AddPair(
      'pdf_gerado_em',
      TJSONNull.Create
    );

  if AItem.TemEmitidoEm then
    Result.AddPair(
      'emitido_em',
      DataHoraISO(
        AItem.EmitidoEm
      )
    )
  else
    Result.AddPair(
      'emitido_em',
      TJSONNull.Create
    );
end;

class procedure TInstituicaoCertificadoDocumentoController.Registry;
begin
  THorse.Get('/v1/certifica/instituicao/certificados/:id/pdf',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Caminho: string;
      Id: Int64;
    begin
      Res.RawWebResponse.SetCustomHeader('Cache-Control', 'private, no-store');
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      try
        if not AutorizarInstituicao(Req, Res, Claims) then Exit;
        Id := StrToInt64Def(Req.Params.Items['id'], 0);
        Caminho := TInstituicaoCertificadoDocumentoService.CaminhoPdf(
          Claims.IdInstituicao, Id, Claims.IdUsuarioInstituicao);
        Res.RawWebResponse.ContentType := 'application/pdf';
        Res.RawWebResponse.SetCustomHeader('Content-Disposition',
          'attachment; filename="certificado-' + IntToStr(Id) + '.pdf"');
        Res.SendFile(Caminho);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post(
    '/v1/certifica/instituicao/certificados/:id/gerar-pdf',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      IdCertificado: Int64;
      Certificado: TCertificadoItem;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        TInstituicaoPermissaoService.Exigir(Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao, 'certificado.emitir');

        IdCertificado :=
          StrToInt64Def(
            Req.Params.Items[
              'id'
            ],
            0
          );

        Certificado :=
          TInstituicaoCertificadoDocumentoService.GerarPdf(
            Claims.IdInstituicao,
            IdCertificado,
            Claims.IdUsuarioInstituicao
          );

        try
          TAppResponse.Ok(
            Res,
            CertificadoGeradoParaJson(
              Certificado
            ),
            'PDF e QR Code gerados; certificado emitido com sucesso.'
          );

        finally
          Certificado.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );
end;

end.
