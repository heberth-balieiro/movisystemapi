
{
  "email": "heberthbalieiro@hotmail.com",
  "senha": "123456"
}

{
  "erro": false,
  "mensagem": "Login realizado com sucesso.",
  "dados": {
    "token": "eyJ...",
    "nome": "Administrador"
  }

unit EleicaoAdminAPI.Controller;

interface

type
  TEleicaoAdminAPIController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Classes,
  App.Errors,
  App.Response,
  App.Token,
  App.JWT,
  EleicaoAdminAPI.Service,
  EleicaoAuditoriaAPI.Service,
  EleicaoAuditoriaAPI.Dao,
  App.RequestInfo;

{ TEleicaoAdminAPIController }

class procedure TEleicaoAdminAPIController.Registry;
begin

  {$REGION 'LOGIN ADMIN'}
  //login do adm
  THorse.Post(
    '/api/v1/eleicao/:slug/admin/login',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug      : string;
      email     : string;
      Senha     : string;
      Body      : TJSONObject;
      Resultado : TEleicaoAdminLoginResult;
      Dados     : TJSONObject;
    begin
      try
        Slug    := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('Dados de acesso não informados.');

        email       := Trim(TAppClasses.GetJsonString(Body,'email'));
        Senha       := TAppClasses.GetJsonString(Body,'senha');

        Resultado   := TEleicaoAdminAPIService.Login(Slug, email, Senha);
        Dados       := TJSONObject.Create;

        Dados.AddPair('token',  Resultado.Token);
        Dados.AddPair('nome',   Resultado.Nome);

        TAppResponse.Ok(Res,Dados,'Login realizado com sucesso.');

      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'PAINEL ADMIN'}
  //buscar dados do painel
  THorse.Get(
    '/api/v1/eleicao/:slug/admin/painel',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims      : TJWTClaims;
      Slug        : string;
      Resultado   : TEleicaoAdminPainelResult;

      Dados       : TJSONObject;
      EleicaoJson : TJSONObject;
      ResumoJson  : TJSONObject;

      EvolucaoArray : TJSONArray;
      EvolucaoJson  : TJSONObject;

      Item : TEleicaoAdminPainelEvolucao;
    begin
      try
        // Validar token
        if not TAppToken.ValidarToken(Req,Res,Claims) then
          Exit;

        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Resultado   := TEleicaoAdminAPIService.BuscarPainel(Slug, Claims.UserId, Claims.IdEmpresa);

        try
          Dados       := TJSONObject.Create;
          // Eleição
          EleicaoJson := TJSONObject.Create;

          EleicaoJson.AddPair('id',       TJSONNumber.Create(Resultado.IdEleicao));
          EleicaoJson.AddPair('nome',     Resultado.NomeEleicao);
          EleicaoJson.AddPair('situacao', Resultado.Situacao);
          EleicaoJson.AddPair('data_hora_inicio', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Resultado.DataHoraInicio));
          EleicaoJson.AddPair('data_hora_fim',    FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Resultado.DataHoraFim));
          EleicaoJson.AddPair('abertura',         Resultado.abertura);
          EleicaoJson.AddPair('encerramento',     Resultado.encerramento);
          Dados.AddPair('eleicao',        EleicaoJson);

          // Resumo
          ResumoJson      := TJSONObject.Create;
          ResumoJson.AddPair('total_eleitores', TJSONNumber.Create(Resultado.Resumo.TotalEleitores));
          ResumoJson.AddPair('total_votantes',  TJSONNumber.Create(Resultado.Resumo.TotalVotantes));
          ResumoJson.AddPair('total_nao_votantes',TJSONNumber.Create(Resultado.Resumo.TotalNaoVotantes));
          ResumoJson.AddPair('percentual_participacao',TJSONNumber.Create(Resultado.Resumo.PercentualParticipacao));
          Dados.AddPair('resumo',ResumoJson);

          // Evolução
          EvolucaoArray := TJSONArray.Create;

          for Item in Resultado.Evolucao do
          begin
            EvolucaoJson := TJSONObject.Create;
            EvolucaoJson.AddPair('hora', Item.Hora);
            EvolucaoJson.AddPair('quantidade',TJSONNumber.Create(Item.Quantidade));
            EvolucaoJson.AddPair('acumulado',TJSONNumber.Create(Item.Acumulado));
            EvolucaoArray.AddElement(EvolucaoJson);
          end;

          Dados.AddPair('evolucao', EvolucaoArray);

          TAppResponse.Ok(Res,Dados,'');

        finally
          Resultado.Evolucao.Free;
        end;

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

  {$REGION 'ENCERRAR'}

  THorse.Post('/api/v1/eleicao/:slug/admin/encerrar',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug: string;
    Dados: TJSONObject;
  begin
    try
      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;



      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
      if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

      TEleicaoAdminAPIService.EncerrarEleicao(Slug, Claims.UserId, Claims.IdEmpresa,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

      Dados := TJSONObject.Create;
      Dados.AddPair('situacao', 'ENCERRADA');

      TAppResponse.Ok(Res, Dados, 'Eleição encerrada com sucesso.');

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'APURACAO'}

  THorse.Post('/api/v1/eleicao/:slug/admin/iniciar-apuracao',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug: string;
    Dados: TJSONObject;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');



      TEleicaoAdminAPIService.IniciarApuracao(Slug, Claims.UserId, Claims.IdEmpresa,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

      Dados := TJSONObject.Create;
      Dados.AddPair('situacao', 'EM_APURACAO');

      TAppResponse.Ok(Res, Dados, 'Apuração iniciada com sucesso.');

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'FINALIZAR APURACAO'}

  THorse.Post('/api/v1/eleicao/:slug/admin/finalizar-apuracao',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug: string;
    Dados: TJSONObject;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
      if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');



      TEleicaoAdminAPIService.FinalizarApuracao(Slug, Claims.UserId, Claims.IdEmpresa,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

      Dados := TJSONObject.Create;
      Dados.AddPair('situacao', 'APURADA');

      TAppResponse.Ok(Res, Dados, 'Apuração finalizada com sucesso.');

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'RESULTADO'}

  THorse.Get('/api/v1/eleicao/:slug/admin/resultado',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug: string;
    Resultado: TEleicaoAdminResultadoResult;
    Dados, EleicaoJson, ResumoJson, ChapaJson: TJSONObject;
    ChapasArray: TJSONArray;
    Item: TEleicaoAdminResultadoChapaResult;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');



      Resultado := TEleicaoAdminAPIService.BuscarResultado(Slug, Claims.UserId, Claims.IdEmpresa);

      try
        Dados := TJSONObject.Create;

        EleicaoJson := TJSONObject.Create;
        EleicaoJson.AddPair('id', TJSONNumber.Create(Resultado.IdEleicao));
        EleicaoJson.AddPair('nome', Resultado.NomeEleicao);
        EleicaoJson.AddPair('situacao', Resultado.Situacao);
        Dados.AddPair('eleicao', EleicaoJson);

        ResumoJson := TJSONObject.Create;
        ResumoJson.AddPair('total_votos', TJSONNumber.Create(Resultado.TotalVotos));
        ResumoJson.AddPair('votos_validos', TJSONNumber.Create(Resultado.VotosValidos));
        ResumoJson.AddPair('votos_brancos', TJSONNumber.Create(Resultado.VotosBrancos));
        ResumoJson.AddPair('votos_nulos', TJSONNumber.Create(Resultado.VotosNulos));
        Dados.AddPair('resumo', ResumoJson);

        ChapasArray := TJSONArray.Create;

        for Item in Resultado.Chapas do
        begin
          ChapaJson := TJSONObject.Create;
          ChapaJson.AddPair('id', TJSONNumber.Create(Item.IdChapa));
          ChapaJson.AddPair('numero', TJSONNumber.Create(Item.Numero));
          ChapaJson.AddPair('nome', Item.Nome);
          ChapaJson.AddPair('quantidade_votos', TJSONNumber.Create(Item.QuantidadeVotos));
          ChapaJson.AddPair('percentual', TJSONNumber.Create(Item.Percentual));

          ChapasArray.AddElement(ChapaJson);
        end;

        Dados.AddPair('chapas', ChapasArray);

        TAppResponse.Ok(Res, Dados, '');

      finally
        Resultado.Chapas.Free;
      end;

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'Publicar Resultado'}

  THorse.Post('/api/v1/eleicao/:slug/admin/publicar-resultado',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug: string;
    Dados: TJSONObject;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Slug := Trim(Req.Params['slug']);

      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
      if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

      TEleicaoAdminAPIService.PublicarResultado(Slug, Claims.UserId, Claims.IdEmpresa,TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

      Dados := TJSONObject.Create;
      Dados.AddPair('situacao', 'PUBLICADA');

      TAppResponse.Ok(Res, Dados, 'Resultado publicado com sucesso.');

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}

  {$REGION 'Auditoria'}

  THorse.Get('/api/v1/eleicao/:slug/admin/auditoria',
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  var
    Claims: TJWTClaims;
    Slug, TipoEvento, Origem, Sucesso, DataInicial, DataFinal: string;
    Lista: TEleicaoAuditoriaLista;
    Dados: TJSONArray;
    ItemJson: TJSONObject;
    Item: TEleicaoAuditoriaItem;
  begin
    try
      if not TAppToken.ValidarToken(Req, Res, Claims) then
        Exit;

      Slug        := Trim(Req.Params['slug']);
      TipoEvento  := Trim(Req.Query['tipo_evento']);
      Origem      := Trim(Req.Query['origem']);
      Sucesso     := Trim(Req.Query['sucesso']);
      DataInicial := Trim(Req.Query['data_inicial']);
      DataFinal   := Trim(Req.Query['data_final']);


      if Slug.IsEmpty then
        TAppErrors.RaiseBadRequest('Eleição não informada.');

      if not TAppToken.PossuiRole(Claims.Roles, 'ADMIN') then
        TAppErrors.RaiseUnauthorized('Usuário não autorizado.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

      Lista := TEleicaoAuditoriaAPIService.BuscarAuditoria(Slug, Claims.UserId, Claims.IdEmpresa,
                TipoEvento,
                Origem,
                Sucesso,
                DataInicial,
                DataFinal);

      try
        Dados := TJSONArray.Create;

        for Item in Lista do
        begin
          ItemJson := TJSONObject.Create;

          ItemJson.AddPair('id', TJSONNumber.Create(Item.Id));
          ItemJson.AddPair('tipo_evento', Item.TipoEvento);
          ItemJson.AddPair('origem', Item.Origem);
          ItemJson.AddPair('sucesso', Item.Sucesso);
          ItemJson.AddPair('descricao', Item.Descricao);
          ItemJson.AddPair('ip', Item.IP);
          ItemJson.AddPair('user_agent', Item.UserAgent);
          ItemJson.AddPair('criado_em', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Item.CriadoEm));

          if Item.UsuarioId > 0 then
            ItemJson.AddPair('usuario_id', TJSONNumber.Create(Item.UsuarioId))
          else
            ItemJson.AddPair('usuario_id', TJSONNull.Create);

          Dados.AddElement(ItemJson);
        end;

        TAppResponse.Ok(Res, Dados, '');

      finally
        Lista.Free;
      end;

    except
      on E: Exception do
        TAppErrors.HandleException(Res, E);
    end;
  end
);

  {$ENDREGION}


end;

end.
