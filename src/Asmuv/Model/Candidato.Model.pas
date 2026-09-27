unit Candidato.Model;

interface

uses
  System.SysUtils;

type
  TCandidatoModel = class
  private
    FIdCandidato: Int64;
    FIdEmpresa: Int64;
    FCodigo: Integer;
    FNome: string;
    FCargo: string;
    FCpf: string;
    FDescricao: string;
    FFoto: TBytes;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdCandidato: Int64 read FIdCandidato write FIdCandidato;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Codigo: Integer read FCodigo write FCodigo;
    property Nome: string read FNome write FNome;
    property Cargo: string read FCargo write FCargo;
    property Cpf: string read FCpf write FCpf;
    property Descricao: string read FDescricao write FDescricao;
    property Foto: TBytes read FFoto write FFoto;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
