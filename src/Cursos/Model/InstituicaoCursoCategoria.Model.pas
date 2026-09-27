unit InstituicaoCursoCategoria.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoCursoCategoriaItem = class
  private
    FId: Int64;
    FNome: string;
    FDescricao: string;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoCursoCategoriaCadastro = record
    Nome: string;
    Descricao: string;
  end;

  TInstituicaoCursoCategoriaAlteracao = record
    Nome: string;
    Descricao: string;
  end;

  TInstituicaoCursoCategoriaFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoCursoCategoriaLista = class
  private
    FItens: TObjectList<TInstituicaoCursoCategoriaItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoCursoCategoriaItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoCursoCategoriaLista.Create;
begin
  inherited;
  FItens :=
    TObjectList<TInstituicaoCursoCategoriaItem>.Create(True);
end;

destructor TInstituicaoCursoCategoriaLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
