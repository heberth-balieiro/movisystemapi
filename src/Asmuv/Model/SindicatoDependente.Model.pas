unit SindicatoDependente.Model;

interface

uses
  System.SysUtils;

type
  TSindicatoDependenteModel = class
  private
    FIdDependente: Int64;
    FIdEmpresa: Int64;
    FIdSocio: Int64;
    FCodigo: Integer;
    FNome: string;
    FDataNascimento: TDateTime;
    FParentesco: string;
    FCpf: string;
    FRg: string;
    FSexo: string;
    FFoto: TBytes;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdDependente: Int64 read FIdDependente write FIdDependente;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdSocio: Int64 read FIdSocio write FIdSocio;

    property Codigo: Integer read FCodigo write FCodigo;
    property Nome: string read FNome write FNome;
    property DataNascimento: TDateTime read FDataNascimento write FDataNascimento;
    property Parentesco: string read FParentesco write FParentesco;
    property Cpf: string read FCpf write FCpf;
    property Rg: string read FRg write FRg;
    property Sexo: string read FSexo write FSexo;
    property Foto: TBytes read FFoto write FFoto;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
