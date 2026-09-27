unit EleicaoConfirmacaoAPI.Controller;

interface

uses
  System.Generics.Collections;

type
  TEleicaoAPIConfirmacaoController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Response,
  APP.Errors,
  App.JWT,
  App.Token,
  EleicaoAPIPublic.Service,
  APP.Classes,
  App.RequestInfo;

{ TEleicaoAPIConfirmacaoController }

class procedure TEleicaoAPIConfirmacaoController.Registry;
begin

  {$REGION 'Confirmação'}

  //
  // SOLICITAR CÓDIGO
  //
  THorse.Post('/api/v1/public/eleicao/:slug/confirmacao/solicitar-codigo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims  : TJWTClaims;
      Slug    : string;
      Result  : TSolicitarCodigoResult;
      Retorno : TJSONObject;
    begin
      try
        // 1. Valida token_identificacao
        //
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        // 2. Recupera slug

        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');


        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');


        // 3. Chama Service
        //
        Result  := TEleicaoAPIPublicService.SolicitarCodigoConfirmacao(
                    Slug, Claims.UserId, Claims.IdEmpresa,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

        //
        // 4. Monta retorno
        //
        Retorno   := TJSONObject.Create;

        Retorno.AddPair('enviado', Result.Enviado);
        Retorno.AddPair('destino',Result.Destino);
        Retorno.AddPair('expira_em_segundos',TJSONNumber.Create(Result.ExpiraEmSegundos));
        Retorno.AddPair('reenviar_em_segundos',TJSONNumber.Create(Result.ReenviarEmSegundos));

        TAppResponse.Ok(Res,Retorno,'Código de confirmação enviado.');

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);


  //
  // VALIDAR CÓDIGO
  //
  THorse.Post('/api/v1/public/eleicao/:slug/confirmacao/validar-codigo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body    : TJSONObject;
      Claims  : TJWTClaims;
      Slug    : string;
      Codigo  : string;
      Result  : TValidarCodigoResult;
      Retorno : TJSONObject;
    begin
      try
        //
        // 1. Valida token_identificacao
        //
        if not TAppToken.ValidarToken(Req, Res, Claims) then
          Exit;

        //
        // 2. Recupera slug
        //
        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
        TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');



        //
        // 3. Recupera JSON
        //
        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Codigo := Trim(TAppClasses.GetJsonString(Body,'codigo'));

        if Codigo.IsEmpty then
          TAppErrors.RaiseBadRequest('Informe o código de confirmação.');

        //
        // 4. Chama Service
        //
        Result := TEleicaoAPIPublicService.ValidarCodigoConfirmacao(
                    Slug,
                    Claims.UserId,
                    Claims.IdEmpresa,
                    Codigo,
                    TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

        //
        // 5. Monta retorno
        //
        Retorno := TJSONObject.Create;

        Retorno.AddPair('confirmado',Result.Confirmado);
        Retorno.AddPair('token_votacao',Result.TokenVotacao);
        TAppResponse.Ok(Res,Retorno,'Código confirmado com sucesso.');

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

end;

end.
