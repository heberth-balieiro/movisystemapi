unit PlataformaUsuarioWhatsApp.Controller;

interface

type
  TPlataformaUsuarioWhatsAppController = class
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
  PlataformaUsuarioWhatsApp.Service;

function AutorizarSuperAdmin(
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

  if not TAppToken.PossuiRole(
    AClaims.Roles,
    'SUPER_ADMIN'
  ) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para administrar WhatsApp dos usuários da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

class procedure TPlataformaUsuarioWhatsAppController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/usuarios/:id/whatsapp',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdUsuario: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        IdUsuario :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        TAppResponse.Ok(
          Res,
          TPlataformaUsuarioWhatsAppService.BuscarStatus(
            IdUsuario
          ),
          'WhatsApp do usuário carregado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/usuarios/:id/whatsapp/instancia',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdUsuario: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        IdUsuario :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        TAppResponse.Created(
          Res,
          TPlataformaUsuarioWhatsAppService.CriarInstancia(
            Claims.UserId,
            IdUsuario,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          ),
          'Instância WhatsApp criada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/plataforma/usuarios/:id/whatsapp/qrcode',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdUsuario: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        IdUsuario :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        TAppResponse.Ok(
          Res,
          TPlataformaUsuarioWhatsAppService.ObterQrCode(
            Claims.UserId,
            IdUsuario,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          ),
          'QR Code carregado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/plataforma/usuarios/:id/whatsapp/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdUsuario: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        IdUsuario :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        TAppResponse.Ok(
          Res,
          TPlataformaUsuarioWhatsAppService.AtualizarStatus(
            IdUsuario
          ),
          'Status do WhatsApp atualizado.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/usuarios/:id/whatsapp/logout',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      IdUsuario: Int64;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        IdUsuario :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        TAppResponse.Ok(
          Res,
          TPlataformaUsuarioWhatsAppService.Logout(
            Claims.UserId,
            IdUsuario,
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          ),
          'WhatsApp do usuário desconectado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
