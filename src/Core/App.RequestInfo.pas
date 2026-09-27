unit App.RequestInfo;

interface

uses
  Horse;

type
  TAppRequestInfo = class
  public
    class function GetIP(const AReq: THorseRequest): string; static;
    class function GetUserAgent(const AReq: THorseRequest): string; static;
  end;

implementation

uses
  System.SysUtils;

class function TAppRequestInfo.GetIP(const AReq: THorseRequest): string;
var
  P: Integer;
begin
  Result := Trim(AReq.Headers['X-Real-IP']);

  if Result.IsEmpty then
    Result := Trim(AReq.Headers['X-Forwarded-For']);

  P := Pos(',', Result);
  if P > 0 then
    Result := Trim(Copy(Result, 1, P - 1));

  if Result.IsEmpty then
    Result := Trim(AReq.RawWebRequest.RemoteAddr);

  Result := Copy(Result, 1, 45);
end;

class function TAppRequestInfo.GetUserAgent(const AReq: THorseRequest): string;
begin
  Result := Copy(Trim(AReq.Headers['User-Agent']), 1, 500);
end;

end.
