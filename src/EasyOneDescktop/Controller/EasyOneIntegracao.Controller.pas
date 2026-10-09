unit EasyOneIntegracao.Controller;

interface

type
  TEasyOneIntegracaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  APP.Errors,
  APP.Classes,
  App.Response,
  EasyOneIntegracao.Service;

{ TEasyOneIntegracaoController }

class procedure TEasyOneIntegracaoController.Registry;
begin
  THorse.Get('/api/v1/integracao/easyone/autenticar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID    : string;
      APIKey  : string;
      Contexto: TEasyOneIntegracaoContexto;
      Retorno : TJSONObject;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID, APIKey);

        Retorno := TJSONObject.Create;
        Retorno.AddPair('autenticado', 'S');
        Retorno.AddPair('id_empresa', TJSONNumber.Create(Contexto.IdEmpresa));
        Retorno.AddPair('uuid', Contexto.UUID);

        TAppResponse.OK(Res, Retorno, 'Integração autenticada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Pendências criadas pela página pública /atualizar-cadastro.
  // Mantém o mesmo prefixo /v1 utilizado pelo EasyBot nas rotas de integração.
  THorse.Get('/v1/integracao/easyone/atualizacoes-cadastrais/pendentes',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID    : string;
      APIKey  : string;
      Contexto: TEasyOneIntegracaoContexto;
      Dados   : TJSONArray;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID, APIKey);
        Dados := TEasyOneIntegracaoService.ListarAtualizacoesCadastraisPendentes(
          Contexto.IdEmpresaAPI
        );

        TAppResponse.OK(
          Res,
          Dados,
          'Solicitações cadastrais pendentes consultadas com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Retorno do EasyBot após o processamento local pelo EasyOne.
  THorse.Post('/v1/integracao/easyone/atualizacoes-cadastrais/status',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID         : string;
      APIKey       : string;
      Contexto     : TEasyOneIntegracaoContexto;
      Body         : TJSONObject;
      IdSolicitacao: Int64;
      Situacao     : string;
      Observacao   : string;
      Retorno      : TJSONObject;
    begin
      try
        UUID   := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);

        Contexto := TEasyOneIntegracaoService.Autenticar(UUID, APIKey);

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        if not TryStrToInt64(
          Trim(TAppClasses.GetJsonString(Body, 'id_solicitacao')),
          IdSolicitacao
        ) then
          TAppErrors.RaiseBadRequest('Solicitação cadastral inválida.');

        Situacao   := Trim(TAppClasses.GetJsonString(Body, 'situacao'));
        Observacao := Trim(TAppClasses.GetJsonString(Body, 'observacao'));

        TEasyOneIntegracaoService.AtualizarStatusAtualizacaoCadastral(
          Contexto.IdEmpresaAPI,
          IdSolicitacao,
          Situacao,
          Observacao
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('id_solicitacao', TJSONNumber.Create(IdSolicitacao));
        Retorno.AddPair('situacao', UpperCase(Situacao));

        TAppResponse.OK(
          Res,
          Retorno,
          'Status da solicitação cadastral atualizado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);
end;

end.
