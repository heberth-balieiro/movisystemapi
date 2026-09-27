unit Autorizacao.Model;

interface

uses
  System.SysUtils;

type
  TAutorizacaoModel = class
  private
    FIdAutorizacao: Int64;
    FIdEmpresa: Int64;
    FDataAutorizacao: TDateTime;
    FNome: string;
    FQtdePessoa: Integer;
    FObservacao: string;
    FPessoaAutorizou: string;
    FStatus: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdAutorizacao: Int64 read FIdAutorizacao write FIdAutorizacao;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property DataAutorizacao: TDateTime read FDataAutorizacao write FDataAutorizacao;
    property Nome: string read FNome write FNome;
    property QtdePessoa: Integer read FQtdePessoa write FQtdePessoa;
    property Observacao: string read FObservacao write FObservacao;
    property PessoaAutorizou: string read FPessoaAutorizou write FPessoaAutorizou;
    property Status: string read FStatus write FStatus;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
