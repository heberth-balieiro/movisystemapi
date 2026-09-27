unit Carteira.Model;

interface

uses
  System.SysUtils;

type
  TCarteiraModel = class
  private
    FIdCarteira: Int64;
    FIdEmpresa: Int64;
    FIdSocio: Int64;
    FIdDependente: Int64;

    FDataValidade: TDateTime;
    FDataEmissao: TDateTime;

    FAtivo: string;
    FImpressoDependente: string;
    FDigital: string;
    FApi: string;

    FLogin: string;
    FNomeUsuario: string;
    FSenha: string;
    FToken: string;
    FTokenDevice: string;
    FQrCode: TBytes;

    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdCarteira: Int64 read FIdCarteira write FIdCarteira;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdSocio: Int64 read FIdSocio write FIdSocio;
    property IdDependente: Int64 read FIdDependente write FIdDependente;

    property DataValidade: TDateTime read FDataValidade write FDataValidade;
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;

    property Ativo: string read FAtivo write FAtivo;
    property ImpressoDependente: string read FImpressoDependente write FImpressoDependente;
    property Digital: string read FDigital write FDigital;
    property Api: string read FApi write FApi;

    property Login: string read FLogin write FLogin;
    property NomeUsuario: string read FNomeUsuario write FNomeUsuario;
    property Senha: string read FSenha write FSenha;
    property Token: string read FToken write FToken;
    property TokenDevice: string read FTokenDevice write FTokenDevice;
    property QrCode: TBytes read FQrCode write FQrCode;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
