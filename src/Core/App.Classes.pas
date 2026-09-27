unit App.Classes;

interface

Uses
 System.SysUtils,
  System.JSON,
  App.JWT,
  App.Errors,
  System.DateUtils,
  Horse;

Type
TAppClasses = class
  Private

  public
    class function GetJsonString(const AJson: TJSONObject; const ACampo: string; const APadrao: string = ''): string;
    class function GetJsonInt(const AJson: TJSONObject; const ACampo: string;const APadrao: Integer): Integer;
    class function GetJsonCurrency(const AJson: TJSONObject; const ACampo: string; const APadrao: Currency = 0): Currency;
    class function GetJsonDate(const AJson: TJSONObject; const ACampo: string): TDateTime;
    class function GetFormField(const Req: THorseRequest; const ACampo: string): string;
    class function GetJsonDateTimeISO(const AJson: TJSONObject;const ACampo: string): TDateTime; static;


    class function PossuiPerfil(const AClaims: TJWTClaims; const APerfil: string): Boolean;
    class function SafeStr(const AValue: string): string; static;

    // tratar campo ativo
    class function NormalizarSN(const AValor,APadrao: string): string;

end;


implementation

{ TAppClasses }

class function TAppClasses.GetFormField(const Req: THorseRequest;const ACampo: string): string;
begin
  Result := '';
  if Req.RawWebRequest <> nil then
    Result := Trim(Req.RawWebRequest.ContentFields.Values[ACampo]);
end;

class function TAppClasses.GetJsonCurrency(const AJson: TJSONObject;const ACampo: string; const APadrao: Currency): Currency;
var
  Valor: TJSONValue;
  Texto: string;
begin
  Result := APadrao;

  if AJson = nil then
    Exit;

  Valor := AJson.GetValue(ACampo);

  if Valor <> nil then
  begin
    Texto := StringReplace(Valor.Value, ',', '.', [rfReplaceAll]);
    Result := StrToCurrDef(Texto, APadrao, TFormatSettings.Invariant);
  end;
end;

class function TAppClasses.GetJsonDate(const AJson: TJSONObject;const ACampo: string): TDateTime;
var
  Valor: TJSONValue;
  Texto: string;
  FS: TFormatSettings;
  DataTmp: TDateTime;
begin
  Result := 0;

  if AJson = nil then
    Exit;

  Valor := AJson.GetValue(ACampo);

  if Valor = nil then
    Exit;

  Texto := Trim(Valor.Value);

  if Texto.IsEmpty then
    Exit;

  FS := TFormatSettings.Create;
  FS.DateSeparator := '-';
  FS.TimeSeparator := ':';
  FS.ShortDateFormat := 'yyyy-mm-dd';
  FS.ShortTimeFormat := 'hh:nn:ss';
  FS.LongTimeFormat := 'hh:nn:ss';

  if TryStrToDateTime(Texto, DataTmp, FS) then
    Result := DataTmp
  else if TryStrToDate(Texto, DataTmp, FS) then
    Result := DataTmp;
end;

class function TAppClasses.GetJsonInt(const AJson: TJSONObject;const ACampo: string; const APadrao: Integer): Integer;
var
  Valor: TJSONValue;
begin
  Result := APadrao;

  if AJson = nil then
    Exit;

  Valor := AJson.GetValue(ACampo);

  if Valor <> nil then
    Result := StrToIntDef(Valor.Value, APadrao);
end;

class function TAppClasses.GetJsonString(const AJson: TJSONObject; const ACampo,APadrao: string): string;
var
  Valor: TJSONValue;
begin
  Result := APadrao;

  if AJson = nil then
    Exit;

  Valor := AJson.GetValue(ACampo);

  if Valor <> nil then
    Result := Valor.Value;
end;

class function TAppClasses.GetJsonDateTimeISO(const AJson: TJSONObject; const ACampo: string): TDateTime;
var
  Valor: string;
begin
  Result := 0;
  Valor := Trim(TAppClasses.GetJsonString(AJson,ACampo));
  if Valor.IsEmpty then Exit;
  try
    Result := ISO8601ToDate(Valor,True);
  except
    TAppErrors.RaiseBadRequest('Campo ' + ACampo + ' inválido. Informe a data no formato ISO 8601.');
  end;
end;



class function TAppClasses.PossuiPerfil(const AClaims: TJWTClaims;const APerfil: string): Boolean;
var
  Role: string;
begin
  Result := False;

  for Role in AClaims.Roles do
  begin
    if SameText(Role, APerfil) then
      Exit(True);
  end;
end;

class function TAppClasses.SafeStr(const AValue: string): string;
begin
  //funcao para tratar valores null
  Result := Trim(AValue);
  if SameText(Result, 'null') then
    Result := '';
end;

class function TAppClasses.NormalizarSN(const AValor,APadrao: string): string;
var
  Valor: string;
begin
  Valor := UpperCase(Trim(AValor));

  if Valor.IsEmpty then
    Valor := UpperCase(Trim(APadrao));

  if (Valor <> 'S') and (Valor <> 'N') then
    Valor := UpperCase(Trim(APadrao));

  if Valor.IsEmpty then
    Valor := 'N';

  Result := Valor;
end;





end.

