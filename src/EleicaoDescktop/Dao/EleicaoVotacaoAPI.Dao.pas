unit EleicaoVotacaoAPI.Dao;

interface

uses
  Uni,
  System.JSON;

type
  TEleicaoVotacaoAPIDao = class
  public
    class procedure GarantirEstruturaVotoQuestao(
      const AConn: TUniConnection
    ); static;

    class function EleitorJaVotou(
      const AConn: TUniConnection;
      const AIdEleicao: Integer;
      const AIdUsuario: Integer
    ): Boolean; static;

    class function