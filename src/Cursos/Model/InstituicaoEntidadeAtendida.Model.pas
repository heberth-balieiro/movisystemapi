unit InstituicaoEntidadeAtendida.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoEntidadeAtendidaCadastro = record
    Nome: string;
    NomeFantasia: string;
    Tipo: string;
    Documento: string;
    Situacao: string;
    Observacao: string;
  end;

  TInstituicaoEntidadeAtendidaAlteracao = TInstituicaoEntidadeAtendidaCadastro;

  TInstituicaoEntidadeAtendidaItem = class
  private
    FId: Int64;
    FNome: string;
    FNomeFantasia: string;
    FTipo: string;
    FDocumento: string;
    FSituacao: string;
    FObservacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property Tipo: string read FTipo write FTipo;
    property Documento: string read FDocumento write FDocumento;
    property Situacao: string read FSituacao write FSituacao;
    property Observacao: string read FObservacao write FObservacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoEntidadeAtendidaFiltro = record
    Busca: string;
    Tipo: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoEntidadeAtendidaLista = class
  private
    FItens: TObjectList<TInstituicaoEntidadeAtendidaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoEntidadeAtendidaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoEntidadeAtendidaLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoEntidadeAtendidaItem>.Create(True);
end;

destructor TInstituicaoEntidadeAtendidaLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
