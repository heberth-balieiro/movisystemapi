unit Secretaria.Model;

interface

uses
  System.SysUtils;

type
  TSecretariaModel = class
  private
    FIdSecretaria: Int64;
    FIdEmpresa: Int64;
    FCodigo: Integer;
    FRazaoSocial: string;
    FNomeFantasia: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdSecretaria: Int64 read FIdSecretaria write FIdSecretaria;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Codigo: Integer read FCodigo write FCodigo;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
