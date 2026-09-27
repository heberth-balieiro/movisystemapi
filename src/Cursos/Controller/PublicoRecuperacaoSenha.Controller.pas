unit PublicoRecuperacaoSenha.Controller;

interface

type
  TPublicoRecuperacaoSenhaController = class
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
  PublicoRecuperacaoSenha.DAO,
  PublicoRecuperacaoSenha.Service;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  Valor := AObj.GetValue(ANome);

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result := Valor.Value;
end;

function DadosParaJson(
  const ADados: TRecuperacaoSenhaDados
): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('nome', ADados.Nome);
  Result.AddPair(
    'email_mascarado',
    TPublicoRecuperacaoSenhaService.EmailMascarado(
      ADados.Email
    )
  );
  Result.AddPair('instituicao_nome', ADados.InstituicaoNome);
  Result.AddPair('instituicao_slug', ADados.InstituicaoSlug);
end;

class procedure TPublicoRecuperacaoSenhaController.Registry;
begin
  THorse.Post(
    '/v1/certifica/publico/recuperacao-senha/solicitar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Slug: string;
      Email: string;
      Retorno: TJSONObject;
    begin
      try
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Slug := JsonString(Body, 'slug');
          Email := JsonString(Body, 'email');
        finally
          Body.Free;
        end;

        TPublicoRecuperacaoSenhaService.Solicitar(
          Slug,
          Email
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair(
          'solicitado',
          TJSONBool.Create(True)
        );

        TAppResponse.Ok(
          Res,
          Retorno,
          'Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/publico/recuperacao-senha/validar',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Slug: string;
      Token: string;
      Dados: TRecuperacaoSenhaDados;
    begin
      try
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Slug := JsonString(Body, 'slug');
          Token := JsonString(Body, 'token');
        finally
          Body.Free;
        end;

        Dados :=
          TPublicoRecuperacaoSenhaService.Validar(
            Slug,
            Token
          );

        TAppResponse.Ok(
          Res,
          DadosParaJson(Dados),
          'Link de recuperação válido.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

  THorse.Post(
    '/v1/certifica/publico/recuperacao-senha/redefinir',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Slug: string;
      Token: string;
      Senha: string;
      Dados: TRecuperacaoSenhaDados;
    begin
      try
        JsonValue := TJSONObject.ParseJSONValue(Req.Body);

        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON inválido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Slug := JsonString(Body, 'slug');
          Token := JsonString(Body, 'token');
          Senha := JsonString(Body, 'senha');
        finally
          Body.Free;
        end;

        Dados :=
          TPublicoRecuperacaoSenhaService.Redefinir(
            Slug,
            Token,
            Senha
          );

        TAppResponse.Ok(
          Res,
          DadosParaJson(Dados),
          'Senha redefinida com sucesso.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
