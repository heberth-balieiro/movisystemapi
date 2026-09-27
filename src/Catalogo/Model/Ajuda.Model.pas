unit Ajuda.Model;

interface

uses
  System.SysUtils;

type
  TAjudaModel = class
  private
    FIdAjuda: Int64;
    FIdEmpresa: Int64;
    FOrdem: Integer;
    FTitulo: string;
    FUrl: string;
    FDescricao: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdAjuda: Int64 read FIdAjuda write FIdAjuda;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Ordem: Integer read FOrdem write FOrdem;
    property Titulo: string read FTitulo write FTitulo;
    property Url: string read FUrl write FUrl;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
