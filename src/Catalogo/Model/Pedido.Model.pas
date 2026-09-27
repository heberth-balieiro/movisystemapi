unit Pedido.Model;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  PedidoItem.Model;

type
  TPedidoModel = class
  private
    FIdPedido: Int64;
    FIdEmpresa: Int64;
    FNomeCliente: string;
    FWhatsappCliente: string;
    FEmailCliente: string;
    FObservacao: string;
    FTipoEntrega: string;
    FEnderecoEntrega: string;
    FStatus: string;
    FValorTotal: Currency;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    FItens: TObjectList<TPedidoItemModel>;
    FTipoPedido: string;
    FIdCliente: Int64;
  public
    constructor Create;
    destructor Destroy; override;

    property IdPedido: Int64 read FIdPedido write FIdPedido;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property NomeCliente: string read FNomeCliente write FNomeCliente;
    property WhatsappCliente: string read FWhatsappCliente write FWhatsappCliente;
    property EmailCliente: string read FEmailCliente write FEmailCliente;
    property Observacao: string read FObservacao write FObservacao;
    property TipoEntrega: string read FTipoEntrega write FTipoEntrega;
    property EnderecoEntrega: string read FEnderecoEntrega write FEnderecoEntrega;
    property Status: string read FStatus write FStatus;
    property ValorTotal: Currency read FValorTotal write FValorTotal;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property Itens: TObjectList<TPedidoItemModel> read FItens;

    property IdCliente: Int64 read FIdCliente write FIdCliente;
    property TipoPedido: string read FTipoPedido write FTipoPedido;





//    ORCAMENTO
//ECOMMERCE
//CONSIGNADO


  end;

implementation

constructor TPedidoModel.Create;
begin
  inherited Create;
  FItens := TObjectList<TPedidoItemModel>.Create(True);
end;

destructor TPedidoModel.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
