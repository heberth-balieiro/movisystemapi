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
  System.Classes,
  App.Response,
  APP.Errors,
  EleicaoAPIPublic.Service,
  EleicaoPublicMedia.Service,
  APP.Classes,
  App.RequestInfo;

{ TEleicaoAPIPublicController }

class procedure TEleicaoAPIPublicController.Registry;
begin

  {$REGION 'Slug'}

  // Retorno leve: não transporta logo/banner em Base64 junto com os dados.
  THorse.Get('/api/v1/public/eleicao/:slug/leve',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Dados: TJSONObject;
    begin
      try
        Slug := Req.Params['slug'];
        Dados := TEleicaoPublicMediaService.BuscarEleicaoLeve(Slug);
        TAppResponse.Ok(Res, Dados);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end);

  // Mídia carregada separadamente e cacheável pelo navegador.
  THorse.Get('/api/v1/public/eleicao/:slug/midia/:tipo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Tipo: string;
      Bytes: TBytes;
      MimeType: string;
      Stream: TBytesStream;
    begin
      Stream := nil;
      try
        Slug := Req.Params['slug'];
        Tipo := Req.Params['tipo'];

        if not TEleicaoPublicMediaService.BuscarMidia(Slug, Tipo, Bytes, MimeType) then
          TAppErrors.RaiseNotFound('Mídia não encontrada.');

        Stream := TBytesStream.Create(Bytes);
        Res.AddHeader('Cache-Control', 'public, max-age=3600, stale-while-revalidate=86400');
        Res.SendFile(Stream, Tipo, MimeType);
      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
      Stream.Free;
    end);

  // Compatibilidade: rota legada permanece inalterada para outros consumidores.
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
