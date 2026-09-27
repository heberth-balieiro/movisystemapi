unit EleicaoAPIPublic.Controller;

interface

Uses System.Generics.Collections;

type
  TEleicaoAPIPublicController = class
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
  EleicaoAPIPublic.Service,
  APP.Classes,
  App.RequestInfo;

{ TEleicaoAPIPublicController }

class procedure TEleicaoAPIPublicController.Registry;
begin

  {$REGION 'Slug'}
  //Retornar uma eleicao
  THorse.Get('/api/v1/public/eleicao/:slug',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Dados: TJSONObject;
    begin
      try
        Slug    := Req.Params['slug'];
        Dados := TEleicaoAPIPublicService.BuscarEleicaoPorSlug(Slug);

        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

  {$REGION 'Login'}

  THorse.Post('/api/v1/public/eleicao/:slug/login',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Body: TJSONObject;
      CPF: string;
      Matricula: string;
      Login: TLoginResult;
      Dados: TJSONObject;
      Slug: string;
    begin
      try
        Body := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('JSON inválido ou não informado.');

        Slug        := Req.Params['slug'];
        CPF         := TAppClasses.GetJsonString(Body, 'cpf');
        Matricula   := TAppClasses.GetJsonString(Body, 'matricula');

        Login       := TEleicaoAPIPublicService.Login(Slug, CPF, Matricula,
                      TAppRequestInfo.GetIP(Req),TAppRequestInfo.GetUserAgent(Req));

        Dados                       := TJSONObject.Create;
        //Dados.AddPair('IdUsuario',    TJSONNumber.Create(Login.IdUsuario));
        //Dados.AddPair('IdEmpresa',    TJSONNumber.Create(Login.IdEmpresa));
        Dados.AddPair('token_identificacao',      Login.Token);
        Dados.AddPair('identificado',             Login.identificado);
        Dados.AddPair('nome',                     Login.nome);
        TAppResponse.Ok(Res, Dados, 'Identificação realizada com sucesso.');
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  {$ENDREGION}

end;

end.
