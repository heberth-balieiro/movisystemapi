unit EleicaoResultadoPublicoAPI.Service;

interface

uses
  System.Generics.Collections;

type
  TEleicaoResultadoPublicoChapaResult = record
    IdChapa: Integer;
    Numero: Integer;
    Nome: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoResultadoPublicoResult = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Situacao: string;

    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;

    Chapas: TList<TEleicaoResultadoPublicoChapaResult>;
  end;

  TEleicaoResultadoPublicoAPIService = class
  public
    class function BuscarResultado(const ASlug: string): TEleicaoResultadoPublicoResult; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoResultadoPublicoAPI.Dao;

class function TEleicaoResultadoPublicoAPIService.BuscarResultado(const ASlug: string): TEleicaoResultadoPublicoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoResultadoPublicoDados;
  Resumo: TEleicaoResultadoPublicoResumo;
  ListaDAO: TEleicaoResultadoPublicoLista;
  ItemDAO: TEleicaoResultadoPublicoChapa;
  Item: TEleicaoResultadoPublicoChapaResult;
begin
  Result := Default(TEleicaoResultadoPublicoResult);
  Result.Chapas := TList<TEleicaoResultadoPublicoChapaResult>.Create;

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleição não informada.');

    Config := TAppConfig.Carregar(ExtractFilePath(ParamStr(0)) + 'Config.ini');
    Conn := TDatabaseConnection.NewConnection(Config.Database);

    try
      if not TEleicaoResultadoPublicoAPIDao.BuscarEleicaoPublicada(Conn, Trim(ASlug), Eleicao) then
        TAppErrors.RaiseNotFound('Resultado da eleição não disponível.');

      Result.IdEleicao := Eleicao.IdEleicao;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Situacao := Eleicao.Situacao;

      if not TEleicaoResultadoPublicoAPIDao.BuscarResumo(Conn, Eleicao.IdEmpresa, Eleicao.IdEleicao, Resumo) then
        TAppErrors.RaiseBadRequest('Não foi possível carregar o resultado da eleição.');

      Result.TotalVotos := Resumo.TotalVotos;
      Result.VotosValidos := Resumo.VotosValidos;
      Result.VotosBrancos := Resumo.VotosBrancos;
      Result.VotosNulos := Resumo.VotosNulos;

      ListaDAO := TEleicaoResultadoPublicoLista.Create;
      try
        TEleicaoResultadoPublicoAPIDao.BuscarChapas(Conn, Eleicao.IdEmpresa, Eleicao.IdEleicao, ListaDAO);

        for ItemDAO in ListaDAO do
        begin
          Item := Default(TEleicaoResultadoPublicoChapaResult);
          Item.IdChapa := ItemDAO.IdChapa;
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
