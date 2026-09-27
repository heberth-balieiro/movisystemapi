unit Categoria.Model;

interface

uses
  System.SysUtils;

type
  TCategoriaModel = class
  private
    FIdCategoria: Int64;
    FIdEmpresa: Int64;
    FNome: string;
    FDescricao: string;
    FAtivo: string;
    FOrdem: Integer;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    FImagemUrl: string;
  public
    property IdCategoria: Int64 read FIdCategoria write FIdCategoria;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;
    property Ordem: Integer read FOrdem write FOrdem;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property ImagemUrl: string read FImagemUrl write FImagemUrl;
  end;

implementation

end.
