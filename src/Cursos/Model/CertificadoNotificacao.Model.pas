unit CertificadoNotificacao.Model;

interface

type
  TCertificadoNotificacaoItem = class
  public
    Id: Int64;
    IdInstituicao: Int64;
    IdCertificado: Int64;
    Canal: string;
    Destinatario: string;
    Tentativas: Integer;
  end;

  TCertificadoNotificacaoContexto = class
  public
    IdInstituicao: Int64;
    IdCertificado: Int64;
    NumeroPublico: string;
    ParticipanteNome: string;
    ParticipanteEmail: string;
    ParticipanteTelefone: string;
    CursoNome: string;
    InstituicaoNome: string;
    InstituicaoSlug: string;
  end;

implementation

end.
