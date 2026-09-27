unit Emp.Controller;

interface

Uses EasyOneIntegracao.Service;

type
  TEmpresasController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  App.Config,
  App.JWT,
  Emp.Model,
  Emp.Service,
  App.Response,
  APP.Errors,
  App.Classes,
  App.Token;

procedure PreencherEmpresaFromJson(const AJson: TJSONObject; const AEmpresa: TEmpresasModel);
begin
  AEmpresa.id_empresa     := TAppClasses.GetJsonInt(AJson, 'id_empresa',0); //id do retaguarda
  AEmpresa.uuid           := TAppClasses.GetJsonString(AJson, 'uuid');     //guid gerado para empresa usar online
  AEmpresa.razao          := TAppClasses.GetJsonString(AJson, 'razao');
  AEmpresa.fantasia       := TAppClasses.GetJsonString(AJson, 'fantasia');
  AEmpresa.telefone       := TAppClasses.GetJsonString(AJson, 'telefone');
  AEmpresa.ativo          := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  AEmpresa.cpfcnpj        := TAppClasses.GetJsonString(AJson, 'cpfcnpj');

  // Configuração WhatsApp
  AEmpresa.whatsapp_url             := TAppClasses.GetJsonString(AJson, 'whatsapp_url');
  AEmpresa.whatsapp_instancia       := TAppClasses.GetJsonString(AJson, 'whatsapp_instancia');
  AEmpresa.whatsapp_token           := TAppClasses.GetJsonString(AJson, 'whatsapp_token');
  // Integração EasyOne
  AEmpresa.easyone_api_key_hash     := TAppClasses.GetJsonString(AJson, 'easyone_api_key_hash');
  AEmpresa.easyone_integracao_ativo := TAppClasses.GetJsonString(AJson, 'easyone_integracao_ativo', 'N');


end;

class procedure TEmpresasController.Registry;
begin
  //para cadastro de empresa

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/empresa',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      Empresa   : TEmpresasModel;
      Resultado : TCadastroEmpresaResult;
      Retorno   : TJSONObject;
      UsuarioAPI:String;
      SenhaAPI  :String;
    begin
      try
        //Autenticacao
        UsuarioAPI := Trim(Req.Headers['X-EasyOne-Usuario']);
        SenhaAPI   := Trim(Req.Headers['X-EasyOne-Senha']);
        TEasyOneIntegracaoService.ValidarBootstrap(UsuarioAPI, SenhaAPI);

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Empresa     := TEmpresasModel.Create;
        try
          PreencherEmpresaFromJson(Body, Empresa);
          Resultado := TEmpresasServices.InserirEmpresa(Empresa);
          Retorno                   := TJSONObject.Create;
          Retorno.AddPair('','');

          TAppResponse.Created(Res, Retorno, 'Empresa cadastrada com sucesso.');
        finally
          Empresa.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}


end;

end.
