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

  TEleicaoResultadoPublicoOpcaoResult = record
    IdOpcao: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoResultadoPublicoQuestaoResult = class
  public
    IdQuestao: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TList<TEleicaoResultadoPublicoOpcaoResult>;

    constructor Create;
    destructor Destroy; override;
  end;

  TEleicaoResultadoPublicoResult = record
    IdEleicao: Integer;
    NomeEleicao: string;
    Situacao: string;
    Operacao: string;

    TotalVotos: Integer;
    VotosValidos: Integer;
    VotosBrancos: Integer;
    VotosNulos: Integer;

    Chapas: TList<TEleicaoResultadoPublicoChapaResult>;
    Questoes: TObjectList<TEleicaoResultadoPublicoQuestaoResult>;
  end;

  TEleicaoResultadoPublicoAPIService = class
  public
    class function BuscarResultado(
      const ASlug: string
    ): TEleicaoResultadoPublicoResult; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoResultadoPublicoAPI.Dao;

{ TEleicaoResultadoPublicoQuestaoResult }

constructor TEleicaoResultadoPublicoQuestaoResult.Create;
begin
  inherited Create;
  Opcoes := TList<TEleicaoResultadoPublicoOpcaoResult>.Create;
end;

destructor TEleicaoResultadoPublicoQuestaoResult.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

{ TEleicaoResultadoPublicoAPIService }

class function TEleicaoResultadoPublicoAPIService.BuscarResultado(
  const ASlug: string
): TEleicaoResultadoPublicoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;
  Eleicao: TEleicaoResultadoPublicoDados;
  Resumo: TEleicaoResultadoPublicoResumo;

  ListaChapasDAO: TEleicaoResultadoPublicoLista;
  ItemChapaDAO: TEleicaoResultadoPublicoChapa;
  ItemChapa: TEleicaoResultadoPublicoChapaResult;

  ListaQuestoesDAO: TEleicaoResultadoPublicoQuestoes;
  QuestaoDAO: TEleicaoResultadoPublicoQuestao;
  OpcaoDAO: TEleicaoResultadoPublicoOpcao;
  Questao: TEleicaoResultadoPublicoQuestaoResult;
  Opcao: TEleicaoResultadoPublicoOpcaoResult;
begin
  Result := Default(TEleicaoResultadoPublicoResult);
  Result.Chapas := TList<TEleicaoResultadoPublicoChapaResult>.Create;
  Result.Questoes := TObjectList<TEleicaoResultadoPublicoQuestaoResult>.Create(True);

  try
    if Trim(ASlug).IsEmpty then
      TAppErrors.RaiseBadRequest('Eleicao nao informada.');

    Config := TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

    Conn := TDatabaseConnection.NewConnection(Config.Database);
    try
      if not TEleicaoResultadoPublicoAPIDao.BuscarEleicaoPublicada(
        Conn,
        Trim(ASlug),
        Eleicao
      ) then
        TAppErrors.RaiseNotFound('Resultado da eleicao nao disponivel.');

      Result.IdEleicao := Eleicao.IdEleicao;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Situacao := Eleicao.Situacao;
      Result.Operacao := Eleicao.Operacao;

      if SameText(Eleicao.Operacao,'ASSEMBLEIA') then
      begin
        Result.TotalVotos :=
          TEleicaoResultadoPublicoAPIDao.BuscarTotalVotantes(
            Conn,
            Eleicao.IdEmpresa,
            Eleicao.IdEleicao
          );
        Result.VotosValidos := 0;
        Result.VotosBrancos := 0;
        Result.VotosNulos := 0;

        ListaQuestoesDAO := TEleicaoResultadoPublicoQuestoes.Create(True);
        try
          TEleicaoResultadoPublicoAPIDao.BuscarQuestoes(
            Conn,
            Eleicao.IdEmpresa,
            Eleicao.IdEleicao,
            ListaQuestoesDAO
          );

          for QuestaoDAO in ListaQuestoesDAO do
          begin
            Questao := TEleicaoResultadoPublicoQuestaoResult.Create;
            Questao.IdQuestao := QuestaoDAO.IdQuestao;
            Questao.Ordem := QuestaoDAO.Ordem;
            Questao.Titulo := QuestaoDAO.Titulo;
            Questao.TotalVotos := QuestaoDAO.TotalVotos;

            for OpcaoDAO in QuestaoDAO.Opcoes do
            begin
              Opcao := Default(TEleicaoResultadoPublicoOpcaoResult);
              Opcao.IdOpcao := OpcaoDAO.IdOpcao;
              Opcao.Ordem := OpcaoDAO.Ordem;
              Opcao.Descricao := OpcaoDAO.Descricao;
              Opcao.QuantidadeVotos := OpcaoDAO.QuantidadeVotos;

              if Questao.TotalVotos > 0 then
                Opcao.Percentual :=
                  (Opcao.QuantidadeVotos / Questao.TotalVotos) * 100
              else
                Opcao.Percentual := 0;

              Questao.Opcoes.Add(Opcao);
            end;

            Result.Questoes.Add(Questao);
          end;
        finally
          ListaQuestoesDAO.Free;
        end;
      end
      else
      begin
        if not TEleicaoResultadoPublicoAPIDao.BuscarResumo(
          Conn,
          Eleicao.IdEmpresa,
          Eleicao.IdEleicao,
          Resumo
        ) then
          TAppErrors.RaiseBadRequest(
            'Nao foi possivel carregar o resultado da eleicao.'
          );

        Result.TotalVotos := Resumo.TotalVotos;
        Result.VotosValidos := Resumo.VotosValidos;
        Result.VotosBrancos := Resumo.VotosBrancos;
        Result.VotosNulos := Resumo.VotosNulos;

        ListaChapasDAO := TEleicaoResultadoPublicoLista.Create;
        try
          TEleicaoResultadoPublicoAPIDao.BuscarChapas(
            Conn,
            Eleicao.IdEmpresa,
            Eleicao.IdEleicao,
            ListaChapasDAO
          );

          for ItemChapaDAO in ListaChapasDAO do
          begin
            ItemChapa := Default(TEleicaoResultadoPublicoChapaResult);
            ItemChapa.IdChapa := ItemChapaDAO.IdChapa;
            ItemChapa.Numero := ItemChapaDAO.Numero;
            ItemChapa.Nome := ItemChapaDAO.Nome;
            ItemChapa.QuantidadeVotos := ItemChapaDAO.QuantidadeVotos;

            if Result.VotosValidos > 0 then
              ItemChapa.Percentual :=
                (ItemChapa.QuantidadeVotos / Result.VotosValidos) * 100
            else
              ItemChapa.Percentual := 0;

            Result.Chapas.Add(ItemChapa);
          end;
        finally
          ListaChapasDAO.Free;
        end;
      end;
    finally
      Conn.Free;
    end;
  except
    Result.Chapas.Free;
    Result.Chapas := nil;
    Result.Questoes.Free;
    Result.Questoes := nil;
    raise;
  end;
end;

end.
