unit Unidade.Model;

interface

uses
  System.SysUtils;

type
  TUnidadeModel = class
  private
    FIdUnidade: Int64;
    FSigla: string;
    FDescricao: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdUnidade: Int64 read FIdUnidade write FIdUnidade;
    property Sigla: string read FSigla write FSigla;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
