unit LgpdSolicitacao.Model;

interface

uses
  System.Generics.Collections;

type
  TLgpdSolicitacaoItem = class
  private
    FId: Int64;
    FIdParticipante: Int64;
    FParticipanteNome: string;
    FProtocolo: string;
    FTipo: string;
    FSituacao: string;
    FDescricao: string;
    FResposta: string;
    FSolicitadoEm: TDateTime;
    FTemConcluidoEm: Boolean;
    FConcluidoEm: TDateTime;
    FResponsavelNome: string;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property ParticipanteNome: string read FParticipanteNome write FParticipanteNome;
    property Protocolo: string read FProtocolo write FProtocolo;
    property Tipo: string read FTipo write FTipo;
    property Situacao: string read FSituacao write FSituacao;
    property Descricao: string read FDescricao write FDescricao;
    property Resposta: string read FResposta write FResposta;
    property SolicitadoEm: TDateTime read FSolicitadoEm write FSolicitadoEm;
    property TemConcluidoEm: Boolean read FTemConcluidoEm write FTemConcluidoEm;
    property ConcluidoEm: TDateTime read FConcluidoEm write FConcluidoEm;
    property ResponsavelNome: string read FResponsavelNome write FResponsavelNome;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TLgpdSolicitacaoFiltro = record
    Busca: string;
    Tipo: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TLgpdSolicitacaoResultado = class
  private
    FItens: TObjectList<TLgpdSolicitacaoItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TLgpdSolicitacaoItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TLgpdSolicitacaoResultado.Create;
begin
  inherited;
  FItens := TObjectList<TLgpdSolicitacaoItem>.Create(True);
end;

destructor TLgpdSolicitacaoResultado.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
