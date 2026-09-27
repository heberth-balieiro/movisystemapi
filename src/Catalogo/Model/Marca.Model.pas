unit Marca.Model;

interface

uses
  System.SysUtils;

type
  TMarcaModel = class
  private
    FIdMarca: Int64;
    FIdEmpresa: Int64;
    FNome: string;
    FDescricao: string;
    FAtivo: string;
    FOrdem: Integer;
    FProdutoQtde: Integer;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdMarca: Int64 read FIdMarca write FIdMarca;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Descricao: string read FDescricao write FDescricao;
    property Ativo: string read FAtivo write FAtivo;
    property Ordem: Integer read FOrdem write FOrdem;

    // Campo usado apenas na listagem para retornar a quantidade de produtos vinculados
    property ProdutoQtde: Integer read FProdutoQtde write FProdutoQtde;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
