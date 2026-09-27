unit UsuarioAsmuv.Model;

interface

uses
  System.SysUtils;

type
  TUsuarioModel = class
  private
    FIdUsuario: Int64;
    FIdEmpresa: Int64;
    FNome: string;
    FLogin: string;
    FSenha: string;
    FEmail: string;
    FAtivo: string;
    FDataCriacao: TDateTime;
    FDataAlteracao: TDateTime;
  public
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property IdEmpresa: Int64 read FIdEmpresa write FIdEmpresa;
    property Nome: string read FNome write FNome;
    property Login: string read FLogin write FLogin;
    property Senha: string read FSenha write FSenha;
    property Email: string read FEmail write FEmail;
    property Ativo: string read FAtivo write FAtivo;

    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    property DataAlteracao: TDateTime read FDataAlteracao write FDataAlteracao;
  end;

implementation

end.
