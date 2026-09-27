unit Socio.Model;

interface

uses
  System.SysUtils;

type
  TSocioModel = class
  private
    FIdSocio: Int64;
    FIdEmpresa: Int64;
    FCodigo: Integer;
    FMatricula: Integer;
    FDataAssociacao: TDateTime;
    FSituacao: string;
    FNome: string;
    FApelido: string;
    FCpf: string;
    FRg: string;
    FOrgao: string;
    FCtps: string;
    FSerie: string;
    FPis: string;
    FSexo: string;
    FEstadoCivil: string;
    FDataNascimento: TDateTime;
    FEmail: string;
    FPai: string;
    FMae: string;
    FProfissao: string;
    FDataAdmissao: TDateTime;
    FObservacao: string;
    FFoto: TBytes;
    FEscritorio: Integer;
    FMostrarApp: string;
    FBloqueado: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdSocio: Int64 read FIdSocio write FIdSocio;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;

    property Codigo: Integer read FCodigo write FCodigo;
    property Matricula: Integer read FMatricula write FMatricula;
    property DataAssociacao: TDateTime read FDataAssociacao write FDataAssociacao;
    property Situacao: string read FSituacao write FSituacao;
    property Nome: string read FNome write FNome;
    property Apelido: string read FApelido write FApelido;

    property Cpf: string read FCpf write FCpf;
    property Rg: string read FRg write FRg;
    property Orgao: string read FOrgao write FOrgao;
    property Ctps: string read FCtps write FCtps;
    property Serie: string read FSerie write FSerie;
    property Pis: string read FPis write FPis;
    property Sexo: string read FSexo write FSexo;
    property EstadoCivil: string read FEstadoCivil write FEstadoCivil;
    property DataNascimento: TDateTime read FDataNascimento write FDataNascimento;

    property Email: string read FEmail write FEmail;
    property Pai: string read FPai write FPai;
    property Mae: string read FMae write FMae;
    property Profissao: string read FProfissao write FProfissao;
    property DataAdmissao: TDateTime read FDataAdmissao write FDataAdmissao;

    property Observacao: string read FObservacao write FObservacao;
    property Foto: TBytes read FFoto write FFoto;
    property Escritorio: Integer read FEscritorio write FEscritorio;
    property MostrarApp: string read FMostrarApp write FMostrarApp;
    property Bloqueado: string read FBloqueado write FBloqueado;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
