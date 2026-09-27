unit VerificaCode.Model;

interface

uses
  System.SysUtils;

type
  TVerificaCodeModel = class
  private
    FIdVerificaCode: Int64;
    FIdSocio: Int64;
    FCodigo: string;
    FDataExpiracao: TDateTime;
    FUtilizado: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdVerificaCode: Int64 read FIdVerificaCode write FIdVerificaCode;
    property IdSocio: Int64 read FIdSocio write FIdSocio;
    property Codigo: string read FCodigo write FCodigo;
    property DataExpiracao: TDateTime read FDataExpiracao write FDataExpiracao;
    property Utilizado: string read FUtilizado write FUtilizado;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
