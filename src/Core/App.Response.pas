unit App.Response;

interface

uses
  Horse,
  System.JSON;

type
  TAppResponse = class
  public
    class procedure Ok(const Res: THorseResponse; const ADados: TJSONValue; const AMensagem: string = ''); static;
    class procedure Created(const Res: THorseResponse; const ADados: TJSONValue; const AMensagem: string = ''); static;
    class procedure NoContent(const Res: THorseResponse); static;

    class procedure BadRequest(const Res: THorseResponse; const AMsg: string); static;
    class procedure Unauthorized(const Res: THorseResponse; const AMsg: string); static;
    class procedure Forbidden(const Res: THorseResponse; const AMsg: string); static;
    class procedure NotFound(const Res: THorseResponse; const AMsg: string); static;
    class procedure TooManyRequests(const Res: THorseResponse; const AMsg: string); static;
    class procedure ServerError(const Res: THorseResponse; const AMsg: string); static;

    class procedure SendStatus(const Res: THorseResponse; const AStatus: Integer;
      const AErro: Boolean; const AMsg: string; const ADados: TJSONValue); static;

    class function BuildSuccess(const ADados: TJSONValue; const AMsg: string = ''): TJSONObject; static;
    class function BuildError(const AMsg: string): TJSONObject; static;
  end;

implementation

class function TAppResponse.BuildSuccess(const ADados: TJSONValue; const AMsg: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('erro', TJSONBool.Create(False));
  Result.AddPair('mensagem', AMsg);

  if Assigned(ADados) then
    Result.AddPair('dados', ADados)
  else
    Result.AddPair('dados', TJSONNull.Create);
end;

class function TAppResponse.BuildError(const AMsg: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('erro', TJSONBool.Create(True));
  Result.AddPair('mensagem', AMsg);
  Result.AddPair('dados', TJSONNull.Create);
end;

class procedure TAppResponse.SendStatus(const Res: THorseResponse; const AStatus: Integer;
  const AErro: Boolean; const AMsg: string; const ADados: TJSONValue);
var
  Payload: TJSONObject;
begin
  if AErro then
    Payload := BuildError(AMsg)
  else
    Payload := BuildSuccess(ADados, AMsg);

  Res.Status(AStatus).Send<TJSONObject>(Payload);
end;

class procedure TAppResponse.Ok(const Res: THorseResponse; const ADados: TJSONValue; const AMensagem: string);
begin
  Res.Status(200).Send<TJSONObject>(BuildSuccess(ADados, AMensagem));
end;

class procedure TAppResponse.Created(const Res: THorseResponse; const ADados: TJSONValue; const AMensagem: string);
begin
  Res.Status(201).Send<TJSONObject>(BuildSuccess(ADados, AMensagem));
end;

class procedure TAppResponse.NoContent(const Res: THorseResponse);
begin
  Res.Status(204);
end;

class procedure TAppResponse.BadRequest(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(400).Send<TJSONObject>(BuildError(AMsg));
end;

class procedure TAppResponse.Unauthorized(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(401).Send<TJSONObject>(BuildError(AMsg));
end;

class procedure TAppResponse.Forbidden(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(403).Send<TJSONObject>(BuildError(AMsg));
end;

class procedure TAppResponse.NotFound(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(404).Send<TJSONObject>(BuildError(AMsg));
end;

class procedure TAppResponse.TooManyRequests(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(429).Send<TJSONObject>(BuildError(AMsg));
end;

class procedure TAppResponse.ServerError(const Res: THorseResponse; const AMsg: string);
begin
  Res.Status(500).Send<TJSONObject>(BuildError(AMsg));
end;

end.
