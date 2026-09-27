unit Segmento.Model;

interface

uses
  System.SysUtils;

type
  TSegmentoModel = class
  private
    FIdSegmento: Int64;
    FIdEmpresa: Int64;
    FNome: string;
    FDescricao: string;
    FAtivo: string;
    FOrdem: Integer;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdSegmento: Int64 read FIdSegmento write FIdSegmento;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;
    property Ordem: Integer read FOrdem write FOrdem;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.


{

INSERT INTO segmento (nome, descricao, ativo, ordem) VALUES
('Acessórios', 'Catálogo para acessórios, bijuterias, joias e semijoias.', 'S', 1),
('Moda e Vestuário', 'Catálogo para roupas, calçados e moda em geral.', 'S', 2),
('Alimentos', 'Catálogo para restaurantes, lanchonetes, marmitas e alimentos.', 'S', 3),
('Ferramentas', 'Catálogo para ferramentas, peças e materiais de construção.', 'S', 4),
('Serviços', 'Catálogo para empresas prestadoras de serviço.', 'S', 5);



}
