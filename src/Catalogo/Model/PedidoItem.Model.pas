unit PedidoItem.Model;

interface

uses
  System.SysUtils;

type
  TPedidoItemModel = class
  private
    FIdItem: Int64;
    FIdPedido: Int64;
    FIdEmpresa: Int64;
    FIdProduto: Int64;
    FNomeProduto: string;
    FQuantidade: Currency;
    FValorUnitario: Currency;
    FValorTotal: Currency;
    FObservacao: string;
    FDataCriacao: TDateTime;
  public
    property IdItem: Int64 read FIdItem write FIdItem;
    property IdPedido: Int64 read FIdPedido write FIdPedido;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdProduto: Int64 read FIdProduto write FIdProduto;
    property NomeProduto: string read FNomeProduto write FNomeProduto;
    property Quantidade: Currency read FQuantidade write FQuantidade;
    property ValorUnitario: Currency read FValorUnitario write FValorUnitario;
    property ValorTotal: Currency read FValorTotal write FValorTotal;
    property Observacao: string read FObservacao write FObservacao;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
  end;

implementation

end.
