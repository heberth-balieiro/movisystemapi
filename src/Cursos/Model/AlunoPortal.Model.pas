unit AlunoPortal.Model;

interface

uses
  System.Generics.Collections;

type
  TAlunoContexto = class
  private
    FIdParticipante: Int64;
    FIdInstituicao: Int64;
    FIdUsuarioInstituicao: Int64;
    FCodigoPublico: string;
    FNome: string;
    FEmail: string;
    FCpfMascarado: string;
    FMatricula: string;
    FTelefone: string;
    FOrgaoEmpresa: string;
    FCargo: string;
    FInstituicaoNome: string;
    FInstituicaoSlug: string;
  public
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property IdInstituicao: Int64 read FIdInstituicao write FIdInstituicao;
    property IdUsuarioInstituicao: Int64 read FIdUsuarioInstituicao write FIdUsuarioInstituicao;
    property CodigoPublico: string read FCodigoPublico write FCodigoPublico;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
    property Matricula: string read FMatricula write FMatricula;
    property Telefone: string read FTelefone write FTelefone;
    property OrgaoEmpresa: string read FOrgaoEmpresa write FOrgaoEmpresa;
    property Cargo: string read FCargo write FCargo;
    property InstituicaoNome: string read FInstituicaoNome write FInstituicaoNome;
    property InstituicaoSlug: string read FInstituicaoSlug write FInstituicaoSlug;
  end;

  TAlunoDashboard = class
  public
    TotalInscricoes: Integer;
    InscricoesEmAndamento: Integer;
    InscricoesConcluidas: Integer;
    CertificadosValidos: Integer;
  end;

  TAlunoInscricaoItem = class
  public
    Id: Int64;
    CodigoPublico: string;
    IdTurma: Int64;
    TurmaNome: string;
    IdCurso: Int64;
    CursoNome: string;
    CursoImagemUrl: string;
    Modalidade: string;
    Situacao: string;
    InscritoEm: TDateTime;
    DataInicio: TDateTime;
    TemDataInicio: Boolean;
    DataFim: TDateTime;
    TemDataFim: Boolean;
    PercentualPresenca: Double;
    TemPercentualPresenca: Boolean;
    PercentualProgresso: Double;
    NotaFinal: Double;
    TemNotaFinal: Boolean;
    ElegivelCertificado: Boolean;
  end;

  TAlunoInscricaoLista = class
  public
    Itens: TObjectList<TAlunoInscricaoItem>;
    Pagina: Integer;
    PorPagina: Integer;
    Total: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TAlunoPresencaItem = class
  public
    IdEncontro: Int64;
    Titulo: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    Obrigatorio: Boolean;
    SituacaoEncontro: string;
    Registrada: Boolean;
    SituacaoPresenca: string;
    MinutosPresentes: Integer;
    TemMinutosPresentes: Boolean;
    Justificativa: string;
  end;

  TAlunoPresencaLista = TObjectList<TAlunoPresencaItem>;

  TAlunoAulaItem = class
  public
    IdAula: Int64;
    ModuloTitulo: string;
    Titulo: string;
    Tipo: string;
    DuracaoMinutos: Integer;
    TemDuracaoMinutos: Boolean;
    Obrigatoria: Boolean;
    Percentual: Double;
    DuracaoAssistidaSegundos: Integer;
    Concluida: Boolean;
  end;

  TAlunoAulaLista = TObjectList<TAlunoAulaItem>;

  TAlunoCriterioItem = class
  public
    IdCriterio: Int64;
    Tipo: string;
    Nome: string;
    Obrigatorio: Boolean;
    TemAtendido: Boolean;
    Atendido: Boolean;
    ResultadoJson: string;
  end;

  TAlunoCriterioLista = TObjectList<TAlunoCriterioItem>;

  TAlunoCertificadoItem = class
  public
    Id: Int64;
    NumeroPublico: string;
    Versao: Integer;
    Situacao: string;
    CursoNome: string;
    InstituicaoNome: string;
    CargaHorariaMinutos: Integer;
    DataConclusao: TDateTime;
    EmitidoEm: TDateTime;
    TemEmitidoEm: Boolean;
    CanceladoEm: TDateTime;
    TemCanceladoEm: Boolean;
    TemPdf: Boolean;
  end;

  TAlunoCertificadoLista = TObjectList<TAlunoCertificadoItem>;

implementation

constructor TAlunoInscricaoLista.Create;
begin
  inherited;
  Itens := TObjectList<TAlunoInscricaoItem>.Create(True);
end;

destructor TAlunoInscricaoLista.Destroy;
begin
  Itens.Free;
  inherited;
end;

end.
