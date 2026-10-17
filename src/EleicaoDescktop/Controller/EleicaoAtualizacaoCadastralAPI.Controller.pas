unit EleicaoAtualizacaoCadastralAPI.Controller;

interface

type
  TEleicaoAtualizacaoCadastralAPIController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Response,
  APP.Errors,
  App.Token,
  App.JWT,
  APP.Classes,
  App.RequestInfo,
  EleicaoMelhoriasAPI.Service,
  EleicaoAtualizacaoCadastralEndereco.Service;

class procedure TEleicaoAtualizacaoCadastralAPIController.Registry;
begin
  TEleicaoMelhoriasAPIService.EnsureSchema;
  TEleicaoAtualizacaoCadastralEnderecoService.EnsureSchema;

  THorse.Post('/api/v1/public/atualizacao-cadastral/identificar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body: TJSONObject;
      CPF, Matricula: string;
      Dados: TAtualizacaoCadastralIdentificacaoResult;
      Retorno: TJSONObject;
    begin
      try
        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        CPF := Trim(TAppClasses.GetJsonString(Body, 'cpf'));
        Matricula := Trim(TAppClasses.GetJsonString(Body, 'matricula'));

        Dados := TEleicaoMelhoriasAPIService.IdentificarAssociado(
          CPF,
          Matricula,
          TAppRequestInfo.GetIP(Req)
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('identificado', Dados.Identificado);
        Retorno.AddPair('nome', Dados.Nome);
        Retorno.AddPair('token_atualizacao', Dados.Token);
        TAppResponse.Ok(Res, Retorno, 'Associado identificado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post('/api/v1/public/atualizacao-cadastral/solicitar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Body: TJSONObject;
      Email, Telefone, Whatsapp: string;
      CEP, Endereco, Numero, Bairro, Complemento, Cidade: string;
      Dados: TAtualizacaoCadastralSolicitacaoResult;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        if not TAppToken.PossuiRole(Claims.Roles, 'ATUALIZACAO_CADASTRAL') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Email := Trim(TAppClasses.GetJsonString(Body, 'email'));
        Telefone := Trim(TAppClasses.GetJsonString(Body, 'telefone'));
        Whatsapp := Trim(TAppClasses.GetJsonString(Body, 'whatsapp'));
        CEP := Trim(TAppClasses.GetJsonString(Body, 'cep'));
        Endereco := Trim(TAppClasses.GetJsonString(Body, 'endereco'));
        Numero := Trim(TAppClasses.GetJsonString(Body, 'numero'));
        Bairro := Trim(TAppClasses.GetJsonString(Body, 'bairro'));
        Complemento := Trim(TAppClasses.GetJsonString(Body, 'complemento'));
        Cidade := Trim(TAppClasses.GetJsonString(Body, 'cidade'));

        Dados := TEleicaoAtualizacaoCadastralEnderecoService.SolicitarAtualizacao(
          Claims.IdEmpresa,
          Claims.UserId,
          Email,
          Telefone,
          Whatsapp,
          CEP,
          Endereco,
          Numero,
          Bairro,
          Complemento,
          Cidade,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('solicitacao', TJSONNumber.Create(Dados.IdSolicitacao));
        Retorno.AddPair('situacao', Dados.Situacao);
        TAppResponse.Ok(Res, Retorno, 'Solicitação de atualização cadastral registrada.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
