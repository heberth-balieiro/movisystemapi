unit EleicaoVotacaoAPI.Controller;

interface

uses
  System.Generics.Collections;

type
  TEleicaoAPIVotacaoController = class
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
  EleicaoVotacaoAPI.Service,
  App.Classes;

{ TEleicaoAPIVotacaoController }

class procedure TEleicaoAPIVotacaoController.Registry;
begin
  {$REGION 'Votacao carregar'}

  THorse.Get(
    '/api/v1/public/eleicao/:slug/votacao',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Retorno: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then
          Exit;

        if not TAppToken.PossuiRole(Claims.Roles,'ELEITOR_VOTACAO') then
          TAppErrors.RaiseUnauthorized('Acesso a votacao nao autorizado.');

        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleicao nao informada.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token nao pertence a esta eleicao.');

        Retorno := TEleicaoAPIPublicService.BuscarCedulaVotacao(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa
        );

        TEleicaoVotacaoAPIService.CompletarCedulaAssembleia(
          Slug,
          Claims.IdEmpresa,
          Retorno
        );

        TAppResponse.Ok(
          Res,
          Retorno,
          ''
        );

      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Votar'}

  THorse.Post(
    '/api/v1/public/eleicao/:slug/votacao/votar',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Body: TJSONObject;
      Respostas: TJSONArray;
      TipoVoto: string;
      IdChapa: Integer;
      Resultado: TVotacaoResult;
      Dados: TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req,Res,Claims) then
          Exit;

        if not TAppToken.PossuiRole(Claims.Roles,'ELEITOR_VOTACAO') then
          TAppErrors.RaiseUnauthorized('Acesso a votacao nao autorizado.');

        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleicao nao informada.');

        if not TAppToken.PertenceEleicao(Claims,Slug) then
          TAppErrors.RaiseUnauthorized('Token nao pertence a esta eleicao.');

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('Dados do voto nao informados.');

        Respostas := Body.GetValue<TJSONArray>('respostas');

        if Assigned(Respostas) then
        begin
          Resultado := TEleicaoVotacaoAPIService.RegistrarVotoAssembleia(
            Slug,
            Claims.UserId,
            Claims.IdEmpresa,
            Respostas
          );
        end
        else
        begin
          TipoVoto := UpperCase(
            Trim(
              TAppClasses.GetJsonString(Body,'tipo_voto')
            )
          );

          if TipoVoto.IsEmpty then
            TAppErrors.RaiseBadRequest('Tipo de voto nao informado.');

          IdChapa := 0;

          if Body.GetValue('id_chapa') <> nil then
            IdChapa := Body.GetValue<Integer>('id_chapa',0);

          Resultado := TEleicaoVotacaoAPIService.RegistrarVoto(
            Slug,
            Claims.UserId,
            Claims.IdEmpresa,
            TipoVoto,
            IdChapa
          );
        end;

        Dados := TJSONObject.Create;
        Dados.AddPair('confirmado',Resultado.Confirmado);
        Dados.AddPair('tipo_voto',Resultado.TipoVoto);
        Dados.AddPair('comprovante',Resultado.Comprovante);

        TAppResponse.Ok(
          Res,
          Dados,
          'Voto registrado com sucesso.'
        );

      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end
  );

  {$ENDREGION}
end;

end.
