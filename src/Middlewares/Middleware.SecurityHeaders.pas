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

uses
  App.Config;

class function TMiddlewareSecurityHeaders.Headers: THorseCallback;
begin
  Result :=
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Config: TAppApiConfig;
    begin
      Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
      Res.RawWebResponse.SetCustomHeader('X-Frame-Options', 'DENY');
      Res.RawWebResponse.SetCustomHeader('Referrer-Policy', 'no-referrer');
      Res.RawWebResponse.SetCustomHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
      Res.RawWebResponse.SetCustomHeader(
        'Content-Security-Policy',
        'default-src ''none''; frame-ancestors ''none''; base-uri ''none'''
      );

      Config :=
        TAppConfig.Carregar(
          ExtractFilePath(ParamStr(0)) + 'Config.ini'
        );

      if SameText(Config.Ambiente, 'PRODUCAO') then
        Res.RawWebResponse.SetCustomHeader(
          'Strict-Transport-Security',
          'max-age=31536000; includeSubDomains'
        );

      Next;
    end;
end;

end.
