unit InstituicaoWhatsApp.Controller;

interface

type
  TInstituicaoWhatsAppController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  InstituicaoWhatsApp.Model,
  InstituicaoWhatsApp.Service;

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

  if AClaims.IdUsuarioInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem vínculo de usuário com a instituição.'
    );
    Exit;
  end;

  Result := True;
end;

class procedure TInstituicaoWhatsAppController.Registry;
begin

  {$REGION 'Status'}

  THorse.Get(
    '/v1/certifica/configuracoes/whatsapp/status',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Status: TInstituicaoWhatsAppStatus;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Status :=
          TInstituicaoWhatsAppService.Status(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        TAppResponse.Ok(
          Res,
          Status.ToJSON,
          'Status do WhatsApp carregado com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Criar Instancia'}

  THorse.Post(
    '/v1/certifica/configuracoes/whatsapp/instancia',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Status: TInstituicaoWhatsAppStatus;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Status :=
          TInstituicaoWhatsAppService.CriarInstancia(
            Claims.IdInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Created(
          Res,
          Status.ToJSON,
          'Instância WhatsApp criada com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'QRCode'}

  THorse.Post(
    '/v1/certifica/configuracoes/whatsapp/qrcode',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      QrCode: TInstituicaoWhatsAppQrCode;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        QrCode :=
          TInstituicaoWhatsAppService.ObterQrCode(
            Claims.IdInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          QrCode.ToJSON,
          'QR Code gerado com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Logout'}

  THorse.Delete(
    '/v1/certifica/configuracoes/whatsapp/logout',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Status: TInstituicaoWhatsAppStatus;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        Status :=
          TInstituicaoWhatsAppService.Logout(
            Claims.IdInstituicao,
            Claims.UserId,
            Claims.IdUsuarioInstituicao,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          Status.ToJSON,
          'WhatsApp desconectado com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}

end;

end.
