unit PlataformaAjuda.Model;

interface

type
  TPlataformaAjudaModel = class
  private
    FId: Int64;
    FUrlYoutube: string;
    FAssunto: string;
    FDescricao: string;
    FSituacao: string;
    FOrdem: Integer;
    FCriadoEm: TDateTime;
    FAtualizadoEm: TDateTime;
  public
    property Id: Int64 read FId write FId;
    property UrlYoutube: string read FUrlYoutube write FUrlYoutube;
    property Assunto: string read FAssunto write FAssunto;
    property Descricao: string read FDescricao write FDescricao;
    property Situacao: string read FSituacao write FSituacao;
    property Ordem: Integer read FOrdem write FOrdem;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
    property AtualizadoEm: TDateTime read FAtualizadoEm write FAtualizadoEm;
  end;

implementation

end.
