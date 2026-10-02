unit InstituicaoRelatorioParticipante.Model;

interface

uses
  System.Generics.Collections;

type
  TRelatorioParticipanteFiltro = record
    Busca: string;
    CpfHashBusca: string;
    Situacao: string;
    IdCurso: Int64;
    IdTurma: Int64;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TRelatorioParticipanteItem = class
  private
    FIdParticipante: Int64;
    FNome: string;
    FCpfMascarado: string;
    FEmail: string;
    FTelefone: string;
    FSituacao: string;
    FTotalInscricoes: Integer;
    FTotalConclusoes: Integer;
    FTotalCertificados: Integer;
  public
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property Nome: string read FNome write FNome;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
    property Email: string read FEmail write FEmail;
    property Telefone: string read FTelefone write FTelefone;
    property Situacao: string read FSituacao write FSituacao;
    property TotalInscricoes: Integer read FTotalInscricoes write FTotalInscricoes;
    property TotalConclusoes: Integer read FTotalConclusoes write FTotalConclusoes;
    property TotalCertificados: Integer read FTotalCertificados write FTotalCertificados;
  end;

  TRelatorioParticipanteResumo = record
    TotalParticipantes: Integer;
    Ativos: Integer;
    Inativos: Integer;
    Anonimizados: Integer;
    TotalInscricoes: Integer;
    TotalConclusoes: Integer;
    TotalCertificados: Integer;
  end;

  TRelatorioParticipanteFiltroOpcao = class
  private
    FId: Int64;
    FNome: string;
    FIdCurso: Int64;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property IdCurso: Int64 read FIdCurso write FIdCurso;
  end;

  TRelatorioParticipanteFiltros = class
  private
    FCursos: TObjectList<TRelatorioParticipanteFiltroOpcao>;
    FTurmas: TObjectList<TRelatorioParticipanteFiltroOpcao>;
  public
    constructor Create;
    destructor Destroy; override;
    property Cursos: TObjectList<TRelatorioParticipanteFiltroOpcao> read FCursos;
    property Turmas: TObjectList<TRelatorioParticipanteFiltroOpcao> read FTurmas;
  end;

  TRelatorioParticipanteResultado = class
  private
    FItens: TObjectList<TRelatorioParticipanteItem>;
    FResumo: TRelatorioParticipanteResumo;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TRelatorioParticipanteItem> read FItens;
    property Resumo: TRelatorioParticipanteResumo read FResumo write FResumo;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TRelatorioParticipanteFiltros.Create;
begin
  inherited;
  FCursos := TObjectList<TRelatorioParticipanteFiltroOpcao>.Create(True);
  FTurmas := TObjectList<TRelatorioParticipanteFiltroOpcao>.Create(True);
end;

destructor TRelatorioParticipanteFiltros.Destroy;
begin
  FTurmas.Free;
  FCursos.Free;
  inherited;
end;

constructor TRelatorioParticipanteResultado.Create;
begin
  inherited;
  FItens := TObjectList<TRelatorioParticipanteItem>.Create(True);
end;

destructor TRelatorioParticipanteResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
