unit PlataformaAuth.Controller;

interface
type
  TPlataformaAuthController = class
  public
    class procedure Registry; static;
  end;
implementation
uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Classes,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaAuth.Service;

class procedure TPlataformaAuthController.Registry;
begin
  {$REGION 'Adm Login'}

  THorse.Post('/v1/certifica/plataforma/auth/login',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body: TJSONObject;
      Login: string;
      Senha: string;
      Resultado: TPlataformaLoginResult;
      Dados: TJSONObject;
      UsuarioJson: TJSONObject;
      Permissoes: TJSONArray;
    begin
      try
        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Login     := Trim(TAppClasses.GetJsonString(Body, 'login'));
        Senha     := TAppClasses.GetJsonString(Body, 'senha');
        Resultado := TPlataformaAuthService.Login(Login,Senha,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

        Permissoes := TJSONArray.Create;
        Permissoes.Add('plataforma.*');
        UsuarioJson := TJSONObject.Create;
        UsuarioJson.AddPair('id', TJSONNumber.Create(Resultado.IdUsuario));
        UsuarioJson.AddPair('nome', Resultado.Nome);
        UsuarioJson.AddPair('email', Resultado.Email);
        UsuarioJson.AddPair('role', 'SUPER_ADMIN');
        UsuarioJson.AddPair('permissions', Permissoes);
        Dados := TJSONObject.Create;
        Dados.AddPair('token', Resultado.Token);
        Dados.AddPair('usuario', UsuarioJson);
        Dados.AddPair('instituicao', TJSONNull.Create);
        TAppResponse.Ok(Res, Dados, 'Login realizado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
  {$ENDREGION}

  {$REGION 'Novo Usuario'}


  {$ENDREGION}

  {$REGION 'Pesquisa Usuario'}


  {$ENDREGION}

  {$REGION 'Atualizar Usuario'}


  {$ENDREGION}




end;
end.

