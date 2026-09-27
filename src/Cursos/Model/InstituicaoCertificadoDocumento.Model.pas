unit InstituicaoCertificadoDocumento.Model;

interface

type
  TCertificadoDocumentoTemplate = class
  private
    FTemplateHtml: string;
    FTemplateConfiguracao: string;
    FImagemFundoUrl: string;
    FTextoValidacao: string;
  public
    property TemplateHtml: string read FTemplateHtml write FTemplateHtml;
    property TemplateConfiguracao: string read FTemplateConfiguracao write FTemplateConfiguracao;
    property ImagemFundoUrl: string read FImagemFundoUrl write FImagemFundoUrl;
    property TextoValidacao: string read FTextoValidacao write FTextoValidacao;
  end;

implementation

end.
