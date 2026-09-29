unit App.RateLimit;

interface

uses
  Horse;

type
  TAppRateLimit = class
  private
    class function Bloquear(
      const ARes: THorseResponse;
      const ARetryAfter,
            ALimite: Integer
    ): Boolean; static;

    class function Permitir(
      const AChave: string;
      const ALimite,
            AJanelaSegundos: Integer;
      out ARetryAfter: Integer
    ): Boolean; static;

  public
    class function EnforceIP(
      const AReq: THorseRequest;
      const ARes: THorseResponse;
      const AEscopo: string;
      const ALimite,
            AJanelaSegundos: Integer
    ): Boolean; static;

    class function EnforceIdentity(
      const AReq: THorseRequest;
      const ARes: THorseResponse;
      const AEscopo,
            AIdentidade: string;
      const ALimite,
            AJanelaSegundos: Integer
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Hash,
  System.IniFiles,
  System.SyncObjs,
  System.Generics.Collections,
  App.RequestInfo,
  App.Response;

type
  TRateLimitEntry = record
    Quantidade: Integer;
    ExpiraEm: TDateTime;
  end;

var
  GGuard: TCriticalSection;
  GEntries: TDictionary<string, TRateLimitEntry>;
  GOperacoes: Integer;
  GHabilitado: Boolean;
  GConfiarProxyHeaders: Boolean;

procedure CarregarConfiguracao;
var
  Ini: TIniFile;
  Caminho: string;
begin
  GHabilitado := True;
  GConfiarProxyHeaders := False;

  Caminho := ExtractFilePath(ParamStr(0)) + 'Config.ini';
  if not FileExists(Caminho) then
    Exit;

  Ini := TIniFile.Create(Caminho);
  try
    GHabilitado := Ini.ReadInteger('SECURITY', 'RateLimitEnabled', 1) <> 0;
    GConfiarProxyHeaders := Ini.ReadInteger('SECURITY', 'TrustProxyHeaders', 0) <> 0;
  finally
    Ini.Free;
  end;
end;

procedure LimparExpirados(const AAgora: TDateTime);
var
  Par: TPair<string, TRateLimitEntry>;
  Chaves: TList<string>;
  Chave: string;
begin
  Chaves := TList<string>.Create;
  try
    for Par in GEntries do
      if Par.Value.ExpiraEm <= AAgora then
        Chaves.Add(Par.Key);

    for Chave in Chaves do
      GEntries.Remove(Chave);
  finally
    Chaves.Free;
  end;
end;

function HashIdentidade(const AValor: string): string;
var
  Normalizado: string;
begin
  Normalizado := LowerCase(Trim(AValor));

  if Normalizado.IsEmpty then
    Exit('');

  Result := LowerCase(THashSHA2.GetHashString(Normalizado));
end;

class function TAppRateLimit.Permitir(
  const AChave: string;
  const ALimite,
        AJanelaSegundos: Integer;
  out ARetryAfter: Integer
): Boolean;
var
  Agora: TDateTime;
  Item: TRateLimitEntry;
begin
  Result := True;
  ARetryAfter := 0;

  if not GHabilitado then
    Exit;

  if (ALimite <= 0) or (AJanelaSegundos <= 0) then
    Exit;

  Agora := Now;

  GGuard.Acquire;
  try
    Inc(GOperacoes);

    if (GOperacoes mod 256) = 0 then
      LimparExpirados(Agora);

    if not GEntries.TryGetValue(AChave, Item) or
       (Item.ExpiraEm <= Agora) then
    begin
      Item.Quantidade := 1;
      Item.ExpiraEm := IncSecond(Agora, AJanelaSegundos);
      GEntries.AddOrSetValue(AChave, Item);
      Exit(True);
    end;

    if Item.Quantidade >= ALimite then
    begin
      ARetryAfter := Trunc((Item.ExpiraEm - Agora) * 86400) + 1;

      if ARetryAfter < 1 then
        ARetryAfter := 1;

      Exit(False);
    end;

    Inc(Item.Quantidade);
    GEntries.AddOrSetValue(AChave, Item);
  finally
    GGuard.Release;
  end;
end;

class function TAppRateLimit.Bloquear(
  const ARes: THorseResponse;
  const ARetryAfter,
        ALimite: Integer
): Boolean;
begin
  ARes.RawWebResponse.SetCustomHeader('Retry-After', IntToStr(ARetryAfter));
  ARes.RawWebResponse.SetCustomHeader('X-RateLimit-Limit', IntToStr(ALimite));
  ARes.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

  TAppResponse.TooManyRequests(
    ARes,
    'Muitas tentativas em pouco tempo. Aguarde alguns instantes e tente novamente.'
  );

  Result := False;
end;

class function TAppRateLimit.EnforceIP(
  const AReq: THorseRequest;
  const ARes: THorseResponse;
  const AEscopo: string;
  const ALimite,
        AJanelaSegundos: Integer
): Boolean;
var
  IP: string;
  Chave: string;
  RetryAfter: Integer;
begin
  IP := TAppRequestInfo.GetIP(AReq, GConfiarProxyHeaders);

  if IP.IsEmpty then
    IP := 'unknown';

  Chave := LowerCase(Trim(AEscopo)) + '|ip|' + IP;

  if Permitir(Chave, ALimite, AJanelaSegundos, RetryAfter) then
    Exit(True);

  Result := Bloquear(ARes, RetryAfter, ALimite);
end;

class function TAppRateLimit.EnforceIdentity(
  const AReq: THorseRequest;
  const ARes: THorseResponse;
  const AEscopo,
        AIdentidade: string;
  const ALimite,
        AJanelaSegundos: Integer
): Boolean;
var
  IdentidadeHash: string;
  Chave: string;
  RetryAfter: Integer;
begin
  IdentidadeHash := HashIdentidade(AIdentidade);

  if IdentidadeHash.IsEmpty then
    Exit(True);

  Chave := LowerCase(Trim(AEscopo)) + '|identity|' + IdentidadeHash;

  if Permitir(Chave, ALimite, AJanelaSegundos, RetryAfter) then
    Exit(True);

  Result := Bloquear(ARes, RetryAfter, ALimite);
end;

initialization
  GGuard := TCriticalSection.Create;
  GEntries := TDictionary<string, TRateLimitEntry>.Create;
  GOperacoes := 0;
  CarregarConfiguracao;

finalization
  GEntries.Free;
  GGuard.Free;

end.
