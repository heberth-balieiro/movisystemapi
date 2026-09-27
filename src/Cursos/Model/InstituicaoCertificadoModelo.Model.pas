unit InstituicaoCertificadoModelo.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoCertificadoModeloItem = class
  private
    FId: Int64;
    FNome: string;
    FDescricao: string;
    FTemplateHtml: string;
    FTemplateConfiguracao: string;
    FImagemFundoUrl: string;
    FSituacao: string;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property TemplateHtml: string read FTemplateHtml write FTemplateHtml;
    property TemplateConfiguracao: string read FTemplateConfiguracao write FTemplateConfiguracao;
    property ImagemFundoUrl: string read FImagemFundoUrl write FImagemFundoUrl;
    property Situacao: string read FSituacao write FSituacao;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

  TInstituicaoCertificadoModeloCadastro = record
    Nome: string;
    Descricao: string;
    TemplateHtml: string;
    TemplateConfiguracao: string;
    ImagemFundoUrl: string;
  end;

  TInstituicaoCertificadoModeloAlteracao = record
    Nome: string;
    Descricao: string;
    TemplateHtml: string;
    TemplateConfiguracao: string;
    ImagemFundoUrl: string;
  end;

  TInstituicaoCertificadoModeloFiltro = record
    Busca: string;
    Situacao: string;
    Pagina: Integer;
    PorPagina: Integer;
  end;

  TInstituicaoCertificadoModeloLista = class
  private
    FItens: TObjectList<TInstituicaoCertificadoModeloItem>;
    FTotal: Integer;
    FPagina: Integer;
    FPorPagina: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoCertificadoModeloItem> read FItens;
    property Total: Integer read FTotal write FTotal;
    property Pagina: Integer read FPagina write FPagina;
    property PorPagina: Integer read FPorPagina write FPorPagina;
  end;

implementation

constructor TInstituicaoCertificadoModeloLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoCertificadoModeloItem>.Create(True);
end;

destructor TInstituicaoCertificadoModeloLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
