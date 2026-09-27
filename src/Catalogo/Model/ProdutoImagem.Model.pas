unit ProdutoImagem.Model;

interface

uses
  System.SysUtils;

type
  TProdutoImagemModel = class
  private
    FIdImagem: Int64;
    FIdEmpresa: Int64;
    FIdProduto: Int64;
    FUrlImagem: string;
    FPrincipal: string;
    FOrdem: Integer;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdImagem: Int64 read FIdImagem write FIdImagem;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdProduto: Int64 read FIdProduto write FIdProduto;
    property UrlImagem: string read FUrlImagem write FUrlImagem;
    property Principal: string read FPrincipal write FPrincipal;
    property Ordem: Integer read FOrdem write FOrdem;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
