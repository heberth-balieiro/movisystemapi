unit InstituicaoCursoInstrutor.Model;

interface

uses
  System.Generics.Collections;

type
  TInstituicaoCursoInstrutorItem = class
  private
    FIdInstrutor: Int64;
    FInstrutorNome: string;
    FInstrutorEmail: string;
    FInstrutorTelefone: string;
    FInstrutorSituacao: string;
    FPrincipal: Boolean;
    FCriadoEm: TDateTime;
  public
    property IdInstrutor: Int64 read FIdInstrutor write FIdInstrutor;
    property InstrutorNome: string read FInstrutorNome write FInstrutorNome;
    property InstrutorEmail: string read FInstrutorEmail write FInstrutorEmail;
    property InstrutorTelefone: string read FInstrutorTelefone write FInstrutorTelefone;
    property InstrutorSituacao: string read FInstrutorSituacao write FInstrutorSituacao;
    property Principal: Boolean read FPrincipal write FPrincipal;
    property CriadoEm: TDateTime read FCriadoEm write FCriadoEm;
  end;

  TInstituicaoCursoInstrutorLista = class
  private
    FItens: TObjectList<TInstituicaoCursoInstrutorItem>;
  public
    constructor Create;
    destructor Destroy; override;

    property Itens: TObjectList<TInstituicaoCursoInstrutorItem> read FItens;
  end;

implementation

constructor TInstituicaoCursoInstrutorLista.Create;
begin
  inherited;
  FItens := TObjectList<TInstituicaoCursoInstrutorItem>.Create(True);
end;

destructor TInstituicaoCursoInstrutorLista.Destroy;
begin
  FItens.Free;
  inherited;
end;

end.
