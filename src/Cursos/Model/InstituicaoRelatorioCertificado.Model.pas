unit InstituicaoRelatorioCertificado.Model;

interface

uses
  System.Generics.Collections;

type
  TRelatorioCertificadoFiltro = record
    Busca: string;
    Situacao: string;
    TipoTurma: string;
    IdCurso: Int64;
    IdTurma: Int64;
    IdParticipante: Int64;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    TemDataInicio: Boolean;
    TemDataFim: Boolean;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TRelatorioCertificadoItem = class
  private
    FIdCertificado: Int64;
    FNumeroPublico: string;
    FParticipanteNome: string;
    FCpfMascarado: string;
    FCursoNome: string;
    FTurmaNome: string;
    FTipoTurma: string;
    FSituacao: string;
    FVersao: Integer;
    FReemitido: Boolean;
    FEmitidoEm: TDateTime;
    FTemEmitidoEm: Boolean;
    FCanceladoEm: TDateTime;
    FTemCanceladoEm: Boolean;
    FEmitidoPorNome: string;
    FCargaHorariaMinutos: Integer;
  public
    property IdCertificado: Int64 read FIdCertificado write FIdCertificado;
    property NumeroPublico: string read FNumeroPublico write FNumeroPublico;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
    property CursoNome: string read FCursoNome write FCursoNome;
    property TurmaNome: string read FTurmaNome write FTurmaNome;
    property TipoTurma: string read FTipoTurma write FTipoTurma;
    property Situacao: string read FSituacao write FSituacao;
    property Versao: Integer read FVersao write FVersao;
    property Reemitido: Boolean read FReemitido write FReemitido;
    property EmitidoEm: TDateTime read FEmitidoEm write FEmitidoEm;
    property TemEmitidoEm: Boolean read FTemEmitidoEm write FTemEmitidoEm;
    property CanceladoEm: TDateTime read FCanceladoEm write FCanceladoEm;
    property TemCanceladoEm: Boolean read FTemCanceladoEm write FTemCanceladoEm;
    property EmitidoPorNome: string read FEmitidoPorNome write FEmitidoPorNome;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
  end;

  TRelatorioCertificadoResumo = record
    Total: Integer;
    Valid0s: Integer;
    Cancelados: Integer;
    Pendentes: Integer;
    Erros: Integer;
    Reemitidos: Integer;
  end;

  TRelatorioCertificadoResultado = class
  private
    FItens: TObjectList<TRelatorioCertificadoItem>;
    FResumo: TRelatorioCertificadoResumo;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TRelatorioCertificadoItem> read FItens;
    property Resumo: TRelatorioCertificadoResumo read FResumo write FResumo;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TRelatorioCertificadoResultado.Create;
begin
  inherited;
  FItens := TObjectList<TRelatorioCertificadoItem>.Create(True);
end;

destructor TRelatorioCertificadoResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
