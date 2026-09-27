unit App.Token;

interface

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  App.JWT,
  App.Response,
  APP.Errors;

Type
TAppToken = class
  Private

  public
    class function ValidarToken(const Req: THorseRequest; const Res: THorseResponse; out AClaims: TJWTClaims): Boolean;

    {$REGION 'Eleicao'}

    class function PossuiRole(const ARoles: TArray<string>;const ARole: string): Boolean; static;
    class function PertenceEleicao(const AClaims: TJWTClaims; const ASlug: string): Boolean; static;
    {$ENDREGION}
end;

implementation

{ TAppToken }

class function TAppToken.ValidarToken(const Req: THorseRequest;const Res: THorseResponse; out AClaims: TJWTClaims): Boolean;
var
  Config: TAppApiConfig;
  Token: string;
begin
  Result := False;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

  Token := TAppJWT.ExtrairBearerToken(Req.Headers['Authorization']);

  if Token.Trim.IsEmpty then
  begin
    TAppResponse.Unauthorized(Res, 'Token ausente. Use Authorization: Bearer <token>.');
    Exit;
  end;

  if not TAppJWT.ValidarEExtrair(Config.JWT, Token, AClaims) then
  begin
    TAppResponse.Unauthorized(Res, 'Token inválido ou expirado.');
    Exit;
  end;

  Result := True;
end;


{$REGION 'Eleicao'}

class function TAppToken.PertenceEleicao(const AClaims: TJWTClaims;
                                                const ASlug: string): Boolean;
begin
  Result := (not Trim(AClaims.EleicaoSlug).IsEmpty) and
            (not Trim(ASlug).IsEmpty) and
            SameText(Trim(AClaims.EleicaoSlug), Trim(ASlug));
end;

class function TAppToken.PossuiRole(const ARoles: TArray<string>;const ARole: string): Boolean;
var
  Role: string;
begin
  Result := False;

  for Role in ARoles do
  begin
    if SameText(
      Trim(Role),
      Trim(ARole)
    ) then
      Exit(True);
  end;
end;

{$ENDREGION}



end.

