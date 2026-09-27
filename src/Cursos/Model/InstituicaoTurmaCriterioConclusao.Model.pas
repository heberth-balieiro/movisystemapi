unit InstituicaoTurmaCriterioConclusao.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoTurmaCriterioConclusaoItem = class
  private
    FId: Int64;
    FIdTurma: Int64;
    FTipo: string;
    FNome: string;
    FObrigatorio: Boolean;
    FConfiguracao: string;
    FTemConfiguracao: Boolean;
    FOrdem: Integer;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property Tipo: string read FTipo write FTipo;
    property Nome: string read FNome write FNome;
    property Obrigatorio: Boolean read FObrigatorio write FObrigatorio;
    property Configuracao: string read FConfiguracao write FConfiguracao;
    property TemConfiguracao: Boolean read FTemConfiguracao write FTemConfiguracao;
    property Ordem: Integer read FOrdem write FOrdem;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoTurmaCriterioConclusaoCadastro = record
    Tipo: string;
    Nome: string;
    Obrigatorio: Boolean;
    Configuracao: string;
    TemConfiguracao: Boolean;
    Ordem: Integer;
  end;

  TInstituicaoTurmaCriterioConclusaoAlteracao = TInstituicaoTurmaCriterioConclusaoCadastro;

  TInstituicaoTurmaCriterioConclusaoFiltro = record
    Busca: string;
    Tipo: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoTurmaCriterioConclusaoLista = class
  private
    FItens: TObjectList<TInstituicaoTurmaCriterioConclusaoItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    property Itens: TObjectList<TInstituicaoTurmaCriterioConclusaoItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoTurmaCriterioConclusaoLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoTurmaCriterioConclusaoItem>.Create(True);
end;

destructor TInstituicaoTurmaCriterioConclusaoLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
