unit Membro.Model;

interface

uses
  System.SysUtils;

type
  TMembroModel = class
  private
    FIdMembro: Int64;
    FIdEmpresa: Int64;
    FIdUsuario: Int64;
    FIdEleicao: Int64;
    FCodigo: Integer;
    FNome: string;
    FCpf: string;
    FWhatsapp: string;
    FEmail: string;
    FChaveKey: string;
    FFoto: TBytes;
    FPresidente: string;
    FSecretaria: string;
    FMesario: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdMembro: Int64 read FIdMembro write FIdMembro;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property IdEleicao: Int64 read FIdEleicao write FIdEleicao;
    property Codigo: Integer read FCodigo write FCodigo;
    property Nome: string read FNome write FNome;
    property Cpf: string read FCpf write FCpf;
    property Whatsapp: string read FWhatsapp write FWhatsapp;
    property Email: string read FEmail write FEmail;
    property ChaveKey: string read FChaveKey write FChaveKey;
    property Foto: TBytes read FFoto write FFoto;
    property Presidente: string read FPresidente write FPresidente;
    property Secretaria: string read FSecretaria write FSecretaria;
    property Mesario: string read FMesario write FMesario;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
