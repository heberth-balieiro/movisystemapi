unit ContratoAditivo.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoAditivoCadastro = record
    Numero: string;
    Tipo: string;
    DataAssinatura: TDateTime;
    NovaDataFim: TDateTime;
    ValorAcrescimo: Double;
    ValorSupressao: Double;
    Justificativa: string;
  end;

  TContratoAditivoItem = class
  public
    Id: Int64;
    Numero: string;
    Tipo: string;
    DataAssinatura: TDateTime;
    NovaDataFim: TDateTime;
    ValorAcrescimo: Double;
    ValorSupressao: Double;
    Justificativa: string;
    CriadoEm: TDateTime;
  end;

  TContratoAditivoLista = TObjectList<TContratoAditivoItem>;

implementation

end.
