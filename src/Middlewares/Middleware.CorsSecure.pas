unit Middleware.CorsSecure;

interface

uses
  Horse;

type
  TMiddlewareCorsSecure = class
  public
    class function Headers: THorseCallback; static;
  end;

implementation

uses
  System.SysUtils,
  Horse.Exception.Interrupted,
  App.Config;

function OrigemPermitida(
  const AOrigin,
        AAllowedOrigin: string
): Boolean;
begin
  if Trim(AOrigin).IsEmpty then
    Exit(True);

  if SameText(Trim(AAllowedOrigin), '*') then
    Exit(True);

  Result :=
    SameText(
      Trim(AOrigin),
      Trim(AAllowedOrigin)
    );
end;

class function TMiddlewareCorsSecure.Headers: THorseCallback;
begin
  Result :=
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Config: TAppApiConfig;
      Origin: string;
      AllowedOrigin: string;
    begin
      Config :=
        TAppConfig.Carregar(
          ExtractFilePath(ParamStr(0)) + 'Config.ini'
        );

      Origin := Trim(Req.Headers['Origin']);
      AllowedOrigin := Trim(Config.CorsAllowedOrigin);

      if not OrigemPermitida(Origin, AllowedOrigin) then
      begin
        Res.Status(403)
          .ContentType('application/json')
          .Send('{"erro":true,"mensagem":"Origem não permitida.","dados":null}');
        Exit;
      end;

      if not Origin.IsEmpty then
      begin
        if SameText(AllowedOrigin, '*') then
          Res.AddHeader('Access-Control-Allow-Origin', '*')
        else
          Res.AddHeader('Access-Control-Allow-Origin', AllowedOrigin);

        Res.AddHeader('Vary', 'Origin');
      end;

      Res.AddHeader(
        'Access-Control-Allow-Methods',
        'GET, POST, PUT, PATCH, DELETE, OPTIONS'
      );

      Res.AddHeader(
        'Access-Control-Allow-Headers',
        'Authorization, Content-Type, Accept'
      );

      Res.AddHeader(
        'Access-Control-Max-Age',
        '600'
      );

      if SameText(Req.Method, 'OPTIONS') then
      begin
        Res.Status(204);
        raise EHorseCallbackInterrupted.Create;
      end;

      Next;
    end;
end;

end.
