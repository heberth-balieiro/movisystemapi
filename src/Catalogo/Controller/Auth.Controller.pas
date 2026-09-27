unit Auth.Controller;

interface

type
  TAuthController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  Usuario.Service,
  App.Response,
  APP.Errors,
  App.Config,
  App.JWT;

function GetJsonString(const AJson: TJSONObject; const ACampo: string; const APadrao: string = ''): string;
var
  Valor: TJSONValue;
begin
  Result := APadrao;

  if AJson = nil then
    Exit;

  Valor := AJson.GetValue(ACampo);
  if Valor <> nil then
    Result := Trim(Valor.Value);
end;

class procedure TAuthController.Registry;
begin
  THorse.Post('/v1/auth/login',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body: TJSONObject;
      Email: string;
      Senha: string;
      Login: TLoginResult;
      Dados: TJSONObject;
      UsuarioJson: TJSONObject;
      EmpresaJson: TJSONObject;
    begin
      try
        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Email := GetJsonString(Body, 'email');
        Senha := GetJsonString(Body, 'senha');

        Login := TUsuarioService.Login(Email, Senha);

        UsuarioJson := TJSONObject.Create;
        UsuarioJson.AddPair('id_usuario', TJSONNumber.Create(Login.IdUsuario));
        UsuarioJson.AddPair('nome', Login.NomeUsuario);
        UsuarioJson.AddPair('email', Login.Email);
        UsuarioJson.AddPair('perfil', Login.Perfil);

        EmpresaJson := TJSONObject.Create;
        EmpresaJson.AddPair('id_empresa', TJSONNumber.Create(Login.IdEmpresa));
        EmpresaJson.AddPair('nome', Login.EmpresaNome);
        EmpresaJson.AddPair('data_validade', FormatDateTime('yyyy-mm-dd', Login.DataValidade));

        Dados := TJSONObject.Create;
        Dados.AddPair('token', Login.Token);
        Dados.AddPair('usuario', UsuarioJson);
        Dados.AddPair('empresa', EmpresaJson);

        TAppResponse.Ok(Res, Dados, 'Login realizado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Get('/v1/auth/me',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Config: TAppApiConfig;
      Token: string;
      Claims: TJWTClaims;
      Dados: TJSONObject;
      RolesArray: TJSONArray;
      Role: string;
    begin
      try
        Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');

        Token := TAppJWT.ExtrairBearerToken(Req.Headers['Authorization']);

        if Token.Trim.IsEmpty then
        begin
          TAppResponse.Unauthorized(Res, 'Token ausente. Use Authorization: Bearer <token>.');
          Exit;
        end;

        if not TAppJWT.ValidarEExtrair(Config.JWT, Token, Claims) then
        begin
          TAppResponse.Unauthorized(Res, 'Token inválido ou expirado.');
          Exit;
        end;

        RolesArray := TJSONArray.Create;

        for Role in Claims.Roles do
          RolesArray.Add(Role);

        Dados := TJSONObject.Create;
        Dados.AddPair('id_usuario', TJSONNumber.Create(Claims.UserId));
        Dados.AddPair('id_empresa', TJSONNumber.Create(Claims.IdEmpresa));
        Dados.AddPair('issuer', Claims.Issuer);
        Dados.AddPair('roles', RolesArray);

        TAppResponse.Ok(Res, Dados, 'Usuário autenticado.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
