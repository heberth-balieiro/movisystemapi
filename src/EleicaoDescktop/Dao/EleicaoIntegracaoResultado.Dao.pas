unit EleicaoIntegracaoResultado.Dao;

interface

uses
  Uni,
  System.Generics.Collections;

type
  TEleicaoIntegracaoResultadoEleicao = record
    IdEleicao: Integer;
    IdEleicaoInt: Integer;
    Nome: string;
    Situacao: string;
    Operacao: string;
  end;

  TEleicaoIntegracaoResultadoResumo = record
    TotalEleitores: Integer;
    TotalVotantes: Integer;
    TotalVotos: Integer;
    Votos