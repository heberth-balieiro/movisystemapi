unit SindicatoProfissao.Model;

interface

uses
  System.SysUtils;

type
  TSindicatoProfissaoModel = class
  private
    FIdProfissao: Int64;
    FIdEmpresa: Int64;
    FCodigo: Integer;
    FDescricao: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdProfissao: Int64 read FIdProfissao write FIdProfissao;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Codigo: Integer read FCodigo write FCodigo;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
