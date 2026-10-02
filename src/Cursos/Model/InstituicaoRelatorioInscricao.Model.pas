unit InstituicaoRelatorioInscricao.Model;

interface

uses
  System.Generics.Collections;

type
  TRelatorioInscricaoFiltro = record
    Busca: string;
    Situacao: string;
    Origem: string;
    IdCurso: Int64;
    IdTurma: Int64;
    DataInscricaoInicio: TDateTime;
    DataInscricaoFim: TDateTime;
    TemDataInscricaoInicio: Boolean;
    TemDataInscricaoFim: Boolean;
    DataConclusaoInicio: TDateTime;
    DataConclusaoFim: TDateTime;
    TemDataConclusaoInicio: Boolean;
    TemDataConclusaoFim: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TRelatorioInscricaoItem = class
  private
    FIdInscricao: Int64;
    FParticipanteNome: string;
    FCpfMascarado: string;
    FCursoNome: string;
    FTurmaNome: string;
    FTipoTurma: string;
    FOrigem: string;
    FSituacao: string;
    FInscritoEm: TDateTime;
    FTemConcluidoEm: Boolean;
    FConcluidoEm: TDateTime;
    FTemPercentualPresenca: Boolean;
    FPercentualPresenca: Double;
    FElegivelCertificado: Boolean;
    FCertificadoEmitido: Boolean;
  public
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property TipoTurma: string read FTipoTurma write FTipoTurma;
    property Origem: string read FOrigem write FOrigem;
    property Situacao: string read FSituacao write FSituacao;
    property InscritoEm: TDateTime read FInscritoEm write FInscritoEm;
    property TemConcluidoEm: Boolean read FTemConcluidoEm write FTemConcluidoEm;
    property ConcluidoEm: TDateTime read FConcluidoEm write FConcluidoEm;
    property TemPercentualPresenca: Boolean read FTemPercentualPresenca write FTemPercentualPresenca;
    property PercentualPresenca: Double read FPercentualPresenca write FPercentualPresenca;
    property ElegivelCertificado: Boolean read FElegivelCertificado write FElegivelCertificado;
    property CertificadoEmitido: Boolean read FCertificadoEmitido write FCertificadoEmitido;
  end;

  TRelatorioInscricaoResumo = record
    TotalInscricoes: Integer;
    Confirmadas: Integer;
    EmAndamento: Integer;
    Concluidas: Integer;
    Canceladas: Integer;
    Reprovadas: Integer;
    Desistentes: Integer;
    ElegiveisCertificado: Integer;
    CertificadosEmitidos: Integer;
  end;

  TRelatorioInscricaoFiltroOpcao = class
  private
    FId: Int64;
    FNome: string;
    FIdCurso: Int64;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
  end;

  TRelatorioInscricaoFiltros = class
  private
    FCursos: TObjectList<TRelatorioInscricaoFiltroOpcao>;
    FTurmas: TObjectList<TRelatorioInscricaoFiltroOpcao>;
  public
    constructor Create;
    destructor Destroy; override;
    property Cursos: TObjectList<TRelatorioInscricaoFiltroOpcao> read FCursos;
    property Turmas: TObjectList<TRelatorioInscricaoFiltroOpcao> read FTurmas;
  end;

  TRelatorioInscricaoResultado = class
  private
    FItens: TObjectList<TRelatorioInscricaoItem>;
    FResumo: TRelatorioInscricaoResumo;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TRelatorioInscricaoItem> read FItens;
    property Resumo: TRelatorioInscricaoResumo read FResumo write FResumo;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TRelatorioInscricaoFiltros.Create;
begin
  inherited;
  FCursos := TObjectList<TRelatorioInscricaoFiltroOpcao>.Create(True);
  FTurmas := TObjectList<TRelatorioInscricaoFiltroOpcao>.Create(True);
end;

destructor TRelatorioInscricaoFiltros.Destroy;
begin
  FTurmas.Free;
  FCursos.Free;
  inherited;
end;

constructor TRelatorioInscricaoResultado.Create;
begin
  inherited;
  FItens := TObjectList<TRelatorioInscricaoItem>.Create(True);
end;

destructor TRelatorioInscricaoResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
