unit InstituicaoRelatorioPresenca.Model;

interface

uses
  System.Generics.Collections;

type
  TRelatorioPresencaFiltro = record
    Busca: string;
    CpfHashBusca: string;
    Situacao: string;
    Origem: string;
    ControlePresenca: string;
    IdCurso: Int64;
    IdTurma: Int64;
    IdEncontro: Int64;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    TemDataInicio: Boolean;
    TemDataFim: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TRelatorioPresencaItem = class
  private
    FIdInscricao: Int64;
    FIdParticipante: Int64;
    FParticipanteNome: string;
    FCpfMascarado: string;
    FIdCurso: Int64;
    FCursoNome: string;
    FIdTurma: Int64;
    FTurmaNome: string;
    FControlePresenca: string;
    FIdEncontro: Int64;
    FTemEncontro: Boolean;
    FEncontroTitulo: string;
    FDataReferencia: TDateTime;
    FSituacao: string;
    FOrigem: string;
    FCheckinEm: TDateTime;
    FTemCheckinEm: Boolean;
    FRegistradoPorNome: string;
    FJustificativa: string;
    FMinutosPresentes: Integer;
    FTemMinutosPresentes: Boolean;
  public
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property CursoNome: string read FCursoNome write FCursoNome;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property ControlePresenca: string read FControlePresenca write FControlePresenca;
    property IdEncontro: Int64 read FIdEncontro write FIdEncontro;
    property TemEncontro: Boolean read FTemEncontro write FTemEncontro;
    property EncontroTitulo: string read FEncontroTitulo write FEncontroTitulo;
    property DataReferencia: TDateTime read FDataReferencia write FDataReferencia;
    property Situacao: string read FSituacao write FSituacao;
    property Origem: string read FOrigem write FOrigem;
    property CheckinEm: TDateTime read FCheckinEm write FCheckinEm;
    property TemCheckinEm: Boolean read FTemCheckinEm write FTemCheckinEm;
    property RegistradoPorNome: string read FRegistradoPorNome write FRegistradoPorNome;
    property Justificativa: string read FJustificativa write FJustificativa;
    property MinutosPresentes: Integer read FMinutosPresentes write FMinutosPresentes;
    property TemMinutosPresentes: Boolean read FTemMinutosPresentes write FTemMinutosPresentes;
  end;

  TRelatorioPresencaResumo = record
    TotalPrevistos: Integer;
    Presentes: Integer;
    Ausentes: Integer;
    Justificadas: Integer;
    Parciais: Integer;
    SemRegistro: Integer;
    AutoCheckin: Integer;
    QrEquipe: Integer;
    Manuais: Integer;
  end;

  TRelatorioPresencaFiltroOpcao = class
  private
    FId: Int64;
    FNome: string;
    FIdCurso: Int64;
    FIdTurma: Int64;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
  end;

  TRelatorioPresencaFiltros = class
  private
    FCursos: TObjectList<TRelatorioPresencaFiltroOpcao>;
    FTurmas: TObjectList<TRelatorioPresencaFiltroOpcao>;
    FEncontros: TObjectList<TRelatorioPresencaFiltroOpcao>;
  public
    constructor Create;
    destructor Destroy; override;
    property Cursos: TObjectList<TRelatorioPresencaFiltroOpcao> read FCursos;
    property Turmas: TObjectList<TRelatorioPresencaFiltroOpcao> read FTurmas;
    property Encontros: TObjectList<TRelatorioPresencaFiltroOpcao> read FEncontros;
  end;

  TRelatorioPresencaResultado = class
  private
    FItens: TObjectList<TRelatorioPresencaItem>;
    FResumo: TRelatorioPresencaResumo;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TRelatorioPresencaItem> read FItens;
    property Resumo: TRelatorioPresencaResumo read FResumo write FResumo;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TRelatorioPresencaFiltros.Create;
begin
  inherited;
  FCursos := TObjectList<TRelatorioPresencaFiltroOpcao>.Create(True);
  FTurmas := TObjectList<TRelatorioPresencaFiltroOpcao>.Create(True);
  FEncontros := TObjectList<TRelatorioPresencaFiltroOpcao>.Create(True);
end;

destructor TRelatorioPresencaFiltros.Destroy;
begin
  FEncontros.Free;
  FTurmas.Free;
  FCursos.Free;
  inherited;
end;

constructor TRelatorioPresencaResultado.Create;
begin
  inherited;
  FItens := TObjectList<TRelatorioPresencaItem>.Create(True);
end;

destructor TRelatorioPresencaResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
