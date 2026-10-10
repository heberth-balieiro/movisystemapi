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

  TEleicaoIntegracaoResultadoOpcaoResult = record
    IdOpcaoInt: Integer;
    Ordem: Integer;
    Descricao: string;
    QuantidadeVotos: Integer;
    Percentual: Double;
  end;

  TEleicaoIntegracaoResultadoQuestaoResult = class
  public
    IdQuestaoInt: Integer;
    Ordem: Integer;
    Titulo: string;
    TotalVotos: Integer;
    Opcoes: TList<TEleicaoIntegracaoResultadoOpcaoResult>;

    constructor Create;
    destructor Destroy; override;
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
    Questoes: TObjectList<TEleicaoIntegracaoResultadoQuestaoResult>;
  end;

  TEleicaoIntegracaoResultadoService = class
  private
    class procedure ValidarConsulta(
      const AIdEmpresa: Integer;
      const AIdEleicaoInt: Integer
    ); static;

    class procedure ValidarEleicao(
      const AEleicao: TEleicaoIntegracaoResultadoEleicao
    ); static;

  public
    class function BuscarResultado(
      const AIdEmpresa: Integer;
      const AIdEleicaoInt: Integer
    ): TEleicaoIntegracaoResultadoResult; static;
  end;

implementation

uses
  System.SysUtils,
  Uni,
  App.Config,
  App.Errors,
  Database.Connection,
  EleicaoVotacaoAPI.Dao;

{ TEleicaoIntegracaoResultadoQuestaoResult }

constructor TEleicaoIntegracaoResultadoQuestaoResult.Create;
begin
  inherited Create;
  Opcoes := TList<TEleicaoIntegracaoResultadoOpcaoResult>.Create;
end;

destructor TEleicaoIntegracaoResultadoQuestaoResult.Destroy;
begin
  Opcoes.Free;
  inherited;
end;

{ TEleicaoIntegracaoResultadoService }

class procedure TEleicaoIntegracaoResultadoService.ValidarConsulta(
  const AIdEmpresa: Integer;
  const AIdEleicaoInt: Integer
);
begin
  if AIdEmpresa <= 0 then
    TAppErrors.RaiseUnauthorized('Empresa nao informada.');

  if AIdEleicaoInt <= 0 then
    TAppErrors.RaiseBadRequest('ID da eleicao nao informado.');
end;

class procedure TEleicaoIntegracaoResultadoService.ValidarEleicao(
  const AEleicao: TEleicaoIntegracaoResultadoEleicao
);
begin
  if not (
    SameText(AEleicao.Situacao, 'APURADA') or
    SameText(AEleicao.Situacao, 'PUBLICADA')
  ) then
    TAppErrors.RaiseBadRequest(
      'O resultado somente pode ser consultado apos a apuracao.'
    );
end;

class function TEleicaoIntegracaoResultadoService.BuscarResultado(
  const AIdEmpresa: Integer;
  const AIdEleicaoInt: Integer
): TEleicaoIntegracaoResultadoResult;
var
  Config: TAppApiConfig;
  Conn: TUniConnection;

  Eleicao: TEleicaoIntegracaoResultadoEleicao;
  Participacao: TEleicaoIntegracaoParticipacaoResumo;
  Apuracao: TEleicaoIntegracaoApuracaoResumo;

  ListaChapasDAO: TEleicaoIntegracaoResultadoChapas;
  ChapaDAO: TEleicaoIntegracaoResultadoChapa;
  Chapa: TEleicaoIntegracaoResultadoChapaResult;

  ListaQuestoesDAO: TEleicaoIntegracaoResultadoQuestoes;
  QuestaoDAO: TEleicaoIntegracaoResultadoQuestao;
  OpcaoDAO: TEleicaoIntegracaoResultadoOpcao;
  Questao: TEleicaoIntegracaoResultadoQuestaoResult;
  Opcao: TEleicaoIntegracaoResultadoOpcaoResult;
