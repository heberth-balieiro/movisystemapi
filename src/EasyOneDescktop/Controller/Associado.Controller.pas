unit Associado.Controller;

interface

Uses EasyOneIntegracao.Service;

Type
TAssociadoController = Class
  private

  public
    class procedure Registry;
End;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Generics.Collections,
  Associado.Model,
  Associado.Service,
  App.Response,
  APP.Errors,
  App.Classes;

procedure PreencherAssociadoFromJson(const AJson: TJSONObject; const ADoc: TAssociadoModel);
begin

  ADoc.id_socio         := TAppClasses.GetJsonInt(AJson, 'id_socio',0);
  ADoc.codigo           := TAppClasses.GetJsonInt(AJson, 'codigo',0);
  ADoc.matricula        := TAppClasses.GetJsonInt(AJson, 'matricula',0);
  ADoc.ativo            := TAppClasses.GetJsonString(AJson, 'ativo', 'S');
  ADoc.nome             := TAppClasses.GetJsonString(AJson, 'nome');
  ADoc.apelido          := TAppClasses.GetJsonString(AJson, 'apelido');
  ADoc.telefone         := TAppClasses.GetJsonString(AJson, 'telefone');
  ADoc.celular          := TAppClasses.GetJsonString(AJson, 'celular');
  ADoc.whatsapp         := TAppClasses.GetJsonString(AJson, 'whatsapp');
  ADoc.cpf              := TAppClasses.GetJsonString(AJson, 'cpf');
  ADoc.nascimento       := TAppClasses.GetJsonDate(AJson, 'nascimento');
  ADoc.email            := TAppClasses.GetJsonString(AJson, 'email');
  ADoc.cidade           := TAppClasses.GetJsonString(AJson, 'cidade');
  ADoc.secretaria       := TAppClasses.GetJsonString(AJson, 'secretaria');
  ADoc.profissao        := TAppClasses.GetJsonString(AJson, 'profissao');
  ADoc.lotacao          := TAppClasses.GetJsonString(AJson, 'lotacao');
  ADoc.localtrabalho    := TAppClasses.GetJsonString(AJson, 'localtrabalho');
  ADoc.funcao           := TAppClasses.GetJsonString(AJson, 'funcao');
  ADoc.naturalde        := TAppClasses.GetJsonString(AJson, 'naturalde');
  ADoc.rg               := TAppClasses.GetJsonString(AJson, 'rg');
  ADoc.data_filiacao    := TAppClasses.GetJsonDate(AJson, 'data_filiacao');
  ADoc.pai              := TAppClasses.GetJsonString(AJson, 'pai');
  ADoc.mae              := TAppClasses.GetJsonString(AJson, 'mae');
  ADoc.foto             := TAppClasses.GetJsonString(AJson, 'foto');
  ADoc.bloqueado        := TAppClasses.GetJsonString(AJson, 'bloqueado', 'N');
  ADoc.excluido         := TAppClasses.GetJsonInt(AJson, 'excluido',0);

end;

class procedure TAssociadoController.Registry;
begin
  //para cadastro de associado

  {$REGION 'Post'}

  THorse.Post('/v1/integracao/associado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body      : TJSONObject;
      Associado : TAssociadoModel;
      Resultado : TCadastroassociadoResult;
      Contexto  : TEasyOneIntegracaoContexto;
      Retorno   : TJSONObject;
      AEmpresaID: Integer;
      UUID      : String;
      APIKey    : String;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        Body    := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Associado           := TAssociadoModel.Create;

        try
          PreencherAssociadoFromJson(Body, Associado);
          Resultado         := TAssociadoService.InserirAssociado(Contexto.IdEmpresaAPI, Associado);
          Retorno           := TJSONObject.Create;

          if Resultado.IdAssociado > 0 then
          Retorno.AddPair('id', TJSONNumber.Create(Resultado.IdAssociado));

          TAppResponse.Created(Res, Retorno, 'Associado sincronizado com sucesso.');
        finally
          Associado.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}


end;

end.
