unit Plano.Model;

interface

uses
  System.SysUtils;

type
  TPlanoModel = class
  private
    FIdPlano: Int64;
    FDescricao: string;
    FValor: Currency;
    FCatalogo: string;
    FCatalogoQtde: Integer;
    FInterno: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    Fprodutoqtde: integer;
    Frecursos: String;
    Fvaloranual: double;
    FPermiteWhatsapp: string;
    FPermitePagSeguro: string;
    FPermiteEcommerce: string;
    FPermiteEmail: string;
    FPermitePedidoFicha: string;
    FPermitePedido: string;
    FPermiteProdutoIlimitado: string;
    FPermiteConfigVisual: string;
    fpermiteconfigcupom: string;
  public
    property IdPlano: Int64 read FIdPlano write FIdPlano;
    property Descricao: string read FDescricao write FDescricao;
    property Valor: Currency read FValor write FValor;
    property Catalogo: string read FCatalogo write FCatalogo;
    property CatalogoQtde: Integer read FCatalogoQtde write FCatalogoQtde;
    property Interno: string read FInterno write FInterno;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property valoranual  :double read Fvaloranual write Fvaloranual;
    property produtoqtde :integer read Fprodutoqtde write Fprodutoqtde;
    property recursos   :String read  Frecursos   write Frecursos;

    property PermiteProdutoIlimitado: string read FPermiteProdutoIlimitado write FPermiteProdutoIlimitado;
    property PermiteWhatsapp        : string read FPermiteWhatsapp write FPermiteWhatsapp;
    property PermiteEmail           : string read FPermiteEmail write FPermiteEmail;
    property PermitePedido          : string read FPermitePedido write FPermitePedido;
    property PermiteEcommerce       : string read FPermiteEcommerce write FPermiteEcommerce;
    property PermitePagSeguro       : string read FPermitePagSeguro write FPermitePagSeguro;
    property PermitePedidoFicha     : string read FPermitePedidoFicha write FPermitePedidoFicha;
    property PermiteConfigVisual    : string read FPermiteConfigVisual write FPermiteConfigVisual;
    property permiteconfigcupom     : string read fpermiteconfigcupom  write Fpermiteconfigcupom;
  end;

implementation

end.