begin
  Result := Default(TEleicaoIntegracaoResultadoResult);
  Result.Chapas := TList<TEleicaoIntegracaoResultadoChapaResult>.Create;
  Result.Questoes := TObjectList<TEleicaoIntegracaoResultadoQuestaoResult>.Create(True);

  try
    ValidarConsulta(AIdEmpresa,AIdEleicaoInt);

    Config := TAppConfig.Carregar(
      ExtractFilePath(ParamStr(0)) + 'Config.ini'
    );

    Conn := TDatabaseConnection.NewConnection(Config.Database);
    try
      if not TEleicaoIntegracaoResultadoDao.BuscarEleicao(
        Conn,
        AIdEmpresa,
        AIdEleicaoInt,
        Eleicao
      ) then
        TAppErrors.RaiseNotFound('Eleicao nao encontrada.');

      ValidarEleicao(Eleicao);

      Result.IdEleicaoInt := Eleicao.IdEleicaoInt;
      Result.NomeEleicao := Eleicao.Nome;
      Result.Operacao := Eleicao.Operacao;
      Result.Situacao := Eleicao.Situacao;

      if not TEleicaoIntegracaoResultadoDao.BuscarResumoParticipacao(
        Conn,
        AIdEmpresa,
        Eleicao.IdEleicao,
        Participacao
      ) then
        TAppErrors.RaiseBadRequest(
          'Nao foi possivel carregar o resumo de participacao da eleicao.'
        );

      Result.TotalEleitores := Participacao.TotalEleitores;
      Result.TotalVotantes := Participacao.TotalVotantes;
      Result.TotalNaoVotantes := Result.TotalEleitores - Result.TotalVotantes;

      if Result.TotalNaoVotantes < 0 then
        Result.TotalNaoVotantes := 0;

      if SameText(Eleicao.Operacao,'ASSEMBLEIA') then
      begin
        TEleicaoVotacaoAPIDao.GarantirEstruturaVotoQuestao(Conn);

        Result.TotalVotos := Result.TotalVotantes;
        Result.VotosValidos := 0;
        Result.VotosBrancos := 0;
        Result.VotosNulos := 0;

        ListaQuestoesDAO := TEleicaoIntegracaoResultadoQuestoes.Create(True);
        try
          TEleicaoIntegracaoResultadoDao.BuscarResultadoQuestoes(
            Conn,
            AIdEmpresa,
            Eleicao.IdEleicao,
            ListaQuestoesDAO
          );

          for QuestaoDAO in ListaQuestoesDAO do
          begin
            Questao := TEleicaoIntegracaoResultadoQuestaoResult.Create;
            Questao.IdQuestaoInt := QuestaoDAO.IdQuestaoInt;
            Questao.Ordem := QuestaoDAO.Ordem;
            Questao.Titulo := QuestaoDAO.Titulo;
            Questao.TotalVotos := QuestaoDAO.TotalVotos;

            for OpcaoDAO in QuestaoDAO.Opcoes do
            begin
              Opcao := Default(TEleicaoIntegracaoResultadoOpcaoResult);
              Opcao.IdOpcaoInt := OpcaoDAO.IdOpcaoInt;
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
        if not TEleicaoIntegracaoResultadoDao.BuscarResumoApuracao(
          Conn,
          AIdEmpresa,
          Eleicao.IdEleicao,
          Apuracao
        ) then
          TAppErrors.RaiseBadRequest(
            'Nao foi possivel carregar o resumo da apuracao da eleicao.'
          );

        Result.TotalVotos := Apuracao.TotalVotos;
        Result.VotosValidos := Apuracao.VotosValidos;
        Result.VotosBrancos := Apuracao.VotosBrancos;
        Result.VotosNulos := Apuracao.VotosNulos;

        ListaChapasDAO := TEleicaoIntegracaoResultadoChapas.Create;
        try
          TEleicaoIntegracaoResultadoDao.BuscarResultadoChapas(
            Conn,
            AIdEmpresa,
            Eleicao.IdEleicao,
            ListaChapasDAO
          );

          for ChapaDAO in ListaChapasDAO do
          begin
            Chapa := Default(TEleicaoIntegracaoResultadoChapaResult);
            Chapa.IdChapaInt := ChapaDAO.IdChapaInt;
            Chapa.Numero := ChapaDAO.Numero;
            Chapa.Nome := ChapaDAO.Nome;
            Chapa.QuantidadeVotos := ChapaDAO.QuantidadeVotos;

            if Result.VotosValidos > 0 then
              Chapa.Percentual :=
                (Chapa.QuantidadeVotos / Result.VotosValidos) * 100
            else
              Chapa.Percentual := 0;

            Result.Chapas.Add(Chapa);
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
