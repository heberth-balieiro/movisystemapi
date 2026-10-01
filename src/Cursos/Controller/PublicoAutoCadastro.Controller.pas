unit PublicoAutoCadastro.Controller;

interface

type
  TPublicoAutoCadastroController = class
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
  PublicoAutoCadastro.Service;

function JsonString(const AObj: TJSONObject; const ANome: string): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  Valor := AObj.GetValue(ANome);
  if (Valor <> nil) and not (Valor is TJSONNull) then
    Result := Valor.Value;
end;

function JsonBoolean(const AObj: TJSONObject; const ANome: string): Boolean;
var
  Valor: TJSONValue;
begin
  Result := False;
  Valor := AObj.GetValue(ANome);
  if (Valor <> nil) and not (Valor is TJSONNull) then
    Result := SameText(Valor.Value, 'true');
end;

class procedure TPublicoAutoCadastroController.Registry;
begin
  THorse.Post(
    '/v1/certifica/publico/instituicoes/:slug/auto-cadastro',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      JsonValue: TJSONValue;
      Body: TJSONObject;
      Resultado: TPublicoAutoCadastroResultado;
      Retorno: TJSONObject;
      Slug, Nome, Cpf, Email, Telefone, Senha: string;
      AceiteTermos: Boolean;
    begin
      try
        Res.RawWebResponse.SetCustomHeader('Cache-Control', 'no-store');

        if not TAppRateLimit.EnforceIP(Req, Res, 'publico-auto-cadastro', 10, 600) then
          Exit;

        if Length(Req.Body) > 16384 then
          TAppErrors.RaiseBadRequest('Requisicao invalida.');

        Slug := LowerCase(Trim(Req.Params.Items['slug']));

        JsonValue := TJSONObject.ParseJSONValue(Req.Body);
        if not (JsonValue is TJSONObject) then
        begin
          JsonValue.Free;
          TAppErrors.RaiseBadRequest('JSON invalido.');
        end;

        Body := JsonValue as TJSONObject;
        try
          Nome := JsonString(Body, 'nome');
          Cpf := JsonString(Body, 'cpf');
          Email := JsonString(Body, 'email');
          Telefone := JsonString(Body, 'telefone');
          Senha := JsonString(Body, 'senha');
          AceiteTermos := JsonBoolean(Body, 'aceite_termos');
        finally
          Body.Free;
        end;

        if not TAppRateLimit.EnforceIdentity(
          Req,
          Res,
          'publico-auto-cadastro-email',
          Slug + '|' + LowerCase(Trim(Email)),
          5,
          600
        ) then
          Exit;

        Resultado := TPublicoAutoCadastroService.Cadastrar(
          Slug,
          Nome,
          Cpf,
          Email,
          Telefone,
          Senha,
          AceiteTermos
        );

        Retorno := TJSONObject.Create;
        Retorno.AddPair('id_participante', TJSONNumber.Create(Resultado.IdParticipante));
        Retorno.AddPair('email', Resultado.Email);

        TAppResponse.Ok(
          Res,
          Retorno,
          'Cadastro realizado com sucesso. Entre com seu acesso para continuar.'
        );
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
