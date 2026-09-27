unit EmpresaAsmuv.Model;

interface

uses
  System.SysUtils;

type
  TEmpresaModel = class
  private
    FIdEmpresa: Int64;
    FRazaoSocial: string;
    FNomeFantasia: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property RazaoSocial: string read FRazaoSocial write FRazaoSocial;
    property NomeFantasia: string read FNomeFantasia write FNomeFantasia;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
