unit InstituicaoPerfil.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoPermissaoItem = class
  private
    FId: Int64;
    FCodigo: string;
    FModulo: string;
    FDescricao: string;
    FSituacao: string;
    FSelecionada: Boolean;
  public
    property Id: Int64 read FId write FId;
    property Codigo: string read FCodigo write FCodigo;
    property Modulo: string read FModulo write FModulo;
    property Descricao: string read FDescricao write FDescricao;
    property Situacao: string read FSituacao write FSituacao;
    property Selecionada: Boolean read FSelecionada write FSelecionada;
  end;

  TInstituicaoPerfilItem = class
  private
    FId: Int64;
    FNome: string;
    FDescricao: string;
    FSistema: Boolean;
    FSituacao: string;
    FQuantidadePermissoes: Integer;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
    FPermissoes: TObjectList<TInstituicaoPermissaoItem>;
  public
    constructor Create;
    destructor Destroy; override;

    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Sistema: Boolean read FSistema write FSistema;
    property Situacao: string read FSituacao write FSituacao;
    property QuantidadePermissoes: Integer read FQuantidadePermissoes write FQuantidadePermissoes;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
    property Permissoes: TObjectList<TInstituicaoPermissaoItem> read FPermissoes;
  end;

  TInstituicaoPerfilCadastro = record
    Nome: string;
    Descricao: string;
  end;

  TInstituicaoPerfilAlteracao = record
    Nome: string;
    Descricao: string;
  end;

  TInstituicaoPerfilFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoPerfilLista = class
  private
    FItens: TObjectList<TInstituicaoPerfilItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoPerfilItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoPerfilItem.Create;
begin
  inherited;
  FPermissoes :=
    TObjectList<TInstituicaoPermissaoItem>.Create(True);
end;

destructor TInstituicaoPerfilItem.Destroy;
begin
  FPermissoes.Free;
  inherited;
end;

constructor TInstituicaoPerfilLista.Create;
begin
  inherited;
  FItens :=
    TObjectList<TInstituicaoPerfilItem>.Create(True);
end;

destructor TInstituicaoPerfilLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
