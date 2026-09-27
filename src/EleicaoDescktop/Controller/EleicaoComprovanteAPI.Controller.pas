unit EleicaoComprovanteAPI.Controller;

interface

type
  TEleicaoComprovanteAPIController = class
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
  EleicaoComprovanteAPI.Service;

{ TEleicaoComprovanteAPIController }

class procedure TEleicaoComprovanteAPIController.Registry;
begin
  THorse.Post('/api/v1/public/eleicao/:slug/comprovante/validar',

    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug        : string;
      Comprovante : string;
      Body        : TJSONObject;
      Resultado   : TValidarComprovanteResult;
      Dados       : TJSONObject;
    begin
      try
        // 1. Slug
        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        // 2. Body
        Body  := Req.Body<TJSONObject>;

        if Body = nil then
          TAppErrors.RaiseBadRequest('Dados não informados.');

        Comprovante := Trim(TAppClasses.GetJsonString(Body, 'comprovante'));

        if Comprovante.IsEmpty then
          TAppErrors.RaiseBadRequest('Comprovante não informado.');

        // 3. Validar comprovante
        Resultado := TEleicaoComprovanteAPIService.ValidarComprovante(Slug, Comprovante);

        // 4. Montar retorno
        Dados := TJSONObject.Create;

        Dados.AddPair('valido', Resultado.Valido);

        if Resultado.Valido = 'S' then
        begin
          Dados.AddPair('eleicao',Resultado.Eleicao);

          Dados.AddPair('registrado_em',FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',Resultado.RegistradoEm));
        end;

        // 5. Response
        TAppResponse.Ok(Res, Dados, '');

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
