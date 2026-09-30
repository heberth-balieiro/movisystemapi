unit CertificadoProcessamento.Model;

interface

type
  TCertificadoProcessamentoItem = class
  public
    Id: Int64;
    IdInstituicao: Int64;
    IdCertificado: Int64;
    SolicitadoPor: Int64;
    Tentativas: Integer;
  end;

implementation

end.
