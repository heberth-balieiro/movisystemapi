unit AssinaturaCobranca.Model;

interface

uses
  System.SysUtils;

type
  TAssinaturaCobrancaModel = class
  private
    FIdCobranca: Int64;
    FIdAssinatura: Int64;
    FIdEmpresa: Int64;
    FVencimento: TDateTime;
    FPagoEm: TDateTime;
    FSituacao: string;
    FValor: Currency;
    FDescricao: string;
    FReferencia: string;
    FFormaPagamento: string;
    FIdTransacao: string;
    FLinkPagamento: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdCobranca: Int64 read FIdCobranca write FIdCobranca;
    property IdAssinatura: Int64 read FIdAssinatura write FIdAssinatura;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Vencimento: TDateTime read FVencimento write FVencimento;
    property PagoEm: TDateTime read FPagoEm write FPagoEm;
    property Situacao: string read FSituacao write FSituacao;
    property Valor: Currency read FValor write FValor;
    property Descricao: string read FDescricao write FDescricao;
    property Referencia: string read FReferencia write FReferencia;
    property FormaPagamento: string read FFormaPagamento write FFormaPagamento;
    property IdTransacao: string read FIdTransacao write FIdTransacao;
    property LinkPagamento: string read FLinkPagamento write FLinkPagamento;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
