unit Middleware.Roles;

{
Uso:

THorse.Get('/admin/health',
  TMiddlewareJWT.RequireAuth(JwtCfg),
  TMiddlewareRoles.RequireAnyRole(['ADM']),
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  begin
    ...
  end
);

}

interface

uses
  Horse;

type
  TMiddlewareRoles = class
  public
    class function RequireAnyRole(const ARoles: array of string): THorseCallback; static;
  end;

implementation

uses
  System.SysUtils,
  Middleware.JWT,
  App.Response;

class function TMiddlewareRoles.RequireAnyRole(const ARoles: array of string): THorseCallback;
var
  RolesCopy: TArray<string>;
  I: Integer;
begin
  // Copia o open array para um TArray<string> fixo.
  // Isso evita problemas ao usar ARoles dentro da closure.
  SetLength(RolesCopy, Length(ARoles));

  for I := 0 to High(ARoles) do
    RolesCopy[I] := UpperCase(Trim(ARoles[I]));

  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      J: Integer;
    begin
      if TMiddlewareJWT.GetUserId <= 0 then
      begin
        TAppResponse.Unauthorized(Res, 'Não autenticado.');
        Exit;
      end;

      for J := 0 to High(RolesCopy) do
      begin
        if TMiddlewareJWT.HasRole(RolesCopy[J]) then
        begin
          Next;
          Exit;
        end;
      end;

      TAppResponse.Forbidden(Res, 'Sem permissão para acessar este recurso.');
    end;
end;

end.
