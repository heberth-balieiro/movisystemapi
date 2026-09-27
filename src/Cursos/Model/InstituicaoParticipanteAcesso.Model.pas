unit InstituicaoParticipanteAcesso.Model;

interface

type
  TParticipanteAcessoInfo = class
  private
    FIdParticipante: Int64;
    FIdUsuario: Int64;
    FIdUsuarioInstituicao: Int64;
    FNome: string;
    FEmail: string;
    FSituacaoUsuario: string;
    FSituacaoVinculo: string;
    FAcessoLiberado: Boolean;
    FPrimeiroAcessoNecessario: Boolean;
    FConviteWhatsAppEnviado: Boolean;
    FConviteMensagem: string;
  public
    property IdParticipante: Int64 read FIdParticipante write FIdParticipante;
    property IdUsuario: Int64 read FIdUsuario write FIdUsuario;
    property IdUsuarioInstituicao: Int64 read FIdUsuarioInstituicao write FIdUsuarioInstituicao;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property SituacaoUsuario: string read FSituacaoUsuario write FSituacaoUsuario;
    property SituacaoVinculo: string read FSituacaoVinculo write FSituacaoVinculo;
    property AcessoLiberado: Boolean read FAcessoLiberado write FAcessoLiberado;
    property PrimeiroAcessoNecessario: Boolean read FPrimeiroAcessoNecessario write FPrimeiroAcessoNecessario;
    property ConviteWhatsAppEnviado: Boolean read FConviteWhatsAppEnviado write FConviteWhatsAppEnviado;
    property ConviteMensagem: string read FConviteMensagem write FConviteMensagem;
  end;

implementation

end.
