unit AlunoCursoDisponivel.Model;

interface

uses
  System.Generics.Collections;

type
  TAlunoCursoDisponivelItem = class
  private
    FIdTurma: Int64;
    FCodigoTurma: string;
    FTurmaNome: string;
    FIdCurso: Int64;
    FCodigoCurso: string;
    FCursoNome: string;
    FCursoDescricao: string;
    FCursoObjetivo: string;
    FModalidade: string;
    FImagemUrl: string;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FInscricaoInicio: TDateTime;
    FTemInscricaoInicio: Boolean;
    FInscricaoFim: TDateTime;
    FTemInscricaoFim: Boolean;
    FLimiteParticipantes: Integer;
    FTemLimiteParticipantes: Boolean;
    FInscritosConfirmados: Integer;
    FVagasDisponiveis: Integer;
    FTemVagasDisponiveis: Boolean;
    FLocal: string;
    FCargaHorariaMinutos: Integer;
    FJaInscrito: Boolean;
    FIdInscricao: Int64;
    FTemIdInscricao: Boolean;
    FSituacaoInscricao: string;
  public
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property CodigoTurma: string read FCodigoTurma write FCodigoTurma;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property CodigoCurso: string read FCodigoCurso write FCodigoCurso;
    property CursoNome: string read FCursoNome write FCursoNome;
    property CursoDescricao: string read FCursoDescricao write FCursoDescricao;
    property CursoObjetivo: string read FCursoObjetivo write FCursoObjetivo;
    property Modalidade: string read FModalidade write FModalidade;
    property ImagemUrl: string read FImagemUrl write FImagemUrl;
    property DataHoraInicio: TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim: TDateTime read FDataHoraFim write FDataHoraFim;
    property InscricaoInicio: TDateTime read FInscricaoInicio write FInscricaoInicio;
    property TemInscricaoInicio: Boolean read FTemInscricaoInicio write FTemInscricaoInicio;
    property InscricaoFim: TDateTime read FInscricaoFim write FInscricaoFim;
    property TemInscricaoFim: Boolean read FTemInscricaoFim write FTemInscricaoFim;
    property LimiteParticipantes: Integer read FLimiteParticipantes write FLimiteParticipantes;
    property TemLimiteParticipantes: Boolean read FTemLimiteParticipantes write FTemLimiteParticipantes;
    property InscritosConfirmados: Integer read FInscritosConfirmados write FInscritosConfirmados;
    property VagasDisponiveis: Integer read FVagasDisponiveis write FVagasDisponiveis;
    property TemVagasDisponiveis: Boolean read FTemVagasDisponiveis write FTemVagasDisponiveis;
    property Local: string read FLocal write FLocal;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
    property JaInscrito: Boolean read FJaInscrito write FJaInscrito;
    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property TemIdInscricao: Boolean read FTemIdInscricao write FTemIdInscricao;
    property SituacaoInscricao: string read FSituacaoInscricao write FSituacaoInscricao;
  end;

  TAlunoCursoDisponivelLista = class
  private
    FItens: TObjectList<TAlunoCursoDisponivelItem>;
    FPagina: Integer;
    FPorPagina: Integer;
    FTotal: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TAlunoCursoDisponivelItem> read FItens;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
    property Total: Integer read FTotal write FTotal;
  end;

implementation

constructor TAlunoCursoDisponivelLista.Create;
begin
  inherited;
  FItens := TObjectList<TAlunoCursoDisponivelItem>.Create(True);
end;

destructor TAlunoCursoDisponivelLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
