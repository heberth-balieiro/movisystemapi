unit ContratoDocumento.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoDocumentoItem = class
  public
    Id: Int64;
    Tipo: string;
    Nome: string;
    StorageKey: string;
    MimeType: string;
    TamanhoBytes: Int64;
    Sha256: string;
    Observacao: string;
    EnviadoPor: Int64;
    CriadoEm: TDateTime;
  end;

  TContratoDocumentoLista = TObjectList<TContratoDocumentoItem>;

implementation

end.
