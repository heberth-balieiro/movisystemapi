unit ContratoHistorico.Model;

interface

uses
  System.Generics.Collections;

type
  TContratoHistoricoItem = class
  public
    Id: Int64;
    Evento: string;
    Descricao: string;
    ReferenciaTipo: string;
    ReferenciaId: Int64;
    DetalhesJson: string;
    Usuario: Int64;
    UsuarioNome: string;
    CriadoEm: TDateTime;
  end;

  TContratoHistoricoLista = TObjectList<TContratoHistoricoItem>;

implementation

end.
