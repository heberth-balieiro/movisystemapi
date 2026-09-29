unit Middleware.SecurityHeaders;

interface

uses
  Horse,
  System.SysUtils;

type
  TMiddlewareSecurityHeaders = class
  public
    class function Headers: THorseCallback; static;
  end;

implementation

class function TMiddlewareSecurityHeaders.Headers: THorseCallback;
begin
  Result :=
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    begin
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      Res.RawWebResponse.SetCustomHeader('X-Frame-Options', 'DENY');
      Res.RawWebResponse.SetCustomHeader('Referrer-Policy', 'no-referrer');
      Res.RawWebResponse.SetCustomHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
      Next;
    end;
end;

end.
