unit PublicoPrimeiroAcesso.Controller;

interface

type
  TPublicoPrimeiroAcessoController = class
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
  App.RateLimit,
  PublicoPrimeiroAcesso.DAO,
  PublicoPrimeiroAcesso.Service;

function JsonString(
  const AObj: TJSONObject;
  const ANome: string
): string;
var
  Valor: TJSONValue;
begin
  Result := '';

  Valor :=
    AObj.GetValue(
      ANome
    );

  if (Valor = nil) or
     (Valor is TJSONNull) then
    Exit;

  Result :=
    Valor.Value;
end;

function DadosParaJson(
  const ADados: TPrimeiroAcessoDados
): TJSONObject;
begin
  Result := TJSONObject.Create;

  Result.AddPair(
    'nome',
    ADados.Nome
  );

  Result.AddPair(
    'email',
    ADados.Email
  );

  Result.AddPair(
    'instituicao_nome',
    ADados.InstituicaoNome
  );

  Result.AddPair(
    'instituicao_slug',
    ADados.InstituicaoSlug
  );
end;

class procedure TPublicoPrimeiroAcessoController.Registry;
begin

  THorse.Post(
    '/v1/certifica/publico/primeiro-acesso/validar',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Slug: string;
      Token: string;
      Dados: TPrimeiroAcessoDados;
    begin
      try
        Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

        if not TAppRateLimit.EnforceIP(Req, Res, 'primeiro-acesso-validar', 30, 300) then
          Exit;

        if Length(Req.Body) > 8192 then
          TAppErrors.RaiseBadRequest('Requisição inválida.');

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
          Slug :=
            JsonString(
              Body,
              'slug'
            );

          Token :=
            JsonString(
              Body,
              'token'
            );
        finally
          Body.Free;
        end;

        if not TAppRateLimit.EnforceIdentity(Req, Res, 'primeiro-acesso-token-validar', Token, 10, 300) then
          Exit;

        Dados :=
          TPublicoPrimeiroAcessoService.Validar(
            Slug,
            Token
          );

        TAppResponse.Ok(
          Res,
          DadosParaJson(Dados),
          'Link de primeiro acesso válido.'
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


  THorse.Post(
    '/v1/certifica/publico/primeiro-acesso/definir-senha',

    procedure(
      Req: THorseRequest;
      Res: THorseResponse;
      Next: TProc
    )
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Slug: string;
      Token: string;
      Senha: string;
      Dados: TPrimeiroAcessoDados;
    begin
      try
        Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

        if not TAppRateLimit.EnforceIP(Req, Res, 'primeiro-acesso-definir-senha', 10, 600) then
          Exit;

        if Length(Req.Body) > 8192 then
          TAppErrors.RaiseBadRequest('Requisição inválida.');

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
          Slug :=
            JsonString(
              Body,
              'slug'
            );

          Token :=
            JsonString(
              Body,
              'token'
            );

          Senha :=
            JsonString(
              Body,
              'senha'
            );
        finally
          Body.Free;
        end;

        if not TAppRateLimit.EnforceIdentity(Req, Res, 'primeiro-acesso-token-definir', Token, 5, 600) then
          Exit;

        Dados :=
          TPublicoPrimeiroAcessoService.DefinirSenha(
            Slug,
            Token,
            Senha
          );

        TAppResponse.Ok(
          Res,
          DadosParaJson(Dados),
          'Senha criada com sucesso.'
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

end;

end.
