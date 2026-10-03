unit ContratoFiscalizacao.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoFiscalizacaoCadastro = record
    DataOcorrencia: TDateTime;
    Tipo: string;
    Descricao: string;
    Providencia: string;
    Situacao: string;
  end;

  TContratoFiscalizacaoItem = class
  public
    Id: Int64;
    DataOcorrencia: TDateTime;
    Tipo: string;
    Descricao: string;
    Providencia: string;
    Situacao: string;
    RegistradoPor: Int64;
    CriadoEm: TDateTime;
    AtualizadoEm: TDateTime;
  end;

  TContratoFiscalizacaoLista = TObjectList<TContratoFiscalizacaoItem>;

implementation

end.
