unit Middleware.JWT;

interface

uses
  Horse,
  App.JWT,
  App.Config;

type
  TJWTContext = record
    UserId: Int64;
    Roles: TArray<string>;
  end;

  TMiddlewareJWT = class
  public
    class function RequireAuth(const ACfg: TAppJWTConfig): THorseCallback; static;
    class function OptionalAuth(const ACfg: TAppJWTConfig): THorseCallback; static;

    class function GetUserId: Int64; static;
    class function GetRoles: TArray<string>; static;
    class function HasRole(const ARole: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  App.Response;

threadvar
  GCtx: TJWTContext;

procedure ClearCtx;
begin
  GCtx.UserId := 0;
  SetLength(GCtx.Roles, 0);
end;

class function TMiddlewareJWT.RequireAuth(const ACfg: TAppJWTConfig): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Token: string;
      Claims: TJWTClaims;
    begin
      ClearCtx;

      Token := TAppJWT.ExtrairBearerToken(Req.Headers['Authorization']);

      if Token.Trim.IsEmpty then
      begin
        TAppResponse.Unauthorized(Res, 'Token ausente. Use Authorization: Bearer <token>.');
        Exit;
      end;

      if not TAppJWT.ValidarEExtrair(ACfg, Token, Claims) then
      begin
        TAppResponse.Unauthorized(Res, 'Token inválido ou expirado.');
        Exit;
      end;

      GCtx.UserId := Claims.UserId;
      GCtx.Roles := Claims.Roles;

      try
        Next;
      finally
        ClearCtx;
      end;
    end;
end;

class function TMiddlewareJWT.OptionalAuth(const ACfg: TAppJWTConfig): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Token: string;
      Claims: TJWTClaims;
    begin
      ClearCtx;

      Token := TAppJWT.ExtrairBearerToken(Req.Headers['Authorization']);

      if (not Token.Trim.IsEmpty) and TAppJWT.ValidarEExtrair(ACfg, Token, Claims) then
      begin
        GCtx.UserId := Claims.UserId;
        GCtx.Roles := Claims.Roles;
      end;

      try
        Next;
      finally
        ClearCtx;
      end;
    end;
end;

class function TMiddlewareJWT.GetUserId: Int64;
begin
  Result := GCtx.UserId;
end;

class function TMiddlewareJWT.GetRoles: TArray<string>;
begin
  Result := GCtx.Roles;
end;

class function TMiddlewareJWT.HasRole(const ARole: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to High(GCtx.Roles) do
  begin
    if SameText(GCtx.Roles[I], ARole) then
      Exit(True);
  end;
end;

end.
