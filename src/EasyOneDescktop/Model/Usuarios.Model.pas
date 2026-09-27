unit Usuarios.Model;

interface

Type
TUsuariosModel  = class
  private
    FEmail: String;
    FAtivo: String;
    FPessoaId: Integer;
    FSenhaHash: String;
    FId: Integer;
    FEmpresaId: Integer;
    FLogin: String;
    FNome: String;
    FIdSocio: Integer;
    Fid_eleitor_int: integer;

  public
    property id         : Integer read FId        write FId;
    property empresa_id : Integer read FEmpresaId write FEmpresaId;
    property pessoa_id  : Integer read FPessoaId  write FPessoaId;
    property nome       : String  read FNome      write FNome;
    property login      : String  read FLogin     write FLogin;
    property senha_hash : String  read FSenhaHash write FSenhaHash;
    property ativo      : String  read FAtivo     write FAtivo;
    property email      : String  read FEmail     write FEmail;
    property id_socio   : Integer read FIdSocio   write FIdSocio;
    property id_eleitor_int: integer read Fid_eleitor_int write Fid_eleitor_int;
end;

implementation

end.
