unit App.RequestInfo;

interface

uses
  Horse;

type
  TAppRequestInfo = class
  public
    class function GetIP(
      const AReq: THorseRequest;
      const ATrustProxyHeaders: Boolean = False
    ): string; static;

    class function GetUserAgent(
      const AReq: THorseRequest
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils;

function NormalizarIP(const AValor: string): string;
var
  Valor: string;
  P: Integer;
  C: Char;
begin
  Result := '';
  Valor := Trim(AValor);

  P := Pos(',', Valor);
  if P > 0 then
    Valor := Trim(Copy(Valor, 1, P - 1));

  if (Length(Valor) = 0) or (Length(Valor) > 45) then
    Exit;

  for C in Valor do
    if not CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F', '.', ':']) then
      Exit;

  Result := Valor;
end;

function IPPrivadoOuLocal(const AIP: string): Boolean;
var
  Partes: TArray<string>;
  SegundoOcteto: Integer;
  IP: string;
begin
  IP := LowerCase(Trim(AIP));

  Result :=
    (IP = '::1') or
    StartsText('127.', IP) or
    StartsText('10.', IP) or
    StartsText('192.168.', IP) or
    StartsText('fc', IP) or
    StartsText('fd', IP) or
    StartsText('fe80:', IP);

  if Result then
    Exit;

  Partes := IP.Split(['.']);

  if (Length(Partes) = 4) and (Partes[0] = '172') then
  begin
    SegundoOcteto := StrToIntDef(Partes[1], -1);
    Result := (SegundoOcteto >= 16) and (SegundoOcteto <= 31);
  end;
end;

class function TAppRequestInfo.GetIP(
  const AReq: THorseRequest;
  const ATrustProxyHeaders: Boolean
): string;
var
  IPRemoto: string;
  PodeConfiarProxy: Boolean;
begin
  IPRemoto := NormalizarIP(AReq.RawWebRequest.RemoteAddr);

  PodeConfiarProxy :=
    ATrustProxyHeaders or
    IPPrivadoOuLocal(IPRemoto);

  Result := '';

  if PodeConfiarProxy then
  begin
    Result := NormalizarIP(AReq.Headers['X-Real-IP']);

    if Result.IsEmpty then
      Result := NormalizarIP(AReq.Headers['CF-Connecting-IP']);

    if Result.IsEmpty then
      Result := NormalizarIP(AReq.Headers['X-Forwarded-For']);
  end;

  if Result.IsEmpty then
    Result := IPRemoto;
end;

class function TAppRequestInfo.GetUserAgent(
  const AReq: THorseRequest
): string;
begin
  Result := Copy(Trim(AReq.Headers['User-Agent']), 1, 500);
end;

end.
