unit InstituicaoConfiguracao.Controller;

interface

type
  TInstituicaoConfiguracaoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.Classes,
  System.JSON,
  App.JWT,
  App.Token,
  App.Response,
  APP.Errors,
  InstituicaoConfiguracao.Model,
  InstituicaoConfiguracao.Service,
  InstituicaoEmail.Service;

function AutorizarInstituicao(
  const Req: THorseRequest;
  const Res: THorseResponse;
  out AClaims: TJWTClaims
): Boolean;
begin
  Result := False;

  if not TAppToken.ValidarToken(
    Req,
    Res,
    AClaims
  ) then
    Exit;

  if AClaims.IdInstituicao <= 0 then
  begin
    TAppResponse.Forbidden(
      Res,
      'Token sem contexto de instituição.'
    );
    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: string = ''
): string;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function JsonBoolean(
  const AObj: TJSONObject;
  const ANome: string;
  const ADefault: Boolean = False
): Boolean;
var
  Valor: TJSONValue;
begin
  Result := ADefault;
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := SameText(
    Valor.Value,
    'true'
  );
end;

function BaseUrl(
  const Req: THorseRequest
): string;
var
  Proto: string;
  Host: string;
begin
  Proto := Trim(
    Req.Headers['X-Forwarded-Proto']
  );

  Host := Trim(
    Req.Headers['X-Forwarded-Host']
  );

  if Proto.IsEmpty then
    Proto := 'http';

  if Host.IsEmpty then
    Host := Trim(
      Req.Headers['Host']
    );

  if Host.IsEmpty then
    TAppErrors.RaiseBadRequest(
      'Não foi possível identificar o host da API.'
    );

  Result :=
    Proto +
    '://' +
    Host;
end;

