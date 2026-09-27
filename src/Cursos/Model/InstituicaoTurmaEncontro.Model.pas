unit InstituicaoTurmaEncontro.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoTurmaEncontroItem = class
  private
    FId: Int64;
    FIdTurma: Int64;
    FTitulo: string;
    FDescricao: string;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FCargaHorariaMinutos: Integer;
    FTemCargaHoraria: Boolean;
    FLocal: string;
    FUrlOnline: string;
    FObrigatorio: Boolean;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property IdTurma: Int64 read FIdTurma write FIdTurma;
    property Titulo: string read FTitulo write FTitulo;
    property Descricao: string read FDescricao write FDescricao;
    property DataHoraInicio: TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim: TDateTime read FDataHoraFim write FDataHoraFim;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
    property TemCargaHoraria: Boolean read FTemCargaHoraria write FTemCargaHoraria;
    property Local: string read FLocal write FLocal;
    property UrlOnline: string read FUrlOnline write FUrlOnline;
    property Obrigatorio: Boolean read FObrigatorio write FObrigatorio;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoTurmaEncontroCadastro = record
    Titulo: string;
    Descricao: string;
    DataHoraInicio: TDateTime;
    DataHoraFim: TDateTime;
    CargaHorariaMinutos: Integer;
    Local: string;
    UrlOnline: string;
    Obrigatorio: Boolean;
  end;

  TInstituicaoTurmaEncontroAlteracao = TInstituicaoTurmaEncontroCadastro;

  TInstituicaoTurmaEncontroFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoTurmaEncontroLista = class
  private
    FItens: TObjectList<TInstituicaoTurmaEncontroItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoTurmaEncontroItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoTurmaEncontroLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoTurmaEncontroItem>.Create(True);
end;

destructor TInstituicaoTurmaEncontroLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
