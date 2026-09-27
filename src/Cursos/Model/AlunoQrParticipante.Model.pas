unit AlunoQrParticipante.Model;

interface

type
  TAlunoQrParticipante = class
  private
    FCodigoParticipante: string;
    FConteudoQr: string;
    FNome: string;
    FMatricula: string;
    FCpfMascarado: string;
  public
    property CodigoParticipante: string read FCodigoParticipante write FCodigoParticipante;
    property ConteudoQr: string read FConteudoQr write FConteudoQr;
    property Nome: string read FNome write FNome;
    property Matricula: string read FMatricula write FMatricula;
    property CpfMascarado: string read FCpfMascarado write FCpfMascarado;
  end;

implementation

end.
