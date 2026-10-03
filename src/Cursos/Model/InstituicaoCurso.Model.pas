unit InstituicaoCurso.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoCursoCadastro = record
    IdCategoria: Int64;
    IdEntidadeAtendida: Int64;

    CodigoPublico: string;
    CodigoInterno: string;
    Slug: string;

    Nome: string;
    Descricao: string;
    Objetivo: string;
    ConteudoProgramatico: string;

    CargaHorariaMinutos: Integer;
    Modalidade: string;
    ImagemUrl: string;

    PermitirInscricaoPublica: Boolean;
    Situacao: string;

    CriadoPor: Int64;
  end;


  TInstituicaoCursoAlteracao = record
    IdCategoria: Int64;
    IdEntidadeAtendida: Int64;
    CodigoInterno: string;
    Slug: string;

    Nome: string;
    Descricao: string;
    Objetivo: string;
    ConteudoProgramatico: string;

    CargaHorariaMinutos: Integer;
    Modalidade: string;
    ImagemUrl: string;

    PermitirInscricaoPublica: Boolean;
    Situacao: string;
  end;

  TInstituicaoCursoItem = class
  private
    FId: Int64;
    FIdCategoria: Int64;
    FIdEntidadeAtendida: Int64;
    FTemEntidadeAtendida: Boolean;
    FEntidadeAtendidaNome: string;
    FCodigoPublico: string;
    FCodigoInterno: string;
    FSlug: string;
    FNome: string;
    FDescricao: string;
    FObjetivo: string;
    FConteudoProgramatico: string;
    FCargaHorariaMinutos: Integer;
    FModalidade: string;
    FImagemUrl: string;
    FPermitirInscricaoPublica: Boolean;
    FSituacao: string;
  public
    property Id: Int64 read FId write FId;
    property IdCategoria: Int64 read FIdCategoria write FIdCategoria;
    property IdEntidadeAtendida: Int64 read FIdEntidadeAtendida write FIdEntidadeAtendida;
    property TemEntidadeAtendida: Boolean read FTemEntidadeAtendida write FTemEntidadeAtendida;
    property EntidadeAtendidaNome: string read FEntidadeAtendidaNome write FEntidadeAtendidaNome;
    property CodigoPublico: string read FCodigoPublico write FCodigoPublico;
    property CodigoInterno: string read FCodigoInterno write FCodigoInterno;
    property Slug: string read FSlug write FSlug;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Objetivo: string read FObjetivo write FObjetivo;
    property ConteudoProgramatico: string read FConteudoProgramatico write FConteudoProgramatico;
    property CargaHorariaMinutos: Integer read FCargaHorariaMinutos write FCargaHorariaMinutos;
    property Modalidade: string read FModalidade write FModalidade;
    property ImagemUrl: string read FImagemUrl write FImagemUrl;
    property PermitirInscricaoPublica: Boolean read FPermitirInscricaoPublica write FPermitirInscricaoPublica;
    property Situacao: string read FSituacao write FSituacao;
  end;

  TInstituicaoCursoFiltro = record
    Busca: string;
    Situacao: string;
    Modalidade: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoCursoLista = class
  private
    FItens: TObjectList<TInstituicaoCursoItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoCursoItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoCursoLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoCursoItem>.Create(True);
end;

destructor TInstituicaoCursoLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
