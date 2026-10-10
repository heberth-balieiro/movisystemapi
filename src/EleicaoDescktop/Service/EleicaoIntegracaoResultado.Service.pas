unit EleicaoIntegracaoResultado.Service;

interface

uses
  System.Generics.Collections,
  EleicaoIntegracaoResultado.Dao;

type
  TEleicaoIntegracaoResultadoChapaResult = record
    IdChapaInt: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoIntegracaoResultadoResult = record
    IdEleicaoInt: Integer;
    NomeEleicao: string;
    Operacao: string;
    Situacao: string;
    TotalEleitores: Integer;
    TotalVotantes: Integer;
    TotalNaoVotantes: Integer;
    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;
    Chapas: TList<TEleicaoIntegracaoResultadoChapaResult>;
  end;

  TEleicaoIntegracaoResultadoService = class
  public
    class function BuscarResultado(
      const AIdEmpresa, AIdEleicaoInt: Integer
    ): TEleicaoIntegracaoResultadoResult; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection;

class function TEleicaoIntegracaoResultadoService.BuscarResultado(
  const AIdEmpresa, AIdEleicaoInt: Integer
): TEleicaoIntegracaoResultadoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoIntegracaoResultadoEleicao;
  Resumo: TEleicaoIntegracaoResultadoResumo;
  ListaDAO: TEleicaoIntegracaoResultadoChapas;
  ItemDAO: TEleicaoIntegracaoResultadoChapa;
  Item: TEleicaoIntegracaoResultadoChapaResult;
  OperacaoNormalizada: string;
begin
  Result := Default(TEleicaoIntegracaoResultadoResult);
  Result.Chapas := TList<TEleicaoIntegracaoResultadoChapaResult>.Create;

  try
    if AIdEmpresa <= 0 then
      TAppErrors.RaiseUnauthorized('Empresa nao informada.');

    if AIdEleicaoInt <= 0 then
      TAppErrors.RaiseBadRequest('ID da eleicao nao informado.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);
    try
      if not TEleicaoIntegracaoResultadoDao.BuscarEleicao(
        Conn,
        AIdEmpresa,
        AIdEleicaoInt,
        Eleicao
      ) then
        TAppErrors.RaiseNotFound('Eleicao nao encontrada.');

      if not (
        SameText(Eleicao.Situacao, 'APURADA') or
        SameText(Eleicao.Situacao, 'PUBLICADA')
      ) then
        TAppErrors.RaiseBadRequest('O resultado somente pode ser consultado apos a apuracao.');

      OperacaoNormalizada := UpperCase(Trim(Eleicao.Operacao));
      if SameText(OperacaoNormalizada, 'ASSEMBLEIA') then
        TAppErrors.RaiseBadRequest('Resultado de assembleia ainda nao disponivel para integracao.');

      Result.IdEleicaoInt := Eleicao.IdEleicaoInt;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Operacao := Eleicao.Operacao;
      Result.Situacao := Eleicao.Situacao;

      TEleicaoIntegracaoResultadoDao.BuscarResumo(
        Conn,
        AIdEmpresa,
        Eleicao.IdEleicao,
        Resumo
      );

      Result.TotalEleitores := Resumo.TotalEleitores;
      Result.TotalVotantes := Resumo.TotalVotantes;
      Result.TotalNaoVotantes := Result.TotalEleitores - Result.TotalVotantes;
      if Result.TotalNaoVotantes < 0 then
        Result.TotalNaoVotantes := 0;

      Result.TotalVotos := Resumo.TotalVotos;
      Result.VotosValidos := Resumo.VotosValidos;
      Result.VotosBrancos := Resumo.VotosBrancos;
      Result.VotosNulos := Resumo.VotosNulos;

      ListaDAO := TEleicaoIntegracaoResultadoChapas.Create;
      try
        TEleicaoIntegracaoResultadoDao.BuscarChapas(
          Conn,
          AIdEmpresa,
          Eleicao.IdEleicao,
          ListaDAO
        );

        for ItemDAO in ListaDAO do
        begin
          Item := Default(TEleicaoIntegracaoResultadoChapaResult);
          Item.IdChapaInt := ItemDAO.IdChapaInt;
          Item.Numero := ItemDAO.Numero;
          Item.Nome := ItemDAO.Nome;
          Item.QuantidadeVotos := ItemDAO.QuantidadeVotos;

          if Result.VotosValidos > 0 then
            Item.Percentual := (Item.QuantidadeVotos / Result.VotosValidos) * 100
          else
            Item.Percentual := 0;

          Result.Chapas.Add(Item);
        end;
      finally
        ListaDAO.Free;
      end;
    finally
      Conn.Free;
    end;
  except
    Result.Chapas.Free;
    Result.Chapas := nil;
    raise;
  end;
end;

end.
