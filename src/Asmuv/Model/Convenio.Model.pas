unit Convenio.Model;

interface

uses
  System.SysUtils;

type
  TConvenioModel = class
  private
    FIdConvenio: Int64;
    FIdEmpresa: Int64;
    FCodigo: Integer;
    FNome: string;
    FTipo: string;
    FTermos: string;
    FInformacaoContrato: string;
    FValor: Currency;
    FTelefone: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdConvenio: Int64 read FIdConvenio write FIdConvenio;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Codigo: Integer read FCodigo write FCodigo;
    property Nome: string read FNome write FNome;
    property Tipo: string read FTipo write FTipo;
    property Termos: string read FTermos write FTermos;
    property InformacaoContrato: string read FInformacaoContrato write FInformacaoContrato;
    property Valor: Currency read FValor write FValor;
    property Telefone: string read FTelefone write FTelefone;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
