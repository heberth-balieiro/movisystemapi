unit InstituicaoInscricao.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoInscricaoItem = class
  private
    FId: Int64;
    FIdTurma: Int64;
    FIdCurso: Int64;
    FCursoNome: string;
    FTurmaNome: string;
    FIdParticipante: Int64;
    FParticipanteNome: string;
    FParticipanteCpfMascarado: string;
    FParticipanteMatricula: string;
    FCodigoPublico: string;
    FOrigem: string;
    FSituacao: string;

    FInscritoEm: TDateTime;

    FConfirmadoEm: TDateTime;
    FTemConfirmadoEm: Boolean;

    FIniciadoEm: TDateTime;
    FTemIniciadoEm: Boolean;

    FConcluidoEm: TDateTime;
    FTemConcluidoEm: Boolean;

    FCanceladoEm: TDateTime;
    FTemCanceladoEm: Boolean;

    FMotivoCancelamento: string;

    FPercentualPresenca: Double;
    FTemPercentualPresenca: Boolean;

    FPercentualProgresso: Double;

    FNotaFinal: Double;
    FTemNotaFinal: Boolean;

    FElegivelCertificado: Boolean;

    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property ParticipanteCpfMascarado: string read FParticipanteCpfMascarado write FParticipanteCpfMascarado;
    property ParticipanteMatricula: string read FParticipanteMatricula write FParticipanteMatricula;
    property CodigoPublico: string read FCodigoPublico write FCodigoPublico;
    property Origem: string read FOrigem write FOrigem;
    property Situacao: string read FSituacao write FSituacao;

    property InscritoEm: TDateTime read FInscritoEm write FInscritoEm;

    property ConfirmadoEm: TDateTime read FConfirmadoEm write FConfirmadoEm;
    property TemConfirmadoEm: Boolean read FTemConfirmadoEm write FTemConfirmadoEm;

    property IniciadoEm: TDateTime read FIniciadoEm write FIniciadoEm;
    property TemIniciadoEm: Boolean read FTemIniciadoEm write FTemIniciadoEm;

    property ConcluidoEm: TDateTime read FConcluidoEm write FConcluidoEm;
    property TemConcluidoEm: Boolean read FTemConcluidoEm write FTemConcluidoEm;

    property CanceladoEm: TDateTime read FCanceladoEm write FCanceladoEm;
    property TemCanceladoEm: Boolean read FTemCanceladoEm write FTemCanceladoEm;

    property MotivoCancelamento: string read FMotivoCancelamento write FMotivoCancelamento;

    property PercentualPresenca: Double read FPercentualPresenca write FPercentualPresenca;
    property TemPercentualPresenca: Boolean read FTemPercentualPresenca write FTemPercentualPresenca;

    property PercentualProgresso: Double read FPercentualProgresso write FPercentualProgresso;

    property NotaFinal: Double read FNotaFinal write FNotaFinal;
    property TemNotaFinal: Boolean read FTemNotaFinal write FTemNotaFinal;

    property ElegivelCertificado: Boolean read FElegivelCertificado write FElegivelCertificado;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;


  TInstituicaoInscricaoCadastro = record
    IdTurma: Int64;
    IdParticipante: Int64;
  end;


  TInstituicaoInscricaoSituacaoAlteracao = record
    Situacao: string;
    Observacao: string;
    MotivoCancelamento: string;
  end;


  TInstituicaoInscricaoFiltro = record
    Busca: string;
    IdTurma: Int64;
    IdParticipante: Int64;
    Situacao: string;
    Origem: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;


  TInstituicaoInscricaoLista = class
  private
    FItens: TObjectList<TInstituicaoInscricaoItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoInscricaoItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;


  TInstituicaoInscricaoHistoricoItem = class
  private
    FId: Int64;
    FSituacaoAnterior: string;
    FTemSituacaoAnterior: Boolean;
    FSituacaoNova: string;
    FObservacao: string;
    FAlteradoPor: Int64;
    FTemAlteradoPor: Boolean;
    FAlteradoPorNome: string;
    FCriadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;

    property SituacaoAnterior: string read FSituacaoAnterior write FSituacaoAnterior;
    property TemSituacaoAnterior: Boolean read FTemSituacaoAnterior write FTemSituacaoAnterior;

    property SituacaoNova: string read FSituacaoNova write FSituacaoNova;
    property Observacao: string read FObservacao write FObservacao;

    property AlteradoPor: Int64 read FAlteradoPor write FAlteradoPor;
    property TemAlteradoPor: Boolean read FTemAlteradoPor write FTemAlteradoPor;
    property AlteradoPorNome: string read FAlteradoPorNome write FAlteradoPorNome;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;


  TInstituicaoInscricaoHistoricoLista =
    TObjectList<TInstituicaoInscricaoHistoricoItem>;

implementation

constructor TInstituicaoInscricaoLista.Create;
begin
  inherited;

  FItens :=
    TObjectList<TInstituicaoInscricaoItem>.Create(
      True
    );
end;

destructor TInstituicaoInscricaoLista.Destroy;
begin
  FItens.Free;

  inherited;
end;

end.
