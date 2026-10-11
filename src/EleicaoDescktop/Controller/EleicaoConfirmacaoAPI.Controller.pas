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
  Uni,
  App.Response,
  APP.Errors,
  App.JWT,
  App.Token,
  App.Config,
  Database.Connection,
  EleicaoAPIPublic,
  EleicaoAPIPublic.Service,
  EleicaoEmailContingencia.Service,
  EleicaoCodigoTemporarioAPI.Service,
  EleicaoMelhoriasAPI.Service,
  APP.Classes,
  App.RequestInfo;

function SomenteNumeros(const AValor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in AValor do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

function MascararWhatsapp(const AWhatsapp: string): string;
var
  Numero: string;
begin
  Numero := SomenteNumeros(AWhatsapp);
  if Length(Numero) < 4 then
    Exit('WhatsApp cadastrado');

  Result := '(**) *****-' + Copy(Numero, Length(Numero) - 3, 4);
end;

function ConsultarWhatsappCanal(const ASlug: string; const AIdUsuario,
  AIdEmpresa: Integer; out ADestinoMascarado: string): Boolean;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Contexto: TEleicaoConfirmacaoContexto;
begin
  Result := False;
  ADestinoMascarado := '';

  if Trim(ASlug).IsEmpty or (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn, Trim(ASlug), AIdEmpresa, AIdUsuario, Contexto
    ) then
      Exit;

    if SomenteNumeros(Contexto.Whatsapp).IsEmpty then
      Exit;

    ADestinoMascarado := MascararWhatsapp(Contexto.Whatsapp);
    Result := True;
  finally
    Conn.Free;
  end;
end;

procedure PrepararNovaConfirmacaoWhatsapp(const ASlug: string;
  const AIdUsuario, AIdEmpresa: Integer);
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Qry: TUniQuery;
  Contexto: TEleicaoConfirmacaoContexto;
  Confirmacao: TEleicaoConfirmacao;
begin
  if Trim(ASlug).IsEmpty or (AIdUsuario <= 0) or (AIdEmpresa <= 0) then
    Exit;

  Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Conn := TDatabaseConnection.NewConnection(Config.Database);
  try
    if not TEleicaoAPIPublicDao.BuscarContextoConfirmacao(
      Conn, Trim(ASlug), AIdEmpresa, AIdUsuario, Contexto
    ) then
      Exit;

    if not TEleicaoAPIPublicDao.BuscarConfirmacao(
      Conn, Contexto.IdEleicao, Contexto.IdUsuario, Confirmacao
    ) then
      Exit;

    // Nova identificação: permite escolher WhatsApp novamente mesmo quando
    // uma confirmação anterior já foi concluída. O novo código substituirá
    // o hash anterior no fluxo normal do serviço.
    if not SameText(Trim(Confirmacao.Confirmado), 'S') then
      Exit;

    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.SQL.Text :=
        'UPDATE eleicao_confirmacao SET ' +
        'confirmado = ''N'', confirmado_em = NULL, ' +
        'tentativas = 0, enviado_em = NULL, expira_em = NULL ' +
        'WHERE id = :id';
      Qry.ParamByName('id').AsLargeInt := Confirmacao.Id;
      Qry.ExecSQL;
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

{ TEleicaoAPIConfirmacaoController }

class procedure TEleicaoAPIConfirmacaoController.Registry;
begin

  {$REGION 'Confirmação'}

  THorse.Get('/api/v1/public/eleicao/:slug/confirmacao/canais',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Contingencia: TEleicaoEmailContingenciaInfo;
      Retorno: TJSONObject;
      WhatsappDisponivel: Boolean;
      WhatsappDestino: string;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Contingencia := TEleicaoEmailContingenciaService.Consultar(
          Slug, Claims.UserId, Claims.IdEmpresa
        );

        WhatsappDisponivel := ConsultarWhatsappCanal(
          Slug, Claims.UserId, Claims.IdEmpresa, WhatsappDestino
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('whatsapp_disponivel', TJSONBool.Create(WhatsappDisponivel));
        if WhatsappDisponivel then
          Retorno.AddPair('whatsapp_destino', WhatsappDestino)
        else
          Retorno.AddPair('whatsapp_destino', TJSONNull.Create);

        Retorno.AddPair('email_disponivel', TJSONBool.Create(Contingencia.Disponivel));
        if Contingencia.Disponivel then
          Retorno.AddPair('email_destino', Contingencia.DestinoMascarado)
        else
          Retorno.AddPair('email_destino', TJSONNull.Create);

        TAppResponse.Ok(Res, Retorno);
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post('/api/v1/public/eleicao/:slug/confirmacao/solicitar-codigo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims  : TJWTClaims;
      Slug    : string;
      Result  : TSolicitarCodigoResult;
      Contingencia: TEleicaoEmailContingenciaInfo;
      Retorno : TJSONObject;
      ExpiracaoAjustada: Integer;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        PrepararNovaConfirmacaoWhatsapp(Slug, Claims.UserId, Claims.IdEmpresa);

        Result := TEleicaoAPIPublicService.SolicitarCodigoConfirmacao(
          Slug, Claims.UserId, Claims.IdEmpresa,
          TAppRequestInfo.GetIP(Req), TAppRequestInfo.GetUserAgent(Req)
        );

        if (Result.ExpiraEmSegundos >= 60) and (Result.ReenviarEmSegundos >= 60) then
        begin
          ExpiracaoAjustada := TEleicaoMelhoriasAPIService.AjustarExpiracaoOTP(
            Slug, Claims.IdEmpresa, Claims.UserId
          );
          if ExpiracaoAjustada > 0 then Result.ExpiraEmSegundos := ExpiracaoAjustada;
        end;

        Contingencia := TEleicaoEmailContingenciaService.Consultar(
          Slug, Claims.UserId, Claims.IdEmpresa
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('enviado', Result.Enviado);
        Retorno.AddPair('destino', Result.Destino);
        Retorno.AddPair('canal', 'WHATSAPP');
        Retorno.AddPair('expira_em_segundos', TJSONNumber.Create(Result.ExpiraEmSegundos));
        Retorno.AddPair('reenviar_em_segundos', TJSONNumber.Create(Result.ReenviarEmSegundos));
        Retorno.AddPair('email_disponivel', TJSONBool.Create(Contingencia.Disponivel));
        if Contingencia.Disponivel then
          Retorno.AddPair('email_destino', Contingencia.DestinoMascarado)
        else
          Retorno.AddPair('email_destino', TJSONNull.Create);
        TAppResponse.Ok(Res, Retorno, 'Código de confirmação enviado.');
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/api/v1/public/eleicao/:slug/confirmacao/solicitar-codigo-email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Result: TEleicaoEmailContingenciaResult;
      Retorno: TJSONObject;
      ExpiracaoAjustada: Integer;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Result := TEleicaoEmailContingenciaService.SolicitarCodigo(
          Slug, Claims.UserId, Claims.IdEmpresa,
          TAppRequestInfo.GetIP(Req), TAppRequestInfo.GetUserAgent(Req)
        );

        ExpiracaoAjustada := TEleicaoMelhoriasAPIService.AjustarExpiracaoOTP(
          Slug, Claims.IdEmpresa, Claims.UserId
        );
        if ExpiracaoAjustada > 0 then Result.ExpiraEmSegundos := ExpiracaoAjustada;

        Retorno := TJSONObject.Create;
        Retorno.AddPair('enviado', Result.Enviado);
        Retorno.AddPair('destino', Result.Destino);
        Retorno.AddPair('canal', 'EMAIL');
        Retorno.AddPair('expira_em_segundos', TJSONNumber.Create(Result.ExpiraEmSegundos));
        Retorno.AddPair('reenviar_em_segundos', TJSONNumber.Create(Result.ReenviarEmSegundos));
        Retorno.AddPair('email_disponivel', TJSONBool.Create(True));
        Retorno.AddPair('email_destino', Result.Destino);
        TAppResponse.Ok(Res, Retorno, 'Código de confirmação enviado por e-mail.');
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end);

  THorse.Post('/api/v1/public/eleicao/:slug/confirmacao/validar-codigo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body    : TJSONObject;
      Claims  : TJWTClaims;
      Slug    : string;
      Codigo  : string;
      TokenTemporario: string;
      Result  : TValidarCodigoResult;
      Retorno : TJSONObject;
    begin
      try
        if not TAppToken.ValidarToken(Req, Res, Claims) then Exit;
        Slug := Trim(Req.Params['slug']);
        if Slug.IsEmpty then TAppErrors.RaiseBadRequest('Eleição não informada.');
        if not TAppToken.PossuiRole(Claims.Roles, 'ELEITOR_IDENTIFICADO') then
          TAppErrors.RaiseUnauthorized('Identificação inválida ou expirada.');
        if not TAppToken.PertenceEleicao(Claims, Slug) then
          TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

        Body := Req.Body<TJSONObject>;
        if Body = nil then TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');
        Codigo := Trim(TAppClasses.GetJsonString(Body,'codigo'));
        if Codigo.IsEmpty then TAppErrors.RaiseBadRequest('Informe o código de confirmação.');

        TokenTemporario := '';
        if TEleicaoCodigoTemporarioAPIService.Validar(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa,
          Codigo,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req),
          TokenTemporario
        ) then
        begin
          Retorno := TJSONObject.Create;
          Retorno.AddPair('confirmado','S');
          Retorno.AddPair('token_votacao',TokenTemporario);
          TAppResponse.Ok(Res,Retorno,'Código temporário confirmado com sucesso.');
          Exit;
        end;

        Result := TEleicaoAPIPublicService.ValidarCodigoConfirmacao(
          Slug,
          Claims.UserId,
          Claims.IdEmpresa,
          Codigo,
          TAppRequestInfo.GetIP(Req),
          TAppRequestInfo.GetUserAgent(Req)
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('confirmado', Result.Confirmado);
        Retorno.AddPair('token_votacao', Result.TokenVotacao);
        TAppResponse.Ok(Res, Retorno, 'Código confirmado com sucesso.');
      except
        on E: Exception do TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}
end;

end.
