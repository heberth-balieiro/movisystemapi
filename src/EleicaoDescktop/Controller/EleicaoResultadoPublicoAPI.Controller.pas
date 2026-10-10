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
      QuestoesArray, OpcoesArray: TJSONArray;
      QuestaoJson, OpcaoJson: TJSONObject;
      Questao: TEleicaoResultadoPublicoQuestaoResult;
      Opcao: TEleicaoResultadoPublicoOpcaoResult;
    begin
      try
        Slug := Trim(Req.Params['slug']);

        if Slug.IsEmpty then
          TAppErrors.RaiseBadRequest('Eleicao nao informada.');

        Resultado := TEleicaoResultadoPublicoAPIService.BuscarResultado(Slug);

        try
          Dados := TJSONObject.Create;

          EleicaoJson := TJSONObject.Create;
          EleicaoJson.AddPair('id', TJSONNumber.Create(Resultado.IdEleicao));
          EleicaoJson.AddPair('nome', Resultado.NomeEleicao);
          EleicaoJson.AddPair('situacao', Resultado.Situacao);
          EleicaoJson.AddPair('operacao', Resultado.Operacao);
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

          QuestoesArray := TJSONArray.Create;
          for Questao in Resultado.Questoes do
          begin
            QuestaoJson := TJSONObject.Create;
            QuestaoJson.AddPair('id', TJSONNumber.Create(Questao.IdQuestao));
            QuestaoJson.AddPair('ordem', TJSONNumber.Create(Questao.Ordem));
            QuestaoJson.AddPair('titulo', Questao.Titulo);
            QuestaoJson.AddPair('total_votos', TJSONNumber.Create(Questao.TotalVotos));

            OpcoesArray := TJSONArray.Create;
            for Opcao in Questao.Opcoes do
            begin
              OpcaoJson := TJSONObject.Create;
              OpcaoJson.AddPair('id', TJSONNumber.Create(Opcao.IdOpcao));
              OpcaoJson.AddPair('ordem', TJSONNumber.Create(Opcao.Ordem));
              OpcaoJson.AddPair('descricao', Opcao.Descricao);
              OpcaoJson.AddPair('quantidade_votos', TJSONNumber.Create(Opcao.QuantidadeVotos));
              OpcaoJson.AddPair('percentual', TJSONNumber.Create(Opcao.Percentual));
              OpcoesArray.AddElement(OpcaoJson);
            end;

            QuestaoJson.AddPair('opcoes', OpcoesArray);
            QuestoesArray.AddElement(QuestaoJson);
          end;
          Dados.AddPair('questoes', QuestoesArray);

          TAppResponse.Ok(Res, Dados, '');
        finally
          Resultado.Chapas.Free;
          Resultado.Questoes.Free;
        end;

      except
        on E: Exception do
          TAppErrors.HandleException(Res, E);
      end;
    end
  );
end;

end.
