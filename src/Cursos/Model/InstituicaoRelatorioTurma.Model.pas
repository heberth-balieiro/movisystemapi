unit InstituicaoRelatorioTurma.Model;

interface

uses
  System.Generics.Collections;

type
  TRelatorioTurmaFiltro = record
    Busca: string;
    Situacao: string;
    Modalidade: string;
    TipoTurma: string;
    IdCurso: Int64;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    TemDataInicio: Boolean;
    TemDataFim: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TRelatorioTurmaItem = class
  private
    FIdTurma: Int64;
    FIdCurso: Int64;
    FCursoNome: string;
    FTurmaNome: string;
    FModalidade: string;
    FTipoTurma: string;
    FSituacao: string;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FTotalInscritos: Integer;
    FTotalConcluidos: Integer;
    FTotalCertificados: Integer;
  public
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property Modalidade: string read FModalidade write FModalidade;
    property TipoTurma: string read FTipoTurma write FTipoTurma;
    property Situacao: string read FSituacao write FSituacao;
    property DataHoraInicio: TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim: TDateTime read FDataHoraFim write FDataHoraFim;
    property TotalInscritos: Integer read FTotalInscritos write FTotalInscritos;
    property TotalConcluidos: Integer read FTotalConcluidos write FTotalConcluidos;
    property TotalCertificados: Integer read FTotalCertificados write FTotalCertificados;
  end;

  TRelatorioTurmaResumo = record
    TotalTurmas: Integer;
    InscricoesAbertas: Integer;
    EmAndamento: Integer;
    Encerradas: Integer;
    Participantes: Integer;
    CertificadosEmitidos: Integer;
  end;

  TRelatorioTurmaFiltroOpcao = class
  private
    FId: Int64;
    FNome: string;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
  end;

  TRelatorioTurmaFiltros = class
  private
    FCursos: TObjectList<TRelatorioTurmaFiltroOpcao>;
  public
    constructor Create;
    destructor Destroy; override;
    property Cursos: TObjectList<TRelatorioTurmaFiltroOpcao> read FCursos;
  end;

  TRelatorioTurmaResultado = class
  private
    FItens: TObjectList<TRelatorioTurmaItem>;
    FResumo: TRelatorioTurmaResumo;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TRelatorioTurmaItem> read FItens;
    property Resumo: TRelatorioTurmaResumo read FResumo write FResumo;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TRelatorioTurmaFiltros.Create;
begin
  inherited;
  FCursos := TObjectList<TRelatorioTurmaFiltroOpcao>.Create(True);
end;

destructor TRelatorioTurmaFiltros.Destroy;
begin
  FCursos.Free;
  inherited;
end;

constructor TRelatorioTurmaResultado.Create;
begin
  inherited;
  FItens := TObjectList<TRelatorioTurmaItem>.Create(True);
end;

destructor TRelatorioTurmaResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
