unit EleicaoEmailConfigAPI.Controller;

interface

type
  TEleicaoEmailConfigAPIController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Token,
  App.JWT,
  App.Response,
  APP.Errors,
  EleicaoEmailConfigAPI.Model,
  EleicaoEmailConfigAPI.Service,
  EleicaoEmail.Service;

function JsonString(const AObj: TJSONObject; const ANome: string;
  const ADefault: string = ''): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);
  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;
  Result := Valor.Value;
end;

function JsonBoolean(const AObj: TJSONObject; const ANome: string;
  const ADefault: Boolean = False): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);
  if (Valor = nil) or (Valor is TJSONNull) then
    Exit;
  Result := SameText(Valor.Value, 'true') or SameText(Valor.Value, '1');
end;

function AutorizarAdmin(const Req: THorseRequest; const Res: THorseResponse;
  out AClaims: TJWTClaims; out ASlug: string): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(Req, Res, AClaims) then
    Exit;

  ASlug := Trim(Req.Params['slug']);
  if ASlug.IsEmpty then
    TAppErrors.RaiseBadRequest('Eleição não informada.');

  if not TAppToken.PodeAdministrarEleicao(AClaims.Roles) then
    TAppErrors.RaiseUnauthorized('Usuário não autorizado.');

  if not TAppToken.PertenceEleicao(AClaims, ASlug) then
    TAppErrors.RaiseUnauthorized('Token não pertence a esta eleição.');

  if AClaims.IdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa não identificada.');

  Result := True;
end;

class procedure TEleicaoEmailConfigAPIController.Registry;
begin
  THorse.Get(
    '/api/v1/eleicao/:slug/admin/email-config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Config: TEleicaoEmailConfig;
    begin
      try
        if not AutorizarAdmin(Req, Res, Claims, Slug) then
          Exit;

        Config := TEleicaoEmailConfigService.Buscar(Claims.IdEmpresa);
        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração de e-mail carregada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/api/v1/eleicao/:slug/admin/email-config',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Body: TJSONObject;
      Dados: TEleicaoEmailInput;
      Config: TEleicaoEmailConfig;
    begin
      try
        if not AutorizarAdmin(Req, Res, Claims, Slug) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Dados := Default(TEleicaoEmailInput);
        Dados.Ativo := JsonBoolean(Body, 'ativo', False);
        Dados.SmtpHost := JsonString(Body, 'smtp_host');
        Dados.SmtpPorta := StrToIntDef(JsonString(Body, 'smtp_porta', '587'), 587);
        Dados.Seguranca := JsonString(Body, 'seguranca', 'STARTTLS');
        Dados.Usuario := JsonString(Body, 'usuario');
        Dados.Senha := JsonString(Body, 'senha');
        Dados.RemetenteNome := JsonString(Body, 'remetente_nome');
        Dados.RemetenteEmail := JsonString(Body, 'remetente_email');
        Dados.ResponderPara := JsonString(Body, 'responder_para');

        Config := TEleicaoEmailConfigService.Atualizar(Claims.IdEmpresa, Dados);
        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração de e-mail atualizada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/api/v1/eleicao/:slug/admin/email-config/teste',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Slug: string;
      Body: TJSONObject;
      Destinatario: string;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarAdmin(Req, Res, Claims, Slug) then
          Exit;

        Body := Req.Body<TJSONObject>;
        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Destinatario := LowerCase(Trim(JsonString(Body, 'destinatario')));
        if Destinatario.IsEmpty then
          TAppErrors.RaiseBadRequest('Informe o destinatário do teste.');

        TEleicaoEmailService.EnviarTeste(Claims.IdEmpresa, Destinatario);

        Dados := TJSONObject.Create;
        Dados.AddPair('enviado', TJSONBool.Create(True));
        Dados.AddPair('destinatario', Destinatario);
        TAppResponse.Ok(Res, Dados, 'E-mail de teste enviado com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
