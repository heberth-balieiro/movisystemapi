unit Empresa.Model;

interface

uses
  System.SysUtils;

type
  TEmpresaModel = class
  private
    FIdEmpresa: Int64;
    FNome: string;
    FCnpj: string;
    FCep: string;
    FEndereco: string;
    FNumero: string;
    FComplemento: string;
    FBairro: string;
    FCidade: string;
    FUf: string;
    FWhatsapp: string;
    FEmail: string;
    FNomeResponsavel: string;
    FDataCriacao: TDateTime;
    FDataValidade: TDate;
    FAtivo: string;
    FNotificarPedidoWhatsapp: string;
    FNotificarPedidoEmail: string;
    FResumoDiario: string;
    FMensagemModelo: string;
    Fidplano: Integer;
    Fidsegmento: Int64;
  public
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Cnpj: string read FCnpj write FCnpj;
    property Cep: string read FCep write FCep;
    property Endereco: string read FEndereco write FEndereco;
    property Numero: string read FNumero write FNumero;
    property Complemento: string read FComplemento write FComplemento;
    property Bairro: string read FBairro write FBairro;
    property Cidade: string read FCidade write FCidade;
    property Uf: string read FUf write FUf;
    property Whatsapp: string read FWhatsapp write FWhatsapp;
    property Email: string read FEmail write FEmail;
    property NomeResponsavel: string read FNomeResponsavel write FNomeResponsavel;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataValidade: TDate read FDataValidade write FDataValidade;
    property Ativo: string read FAtivo write FAtivo;
    property NotificarPedidoWhatsapp: string read FNotificarPedidoWhatsapp write FNotificarPedidoWhatsapp;
    property NotificarPedidoEmail: string read FNotificarPedidoEmail write FNotificarPedidoEmail;
    property ResumoDiario: string read FResumoDiario write FResumoDiario;
    property MensagemModelo: string read FMensagemModelo write FMensagemModelo;
    property idplano:Integer  read Fidplano write Fidplano;
    property idsegmento:Int64 read Fidsegmento  write Fidsegmento;
  end;

implementation

end.
