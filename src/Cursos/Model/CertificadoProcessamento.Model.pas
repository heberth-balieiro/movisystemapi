unit CertificadoProcessamento.Model;

interface

uses
  System.Generics.Collections;

type
  TCertificadoProcessamentoItem = class
  public
    Id: Int64;
    IdInstituicao: Int64;
    IdCertificado: Int64;
    SolicitadoPor: Int64;
    Tentativas: Integer;
    Situacao: string;
    UltimoErro: string;
    ParticipanteNome: string;
    CursoNome: string;
    NumeroPublico: string;
    CertificadoSituacao: string;
    CriadoEm: TDateTime;
    AtualizadoEm: TDateTime;
    ProximaTentativaEm: TDateTime;
    TemProximaTentativaEm: Boolean;
    ProcessandoEm: TDateTime;
    TemProcessandoEm: Boolean;
    ConcluidoEm: TDateTime;
    TemConcluidoEm: Boolean;
  end;

  TCertificadoProcessamentoLista = class
  public
    Itens: TObjectList<TCertificadoProcessamentoItem>;
    Pagina: Integer;
    PorPagina: Integer;
    Total: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

constructor TCertificadoProcessamentoLista.Create;
begin
  inherited;
  Itens := TObjectList<TCertificadoProcessamentoItem>.Create(True);
end;

destructor TCertificadoProcessamentoLista.Destroy;
begin
  Itens.Free;
  inherited;
end;

end.
