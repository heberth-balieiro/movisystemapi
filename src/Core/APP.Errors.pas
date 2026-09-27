unit APP.Errors;

interface

uses
  System.SysUtils,
  Horse;

type
  EAppBase = class(Exception)
  private
    FStatusCode: Integer;
  public
    constructor Create(const AMsg: string; const AStatusCode: Integer); reintroduce;
    property StatusCode: Integer read FStatusCode;
  end;

  EAppBadRequest   = class(EAppBase);
  EAppUnauthorized = class(EAppBase);
  EAppForbidden    = class(EAppBase);
  EAppNotFound     = class(EAppBase);

  TAppErrors = class
  public
    class procedure HandleException(const Res: THorseResponse; const E: Exception); static;

    class procedure RaiseBadRequest(const AMsg: string); static;
    class procedure RaiseUnauthorized(const AMsg: string); static;
    class procedure RaiseForbidden(const AMsg: string); static;
    class procedure RaiseNotFound(const AMsg: string); static;
  end;

implementation

uses
  App.Response;

constructor EAppBase.Create(const AMsg: string; const AStatusCode: Integer);
begin
  inherited Create(AMsg);
  FStatusCode := AStatusCode;
end;

class procedure TAppErrors.HandleException(const Res: THorseResponse; const E: Exception);
var
  StatusCode: Integer;
begin
  if E is EAppBase then
  begin
    StatusCode := (E as EAppBase).StatusCode;

    case StatusCode of
      400: TAppResponse.BadRequest(Res, E.Message);
      401: TAppResponse.Unauthorized(Res, E.Message);
      403: TAppResponse.Forbidden(Res, E.Message);
      404: TAppResponse.NotFound(Res, E.Message);
    else
      TAppResponse.ServerError(Res, E.Message);
    end;

    Exit;
  end;

  TAppResponse.ServerError(Res, 'Erro interno: ' + E.Message);
end;

class procedure TAppErrors.RaiseBadRequest(const AMsg: string);
begin
  raise EAppBadRequest.Create(AMsg, 400);
end;

class procedure TAppErrors.RaiseUnauthorized(const AMsg: string);
begin
  raise EAppUnauthorized.Create(AMsg, 401);
end;

class procedure TAppErrors.RaiseForbidden(const AMsg: string);
begin
  raise EAppForbidden.Create(AMsg, 403);
end;

class procedure TAppErrors.RaiseNotFound(const AMsg: string);
begin
  raise EAppNotFound.Create(AMsg, 404);
end;

end.
