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
//
  {$REGION 'Votação carregar'}

  //
  // CARREGAR CÉDULA DE VOTAÇÃO
  //
  THorse.Get(
    '/api/v1/public/eleicao/:slug/votacao',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims  : TJWTClaims;
      Slug    : string;
      Retorno : TJSONObject;
    begin
      try
        // 1. Validar token_votacao

        if not TAppToken.ValidarToken(Req,Res,Claims) then
          Exit;

        if not TAppToken.PossuiRole(Claims.Roles,'ELEITOR_VOTACAO') then
        begin
          TAppErrors.RaiseUnauthorized('Acesso à votação não autorizado.');
        end;

        // 2. Recuperar slug
        Slug    := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        if not TAppToken.PertenceEleicao(Claims, Slug) then
        TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        // 3. Buscar cédula

        Retorno := TEleicaoAPIPublicService.BuscarCedulaVotacao(
            Slug,
            Claims.UserId,
            Claims.IdEmpresa
          );

        //
        // 4. Retorno
        //
        TAppResponse.Ok(
          Res,
          Retorno,
          ''
        );

      except
        on E: Exception do
          TAppErrors.HandleException(
            Res,
            E
          );
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Votar'}

  THorse.Post('/api/v1/public/eleicao/:slug/votacao/votar',

  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims   : TJWTClaims;
    Slug     : string;
    Body     : TJSONObject;
    TipoVoto : string;
    IdChapa  : Integer;
    Resultado: TVotacaoResult;
    Dados    : TJSONObject;
  begin
    try
      // 1. Validar token
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      // 2. Aceitar somente token de votação
      if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_VOTACAO') then
        TAppErrors.RaiseUnauthorized('Acesso à votação não autorizado.');

      // 3. Slug
      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest(
          'Eleição não informada.'
        );

      if not TAppToken.PertenceEleicao(Claims, Slug) then
        TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');


      //
      // 4. Body
      //
      Body := Req.Body<TJSONObject>;

      if Body = nil then
        TAppErrors.RaiseBadRequest(
          'Dados do voto não informados.'
        );

      TipoVoto    :=
        UpperCase(
          Trim(
            TAppClasses.GetJsonString(Body,'tipo_voto')
          )
        );

      if TipoVoto.IsEmpty then
        TAppErrors.RaiseBadRequest(
          'Tipo de voto não informado.'
        );

      //
      // id_chapa é obrigatório somente para CHAPA
      //
      IdChapa := 0;

      if Body.GetValue('id_chapa') <> nil then
        IdChapa :=
          Body.GetValue<Integer>(
            'id_chapa',
            0
          );

      //
      // 5. Registrar voto
      //
      Resultado := TEleicaoVotacaoAPIService.RegistrarVoto(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa,
          TipoVoto,
          IdChapa
        );

      //
      // 6. Retorno
      //
      Dados := TJSONObject.Create;

      Dados.AddPair('confirmado', Resultado.Confirmado);

      Dados.AddPair(
        'comprovante',
        Resultado.Comprovante
      );

      TAppResponse.Ok(
        Res,
        Dados,
        'Voto registrado com sucesso.'
      );

    except
      on E: Exception do
        TAppErrors.HandleException(
          Res,
          E
        );
    end;
  end
);


  {$ENDREGION}

end;

end.
