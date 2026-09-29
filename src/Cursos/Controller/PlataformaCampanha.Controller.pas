unit PlataformaCampanha.Controller;

interface

type
  TPlataformaCampanhaController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  System.Classes,
  App.JWT,
  App.Token,
  App.RequestInfo,
  App.Response,
  APP.Errors,
  PlataformaCampanha.Service;

function AutorizarSuperAdmin(
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

  if not TAppToken.PossuiRole(
    AClaims.Roles,
    'SUPER_ADMIN'
  ) then
  begin
    TAppResponse.Forbidden(
      Res,
      'Sem permissão para administrar campanhas da plataforma.'
    );
    Exit;
  end;

  Result := True;
end;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  V: TJSONValue;
begin
  Result := '';
  V := AObj.GetValue(ANome);

  if (V <> nil) and
     not (V is TJSONNull) then
    Result := V.Value;
end;

class procedure TPlataformaCampanhaController.Registry;
begin
  THorse.Get(
    '/v1/certifica/plataforma/campanhas',
    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados :=
          TPlataformaCampanhaService.Listar(
            Req.Query.Items['busca'],
            Req.Query.Items['situacao'],
            Req.Query.Items['canal'],
            StrToIntDef(Req.Query.Items['page'], 1),
            StrToIntDef(Req.Query.Items['page_size'], 50)
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'Campanhas carregadas com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/plataforma/campanhas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados :=
          TPlataformaCampanhaService.Buscar(
            StrToInt64Def(
              Req.Params.Items['id'],
              0
            )
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'Campanha carregada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        if Length(Req.Body) > 1024 * 1024 then
          TAppErrors.RaiseBadRequest(
            'Conteúdo da campanha excede o limite permitido.'
          );

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          Dados :=
            TPlataformaCampanhaService.Salvar(
              Claims.UserId,
              0,
              JsonString(Body, 'nome'),
              JsonString(Body, 'canal'),
              JsonString(Body, 'assunto_email'),
              JsonString(Body, 'corpo_email'),
              JsonString(Body, 'mensagem_whatsapp'),
              TAppRequestInfo.GetIP(Req),
              TAppRequestInfo.GetUserAgent(Req)
            );
        finally
          Body.Free;
        end;

        TAppResponse.Created(
          Res,
          Dados,
          'Campanha criada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Put(
    '/v1/certifica/plataforma/campanhas/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          Dados :=
            TPlataformaCampanhaService.Salvar(
              Claims.UserId,
              StrToInt64Def(Req.Params.Items['id'], 0),
              JsonString(Body, 'nome'),
              JsonString(Body, 'canal'),
              JsonString(Body, 'assunto_email'),
              JsonString(Body, 'corpo_email'),
              JsonString(Body, 'mensagem_whatsapp'),
              TAppRequestInfo.GetIP(Req),
              TAppRequestInfo.GetUserAgent(Req)
            );
        finally
          Body.Free;
        end;

        TAppResponse.Ok(
          Res,
          Dados,
          'Campanha atualizada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/destinatarios',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          Dados :=
            TPlataformaCampanhaService.AdicionarDestinatario(
              StrToInt64Def(Req.Params.Items['id'], 0),
              JsonString(Body, 'nome'),
              JsonString(Body, 'email'),
              JsonString(Body, 'whatsapp'),
              JsonString(Body, 'empresa'),
              'MANUAL'
            );
        finally
          Body.Free;
        end;

        TAppResponse.Created(
          Res,
          Dados,
          'Destinatário adicionado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/importar-csv',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Stream: TStream;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        if Req.ContentFields.Field('arquivo') = nil then
          TAppErrors.RaiseBadRequest(
            'Arquivo CSV não informado.'
          );

        Stream :=
          Req.ContentFields
             .Field('arquivo')
             .AsStream;

        Dados :=
          TPlataformaCampanhaService.ImportarCSV(
            StrToInt64Def(Req.Params.Items['id'], 0),
            Stream
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'CSV processado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Delete(
    '/v1/certifica/plataforma/campanhas/:id/destinatarios/:id_destinatario',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        TPlataformaCampanhaService.ExcluirDestinatario(
          StrToInt64Def(Req.Params.Items['id'], 0),
          StrToInt64Def(Req.Params.Items['id_destinatario'], 0)
        );

        TAppResponse.NoContent(Res);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/anexos',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Stream: TStream;
      NomeArquivo: string;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        if Req.ContentFields.Field('arquivo') = nil then
          TAppErrors.RaiseBadRequest(
            'Anexo não informado.'
          );

        NomeArquivo :=
          Trim(
            Req.Query.Items['nome']
          );

        if NomeArquivo.IsEmpty then
          TAppErrors.RaiseBadRequest(
            'Informe o nome original do anexo.'
          );

        Stream :=
          Req.ContentFields
             .Field('arquivo')
             .AsStream;

        Dados :=
          TPlataformaCampanhaService.SalvarAnexo(
            StrToInt64Def(Req.Params.Items['id'], 0),
            NomeArquivo,
            Stream
          );

        TAppResponse.Created(
          Res,
          Dados,
          'Anexo adicionado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Delete(
    '/v1/certifica/plataforma/campanhas/:id/anexos/:id_anexo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        TPlataformaCampanhaService.ExcluirAnexo(
          StrToInt64Def(Req.Params.Items['id'], 0),
          StrToInt64Def(Req.Params.Items['id_anexo'], 0)
        );

        TAppResponse.NoContent(Res);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/iniciar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados :=
          TPlataformaCampanhaService.Iniciar(
            Claims.UserId,
            StrToInt64Def(Req.Params.Items['id'], 0),
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'Campanha iniciada. Os envios serão processados em fila.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/cancelar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados :=
          TPlataformaCampanhaService.Cancelar(
            Claims.UserId,
            StrToInt64Def(Req.Params.Items['id'], 0),
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'Campanha cancelada.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/:id/reprocessar-falhas',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados :=
          TPlataformaCampanhaService.ReprocessarFalhas(
            Claims.UserId,
            StrToInt64Def(Req.Params.Items['id'], 0),
            TAppRequestInfo.GetIP(Req),
            TAppRequestInfo.GetUserAgent(Req)
          );

        TAppResponse.Ok(
          Res,
          Dados,
          'Falhas reenfileiradas com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/testar-email',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          TPlataformaCampanhaService.EnviarEmailTeste(
            JsonString(Body, 'destinatario'),
            JsonString(Body, 'assunto'),
            JsonString(Body, 'corpo_email')
          );
        finally
          Body.Free;
        end;

        TAppResponse.Ok(
          Res,
          TJSONObject.Create,
          'E-mail de teste enviado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/testar-whatsapp',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          TPlataformaCampanhaService.EnviarWhatsAppTeste(
            JsonString(Body, 'numero'),
            JsonString(Body, 'mensagem')
          );
        finally
          Body.Free;
        end;

        TAppResponse.Ok(
          Res,
          TJSONObject.Create,
          'WhatsApp de teste enviado com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Get(
    '/v1/certifica/plataforma/campanhas/bloqueios',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Dados: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Dados := TJSONObject.Create;
        Dados.AddPair(
          'itens',
          TPlataformaCampanhaService.ListarBloqueios
        );

        TAppResponse.Ok(
          Res,
          Dados,
          'Lista de bloqueio carregada com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/plataforma/campanhas/bloqueios',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
      Raw: TJSONValue;
      Body: TJSONObject;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        Raw := TJSONObject.ParseJSONValue(Req.Body);
        if not (Raw is TJSONObject) then
        begin
          Raw.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := Raw as TJSONObject;
        try
          TPlataformaCampanhaService.AdicionarBloqueio(
            Claims.UserId,
            JsonString(Body, 'canal'),
            JsonString(Body, 'valor'),
            JsonString(Body, 'motivo')
          );
        finally
          Body.Free;
        end;

        TAppResponse.Created(
          Res,
          TJSONObject.Create,
          'Contato adicionado à lista de bloqueio.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Delete(
    '/v1/certifica/plataforma/campanhas/bloqueios/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Claims: TJWTClaims;
    begin
      try
        if not AutorizarSuperAdmin(Req, Res, Claims) then
          Exit;

        TPlataformaCampanhaService.ExcluirBloqueio(
          StrToInt64Def(
            Req.Params.Items['id'],
            0
          )
        );

        TAppResponse.NoContent(Res);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
