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
      Item: TEleicaoIntegracaoResultadoChapaResult;
    begin
      try
        UUID := Trim(Req.Headers['X-EasyOne-Empresa']);
        APIKey := Trim(Req.Headers['X-EasyOne-Key']);
        Contexto := TEasyOneIntegracaoService.Autenticar(UUID, APIKey);

        IdEleicaoInt := StrToIntDef(Trim(Req.Params['id_eleicao_int']), 0);
        if IdEleicaoInt <= 0 then
          TAppErrors.RaiseBadRequest('ID da eleicao invalido.');

        Resultado := TEleicaoIntegracaoResultadoService.BuscarResultado(
          Contexto.IdEmpresaAPI,
          IdEleicaoInt
        );

        try
          Dados := TJSONObject.Create;
          Dados.AddPair('id_eleicao_int', TJSONNumber.Create(Resultado.IdEleicaoInt));
          Dados.AddPair('nome', Resultado.NomeEleicao);
          Dados.AddPair('operacao', Resultado.Operacao);
          Dados.AddPair('situacao', Resultado.Situacao);

          Resumo := TJSONObject.Create;
          Resumo.AddPair('total_eleitores', TJSONNumber.Create(Resultado.TotalEleitores));
          Resumo.AddPair('total_votantes', TJSONNumber.Create(Resultado.TotalVotantes));
          Resumo.AddPair('total_nao_votantes', TJSONNumber.Create(Resultado.TotalNaoVotantes));
          Resumo.AddPair('total_votos', TJSONNumber.Create(Resultado.TotalVotos));
          Resumo.AddPair('votos_validos', TJSONNumber.Create(Resultado.VotosValidos));
          Resumo.AddPair('votos_brancos', TJSONNumber.Create(Resultado.VotosBrancos));
          Resumo.AddPair('votos_nulos', TJSONNumber.Create(Resultado.VotosNulos));
          Dados.AddPair('resumo', Resumo);

          Chapas := TJSONArray.Create;
          for Item in Resultado.Chapas do
          begin
            Chapa := TJSONObject.Create;
            Chapa.AddPair('id_chapa_int', TJSONNumber.Create(Item.IdChapaInt));
            Chapa.AddPair('numero', TJSONNumber.Create(Item.Numero));
            Chapa.AddPair('nome', Item.Nome);
            Chapa.AddPair('quantidade_votos', TJSONNumber.Create(Item.QuantidadeVotos));
            Chapa.AddPair('percentual', TJSONNumber.Create(Item.Percentual));
            Chapas.AddElement(Chapa);
          end;
          Dados.AddPair('chapas', Chapas);

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
