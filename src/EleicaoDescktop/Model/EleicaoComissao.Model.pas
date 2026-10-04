unit EleicaoComissao.Model;

interface

type
  TEleicaoComissaoModel = class
  private
    FId: Integer;
    FEmpresaId: Integer;
    FEleicaoId: Integer;
    FIdEleicaoInt: Integer;
    FIdComissaoInt: Integer;
    FUsuarioId: Integer;
    FNome: string;
    FCPF: string;
    FTelefone: string;
    FEmail: string;
    FCargo: string;
    FAtivo: string;
    FSenhaHash: string;
  public
    property Id: Integer read FId write FId;
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;
    property EleicaoId: Integer read FEleicaoId write FEleicaoId;
    property IdEleicaoInt: Integer read FIdEleicaoInt write FIdEleicaoInt;
    property IdComissaoInt: Integer read FIdComissaoInt write FIdComissaoInt;
    property UsuarioId: Integer read FUsuarioId write FUsuarioId;
    property Nome: string read FNome write FNome;
    property CPF: string read FCPF write FCPF;
    property Telefone: string read FTelefone write FTelefone;
    property Email: string read FEmail write FEmail;
    property Cargo: string read FCargo write FCargo;
    property Ativo: string read FAtivo write FAtivo;
    property SenhaHash: string read FSenhaHash write FSenhaHash;
  end;

implementation

end.
