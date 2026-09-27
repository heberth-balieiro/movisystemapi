{

Contexto dos campos



}


unit Cliente.Model;

interface

uses
  System.SysUtils;

type
  TClienteModel = class
  private
    FIdCliente: Int64;
    FIdEmpresa: Int64;

    FTipoPessoa: string;
    FNomeRazao: string;
    FNomeFantasia: string;
    FCpfCnpj: string;
    FRgIe: string;

    FTelefone: string;
    FWhatsapp: string;
    FEmail: string;

    FCep: string;
    FEndereco: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCidade: string;
    FUf: string;

    FResponsavelNome: string;
    FResponsavelCpf: string;
    FResponsavelTelefone: string;

    FAcessoPortal: string;
    FEcommerce: string;
    FConsignado: string;

    FLimiteConsignado: Double;
    FDiaFechamento: Integer;
    FPrazoPagamentoDias: Integer;

    FStatus: string;
    FObservacao: string;

    FDataCadastro: TDateTime;
    FDataAlteracao: TDateTime;
    FSenhaPortal: string;
    FCriarAcessoPortal: string;

  public
    property IdCliente: Int64 read FIdCliente write FIdCliente;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;

    property TipoPessoa: string read FTipoPessoa write FTipoPessoa;
    property NomeRazao: string read FNomeRazao write FNomeRazao;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property CpfCnpj: string read FCpfCnpj write FCpfCnpj;
    property RgIe: string read FRgIe write FRgIe;

    property Telefone: string read FTelefone write FTelefone;
    property Whatsapp: string read FWhatsapp write FWhatsapp;
    property Email: string read FEmail write FEmail;

    property Cep: string read FCep write FCep;
    property Endereco: string read FEndereco write FEndereco;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property Cidade: string read FCidade write FCidade;
    property Uf: string read FUf write FUf;

    property ResponsavelNome: string read FResponsavelNome write FResponsavelNome;
    property ResponsavelCpf: string read FResponsavelCpf write FResponsavelCpf;
    property ResponsavelTelefone: string read FResponsavelTelefone write FResponsavelTelefone;

    property AcessoPortal: string read FAcessoPortal write FAcessoPortal;
    property Ecommerce: string read FEcommerce write FEcommerce;
    property Consignado: string read FConsignado write FConsignado;

    property LimiteConsignado: Double read FLimiteConsignado write FLimiteConsignado;
    property DiaFechamento: Integer read FDiaFechamento write FDiaFechamento;
    property PrazoPagamentoDias: Integer read FPrazoPagamentoDias write FPrazoPagamentoDias;

    property Status: string read FStatus write FStatus;
    property Observacao: string read FObservacao write FObservacao;

    property DataCadastro: TDateTime read FDataCadastro write FDataCadastro;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;

    property CriarAcessoPortal: string read FCriarAcessoPortal write FCriarAcessoPortal;
    property SenhaPortal: string read FSenhaPortal write FSenhaPortal;
  end;

implementation

end.
