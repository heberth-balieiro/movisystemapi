unit Usuario.Model;

interface

uses
  System.SysUtils;

type
  TUsuarioModel = class
  private
    FIdUsuario: Int64;
    FIdEmpresa: Int64;
    FNome: string;
    FEmail: string;
    FSenhaHash: string;
    FPerfil: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
    FIdCliente: Int64;
  public
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property SenhaHash: string read FSenhaHash write FSenhaHash;
    property Perfil: string read FPerfil write FPerfil;
    property Ativo: string read FAtivo write FAtivo;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
    property IdCliente: Int64 read FIdCliente write FIdCliente;
  end;

implementation

end.
