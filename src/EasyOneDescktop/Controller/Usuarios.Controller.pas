unit Usuarios.Controller;

interface

type
  TUsuariosController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  Usuarios.Model,
  Usuarios.Service,
  App.Response,
  APP.Errors,
  App.Classes,
  EasyOneIntegracao.Service;

procedure PreencherUsuariosFromJson(const AJson: TJSONObject; const ADoc: TUsuariosModel);
begin
  ADoc.id_socio   := TAppClasses.GetJsonInt(AJson,'id_socio',0);
  ADoc.nome       := TAppClasses.GetJsonString(AJson,'nome');
  ADoc.login      := TAppClasses.GetJsonString(AJson,'login');
  ADoc.senha_hash := TAppClasses.GetJsonString(AJson,'senha_hash');
  ADoc.ativo      := TAppClasses.GetJsonString(AJson,'ativo','S');
  ADoc.email      := TAppClasses.GetJsonString(AJson,'email');
end;

procedure PreencherAssociadoAPTOSFromJson(const AJson: TJSONObject; const ADoc: TUsuariosModel);
begin
  ADoc.id_eleitor_int:= TAppClasses.GetJsonInt(AJson,'id_eleitor',0);
  ADoc.id_socio   := TAppClasses.GetJsonInt(AJson,'id_socio',0);
  ADoc.nome       := TAppClasses.GetJsonString(AJson,'nome');
  ADoc.login      := TAppClasses.GetJsonString(AJson,'login');
  ADoc.senha_hash := TAppClasses.GetJsonString(AJson,'senha_hash');
  ADoc.ativo      := TAppClasses.GetJsonString(AJson,'ativo','S');
  ADoc.email      := TAppClasses.GetJsonString(AJson,'email');
end;

class procedure TUsuariosController.Registry;
begin
  {$REGION 'Login Associado'}

  THorse.Post('/v1/integracao/usuario/associado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID     : string;
      APIKey   : string;
      Contexto : TEasyOneIntegracaoContexto;
      Body     : TJSONObject;
      Usuario  : TUsuariosModel;
      Resultado: TCadastroUsuariosResult;
      Retorno  : TJSONObject;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Usuario := TUsuariosModel.Create;
        try
          PreencherAssociadoAPTOSFromJson(Body,Usuario);

          Resultado   := TUsuariosService.InserirUsuario(Contexto.IdEmpresaAPI,Usuario);
          Retorno     := TJSONObject.Create;

          if Resultado.IdUsuarios > 0 then
            Retorno.AddPair('id',TJSONNumber.Create(Resultado.IdUsuarios));

          TAppResponse.Created(Res,Retorno,'[API] Usuário/Associado sincronizado com sucesso.');
        finally
          Usuario.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end);
  {$ENDREGION}


  {$REGION 'Login Sistema'}

  THorse.Post('/v1/integracao/usuario/sistema',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID     : string;
      APIKey   : string;
      Contexto : TEasyOneIntegracaoContexto;
      Body     : TJSONObject;
      Usuario  : TUsuariosModel;
      Resultado: TCadastroUsuariosResult;
      Retorno  : TJSONObject;
    begin
      try
        UUID      := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey    := Trim(Req.Headers['X-EasyOne-Key']);
        Contexto  := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Usuario := TUsuariosModel.Create;
        try
          PreencherUsuariosFromJson(Body,Usuario);
          Resultado := TUsuariosService.InserirUsuario(Contexto.IdEmpresaAPI,Usuario);
          Retorno   := TJSONObject.Create;

          if Resultado.IdUsuarios > 0 then
            Retorno.AddPair('id',TJSONNumber.Create(Resultado.IdUsuarios));

          TAppResponse.Created(Res,Retorno, '[API] Usuário sincronizado com sucesso.');
        finally
          Usuario.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end);
  {$ENDREGION}
end;

end.
