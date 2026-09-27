unit InstituicaoPresenca.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoPresencaItem = class
  private
    FId: Int64;
    FTemPresenca: Boolean;
    FIdTurma: Int64;
    FIdEncontro: Int64;
    FEncontroTitulo: string;
    FEncontroInicio: TDateTime;
    FEncontroFim: TDateTime;
    FIdInscricao: Int64;
    FInscricaoSituacao: string;
    FIdParticipante: Int64;
    FParticipanteNome: string;
    FParticipanteCpfMascarado: string;
    FParticipanteMatricula: string;
    FSituacao: string;

    FCheckinEm: TDateTime;
    FTemCheckinEm: Boolean;

    FCheckoutEm: TDateTime;
    FTemCheckoutEm: Boolean;

    FMinutosPresentes: Integer;
    FTemMinutosPresentes: Boolean;

    FJustificativa: string;

    FRegistradoPor: Int64;
    FTemRegistradoPor: Boolean;
    FRegistradoPorNome: string;

    FCriadoEm: TDateTime;
    FTemCriadoEm: Boolean;

    FAtualizadoEm: TDateTime;
    FTemAtualizadoEm: Boolean;
  public
    property Id: Int64 read FId write FId;
    property TemPresenca: Boolean read FTemPresenca write FTemPresenca;

    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property IdEncontro: Int64 read FIdEncontro write FIdEncontro;
    property EncontroTitulo: string read FEncontroTitulo write FEncontroTitulo;
    property EncontroInicio: TDateTime read FEncontroInicio write FEncontroInicio;
    property EncontroFim: TDateTime read FEncontroFim write FEncontroFim;

    property IdInscricao: Int64 read FIdInscricao write FIdInscricao;
    property InscricaoSituacao: string read FInscricaoSituacao write FInscricaoSituacao;

    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property ParticipanteCpfMascarado: string read FParticipanteCpfMascarado write FParticipanteCpfMascarado;
    property ParticipanteMatricula: string read FParticipanteMatricula write FParticipanteMatricula;

    property Situacao: string read FSituacao write FSituacao;

    property CheckinEm: TDateTime read FCheckinEm write FCheckinEm;
    property TemCheckinEm: Boolean read FTemCheckinEm write FTemCheckinEm;

    property CheckoutEm: TDateTime read FCheckoutEm write FCheckoutEm;
    property TemCheckoutEm: Boolean read FTemCheckoutEm write FTemCheckoutEm;

    property MinutosPresentes: Integer read FMinutosPresentes write FMinutosPresentes;
    property TemMinutosPresentes: Boolean read FTemMinutosPresentes write FTemMinutosPresentes;

    property Justificativa: string read FJustificativa write FJustificativa;

    property RegistradoPor: Int64 read FRegistradoPor write FRegistradoPor;
    property TemRegistradoPor: Boolean read FTemRegistradoPor write FTemRegistradoPor;
    property RegistradoPorNome: string read FRegistradoPorNome write FRegistradoPorNome;

    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property TemCriadoEm: Boolean read FTemCriadoEm write FTemCriadoEm;

    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
    property TemAtualizadoEm: Boolean read FTemAtualizadoEm write FTemAtualizadoEm;
  end;


  TInstituicaoPresencaRegistro = record
    IdInscricao: Int64;
    Situacao: string;

    CheckinEm: TDateTime;
    TemCheckinEm: Boolean;

    CheckoutEm: TDateTime;
    TemCheckoutEm: Boolean;

    MinutosPresentes: Integer;
    TemMinutosPresentes: Boolean;

    Justificativa: string;
  end;


  TInstituicaoPresencaRegistroLista =
    TList<TInstituicaoPresencaRegistro>;


  TInstituicaoPresencaFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;


  TInstituicaoPresencaLista = class
  private
    FItens: TObjectList<TInstituicaoPresencaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoPresencaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoPresencaLista.Create;
begin
  inherited;

  FItens :=
    TObjectList<TInstituicaoPresencaItem>.Create(
      True
    );
end;

destructor TInstituicaoPresencaLista.Destroy;
begin
  FItens.Free;

  inherited;
end;

end.
