unit ContratoProjecao.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoProjecaoItem = class
  public
    Id: Int64;
    Competencia: TDateTime;
    ValorPrevisto: Double;
    ValorRealizado: Double;
    Origem: string;
    Observacao: string;
  end;

  TContratoProjecaoLista = TObjectList<TContratoProjecaoItem>;

implementation

end.
