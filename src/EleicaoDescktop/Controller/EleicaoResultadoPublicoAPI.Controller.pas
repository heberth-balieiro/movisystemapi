unit EleicaoResultadoPublicoAPI.Controller;

interface

type
  TEleicaoResultadoPublicoAPIController = class
  public
    class procedure Registry;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  App.Errors,
  App.Response,
  EleicaoResultadoPublicoAPI.Service;

class procedure TEleicaoResultadoPublicoAPIController.Registry;
begin

  THorse.Get('/api/v1/public/eleicao/:slug/resultado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      Slug: string;
      Resultado: TEleicaoResultadoPublicoResult;
      Dados, EleicaoJson, ResumoJson, ChapaJson: TJSONObject;
      ChapasArray: TJSONArray;
      Item: TEleicaoResultadoPublicoChapaResult;
    begin
      try
        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleição não informada.');

        Resultado := TEleicaoResultadoPublicoAPIService.BuscarResultado(Slug);

        try
          Dados := TJSONObject.Create;

          EleicaoJson := TJSONObject.Create;
          EleicaoJson.AddPair('id', TJSONNumber.Create(Resultado.IdEleicao));
          EleicaoJson.AddPair('nome', Resultado.NomeEleicao);
          EleicaoJson.AddPair('situacao', Resultado.Situacao);
          Dados.AddPair('eleicao', EleicaoJson);

          ResumoJson := TJSONObject.Create;
          ResumoJson.AddPair('total_votos', TJSONNumber.Create(Resultado.TotalVotos));
          ResumoJson.AddPair('votos_validos', TJSONNumber.Create(Resultado.VotosValidos));
          ResumoJson.AddPair('votos_brancos', TJSONNumber.Create(Resultado.VotosBrancos));
          ResumoJson.AddPair('votos_nulos', TJSONNumber.Create(Resultado.VotosNulos));
          Dados.AddPair('resumo', ResumoJson);

          ChapasArray := TJSONArray.Create;

          for Item in Resultado.Chapas do
          begin
            ChapaJson := TJSONObject.Create;
            ChapaJson.AddPair('id', TJSONNumber.Create(Item.IdChapa));
            ChapaJson.AddPair('numero', TJSONNumber.Create(Item.Numero));
            ChapaJson.AddPair('nome', Item.Nome);
            ChapaJson.AddPair('quantidade_votos', TJSONNumber.Create(Item.QuantidadeVotos));
            ChapaJson.AddPair('percentual', TJSONNumber.Create(Item.Percentual));
            ChapasArray.AddElement(ChapaJson);
          end;

          Dados.AddPair('chapas', ChapasArray);

          TAppResponse.Ok(Res, Dados, '');

        finally
          Resultado.Chapas.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );

end;

end.
