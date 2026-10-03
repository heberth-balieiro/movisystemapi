unit ContratoResponsavel.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoResponsavelCadastro = record
    IdUsuarioInstituicao: Int64;
    Nome: string;
    Funcao: string;
    NumeroDesignacao: string;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    Ativo: Boolean;
  end;

  TContratoResponsavelItem = class
  public
    Id: Int64;
    IdUsuarioInstituicao: Int64;
    Nome: string;
    Funcao: string;
    NumeroDesignacao: string;
    DataInicio: TDateTime;
    DataFim: TDateTime;
    Ativo: Boolean;
  end;

  TContratoResponsavelLista = TObjectList<TContratoResponsavelItem>;

implementation

end.