class procedure TInstituicaoConfiguracaoController.Registry;
begin
  {$REGION 'Atualizar Instituição'}

  THorse.Put(
    '/v1/certifica/configuracoes/instituicao',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoDadosInput;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoDadosInput
            );

          Dados.Nome :=
            JsonString(
              Body,
              'nome'
            );

          Dados.RazaoSocial :=
            JsonString(
              Body,
              'razao_social'
            );

          Dados.Cnpj :=
            JsonString(
              Body,
              'cnpj'
            );

          Dados.Descricao :=
            JsonString(
              Body,
              'descricao'
            );

          Dados.Email :=
            JsonString(
              Body,
              'email'
            );

          Dados.Telefone :=
            JsonString(
              Body,
              'telefone'
            );

          Dados.Site :=
            JsonString(
              Body,
              'site'
            );
        finally
          Body.Free;
        end;

        Retorno :=
          TInstituicaoConfiguracaoService.AtualizarInstituicao(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Dados da instituição atualizados com sucesso.'
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

  {$REGION 'Upload Logo'}

  THorse.Post(
    '/v1/certifica/configuracoes/instituicao/logo',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Stream: TStream;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        if Req.ContentFields.Field('arquivo') = nil then
          TAppErrors.RaiseBadRequest(
            'Arquivo não informado.'
          );

        Stream :=
          Req.ContentFields
             .Field('arquivo')
             .AsStream;

        if Stream = nil then
          TAppErrors.RaiseBadRequest(
            'Arquivo inválido.'
          );

        Retorno :=
          TInstituicaoConfiguracaoService.SalvarMidia(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            'logo',
            BaseUrl(Req),
            Stream
          );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Logo atualizado com sucesso.'
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

  {$REGION 'Upload Banner'}

  THorse.Post(
    '/v1/certifica/configuracoes/instituicao/banner',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Stream: TStream;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        if Req.ContentFields.Field('arquivo') = nil then
          TAppErrors.RaiseBadRequest(
            'Arquivo não informado.'
          );

        Stream :=
          Req.ContentFields
             .Field('arquivo')
             .AsStream;

        if Stream = nil then
          TAppErrors.RaiseBadRequest(
            'Arquivo inválido.'
          );

        Retorno :=
          TInstituicaoConfiguracaoService.SalvarMidia(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            'banner',
            BaseUrl(Req),
            Stream
          );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Banner atualizado com sucesso.'
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


  {$REGION 'Auto cadastro de participantes'}

  THorse.Get(
    '/v1/certifica/configuracoes/auto-cadastro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Config: TInstituicaoAutoCadastroConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        Config := TInstituicaoConfiguracaoService.BuscarAutoCadastro(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração de auto cadastro carregada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/configuracoes/auto-cadastro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoAutoCadastroInput;
      Config: TInstituicaoAutoCadastroConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoAutoCadastroInput);
          Dados.PermitirAutoCadastro :=
            JsonBoolean(Body, 'permitir_auto_cadastro', False);
        finally
          Body.Free;
        end;

        Config := TInstituicaoConfiguracaoService.AtualizarAutoCadastro(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Dados
        );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração de auto cadastro atualizada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Configuração de E-mail'}

  THorse.Get(
    '/v1/certifica/configuracoes/email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Config: TInstituicaoEmailConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(Res, 'Token sem vínculo de usuário com a instituição.');
          Exit;
        end;

        Config := TInstituicaoConfiguracaoService.BuscarEmail(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao
        );

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
    '/v1/certifica/configuracoes/email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoEmailInput;
      Config: TInstituicaoEmailConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(Res, 'Token sem vínculo de usuário com a instituição.');
          Exit;
        end;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoEmailInput);
          Dados.Ativo := JsonBoolean(Body, 'ativo', False);
          Dados.SmtpHost := JsonString(Body, 'smtp_host');
          Dados.SmtpPorta := StrToIntDef(JsonString(Body, 'smtp_porta', '587'), 587);
          Dados.Seguranca := JsonString(Body, 'seguranca', 'STARTTLS');
          Dados.Usuario := JsonString(Body, 'usuario');
          Dados.Senha := JsonString(Body, 'senha');
          Dados.RemetenteNome := JsonString(Body, 'remetente_nome');
          Dados.RemetenteEmail := JsonString(Body, 'remetente_email');
          Dados.ResponderPara := JsonString(Body, 'responder_para');
        finally
          Body.Free;
        end;

        Config := TInstituicaoConfiguracaoService.AtualizarEmail(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Dados
        );

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
    '/v1/certifica/configuracoes/email/teste',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Destinatario: string;
      Retorno: TJSONObject;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Destinatario :=
            JsonString(
              Body,
              'destinatario'
            );
        finally
          Body.Free;
        end;

        TInstituicaoEmailService.EnviarTeste(
          Claims.IdInstituicao,
          Claims.IdUsuarioInstituicao,
          Destinatario
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair(
          'enviado',
          TJSONBool.Create(True)
        );
        Retorno.AddPair(
          'destinatario',
          LowerCase(Trim(Destinatario))
        );

        TAppResponse.Ok(
          Res,
          Retorno,
          'E-mail de teste enviado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}


  {$REGION 'Canais de Envio do Acesso'}

  THorse.Get(
    '/v1/certifica/configuracoes/envio-acesso',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Config: TInstituicaoAcessoEnvioConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        Config :=
          TInstituicaoConfiguracaoService.BuscarAcessoEnvio(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Canais de envio do acesso carregados com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/configuracoes/envio-acesso',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoAcessoEnvioInput;
      Config: TInstituicaoAcessoEnvioConfig;
    begin
      try
        if not AutorizarInstituicao(Req, Res, Claims) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Dados := Default(TInstituicaoAcessoEnvioInput);
          Dados.EnviarEmail := JsonBoolean(Body, 'enviar_email', False);
          Dados.EnviarWhatsApp := JsonBoolean(Body, 'enviar_whatsapp', False);
        finally
          Body.Free;
        end;

        Config :=
          TInstituicaoConfiguracaoService.AtualizarAcessoEnvio(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Canais de envio do acesso atualizados com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  {$ENDREGION}

  {$REGION 'Buscar Configuração WhatsApp'}

  THorse.Get(
    '/v1/certifica/configuracoes/whatsapp',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Config: TInstituicaoWhatsAppConfig;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        Config :=
          TInstituicaoConfiguracaoService.BuscarWhatsApp(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao
          );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Configuração do WhatsApp carregada com sucesso.'
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

  {$REGION 'Atualizar Configuração WhatsApp'}

  THorse.Put(
    '/v1/certifica/configuracoes/whatsapp',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Dados: TInstituicaoWhatsAppInput;
      Config: TInstituicaoWhatsAppConfig;
    begin
      try
        if not AutorizarInstituicao(
          Req,
          Res,
          Claims
        ) then
          Exit;

        if Claims.IdUsuarioInstituicao <= 0 then
        begin
          TAppResponse.Forbidden(
            Res,
            'Token sem vínculo de usuário com a instituição.'
          );
          Exit;
        end;

        JsonValue :=
          TJSONObject.ParseJSONValue(
            Req.Body
          );

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;

          TAppErrors.RaiseBadRequest(
            'JSON inválido.'
          );
        end;

        Body :=
          JsonValue as TJSONObject;

        try
          Dados :=
            Default(
              TInstituicaoWhatsAppInput
            );

          Dados.Ativo :=
            JsonBoolean(
              Body,
              'ativo',
              False
            );

          Dados.Url :=
            JsonString(
              Body,
              'url'
            );

          Dados.Token :=
            JsonString(
              Body,
              'token'
            );
        finally
          Body.Free;
        end;

        Config :=
          TInstituicaoConfiguracaoService.AtualizarWhatsApp(
            Claims.IdInstituicao,
            Claims.IdUsuarioInstituicao,
            Dados
          );

        TAppResponse.Ok(
          Res,
          Config.ToJSON,
          'Integração com WhatsApp atualizada com sucesso.'
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

  {$REGION 'Mídia Pública'}

  THorse.Get(
    '/v1/certifica/publico/midias/instituicoes/:id/:tipo/:arquivo',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      IdInstituicao: Int64;
      Caminho: string;
    begin
      try
        IdInstituicao :=
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          );

        if IdInstituicao <= 0 then
          TAppErrors.RaiseBadRequest(
            'Instituição inválida.'
          );

        Caminho :=
          TInstituicaoConfiguracaoService.ResolverMidiaPublica(
            IdInstituicao,
            Req.Params.Items['tipo'],
            Req.Params.Items['arquivo']
          );

        Res.SendFile(
          Caminho
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

