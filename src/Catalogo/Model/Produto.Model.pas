unit Produto.Model;

interface

uses
  System.SysUtils;

type
  TProdutoModel = class
  private
    FDestaque: string;
    FIdEmpresa: Int64;
    Fidunidade: Int64;
    Fidmarca: Int64;
    FAtivo: string;
    FPreco: Currency;
    FDescricao: string;
    Ftags: String;
    Fcodigo: String;
    Fimagem_principal: String;
    FDataAlteracao: TDateTime;
    FIdProduto: Int64;
    Fpromocao: Currency;
    Fsigla: string;
    Freferencia: String;
    FNome: string;
    FOrdem: Integer;
    FDataCriacao: TDateTime;
    FIdCategoria: Int64;
    Fnmmarca: string;
    Fnmcategoria: string;
    
  public
    property IdProduto    : Int64 read FIdProduto write FIdProduto;
    property IdEmpresa    : Int64 read FIdEmpresa write FIdEmpresa;
    property IdCategoria  : Int64 read FIdCategoria write FIdCategoria;
    property Nome         : string read FNome write FNome;
    property Descricao    : string read FDescricao write FDescricao;
    property Preco        : Currency read FPreco write FPreco;
    property Ativo        : string read FAtivo write FAtivo;
    property Destaque     : string read FDestaque write FDestaque;
    property Ordem        : Integer read FOrdem write FOrdem;
    property DataCriacao  : TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property imagem_principal :String read Fimagem_principal write Fimagem_principal;
    property codigo       : String read Fcodigo write Fcodigo;
    property idmarca      : Int64 read Fidmarca  write Fidmarca;
    property idunidade    : Int64 read Fidunidade  write Fidunidade;
    property promocao     : Currency read Fpromocao write Fpromocao;
    property referencia   : String read Freferencia write Freferencia;
    property tags         : String read Ftags write Ftags;

    //referencia
    property sigla        : string   read Fsigla   write Fsigla;
    property nmcategoria  : string   read Fnmcategoria   write Fnmcategoria;
    property nmmarca      : string   read Fnmmarca   write Fnmmarca;
  end;

implementation

end.


