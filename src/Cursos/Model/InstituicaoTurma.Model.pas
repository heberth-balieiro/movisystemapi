unit InstituicaoTurma.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoTurmaItem = class
  private
    FId: Int64;
    FIdCurso: Int64;
    FCursoNome: string;
    FIdEntidadeAtendida: Int64;
    FTemEntidadeAtendida: Boolean;
    FEntidadeAtendidaNome: string;
    FIdModeloCertificado: Int64;
    FTemModeloCertificado: Boolean;
    FModeloCertificadoNome: string;
    FCodigoPublico: string;
    FCodigoInterno: string;
    FNome: string;
    FModalidade: string;
    FTipoFluxo: string;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FInscricaoInicio: TDateTime;
    FTemInscricaoInicio: Boolean;
    FInscricaoFim: TDateTime;
    FTemInscricaoFim: Boolean;
    FLimiteParticipantes: Integer;
    FTemLimiteParticipantes: Boolean;
    FLocal: string;
    FUrlOnline: string;
    FCargaHorariaMinutos: Integer;
    FTemCargaHorariaMinutos: Boolean;
    FPermitirInscricaoPublica: Boolean;
    FAprovacaoInscricao: string;
    FControlePresenca: string;
    FExigirPresencaConclusao: Boolean;
    FConclusaoAutomatica: Boolean;
    FCertificadoAutomatico: Boolean;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
    property CursoNome: string read FCursoNome write FCursoNome;
    property IdEntidadeAtendida: Int64 read FIdEntidadeAtendida write FIdEntidadeAtendida;
    property TemEntidadeAtendida: Boolean read FTemEntidadeAtendida write FTemEntidadeAtendida;
    property EntidadeAtendidaNome: string read FEntidadeAtendidaNome write FEntidadeAtendidaNome;

    property IdModeloCertificado: Int64 read FIdModeloCertificado write FIdModeloCertificado;
    property TemModeloCertificado: Boolean read FTemModeloCertificado write FTemModeloCertificado;
    property ModeloCertificadoNome: string read FModeloCertificadoNome write FModeloCertificadoNome;

    property CodigoPublico: string read FCodigoPublico write FCodigoPublico;
    property CodigoInterno: string read FCodigoInterno write FCodigoInterno;
    property Nome: string read FNome write FNome;
    property Modalidade: string read FModalidade write FModalidade;
    property TipoFluxo: string read FTipoFluxo write FTipoFluxo;

    property DataHoraInicio: TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim: TDateTime read FDataHoraFim write FDataHoraFim;

    property InscricaoInicio: TDateTime read FInscricaoInicio write FInscricaoInicio;
    property TemInscricaoInicio: Boolean read FTemInscricaoInicio write FTemInscricaoInicio;

    property InscricaoFim: TDateTime read FInscricaoFim write FInscricaoFim;
    property TemInscricaoFim: Boolean read FTemInscricaoFim write FTemInscricaoFim;

    property LimiteParticipantes: Integer read FLimiteParticipantes write FLimiteParticipantes;
    property TemLimiteParticipantes: Boolean read FTemLimiteParticipantes write FTemLimiteParticipantes;

    property Local: string read FLocal write FLocal;
    property UrlOnline: string read FUrlOnline write FUrlOnline;

    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
    property TemCargaHorariaMinutos: Boolean read FTemCargaHorariaMinutos write FTemCargaHorariaMinutos;

    property PermitirInscricaoPublica: Boolean read FPermitirInscricaoPublica write FPermitirInscricaoPublica;
    property AprovacaoInscricao: string read FAprovacaoInscricao write FAprovacaoInscricao;
    property ControlePresenca: string read FControlePresenca write FControlePresenca;
    property ExigirPresencaConclusao: Boolean read FExigirPresencaConclusao write FExigirPresencaConclusao;
    property ConclusaoAutomatica: Boolean read FConclusaoAutomatica write FConclusaoAutomatica;
    property CertificadoAutomatico: Boolean read FCertificadoAutomatico write FCertificadoAutomatico;
    property Situacao: string read FSituacao write FSituacao;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoTurmaCadastro = record
    IdCurso: Int64;
    IdEntidadeAtendida: Int64;
    TemEntidadeAtendidaInformada: Boolean;
    IdModeloCertificado: Int64;
    CodigoPublico: string;
    CodigoInterno: string;
    Nome: string;
    Modalidade: string;
    TipoFluxo: string;

    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;

    InscricaoInicio: TDateTime;
    TemInscricaoInicio: Boolean;

    InscricaoFim: TDateTime;
    TemInscricaoFim: Boolean;

    LimiteParticipantes: Integer;
    TemLimiteParticipantes: Boolean;

    Local: string;
    UrlOnline: string;

    CargaHorariaMinutos: Integer;
    TemCargaHorariaMinutos: Boolean;

    PermitirInscricaoPublica: Boolean;
    AprovacaoInscricao: string;
    ControlePresenca: string;
    ExigirPresencaConclusao: Boolean;
    ConclusaoAutomatica: Boolean;
    CertificadoAutomatico: Boolean;
    Situacao: string;
    CriadoPor: Int64;
  end;

  TInstituicaoTurmaAlteracao = record
    IdCurso: Int64;
    IdEntidadeAtendida: Int64;
    IdModeloCertificado: Int64;
    CodigoInterno: string;
    Nome: string;
    Modalidade: string;
    TipoFluxo: string;

    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;

    InscricaoInicio: TDateTime;
    TemInscricaoInicio: Boolean;

    InscricaoFim: TDateTime;
    TemInscricaoFim: Boolean;

    LimiteParticipantes: Integer;
    TemLimiteParticipantes: Boolean;

    Local: string;
    UrlOnline: string;

    CargaHorariaMinutos: Integer;
    TemCargaHorariaMinutos: Boolean;

    PermitirInscricaoPublica: Boolean;
    AprovacaoInscricao: string;
    ControlePresenca: string;
    ExigirPresencaConclusao: Boolean;
    ConclusaoAutomatica: Boolean;
    CertificadoAutomatico: Boolean;
    Situacao: string;
  end;

  TInstituicaoTurmaFiltro = record
    Busca: string;
    Situacao: string;
    Modalidade: string;
    IdCurso: Int64;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoTurmaLista = class
  private
    FItens: TObjectList<TInstituicaoTurmaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoTurmaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoTurmaLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoTurmaItem>.Create(True);
end;

destructor TInstituicaoTurmaLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
