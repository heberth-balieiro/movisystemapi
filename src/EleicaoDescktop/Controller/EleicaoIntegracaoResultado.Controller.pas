unit EleicaoIntegracaoResultado.Controller;

interface

type
  TEleicaoIntegracaoResultadoController = class
  public
    class procedure Registry; static;
  end;

implementation

uses
  Horse,
  System.SysUtils,
  System.JSON,
  EasyOneIntegracao.Service,
  EleicaoIntegracaoResultado.Service,
  App.Response,
  App.Errors;

class procedure TEleicaoIntegracaoResultadoController.Registry;
begin
  THorse.Get(
    '/v1/integracao/easyone/eleicoes/:id_eleicao_int/resultado',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UUID: string;
      APIKey: string;
      IdEleicaoInt: Integer;
      Contexto: TEasyOneIntegracaoContexto;
      Resultado: TEleicaoIntegracaoResultadoResult;
      Dados: TJSONObject;
      Resumo: TJSONObject;
      Chapas: TJSONArray;
      Chapa: TJSONObject;
      ItemChapa: TEleicaoIntegracaoResultadoChapaResult;
      Questoes: TJSONArray;
      QuestaoJson: TJSONObject;
      Questao: TEleicaoIntegracaoResultadoQuestaoResult;
      Opcoes: TJSONArray;
      OpcaoJson: TJSONObject;
      Opcao: TEleicaoIntegracaoResultadoOpcaoResult;
    begin
      try
        UUID := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);
        Contexto := TEasyOneIntegracaoService.Autenticar(UUID,APIKey);

        IdEleicaoInt := StrToIntDef(Trim(Req.Params['id_eleicao_int']),0);
        if IdEleicaoInt <= 0 then
          TAppErrors.RaiseBadRequest('ID da eleicao invalido.');

        Resultado := TEleicaoIntegracaoResultadoService.BuscarResultado(
          Contexto.IdEmpresaAPI,
          IdEleicaoInt
        );

        try
          Dados := TJSONObject.Create;
          Dados.AddPair('id_eleicao_int',TJSONNumber.Create(Resultado.IdEleicaoInt));
          Dados.AddPair('nome',Resultado.NomeEleicao);
          Dados.AddPair('operacao',Resultado.Operacao);
          Dados.AddPair('situacao',Resultado.Situacao);

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_eleitores',TJSONNumber.Create(Resultado.TotalEleitores));
          Resumo.AddPair('total_votantes',TJSONNumber.Create(Resultado.TotalVotantes));
          Resumo.AddPair('total_nao_votantes',TJSONNumber.Create(Resultado.TotalNaoVotantes));
          Resumo.AddPair('total_votos',TJSONNumber.Create(Resultado.TotalVotos));
          Resumo.AddPair('votos_validos',TJSONNumber.Create(Resultado.VotosValidos));
          Resumo.AddPair('votos_brancos',TJSONNumber.Create(Resultado.VotosBrancos));
          Resumo.AddPair('votos_nulos',TJSONNumber.Create(Resultado.VotosNulos));
          Dados.AddPair('resumo',Resumo);

          Chapas := TJSONArray.Create;
          for ItemChapa in Resultado.Chapas do
          begin
            Chapa := TJSONObject.Create;
            Chapa.AddPair('id_chapa_int',TJSONNumber.Create(ItemChapa.IdChapaInt));
            Chapa.AddPair('numero',TJSONNumber.Create(ItemChapa.Numero));
            Chapa.AddPair('nome',ItemChapa.Nome);
            Chapa.AddPair('quantidade_votos',TJSONNumber.Create(ItemChapa.QuantidadeVotos));
            Chapa.AddPair('percentual',TJSONNumber.Create(ItemChapa.Percentual));
            Chapas.AddElement(Chapa);
          end;
          Dados.AddPair('chapas',Chapas);

          Questoes := TJSONArray.Create;
          for Questao in Resultado.Questoes do
          begin
            QuestaoJson := TJSONObject.Create;
            QuestaoJson.AddPair('id_questao_int',TJSONNumber.Create(Questao.IdQuestaoInt));
            QuestaoJson.AddPair('ordem',TJSONNumber.Create(Questao.Ordem));
            QuestaoJson.AddPair('titulo',Questao.Titulo);
            QuestaoJson.AddPair('total_votos',TJSONNumber.Create(Questao.TotalVotos));

            Opcoes := TJSONArray.Create;
            for Opcao in Questao.Opcoes do
            begin
              OpcaoJson := TJSONObject.Create;
              OpcaoJson.AddPair('id_opcao_int',TJSONNumber.Create(Opcao.IdOpcaoInt));
              OpcaoJson.AddPair('ordem',TJSONNumber.Create(Opcao.Ordem));
              OpcaoJson.AddPair('descricao',Opcao.Descricao);
              OpcaoJson.AddPair('quantidade_votos',TJSONNumber.Create(Opcao.QuantidadeVotos));
              OpcaoJson.AddPair('percentual',TJSONNumber.Create(Opcao.Percentual));
              Opcoes.AddElement(OpcaoJson);
            end;

            QuestaoJson.AddPair('opcoes',Opcoes);
            Questoes.AddElement(QuestaoJson);
          end;
          Dados.AddPair('questoes',Questoes);

          TAppResponse.Ok(Res,Dados,'');
        finally
          Resultado.Chapas.Free;
          Resultado.Questoes.Free;
        end;
      except
        on E: Exception do
          TAppErrors.HandleException(Res,E);
      end;
    end
  );
end;

end.
