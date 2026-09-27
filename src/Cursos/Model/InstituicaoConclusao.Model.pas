unit InstituicaoConclusao.Model;

interface

uses
  System.Generics.Collections;

type
  TConclusaoInscricaoContexto = class
  private
    FIdInscricao: Int64;
    FIdTurma: Int64;
    FIdCurso: Int64;
    FSituacao: string;
    FParticipanteNome: string;
    FCursoNome: string;
    FTurmaNome: string;
  public
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property Situacao: string read FSituacao write FSituacao;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
  end;


  TConclusaoMetricaPresenca = record
    TemBaseCalculo: Boolean;
    Percentual: Double;
    MinutosPrevistos: Int64;
    MinutosComputados: Int64;
  end;


  TConclusaoMetricaAulas = record
    TemAulasObrigatorias: Boolean;
    Percentual: Double;
    TotalAulas: Integer;
    AulasConcluidas: Integer;
  end;


  TConclusaoCriterioItem = class
  private
    FIdCriterio: Int64;
    FTipo: string;
    FNome: string;
    FObrigatorio: Boolean;
    FConfiguracao: string;
    FOrdem: Integer;

    FTemAtendido: Boolean;
    FAtendido: Boolean;

    FResultado: string;

    FTemAvaliadoPor: Boolean;
    FAvaliadoPor: Int64;
    FAvaliadoPorNome: string;

    FTemAvaliadoEm: Boolean;
    FAvaliadoEm: TDateTime;
  public
    property IdCriterio: Int64 read FIdCriterio write FIdCriterio;
    property Tipo: string read FTipo write FTipo;
    property Nome: string read FNome write FNome;
    property Obrigatorio: Boolean read FObrigatorio write FObrigatorio;
    property Configuracao: string read FConfiguracao write FConfiguracao;
    property Ordem: Integer read FOrdem write FOrdem;

    property TemAtendido: Boolean read FTemAtendido write FTemAtendido;
    property Atendido: Boolean read FAtendido write FAtendido;

    property Resultado: string read FResultado write FResultado;

    property TemAvaliadoPor: Boolean read FTemAvaliadoPor write FTemAvaliadoPor;
    property AvaliadoPor: Int64 read FAvaliadoPor write FAvaliadoPor;
    property AvaliadoPorNome: string read FAvaliadoPorNome write FAvaliadoPorNome;

    property TemAvaliadoEm: Boolean read FTemAvaliadoEm write FTemAvaliadoEm;
    property AvaliadoEm: TDateTime read FAvaliadoEm write FAvaliadoEm;
  end;


  TConclusaoCriterioLista =
    TObjectList<TConclusaoCriterioItem>;


  TConclusaoResumo = class
  private
    FIdInscricao: Int64;
    FIdTurma: Int64;
    FIdCurso: Int64;
    FParticipanteNome: string;
    FCursoNome: string;
    FTurmaNome: string;
    FSituacaoInscricao: string;

    FTemPercentualPresenca: Boolean;
    FPercentualPresenca: Double;

    FPercentualProgresso: Double;
    FElegivelCertificado: Boolean;

    FCriteriosObrigatorios: Integer;
    FCriteriosObrigatoriosAtendidos: Integer;
    FCriteriosObrigatoriosPendentes: Integer;
    FCriteriosObrigatoriosNaoAtendidos: Integer;

    FCriterios: TConclusaoCriterioLista;
  public
    constructor Create;
    destructor Destroy; override;

    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property SituacaoInscricao: string read FSituacaoInscricao write FSituacaoInscricao;

    property TemPercentualPresenca: Boolean read FTemPercentualPresenca write FTemPercentualPresenca;
    property PercentualPresenca: Double read FPercentualPresenca write FPercentualPresenca;

    property PercentualProgresso: Double read FPercentualProgresso write FPercentualProgresso;
    property ElegivelCertificado: Boolean read FElegivelCertificado write FElegivelCertificado;

    property CriteriosObrigatorios: Integer read FCriteriosObrigatorios write FCriteriosObrigatorios;
    property CriteriosObrigatoriosAtendidos: Integer read FCriteriosObrigatoriosAtendidos write FCriteriosObrigatoriosAtendidos;
    property CriteriosObrigatoriosPendentes: Integer read FCriteriosObrigatoriosPendentes write FCriteriosObrigatoriosPendentes;
    property CriteriosObrigatoriosNaoAtendidos: Integer read FCriteriosObrigatoriosNaoAtendidos write FCriteriosObrigatoriosNaoAtendidos;

    property Criterios: TConclusaoCriterioLista read FCriterios;
  end;


  TConclusaoAvaliacaoManual = record
    TemAtendido: Boolean;
    Atendido: Boolean;
    ResultadoJson: string;
  end;

implementation

constructor TConclusaoResumo.Create;
begin
  inherited;

  FCriterios :=
    TConclusaoCriterioLista.Create(
      True
    );
end;

destructor TConclusaoResumo.Destroy;
begin
  FCriterios.Free;

  inherited;
end;

end.
